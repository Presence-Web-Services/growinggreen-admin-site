FROM nginx:alpine
COPY public /usr/share/nginx/html
COPY nginx_vhost.conf /etc/nginx/conf.d/default.conf
