#!/bin/bash
echo "Web application is starting up..."
if [[ ! -e /tmp/webapp/.env ]]; then
  touch /tmp/webapp/.env
fi

if [[ ! -e "/var/run/webapp_configured" ]]; then
  echo "Configuring web application..."
  {
    echo "DB_USER=${DB_USER}"
    echo "DB_PASSWORD=${DB_PASSWORD}"
    echo "DB_HOST=${DB_HOST}"
    echo "DB_NAME=${DB_NAME}"
  } >> /tmp/webapp/.env

  touch /var/run/webapp_configured
else
  echo "Web application is already configured."
fi

sudo systemctl stop csye-6225
sudo systemctl start csye-6225
sudo systemctl status csye-6225
echo "Web application is configured."
echo "Web application is running."
