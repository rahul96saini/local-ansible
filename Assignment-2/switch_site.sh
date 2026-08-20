#!/bin/bash
MIN=$(date +%s)
BLOCK=$(( (MIN / 120) % 2 ))

if [ $BLOCK -eq 0 ]; then
    ln -sfn /var/www/tanya /var/www/current
else
    ln -sfn /var/www/heena /var/www/current
fi

systemctl reload apache2
