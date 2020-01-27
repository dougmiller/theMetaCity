from flask_graphql import GraphQLView
from . import api, schema

api.add_url_rule(
    '/',
    view_func=GraphQLView.as_view(
        'graphql',
        schema=schema.schema,
        graphiql=True
    )
)
