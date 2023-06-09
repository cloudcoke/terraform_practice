#!/usr/bin/env bash

# 기본값
DOMAIN="www.cloudcoke.site"
EMAIL="cloudcoke.dev@gmail.com"

# 입력된 인자가 있는지 확인하고 변수 변경
while getopts "d:m:" opt; do
    case $opt in
        d) # -d (도메인 주소)
            DOMAIN=$OPTARG
            ;;
        m) # -m (이메일 주소)
            EMAIL=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

# 패키지 설치
sudo apt-get update
sudo apt-get install nginx snapd -y

# 부팅 시 자동 시작
sudo systemctl enable nginx

# nginx 설정 파일 경로
NGINX_CONF="/etc/nginx/sites-available/default"

# nginx 파일 수정
sudo cp $NGINX_CONF $NGINX_CONF.bak
sudo sed -i 's|root /var/www/html;|root /home/ubuntu/www/build;|g' $NGINX_CONF
sudo sed -i 's|index index.html index.htm index.nginx-debian.html;|index index.html;|g' $NGINX_CONF
sudo sed -i 's|try_files $uri $uri/ =404;|if ( !-e $request_filename ) {rewrite ^(.*)$ /index.html break;}|g' $NGINX_CONF

# 테스트를 위한 작업
mkdir -p www/build
echo "front server" > www/build/index.html

# https를 위한 작업
sudo snap install core
sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# nginx https 인증서 적용
sudo certbot --nginx -d $DOMAIN -m $EMAIL --non-interactive --agree-tos

# 인증서 갱신 확인
sudo certbot renew --dry-run

# 인증서 갱신 cron 등록
cat <(crontab -l 2>/dev/null) <(echo '0 18 1 * * sudo certbot renew --renew-hook="sudo systemctl restart nginx"') | crontab - > /dev/null 2>&1

# nginx 재시작
sudo systemctl restart nginx