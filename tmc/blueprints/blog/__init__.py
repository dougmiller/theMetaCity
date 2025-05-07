from flask import Blueprint


blog = Blueprint(
    'blog',
    __name__,
    template_folder='templates',
    static_folder='static',
    static_url_path='',
)

from . import routes, helpers, cli
