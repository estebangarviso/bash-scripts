#!/bin/bash
cat <<EOF >${NGINX_AVAILABLE_VHOSTS_DIR}/${DOMAIN}.conf
server {

    # Ipv4
    listen 80;
    listen 443 ssl http2;
 
    # IPv6
    # listen [::]:80;

    # SSL Ipv4 & v6
    # listen 443 ssl;
    # listen [::]:443 ssl;

    # ssl_session_timeout 24h;
    # ssl_session_cache shared:SSL:10m;
    # ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    # ssl_ciphers ECDH+AESGCM:ECDH+AES256:ECDH+AES128:DH+3DES:RSA+3DES:AES128-SHA:!ADH:!AECDH:!MD5;
    # ssl_prefer_server_ciphers on;
    # Do not forget to create this file before with OpenSSL : "openssl dhparam -out ${ETC_DIR}/nginx/ssl/dhparam.pem 2048"
    # ssl_dhparam ${ETC_DIR}/nginx/ssl/dhparam.pem;

    # Your domain names here
    server_name ${DOMAIN} www.${DOMAIN};

    # Your website root location
    root ${WEB_DIR}/${DOMAIN}/;

    index index.php;

    #Log
    access_log ${LOGS_DIR}/nginx/${DOMAIN}/access.log;
    error_log ${LOGS_DIR}/nginx/${DOMAIN}/error.log;

    # Your admin folder
    set \$admin_dir /${CMS_ADMIN_DIRNAME};

    # Gzip Settings, convert all types.
    gzip on;
    gzip_vary on;
    gzip_proxied any;

    # Can be enhance to 5, but it can slow you server
    # gzip_comp_level    5;
    # gzip_min_length    256;

    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rss+xml
        application/vnd.geo+json
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/bmp
        image/svg+xml
        image/x-icon
        text/cache-manifest
        text/css
        text/plain
        text/vcard
        text/vnd.rim.location.xloc
        text/vtt
        text/x-component
        text/x-cross-domain-policy;
        # Supposed to be the case but we never know
        # text/html;
        
    gzip_disable "MSIE [1-6]\.(?!.*SV1)";
    
    # Symfony controllers
    location ~ /(international|_profiler|module|product|feature|attribute|supplier|combination|specific-price|configure)/(.*)\$ {
      	try_files \$uri \$uri/ /index.php?q=\$uri&\$args \$admin_dir/index.php\$is_args\$args;    	
    }


    # Redirect needed to "hide" index.php
    location / {
#        try_files \$uri \$uri/ /index.php\$uri&\$args;

        # Old image system ?
                    rewrite ^/api/?(.*)\$ /webservice/dispatcher.php?url=\$1 last;
                    rewrite ^/([0-9])(-[_a-zA-Z0-9-]*)?(-[0-9]+)?/.+\.jpg\$ /img/p/\$1/\$1\$2.jpg last;
                    rewrite ^/([0-9])([0-9])(-[_a-zA-Z0-9-]*)?(-[0-9]+)?/.+\.jpg\$ /img/p/\$1/\$2/\$1\$2\$3.jpg last;
                    rewrite ^/([0-9])([0-9])([0-9])(-[_a-zA-Z0-9-]*)?(-[0-9]+)?/.+\.jpg\$ /img/p/\$1/\$2/\$3/\$1\$2\$3\$4.jpg last;
                    rewrite ^/([0-9])([0-9])([0-9])([0-9])(-[_a-zA-Z0-9-]*)?(-[0-9]+)?/.+\.jpg\$ /img/p/\$1/\$2/\$3/\$4/\$1\$2\$3\$4\$5.jpg last;
                    rewrite ^/([0-9])([0-9])([0-9])([0-9])([0-9])(-[_a-zA-Z0-9-]*)?(-[0-9]+)?/.+\.jpg\$ /img/p/\$1/\$2/\$3/\$4/\$5/\$1\$2\$3\$4\$5\$6.jpg last;
                    rewrite ^/([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])(-[_a-zA-Z0-9-]*)?(-[0-9]+)?/.+\.jpg\$ /img/p/\$1/\$2/\$3/\$4/\$5/\$6/\$1\$2\$3\$4\$5\$6\$7.jpg last;
                    rewrite ^/([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])(-[_a-zA-Z0-9-]*)?(-[0-9]+)?/.+\.jpg\$ /img/p/\$1/\$2/\$3/\$4/\$5/\$6/\$7/\$1\$2\$3\$4\$5\$6\$7\$8.jpg last;
                    rewrite ^/([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])([0-9])(-[_a-zA-Z0-9-]*)?(-[0-9]+)?/.+\.jpg\$ /img/p/\$1/\$2/\$3/\$4/\$5/\$6/\$7/\$8/\$1\$2\$3\$4\$5\$6\$7\$8\$9.jpg last;
                    rewrite ^/c/([0-9]+)(-[_a-zA-Z0-9-]*)(-[0-9]+)?/.+\.jpg\$ /img/c/\$1\$2.jpg last;
                    rewrite ^/c/([a-zA-Z-]+)(-[0-9]+)?/.+\.jpg\$ /img/c/\$1.jpg last;
                    rewrite ^/([0-9]+)(-[_a-zA-Z0-9-]*)(-[0-9]+)?/.+\.jpg\$ /img/c/\$1\$2.jpg last;
                    try_files \$uri \$uri/ /index.php?\$args;  
    }
    
    error_page 404 /index.php?controller=404;

    # Static assets delivery optimisations
    add_header Strict-Transport-Security max-age=31536000;

    # Cloudflare / Max CDN fix
    location ~* \.(eot|otf|ttf|woff|woff2)\$ {
        add_header Access-Control-Allow-Origin *;
    }

    location ~* \.(css|js|docx|zip|pptx|swf|txt|jpg|jpeg|png|gif|swf|webp|flv|ico|pdf|avi|mov|ppt|doc|mp3|wmv|wav|mp4|m4v|ogg|webm|aac)\$ {
      expires max;
      log_not_found off;
      add_header Pragma public;
      add_header Cache-Control "public, must-revalidate, proxy-revalidate";
    }

    # Deny access to .htaccess .DS_Store .htpasswd etc
    location ~ /\. {
        deny all;
    }

    # PHP 7 FPM part
    location ~ [^/]\.php(/|\$) {

        fastcgi_index index.php;

        # Switch if needed
        include ${ETC_DIR}/nginx/fastcgi_params;
        # include fcgi.conf;

        # Do not forget to update this part if needed
        # fastcgi_pass 127.0.0.1:9000;  
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_keep_conn on;
        fastcgi_read_timeout 30s;
        fastcgi_send_timeout 30s;

        # In case of long loading or 502 / 504 errors
        # fastcgi_buffer_size 256k;
        # fastcgi_buffers 256 16k;
        # fastcgi_busy_buffers_size 256k;
        client_max_body_size ${NGINX_CLIENT_MAX_BODY_SIZE};

        # Temp file tweak
        fastcgi_max_temp_file_size 0;
        fastcgi_temp_file_write_size 256k;

   }

   # Allow access to robots.txt but disable logging every access
   location = /robots.txt {
       allow all;
       log_not_found off;
       access_log off;
   }


   # Prevent injection of php files in directories a user can upload stuff
   location /upload {
       location ~ \.php\$ { deny all; }
   }
   location /img {
       location ~ \.php\$ {  deny all;}
   }

   # Ban access to source code directories
   location ~ ^/(app|bin|cache|classes|config|controllers|docs|localization|override|src|tests|tools|translations|travis-scripts|vendor)/ {
      deny all;
   }

   # Banned file types
   location ~ \.(htaccess|yml|log|twig|sass|git|tpl)\$ {
       deny all;
   }

}
EOF
