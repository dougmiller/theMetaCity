from flask import Blueprint


edo = Blueprint(
    'edo',
    __name__,
    template_folder='templates',
    static_folder='static',
    static_url_path='',
)

from . import routes
from . import cli