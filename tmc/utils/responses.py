from flask import Response, jsonify


def api_response(data=None, success=True, message=None, status=200) -> tuple[Response, int]:
    response = {
        "success": success,
        "data": data if data is not None else {},
    }

    if message:
        response["message"] = message

    return jsonify(response), status
