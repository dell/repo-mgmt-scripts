#!/bin/sh

# this script is still under development
#echo "not yet"
#exit 1

DIR=$(cd $(dirname $(readlink -f $0)); pwd)
PATH=$PATH:$DIR

set -e
set -x

umask 002

REPOS="/var/ftp/pub/yum/dell-repo/software/debian /var/ftp/pub/yum/dell-repo/testing/debian"

# move out of incoming
for repo in $REPOS
do
    for distdir in $repo/incoming/*
    do
        dist=$(basename $distdir)
        [ -e $distdir ] || continue
        for pkgdir in $distdir/*
        do
            pkg=$(basename $pkgdir)
            pkg_ver_to_keep=$(basename $(ls -dt $pkgdir/* | head -n1))
            for pkgverdir in $pkgdir/*
            do
                pkgver=$(basename $pkgverdir)
                if [ $pkgver != $pkg_ver_to_keep ]; then
                    echo "removing older pkg ver: $pkgverdir"
                    rm -rf $pkgverdir
                    continue
                fi
                echo "signing package: $pkgverdir"
                debsign -klibsmbios $pkgverdir/*.dsc
                echo "removing any existing pkg versions"
                rm -rf $repo/$dist/$pkg
                mkdir -p $repo/$dist/$pkg
                mv $pkgverdir $repo/$dist/$pkg
            done
        done

        pushd $repo/$dist/
        apt-ftparchive packages . | gzip > Packages.gz
        apt-ftparchive sources . | gzip > Sources.gz
        gpg --no-tty -ab Packages.gz
        gpg --no-tty -ab Sources.gz
        mv Packages.gz.asc Packages.gz.gpg 
        mv Sources.gz.asc Sources.gz.gpg 
        popd
    done
done


