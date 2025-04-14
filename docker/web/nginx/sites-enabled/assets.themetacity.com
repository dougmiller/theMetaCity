include /etc/nginx/snippets/themetacity-media-expires.conf;

server {
	listen 80;

	server_name assets.themetacity.test;

	root /srv/http/assets.themetacity.test;

	location / {
		autoindex on;
	}

	expires $expires;
}