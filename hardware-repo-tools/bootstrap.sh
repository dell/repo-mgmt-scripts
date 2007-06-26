#!/bin/sh
# vim:et:tw=0:ts=4:sw=4:filetype=sh

# The purpose of this script is to download and install the appropriate 
# repository RPM. This RPM will set up the Dell yum repositories on your 
# system. This script will also install the Dell GPG keys used to sign 
# Dell RPMS.

# If you wish to mirror the Dell yum repository, you need to:
#   --> ask me to redo these instructions, because I just made it a lot easier. :)

# These two variables are used to see if the perl script changed
# SERVER and REPO_URL inline. If the perl script changes these, 
# it activates private mirror mode and modifies the repos.
PUBLIC_HARDWARE_SERVER="http://linux.dell.com"
PUBLIC_HARDWARE_REPO_URL="/repo/hardware"

# these two variables are replaced by the perl script 
# with the actual server name and directory. This is useful for
# mirroring
HARDWARE_SERVER="http://linux.dell.com"
HARDWARE_REPO_URL="/repo/hardware"

GPG_KEY[0]=${HARDWARE_SERVER}/${HARDWARE_REPO_URL}/RPM-GPG-KEY-dell
GPG_KEY[1]=${HARDWARE_SERVER}/${HARDWARE_REPO_URL}/RPM-GPG-KEY-libsmbios
#GPG_KEY[3]=URL_OF_ADDITIONAL_GPG_KEYS_unless_not_using

# change to 0 to disable check of repository RPM sig.
CHECK_REPO_SIGNATURE=1

REPO_RPM_VER="1-9"
REPO_NAME="dell-hw-indep"

##############################################################################
#  Should not need to edit anything below this point
##############################################################################

#set -e
#set -x

# Mirror mode
function write_mirror_cfg() 
{
  if [ -e /etc/dell-mirror.cfg ]; then
    # remove any old entries
    perl -n -i -e "print if ! /^HARDWARE_SERVER/;" /etc/dell-mirror.cfg
    perl -n -i -e "print if ! /^HARDWARE_REPO_URL/;" /etc/dell-mirror.cfg
    perl -n -i -e "print if ! /^PUBLIC_HARDWARE_SERVER/;" /etc/dell-mirror.cfg
    perl -n -i -e "print if ! /^PUBLIC_HARDWARE_REPO_URL/;" /etc/dell-mirror.cfg
  fi
  if [ "$PUBLIC_HARDWARE_REPO_URL" != "$HARDWARE_REPO_URL" -o "$PUBLIC_HARDWARE_SERVER" != "$HARDWARE_SERVER" ]; then
    # update yum conf
    echo "activating mirror mode:"
    echo "  $PUBLIC_HARDWARE_REPO_URL != $HARDWARE_REPO_URL"
    echo "    and/or"
    echo "  $PUBLIC_HARDWARE_SERVER != $HARDWARE_SERVER"
    echo "HARDWARE_SERVER=$HARDWARE_SERVER" >> /etc/dell-mirror.cfg
    echo "HARDWARE_REPO_URL=$HARDWARE_REPO_URL" >> /etc/dell-mirror.cfg

    echo "PUBLIC_HARDWARE_SERVER=$PUBLIC_HARDWARE_SERVER" >> /etc/dell-mirror.cfg
    echo "PUBLIC_HARDWARE_REPO_URL=$PUBLIC_HARDWARE_REPO_URL" >> /etc/dell-mirror.cfg
  fi
}


function distro_version()
{
    # What distribution are we running?
    dist=unknown
    [ ! -e /bin/rpm ] && echo "$dist" && return
    # tail is a fix for case where they have >1 redhat-release rpm (a bug on their end)
    WHATPROVIDES_REDHAT_RELEASE=$(rpm -q --whatprovides redhat-release | tail -n1)
    if rpm -q --whatprovides redhat-release >/dev/null 2>&1; then
	    if $(echo "${WHATPROVIDES_REDHAT_RELEASE}" | grep redhat-release > /dev/null 2>&1) ; then
	        REDHAT_RELEASE=1
	    elif (echo "${WHATPROVIDES_REDHAT_RELEASE}" | grep centos-release > /dev/null 2>&1) ; then
	        REDHAT_RELEASE=1
	    elif (echo "${WHATPROVIDES_REDHAT_RELEASE}" | grep sl-release > /dev/null 2>&1) ; then
	        REDHAT_RELEASE=1
	    fi
    fi

    WHATPROVIDES_SLES_RELEASE=$(rpm -q --whatprovides sles-release | tail -n1)
    if rpm -q --whatprovides sles-release >/dev/null 2>&1; then
	    SLES_RELEASE=1
    fi

    if [ -n "${REDHAT_RELEASE}" ]; then
	    VER=$(rpm -q --qf "%{version}\n" ${WHATPROVIDES_REDHAT_RELEASE})
            # format is 3AS, 4AS, 5Desktop... strip off al alpha chars
	    dist=el${VER%%[a-zA-Z]*}
    elif [ -n "${SLES_RELEASE}" ]; then
	    VER=$(rpm -q --qf "%{version}\n" ${WHATPROVIDES_SLES_RELEASE})
	    dist=sles${VER}
    fi
    echo "$dist"
}

