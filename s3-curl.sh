#!/bin/bash

set -ex

if [ "$#" -eq 3 ]; then
    QUESTION_MARK=""
    port=$3
elif [ "$#" -eq 4 ]; then
    parameters=$3
    port=$4
    QUESTION_MARK="?"
else
    echo "usage: s3-curl <GET|PUT|DELETE> <resource> [parameters] <port>"
    exit 1
fi

if [[ -z "$SYSTEM_ACCESS_KEY" || -z "$SYSTEM_SECRET_KEY" ]]; then
    echo "SYSTEM_ACCESS_KEY and SYSTEM_SECRET_KEY must be set"
    exit 1
fi

verb=$1
resource=$2
host=localhost
dateValue=`date -Ru`
S3KEY=$SYSTEM_ACCESS_KEY
S3SECRET=$SYSTEM_SECRET_KEY
stringToSign="${verb}\n\n\n${dateValue}\n${resource}"
signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${S3SECRET} -binary | base64`

curl -X ${verb} \
    -H "Authorization: AWS ${S3KEY}:${signature}" \
    -H "Date: ${dateValue}" \
    -H "Host: ${host}:${port}" \
    http://${host}:${port}${resource}${QUESTION_MARK}${parameters} --verbose

echo -e

