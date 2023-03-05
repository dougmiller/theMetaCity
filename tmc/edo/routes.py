from flask import render_template
from .models import EverydayOrdinarySelector as EDOs
from tmc.edo import edo


@edo.route("/")
def home():
    edo_list = EDOs.all()
    return render_template('edo/index.jinja2', **locals())


