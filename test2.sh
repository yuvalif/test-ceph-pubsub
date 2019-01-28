#!/bin/bash

# test for HTTP endpoint
# HTTP server should run on port 8080 before the test
# see: SimpleHTTPPostServer.py

if [[ -z "$SYSTEM_ACCESS_KEY" || -z "$SYSTEM_SECRET_KEY" ]]; then
    echo "SYSTEM_ACCESS_KEY and SYSTEM_SECRET_KEY must be set"
    exit 1
fi

set -ex

BUCKET=fishbucket2
TOPIC=fish2
SUBSCRIPTION=sub2

# create a bucket
s3cmd mb s3://${BUCKET} --access_key=$SYSTEM_ACCESS_KEY --secret_key=$SYSTEM_SECRET_KEY

touch fish1.jpg
touch fish2.jpg

# put files in the bucket
s3cmd put ./fish1.jpg ./fish2.jpg s3://${BUCKET} --access_key=$SYSTEM_ACCESS_KEY --secret_key=$SYSTEM_SECRET_KEY

rm fish1.jpg fish2.jpg

# wait for sync
sleep 5

# create a topic
./s3-curl.sh PUT "/topics/${TOPIC}" 8001

# associate the topic with a bucket
./s3-curl.sh PUT "/notifications/bucket/${BUCKET}" "topic=${TOPIC}" 8001

# define push subscription
./s3-curl.sh PUT "/subscriptions/${SUBSCRIPTION}" "topic=${TOPIC}&push-endpoint=http://localhost:8080/something/" 8001

touch fish3.jpg
touch fish4.jpg

# put another file in the bucket
s3cmd put ./fish3.jpg ./fish4.jpg s3://${BUCKET} --access_key=$SYSTEM_ACCESS_KEY --secret_key=$SYSTEM_SECRET_KEY

rm fish3.jpg
rm fish4.jpg

