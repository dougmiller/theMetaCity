from flask import Flask
from flask_marshmallow import Marshmallow


def init_app(app: Flask) -> None:
    ma = Marshmallow()
    ma.init_app(app)
