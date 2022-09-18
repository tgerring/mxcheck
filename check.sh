#!/bin/bash
#################################
#
# MxCheck - Check to see if your validators are scheduled for sync commitee or proposal (within protocol limits)
# Avoid performing system updates or restarts when your node is scheduled for important duties.
#
# TODO Doesn't need tocheck committee sync every epoch, only every EPOCHS_PER_SYNC_COMMITTEE_PERIOD
#
#################################

# TODO get rid of these
VALDINXS='validators_index.txt' # pass via stdin?
DIFF_FILE='/tmp/difflist' # reorganize to use grep in-memory

# Command Line Argument Defaults
ENDPOINT='127.0.0.1:5052' # -e
DAEMON=false # -d
VERBOSE=false # -v

# SETUP
trap cleanup SIGINT SIGTERM

# CONSTANTS
MIN_GENESIS_TIME=1606824000
EPOCHS_PER_SYNC_COMMITTEE_PERIOD=256
SYNC_COMMITTEE_SIZE=512
SECONDS_PER_SLOT=12
SLOTS_PER_EPOCH=32
EPOCH_TIME=$((SECONDS_PER_SLOT * SLOTS_PER_EPOCH))

# GLOBALS
CURRENT_SLOT=0
CURRENT_EPOCH=0
NEXT_EPOCH=0
FUTURE_EPOCH=0
SYNC_START_EPOCH=0
SYNC_NEXT_EPOCH=0
SYNC_FUTURE_EPOCH=0
VALCONT=0


# Extracted helper functions 
getEpochFromSlot() {
  local slot=$1
  echo $((slot / SLOTS_PER_EPOCH))
  }

epochToTime(){
  echo $((MIN_GENESIS_TIME + ( $1 * SLOTS_PER_EPOCH * SECONDS_PER_SLOT )))
  }

timeToEpoch(){
  echo $((( $1 - MIN_GENESIS_TIME ) / SLOTS_PER_EPOCH * SECONDS_PER_SLOT ))
  }

timeToSlot(){
  echo $((( $1 - MIN_GENESIS_TIME ) / SECONDS_PER_SLOT ))
  }

epochTime() {
  (date -d@$(epochToTime $1) '+%F %T')
  }

slotsRemaining() {
  echo $((NEXT_EPOCH * SLOTS_PER_EPOCH - CURRENT_SLOT))
  }


# Functions that do real stuff
getCurrentSlot() {
  echo $(curl -s -X GET "http://$ENDPOINT/eth/v1/beacon/headers/head" | jq .data.header.message.slot -r)
  }

updateTicks () {
  CURRENT_SLOT=$(getCurrentSlot)
  CURRENT_EPOCH=$(getEpochFromSlot CURRENT_SLOT)
  NEXT_EPOCH=$((CURRENT_EPOCH + 1))
  FUTURE_EPOCH=$((NEXT_EPOCH + 1))
  SYNC_START_EPOCH=`expr \( $CURRENT_EPOCH / $EPOCHS_PER_SYNC_COMMITTEE_PERIOD \) \* $EPOCHS_PER_SYNC_COMMITTEE_PERIOD`
  SYNC_NEXT_EPOCH=`expr $SYNC_START_EPOCH + $EPOCHS_PER_SYNC_COMMITTEE_PERIOD`
  SYNC_FUTURE_EPOCH=`expr $SYNC_NEXT_EPOCH + $EPOCHS_PER_SYNC_COMMITTEE_PERIOD`
  }

