#!/bin/sh
# vim:tw=0:et:sw=4:ts=4

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
PUBLIC_REPO_URL="/repo/firmware"

# these two variables are replaced by the perl script 
# with the actual server name and directory. This is useful for
# mirroring
SERVER="http://linux.dell.com"
REPO_URL="/repo/firmware"

#the SERVER variable is transparently replaced by the cgi script
# so this could actually be different
if [ "$SERVER" = "http://repo.fwupdate.com" ]; then
    echo "fwupdate.com is now deprecated."
    echo "go to http://linux.dell.com/repo/firmware for the firmware repo"
    exit 1
fi

REPO_ID=FIRMWARE

# packages are now signed by libsmbios key which should already be installed
#GPG_KEY[0]=${SERVER}/${REPO_URL}/RPM-GPG-KEY-libsmbios
#GPG_KEY[3]=URL_OF_ADDITIONAL_GPG_KEYS_unless_not_using

# change to 0 to disable check of repository RPM sig.
CHECK_REPO_SIGNATURE=1

REPO_RPM_VER="1-4"
REPO_NAME="dell-firmware"


##############################################################################
#  Should not need to edit anything below this point
##############################################################################

#set -e
#set -x

unset DISTRIB_ID
unset DISTRIB_CODENAME
[ -r /etc/lsb-release ] && . /etc/lsb-release

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
    # catch all the *buntu types
    echo "${DISTRIB_ID}" | grep -i buntu > /dev/null 2>&1 && \
	echo "LSB" && return
    [ ! -e /bin/rpm ] && echo "$dist" && return
    if rpm -q --whatprovides redhat-release >/dev/null 2>&1; then
        DISTRO_REL_RPM=$(rpm -q --whatprovides redhat-release 2>/dev/null | tail -n1)
	    if $(echo "${DISTRO_REL_RPM}" | grep redhat-release > /dev/null 2>&1) ; then
	        REDHAT_RELEASE=1
	    elif (echo "${DISTRO_REL_RPM}" | grep centos-release > /dev/null 2>&1) ; then
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
    elif [ -n "${DISTRIB_ID}" ]; then
	    dist=LSB
    fi
    echo "$dist"
}

function get_key()
{
    [ "$1" = "apt" ] && GPG_KEY[0]=${SERVER}/repo/GPG-KEY-libsmbios
    TMPDIR=`mktemp -d /tmp/bootstrap.XXXXXX`
    [ ! -d ${TMPDIR} ] && echo "Failed to make temporary directory." && exit 1
    trap "rm -rf $TMPDIR" EXIT HUP QUIT

    cd ${TMPDIR} 

    i=0
    while [ $i -lt ${#GPG_KEY[*]} ]; do
	echo "Downloading GPG key: ${GPG_KEY[$i]}"
	rm GPG-KEY > /dev/null 2>&1 || true
	wget -q -O GPG-KEY ${GPG_KEY[$i]}
	echo "    Importing key."
	if [ "$1" = "rpm" ]; then
	    rpm --import GPG-KEY
	elif [ "$1" = "apt" ]; then
	    apt-key add GPG-KEY
	fi
	if [ $? -ne 0 ]; then
            echo "GPG-KEY import failed."
            echo "   Either there was a problem downloading the key,"
            echo "   or you do not have sufficient permissions to import the key."
            exit 1
	fi
	i=$(( $i + 1 ))
    done
}

function handle_rpms()
{
    REPO_RPM="${REPO_NAME}-repository-${REPO_RPM_VER}.noarch.rpm"
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

    echo "Installing ${REPO_RPM}"
    rpm -U ${REPO_RPM} > /dev/null 2>&1

    case $dist in
	sles10)
        #hw indep setup
            FULL_URL=$(grep ^mirrorlist= /etc//yum.repos.d/dell-firmware-repository.repo | cut -d= -f2- )
        # no vars in SLES, need to replace $basearch
            basearch=$(uname -i)
            FULL_URL=$(echo $FULL_URL | perl -p -i -e "s|\\\$basearch|$basearch|;")

        # also sles doesnt support CGI params, so fake it with PATH_INFO 
        # (supported by server-side cgi)
            FULL_URL=$(echo $FULL_URL | perl -p -i -e "s|\?|/|;")

        # SLES 10 doesnt support mirrorlist, so turn into redirect (support is in 
        # server-side cgi for this)
            FULL_URL=${FULL_URL}\&redirect=1\&redir_path=

            yes | rug service-add -t ZYPP ${FULL_URL} dell-firmware-repository
            rug subscribe dell-firmware-repository
            ;;

	*)
            :
            ;;
    esac
}

function unknown_os()
{
    echo "Unable to determine that you are running an OS I know about."
    echo "Handled OSs include Red Hat Enterprise Linux and CentOS,"
    echo "Fedora Core and Novell SuSE Linux Enterprise Server and OpenSUSE,"
    echo "and Ubuntu."
}

function handle_ubuntu()
{
    local list=/etc/apt/sources.list.d/dell-software-temp-bootstrap.list
    rm -f ${list}
    echo "deb http://linux.dell.com/repo ${DISTRIB_CODENAME} dell-software" > ${list}
    get_key apt
    aptitude update
    aptitude install dell-repository-keys
    aptitude install dell-firmware-repository dell-software-repository
    rm -f ${list}
    aptitude update
}

function handle_lsb()
{
    if [ "${DISTRIB_ID}" = "Ubuntu" ]; then
	handle_ubuntu
    else
	unknown_os
	exit 1
    fi
}

dist=$(distro_version)
if [ "${dist}" = "unknown" ]; then
    unknown_os
    exit 1
elif [ "${dist}" != "LSB" ]; then
    handle_rpms
else
    handle_lsb
fi

echo "Done!"
exit 0
