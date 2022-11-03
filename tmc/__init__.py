import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from htmlmin.main import minify
from flask_caching import Cache
from flask_admin import Admin
from flask_admin.contrib.sqla import ModelView

cache = Cache(config={'CACHE_TYPE': 'simple', 'CACHE_DEFAULT_TIMEOUT': 3000})
db = SQLAlchemy()
migrate = Migrate()

from tmc import models, handlers, helpers


def _setup_url_maps(app):
    from .util import DateConverter
    app.url_map.default_subdomain = "www"
    app.url_map.converters['date'] = DateConverter


def _setup_blueprints(app):
    from tmc import blog, media, home, android, api
    app.register_blueprint(home.home, url_prefix='/')
    app.register_blueprint(blog.blog, url_prefix='/blog')
    app.register_blueprint(media.media, subdomain='media')
    app.register_blueprint(api.api, subdomain='api')
    app.register_blueprint(android.android, subdomain='android')


def _setup_minification(app):
    @app.after_request
    def response_minify(response):
        """
        minify html response to decrease site traffic
        """
        if response.content_type == u'text/html; charset=utf-8':
            response.set_data(
                minify(response.get_data(as_text=True))
            )

            return response
        return response


def _setup_admin(app):
    admin = Admin(app, name='TheMetaCity Media')
    admin.add_view(ModelView(models.MediaItem, db.session, 'Media Items'))
    admin.add_view(ModelView(models.VideoFile, db.session, 'Video Files'))
    admin.add_view(ModelView(models.VideoTrack, db.session, 'Video Tracks'))
    admin.add_view(ModelView(models.Video, db.session, 'Video'))
    admin.add_view(ModelView(models.AudioFile, db.session, 'Audio Files'))
    admin.add_view(ModelView(models.AudioTrack, db.session, 'Audio Tracks'))
    admin.add_view(ModelView(models.Audio, db.session, 'Audio'))
    admin.add_view(ModelView(models.Picture, db.session, 'Pictures'))
    admin.add_view(ModelView(models.Tags, db.session, 'Tags'))
    admin.add_view(ModelView(models.Code, db.session, 'Code'))
    admin.add_view(ModelView(models.Postcards, db.session, 'Postcards'))
    admin.add_view(ModelView(models.Licence, db.session, 'Licences'))


def create_app(config_file=None):
    app = Flask(__name__, static_url_path='', subdomain_matching=True)

    if config_file is not None:
        app.config.from_pyfile(config_file, silent=True)
    else:
        from config import Config
        app.config.from_object(Config())

    db.init_app(app)
    migrate.init_app(app, db, render_as_batch=True)
    cache.init_app(app)

    _setup_url_maps(app)
    _setup_blueprints(app)

    if os.environ['FLASK_ENV'] == 'development':
        _setup_admin(app)

    if os.environ['FLASK_ENV'] == 'production':
        _setup_minification(app)

    return app
