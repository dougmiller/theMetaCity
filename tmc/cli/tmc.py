from flask.cli import AppGroup, with_appcontext
from flask import current_app
from jinja2 import ChoiceLoader, FileSystemLoader, PrefixLoader


tmc_app = AppGroup(
    'tmc',
    help="Manage TMC",
    short_help="TMC specific behind the scenes items",
)

@tmc_app.command("templates")
def print_template_paths():
    loader = current_app.jinja_loader

    def _walk_loader(loader, indent=0):
        prefix = " " * indent
        if isinstance(loader, ChoiceLoader):
            print(f"{prefix}ChoiceLoader:")
            for sub in loader.loaders:
                _walk_loader(sub, indent + 2)
        elif isinstance(loader, PrefixLoader):
            print(f"{prefix}PrefixLoader:")
            for key, sub_loader in loader.mapping.items():
                print(f"{prefix}  '{key}':")
                _walk_loader(sub_loader, indent + 4)
        elif isinstance(loader, FileSystemLoader):
            print(f"{prefix}FileSystemLoader: {loader.searchpath}")
        else:
            print(f"{prefix}{loader.__class__.__name__}")

    _walk_loader(loader)
