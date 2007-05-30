#!/usr/bin/perl -w -T
use strict;

use CGI;
my $cgi = new CGI;

use File::Basename;
use Cwd 'abs_path';     # aka realpath()

print "Content-type: text/plain\n\n";

my $thisdir=abs_path(dirname($0));
my $thisscript=basename($@);

my $server_name = $ENV{"SERVER_NAME"} || "linux.dell.com";
my $request_path = $ENV{"SCRIPT_NAME"} || "/repo/software/$thisscript";
my $software_repo = dirname($request_path);
my $base_repo = dirname($software_repo);
my $hardware_repo = "$base_repo/hardware";

my $fd;
open $fd, "$thisdir/.bootstrap.sh" or die "#oops...";
while(<$fd>)
{
    s|^SOFTWARE_SERVER=.*|SOFTWARE_SERVER="http://$server_name"|;
    s|^SOFTWARE_REPO_URL=.*|SOFTWARE_REPO_URL="$software_repo"|;
    s|^HARDWARE_SERVER=.*|HARDWARE_SERVER="http://$server_name"|;
    s|^HARDWARE_REPO_URL=.*|HARDWARE_REPO_URL="$hardware_repo"|;
    print $_;
}
close($fd);

