from flask import Flask, render_template


def init_app(app: Flask) -> None:
    def page_not_found(e) -> tuple[str, int]:
        return render_template("404.html"), 404

    def error_page(e) -> tuple[str, int]:
        return render_template("500.html"), 500

    app.register_error_handler(404, page_not_found)
    app.register_error_handler(500, error_page)
