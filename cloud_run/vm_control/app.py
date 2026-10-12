import json
import os
import urllib.error
import urllib.request
from pathlib import Path

from flask import Flask, jsonify, request
from google.api_core.exceptions import AlreadyExists
from google.auth.transport.requests import Request
from google.cloud import tasks_v2
from google.oauth2 import id_token
from googleapiclient import discovery
from googleapiclient.errors import HttpError
from nacl.exceptions import BadSignatureError
from nacl.signing import VerifyKey


app = Flask(__name__)
PROJECT = os.environ.get("GCP_PROJECT")
VM_ADMIN_URL = os.environ.get("VM_ADMIN_URL", "").rstrip("/")
TASKS_LOCATION = os.environ.get("TASKS_LOCATION", "us-west1")
TASKS_QUEUE = os.environ.get("TASKS_QUEUE", "vm-control")
TASK_SERVICE_ACCOUNT = os.environ.get(
    "TASK_SERVICE_ACCOUNT", f"vm-control@{PROJECT}.iam.gserviceaccount.com"
)
DISCORD_APPLICATION_ID = os.environ.get("DISCORD_APPLICATION_ID")
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
    admin_link = f"\n[Open the admin page]({VM_ADMIN_URL}/)" if VM_ADMIN_URL else ""
    if state == "RUNNING":
        return f"🟢 **{name}** VM is online. The game may still be starting.{admin_link}"
    if state in {"PROVISIONING", "STAGING", "STOPPING", "SUSPENDING"}:
        return f"🟡 **{name}** is {state.lower()} right now."
    if state == "TERMINATED":
        return f"⚪ **{name}** is offline. Use `/start` to start it."
    if state == "NOT_DEPLOYED":
        return f"⚪ **{name}** is not deployed."
    return f"⚪ **{name}** has status `{state or 'unknown'}`."


def discord_admin_link():
    return f"\n[Open the admin page]({VM_ADMIN_URL}/)" if VM_ADMIN_URL else ""


def task_client():
    return tasks_v2.CloudTasksClient()


def service_base_url():
    # Cloud Run terminates TLS before forwarding the request to Flask, but the
    # forwarded scheme can appear as HTTP. Cloud Tasks requires HTTPS targets.
    return f"https://{request.host}"


def enqueue_discord_task(command, interaction_id, interaction_token):
    """Queue the slow part of a Discord interaction exactly once."""
    base_url = service_base_url()
    client = task_client()
    parent = client.queue_path(PROJECT, TASKS_LOCATION, TASKS_QUEUE)
    task_name = f"{parent}/tasks/discord-{interaction_id}"
    payload = json.dumps({
        "command": command,
        "interaction_id": interaction_id,
        "interaction_token": interaction_token,
    }).encode()
    task = {
        "name": task_name,
        "http_request": {
            "http_method": tasks_v2.HttpMethod.POST,
            "url": f"{base_url}/discord/tasks",
            "headers": {"Content-Type": "application/json"},
            "body": payload,
            "oidc_token": {
                "service_account_email": TASK_SERVICE_ACCOUNT,
                "audience": base_url,
            },
        },
    }
    try:
        client.create_task(parent=parent, task=task)
    except AlreadyExists:
        # Discord can retry an interaction. The first task is still the work item.
        app.logger.info("Discord task already queued: %s", task_name)


def verify_task_request():
    """Validate the OIDC token that Cloud Tasks adds to worker requests."""
    authorization = request.headers.get("Authorization", "")
    if not authorization.startswith("Bearer "):
        return False
    try:
        claims = id_token.verify_oauth2_token(
            authorization.removeprefix("Bearer ").strip(),
            Request(),
            audience=service_base_url(),
        )
    except ValueError:
        return False
    return claims.get("email") == TASK_SERVICE_ACCOUNT and claims.get("email_verified") is True


def edit_original_response(interaction_token, content):
    """Replace Discord's deferred response, retrying transient HTTP failures."""
    if not DISCORD_APPLICATION_ID:
        raise RuntimeError("DISCORD_APPLICATION_ID is not configured")
    url = (
        f"https://discord.com/api/v10/webhooks/{DISCORD_APPLICATION_ID}/"
        f"{interaction_token}/messages/@original"
    )
    body = json.dumps({"content": content}).encode()
    request_data = urllib.request.Request(
        url,
        data=body,
        method="PATCH",
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(request_data, timeout=10) as response:
            response.read()
    except urllib.error.HTTPError as error:
        if 400 <= error.code < 500:
            # Expired/invalid interaction tokens are permanent failures. Do not
            # keep replaying a task whose Discord response can no longer exist.
            app.logger.warning("Discord response rejected with HTTP %s", error.code)
            return False
        raise
    return True


def deferred_start_message(game, status_code, body):
    if status_code == 202:
        return (
            f"🟡 Starting **{DISPLAY_NAMES[game]}** now. "
            f"It may take a few minutes before the game is ready. "
            f"Use `/status` or check the admin page.{discord_admin_link()}"
        )
    if status_code == 200:
        return (
            f"🟢 **{DISPLAY_NAMES[game]}** VM is already online. "
            f"The game may still be starting.{discord_admin_link()}"
        )
    if body.get("error") == "another_instance_active":
        return "⚠️ Another game server is already active. Check `/status game` before starting this one."
    if body.get("error") == "unknown_instance":
        return f"⚪ **{DISPLAY_NAMES[game]}** is not configured."
    return f"⚠️ **{DISPLAY_NAMES[game]}** could not be started right now."


@app.get("/health")
def health():
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

    enqueue_discord_task(
        command,
        payload.get("id"),
        payload.get("token"),
    )
    # Discord requires an acknowledgement within a few seconds. Cloud Tasks
    # performs Compute Engine work and edits this deferred response afterward.
    return jsonify({"type": 5})


@app.post("/discord/tasks")
def discord_task():
    if not verify_task_request():
        return jsonify({"error": "invalid_task_identity"}), 401

    payload = request.get_json(silent=True) or {}
    command = payload.get("command")
    interaction_token = payload.get("interaction_token")
    if command not in {"status", "start"} or not interaction_token:
        return jsonify({"error": "invalid_task"}), 400

    game, status = discord_target(compute_client())
    if game is None:
        message = "I need exactly one deployed game server before I can control it."
    elif command == "status":
        message = discord_status_message(game, status)
    else:
        body, status_code = start_instance_result(game)
        message = deferred_start_message(game, status_code, body)

    edit_original_response(interaction_token, message)
    return jsonify({"status": "completed"})


@app.errorhandler(HttpError)
def handle_compute_error(error):
    return jsonify({"error": "compute_api_error", "status": error.resp.status}), 502


@app.errorhandler(Exception)
def handle_unexpected_error(error):
    app.logger.exception("Unexpected VM control error")
    return jsonify({"error": "internal_error"}), 500
