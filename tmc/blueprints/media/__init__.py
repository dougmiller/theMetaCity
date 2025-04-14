import os
from flask import Blueprint
from flask_caching import Cache

cache = Cache(config={'CACHE_TYPE': 'simple', 'CACHE_DEFAULT_TIMEOUT': 0})

media = Blueprint(
    'media',
    __name__,
    template_folder='templates',
    static_folder='static',
    static_url_path='',
)

from . import routes


@media.context_processor
def custom_importer():
    def import_svg(name):
        f = open(os.path.join(os.path.abspath(os.path.dirname(__file__)), 'static', 'images', name + '.svg'))
        data = f.readlines()[1:]
        f.close()
        return ''.join(data)
    return dict(import_svg=import_svg)