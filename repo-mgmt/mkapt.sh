#!/bin/bash
# vim:ts=4:sw=4:et

set -e

umask 002

while [ $# -gt 0 ]
do
    REPO=$1
    [ -n "$REPO" ] || exit 1
    shift

    repometa=$REPO/Sources.gz.gpg
    if [ -e $repometa ]; then
    	need_update=$(find $REPO -newer $repometa -type f ! -name \*.gz)
    else
    	need_update=yes
    fi
    
    pushd $REPO
    apt-ftparchive packages . | gzip > Packages.gz
    apt-ftparchive sources . | gzip > Sources.gz
    gpg --no-tty -ab Packages.gz
    gpg --no-tty -ab Sources.gz
    mv Packages.gz.asc Packages.gz.gpg 
    mv Sources.gz.asc Sources.gz.gpg 
    popd
done

