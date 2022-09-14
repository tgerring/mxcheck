# MxCheck

Check to see if your validators are scheduled for sync commitee or proposal (within protocol limits)
Avoid performing system updates or restarts when your node is scheduled for important duties

## Requirements

The BASH script uses the tool `jq` to encode/decode JSON. Install it with your package manager of choice.

## Errata

There are lots of improvements that could be made, but this was a quick script I put topgether to help me ensure I know when NOT to perform maintenance, such as applying patches.
Developed using Ubuntu on Windows. This can run on your local machine and query the validator node. It does not need to run on the server (but the server needs to expose the REST API)
