#!/usr/bin/perl -w -T
use strict;

use CGI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
my $cgi = new CGI;

# to support sles, which cannot send a query string, uses PATH_INFO instead.
if (not $ENV{"QUERY_STRING"}) {
    use lib "_tools";
    use PathInfo;
    $cgi = CGI::PathInfo->new({  Eq => '=', SplitOn => '&', });
}

use File::Basename;
use Cwd 'abs_path';     # aka realpath()

print "Content-type: text/plain\n";

my $osname = $cgi->param('osname') || "cross-distro";
my $basearch = $cgi->param('basearch') || "null_ARCH";
my $thisdir=abs_path(dirname($0));

my $debug = $cgi->param('debug') || 0;
my $redirect = $cgi->param('redirect') || 0;
my $redir_path = $cgi->param('redir_path') || '';

my $server_name = $ENV{"SERVER_NAME"} || "linux.dell.com";
my $request_path = $ENV{"SCRIPT_NAME"} || "/repo/firmware/mirrors.pl";
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
    #Centos/Scientific
    'el4.0' => 'el4',
    'el4.1' => 'el4',
    'el4.2' => 'el4',
    'el4.3' => 'el4',
    'el4.4' => 'el4',
    'el4.5' => 'el4',
    #future el4 variants
    'el4.6' => 'el4',
    'el4.7' => 'el4',
    'el4.8' => 'el4',
    'el4.9' => 'el4',

    el5Client => 'el5',
    el5Server => 'el5',
    rhel5 => 'el5',
    #Centos/Scientific
    'el5.0' => 'el5',
    #future el5 variants
    'el5.1' => 'el5',
    'el5.2' => 'el5',
    'el5.3' => 'el5',
    'el5.4' => 'el5',
    'el5.5' => 'el5',
    'el5.6' => 'el5',
    'el5.7' => 'el5',
    'el5.8' => 'el5',
    'el5.9' => 'el5',
    );

$osname = $links{$osname} if defined $links{$osname};


my $url="";
if (-d ($thisdir . "/$osname/$basearch")) {
    $url = "http://$server_name/$base_web_path/$osname/$basearch";
}
elsif (-d ($thisdir . "/$osname")) {
    $url = "http://$server_name/$base_web_path/$osname";
}
else {
    $url = "http://$server_name/$base_web_path/cross-distro";
}


if ($redirect){
    print "Status: 301 Moved Permanantly\n";
    print "Location: $url$redir_path\n";
    print "\n";  # END OF HTTP HEADERS
    # NO CONTENT
} else {
    print "\n";  # END OF HTTP HEADERS
    print $url . "\n";
}

#if ($debug == 1){
#    print "#debug: $repo_config, $dellname, $osname, $basearch, $ven_id, $dev_id\n";
#}
