#!/bin/bash

PROTFOLDER="./port"
LOG="/var/log/natmap/natmap.log"

if [ ! -d "$PROTFOLDER" ]; then
    mkdir $PROTFOLDER
fi

FILE="$PROTFOLDER/$5$1"

chat_id="${CHAT_ID}"
token="${TOKEN}"
proxy="${PROXY}"
time="$(date +'%Y-%m-%d %H:%M:%S')"

function getTargetLastestPort() {
    if [ -f "$FILE" ]; then
        return `cat $FILE`
    else
        return "0"
    fi
}

function curl_proxy() {
    if [ -z "$proxy" ]; then
        curl "$@"
    else
        curl -x $proxy "$@"
    fi
}

msg=\
"Export Service Name: <strong>${GENERAL_NAT_NAME}</strong>\n"\
"Connect Info: $5-$4 -> <strong>$1:$2</strong>\n"\
"Upgrade Time: <strong>$time</strong>"

getTargetLastestPort $4
msgid=$?

if [ $msgid = "0" ]; then
    response=$(curl_proxy -4 -Ss -X POST \
        -H 'Content-Type: application/json' \
        -d '{"chat_id": "'"${chat_id}"'", "text": "'"${msg}"'", "parse_mode": "HTML", "disable_notification": "false"}' \
        "https://api.telegram.org/bot${token}/sendMessage")
else
    response=$(curl_proxy -4 -Ss -X POST \
        -H 'Content-Type: application/json' \
        -d '{"chat_id": "'"${chat_id}"'","message_id": "'"${msgid}"'" , "text": "'"${msg}"'", "parse_mode": "HTML", "disable_notification": "false"}' \
        "https://api.telegram.org/bot${token}/editMessageText")
fi

if echo "$response" | grep -q '"error_code"'; then
    echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - Error $reponse" >> "$LOG"
else
    message_id=$(echo "$response" | grep -o '"message_id":[0-9]*' | sed 's/[^0-9]*//g')
    echo "$message_id" > "$FILE"
    echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - Succeed" >> "$LOG"
fi

