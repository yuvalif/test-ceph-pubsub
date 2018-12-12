#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "usage: load_push <bucket> <sleep>"
      exit 1
fi

if [[ -z "$SYSTEM_ACCESS_KEY" || -z "$SYSTEM_SECRET_KEY" ]]; then
    echo "SYSTEM_ACCESS_KEY and SYSTEM_SECRET_KEY must be set"
    exit 1
fi

while true; do
    filename=`date +%s`.jpg
    echo hello > ${filename}
    s3cmd put ${filename} s3://$1 --access_key=${SYSTEM_ACCESS_KEY} --secret_key=${SYSTEM_SECRET_KEY}
    sleep $2
    rm -f ${filename}
done

