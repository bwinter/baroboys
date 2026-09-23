import json
import os
from pathlib import Path

from flask import Flask, jsonify
from googleapiclient import discovery
from googleapiclient.errors import HttpError


app = Flask(__name__)
PROJECT = os.environ.get("GCP_PROJECT")
CONFIG_PATH = Path(__file__).with_name("instances.json")
ACTIVE_STATES = {"PROVISIONING", "STAGING", "RUNNING", "STOPPING", "SUSPENDING"}


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


@app.get("/healthz")
def healthz():
    return jsonify({"status": "ok"})


@app.get("/v1/instances")
def instances_status():
    compute = compute_client()
    return jsonify({"instances": configured_states(compute, load_instances())})


@app.post("/v1/instances/<instance>/start")
def start_instance(instance):
    instances = load_instances()
    instance_key = instance.lower()
    config = instances.get(instance_key)
    if config is None:
        return jsonify({"error": "unknown_instance", "instance": instance}), 404

    compute = compute_client()
    states = configured_states(compute, instances)
    target = states[instance_key]
    target_state = target["state"]

    if target_state == "NOT_DEPLOYED":
        return jsonify({"instance": instance_key, "state": target_state}), 409
    if target_state in {"RUNNING", "PROVISIONING", "STAGING"}:
        return jsonify({"instance": instance_key, "state": target_state.lower()}), 200

    other_active = [
        other_instance
        for other_instance, status in states.items()
        if other_instance != instance_key and status["state"] in ACTIVE_STATES
    ]
    if other_active:
        return jsonify({
            "error": "another_instance_active",
            "instance": instance_key,
            "active_instances": other_active,
        }), 409

    if target_state != "TERMINATED":
        return jsonify({
            "error": "unsupported_instance_state",
            "instance": instance_key,
            "state": target_state,
        }), 409

    operation = (
        compute.instances()
        .start(project=PROJECT, zone=config["zone"], instance=config["instance"])
        .execute()
    )
    return jsonify({
        "instance": instance_key,
        "state": "starting",
        "operation": operation.get("name"),
    }), 202


@app.errorhandler(HttpError)
def handle_compute_error(error):
    return jsonify({"error": "compute_api_error", "status": error.resp.status}), 502


@app.errorhandler(Exception)
def handle_unexpected_error(error):
    app.logger.exception("Unexpected VM control error")
    return jsonify({"error": "internal_error"}), 500
