#!/bin/sh
# vim:tw=0:et:sw=4:ts=4

#echo "the repository bootstrap is down for maintainance. Please check back in 1 hour."
#[ -n "$DEBUG" ] || exit 1

# The purpose of this script is to download and install the appropriate 
# repository RPM. This RPM will set up the Dell yum repositories on your 
# system. This script will also install the Dell GPG keys used to sign 
# Dell RPMS.

# If you wish to mirror the Dell yum repository, you need to:
#   --> ask me to redo these instructions, because I just made it a lot easier. :)

# These two variables are used to see if the perl script changed
# SERVER and REPO_URL inline. If the perl script changes these, 
# it activates private mirror mode and modifies the repos.
PUBLIC_SOFTWARE_SERVER="http://linux.dell.com"
PUBLIC_SOFTWARE_REPO_URL="/repo/software"

# these two variables are replaced by the perl script 
# with the actual server name and directory. This is useful for
# mirroring
SOFTWARE_SERVER="http://linux.dell.com"
SOFTWARE_REPO_URL="/repo/software"

GPG_KEY[0]=${SOFTWARE_SERVER}/${SOFTWARE_REPO_URL}/RPM-GPG-KEY-dell
GPG_KEY[1]=${SOFTWARE_SERVER}/${SOFTWARE_REPO_URL}/RPM-GPG-KEY-libsmbios
#GPG_KEY[3]=URL_OF_ADDITIONAL_GPG_KEYS_unless_not_using

# change to 0 to disable check of repository RPM sig.
CHECK_REPO_SIGNATURE=1

REPO_RPM_VER="1-1"
REPO_NAME="dell-unsupported"


##############################################################################
#  Should not need to edit anything below this point
##############################################################################

#set -e
#set -x

function write_mirror_cfg() 
{
  if [ -e /etc/dell-mirror.cfg ]; then
    # remove any old entries
    perl -n -i -e "print if ! /^SOFTWARE_SERVER/;" /etc/dell-mirror.cfg
    perl -n -i -e "print if ! /^SOFTWARE_REPO_URL/;" /etc/dell-mirror.cfg
    perl -n -i -e "print if ! /^PUBLIC_SOFTWARE_SERVER/;" /etc/dell-mirror.cfg
    perl -n -i -e "print if ! /^PUBLIC_SOFTWARE_REPO_URL/;" /etc/dell-mirror.cfg
  fi

  # Mirror mode
  if [ "$PUBLIC_SOFTWARE_REPO_URL" != "$SOFTWARE_REPO_URL" -o "$PUBLIC_SOFTWARE_SERVER" != "$SOFTWARE_SERVER" ]; then
    # update yum conf
    echo "activating mirror mode:"
    echo "  $PUBLIC_SOFTWARE_REPO_URL != $SOFTWARE_REPO_URL"
    echo "    or"
    echo "  $PUBLIC_SOFTWARE_SERVER != $SOFTWARE_SERVER"

    echo "SOFTWARE_SERVER=$SOFTWARE_SERVER" >> /etc/dell-mirror.cfg
    echo "SOFTWARE_REPO_URL=$SOFTWARE_REPO_URL" >> /etc/dell-mirror.cfg

    echo "PUBLIC_SOFTWARE_SERVER=$PUBLIC_SOFTWARE_SERVER" >> /etc/dell-mirror.cfg
    echo "PUBLIC_SOFTWARE_REPO_URL=$PUBLIC_SOFTWARE_REPO_URL" >> /etc/dell-mirror.cfg
  fi
}

function distro_version()
{
# What distribution are we running?
    dist=unknown
    [ ! -e /bin/rpm ] && echo "$dist" && return
    WHATPROVIDES_REDHAT_RELEASE=$(rpm -q --whatprovides redhat-release | tail -n1)
    if [ $? -eq 0 ]; then
	if $(echo "${WHATPROVIDES_REDHAT_RELEASE}" | grep redhat-release > /dev/null 2>&1) ; then
	    REDHAT_RELEASE=1
	elif (echo "${WHATPROVIDES_REDHAT_RELEASE}" | grep centos-release > /dev/null 2>&1) ; then
	    CENTOS_RELEASE=1
	elif (echo "${WHATPROVIDES_REDHAT_RELEASE}" | grep sl-release > /dev/null 2>&1) ; then
	    SCIENTIFIC_RELEASE=1
	elif $(echo "${WHATPROVIDES_REDHAT_RELEASE}" | grep fedora-release > /dev/null 2>&1) ; then
	    FEDORA_RELEASE=1
	fi
    fi

    WHATPROVIDES_SLES_RELEASE=$(rpm -q --whatprovides sles-release | tail -n1)
    if [ $? -eq 0 ]; then
	SLES_RELEASE=1
    fi

    WHATPROVIDES_SUSE_RELEASE=$(rpm -q --whatprovides suse-release | tail -n1)
    if [ $? -eq 0 ]; then
	SUSE_RELEASE=1
    fi

    if [ -n "${FEDORA_RELEASE}" ]; then
	VER=$(rpm -q --qf "%{version}\n" ${WHATPROVIDES_REDHAT_RELEASE})
	dist=fc${VER}
    elif [ -n "${REDHAT_RELEASE}" ]; then
	VER=$(rpm -q --qf "%{version}\n" ${WHATPROVIDES_REDHAT_RELEASE})
        # format is 3AS, 4AS, 5Desktop...
	VER=$(echo "${VER}" | sed -e 's/^\([[:digit:]]*\).*/\1/g')
	dist=el${VER}
    elif [ -n "${CENTOS_RELEASE}" -o -n "${SCIENTIFIC_RELEASE}" ]; then
	VER=$(rpm -q --qf "%{version}\n" ${WHATPROVIDES_REDHAT_RELEASE})
        # format is 3, 4, ...
	dist=el${VER%%\.*}
    elif [ -n "${SLES_RELEASE}" ]; then
	VER=$(rpm -q --qf "%{version}\n" ${WHATPROVIDES_SLES_RELEASE})
	dist=sles${VER}
    elif [ -n "${SUSE_RELEASE}" ]; then
	VER=$(rpm -q --qf "%{version}\n" ${WHATPROVIDES_SUSE_RELEASE})
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

# try new path
RPMPATH=${SOFTWARE_SERVER}/${SOFTWARE_REPO_URL}/${dist}/$(uname -i)/${REPO_NAME}-repository/${REPO_RPM_VER}/${REPO_RPM}
wget -q -N ${RPMPATH}
if [ ! -e ${REPO_RPM} ]; then
    echo "Failed to download RPM: ${RPMPATH}"
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
        FULL_URL=$(grep ^mirrorlist= /etc//yum.repos.d/dell-unsupported-repository.repo | cut -d= -f2- )
        # no vars in SLES, need to replace $basearch
        basearch=$(uname -i)
        FULL_URL=$(echo $FULL_URL | perl -p -i -e "s|\\\$basearch|$basearch|;")

        # also sles doesnt support CGI params, so fake it with PATH_INFO 
        # (supported by server-side cgi)
        FULL_URL=$(echo $FULL_URL | perl -p -i -e "s|\?|/|;")

        # SLES 10 doesnt support mirrorlist, so turn into redirect (support is in 
        # server-side cgi for this)
        FULL_URL=${FULL_URL}\&redirect=1\&redir_path=

        yes | rug service-add -t ZYPP ${FULL_URL} dell-unsupported-repository
        rug subscribe dell-unsupported-repository
        ;;

    *)
        :
        ;;
esac

echo "Done!"
exit 0