main () {
  updateTicks

  # Check current epoch for proposals and sync committee
  local slotstogo=$(slotsRemaining)
  local secs=$((slotstogo * SECONDS_PER_SLOT))
  logit
  logit "Actually Slot $CURRENT_SLOT in Epoch $CURRENT_EPOCH. $slotstogo slots remaining" # (~$secs seconds)"
  checkProposals $CURRENT_EPOCH
  checkSyncCommittee $CURRENT_EPOCH

  # Check next epoch for proposals
  local nextepoctime=$(epochTime $NEXT_EPOCH)
  logit
  logit "Next Epoch $NEXT_EPOCH expecting to begin $nextepoctime"
  checkProposals $NEXT_EPOCH
  #farsecs=$((SLOTS_PER_EPOCH * SECONDS_PER_SLOT + secs))
  logit "Next Epoch $NEXT_EPOCH expected to end by $(epochTime $((NEXT_EPOCH + 1)))" # (~$farsecs seconds)"

  # Check next sync committee
  local nextsynctime=$(epochTime $SYNC_NEXT_EPOCH)
  logit
  logit "Next Sync Committee scheduled for Epoch $SYNC_NEXT_EPOCH ($nextsynctime)"
  checkSyncCommittee $SYNC_NEXT_EPOCH
  local futuresynctime=$(epochTime $SYNC_FUTURE_EPOCH)
  logit "Next Sync Committee to end after  Epoch $((SYNC_FUTURE_EPOCH - 1)) ($futuresynctime)"
  }


init() {
  logit "ENDPOINT=$ENDPOINT DAEMON=$DAEMON VERBOSE=$VERBOSE"
  checkValidators
  local estepoc=$(timeToEpoch $(date +%s))
  local estslot=$(timeToSlot $(date +%s))
  logit "Estimate Slot $estslot in Epoch $estepoc"
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
  #logit "Checking for proposals"
  local epoch=$1
  local propfile="proposals_${epoch}"
  local tempfile="${DIFF_FILE}_pro_${epoch}"

  curl -s -X GET "http://$ENDPOINT/eth/v1/validator/duties/proposer/$epoch" | jq .data | jq '.[].validator_index' -c -S -r > $propfile

  # compare the committee list against local validators
  grep -Fi -f $VALDINXS $propfile > $tempfile
  local DIFFCONT=$(grep -e "$" -c $tempfile)


  logit "Found $DIFFCONT validators assigned to propose a block"
  if [ $DIFFCONT -ne 0 ]; then
    for VALINX in $(cat $tempfile)
    do
      logit "******** $VALINX will be assigned to proposae a block during $epoch ********" true
    done
  fi

  rm $tempfile
  rm $propfile
  }

checkSyncCommittee() {
  #logit "Checking for sync duties"
  local epoch=$1
  local commfile="synccomittee_${epoch}"
  local tempfile="${DIFF_FILE}_com_${epoch}"

  curl -s -X GET "http://$ENDPOINT/eth/v1/beacon/states/head/sync_committees?epoch=$epoch" | jq .data.validators | jq '.[]' -c -S -r > $commfile

  # check that committee count is the right size
  local COMMCONT=$(grep -e "$" -c $commfile)
  if [ $COMMCONT -ne $SYNC_COMMITTEE_SIZE ]; then
    echo "Found $COMMCONT but was expecting $SYNC_COMMITTEE_SIZE", true
    exit 1
  fi

  # compare the committee list against local validators
  grep -Fi -f $VALDINXS $commfile > $tempfile
  local DIFFCONT=$(grep -e "$" -c $tempfile)

  logit "Found $DIFFCONT validators assigned to sync committee"
  if [ $DIFFCONT -ne 0 ]; then
    for VALINX in $(cat $tempfile)
    do
      logit "******** $VALINX will be on sync committee from $epoch through $((SYNC_FUTURE_EPOCH - 1)) ********" true
    done
  fi
  rm $tempfile
  rm $commfile
  }

logit () {
  if [[ $VERBOSE == true || $2 == true ]]; then
    #echo  "`date +"%Y-%m-%d %T"`   $1"
    echo  "   $1"
  fi
  }

cleanup () {
  logit
  logit 'Cleanup'
  exit
  }

chill () {
  # sleep until next epoch
  local sleepTime=$(($1 * SECONDS_PER_SLOT))

  logit
  logit "Sleeping until next epoch ($sleepTime secs)"
  logit
  logit

  sleep $sleepTime
  }

# Program entry
while getopts 'vde:' OPTION; do
  case "$OPTION" in
    v)
      VERBOSE=true
      ;;
    d)
      DAEMON=true
      ;;
    e)
      ENDPOINT="$OPTARG"
      ;;
    ?)
      echo "script usage: [-v] [-d] [-e ip:port]" >&2
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

init
if [ $DAEMON == false ]; then
  main
else
  while [ true ]; do
    main
    chill $(slotsRemaining)
  done
fi
cleanup

