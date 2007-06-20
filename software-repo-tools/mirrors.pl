#!/usr/bin/perl -w -T
use strict;

use CGI;
my $cgi = new CGI;

use File::Basename;
use Cwd 'abs_path';     # aka realpath()

print "Content-type: text/plain\n\n";

my $osname = $cgi->param('osname') || "null_OS";
my $basearch = $cgi->param('basearch') || "null_ARCH";
my $thisdir=abs_path(dirname($0));

my $server_name = $ENV{"SERVER_NAME"} || "linux.dell.com";
my $request_path = $ENV{"SCRIPT_NAME"} || "/repo/software/mirrors.pl";
my $base_web_path = dirname($request_path);

$base_web_path =~ s|^/||;
$server_name =~ s|/$||;

my %links = (
    el3AS => 'el3',
    el3ES => 'el3',
    el3WS => 'el3',
    el3Desktop => 'el3',
    rhel3 => 'el3',

    el4AS => 'el4',
    el4ES => 'el4',
    el4WS => 'el4',
    el4Desktop => 'el4',
    rhel4 => 'el4',

    el5Client => 'el5',
    el5Server => 'el5',
    rhel5 => 'el5',
    );

$osname = $links{$osname} if defined $links{$osname};

if (-d ($thisdir . "/$osname/$basearch")) {
    print "http://$server_name/$base_web_path/$osname/$basearch\n";
}
elsif (-d ($thisdir . "/$osname")) {
    print "http://$server_name/$base_web_path/$osname\n";
}
