server {
	listen 80;
	server_name themetacity.test;
	return 301 http://www.themetacity.test$request_uri;
}