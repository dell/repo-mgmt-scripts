#!/usr/bin/python
# vim:expandtab:autoindent:tabstop=4:shiftwidth=4:filetype=python:

  #############################################################################
  #
  # Dual Licenced under GNU GPL and OSL
  #
  # Copyright (C) 2005 - 2006 Dell Inc.
  #  by Michael Brown <Michael_E_Brown@dell.com>
  #     Jay Perusse <Jay_Perusse@dell.com>
  # Licensed under the Open Software License version 2.1 or later
  #
  # Alternatively, you can redistribute it and/or modify
  # it under the terms of the GNU General Public License as published
  # by the Free Software Foundation; either version 2 of the License,
  # or (at your option) any later version.
  #
  # This program is distributed in the hope that it will be useful, but
  # WITHOUT ANY WARRANTY; without even the implied warranty of
  # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  # See the GNU General Public License for more details.
  #
  # See the files COPYING-GPL and COPYING-OSL for full license
  # terms
  # ---------------------------------------------------------------
  #
  # version history
  #     1.2.0   11-April-2007     Michael Brown
  #         a) add --yum, --omsa cmdline params
  #         b) add system id symlinks
  #         c) add osnamemap symlinks
  #     1.1.1   31-March-2006     Pritesh Prabhu
  #         a) code review changes
  #         b) usability-related changes
  #     1.1.0   28-March-2006     Michael Brown
  #         a) code review cleanups
  #         b) add hardlink tree option
  #     1.0.3   04-January-2006     Jay Perusse
  #         a) Adding version history and inline comments
  #         b) Changed syntax output to show windows syntax for windows and
  #             linux syntax for syntax.
  #         c) Change -o & --output_dir to -d & --dest_dir & all varibles used
  #         d) Changed -s to -o for OS input
  #         e) If --input_dir is provided default to --info and if --dest_dir is
  #             provided provide feedback the user to use --extract to extract
  #         f) Changed OEMPnPDriversPath=; to OEMPnPDriversPath=drivers; and
  #             changed forward slash (/) to back slash (\) when ran on a linux
  #             system
  #         g) When ran on a windows system remove read only file attributes
  #             from the files copied from the DSA source to the hard disk so
  #             the script can be re-run
  #     1.0.2   04-January-2006     Michael Brown   Added pnpdriverpath.txt
  #         creation when a windows OS is selected.
  #     1.0.1   14-December-2005    Jay Perusse     Changed user output and
  #         adding a back slash (\) when --input_dir or --dest_dir is give as a
  #          drive letter only (d: changed to d:\)
  #     1.0.0   13-December-2005    Michael Brown   Initial release
  #
  #############################################################################

"""
make_driver_dir:

usage:
    -h | --help              prints this message
    -d | --dest_dir <dir>    destination directory to extract drivers to
*   -i | --input_dir <dir>   source Server Assistant CD
    -p | --platform <plat>   limits the drivers extracted to the specified
                               platform
    -o | --os <os name>      extracts drivers for specified operating
                               system only
    -v | --verbose           enable verbose output
    -q | --quiet             suppress verbose output
    -y | --yum               create yum repo from resulting dest (for extract
                             only) Requires /usr/bin/createrepo for new format
                             yum repo and /usr/bin/yum-arch for old format yum
                             repo. Will run both binaries if found.
         --extract           extract drivers
         --info              provides information about platform/operating
                               system support (default)
         --hardlink          hardlink all destination files (saves space, only
                               works if operating system supports hardlinks)

Action to take is a required parameter. Specify one of: [--extract | --info]

 -- Required parameters are denoted by an asterisk (*)

Example Syntax:
"""
#-- future stuff needs to be first
from __future__ import generators

windowsSyntax = "C:\> make_driver_dir -i d:\ -d c:\drv -p pe1855 -o w2003 --extract\n"
linuxSyntax = "$ ./make_driver_dir.py -i /media/cdrom -d ~/drivers/ -p pe1855 -o rh40 --extract\n"

PROGRAM_NAME="make_driver_dir"
VERSION="1.2.0"
PROGRAM_BANNER="""%s %s

Copyright 2005-2006 Dell Inc.
This is free software; see the source for copying conditions. There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
""" % (PROGRAM_NAME, VERSION)

# map OMSA RPM directory names to DSA OS dirs to copy to
OMSA_osList={
    "RHEL4": ("rh40", "rh40_64",),
    "RHEL5": ("rh50", "rh50_64",),
    "SLES9": ("suse9_64",),
    "SLES10": ("suse10_64",),
    }


#-- import arranged alphabetically
import getopt
import glob
import os
import re
import sys
import ConfigParser
import shutil

