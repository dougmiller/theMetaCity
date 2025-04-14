from tmc.extensions import db


class BasicModel(db.Model):
	__abstract__ = True