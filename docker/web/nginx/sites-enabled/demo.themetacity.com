server {
	listen 80;
	server_name demo.themetacity.test;

	root /srv/http/demo.themetacity.test;

	location / {
		autoindex on;
	}
}