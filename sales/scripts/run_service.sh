#!/bin/sh

PID_FILE="/tmp/sales.pid"

# Pid file is needless in container enviroment
rm -f $PID_FILE

/sales -pid-file=$PID_FILE &

/usr/sbin/nginx -g "daemon off;"
