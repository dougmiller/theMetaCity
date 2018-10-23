from tmc import db


article_tags = db.Table('tags_joiner',
                       db.Column('tag_id', db.Integer, db.ForeignKey('tags.id')),
                       db.Column('article_id', db.Integer, db.ForeignKey('articles.id')),
                       db.PrimaryKeyConstraint('tag_id', 'article_id'))


class Tags(db.Model):
    __tablename__ = 'tags'
    id = db.Column(db.Integer, primary_key=True, unique=True)
    tag = db.Column(db.String, unique=True, nullable=False)

    def __repr__(self):
        return '<Tag: {}>'.format(self.tag)


class Article(db.Model):
    __tablename__ = 'articles'
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String, unique=True)
    url = db.Column(db.String, unique=True)
    type = db.Column(db.Enum('blog', 'workshop', name='type'), nullable=False, default='blog', server_default='blog')
    text = db.Column(db.String, nullable=False)
    creation_date = db.Column(db.DateTime, server_default=db.func.now())
    update_date = db.Column(db.DateTime, server_default=db.func.now(), server_onupdate=db.func.now())
    parent = db.relationship('Article', backref='Parent', lazy='dynamic')
    tags = db.relationship('Tags', secondary=article_tags, backref='articles')

    def __repr__(self):
        return '<Article {}: {}>'.format(self.id, self.title)