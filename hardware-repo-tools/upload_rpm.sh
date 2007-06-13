#!/bin/sh
# vim:tw=0:et:sw=4:ts=4:ai

set -e

num=0
REPO[$num]=rh40
REPO_ARCH[$num]=i386
REPO_CFG[$num]=rhel4-i386

num=$(( $num + 1 ))
REPO[$num]=rh50
REPO_ARCH[$num]=i386
REPO_CFG[$num]=rhel5-i386

num=$(( $num + 1 ))
REPO[$num]=rh40_64
REPO_ARCH[$num]=x86_64
REPO_CFG[$num]=rhel4-x86_64

num=$(( $num + 1 ))
REPO[$num]=rh50_64
REPO_ARCH[$num]=x86_64
REPO_CFG[$num]=rhel5-x86_64

num=$(( $num + 1 ))
REPO[$num]=sles9_64
REPO_ARCH[$num]=x86_64
REPO_CFG[$num]=sles9-x86_64

num=$(( $num + 1 ))
REPO[$num]=sles10_64
REPO_ARCH[$num]=x86_64
REPO_CFG[$num]=sles10-x86_64

REPO_TOPDIR=/var/ftp/pub/yum/dell-repo/hardware
WHICH_REPO=$1
RPM_NAME=$2
RPM_VER=$3
SRPM=$4

if [ -z "$WHICH_REPO" -o -z "$RPM_NAME" -o -z "$RPM_VER" -o -z "$SRPM" ]; then
    echo "missing params"
    echo " upload_rpm.sh repo rpm_name rpm_ver srpm"
    exit 1
fi

REPO_PATH=$REPO_TOPDIR/incoming/$WHICH_REPO/platform_independent/

i=0
while [ $i -lt ${#REPO[*]} ]; do
    OUTDIR=$REPO_PATH/${REPO[$i]}/$RPM_NAME/$RPM_VER/
    OUTRPM=$( ls $OUTDIR/*.rpm 2>/dev/null | head -n1 )
    if [ -e "$OUTRPM" ]; then
        echo "skipping build for ${REPO[$i]} using ${REPO_CFG[$i]} because output RPM already exists."
        i=$(( $i + 1 ))
        continue
    fi
    mkdir -p $OUTDIR
    SETARCH=
    if [ ${REPO_ARCH[$i]} = "i386" ]; then SETARCH='setarch i386'; fi
    echo "building $SRPM for ${REPO[$i]} using ${REPO_CFG[$i]}"
    $SETARCH mock -r ${REPO_CFG[$i]} --resultdir=$OUTDIR $SRPM
    i=$(( $i + 1 ))
done

