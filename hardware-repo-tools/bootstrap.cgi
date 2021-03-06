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
my $request_path = $ENV{"SCRIPT_NAME"} || "/repo/hardware/$thisscript";
my $hardware_repo = dirname($request_path);

my $fd;
open $fd, "$thisdir/_tools/bootstrap.sh" or die "#oops...";
while(<$fd>)
{
    s|^SERVER=.*|SERVER="http://$server_name"|;
    s|^REPO_URL=.*|REPO_URL="$hardware_repo"|;
    print $_;
}
close($fd);

