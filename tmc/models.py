from tmc import db

article_tags = db.Table('tags_joiner',
                        db.Column('tag_id', db.Integer, db.ForeignKey('tags.id')),
                        db.Column('article_id', db.Integer, db.ForeignKey('articles.id')),
                        db.PrimaryKeyConstraint('tag_id', 'article_id'))


class Tag(db.Model):
    __tablename__ = 'tags'
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    tag = db.Column(db.String, primary_key=True)

    def __repr__(self):
        return '<Tag: {}>'.format(self.tag)


class Article(db.Model):
    __tablename__ = 'articles'
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String, unique=True)
    url = db.Column(db.String, unique=True)
    type = db.Column(db.Enum('blog', 'workshop', name='type'), nullable=False, default='blog', server_default='blog')
    blurb = db.Column(db.String)
    text = db.Column(db.String, nullable=False)
    creation_date = db.Column(db.DateTime, server_default=db.func.now())
    update_date = db.Column(db.DateTime, server_default=db.func.now(), server_onupdate=db.func.now())
    parent = db.Column(db.Integer, db.ForeignKey('articles.id'))
    children = db.relationship('Article', remote_side=[id], backref='articles')
    tags = db.relationship('Tag', secondary=article_tags, backref='articles')

    def __repr__(self):
        return '<Article {}: {}>'.format(self.id, self.title)

    def build_date_byline(self):
        if self.creation_date < self.update_date:
            return 'Published: {}. Updated {}' \
                .format(self.creation_date.strftime("%d %B %y"), self.update_date.strftime("%d %B %y"))
        else:
            return 'Published: {}' \
                .format(self.creation_date.strftime("%d %B %y"))
