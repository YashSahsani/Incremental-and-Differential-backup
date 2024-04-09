#!/bin/bash

homeDir="/home/yash"
backupDir="$homeDir/backup"
cbw24Dir="$backupDir/cbw24"
ib24Dir="$backupDir/ibw24"
db24Dir="$backupDir/dbw24"
logFile="$backupDir/backup.log"

# Create the backup directories if they don't exist
mkdir -p "$backupDir" "$cbw24Dir" "$ib24Dir" "$db24Dir"
touch "$logFile"
timeStampBackupFormat="%Y-%m-%d %H:%M:%S %Z"
currentTime=$(TZ=America/New_York date +"$timeStampBackupFormat")
completeBackUpTime=$(TZ=America/New_York date +"$timeStampBackupFormat")
sleeptime=120

function getNextBackupNumber() {
    local dir="$1"
    local prefix="$2"
    local count=0
    while [[ -f "$dir/$prefix-$((++count)).tar" ]]; do :; done
    echo "$count"
}

function completeBackUp() {
    local backupNumber=$(getNextBackupNumber "$cbw24Dir" "cbw24")
    local tar_file="cbw24-$backupNumber.tar"
    find "$homeDir" -type f -not -path "$backupDir/*" -print0 2>/dev/null | tar czf "$cbw24Dir/$tar_file" --null -T - >/dev/null 2>&1
    echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") $tar_file was created" >> "$logFile"
}

function incrementalBackup() {
    local backupNumber=$(getNextBackupNumber "$ib24Dir" "ibw24")
    local tar_file="ibw24-$backupNumber.tar"
    local filesForIncrementalBackup=$(find "$homeDir" -type f -not -path "$backupDir/*" -newermt "$1" 2>/dev/null)
    if [ -n "$filesForIncrementalBackup" ]; then
        tar -czf "$ib24Dir/$tar_file" $filesForIncrementalBackup >/dev/null 2>&1
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") $tar_file was created" >> "$logFile"
    else
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") No changes - Incremental backup was not created" >> "$logFile"
    fi
}

function differentialBackup() {
    local backupNumber=$(getNextBackupNumber "$db24Dir" "dbw24")
    local tar_file="dbw24-$backupNumber.tar"
    local filesForDifferentialBackup=$(find "$homeDir" -type f -not -path "$backupDir/*" -newermt "$1" 2>/dev/null)
    if [ -n "$filesForDifferentialBackup" ]; then
        tar -czf "$db24Dir/$tar_file" $filesForDifferentialBackup >/dev/null 2>&1
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") $tar_file was created" >> "$logFile"
    else
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") No changes - Differential backup was not created" >> "$logFile"
    fi
}

while true; do
    # STEP 1: Create a complete backup
    completeBackUp
    # sleep for 2 minutes
    currentTime=$(date +"$timeStampBackupFormat")
    completeBackUpTime=$(date +"$timeStampBackupFormat")
    sleep "$sleeptime"
    # STEP 2: Create an incremental backup
    incrementalBackup "$currentTime"
    # sleep for 2 minutes
    currentTime=$(date +"$timeStampBackupFormat")
    sleep "$sleeptime"
    # STEP 3: Create another incremental backup
    incrementalBackup "$currentTime"
    # sleep for 2 minutes
    sleep "$sleeptime"
    # STEP 4: Create a differential backup
    differentialBackup "$completeBackUpTime"
    # sleep for 2 minutes
    currentTime=$(date +"$timeStampBackupFormat")
    sleep "$sleeptime"
    # STEP 5: Create another incremental backup
    incrementalBackup "$currentTime"
    # sleep for 2 minutes
    sleep "$sleeptime"
done
