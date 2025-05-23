#!/bin/bash

DOMAIN="portfolio.mlorenz.dev"
BUCKET="mlorenz-app-config"

# Create destination directories
mkdir -p /etc/ssl/certs /etc/ssl/private

# Download cert and key from S3
aws s3 cp s3://$BUCKET/ssl/cloudflare-origin.pem /etc/ssl/certs/cloudflare-origin.pem
aws s3 cp s3://$BUCKET/ssl/cloudflare-origin.key /etc/ssl/private/cloudflare-origin.key

# Secure private key
chmod 600 /etc/ssl/private/cloudflare-origin.key

# Write NGINX SSL and redirect config
cat > /etc/nginx/conf.d/ssl.conf <<EOF
server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/ssl/certs/cloudflare-origin.pem;
    ssl_certificate_key /etc/ssl/private/cloudflare-origin.key;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$http_connection;
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Restart nginx to apply changes
systemctl restart nginx
