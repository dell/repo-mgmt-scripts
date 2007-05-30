#!/bin/sh

DIR=$(cd $(dirname $0); pwd)
PATH=$PATH:$DIR

packages=$(movesigned.py -i /var/ftp/pub/yum/dell-repo/plague --check-only | head -n1)

if [ -n "$packages" ]; then
    echo ""
    echo "Hello. This is your friendly cron here, writing to report that there"
    echo " are packages in the plague repository that need to be signed and"
    echo " sent on their way."
    echo
    echo "Please run: /var/ftp/pub/yum/dell-repo/scripts/process-plague.sh"
    echo
    echo "Here is a list of unsigned packages:" 
    echo
    movesigned.py -i /var/ftp/pub/yum/dell-repo/plague --check-only 
fi
