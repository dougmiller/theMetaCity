from flask import render_template, make_response
from tmc import db, cache
from . import edo
from tmc.models.edo import EDO


@edo.route("/")
def home():
    edo_list = db.session.execute(
        db.select(EDO)
            .order_by(EDO.created_at.desc())
            .limit(10)
    ).scalars()
    
    return render_template('edo/index.jinja2', **locals())


