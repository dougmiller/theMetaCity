server {
	listen 80 ;

	server_name api.themetacity.test;

	location / {
		client_max_body_size 10M;
		include uwsgi_params;
		uwsgi_pass unix:/tmp/theMetaCityTestSocket;
	}
}