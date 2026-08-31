from flask import Flask
import logging




def init_app(app: Flask) -> None:
    logging.basicConfig(
        level=logging.DEBUG,  # Capture DEBUG and higher (INFO, WARNING, ERROR, CRITICAL)
        format="{asctime} - {levelname} - {name} - {message}",
        style="{",  # Allows using modern curly-brace formatting
        handlers=[
            logging.StreamHandler(),  # Output to console
            logging.FileHandler("app.log", encoding="utf-8")  # Output to file
        ]
    )


def preflight(app: Flask) -> list[str]:
    errors: list[str] = []
    return errors
