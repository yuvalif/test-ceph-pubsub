#!/bin/bash

# test pubsub without any endpoint

if [[ -z "$SYSTEM_ACCESS_KEY" || -z "$SYSTEM_SECRET_KEY" ]]; then
    echo "SYSTEM_ACCESS_KEY and SYSTEM_SECRET_KEY must be set"
    exit 1
fi

set -ex

BUCKET=fishbucket1
TOPIC=fish1
SUBSCRIPTION=sub1

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

# create a pull subscription
./s3-curl.sh PUT "/subscriptions/${SUBSCRIPTION}" "topic=${TOPIC}" 8001

# pull the events - should return empty
./s3-curl.sh GET "/subscriptions/${SUBSCRIPTION}" "events" 8001 | python -m json.tool

touch fish3.jpg
touch fish4.jpg

# put another file in the bucket
s3cmd put ./fish3.jpg s3://${BUCKET} --access_key=$SYSTEM_ACCESS_KEY --secret_key=$SYSTEM_SECRET_KEY

rm fish3.jpg
rm fish4.jpg

# wait for sync
sleep 5

# pull the events - should return fish3.jpg and fish4.jpg
./s3-curl.sh GET "/subscriptions/${SUBSCRIPTION}" "events" 8001 | python -m json.tool