verbose = 1

class unsuccessfulExit(Exception): pass

def main():
    """
    NAME
        main()

    DESCRIPTION
        Displays DSA driver information and can copy the
        drivers to a user specified directory

    CHANGELOG
        0.2     04-January-2006
         a) Change -o & --output_dir to -d & --dest_dir & all
            varibles used
         b) Changed -s to -o for OS input
         c) If --input_dir is provided default to --info and if
            --dest_dir is provided provide feedback the user to use
            --extract to extract
         d) When ran on a windows system remove read only file
            attributes from the files copied from the DSA source to
            the hard disk so the script can be re-run
        0.1   03-January-2006    Initial release

    AUTHOR
        Michael Brown & Jay Perusse
    """

    inputDir=None
    destDir=None
    ini = None
    selectPlatform = []
    selectOs = []
    global verbose
    action = []
    doYum = 0
    doOmsa=0

    try:
        opts, args = getopt.getopt(sys.argv[1:], "hi:d:vqp:o:y", [
                "help", "input_dir=", "dest_dir=", "platform=", "os=", "verbose", "quiet", "info", "extract", "version", "hardlink", "yum", "omsa",
            ])
        for option, argument in opts:
            if option in ("-h", "--help"):
                printHelp()
                sys.exit(0)
            if option in ("-d", "--dest_dir"):
                if re.search(':$', argument): argument = argument.replace(":", ":\\")
                destDir = os.path.realpath(argument)
            if option in ("-i", "--input_dir"):
                if re.search(':$', argument): argument = argument.replace(":", ":\\")
                inputDir = os.path.realpath(argument)
            if option in ("-p", "--platform"):
                selectPlatform.append(argument)
            if option in ("-o", "--os"):
                selectOs.append(argument)
            if option in ("-v", "--verbose"):
                verbose = 2
                action.append("verbose");
            if option in ("-q", "--quiet"):
                verbose = 0
                action.append("quiet");
            if option in ("--info",):
                action.append("info")
            if option in ("--extract",):
                action.append("extract")
            if option in ("--hardlink",):
                action.append("hardlink")
            if option in ("--omsa",):
                doOmsa=1
            if option in ("-y", "--yum"):
                doYum=1
            if option in ("--version",):
                print PROGRAM_BANNER
                sys.exit(0)

        if args:
            raise getopt.GetoptError("Extra command-line parameters were specified that were not understood: %s" % args[0], "");

        if inputDir is None:
            raise getopt.GetoptError("Missing required parameter: input directory", "")

        if "extract" in action and "info" in action:
            raise getopt.GetoptError("--info and --extract cannot be specified together.", "")

        if "verbose" in action and "quiet" in action:
            raise getopt.GetoptError("--verbose and --quiet cannot be specified together.", "")

        if not os.path.exists(os.path.join(inputDir, "dsa", "oslist-master.ini")):
            raise getopt.GetoptError("Input directory does not exist, or is not a Server Assistant CD.", "")
        if not os.path.exists(os.path.join(inputDir, "server_assistant", "drivers")):
            raise getopt.GetoptError("Input directory appears to be a Server Assistant CD that is an earlier unsupported version.", "")

        if "extract" in action and destDir is None:
            raise getopt.GetoptError("--extract specified, but no destination directory given. ", "")

        if doYum and "extract" not in action:
            raise getopt.GetoptError("--yum specified, but --extract not specified. ", "")

        infoArray = []

        if not "info" in action and not "extract" in action:
            infoArray.append("No action specified. --info assumed");
            action.append("info");
        
        if "info" in action and destDir:
            infoArray.append("--dest_dir ignored for --info action");

        if "info" in action and "hardlink" in action:
            infoArray.append("--hardlink ignored for --info action");

        if infoArray:
            print "\n** INFO **"
            for i in infoArray:
                print i
            print

        oslistIni = ConfigParser.ConfigParser()
        oslistIni.read( glob.glob(os.path.join(inputDir, "dsa", "oslist-*.ini")))

        printOsDescriptions(oslistIni, selectPlatform, selectOs)

        printPlatformSupportMatrix(oslistIni, selectPlatform, selectOs)

        if verbose > 0:
            print "\nDrivers:"
            if verbose>1:
                print "="*80

        try:
            for i in glob.glob(os.path.join(inputDir, "server_assistant", "drivers", "r*")):
                getDriversFromDir(oslistIni, action, i, destDir, selectPlatform, selectOs)

            if doOmsa:
                print "\n"
                if verbose>1:
                    print "="*80
                omsaExtract(oslistIni, action, inputDir, destDir)

            if destDir and doYum:
                doYumRepo(destDir)

        except (OSError), e:
            if e.errno == 13: # permission denied
                print "\n** ERROR **\nYou do not have permissions to create the destination directory: %s" % destDir
            else:
                print "\n** ERROR **\nThere was an error trying to open or create the output directory:\n\t%s" % e
            raise unsuccessfulExit()
                
    except unsuccessfulExit, e:
        sys.exit(4)

    except (getopt.GetoptError), e:
        print "\n** ERROR **\n%s" % e
        print "Try `--help' for more information"
