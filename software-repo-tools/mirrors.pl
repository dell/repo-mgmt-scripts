#!/usr/bin/perl -w -T
use strict;

use CGI;
my $cgi = new CGI;

use File::Basename;
use Cwd 'abs_path';     # aka realpath()

print "Content-type: text/plain\n\n";

my $osname = $cgi->param('osname') || "null_OS";
my $thisdir=abs_path(dirname($0));

my $server_name = $ENV{"SERVER_NAME"} || "linux.dell.com";
my $request_path = $ENV{"SCRIPT_NAME"} || "/repo/software/mirrors.pl";
my $base_web_path = dirname($request_path);

$base_web_path =~ s|^/||;
$server_name =~ s|/$||;

print "http://$server_name/$base_web_path/$osname\n";
print "http://$server_name/$base_web_path/$osname\n";
print "http://$server_name/$base_web_path/$osname\n";
