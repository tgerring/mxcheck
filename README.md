# MxCheck

Check to see if your validators are scheduled for sync commitee or proposal (within protocol limits). Avoid performing system updates or restarts when your node is scheduled for important duties

## Requirements

The BASH script uses the tool `jq` to encode/decode JSON. Install it with your package manager of choice.

A list of validators to check against is needed. Currently, this is defined as the INDEX of the validator (not pubkey). The validators should be seperated by line. Included is a script to convert pubkeys to indexes.

## Arguments

```
-v   VERBOSE=false
-d   DAEMON=false
-e   ENDPOINT=127.0.0.1:5052
```

Enabling daemon mode will sleep the script between epochs. By default the script will run once and exit.

## Errata

There are lots of improvements that could be made, but this was a quick script I put together to help me ensure I know when NOT to perform maintenance, such as applying patches.

Developed using Ubuntu on Windows. This can run on your local machine and query the validator node. It does not need to run on the server (but the server needs to expose the REST API)

## Example Output (WIP)

```
2022-09-18 14:37:57   ENDPOINT=127.0.0.1:5052 DAEMON=true VERBOSE=true
2022-09-18 14:37:57   Loaded 5 validators
2022-09-18 14:37:58
2022-09-18 14:37:58   [curr] Slot 4725187 in Epoch 147662. 29 slots remaining
2022-09-18 14:37:58   Found 0 validators assigned to propose a block
2022-09-18 14:37:58   Found 0 validators assigned to sync committee
2022-09-18 14:37:58   [curr] 348 seconds remaining in Epoch 147662
2022-09-18 14:37:58
2022-09-18 14:37:58   [next] Epoch 147663 expected to start  2022-09-18 14:43:12
2022-09-18 14:37:58   Found 0 validators assigned to propose a block
2022-09-18 14:37:58   [next] Epoch 147663 expected to end by 2022-09-18 14:49:36
2022-09-18 14:37:58
2022-09-18 14:37:58   [futr] Sync Committee scheduled for Epoch 147712 (2022-09-18 19:56:48)
2022-09-18 14:37:58   Found 1 validators assigned to sync committee
2022-09-18 14:37:58   ******** 422792 will be on sync committee from 147712 through 147967 ********
2022-09-18 14:37:58   [futr] Sync Committee to end after  Epoch 147967 (2022-09-19 23:15:12)
2022-09-18 14:37:58
2022-09-18 14:37:58   Sleeping until next epoch (348 secs)
2022-09-18 14:37:58
2022-09-18 14:37:58
2022-09-18 14:38:41   Cleanup
```
