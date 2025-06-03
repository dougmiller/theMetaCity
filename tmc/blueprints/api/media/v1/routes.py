import json
from flask import jsonify, request, current_app
from sqlalchemy.sql.expression import func
from . import v1, api_response
from tmc.models.media import MediaAsset
from tmc.models.media.video import Video, VideoSelector
from tmc.schemas.media import MediaAssetSchema

from tmc.utils.responses import api_response
from tmc import db


@v1.route("/help/")
@v1.route("/")
def media_v1_index():
	# return openAPI swagger doc (YAML)

	return jsonify(
		{
			'info': 'Media api endpoints ',
			'routes': [
				{"endoint": "/help", "description": "This information"},
				{"endoint": "/video", "description": "Returns a video's details"},
			]
		}
	)


@v1.route("/all")
def all():
	all = db.session.execute(
		db.select(MediaAsset)
	).scalars().all()

	media_asset_schema = MediaAssetSchema(many=True)
		
	return api_response(
		data=media_asset_schema.dump(all)
	)
