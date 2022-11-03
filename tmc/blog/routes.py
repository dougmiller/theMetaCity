from flask import render_template, make_response
from tmc import db, cache
from tmc.blog import blog
from tmc.models import Article, ArticleTag


@blog.route('/')
def home():
    articles = Article.query.\
        filter_by(type='blog')\
        .order_by(Article.creation_date.desc())\
        .limit(10)\
        .all()
    tags = ArticleTag.query\
        .all()
    return render_template('blog/index.html', **locals())


@blog.route('/archive/')
def archive():
    articles = Article.query.\
        filter_by(type='blog')\
        .order_by(Article.creation_date.desc())\
        .all()
    tags = ArticleTag.query\
        .all()
    return render_template('blog/archive.html', **locals())


@blog.route('/<string:url>/')
def title(url):
    article = Article.query.\
        filter_by(url=url)\
        .filter_by(type='blog')\
        .first_or_404()
    return render_template('blog/article.html', article=article)


@blog.route('/<int:year>/')
def year(year):
    articles = Article.query\
        .filter(db.func.extract('year', Article.creation_date) == year)\
        .filter_by(type='blog')\
        .all()
    return render_template('blog/index.html', articles=articles)


@blog.route('/<int:year>/<string:url>/')
def year_and_title(year, url):
    article = Article.query\
        .filter(db.func.extract('year', Article.creation_date) == year)\
        .filter_by(type='blog')\
        .filter_by(url=url).first_or_404()
    return render_template('blog/article.html', article=article)


@blog.route('/<int:year>/<int:month>/')
def year_and_month(year, month):
    articles = Article.query\
        .filter(db.func.extract('year', Article.creation_date) == year)\
        .filter(db.func.extract('month', Article.creation_date) == month).all()\
        .filter_by(type='blog')
    return render_template('blog/index.html', articles=articles)


@blog.route('/<int:year>/<int:month>/<string:url>/')
def year_and_month_and_title(year, month, url):
    article = Article.query\
        .filter(db.func.extract('year', Article.creation_date) == year)\
        .filter(db.func.extract('month', Article.creation_date) == month)\
        .filter_by(type='blog')\
        .filter_by(url=url).first_or_404()
    return render_template('blog/article.html', article=article)


@blog.route('/tags/')
def tags():
    tags = ArticleTag.query.all()
    return render_template('blog/tags.html', tags=tags)


@blog.route('/tags/<string:tag>/')
def tags_tag(tag):
    tag = ArticleTag.query\
        .filter_by(tag=tag)\
        .first_or_404()
    return render_template('blog/tag.html', tag=tag)


@blog.route('/sitemap.xml')
def sitemap():
    articles = Article.query.\
        filter_by(type='blog')\
        .order_by(Article.creation_date.desc())\
        .all()
    article_tags = ArticleTag.query\
        .all()

    template = render_template('blog/sitemap.xml', **locals())
    response = make_response(template)
    response.headers['Content-Type'] = 'application/xml'
    return response