#        printHelp()
        sys.exit(2)

    except (KeyboardInterrupt):
        sys.exit(3)

    except (Exception), e:
        print "There was an unhandled error. The message was: %s" % e
        sys.exit(5)

    return 0 #shell logic


def printHelp():
    """
    NAME
        printHelp()

    DESCRIPTION
        Print windows or linux syntax for help

    CHANGELOG
        0.1     03-January-2006     Initial release

    AUTHOR
        Michael Brown & Jay Perusse
    """
    print __doc__
    if os.name == 'nt':
        print " %s" % windowsSyntax
    else:
        print " %s" % linuxSyntax


def eatException(excSpec, func, *args, **kargs):
    try:
        func(*args, **kargs)
    except excSpec:
        pass


def omsaExtract(oslistIni, action, inputDir, destDir):
    if "extract" not in action: return
    omsaSysidIni = ConfigParser.ConfigParser()
    omsaSysidIni.read(os.path.join(inputDir, "srvadmin", "linux", "supportscripts", "prereqcheck", "syslist.txt"))

    needCr=0
    for omsa, dsaDirs in OMSA_osList.items():
        omsaRpms = os.path.join(inputDir, "srvadmin", "linux", "RPMS", omsa)
        omsaMeta = os.path.join(inputDir, "srvadmin", "linux", "RPMS", "supportRPMS", "metaRPMS")
        print "Copying OMSA for OS: %s" % omsa
        firstDest = None
        for dsaDir in dsaDirs:
            print "    into repo dir: %s" % dsaDir
            if verbose>1:
                print "       systems:",
            needComma=0
            for system in omsaSysidIni.options("SystemsSupported"):
                system = "0x%s" % system
                system = int(system,0)
                if verbose>1:
                    if needComma: sys.stdout.write(",")
                    needComma=1
                    if oslistIni.has_option("id_to_name", "0x%04x" % system):
                        sys.stdout.write( " %s" % oslistIni.get("id_to_name", "0x%04x" % system))
                    else:
                        sys.stdout.write(" 0x%04x" % system)
                    sys.stdout.flush()

                dest = os.path.join(destDir, "system.ven_0x1028.dev_0x%04x" % system, dsaDir, "srvadmin")

                # copytree below has to have all dirs except last or it dies
                eatException(OSError, os.makedirs, dest)
                eatException(OSError, os.makedirs, dest + "-meta")
                shutil.rmtree(dest)
                shutil.rmtree(dest + "-meta")

                if firstDest:
                    hardLinkTree(firstDest, dest) 
                    hardLinkTree(firstDest+"-meta", dest+"-meta") 
                else:
                    firstDest = dest
                    shutil.copytree(omsaRpms, firstDest)
                    shutil.copytree(omsaMeta, firstDest + "-meta")
            if verbose>1:
                print "\n"
        if verbose>1:
            print "\n" + "="*80

def doYumRepo(destDir):
    doCreaterepo = 0
    doYumArch = 0
    if os.path.exists("/usr/bin/createrepo"):
        doCreaterepo = 1
    if os.path.exists("/usr/bin/yum-arch"):
        doYumArch = 1
    if not (doYumArch or doCreaterepo):
        raise getopt.GetoptError("The --yum option was specified, but I could not find yum-arch or createrepo.","")

    print 
    platforms = glob.glob(os.path.join(destDir, "*"))
    platforms.sort()
    for platformDir in platforms:
        if os.path.islink(platformDir):
            continue
        if not os.path.isdir(platformDir):
            continue
        repos = glob.glob(os.path.join(platformDir, "*"))
        repos.sort()
        for repo in repos:
            if os.path.islink(repo):
                continue
            if not os.path.isdir(repo):
                continue
            print "Yum repo for %s: " % repo, 
            sys.stdout.flush()
            if doCreaterepo: 
                print "createrepo ",
                sys.stdout.flush()
                status = os.system("createrepo %s >/dev/null 2>&1" % repo)
                if os.WTERMSIG(status) == 2:
                    raise KeyboardInterrupt()
            if doYumArch:    
                print "yum-arch", 
                sys.stdout.flush()
                status = os.system("yum-arch %s >/dev/null 2>&1" % repo)
                if os.WTERMSIG(status) == 2:
                    raise KeyboardInterrupt()
            print

