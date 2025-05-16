import os
from flask import Flask
from tmc.extensions import db, ma, jinja_filters, cache, configs
from tmc import handlers


def _setup_url_maps(app):
    from .util import DateConverter
    app.url_map.default_subdomain = "www"
    app.url_map.converters['date'] = DateConverter


def _setup_blueprints(app):
    from tmc.blueprints import home, blog, media, edo, api
    app.register_blueprint(home, url_prefix='/')
    app.register_blueprint(blog, url_prefix='/blog')
    app.register_blueprint(media, subdomain='media')
    app.register_blueprint(api, subdomain='api', url_prefix='/')
    #app.register_blueprint(android.android, subdomain='android')
    app.register_blueprint(edo, subdomain='everydayordinary')


def _setup_minification(app):
    from htmlmin.main import minify

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
    from tmc import models
    from flask_admin import Admin
    from flask_admin.contrib.sqla import ModelView
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


def create_app():
    app = Flask(__name__, static_url_path='', subdomain_matching=True)
   
    configs.init_app(app)
    db.init_app(app)
    cache.init_app(app)
    jinja_filters.register_filters(app)

    _setup_url_maps(app)
    _setup_blueprints(app)

    #if os.environ['FLASK_ENV'] == 'development':
    #    _setup_admin(app)

    if os.environ['FLASK_ENV'] == 'production':
        _setup_minification(app)

    return app
