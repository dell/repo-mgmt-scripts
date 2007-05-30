#!/bin/sh

# The purpose of this script is to download and install the
# appropriate repository RPM. This RPM will set up the yum
# repositories on your system. This script will also install the GPG
# keys used to sign fwupdate.com RPMS.

PUBLIC_FIRMWARE_SERVER="http://repo.fwupdate.com"
PUBLIC_FIRMWARE_REPO_URL="/repo/firmware"

FIRMWARE_SERVER="http://repo.fwupdate.com"
FIRMWARE_REPO_URL="/repo/firmware"
GPG_KEY[0]=${FIRMWARE_SERVER}/${FIRMWARE_REPO_URL}/RPM-GPG-KEY-fwupdate
#GPG_KEY[3]=URL_OF_ADDITIONAL_GPG_KEYS_unless_not_using

# change to 0 to disable check of repository RPM sig.
CHECK_REPO_SIGNATURE=1

REPO_RPM_VER="12-0"
REPO_NAME="fwupdate"


##############################################################################
#  Should not need to edit anything below this point
##############################################################################

REPO_RPM="${REPO_NAME}-repository-${REPO_RPM_VER}.noarch.rpm"

TMPDIR=`mktemp -d /tmp/bootstrap.XXXXXX`
[ ! -d ${TMPDIR} ] && echo "Failed to make temporary directory." && exit 1
trap "rm -rf $TMPDIR" EXIT HUP QUIT

cd ${TMPDIR} 

i=0
while [ $i -lt ${#GPG_KEY[*]} ]; do
    echo "Downloading GPG key: ${GPG_KEY[$i]}"
    rm GPG-KEY > /dev/null 2>&1 || true
    wget -q -O GPG-KEY ${GPG_KEY[$i]}
    echo "    Importing key into RPM."
    rpm --import GPG-KEY
    i=$(( $i + 1 ))
done

wget -q -N ${FIRMWARE_SERVER}/${FIRMWARE_REPO_URL}/cross-distro/RPMS/${REPO_RPM}
if [ "$CHECK_REPO_SIGNATURE" = "1" ]; then
    rpm -K ${REPO_RPM} > /dev/null 2>&1
    [ $? -ne 0 ] && echo "Failed ${REPO_RPM} GPG check!" && exit 1 
fi

echo "Installing ${REPO_RPM}"
rpm -i ${REPO_RPM} > /dev/null 2>&1


# Mirror mode
if [ "$PUBLIC_FIRMWARE_REPO_URL" != "$FIRMWARE_REPO_URL" -o "$PUBLIC_FIRMWARE_SERVER" != "$FIRMWARE_SERVER" ]; then
    # update yum conf
    echo "FIRMWARE_SERVER=$FIRMWARE_SERVER" >> /etc/dell-mirror.cfg
    echo "FIRMWARE_REPO_URL=$FIRMWARE_REPO_URL" >> /etc/dell-mirror.cfg

    echo "PUBLIC_FIRMWARE_SERVER=$PUBLIC_FIRMWARE_SERVER" >> /etc/dell-mirror.cfg
    echo "PUBLIC_FIRMWARE_REPO_URL=$PUBLIC_FIRMWARE_REPO_URL" >> /etc/dell-mirror.cfg

    perl -p -i -e "s|$PUBLIC_FIRMWARE_REPO_URL|$FIRMWARE_REPO_URL|g;" /etc/yum.repos.d/fwupdate.repo 
    perl -p -i -e "s|$PUBLIC_FIRMWARE_SERVER|$FIRMWARE_SERVER|g;" /etc/yum.repos.d/fwupdate.repo

    # update rhn sources
    RHN=/etc/sysconfig/rhn/sources
    perl -p -i -e "s|^(^yum fwupdate .*)$PUBLIC_FIRMWARE_REPO_URL|\$1$FIRMWARE_REPO_URL|g;" $RHN
    perl -p -i -e "s|^(^yum fwupdate .*)$PUBLIC_FIRMWARE_SERVER|\$1$FIRMWARE_SERVER|g;" $RHN
    perl -p -i -e "s|^(^yum-mirror fwupdate .*)$PUBLIC_FIRMWARE_REPO_URL|\$1$FIRMWARE_REPO_URL|g;" $RHN
    perl -p -i -e "s|^(^yum-mirror fwupdate .*)$PUBLIC_FIRMWARE_SERVER|\$1$FIRMWARE_SERVER|g;" $RHN
fi

echo "Done!"
exit 0
