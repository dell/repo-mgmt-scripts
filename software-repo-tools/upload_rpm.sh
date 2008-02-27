#!/bin/sh
# vim:tw=0:et:sw=4:ts=4:ai

set -e

DIR=$(cd $(dirname $0); pwd)
PATH=$PATH:$DIR
# dont use '..' here or symlinks mess us up.
REPO_TOPDIR=$(dirname $DIR)

usage() {
    echo "upload_rpm.sh [-c config] [-n] [-l mock_cfg] SRPM"
    echo 
    echo "  -c config   - specify config file that defines mock configs. default: repo.cfg"
    echo "  -n          - unset config default (repo.cfg)"
    echo "  -l mock_cfg - manually specify a mock config name"
    exit 1
}

CONFIG=$DIR/repo.cfg
while getopts "c:nl:" Option
do
  case $Option in
      c)
        CONFIG=$OPTARG
        ;;
      n)
        unset CONFIG
        ;;
      l)
        MOCK_CFG_LIST="$MOCK_CFG_LIST $OPTARG"
        ;;
      *) 
        usage
        ;;
  esac
done
shift $(($OPTIND - 1))
# Move argument pointer to next.

SRPM=$1
[ -z "$CONFIG" ] || . $CONFIG
[ -e "$SRPM" ] || usage

REPO_PATH=$REPO_TOPDIR/incoming/
RPM_NAME=$(rpm -qp --qf "%{name}" $SRPM)
RPM_VER=$(rpm -qp --qf "%{version}-%{release}" $SRPM)
OUTDIR=$REPO_PATH/'%(dist)s'/'%(target_arch)s'/$RPM_NAME/$RPM_VER/

for cfg in $MOCK_CFG_LIST; do
    echo "building $SRPM using $cfg"
    mock -r $cfg --resultdir=$OUTDIR --uniqueext=${RPM_NAME}-$$ rebuild $SRPM
done

process-incoming-rpms.sh