def printOsDescriptions(ini, selectPlatform, selectOs):
    """
    NAME
        printOsDescriptions()

    DESCRIPTION
        Print list of OS tokens and the display name for each.
        Only print for OSes on selectPlatform or in selectOs

    CHANGELOG
        1.1     28-March-2006     Initial release

    AUTHOR
        Michael Brown

    """
    global verbose

    if verbose > 0:
        print "\nOS Descriptions:\n"

    osList = {}
    platforms = ini.options( "platforms" )
    for p in platforms:
        if selectPlatform and p not in selectPlatform: continue
        if p == "unknown": continue

        hasOs = 0
        for o in eval(ini.get("platforms", p)):
            if selectOs and o not in selectOs: continue
            osList[o] = 1

    for osName in osList.keys():
        print "%011s: %s" % (osName, ini.get(osName, "display_name"))

def printPlatformSupportMatrix(ini, selectPlatform, selectOs):
    """
    NAME
        printPlatformSupportMatrix(str, array, array)

    DESCRIPTION
        Displays platform and OS supported

    ARGUMENTS
        str =<input dir> DSA source
        array =<platform> Selected platform(s)
        array =<OS> Selected OS(s)

    CHANGELOG
        0.1     03-January-2006     Initial release

    AUTHOR
        Michael Brown
    """
    global verbose

    if verbose > 0:
        print "\nPlatform support matrix:\n"

    platforms = ini.options( "platforms" )
    for p in platforms:
        if selectPlatform and p not in selectPlatform: continue
        if p == "unknown": continue
        outLine =  "%s: " % p
        hasOs = 0
        for o in eval(ini.get("platforms", p)):
            if selectOs and o not in selectOs: continue
            outLine = outLine + " %s" % o
            hasOs = 1

        if (hasOs and verbose==1) or verbose==2:
            print outLine


fixDriverType=re.compile(r"[^a-zA-Z-_]")
def getDriversFromDir(oslistIni, action, inputDir, destDir, selectPlatform, selectOs):
    """
    NAME
        getDriversFromDir(str, str, str, array, array)

    DESCRIPTION
        Prints information about and copies driver from the DSA
        source to the destination dir

    ARGUMENTS
        array =<action> Select action like --extract or --info
        str =<input dir> DSA source
        str =<dest dir> DSA source
        array =<platform> Selected platform(s)
        array =<OS> Selected OS(s)

    CHANGELOG
        0.1     03-January-2006     Initial release
        0.2     04-April-2006       Updated Argument to make first argument an array 

    AUTHOR
        Michael Brown
    """
    if not os.path.exists( os.path.join( inputDir, "readme.txt" )) and verbose > 1:
        print "\n** INFO **\n No config file found, skipping %s" % inputDir
        return 0

    configFile = ConfigParser.ConfigParser()
    configFile.optionxform = str

    matrix = {}

    configFile.read(os.path.join( inputDir, "readme.txt" ))

    if configFile.has_option("driver_matrix", "supported"):
        matrix = eval(configFile.get( "driver_matrix", "supported" ))

    driverType = "unknown"
    if configFile.has_option("release_details", "driver_type"):
        driverType = eval(configFile.get( "release_details", "driver_type" ))
        driverType = fixDriverType.sub("_", driverType).lower()

    driverName = "unknown"
    if configFile.has_option("release_details", "driver_name"):
        driverName = eval(configFile.get( "release_details", "driver_name" ))

    if verbose > 0:
        print " %s = %s (%s)" % (os.path.basename(inputDir), driverType, driverName)

    haveCopiedDriver = None
    for opSys in matrix.keys():
        if selectOs and opSys not in selectOs:
            continue

        if verbose > 1:
            needComma=0
            sys.stdout.write("  %s:" % opSys)

        for platform in matrix[opSys]:
            if selectPlatform and platform not in selectPlatform:
                continue

            if verbose > 1:
                if needComma: sys.stdout.write(",")
                needComma=1
                sys.stdout.write(" %s" % platform)
                sys.stdout.flush()

            # don't go past this point if we are not extracting
            if "extract" not in action:
                continue

            platformDir = os.path.join( destDir, platform, opSys )
            relDir = os.path.join(platformDir, driverType, os.path.basename(inputDir))

            if not os.path.exists( relDir ):
                os.makedirs(relDir)
            if os.path.exists( relDir ):
                shutil.rmtree(relDir)

            if not haveCopiedDriver or "hardlink" not in action:
                shutil.copytree(inputDir, relDir)
                haveCopiedDriver = relDir
            else:
                hardLinkTree(haveCopiedDriver, relDir)

            if oslistIni.has_section("name_to_id"):
                if oslistIni.has_option("name_to_id", platform.lower()):
                    sysid=oslistIni.get("name_to_id", platform.lower())
                    venid="0x1028"
                    try:
                        os.unlink(os.path.join(destDir, "system.ven_%s.dev_%s"%(venid,sysid)))
                    except:
                        pass
                    try: # not all platforms support symlinks
                        os.symlink(platform, os.path.join(destDir, "system.ven_%s.dev_%s"%(venid,sysid)))
                    except:
                        pass

            if oslistIni.has_section("osnamemap"):
                if oslistIni.has_option("osnamemap", opSys):
                    for linkname in eval(oslistIni.get("osnamemap", opSys)):
                        try:
                            os.unlink(os.path.join(destDir, platform, linkname))
                        except:
                            pass
                        try: # not all platforms support symlinks
                            os.symlink(opSys, os.path.join(destDir, platform, linkname))
                        except:
                            pass

            #-- Change the read only attributes on the files for window systems so script can be re-run
            if os.name == 'nt':
                for (d, dirs, files) in walkPath(relDir):
                    for file in files: os.chmod(os.path.join(d, file), 0755)

            if opSys in ("w2000", "w2000sbs", "w2003", "w2003_64", "w2003sbs"):
                genPnpDriversPath( platformDir )

        if verbose > 1:
            print "\n"

    if verbose > 1:
        print "\n" + "="*80  


