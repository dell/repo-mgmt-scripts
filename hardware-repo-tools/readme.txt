How to re-create this repo.

1) Make sure you install 'createrepo' and (optionally) 'yum-arch' on your system. (*)
2) copy the Dell Server Assistant(*) CD to a working directory.
3) copy the oslist-*.ini files into the ./dsa/ directory on the CD.
4) run the make_driver_dir.py(*) program.
    $ ./make_driver_dir.py -i ./path/to/dsa/ -v --extract -d ./path/to/output/dir --hardlink --do_yum

5) save some space (make_driver_dir.py will do some hardlinks, but this saves
   even more space)
    $ hardlink -vv ./path/to/output/dir/ 

6) the *.repo files are created with the create-repo-cfgs.sh script.
    $ create-repo-cfgs.sh ./path/to/output/dir dellhw.repo-template

7) post the resulting output directory to your web server in the normal
   fashion.


Notes:
 *-- createrepo is for new-format yum metadata. yum-arch is for old-format yum
 metadata. RHEL3 & RHEL4 use old-format metadata, RHEL5 uses new format.

 *-- DSA CD used to be called Dell Server Assistant. The CDs were re-arranged
 and it was renamed Installation and Server Management (ISM). It was
 re-arranged again, and may possibly be called the Common Deploy and Update
 (CDU) CD in the future.

 *-- The make_driver_dir.py program is a patched version of the same program
 that exists on the DSA CD. This modification has been submitted back to the
 DSA team and should be incorporated into a future version of the CD.
