#!/bin/bash

# nginx 설치
sudo apt update -y
sudo apt install nginx -y
sudo systemctl enable nginx

NGINX_CONF="/etc/nginx/sites-available/default"

# nginx 설정
sudo cp $NGINX_CONF $NGINX_CONF.bak

sudo sed -i 's|root /var/www/html;|root /home/ubuntu/www/build;|g' $NGINX_CONF
sudo sed -i 's|index index.html index.htm index.nginx-debian.html;|index index.html;|g' $NGINX_CONF
sudo sed -i 's|try_files $uri $uri/ =404;|if ( !-e $request_filename ) {rewrite ^(.*)$ /index.html break;}|g' $NGINX_CONF

mkdir -p /home/ubuntu/www/build

# 테스트용 파일 생성
HOSTNAME=$(hostname -f)
echo "<h1>Hello World from $HOSTNAME</h1>" > /home/ubuntu/www/build/index.html

sudo systemctl restart nginx
