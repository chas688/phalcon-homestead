#!/usr/bin/env bash

block="server {
    listen $3;
    server_name $1;
    set \$root_path '$2';
    root \$root_path;

    charset utf-8;
	
    index index.php index.html index.htm;
	
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/$1-error.log error;

    sendfile off;

    client_max_body_size 100m;
	
    try_files \$uri \$uri/ @rewrite;

    location @rewrite {
        rewrite ^/(.*)$ /index.php?_url=/\$1;
    }
	
    #location / {
    #    try_files \$uri \$uri/ /index.php?_url=\$uri&\$args;
    #}
	
    location ~ \.php$ {
        #try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        include fastcgi_params;
		
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
    }
	
    location ~* ^/(css|img|js|flv|swf|download)/(.+)$ {
        root \$root_path;
    }
	
    location ~ /\.ht {
        deny all;
    }
}
"

echo "$block" > "/etc/nginx/sites-available/$1"
ln -fs "/etc/nginx/sites-available/$1" "/etc/nginx/sites-enabled/$1"
service nginx restart
service php5-fpm restart
