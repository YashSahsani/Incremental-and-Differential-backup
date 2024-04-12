#!/bin/bash

# Define the user's home directory
homeDir="/home/sahsani"
# Define the location where you want to store the backup files
backupDir="$homeDir/backup"
cbw24Dir="$backupDir/cbw24"
ib24Dir="$backupDir/ib24"
db24Dir="$backupDir/db24"
# Define a file to keep a log of backups done
logFile="$backupDir/backup.log"

# Create the backup directories if they don't exist
mkdir -p "$backupDir" "$cbw24Dir" "$ib24Dir" "$db24Dir"
# Create the log file if it doesn't exist
touch "$logFile"
# Define the time-stamp format and sleep time
timeStampBackupFormat="%Y-%m-%d %H:%M:%S %Z"
sleeptime=60
lastestIncrementalBackupFileName="$ib24Dir/$(ls -t $ib24Dir | head -n1)";
lastestDifferentialBackupFileName="$db24Dir/$(ls -t $db24Dir | head -n1)";

# Define a function to get the next backup number
function getNextBackupNumber() {
    # get the directory and prefix from the arguments
    local dir="$1"
    local prefix="$2"
    local count=0
    # loop through the files in the directory and increment the count
    while [[ -f "$dir/$prefix-$((++count)).tar" ]]; do :; done
    # return the count
    echo "$count"
}

# Define a function to create a complete backup
function completeBackUp() {
    # get the next backup number
    local backupNumber=$(getNextBackupNumber "$cbw24Dir" "cbw24")
    # create the tar file
    local tar_file="cbw24-$backupNumber.tar"
    # find all files in the home directory that are not in the backup directory and create a tar file
    find "$homeDir" -type f -not -path "$backupDir/*" -print0 2>/dev/null | tar -cf "$cbw24Dir/$tar_file" --null -T - >/dev/null 2>&1
    # log the creation of the tar file
    echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") $tar_file was created" >> "$logFile"
}

function incrementalBackup() {
    # get the next backup number
    local backupNumber=$(getNextBackupNumber "$ib24Dir" "ibw24")
    # create the tar file name
    local tar_file="ibw24-$backupNumber.tar"
    # find all files in the home directory that are not in the backup directory and are newly created or modified since the last backup
    local filesForIncrementalBackup=$(find "$homeDir" -type f -not -path "$backupDir/*" -newer "$lastestIncrementalBackupFileName" 2>/dev/null)
    # if the files are found, create a tar file
    if [ -n "$filesForIncrementalBackup" ]; then
        # create the tar file
        tar -cf "$ib24Dir/$tar_file" $filesForIncrementalBackup >/dev/null 2>&1
        # log incremental backup creation in the log file
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") $tar_file was created" >> "$logFile"
    else
        # log that no changes were found
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") No changes - Incremental backup was not created" >> "$logFile"
    fi
}

# Define a function to create a differential backup
function differentialBackup() {
    # get the next backup number
    local backupNumber=$(getNextBackupNumber "$db24Dir" "dbw24")
    # create the tar file name
    local tar_file="dbw24-$backupNumber.tar"
    # find all files in the home directory that are not in the backup directory and are newly created or modified since the last complete backup
    local filesForDifferentialBackup=$(find "$homeDir" -type f -not -path "$backupDir/*" -newer "$lastestDifferentialBackupFileName" 2>/dev/null)
    # if the files are found, create a tar file
    if [ -n "$filesForDifferentialBackup" ]; then
        # create the tar file name
        tar -cf "$db24Dir/$tar_file" $filesForDifferentialBackup >/dev/null 2>&1
        # log the creation of the tar file
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") $tar_file was created" >> "$logFile"
    else
        # log that no changes were found
        echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") No changes - Differential backup was not created" >> "$logFile"
    fi
}

while true; do
    # STEP 1: Create a complete backup
    completeBackUp
    # sleep for 2 minutes
    sleep "$sleeptime"
    # STEP 2: Create an incremental backup
    incrementalBackup "$currentTime"
    # sleep for 2 minutes
    sleep "$sleeptime"
    # STEP 3: Create another incremental backup
    incrementalBackup "$currentTime"
    # sleep for 2 minutes
    sleep "$sleeptime"
    # STEP 4: Create a differential backup
    differentialBackup "$completeBackUpTime"
    # sleep for 2 minutes
    sleep "$sleeptime"
    # STEP 5: Create another incremental backup
    incrementalBackup "$currentTime"
    # sleep for 2 minutes
    sleep "$sleeptime"
done
