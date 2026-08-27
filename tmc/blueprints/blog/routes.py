from flask import abort, make_response, render_template
from flask.typing import ResponseReturnValue

from tmc.extensions import md, read_session
from tmc.queries import blog as blog_queries

from .bp import bp


@bp.after_request
def add_no_store_header(response) -> ResponseReturnValue:
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.route("/")
def home() -> str:
    articles = blog_queries.latest_blogs(read_session())
    return render_template("blog/index.jinja2", articles=articles)


@bp.route("/archive/")
def archive() -> str:
    articles = blog_queries.all_blogs(read_session())
    return render_template("blog/archive.jinja2", articles=articles)


@bp.route("/<string:url>/")
def title(url: str) -> str:
    article = blog_queries.blog_by_url(read_session(), url)
    if article is None:
        abort(404)
    article.content = md.convert(article.content)
    return render_template("blog/article.jinja2", article=article)


@bp.route("/<int:year>/")
def year(year: int) -> str:
    articles = blog_queries.blogs_by_year(read_session(), year)
    return render_template("blog/index.jinja2", articles=articles)


@bp.route("/<int:year>/<string:url>/")
def year_and_title(year: int, url: str) -> str:
    article = blog_queries.blog_by_year_and_url(read_session(), year, url)
    if article is None:
        abort(404)
    return render_template("blog/article.jinja2", article=article)


@bp.route("/tags/")
def tags() -> str:
    all_tags = blog_queries.all_tags(read_session())
    return render_template("blog/tags.jinja2", tags=all_tags)


@bp.route("/tags/<string:tag>/")
def tags_tag(tag: str) -> str:
    found = blog_queries.tag_by_name(read_session(), tag)
    if found is None:
        abort(404)
    return render_template("blog/tag.jinja2", tag=found)


@bp.route("/sitemap.xml")
def sitemap() -> ResponseReturnValue:
    articles = blog_queries.all_blogs(read_session())
    article_tags = blog_queries.all_tags(read_session())
    template = render_template("blog/sitemap.xml", articles=articles, article_tags=article_tags)
    response = make_response(template)
    response.headers["Content-Type"] = "application/xml"
    return response
