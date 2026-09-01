"""S3-compatible object storage (Linode) via boto3.

One client is created at app initialisation and stored on
``app.extensions['s3']``. boto3's low-level clients are thread-safe once
constructed, and ``generate_presigned_post`` does no network I/O, so a single
shared client is both correct and fast — far cheaper than rebuilding a client
(which loads botocore service models) on every request. Config is validated in
``preflight`` and, on the normal boot path, sourced from the environment in
``load_config``.
"""

from dataclasses import dataclass
from typing import Any

from flask import Flask

# S3 configuration keys (populated from env on the non-injected path).
_S3_KEYS = (
    "S3_ACCESS_KEY",
    "S3_BUCKET_NAME",
    "S3_ENDPOINT_URL",
    "S3_REGION_NAME",
    "S3_SECRET_KEY",
)


@dataclass
class S3Extension:
    client: Any
    bucket: str

    def generate_presigned_post(self, filename: str, *, expires_in: int = 3600) -> dict:
        """Generate a presigned post request to S3.
        Requires that the client be configured
        :return JSON response S3 presigned post request with details to upload to"""
        return self.client.generate_presigned_post(self.bucket, filename, ExpiresIn=expires_in)


def load_config(app: Flask) -> None:
    """Populate S3 config from the environment (non-injected path)."""
    from tmc.extensions._env import raw_env

    env = raw_env()
    app.config.from_mapping({key: env.get(key) for key in _S3_KEYS})


def preflight(app: Flask) -> list[str]:
    return [f"{key} not set" for key in _S3_KEYS if not app.config.get(key)]


def init_app(app: Flask) -> None:
    import boto3
    from botocore.config import Config

    client = boto3.client(
        "s3",
        endpoint_url=app.config["S3_ENDPOINT_URL"],
        aws_access_key_id=app.config["S3_ACCESS_KEY"],
        aws_secret_access_key=app.config["S3_SECRET_KEY"],
        region_name=app.config["S3_REGION_NAME"],
        config=Config(
            signature_version="s3v4",
            s3={"addressing_style": "virtual"},
        ),
    )

    app.extensions["s3"] = S3Extension(
        client=client,
        bucket=app.config["S3_BUCKET_NAME"],
    )
