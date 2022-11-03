from . import edo


@edo.route("/")
def edo_index():
    return "abc"
