from flask import Flask
from config import Config
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from htmlmin.main import minify

tmc = Flask(__name__)
tmc.config.from_object(Config())
db = SQLAlchemy(tmc)
migrate = Migrate(tmc, db)

from tmc import routes, models, helpers


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
