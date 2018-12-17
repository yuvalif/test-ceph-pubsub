#!/bin/bash

if [[ -z "$SYSTEM_ACCESS_KEY" || -z "$SYSTEM_SECRET_KEY" ]]; then
    echo "SYSTEM_ACCESS_KEY and SYSTEM_SECRET_KEY must be set"
    exit 1
fi

set -ex

BUCKET=fishbucket
TOPIC=fish
SUBSCRIPTION=sub1

# create a bucket
s3cmd mb s3://${BUCKET} --access_key=$SYSTEM_ACCESS_KEY --secret_key=$SYSTEM_SECRET_KEY

touch fish1.jpg
touch fish2.jpg

# put files in the bucket
s3cmd put ./fish1.jpg ./fish2.jpg s3://${BUCKET} --access_key=$SYSTEM_ACCESS_KEY --secret_key=$SYSTEM_SECRET_KEY

rm fish1.jpg fish2.jpg

# create a topic
./s3-curl.sh PUT "/topics/${TOPIC}" 8001

# associate the topic with a bucket
./s3-curl.sh PUT "/notifications/bucket/${BUCKET}" "topic=${TOPIC}" 8001

# create a pull subscription
./s3-curl.sh PUT "/subscriptions/${SUBSCRIPTION}" "topic=${TOPIC}" 8001

# pull the events - should return empty
./s3-curl.sh GET "/subscriptions/${SUBSCRIPTION}" "events" 8001 | python -m json.tool

# run an HTTP server receiving POST requests in the background
./SimpleHTTPPostServer.py 8080 &> http-server.log &

# define push subscription
./s3-curl.sh PUT "/subscriptions/sub2" "topic=${TOPIC}&push-endpoint=http://localhost:8080/something/" 8001

touch fish3.jpg

# put another file in the bucket
s3cmd put ./fish3.jpg s3://${BUCKET} --access_key=$SYSTEM_ACCESS_KEY --secret_key=$SYSTEM_SECRET_KEY

rm fish3.jpg

# check the http server - should see events there
cat http-server.log

