from flask import render_template, make_response
from tmc import db, cache
from tmc.extensions import md
from . import blog
from tmc.models.blog import Blog, Tag


@blog.route('/')
def home() -> str:
    articles = db.session.execute(
        db.select(Blog)
            .order_by(Blog.created_at.desc())
            .limit(10)
    ).scalars()
        
    return render_template('blog/index.html', **locals())


@blog.route('/archive/')
def archive() -> str:
    articles = db.session.execute(
        db.select(Blog)
        .order_by(Blog.created_at.desc())
    ).scalars()

    return render_template('blog/archive.html', **locals())


@blog.route('/<string:url>/')
def title(url: str) -> str:
 
    article = db.one_or_404(
        db.select(Blog)
            .filter_by(url=url)
    )
    
    article.content = md.convert(article.content)

    return render_template('blog/article.html', article=article)


@blog.route('/<int:year>/')
def year(year) -> str:
    
    articles = db.session.execute(
        db.select(Blog)
            .where(db.func.extract('year', Blog.created_at)==year)
            .order_by(Blog.created_at.desc())
    ).scalars()
    
    print(articles)

    return render_template('blog/index.html', articles=articles)


@blog.route('/<int:year>/<string:url>/')
def year_and_title(year, url):
    
    article = db.one_or_404(
        db.select(Blog)
            .where(Blog.url == url)
            .filter(db.func.extract('year', Blog.created_at) == year)
    )
    
    return render_template('blog/article.html', article=article)


@blog.route('/<int:year>/<int:month>/')
def year_and_month(year, month):
    articles = Blog.query\
        .filter(db.func.extract('year', Blog.creation_date) == year)\
        .filter(db.func.extract('month', Blog.creation_date) == month).all()
    return render_template('blog/index.html', articles=articles)


@blog.route('/<int:year>/<int:month>/<string:url>/')
def year_and_month_and_title(year, month, url):
    article = Blog.query\
        .filter(db.func.extract('year', Blog.creation_date) == year)\
        .filter(db.func.extract('month', Blog.creation_date) == month)\
        .filter_by(url=url).first_or_404()
    return render_template('blog/article.html', article=article)


@blog.route('/tags/')
def tags():
    tags = Tag.query.all()
    return render_template('blog/tags.html', tags=tags)


@blog.route('/tags/<string:tag>/')
def tags_tag(tag):
    tag = Tag.query\
        .filter_by(tag=tag)\
        .first_or_404()
    return render_template('blog/tag.html', tag=tag)


@blog.route('/sitemap.xml')
def sitemap():
    articles = Blog.query\
        .order_by(Blog.creation_date.desc())\
        .all()
    article_tags = Tag.query\
        .all()

    template = render_template('blog/sitemap.xml', **locals())
    response = make_response(template)
    response.headers['Content-Type'] = 'application/xml'
    return response
