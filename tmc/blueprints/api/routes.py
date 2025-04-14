from flask import jsonify
from . import api


@api.route("/help/")
@api.route("/")
def api_index():
    # Todo: Turn into Open API spec
    return jsonify(
        {
            'info': 'Basic info on tmc api ',
            'routes': [
                {'/help/': 'This information'},
                {'/edo/': 'Everyday Ordinary uploader'},
            ]
        }
    )
