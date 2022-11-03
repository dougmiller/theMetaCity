from . import api


@api.route("/")
def api_index():
    return "123"
