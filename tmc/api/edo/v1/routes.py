from flask import jsonify, request, current_app
from . import v1, api_response
from ....edo.models import EverydayOrdinary, EverydayOrdinarySelector


@v1.route("/help")
@v1.route("/")
def edo_index():
    # return openAPI swagger doc (YAML)

    return jsonify(
        {
            'info': 'Everyday Ordinary api endpoints ',
            'routes': [
                {"endoint": "/help", "description": "This information"},
                {"endoint": "/login",
                 "description": "Authenticates the user and their credentials. Returns a JWT for future use"},
                {"endoint": "/logout", "description": "De-authenticates the user's JWT so they can no longer login"},
                {"endoint": "/list", "description": "Return a list of all EDO entries"},
                {"endoint": "/text", "description": "Add a new text only extry to edo"},
                {"endoint": "/image", "description": "Add a new image only extry to edo"},
            ]
        }
    )


@v1.route("login", methods=["POST"])
def login():
    # Get user details from request
    # Authentaicate user
    # Generate JWT
    # Return response inc JWT
    pass


@v1.route("logout", methods=["POST"])
def logout():
    # Get user details from JWT
    # Invalidte JWT
    # Return sensible response
    pass


# Add JWT decorator
@v1.route("text", methods=['POST'])
def text():
    if not request.form.get('text'):
        return jsonify(["No text supplied"])

    text_edo = EverydayOrdinary()
    text_edo.contents = request.form.get('text')
    # todo run this through markdown
    text_edo.save()
    return jsonify(["OK"])


# Add JWT decorator
@v1.route("image", methods=['POST'])
def image():
    import os
    from werkzeug.utils import secure_filename

    if 'image' not in request.files:
        if 'image' in request.form:
            api_response['result']['status'] = 'error'
            api_response['result']['message'] = 'Parameter "image" was not type "file" in request'
            return jsonify(api_response), 400

        api_response['result']['status'] = 'error'
        api_response['result']['message'] = 'No "image" in request'
        return jsonify(api_response), 400

    uploaded_image = request.files['image']
    uploaded_name = secure_filename(uploaded_image.filename)

    if uploaded_name == '':
        api_response['result']['status'] = 'error'
        api_response['result']['message'] = 'No image to upload'
        return jsonify(api_response), 400

    uploaded_image.save(os.path.join(current_app.config['EDO_UPLOAD_PATH'], uploaded_name))
    api_response['result']['status'] = 'success'
    api_response['result']['message'] = 'Image uploaded'

    return jsonify(api_response)


# Add JWT decorator
@v1.route("video", methods=['POST'])
def video():
    pass


@v1.route("list")
def list_edo():
    all_list = EverydayOrdinarySelector.all()
    return jsonify([edo.to_dict() for edo in all_list])
