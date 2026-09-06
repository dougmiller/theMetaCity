"""S3-compatible object storage (Linode) via boto3.

One client is created at app initialisation and stored on
``app.extensions['s3']``. boto3's low-level clients are thread-safe once
constructed, and ``generate_presigned_url`` does no network I/O, so a single
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

    def generate_presigned_put(
        self,
        key: str,
        *,
        content_type: str | None = None,
        expires_in: int = 3600,
    ) -> str:
        """Presign a single-object ``PUT`` upload.

        The Linode S3-compatible endpoint accepts a plain HTTP ``PUT`` of the
        raw bytes to the returned URL (it does not support presigned POST). When
        ``content_type`` is given it is signed into the URL, so the client must
        send exactly that ``Content-Type`` header on the PUT. Requires that the
        client be configured.

        :return: the presigned URL to PUT the object bytes to.
        """
        params: dict[str, Any] = {"Bucket": self.bucket, "Key": key}
        if content_type:
            params["ContentType"] = content_type
        return self.client.generate_presigned_url(
            "put_object",
            Params=params,
            ExpiresIn=expires_in,
        )

    def object_exists(self, key: str) -> bool:
        """Return whether ``key`` exists in the bucket (HEAD, no body transfer).

        Used to confirm the client actually completed its presigned upload
        before a post is allowed to reference it. Missing object -> ``False``;
        any other client error is re-raised for the caller to handle.
        """
        from botocore.exceptions import ClientError

        try:
            self.client.head_object(Bucket=self.bucket, Key=key)
        except ClientError as exc:
            code = exc.response.get("Error", {}).get("Code", "")
            if code in ("404", "NoSuchKey", "NotFound"):
                return False
            raise
        return True


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
