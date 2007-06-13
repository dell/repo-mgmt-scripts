#!/bin/sh
# vim:et:ai:ts=4:sw=4:filetype=sh:

# the purpose of this script is to serve as a single point for building
# RPMs to shove into the repository.

set -e
set -x

PLAGUE_BUILDS="fc5 fc6 fcdev rhel3 rhel4 rhel5 sles9 sles10"

for file in $*
do
	for distro in $PLAGUE_BUILDS
	do
		plague-client build $file ${PREFIX}${distro}
		sleep 5 ||:
	done
    rm $file
done
