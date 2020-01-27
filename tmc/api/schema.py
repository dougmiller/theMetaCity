import graphene
from graphene_sqlalchemy import SQLAlchemyObjectType, SQLAlchemyConnectionField
from ..models import Postcards


class PostcardsObject(SQLAlchemyObjectType):
    class Meta:
        model = Postcards
        interfaces = (graphene.relay.Node, )


class Query(graphene.ObjectType):
    node = graphene.relay.Node.Field()
    posters = SQLAlchemyConnectionField(PostcardsObject)


schema = graphene.Schema(query=Query)
