#!/bin/bash
PUBKEYLIST=pubkeys.txt
OUTFILE=validators_index.txt
ENDPOINT=127.0.0.1:5052
echo '' > $OUTFILE
for VAL in $(cat $PUBKEYLIST)
do
  curl -s -X GET "http://$ENDPOINT/eth/v1/beacon/states/head/validators/$VAL" | jq .data.index >> $OUTFILE
done
