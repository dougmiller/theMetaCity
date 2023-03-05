from ..model import UUIDModel
from .. import db


class EverydayOrdinary(UUIDModel):
    """
    UUID primary key for EDO
    """
    __bind_key__ = "edo"
    __tablename__ = "everyday_ordinary"
    __table_args__ = {'schema': 'everyday_ordinary'}

    contents = db.Column(db.String)

    def __str__(self):
        return f"{self.id}, {self.contents}"


class EverydayOrdinarySelector(EverydayOrdinary):
    """
    Read only connection to EDO
    """
    __bind_key__ = "edo_selector"

    def to_dict(self):
        return dict(id=self.id, content=self.contents)

    def __repr__(self):
        return self.id
