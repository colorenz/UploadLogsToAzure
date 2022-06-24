#!/bin/bash

### Version 1.0.0
### Created by colorenz


## The Azure Url from the Azure Portal. 
Azure_URL="https://macadminuploadlogs.blob.core.windows.net/uploadlogs/"
## The Azure Acesse Token with 
Token="?sp=acw&st=2022-06-2bjgjgdgjdgdjgtest1Z&spr=https&sv=2021-06-08&sr=c&sig=KAf8WetSgj3LJp4QQ5ojrpNGsN4lXPItQopZZqeQh9w%3D"


## System Variables
mySerial=$( system_profiler SPHardwareDataType | grep Serial |  awk '{print $NF}' )
currentUser=$( stat -f%Su /dev/console )
UserHome=$(dscl . -read /users/$currentUser NFSHomeDirectory | cut -d " " -f 2)
compHostName=$( scutil --get LocalHostName )
timeStamp=$( date '+%Y-%m-%d-%H-%M-%S' )
# IP Address of ethernet device 0
ethIP0=`/usr/sbin/ipconfig getifaddr en0`
# IP Address of ethernet device 1
ethIP1=`/usr/sbin/ipconfig getifaddr en1`
# List of user profiles in the /Users directory
userProfiles=`/bin/ls /Users/`
#############################
# Check Disk Requirements
#############################
# Size of /private/var/log directory
logdirSize=`/usr/bin/du -sk /private/var/log | awk '{ print $1 }'`
# Free space remaining on the boot volume
freeSpace=`/bin/df / | sed -n 2p | awk '{ print $4 }'`

logFiles="$logFiles $UserHome/Library/Logs/"




# Check if there is enough free space on the boot volume to create a copy of the logs directory
if [ "$freeSpace" -gt "$logdirSize" ];
then
    echo "$freeSpace is greater than $logdirSize and we can gather Logs"
else
    echo "$freeSpace is not greater than $logdirSize. Not enough free HD space to copy the log directory. Exiting."
    exit 1
fi

## Pipe computer information to the file
echo "Current TimeStamp: $timeStamp" > "/private/var/log/00-$compHostName$timeStamp.txt"
echo "Mac Computer Name: $compHostName$timeStamp" >> "/private/var/log/00-$compHostName$timeStamp.txt"
echo "Currently Logged in User: $currentUser" >> "/private/var/log/00-$compHostName$timeStamp.txt"
echo "Currently Logged in UserHome: $UserHome" >> "/private/var/log/00-$compHostName$timeStamp.txt"
echo "en0 IP Address: $ethIP0" >> "/private/var/log/00-$compHostName$timeStamp.txt"
echo "en1 IP Address: $ethIP1" >> "/private/var/log/00-$compHostName$timeStamp.txt"
echo "List of User Profiles: $userProfiles" >> "/private/var/log/00-$compHostName$timeStamp.txt"
echo "Size of /private/var/log Directory: $logdirSize" >> "/private/var/log/00-$compHostName$timeStamp.txt"
echo "Free space remaining on Boot Volume: $freeSpace" >> "/private/var/log/00-$compHostName$timeStamp.txt"


# Create WIFI 802.1x Logs
echo "Get WIFI 802.1x Log"
log show --predicate 'subsystem contains "com.apple.eapol"'  --last 48h --info --debug > /private/var/log/Wifi8021x$timeStamp.log

echo "Logs to Zip"
echo "-------------------"
echo "$logFiles"
echo "-------------------"
fileName=$compHostName-$currentUser-$timeStamp.zip
zip -9 -r /private/tmp/$fileName $logFiles

## Build Upload Path
Log_upload_URL=$Azure_URL$compHostName/$fileName$Token

## Upload Log File
curl -X PUT -T  /private/tmp/$fileName  -H "x-ms-date: $(date -u)" -H "x-ms-blob-type: BlockBlob" $Log_upload_URL

## Cleanup
rm /private/tmp/$fileName

rm "/private/var/log/00-$compHostName$timeStamp.txt"

exit 0
