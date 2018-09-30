from tmc import db
import enum

class ArticleType(enum.Enum):
    BLOG = 'blog'
    WORKSHOP = 'workshop'

class Article(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String, unique=True)
    url = db.Column(db.String, unique=True)
    type = db.Column(db.Enum(ArticleType))
    text = db.Column(db.String)
    date = db.Column(db.DateTime)

    def __repr__(self):
        return '<Article: {}>'.format(self.title)

class Tags(db.model):
    id = db.Column(db.Integer, primary_key=True)
    tag = db.Column(db.String, unique=True)

    def __repr__(self):
        return '<Tag: {}>'.format(self.tag)

class ArticleTags(db.model):
    article = db.Column(db.Integer, primary_key=True)
    tag = db.Column(db.Integer, primary_key=True)

