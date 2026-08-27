import os

from flask import current_app, jsonify, request
from flask.typing import ResponseReturnValue
from werkzeug.utils import secure_filename

from tmc import queries
from tmc.extensions import db, read_session
from tmc.models.edo import EDO
from tmc.queries import edo as edo_queries
from tmc.schemas.edo import EDOSchema
from tmc.utils.responses import api_response

from .bp import bp


@bp.route("/help/")
@bp.route("/")
def edo_index() -> ResponseReturnValue:
    return jsonify(
        {
            "info": "Everyday Ordinary api endpoints ",
            "routes": [
                {"endpoint": "/help", "description": "This information"},
                {"endpoint": "/login", "description": "Authenticates the user and their credentials. Returns a JWT for future use"},
                {"endpoint": "/logout", "description": "De-authenticates the user's JWT so they can no longer login"},
                {"endpoint": "/list", "description": "Return a list of all EDO entries"},
                {"endpoint": "/text", "description": "Add a new text only extry to edo"},
                {"endpoint": "/image", "description": "Add a new image only extry to edo"},
            ],
        }
    )


@bp.route("login", methods=["POST"])
def login() -> ResponseReturnValue:
    return "", 501


@bp.route("logout", methods=["POST"])
def logout() -> ResponseReturnValue:
    return "", 501


@bp.route("appreciate", methods=["POST"])
def appreciate() -> ResponseReturnValue:
    text_edo = EDO()
    text_edo.content = request.form.get("text") or ""
    queries.save(db.session, text_edo)

    uploaded_image = request.files["image"]
    uploaded_name = secure_filename(uploaded_image.filename or "")

    if uploaded_name != "":
        os.mkdir(current_app.config["EDO_UPLOAD_PATH"] + "/" + str(text_edo.id))
        uploaded_image.save(os.path.join(current_app.config["EDO_UPLOAD_PATH"] + "/" + str(text_edo.id), uploaded_name))

    return api_response(message=text_edo.content)


@bp.route("text", methods=["POST"])
def text() -> ResponseReturnValue:
    if not request.form.get("text"):
        return jsonify(["No text supplied"])

    text_edo = EDO()
    text_edo.content = request.form.get("text") or ""
    # todo run this through markdown
    queries.save(db.session, text_edo)
    return jsonify(["OK"])


@bp.route("image", methods=["GET"])
def g_image() -> ResponseReturnValue:
    return api_response(message="get request")


@bp.route("image", methods=["POST"])
def image() -> ResponseReturnValue:
    if "image" not in request.files:
        if "image" in request.form:
            return api_response(message='Parameter "image" was not type "file" in request', success=False, status=400)
        return api_response(message='No "image" in request', success=False, status=400)

    uploaded_image = request.files["image"]
    uploaded_name = secure_filename(uploaded_image.filename or "")

    if uploaded_name == "":
        return api_response(message="No image to upload", success=False, status=400)

    uploaded_image.save(os.path.join(current_app.config["EDO_UPLOAD_PATH"], uploaded_name))
    return api_response(message="Image uploaded")


@bp.route("video", methods=["POST"])
def video() -> ResponseReturnValue:
    return "", 501


@bp.route("list/", methods=["GET"])
def list_edo() -> ResponseReturnValue:
    all_list = edo_queries.all_edo(read_session())
    return api_response(data=EDOSchema(many=True).dump(all_list))


@bp.route("list/<uuid:record>", methods=["GET"])
def one_edo(record) -> ResponseReturnValue:
    one = edo_queries.by_id(read_session(), record)
    if one is None:
        return api_response(message="No matching record found", success=False, status=404)
    return api_response(data=EDOSchema().dump(one))
