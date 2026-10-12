#!/usr/bin/env python3
"""Local smoke tests for the Discord interaction endpoint.

These tests use a temporary signing key and mocked Compute Engine responses.
They do not contact Discord or GCP.
"""

import json
import os
import sys
import unittest
from unittest.mock import patch

from nacl.signing import SigningKey


APP_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../cloud_run/vm_control"))
sys.path.insert(0, APP_DIR)

signing_key = SigningKey.generate()
os.environ["DISCORD_PUBLIC_KEY"] = signing_key.verify_key.encode().hex()
os.environ["DISCORD_ALLOWED_LOCATIONS"] = "test-guild:test-channel"
os.environ["GCP_PROJECT"] = "test-project"
os.environ["TASK_SERVICE_ACCOUNT"] = "vm-control@test-project.iam.gserviceaccount.com"
os.environ["DISCORD_APPLICATION_ID"] = "test-application"

from app import app  # noqa: E402


class DiscordInteractionTests(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def post_interaction(self, payload, key=signing_key):
        body = json.dumps(payload, separators=(",", ":")).encode()
        timestamp = "1727123456"
        signature = key.sign(timestamp.encode() + body).signature.hex()
        return self.client.post(
            "/discord/interactions",
            data=body,
            content_type="application/json",
            headers={
                "X-Signature-Ed25519": signature,
                "X-Signature-Timestamp": timestamp,
            },
        )

    def test_rejects_unsigned_request(self):
        response = self.client.post("/discord/interactions", json={"type": 1})
        self.assertEqual(response.status_code, 401)

    def test_health(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"status": "ok"})

    def test_handles_ping(self):
        response = self.post_interaction({"type": 1})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"type": 1})

    def test_help_response(self):
        response = self.post_interaction({
            "type": 2,
            "guild_id": "test-guild",
            "channel_id": "test-channel",
            "data": {"name": "help", "options": []},
        })
        self.assertEqual(response.status_code, 200)
        self.assertIn("/status", response.json["data"]["content"])

    def test_rejects_wrong_channel(self):
        response = self.post_interaction({
            "type": 2,
            "guild_id": "test-guild",
            "channel_id": "wrong-channel",
            "data": {"name": "help", "options": []},
        })
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json["data"]["flags"], 64)

    @patch("app.enqueue_discord_task")
    def test_status_is_deferred(self, enqueue_task):
        response = self.post_interaction({
            "type": 2,
            "id": "interaction-id",
            "token": "interaction-token",
            "application_id": "test-application",
            "guild_id": "test-guild",
            "channel_id": "test-channel",
            "data": {"name": "status", "options": []},
        })
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"type": 5})
        enqueue_task.assert_called_once_with(
            "status", "interaction-id", "interaction-token", "test-application"
        )

    @patch("app.edit_original_response")
    @patch("app.verify_task_request", return_value=True)
    @patch("app.compute_client")
    @patch("app.load_instances")
    @patch("app.configured_states")
    def test_status_worker_response(
        self, configured_states, load_instances, compute_client, verify_task, edit_response
    ):
        load_instances.return_value = {
            "valheim": {"instance": "valheim", "zone": "us-west1-b"}
        }
        compute_client.return_value = object()
        configured_states.return_value = {"valheim": {"state": "RUNNING"}}
        response = self.client.post("/discord/tasks", json={
            "command": "status",
            "interaction_token": "interaction-token",
            "application_id": "test-application",
        })
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"status": "completed"})
        edit_response.assert_called_once()
        self.assertIn("Valheim", edit_response.call_args.args[2])


if __name__ == "__main__":
    unittest.main()
