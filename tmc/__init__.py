import os
from flask import Flask
from config import Config
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from htmlmin.main import minify
from flask_caching import Cache
from flask_admin import Admin
from flask_admin.contrib.sqla import ModelView

cache = Cache(config={'CACHE_TYPE': 'simple', 'CACHE_DEFAULT_TIMEOUT': 300})
tmc = Flask(__name__, static_url_path='', subdomain_matching=True)
tmc.config.from_object(Config())
db = SQLAlchemy(tmc)
migrate = Migrate(tmc, db)
cache.init_app(tmc)

from tmc import models, helpers, handlers, blog, media, home, api

tmc.url_map.default_subdomain = "www"
tmc.register_blueprint(home.home, url_prefix='/')
tmc.register_blueprint(blog.blog, url_prefix='/blog')
tmc.register_blueprint(media.media, subdomain='media')
tmc.register_blueprint(api.api, subdomain='api')


if os.environ['FLASK_ENV'] == 'production':
    @tmc.after_request
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


if os.environ['FLASK_ENV'] == 'development':
    admin = Admin(tmc, name='TheMetaCity Media')
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
