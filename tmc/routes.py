from flask import render_template, abort
from tmc import tmc, db
from tmc.models import Article


@tmc.route('/')
def index():
    articles = Article.query.order_by(Article.creation_date.desc()).limit(3).all()
    return render_template('index.html', articles=articles)


@tmc.route('/blog')
def blog():
    articles = Article.query.\
        filter_by(type='blog')\
        .order_by(Article.creation_date.desc())\
        .limit(10)\
        .all()
    return render_template('blog/index.html', articles=articles)


@tmc.route('/blog/archive')
def blog_archive():
    articles = Article.query.\
        filter_by(type='blog')\
        .order_by(Article.creation_date.desc())\
        .all()
    return render_template('blog/index.html', articles=articles)


@tmc.route('/blog/<string:url>')
def blog_with_title(url):
    article = Article.query.\
        filter_by(url=url)\
        .filter_by(type='blog')\
        .first_or_404()
    return render_template('blog/article.html', article=article)


@tmc.route('/blog/<int:year>')
def blog_with_year(year):
    articles = Article.query\
        .filter(db.func.extract('year', Article.creation_date) == year)\
        .filter_by(type='blog')\
        .all()
    return render_template('blog/index.html', articles=articles)


@tmc.route('/blog/<int:year>/<string:url>')
def blog_with_year_and_title(year, url):
    article = Article.query\
        .filter(db.func.extract('year', Article.creation_date) == year)\
        .filter_by(type='blog')\
        .filter_by(url=url).first_or_404()
    return render_template('blog/article.html', article=article)


@tmc.route('/blog/<int:year>/<int:month>')
def blog_with_year_and_month(year, month):
    articles = Article.query\
        .filter(db.func.extract('year', Article.creation_date) == year)\
        .filter(db.func.extract('month', Article.creation_date) == month).all()\
        .filter_by(type='blog')
    return render_template('blog/index.html', articles=articles)


@tmc.route('/blog/<int:year>/<int:month>/<string:url>')
def blog_with_year_and_month_and_title(year, month, url):
    article = Article.query\
        .filter(db.func.extract('year', Article.creation_date) == year)\
        .filter(db.func.extract('month', Article.creation_date) == month)\
        .filter_by(type='blog')\
        .filter_by(url=url).first_or_404()
    return render_template('blog/article.html', article=article)


@tmc.route('/workshop')
def workshop():
    articles = Article.query\
        .filter_by(type='workshop')\
        .order_by(Article.creation_date.desc()).all()
    return render_template('workshop/index.html', articles=articles)


@tmc.route('/workshop/<string:url>')
def workshop_with_title(url):
    article = Article.query\
        .filter_by(type='workshop') \
        .filter_by(url=url).first_or_404()
    return render_template('workshop/article.html', article=article)


@tmc.route('/about')
def about():
    return render_template('about.html')


@tmc.route('/rss')
def rss():
    pass
