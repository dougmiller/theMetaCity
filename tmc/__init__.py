import os
from flask import Flask
from tmc.extensions import db, handlers, jinja_filters, cache, configs, debug_toolbar


def _setup_url_maps(app):
    from .utils.converters import DateConverter
    #app.url_map.default_subdomain = "www"
    app.url_map.converters['date'] = DateConverter


def _setup_blueprints(app):
    from tmc.blueprints import home, blog, media, edo, api
    app.register_blueprint(home, url_prefix='/')
    app.register_blueprint(blog, url_prefix='/blog')
    app.register_blueprint(media, subdomain='media')
    app.register_blueprint(api, subdomain='api')
    app.register_blueprint(edo, subdomain='everydayordinary')


def _setup_cli(app):
    from tmc.cli import edo, blog, assets, tmc_app
    app.cli.add_command(edo)
    app.cli.add_command(blog)
    app.cli.add_command(assets)
    app.cli.add_command(tmc_app)


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


def create_app():
    app = Flask(
        __name__,
        #static_url_path='',
        #subdomain_matching=True,
        template_folder="templates",
    )

    configs.init_app(app)
    #debug_toolbar.init_app(app)
    db.init_app(app)
    cache.init_app(app)
    jinja_filters.register_filters(app)
    handlers.init_app(app)

    _setup_url_maps(app)
    _setup_blueprints(app)
    _setup_cli(app)

    if os.environ['FLASK_ENV'] == 'production':
        _setup_minification(app)

    return app
