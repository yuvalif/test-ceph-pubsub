#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "usage: load_push <bucket> <rate>"
      exit 1
fi

if [[ -z "$SYSTEM_ACCESS_KEY" || -z "$SYSTEM_SECRET_KEY" ]]; then
    echo "SYSTEM_ACCESS_KEY and SYSTEM_SECRET_KEY must be set"
    exit 1
fi


batch_size=50
sleep_time=`bc <<< "scale=2;$batch_size/$2"`
max_objects=10000

while true; do
    ((i++))
    prefix=`date +%s`${i}
    ./create-files.sh ${batch_size} ${prefix}
    s3cmd put ./${prefix}* s3://$1 --access_key=${SYSTEM_ACCESS_KEY} --secret_key=${SYSTEM_SECRET_KEY}
    sleep ${sleep_time}
    rm -f ./${prefix}*
    rem=$((($i*${batch_size})%${max_objects}))
    if [[ $rem -eq 0 ]]; then 
        s3cmd rm s3://$1/* --access_key=${SYSTEM_ACCESS_KEY} --secret_key=${SYSTEM_SECRET_KEY}
    fi
done

