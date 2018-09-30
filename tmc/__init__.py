from flask import Flask
from config import Config
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

tmc = Flask(__name__)
tmc.config.from_object(Config)
db = SQLAlchemy(tmc)
migrate = Migrate(tmc, db)

from tmc import routes, models
