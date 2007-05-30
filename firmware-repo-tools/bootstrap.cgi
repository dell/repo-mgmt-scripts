#!/usr/bin/perl -w -T
use strict;

use CGI;
my $cgi = new CGI;

use File::Basename;
use Cwd 'abs_path';     # aka realpath()

print "Content-type: text/plain\n\n";

my $thisdir=abs_path(dirname($0));
my $thisscript=basename($@);

my $server_name = $ENV{"SERVER_NAME"} || "fwupdate.com";
my $request_path = $ENV{"SCRIPT_NAME"} || "/repo/firmware/$thisscript";
my $firmware_repo = dirname($request_path);
my $base_repo = dirname($firmware_repo);
my $hardware_repo = "$base_repo/hardware";

if ($server_name eq "linux.dell.com") {
    $server_name="repo.fwupdate.com";
}

my $fd;
open $fd, "$thisdir/.bootstrap.sh" or die "#oops...";
while(<$fd>)
{
    s|^FIRMWARE_SERVER=.*|FIRMWARE_SERVER="http://$server_name"|;
    s|^FIRMWARE_REPO_URL=.*|FIRMWARE_REPO_URL="$firmware_repo"|;
    print $_;
}
close($fd);

