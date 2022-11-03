from flask import render_template


def error_page():
    return render_template('500.html'), 500


def page_not_found():
    return render_template('404.html'), 404


class Handlers(object):

    def __init__(self, app):
        app.register_error_handler(400, page_not_found)
        app.register_error_handler(500, error_page)
