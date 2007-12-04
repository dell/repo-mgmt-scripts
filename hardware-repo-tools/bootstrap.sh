#!/bin/sh
# vim:et:tw=0:ts=4:sw=4:filetype=sh

#echo "the repository bootstrap is down for maintainance. Please check back in 1 hour."
#[ -n "$DEBUG" ] || exit 1

# The purpose of this script is to download and install the appropriate 
# repository RPM. This RPM will set up the Dell yum repositories on your 
# system. This script will also install the Dell GPG keys used to sign 
# Dell RPMS.

# to mirror this repo, see the wiki pages.

# These two variables are used to see if the perl script changed
# SERVER and REPO_URL inline. If the perl script changes these, 
# it activates private mirror mode and modifies the repos.
PUBLIC_SERVER="http://linux.dell.com"
PUBLIC_REPO_URL="/repo/hardware"

# these two variables are replaced by the perl script 
# with the actual server name and directory. This is useful for
# mirroring
SERVER="http://linux.dell.com"
REPO_URL="/repo/hardware"

REPO_ID=HARDWARE

GPG_KEY[0]=${SERVER}/${REPO_URL}/RPM-GPG-KEY-dell
GPG_KEY[1]=${SERVER}/${REPO_URL}/RPM-GPG-KEY-libsmbios
#GPG_KEY[3]=URL_OF_ADDITIONAL_GPG_KEYS_unless_not_using

# change to 0 to disable check of repository RPM sig.
CHECK_REPO_SIGNATURE=1

REPO_RPM_VER="1-14"
REPO_NAME="dell-hw-indep"

##############################################################################
#  Should not need to edit anything below this point
##############################################################################

#set -e
#set -x

function write_mirror_cfg() 
{
  if [ -e /etc/dell-mirror.cfg ]; then
    # remove any old entries
    perl -n -i -e "print if ! /^${REPO_ID}_SERVER/;" /etc/dell-mirror.cfg
    perl -n -i -e "print if ! /^${REPO_ID}_REPO_URL/;" /etc/dell-mirror.cfg
    perl -n -i -e "print if ! /^PUBLIC_${REPO_ID}_SERVER/;" /etc/dell-mirror.cfg
    perl -n -i -e "print if ! /^PUBLIC_${REPO_ID}_REPO_URL/;" /etc/dell-mirror.cfg
  fi

  # Mirror mode
  if [ "$PUBLIC_REPO_URL" != "$REPO_URL" -o "$PUBLIC_SERVER" != "$SERVER" ]; then
    # update yum conf
    echo "activating mirror mode:"
    echo "  $PUBLIC_REPO_URL != $REPO_URL"
    echo "    and/or"
    echo "  $PUBLIC_SERVER != $SERVER"

    echo "${REPO_ID}_SERVER=$SERVER" >> /etc/dell-mirror.cfg
    echo "${REPO_ID}_REPO_URL=$REPO_URL" >> /etc/dell-mirror.cfg

    echo "PUBLIC_${REPO_ID}_SERVER=$PUBLIC_SERVER" >> /etc/dell-mirror.cfg
    echo "PUBLIC_${REPO_ID}_REPO_URL=$PUBLIC_REPO_URL" >> /etc/dell-mirror.cfg
  fi
}

function distro_version()
{
    # What distribution are we running?
    dist=unknown
    [ ! -e /bin/rpm ] && echo "$dist" && return
    if rpm -q --whatprovides redhat-release >/dev/null 2>&1; then
        DISTRO_REL_RPM=$(rpm -q --whatprovides redhat-release 2>/dev/null | tail -n1)
	    if $(echo "${DISTRO_REL_RPM}" | grep redhat-release > /dev/null 2>&1) ; then
	        REDHAT_RELEASE=1
	    elif (echo "${DISTRO_REL_RPM}" | grep centos-release > /dev/null 2>&1) ; then
            CENTOS_RELEASE=1    # only for messaging purposes
	        REDHAT_RELEASE=1
	    elif (echo "${DISTRO_REL_RPM}" | grep sl-release > /dev/null 2>&1) ; then
	        REDHAT_RELEASE=1
	    elif $(echo "${DISTRO_REL_RPM}" | grep fedora-release > /dev/null 2>&1) ; then
	        FEDORA_RELEASE=1
	    fi
    elif rpm -q --whatprovides sles-release >/dev/null 2>&1; then
        DISTRO_REL_RPM=$(rpm -q --whatprovides sles-release 2>/dev/null | tail -n1)
	    SLES_RELEASE=1
    elif rpm -q --whatprovides suse-release >/dev/null 2>&1; then
        DISTRO_REL_RPM=$(rpm -q --whatprovides suse-release 2>/dev/null | tail -n1)
	    SUSE_RELEASE=1
    fi

    if [ -n "${FEDORA_RELEASE}" ]; then
	    VER=$(rpm -q --qf "%{version}\n" ${DISTRO_REL_RPM})
	    dist=fc${VER}
    elif [ -n "${REDHAT_RELEASE}" ]; then
	    VER=$(rpm -q --qf "%{version}\n" ${DISTRO_REL_RPM})
        # RedHat: format is 3AS, 4AS, 5Desktop... strip off al alpha chars
        # Centos/SL: format is 4.1, 5.1, 5.2, ... strip off .X chars
	    dist=el${VER%%[.a-zA-Z]*}
    elif [ -n "${SLES_RELEASE}" ]; then
	    VER=$(rpm -q --qf "%{version}\n" ${DISTRO_REL_RPM})
	    dist=sles${VER}
    elif [ -n "${SUSE_RELEASE}" ]; then
	    VER=$(rpm -q --qf "%{version}\n" ${DISTRO_REL_RPM})
	    dist=suse${VER}
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
    if [ $? -ne 0 ]; then
        echo "GPG-KEY import failed."
        echo "   Either there was a problem downloading the key,"
        echo "   or you do not have sufficient permissions to import the key."
        exit 1
    fi
    i=$(( $i + 1 ))
done

# download repo rpm
basearch=$(uname -i)
ACTUAL_REPO_URL=$(wget -q -O- ${SERVER}/${REPO_URL}/mirrors.pl?osname=${dist}\&basearch=$basearch | head -n1)
RPM_URL=${ACTUAL_REPO_URL}/${REPO_NAME}-repository/${REPO_RPM_VER}/$REPO_RPM
wget -q -N ${RPM_URL}
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
        # if user appears to have yum installed, prefer it:
        if [ -e /usr/bin/yum ]; then
            yum -y install dell-hw-specific-repository
        else
            up2date -i dell-hw-specific-repository
        fi
        ;;
    el5)
        yum -y install dell-hw-specific-repository
        ;;
    sles10)
        #hw indep setup
        FULL_URL=$(grep ^mirrorlist= /etc//yum.repos.d/dell-hw-indep-repository.repo | cut -d= -f2- )
        # no vars in SLES, need to replace $basearch
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

echo "============================================================================="
if [ -n "$CENTOS_RELEASE" ]; then
    echo 
    echo "Detected CentOS install. "
    echo " CentOS 4.x will not work until yum plugins are enabled. See the FAQ URL below."
fi

echo "If you encounter problems, please read the FAQ at:"
echo "    http://linux.dell.com/wiki/index.php/Repository/FAQ"
echo "============================================================================="
exit 0
