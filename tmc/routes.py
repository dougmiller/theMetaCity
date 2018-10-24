from flask import render_template, abort
from tmc import tmc
from tmc.models import Article


@tmc.route('/')
def index():
    articles = Article.query.order_by(Article.creation_date.desc()).limit(3).all()
    return render_template('index.html', articles=articles)


@tmc.route('/blog')
def blog():
    pass


@tmc.route('/workshop')
def workshop():
    pass