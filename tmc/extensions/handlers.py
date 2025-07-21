from flask import render_template


class Handlers:
    def __init__(self, app=None):
        if app is not None:
            pass

    def init_app(self, app):
        def page_not_found(e):
            return render_template('404.html'), 404

        def error_page(e):
            return render_template('500.html'), 500

        app.register_error_handler(404, page_not_found)
        app.register_error_handler(500, error_page)

handlers = Handlers()
