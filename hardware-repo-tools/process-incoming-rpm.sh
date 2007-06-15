#!/bin/sh

DIR=$(cd $(dirname $(readlink -f $0)); pwd)
PATH=$PATH:$DIR

set -e

umask 002

HWREPO=/var/ftp/pub/yum/dell-repo/hardware/
INCOMING=$HWREPO/incoming/

findunsigned.py -d $INCOMING |  xargs -r rpm --define '_signature gpg' --define '_gpg_name libsmbios' --addsign
movesigned.py -i $INCOMING -o $HWREPO

find $INCOMING \( -name build.log -o -name mockconfig.log -o -name root.log \) -exec rm {} \+

for i in $( ls -ad $HWREPO/*/platform_independent/* | xargs -n1 readlink -f | sort | uniq )
do
    echo "remove $i/.olddata"
    rm -rf $i/.olddata
    echo "repomanage $i"
    repomanage -o $i | xargs -r rm
    echo "createrepo $i"
    [ -e /usr/bin/createrepo ] && createrepo -c /var/ftp/pub/yum/dell-repo/plague/cache $i
    echo "yum-arch $i"
    [ -e /usr/bin/yum-arch ] && yum-arch $i
    echo "remove $i/.olddata"
    rm -rf $i/.olddata
    echo "gpg sign repo"
    gpg --batch --no-tty -ab $i/repodata/repomd.xml
    gpg --batch --no-tty -a --export libsmbios > $i/repodata/repomd.xml.key
done

find $HWREPO -depth -type d -exec rmdir {} \; 2>/dev/null
