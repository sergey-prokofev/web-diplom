FROM nginx:1.29.1
COPY ./index.html /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./images/example.jpg /tmp/images/example.jpg
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]