dist=$(distro_version)
if [ "${dist}" = "unknown" ]; then
    echo "Unable to determine that you are running an OS I know about."
    echo "Handled OSs include Red Hat Enterprise Linux and CentOS,"
    echo "Fedora Core and Novell SuSE Linux Enterprise Server and OpenSUSE"
    exit 1
fi

REPO_RPM="${REPO_NAME}-repository-${REPO_RPM_VER}.${dist}.noarch.rpm"

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

# download repo rpm
basearch=$(uname -i)
ACTUAL_REPO_URL=$(wget -q -O- ${HARDWARE_SERVER}/${HARDWARE_REPO_URL}/mirrors.pl?osname=${dist}\&basearch=$basearch)
RPM_URL=${ACTUAL_REPO_URL}/$basearch/${REPO_NAME}-repository/${REPO_RPM_VER}/$REPO_RPM
wget -q -N $RPM_URL
if [ ! -e ${REPO_RPM} ]; then
    echo "Failed to download RPM: ${RPM_URL}"
    exit 1
fi

if [ "$CHECK_REPO_SIGNATURE" = "1" ]; then
    rpm -K ${REPO_RPM} > /dev/null 2>&1
    [ $? -ne 0 ] && echo "Failed ${REPO_RPM} GPG check!" && exit 1 
fi

# write mirror cfg before installing repo rpm
write_mirror_cfg

echo "Installing platform-independent RPM: ${REPO_RPM}"
rpm -U ${REPO_RPM} > /dev/null 2>&1

echo -e "\nInstalling platform-specific repository RPM."
case $dist in
    el[34])
        up2date -i dell-hw-specific-repository
        ;;
    el5)
        yum -y install dell-hw-specific-repository
        ;;
    sles10)
        #hw indep setup
        FULL_URL=$(grep ^mirrorlist= /etc//yum.repos.d/dell-hw-indep-repository.repo | cut -d= -f2- )
        # no vars in SLES, need to replace $basearch
        basearch=$(uname -i)
        FULL_URL=$(echo $FULL_URL | perl -p -i -e "s|\\\$basearch|$basearch|;")

        # also sles doesnt support CGI params, so fake it with PATH_INFO 
        # (supported by server-side cgi)
        FULL_URL=$(echo $FULL_URL | perl -p -i -e "s|\?|/|;")

        # SLES 10 doesnt support mirrorlist, so turn into redirect (support is in 
        # server-side cgi for this)
        FULL_URL=${FULL_URL}\&redirect=1\&redir_path=

        yes | rug service-add -t ZYPP ${FULL_URL} dell-hw-indep-repository
        rug subscribe dell-hw-indep-repository
        rug install -y dell-hw-specific-repository

        sys_ven_id=0x1028
        sys_dev_id=$(getSystemId | grep "^System ID:"| cut -d: -f2 | xargs echo)
        dellsysidpluginver=up2date
        FULL_URL=$(grep ^mirrorlist= /etc/yum.repos.d/dell-hw-specific-repository.repo | cut -d= -f2- | perl -p -i -e "s|\\\$sys_ven_id|$sys_ven_id|; s|\\\$sys_dev_id|$sys_dev_id|; s|\\\$dellsysidpluginver|$dellsysidpluginver|;")
        # no vars in SLES, need to replace $basearch
        basearch=$(uname -i)
        FULL_URL=$(echo $FULL_URL | perl -p -i -e "s|\\\$basearch|$basearch|;")
        
        # also sles doesnt support CGI params, so fake it with PATH_INFO 
        # (supported by server-side cgi)
        FULL_URL=$(echo $FULL_URL | perl -p -i -e "s|\?|/|;")
        
        # SLES 10 doesnt support mirrorlist, so turn into redirect (support is in 
        # server-side cgi for this)
        FULL_URL=${FULL_URL}\&redirect=1\&redir_path=
        
        yes | rug service-add -t ZYPP $FULL_URL dell-hw-specific-repository
        rug subscribe dell-hw-specific-repository
        ;;
    *)
        ;;
esac

echo "Done!"
exit 0
