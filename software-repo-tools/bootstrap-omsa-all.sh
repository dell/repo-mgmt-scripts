#!/bin/sh

# 
echo "This script is no longer recommended."
echo "please just run 'yum install srvadmin-all'"
echo " or 'up2date -i srvadmin-all'" 
exit 0

# If you wish to mirror the Dell yum repository, you need to:
#   1) create your own "repository" RPM, (you can copy the Dell repo spec file)
#   2) sign your repository RPM
#   3) add your GPG key to the list below
#   4) edit the variables below to point to your new repo.

SERVER="http://linux.dell.com"
YUM_URL="/repo/software"

##############################################################################
#  Should not need to edit anything below this point
##############################################################################

#set -e
#set -x

# What distribution are we running?
dist=unknown
[ ! -e /bin/rpm ] && exit 1
if [ -r /etc/redhat-release ]; then
    WHATPROVIDES_REDHAT_RELEASE=`rpm -q --whatprovides redhat-release`
    if `echo "${WHATPROVIDES_REDHAT_RELEASE}" | grep redhat-release > /dev/null 2>&1` ; then
	REDHAT_RELEASE=`/bin/rpm -q ${WHATPROVIDES_REDHAT_RELEASE} 2>/dev/null`
    elif `echo "${WHATPROVIDES_REDHAT_RELEASE}" | grep centos-release > /dev/null 2>&1` ; then
	CENTOS_RELEASE=`/bin/rpm -q ${WHATPROVIDES_REDHAT_RELEASE} 2>/dev/null`
    elif `echo "${WHATPROVIDES_REDHAT_RELEASE}" | grep fedora-release > /dev/null 2>&1` ; then
	FEDORA_RELEASE=`/bin/rpm -q ${WHATPROVIDES_REDHAT_RELEASE} 2>/dev/null`
    fi
fi
[ -r /etc/SuSE-release ] && SLES_RELEASE=`/bin/rpm -q sles-release 2>/dev/null`

if [ -n "${FEDORA_RELEASE}" ]; then
    VER=`rpm -q --qf "%{version}\n" ${WHATPROVIDES_REDHAT_RELEASE}`
    dist=fc${VER}

    echo "Sorry, at this time, OMSA is not supported on Fedora Core releases."
    echo "Exiting without install..."
    exit 1

elif [ -n "${REDHAT_RELEASE}" ]; then
    VER=`rpm -q --qf "%{version}\n" ${WHATPROVIDES_REDHAT_RELEASE}`
    # format is 3AS, 4AS, ...
    case "${VER}" in 
	3AS|3ES|3WS|3Desktop) dist=el3 ;;
	4AS|4ES|4WS|4Desktop) dist=el4 ;;
	*);;
    esac

elif [ -n "${CENTOS_RELEASE}" ]; then
    VER=`rpm -q --qf "%{version}\n" ${WHATPROVIDES_REDHAT_RELEASE}`
    dist=el${VER}
    # format is 3, 4, ...

elif [ -n "${SLES_RELEASE}" ]; then
    VER=`rpm -q --qf "%{version}\n" sles-release`
    dist=sles${VER}

    echo "Although OMSA is supported on SLES 9 & 10, I dont "
    echo "currently have the commands to use to install it..."
    exit 1
fi

if [ "${dist}" = "unknown" ]; then
    echo "Unable to determine that you are running an OS I know about."
    echo "Handled OSs include Red Hat Enterprise Linux 3 and 4,"
    echo "CentOS 3 and 4,"
    echo "Fedora Core 3 and 4,"
    echo "and Novell SuSE Linux Enterprise Server 9"
    exit 1
fi

case $dist in 
    el3|el4)
        up2date -u srvadmin-all
        ;;
    sles9|sles10)
        # dont think this is right
        yum install srvadmin-all
        ;;
esac

echo "Done!"
exit 0
