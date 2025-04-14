include /etc/nginx/snippets/themetacity-media-expires.conf;

upstream flask {
	server unix:///run/uwsgi/app/www.themetacity.test/socket;
}

server {
	listen 80 default_server;
	server_name www.themetacity.test;

	include /etc/nginx/snippets/themetacity-headers.conf;

	location fonts/ {
		root /srv/http/www.themetacity.test/tmc/static/;
		expires 30d;
		access_log off;
	}

	location js/ {
		root /srv/http/www.themetacity.test/tmc/js/;
		expires 30d;
		access_log off;
	}

	location css/ {
		root /srv/http/www.themetacity.test/tmc/css/;
		expires 30d;
		access_log off;
	}

	location images/ {
		root /srv/http/www.themetacity.test/tmc/images/;
		expires 30d;
		access_log off;
	}

	location / {
		include uwsgi_params;
		uwsgi_pass flask;
	}

	expires $expires;
}