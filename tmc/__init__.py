import os
from flask import Flask
from config import Config
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from htmlmin.main import minify
from flask_caching import Cache

cache = Cache(config={'CACHE_TYPE': 'simple', 'CACHE_DEFAULT_TIMEOUT': 300})
tmc = Flask(__name__, static_url_path='')
tmc.config.from_object(Config())
db = SQLAlchemy(tmc)
migrate = Migrate(tmc, db)
cache.init_app(tmc)

from tmc import routes, models, helpers, blog

tmc.register_blueprint(blog.blog, url_prefix='/blog')


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
