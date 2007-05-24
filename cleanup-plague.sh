#!/bin/sh

/etc/init.d/plague-server stop
/etc/init.d/plague-builder stop

rm -rf /srv/plague_builder/????????????????????????????????????????
rm -rf /var/tmp/rpmbuild/*

rm -rf /var/lib/mock/rhel-?-*-????????????????????????????????????????
rm -rf /var/lib/mock/fedora-?-*-????????????????????????????????????????
rm -rf /var/lib/mock/sles-?-*-????????????????????????????????????????


/etc/init.d/plague-builder start
/etc/init.d/plague-server start

