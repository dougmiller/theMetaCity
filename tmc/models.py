from tmc import db

class Tags(db.Model):
    __tablename__ = 'tags'
    id = db.Column(db.Integer, primary_key=True)
    tag = db.Column(db.String, nullable=False)

    def __repr__(self):
        return '<Tag: {}>'.format(self.tag)


tags_joiner = db.Table('tags_joiner',
                       db.Column('tag', db.Integer, db.ForeignKey('tags.id'), primary_key=True),
                       db.Column('article', db.Integer, db.ForeignKey('articles.id'), primary_key=True))


class Article(db.Model):
    __tablename__ = 'articles'
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String, unique=True)
    url = db.Column(db.String, unique=True)
    type = db.Column(db.Enum('blog', 'workshop', name='type'), nullable=False, default='blog', server_default='blog')
    text = db.Column(db.String)
    creation_date = db.Column(db.DateTime, server_default=db.func.now())
    update_date = db.Column(db.DateTime, server_default=db.func.now(), server_onupdate=db.func.now())
    parent = db.relationship('Article', backref='Parent', lazy='dynamic')
    tags = db.relationship('Tags', secondary=tags_joiner, backref='articles')

    def __repr__(self):
        return '<Article {}: {}>'.format(self.id, self.title)
