#!/bin/bash

if [[ -z "$SYSTEM_ACCESS_KEY" || -z "$SYSTEM_SECRET_KEY" ]]; then
    echo "SYSTEM_ACCESS_KEY and SYSTEM_SECRET_KEY must be set"
    exit 1
fi

set -ex

if [ -z "$BUILD_DIR" ]; then
    BUILD_DIR="."
fi

cd ${BUILD_DIR}

# run the cluster
MON=1 OSD=1 MDS=0 MGR=0 RGW=2 ../src/vstart.sh -n -d

# make sure to call 'source keys' first
RGW_HOST=localhost

# create realm "gold"
./bin/radosgw-admin realm create --rgw-realm=gold --default
# delete default zone group
./bin/radosgw-admin zonegroup delete --rgw-zonegroup=default
# create zonegroup "us"
./bin/radosgw-admin zonegroup create --rgw-zonegroup=us --endpoints=http://${RGW_HOST}:8000 --master --default
# create regular zone "us-east-1"
./bin/radosgw-admin zone create --rgw-zonegroup=us --rgw-zone=us-east-1 --endpoints=http://${RGW_HOST}:8000 \
    --access-key=$SYSTEM_ACCESS_KEY --secret=$SYSTEM_SECRET_KEY --default --master
# create user
./bin/radosgw-admin user create --uid=zone.user --display-name="Zone User" \
    --access-key=$SYSTEM_ACCESS_KEY --secret=$SYSTEM_SECRET_KEY --system

# kill the 2 rados gataways
pgrep radosgw | xargs kill

sleep 1

# rerun the main rgw with the regulat zone
./bin/radosgw -c ./ceph.conf --log-file=./out/radosgw.8000.log --admin-socket=./out/radosgw.8000.asok --pid-file=./out/radosgw.8000.pid \
    --debug-rgw=20 -n client.rgw --rgw_frontends="civetweb port=8000" --rgw-zone=us-east-1 --rgw-zonegroup=us

# create another zone for notifications
./bin/radosgw-admin zone create --rgw-zonegroup=us --rgw-zone=us-east-pubsub --endpoints=http://${RGW_HOST}:8001 --tier-type=pubsub \
    --access-key=$SYSTEM_ACCESS_KEY --secret=$SYSTEM_SECRET_KEY

# run another rgw in the pubsub zone
./bin/radosgw -c ./ceph.conf --log-file=./out/radosgw.8001.log --admin-socket=./out/radosgw.8001.asok --pid-file=./out/radosgw.8001.pid \
    --debug-rgw=20 -n client.rgw --rgw_frontends="civetweb port=8001" --rgw-zone=us-east-pubsub --rgw-zonegroup=us
   
# sync zones
./bin/radosgw-admin period update --commit

cd -

