import json
import os
from pathlib import Path

from flask import Flask, jsonify, request
from googleapiclient import discovery
from googleapiclient.errors import HttpError
from nacl.exceptions import BadSignatureError
from nacl.signing import VerifyKey


app = Flask(__name__)
PROJECT = os.environ.get("GCP_PROJECT")
CONFIG_PATH = Path(__file__).with_name("instances.json")
ACTIVE_STATES = {"PROVISIONING", "STAGING", "RUNNING", "STOPPING", "SUSPENDING"}
DISPLAY_NAMES = {
    "barotrauma": "Barotrauma",
    "valheim": "Valheim",
    "vrising": "V Rising",
}


def load_instances():
    with CONFIG_PATH.open() as config_file:
        return json.load(config_file)


def compute_client():
    return discovery.build("compute", "v1", cache_discovery=False)


def instance_state(compute, config):
    try:
        instance = (
            compute.instances()
            .get(project=PROJECT, zone=config["zone"], instance=config["instance"])
            .execute()
        )
    except HttpError as error:
        if error.resp.status == 404:
            return {"state": "NOT_DEPLOYED"}
        raise

    return {
        "state": instance.get("status", "UNKNOWN"),
        "instance": config["instance"],
        "zone": config["zone"],
    }


def configured_states(compute, instances):
    return {
        instance: instance_state(compute, config)
        for instance, config in instances.items()
    }


def start_instance_result(instance_key):
    """Start one configured instance and return the API body and HTTP status."""
    instances = load_instances()
    config = instances.get(instance_key)
    if config is None:
        return {"error": "unknown_instance", "instance": instance_key}, 404

    compute = compute_client()
    states = configured_states(compute, instances)
    target = states[instance_key]
    target_state = target["state"]

    if target_state == "NOT_DEPLOYED":
        return {"instance": instance_key, "state": target_state}, 409
    if target_state in {"RUNNING", "PROVISIONING", "STAGING"}:
        return {"instance": instance_key, "state": target_state.lower()}, 200

    other_active = [
        other_instance
        for other_instance, status in states.items()
        if other_instance != instance_key and status["state"] in ACTIVE_STATES
    ]
    if other_active:
        return {
            "error": "another_instance_active",
            "instance": instance_key,
            "active_instances": other_active,
        }, 409

    if target_state != "TERMINATED":
        return {
            "error": "unsupported_instance_state",
            "instance": instance_key,
            "state": target_state,
        }, 409

    operation = (
        compute.instances()
        .start(project=PROJECT, zone=config["zone"], instance=config["instance"])
        .execute()
    )
    return {
        "instance": instance_key,
        "state": "starting",
        "operation": operation.get("name"),
    }, 202


def verify_discord_request():
    """Verify Discord's Ed25519 signature over the exact raw request body."""
    public_key = os.environ.get("DISCORD_PUBLIC_KEY")
    signature = request.headers.get("X-Signature-Ed25519")
    timestamp = request.headers.get("X-Signature-Timestamp")
    if not public_key or not signature or not timestamp:
        return False

    try:
        VerifyKey(bytes.fromhex(public_key)).verify(
            timestamp.encode() + request.get_data(),
            bytes.fromhex(signature),
        )
    except (ValueError, BadSignatureError):
        return False
    return True


def discord_response(content, ephemeral=False):
    data = {"content": content}
    if ephemeral:
        data["flags"] = 64
    return {"type": 4, "data": data}


def discord_location_allowed(payload):
    locations = os.environ.get("DISCORD_ALLOWED_LOCATIONS", "")
    allowed = {
        tuple(location.split(":", 1))
        for location in locations.split(";")
        if ":" in location
    }
    return (payload.get("guild_id"), payload.get("channel_id")) in allowed


def discord_target(compute):
    """Return the only deployed instance, or None when selection is ambiguous."""
    states = configured_states(compute, load_instances())
    deployed = [
        (instance, status)
        for instance, status in states.items()
        if status.get("state") != "NOT_DEPLOYED"
    ]
    return deployed[0] if len(deployed) == 1 else (None, None)


def discord_status_message(game, status):
    name = DISPLAY_NAMES[game]
    state = status.get("state")
    if state == "RUNNING":
        return f"🟢 **{name}** is online."
    if state in {"PROVISIONING", "STAGING", "STOPPING", "SUSPENDING"}:
        return f"🟡 **{name}** is {state.lower()} right now."
    if state == "TERMINATED":
        return f"⚪ **{name}** is offline. Use `/start` to start it."
    if state == "NOT_DEPLOYED":
        return f"⚪ **{name}** is not deployed."
    return f"⚪ **{name}** has status `{state or 'unknown'}`."


@app.get("/healthz")
def healthz():
    return jsonify({"status": "ok"})


@app.get("/v1/instances")
def instances_status():
    compute = compute_client()
    return jsonify({"instances": configured_states(compute, load_instances())})


@app.post("/v1/instances/<instance>/start")
def start_instance(instance):
    instance_key = instance.lower()
    body, status = start_instance_result(instance_key)
    return jsonify(body), status


@app.post("/discord/interactions")
def discord_interactions():
    if not verify_discord_request():
        return jsonify({"error": "invalid_signature"}), 401

    payload = request.get_json(silent=True) or {}
    if payload.get("type") == 1:  # Discord URL-verification ping.
        return jsonify({"type": 1})

    if payload.get("type") != 2:
        return jsonify(discord_response("I don't recognize that interaction.", ephemeral=True))
    if not discord_location_allowed(payload):
        return jsonify(discord_response("This command is not available here.", ephemeral=True))

    command = payload.get("data", {}).get("name")
    if command == "help":
        return jsonify(discord_response(
            "**Game Server Controller**\n"
            "`/status` — check the game server\n"
            "`/start` — start the game server\n"
            "`/help` — show this help"
        ))

    if command not in {"status", "start"}:
        return jsonify(discord_response("I don't recognize that command.", ephemeral=True))

    game, status = discord_target(compute_client())
    if game is None:
        return jsonify(discord_response(
            "I need exactly one deployed game server before I can control it.",
            ephemeral=True,
        ))

    if command == "status":
        return jsonify(discord_response(discord_status_message(game, status)))

    body, status_code = start_instance_result(game)
    if status_code == 202:
        message = f"🟡 Starting **{DISPLAY_NAMES[game]}** now. Use `/status` in a moment to check it."
    elif status_code == 200:
        message = f"🟢 **{DISPLAY_NAMES[game]}** is already online."
    elif body.get("error") == "another_instance_active":
        message = "⚠️ Another game server is already active. Check `/status game` before starting this one."
    elif body.get("error") == "unknown_instance":
        message = f"⚪ **{DISPLAY_NAMES[game]}** is not configured."
    else:
        message = f"⚠️ **{DISPLAY_NAMES[game]}** could not be started right now."
    return jsonify(discord_response(message))


@app.errorhandler(HttpError)
def handle_compute_error(error):
    return jsonify({"error": "compute_api_error", "status": error.resp.status}), 502


@app.errorhandler(Exception)
def handle_unexpected_error(error):
    app.logger.exception("Unexpected VM control error")
    return jsonify({"error": "internal_error"}), 500
