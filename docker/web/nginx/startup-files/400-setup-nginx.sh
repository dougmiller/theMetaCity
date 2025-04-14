#!/bin/bash

mkdir /etc/nginx/sites-enabled

mkdir /srv/http
mkdir /srv/http/www.themetacity.test

chown www-data:www-data /srv/http/www.themetacity.test
