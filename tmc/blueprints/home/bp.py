from flask import Blueprint

bp: Blueprint = Blueprint(
    name="home",
    import_name=__name__,
    template_folder="templates",
    static_folder="static",
    static_url_path="",
)
