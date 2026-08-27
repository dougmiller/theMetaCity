from flask import Blueprint

bp: Blueprint = Blueprint(
    "media",
    __name__,
    template_folder="templates",
    static_folder="static",
    static_url_path="",
)
