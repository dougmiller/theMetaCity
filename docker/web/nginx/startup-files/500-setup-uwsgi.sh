#!/bin/bash

mkdir -p /srv/virtualenv/
python -m venv /srv/virtualenv/theMetaCity

cd /srv/virtualenv/theMetaCity
source bin/activate

pip install -r /srv/http/www.themetacity.test/requirements.txt

#service uwsgi start