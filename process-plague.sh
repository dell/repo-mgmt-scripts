#!/bin/sh

DIR=$(cd $(dirname $(readlink -f $0)); pwd)
PATH=$PATH:$DIR

set -e

umask 002

find /var/ftp/pub/yum/dell-repo/plague -name \*.rpm | xargs -r rpm --define '_signature gpg' --define '_gpg_name libsmbios' --addsign 

movesigned.py -i /var/ftp/pub/yum/dell-repo/plague -o /var/ftp/pub/yum/dell-repo/plague-signed

find /var/ftp/pub/yum/dell-repo/plague -depth -type d -exec rmdir {} \; 2>/dev/null

for i in $(ls -d /var/ftp/pub/yum/dell-repo/plague*/* | grep -v cache)
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

find /var/ftp/pub/yum/dell-repo/plague-signed -depth -type d -exec rmdir {} \; 2>/dev/null
