from botocore.exceptions import ClientError
from flask import current_app, jsonify, request
from flask.typing import ResponseReturnValue

from .bp import bp


@bp.route("/presign", methods=["POST"])
def presign() -> ResponseReturnValue:
    data = request.get_json(silent=True)
    if not data or "filename" not in data:
        return jsonify({"success": False, "error": "Missing 'filename' in JSON body"}), 400

    s3 = current_app.extensions["s3"].client
    try:
        response = s3.generate_presigned_post(
            current_app.config["S3_BUCKET_NAME"],
            data["filename"],
            ExpiresIn=3600,
        )
    except ClientError:
        current_app.logger.exception("presign failed")
        return jsonify({"success": False, "error": "Could not generate upload URL"}), 400

    return jsonify({"success": True, "data": response}), 200


@bp.route("/upload", methods=["POST"])
def upload() -> ResponseReturnValue:
    return jsonify({"message": "Upload successful"})