def genPnpDriversPath(topdir):
    """
    NAME
        genPnpDriversPath(str)

    DESCRIPTION
        Generates a pnpdriverpath.txt when a windows OS is
        selected

    ARGUMENTS
        str =<top dir> Top level directory

    CHANGELOG
        0.2     03-January-2006
         a) Changed OEMPnPDriversPath=; to OEMPnPDriversPath=drivers;
            and changed forward slash (/) to back slash (\) when ran
            on a linux system
        0.1     03-January-2006     Initial release

    AUTHOR
        Michael Brown & Jay Perusse
    """
    outFile = os.path.join(topdir, "pnpdriverpath.txt")
    driverpath="drivers"

    for (d, dirs, files) in walkPath(topdir):
        for lfd in dirs:
            driverpath="%s;%s" % (driverpath, os.path.join(d,lfd))

    #-- Replacing forward slash (/) with a back slash (\) - File is for Windows installation
    driverpath=driverpath.replace("/", "\\")
    fh = open(outFile, "w+")
    fh.write("oempnpdriverspath=%s" % driverpath)
    fh.close()

def hardLinkTree(source, dest):
    """
    NAME
        hardLinkTree(str)

    DESCRIPTION
        Generates dest path as a tree of hardlinks to source path

    ARGUMENTS
        source = string. directory path.
        dest   = string. directory path.

    CHANGELOG
        1.0     28-March-2006     Initial release

    AUTHOR
        Michael Brown
    """

    if not os.path.exists(dest):
        os.mkdir(dest)
    for d, dirs, files in walkPath(source):
        destPath = d.replace(source,dest)
        for newDir in dirs:
            os.mkdir( os.path.join( destPath, newDir ))
        for newFile in files:
            os.link( os.path.join(d,newFile), os.path.join(destPath,newFile) )

def walkPath(topdir, direction=0):
    """
    NAME
        walkPath(str, int=0)

    DESCRIPTION
        Generator function -- emulates the os.walk() generator
        in python 2.3 (mostly)

    ARGUEMENTS
        str =<top dir> Top level directory
        int = <direction> default to 0 (forward)

    RETURN
        (path, dirs, files) foreach dir

    CHANGELOG
        0.1     03-January-2006     Initial release

    AUTHOR
        Michael Brown
    """
    rawFiles = os.listdir(topdir)

    files=[f for f in rawFiles if os.path.isfile(os.path.join(topdir,f))]
    dirs =[f for f in rawFiles if os.path.isdir (os.path.join(topdir,f))]

    if direction == 0:
        yield (topdir, dirs, files)

    for d in dirs:
        if not os.path.islink(os.path.join(topdir,d)):
            for (newtopdir, newdirs, newfiles) in walkPath(os.path.join(topdir,d)):
                yield (newtopdir, newdirs, newfiles)

    if direction == 1:
        yield (topdir, dirs, files)



if __name__ == "__main__":
    sys.exit( main() )
