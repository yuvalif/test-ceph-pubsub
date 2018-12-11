# test-ceph-pubsub
This is intendent to run on the local "vstart" ceph cluster.
First step would be to set the ```BUILD_DIR``` variable to the location of the ```build``` directory.
Second step would be to source the keys (used throughout the scripts): ```source keys```.

To start the setup, call ```./setup.sh```
Then, to run the tests, call: ```./test.sh```
To execute higher rate tests use: ```./load_push.sh <sleep> <bucket>```
> Notes:
> - "sleep" in seconds
> - "bucket" should exists, as well as the topics, notifications and subscriptiosn for the endpoint
> - HTTP endpoint should be up and running

