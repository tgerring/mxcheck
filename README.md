# MxCheck

Check to see if your validators are scheduled for sync commitee or proposal (within protocol limits). Avoid performing system updates or restarts when your node is scheduled for important duties

## Requirements

The BASH script uses the tool `jq` to encode/decode JSON. Install it with your package manager of choice.

A list of validators to check against is needed. Currently, this is defined as the INDEX of the validator (not pubkey). The validators should be seperated by line. Included is a script to convert pubkeys to indexes.

## Errata

There are lots of improvements that could be made, but this was a quick script I put together to help me ensure I know when NOT to perform maintenance, such as applying patches.

Developed using Ubuntu on Windows. This can run on your local machine and query the validator node. It does not need to run on the server (but the server needs to expose the REST API)

## Example Output (WIP)

```
2022-09-14 20:03:47   Epoch 146813 @ Slot 4698017
2022-09-14 20:03:47   Checking for sync duties
2022-09-14 20:03:47   Checking for proposals
2022-09-14 20:03:47   31 slots remaining / Approximately 372 seconds
2022-09-14 20:03:47
2022-09-14 20:03:47   Next Epoch 146814
2022-09-14 20:03:47   Checking for proposals
2022-09-14 20:03:48   Next Epoch expected to end in 756 seconds
2022-09-14 20:03:48
2022-09-14 20:03:48   Next Sync Committee @ Epoch 147069
2022-09-14 20:03:48   Checking for sync duties
2022-09-14 20:03:48
2022-09-14 20:03:48   Sleeping 372 seconds
```
