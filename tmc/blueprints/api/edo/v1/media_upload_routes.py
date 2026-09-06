import uuid

from botocore.exceptions import ClientError
from flask import current_app, request
from flask.typing import ResponseReturnValue
from werkzeug.utils import secure_filename

from tmc.utils.responses import api_response

from .bp import bp


@bp.route("/media/presign", methods=["POST"])
def presign() -> ResponseReturnValue:
    """Hand the client a presigned ``PUT`` URL for a direct-to-S3 upload.

    The object key is chosen *server-side* (a random prefix + the sanitised
    filename) so a client can never overwrite another object. When the client
    declares a ``content_type`` it is signed into the URL and must be sent as
    the ``Content-Type`` header on the PUT. The generated ``key`` is returned so
    the client can reference the same object when it later calls ``POST /post``.

    The client uploads by PUTting the raw file bytes to ``data.url`` with the
    returned ``data.headers`` (Linode S3 accepts PUT, not presigned POST).
    """
    filename = request.form.get("filename")
    if not filename:
        return api_response(message="Missing 'filename'", success=False, status=400)

    safe_name = secure_filename(filename) or "upload"
    key = f"{uuid.uuid4().hex}/{safe_name}"

    content_type = request.form.get("content_type") or None

    s3 = current_app.extensions["s3"]
    try:
        url = s3.generate_presigned_put(key, content_type=content_type)
    except ClientError:
        current_app.logger.exception("presign failed")
        return api_response(message="Could not generate upload URL", success=False, status=400)

    headers = {"Content-Type": content_type} if content_type else {}
    return api_response(data={"key": key, "url": url, "method": "PUT", "headers": headers}, status=200)
