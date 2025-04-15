from flask import jsonify


def api_response(data=None, success=True, message=None, status=200):
	response = {
		"success": success,
	}
	
	if data:
		response["data"] = data

	if message:
		response["message"] = message

	return jsonify(response), status
