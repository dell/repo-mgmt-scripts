#!/bin/sh

out_topdir=$1
repo_template=$2

[ -z "$out_topdir" ] && echo "need to set top dir" && exit 1
[ -z "$repo_template" ] && echo "need to specify repo template" && exit 1


echo "creating base autosys repo files"
for os in el3 el4 el5 sles9 sles10
do
    cp $repo_template $out_topdir/dellhw-autosys-${os}.repo
    echo ";" >> $out_topdir/dellhw-autosys-${os}.repo
    echo "; This yum repository file is OS-specific, but works with the" >> $out_topdir/dellhw-autosys-${os}.repo
    echo "; Dell system id yum plugin (dellsysidplugin.py) to automatically" >> $out_topdir/dellhw-autosys-${os}.repo
    echo "; detect the correct repository to use based on the system id." >> $out_topdir/dellhw-autosys-${os}.repo
    echo ";" >> $out_topdir/dellhw-autosys-${os}.repo
    echo "; You must have the 'firmware-addon-dell' package which contains the" >> $out_topdir/dellhw-autosys-${os}.repo
    echo "; Dell system id yum plugin installed for this repo to work." >> $out_topdir/dellhw-autosys-${os}.repo
    echo ";" >> $out_topdir/dellhw-autosys-${os}.repo
    echo "; If you try to install this repo file on a system without the" >> $out_topdir/dellhw-autosys-${os}.repo
    echo "; firmware-addon-dell plugin installed, yum will not function properly." >> $out_topdir/dellhw-autosys-${os}.repo
    echo ";" >> $out_topdir/dellhw-autosys-${os}.repo
    echo "; For questions or comments, please use the linux-poweredge@dell.com mailing list." >> $out_topdir/dellhw-autosys-${os}.repo
    echo ";" >> $out_topdir/dellhw-autosys-${os}.repo
    perl -p -i -e "s/PENAME/auto/g" $out_topdir/dellhw-autosys-${os}.repo
    perl -p -i -e 's/dellname=auto/sys_ven_id=\$sys_ven_id&sys_dev_id=\$sys_dev_id/g' $out_topdir/dellhw-autosys-${os}.repo
    perl -p -i -e "s/OSNAME/$os/g" $out_topdir/dellhw-autosys-${os}.repo
    perl -p -i -e 's/ARCHNAME/\$basearch/g' $out_topdir/dellhw-autosys-${os}.repo
done


for i in $out_topdir/*
do
    if [ ! -d $i ]; then continue; fi
    if [ -L $i ]; then continue; fi

    sys=$(basename $i)
    if [ ${sys:0:1} = "_" ]; then continue; fi

    echo "creating repo files for $sys"

    for os in el3 el4 el5 sles9 sles10
    do
        #
        # yum config
        #
        outfile=$i/dellhw-${sys}-${os}.repo
        cp $repo_template $outfile
        echo ";" >> $outfile
        echo "; This yum repository file is OS and platform specific." >> $outfile
        echo "; This repository is *only* recommended for       OS: $os" >> $outfile
        echo "; This repository is *only* recommended for platform: $sys" >> $outfile
        echo ";" >> $outfile
        echo ";" >> $outfile
        perl -p -i -e "s/PENAME/$sys/g" $outfile
        perl -p -i -e "s/OSNAME/$os/g" $outfile

        #
        # up2date config
        #
        if [ ${os} = "el3" -o ${os} = "el4" ]; then
            outfile=$i/dellhw-${sys}-${os}.rhn-source
            echo "#" > $outfile
            echo "# this is a fragment for the /etc/sysconfig/rhn/sources file." >> $outfile
            echo "# copy this file into your rhn sources file to activate." >> $outfile
            echo "#" >> $outfile
            echo "# example:" >> $outfile
            echo "#   cat $(basename $outfile) >> /etc/sysconfig/rhn/sources" >> $outfile
            echo "#" >> $outfile
            echo "yum        dell-hardware-$sys null  # forces usage of mirror" >> $outfile
            echo "yum-mirror dell-hardware-$sys http://linux.dell.com/repo/hardware/mirrors.pl?dellname=$sys&osname=$os.\$ARCH" >> $outfile
        fi
    done
done
