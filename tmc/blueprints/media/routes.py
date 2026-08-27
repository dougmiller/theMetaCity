import os

from flask import make_response, render_template
from flask.typing import ResponseReturnValue

from tmc.extensions import read_session
from tmc.queries import media as media_queries

from .bp import bp as media


@media.route("/")
def home() -> ResponseReturnValue:
    all = media_queries.all_assets(read_session())
    return render_template("media/index.jinja2", media=all)


@media.route("/favicon.ico")
def show_favicon() -> str:
    return ""


@media.errorhandler(404)
def page_not_found(e) -> ResponseReturnValue:
    return render_template("404.html"), 404


@media.route("/sitemap.xml")
def sitemap() -> ResponseReturnValue:
    media_items = media_queries.all_assets(read_session())
    template = render_template("media/sitemap.xml", media=media_items)
    response = make_response(template)
    response.headers["Content-Type"] = "application/xml"
    return response


@media.context_processor
def custom_importer() -> dict:
    def import_svg(name) -> str:
        path = os.path.join(os.path.abspath(os.path.dirname(__file__)), "static", "images", name + ".svg")
        with open(path) as f:
            data = f.readlines()[1:]
        return "".join(data)

    return {"import_svg": import_svg}
