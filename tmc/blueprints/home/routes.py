from flask import make_response, render_template
from flask.typing import ResponseReturnValue

from tmc.extensions import cache, read_session
from tmc.queries import blog as blog_queries

from .bp import bp


@bp.route("/health")
def health() -> ResponseReturnValue:
    return "ok", 200


@bp.route("/")
def index() -> ResponseReturnValue:
    articles = blog_queries.latest_articles(read_session(), 3)
    return render_template("home/index.jinja2", articles=articles)


@bp.route("/about/")
@cache.cached()
def about() -> ResponseReturnValue:
    return render_template("home/about.jinja2")


@bp.route("/rss/")
@cache.cached()
def rss() -> ResponseReturnValue:
    return "", 501


@bp.route("/sitemap.xml")
def sitemap() -> ResponseReturnValue:
    template = render_template("home/sitemap.xml")
    response = make_response(template)
    response.headers["Content-Type"] = "application/xml"
    return response
