#!/bin/bash
#################################
#
# TODO better timing wrt checking at first epoch tick instead of guessing intervals for committee sync
#
#################################

# TODO convert to command-line arguments
VALDINXS='validators_index.txt'
ENDPOINT='127.0.0.1:5052'
VERBOSE=true
REPORT_FILE='report.txt'
DIFF_FILE='/tmp/difflist'

# init
trap cleanup SIGINT SIGTERM
EPOCHS_PER_SYNC_COMMITTEE_PERIOD=256
SYNC_COMMITTEE_SIZE=512
SECONDS_PER_SLOT=12
SLOTS_PER_EPOCH=32
EPOCH_TIME=$((SECONDS_PER_SLOT * SLOTS_PER_EPOCH))

getCurrentSlot() {
  echo $(curl -s -X GET "http://$ENDPOINT/eth/v1/beacon/headers/head" | jq .data.header.message.slot -r)
}

getEpochFromSlot() {
  local slot=$1
  echo $((slot / SLOTS_PER_EPOCH))
}


main () {
  logit ''
  local curslot=$(getCurrentSlot)
  local curepoc=$(getEpochFromSlot curslot)
  local nexepoc=$((curepoc + 1))
  local nexsync=$((curepoc + EPOCHS_PER_SYNC_COMMITTEE_PERIOD))
  
  local slotstogo=$((nexepoc * SLOTS_PER_EPOCH - curslot))
  local secs=$((slotstogo * SECONDS_PER_SLOT))
  #local future=`date --date="+secs seconds" '+%Y-%m-%d %T'`

  logit "Epoch $curepoc @ Slot $curslot"
  checkSyncCommittee $curepoc
  checkProposals $curepoc
  logit "$slotstogo slots remaining / Approximately $secs seconds"

  logit ''
  logit "Next Epoch $nexepoc "
  checkProposals $nexepoc
  farsecs=$((SLOTS_PER_EPOCH * SECONDS_PER_SLOT + secs))
  logit "Next Epoch expected to end in $farsecs seconds"

  logit ''
  logit "Next Sync Committee @ Epoch $nexsync"
  checkSyncCommittee $nexsync

  chill $((slotstogo))
}


checkValidators(){
  # check that the validator list is not empty, otherwise no matches will be found
  VALCONT=$(grep -e "$" -c $VALDINXS)
  if [ VALCONT == 0 ]; then
    logit 'Validator list empty'
    exit 2
  fi
  logit "Loaded $VALCONT validators" true
}

checkProposals() {
  logit "Checking for proposals"
  local epoch=$1
  local propfile="proposals_${epoch}"
  local tempfile="${DIFF_FILE}_pro_${epoch}"

  curl -s -X GET "http://$ENDPOINT/eth/v1/validator/duties/proposer/$epoch" | jq .data | jq '.[].validator_index' -c -S -r > $propfile

  # compare the committee list against local validators
  grep -Fi -f $VALDINXS $propfile > $tempfile
  local DIFFCONT=$(grep -e "$" -c $tempfile)

  if [ $DIFFCONT -ne 0 ]; then
    logit "******** Found $DIFFCONT validators assigned to propose a block" true
    for VALINX in $(cat $tempfile)
    do
      logit "******** $VALINX" true
    done
  fi
  
  rm $tempfile
  rm $propfile
} 

checkSyncCommittee() {
  logit "Checking for sync duties"
  local epoch=$1
  local commfile="synccomittee_${epoch}"
  local tempfile="${DIFF_FILE}_com_${epoch}"

  curl -s -X GET "http://$ENDPOINT/eth/v1/beacon/states/head/sync_committees?epoch=$epoch" | jq .data.validators | jq '.[]' -c -S -r > $commfile

  # check that committee count is the right size
  local COMMCONT=$(grep -e "$" -c $commfile)
  if [ $COMMCONT -ne $SYNC_COMMITTEE_SIZE ]; then
    echo "Found $COMMCONT but was expecting $SYNC_COMMITTEE_SIZE"
    exit 1
  fi

  # compare the committee list against local validators
  grep -Fi -f $VALDINXS $commfile > $tempfile
  local DIFFCONT=$(grep -e "$" -c $tempfile)

  if [ $DIFFCONT -ne 0 ]; then
    logit "******** Found $DIFFCONT validators assigned to sync committee" true
    for VALINX in $(cat $tempfile)
    do
      logit "******** $VALINX" true
    done
  fi
  rm $tempfile
  rm $commfile
}

logit () {
  if [[ $VERBOSE == true || $2 == true ]]; then
    echo  "`date +"%Y-%m-%d %T"`   $1"
  fi
}

cleanup () {
  logit 'Cleanup'
  exit
}

chill () {
  # sleep until next epoch
  SLEEP_TIME=$(($1 * SECONDS_PER_SLOT)) 

  logit ''
  logit "Sleeping $SLEEP_TIME seconds"
  logit ''
  logit ''

  sleep $SLEEP_TIME
}


# truncate report file before using
echo '' > $REPORT_FILE
checkValidators
while [ true ]; do
  main
done


