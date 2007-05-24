#!/usr/bin/python2
# vim:expandtab:autoindent:tabstop=4:shiftwidth=4:filetype=python:

# import arranged alphabetically
import getopt
import os
import rpmUtils
import shutil
import sys
import traceback
import types
import rpmUtils
import rpmUtils.transaction


from decorator import decorator

import mebtrace

# levels:
#   0: Nothing
#   1: Basic
#   3: Detailed
#   9: ENTER/LEAVE

mebtrace.debug = {
    '__main__': 0,
    }

@mebtrace.trace
@mebtrace.setModule(module="fileCopy_module")
def fileCopy(inputDir, outputDir, file):
    inputDir = os.path.realpath(inputDir)
    outputDir = os.path.realpath(outputDir)
    file = os.path.realpath(file)
    dest = outputDir + file[ len(inputDir): ]
    
    mebtrace.dprint("inputDir : '%s'\n" % inputDir)
    mebtrace.dprint("outputDir: '%s'\n" % outputDir)
    mebtrace.dprint("file     : '%s'\n" % file)
    mebtrace.dprint("dest     : '%s'\n" % dest)

    if not os.path.exists( os.path.dirname(dest) ):
        os.makedirs( os.path.dirname(dest) )

    if not os.path.exists(dest):
        shutil.copyfile( file, dest )


def main():
    inputRepo = None
    outputRepo = None
    checkOnly=False
    try:
        opts, args = getopt.getopt(sys.argv[1:], "i:o:vc", ["input-repo=", "output-repo=", "verbose", "check-only"])
        for option, argument in opts:
            if option in ("-i", "--input-repo"):
                inputRepo = argument
            if option in ("-o", "--output-repo"):
                outputRepo = argument
            if option in ("-c", "--check-only"):
                checkOnly = True
            if option in ("-v", "--verbose"):
                mebtrace.debug["__main__"] = mebtrace.debug["__main__"] + 3

        if inputRepo is None: raise getopt.GetoptError("no input dir", "no input dir")

        for (dirpath, dirnames, filenames) in os.walk(inputRepo):
            for file in filenames:
                file = os.path.realpath(os.path.join(dirpath, file))
                ts = rpmUtils.transaction.initReadOnlyTransaction()
                try:
                    hdr = rpmUtils.miscutils.hdrFromPackage(ts, file)
                    sig = rpmUtils.miscutils.getSigInfo(hdr)
                    mebtrace.dprint("got hdr: %s\n" % repr(hdr))
                    mebtrace.dprint("%s\n" % str(rpmUtils.miscutils.getSigInfo(hdr)))
                    if sig[0] == 0 and outputRepo:
                        fileCopy(inputRepo, outputRepo, file)
                        os.unlink(file)
                    elif sig[0] and (not outputRepo or checkOnly):
                        # no ouput, just report if outputRepo not set
                        print "No signature: %s" % file
                except rpmUtils.RpmUtilsError, e:
                    mebtrace.dprint("could not open rpm: %s" % file)

    except (Exception), e:
        print str(e)
        sys.exit(2)

    except (getopt.GetoptError):
        print __doc__
        sys.exit(1)

    except:
        traceback.print_exc()
        sys.exit(2)

    sys.exit(0)

if __name__ == "__main__":
    main()
