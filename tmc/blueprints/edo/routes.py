from flask import render_template

from tmc.extensions import read_session
from tmc.queries import edo as edo_queries

from .bp import bp


@bp.route("/")
def home() -> str:
    edo_list = edo_queries.latest(read_session(), limit=10)
    return render_template("edo/index.jinja2", edo_list=edo_list)
