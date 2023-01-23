#!/bin/bash

./apply_configs.sh
tail -f /var/log/nginx/access.log & tail -f /var/log/nginx/error.log