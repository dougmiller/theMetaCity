from flask import Blueprint

android = Blueprint(
    'android',
    __name__,
    template_folder='templates',
    static_folder='static',
    static_url_path='',
)

from . import routes

