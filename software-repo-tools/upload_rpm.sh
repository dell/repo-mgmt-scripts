#!/bin/sh
# vim:tw=0:et:sw=4:ts=4:ai

set -e

DIR=$(cd $(dirname $0); pwd)
PATH=$PATH:$DIR

. $DIR/repo.cfg

# dont use '..' here or symlinks mess us up.
REPO_TOPDIR=$(dirname $DIR)

SRPM=$1

if [ ! -e "$SRPM" ]; then
    echo "Usage:"
    echo " upload_rpm.sh  package.src.rpm"
    exit 1
fi

REPO_PATH=$REPO_TOPDIR/incoming/
RPM_NAME=$(rpm -qp --qf "%{name}" $SRPM)
RPM_VER=$(rpm -qp --qf "%{version}-%{release}" $SRPM)

i=0
while [ $i -lt ${#REPO[*]} ]; do
    OUTDIR=$REPO_PATH/${REPO[$i]}/${REPO_ARCH[$i]}/$RPM_NAME/$RPM_VER/
    OUTRPM=$( ls $OUTDIR/*.rpm 2>/dev/null | grep -v src.rpm | head -n1 )
    if [ -e "$OUTRPM" ]; then
        echo "skipping build for ${REPO[$i]} using ${REPO_CFG[$i]} because output RPM already exists."
        i=$(( $i + 1 ))
        continue
    fi
    mkdir -p $OUTDIR
    SETARCH=
    if [ ${REPO_ARCH[$i]} = "i386" ]; then SETARCH='setarch i386'; fi
    echo "building $SRPM for ${REPO[$i]} using ${REPO_CFG[$i]}"
    $SETARCH mock -r ${REPO_CFG[$i]} --resultdir=$OUTDIR  --uniqueext=$RPM_NAME $SRPM
    mock -r ${REPO_CFG[$i]} --uniqueext=$RPM_NAME  clean
    i=$(( $i + 1 ))
done

rm -rf /var/lib/mock/*-$RPM_NAME

process-incoming-rpms.sh
