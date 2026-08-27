import os

from flask import Flask, Response

from tmc import extensions
from tmc.extensions import configs, db, handlers, jinja_filters
from tmc.extensions.alembic import init_app as init_alembic


def _setup_url_maps(app) -> None:
    from .utils.converters import DateConverter

    app.url_map.default_subdomain = "www"
    app.url_map.converters["date"] = DateConverter


def _setup_blueprints(app) -> None:
    from tmc.blueprints import api, blog, edo, homepage, media

    app.register_blueprint(homepage, url_prefix="/")
    app.register_blueprint(blog, url_prefix="/blog")
    app.register_blueprint(media, subdomain="media")
    app.register_blueprint(api, subdomain="api")
    app.register_blueprint(edo, subdomain="everydayordinary")


def _setup_cli(app) -> None:
    from tmc.cli import assets, blog, edo, tmc_app

    app.cli.add_command(edo)
    app.cli.add_command(blog)
    app.cli.add_command(assets)
    app.cli.add_command(tmc_app)


def _setup_minification(app) -> None:
    import minify_html

    @app.after_request
    def response_minify(response) -> Response:
        """
        minify html response to decrease site traffic
        """
        if response.content_type == "text/html; charset=utf-8":
            response.set_data(minify_html.minify(response.get_data(as_text=True)))

            return response
        return response


def create_app(config=None) -> Flask:
    app: Flask = Flask(
        import_name=__name__,
        template_folder="templates",
        subdomain_matching=True,
    )

    if config is None:
        configs.init_app(app)
    else:
        # Test / explicit config: bypass the .env + .pgpass pipeline.
        app.config.from_mapping(config)

    extensions.preflight(app)
    extensions.init_app(app)

    # debug_toolbar.init_app(app)
    init_alembic(app)
    jinja_filters.register_filters(app)
    handlers.init_app(app)

    _setup_url_maps(app)
    _setup_blueprints(app)
    _setup_cli(app)

    if os.environ.get("FLASK_ENV") == "production":
        _setup_minification(app)

    return app


__all__ = ["create_app", "db"]
