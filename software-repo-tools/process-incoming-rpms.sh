#!/bin/sh
# vim:ts=4:sw=4:et:tw=0

set -e
#set -x
umask 002

DIR=$(cd $(dirname $0); pwd)
PATH=$PATH:$DIR

#due to symlinks, dont use /.. here or we wind up in the wrong spot.
REPO_TOP=$(dirname $DIR)

findunsigned.py -d $REPO_TOP/incoming | xargs -r rpmwrap.sh --define '_signature gpg' --define '_gpg_name libsmbios' --addsign 
movesigned.py -i $REPO_TOP/incoming -o $REPO_TOP/
find $REPO_TOP/incoming -name \*.log -exec rm {} + 2>/dev/null || :
find $REPO_TOP/incoming -depth -type d -exec rmdir {} \; 2>/dev/null || :

for i in $REPO_TOP/*/i386/ $REPO_TOP/*/x86_64/
do
    echo "process $i"
    rm -f $i/repodata/repomd.xml.*
    repomanage -o $i | xargs -r rm
    createrepo --checkts -d --update $i

    # only generate old-style metadata for things that need it.
    case $(basename $(dirname $i)) in
        el[34])  
            [ -e /usr/bin/yum-arch ] && yum-arch $i
            ;;
    esac

    gpg --batch --no-tty -ab $i/repodata/repomd.xml
    gpg --batch --no-tty -a --export libsmbios > $i/repodata/repomd.xml.key
done


for i in $REPO_TOP/*
do
    [ -e $i/repodata ] || continue

    echo "process $i"
    rm -f $i/repodata/repomd.xml.*
    [ -e /usr/bin/createrepo ] && createrepo --checkts --update -d $i

    # only generate old-style metadata for things that need it.
    case $(basename $i) in
        el[34])  
            [ -e /usr/bin/yum-arch ] && yum-arch $i
            ;;
    esac

    gpg --batch --no-tty -ab $i/repodata/repomd.xml
    gpg --batch --no-tty -a --export libsmbios > $i/repodata/repomd.xml.key
done

find $REPO_TOP -depth -type d -exec rmdir {} \; 2>/dev/null || :
