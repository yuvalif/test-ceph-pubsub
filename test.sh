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

# sync zones
bin/radosgw-admin period update --commit

# pull the events
./s3-curl.sh GET "/subscriptions/${SUBSCRIPTION}" "events" 8001

# run an HTTP server receiving POST requests in the background
# for now it has to run on port 80 - hence the sudo
sudo ./SimpleHTTPPostServer.py 80 > http-server.log &

# define push subscription
./s3-curl.sh PUT "/subscriptions/sub2" "topic=${TOPIC}&push-endpoint=http://localhost/something/" 8001

touch fish3.jpg

# put another file in the bucket
s3cmd put ./fish3.jpg s3://${BUCKET} --access_key=$SYSTEM_ACCESS_KEY --secret_key=$SYSTEM_SECRET_KEY

rm fish3.jpg

# cehck the http server
cat http-server.log
