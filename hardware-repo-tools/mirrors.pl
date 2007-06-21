#!/usr/bin/perl -w -T
# vim:et:ts=4:sw=4:ai:tw=0
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

sub sanitize_id {
    my $id = shift;
    # sanitize ven id
    if ($id !~ m/^0x/){
        # prepend 0x if necessary (old clients forgot this)
        $id = "0x" . $id;
    }
    # only allow valid hex digits
    $id =~ s/[^0-9a-fA-F]//g;
    # and then back to sanitized string with correct format (zero-padded)
    return sprintf("0x%04x", hex($id));
}

print "Content-type: text/plain\n";

my $debug = $cgi->param('debug') || 0;
my $redirect = $cgi->param('redirect') || 0;
my $redir_path = $cgi->param('redir_path') || '';

my $ven_id = $cgi->param('sys_ven_id') || "0x00";
my $dev_id = $cgi->param('sys_dev_id') || "0x00";
$ven_id = sanitize_id($ven_id);
$dev_id = sanitize_id($dev_id);

my $osname = $cgi->param('osname') || "null_OS";
my $basearch = $cgi->param('basearch') || "null_basearch";
# backwards compat to old-style
if($osname =~ m|^(\w+)\.(\w+)$|)
{
    $osname = $1;
    $basearch = $2;
}

my $repo_config = $cgi->param('repo_config') || "latest";
if ($repo_config eq "\$repo_config")  {$repo_config="latest";}

my $dellname = $cgi->param('dellname') || "null_dellname";
my $thisdir=abs_path(dirname($0));

my $server_name = $ENV{"SERVER_NAME"} || "linux.dell.com";
$server_name =~ s|/$||;

my $request_path = $ENV{"SCRIPT_NAME"} || "/repo/hardware/mirrors.pl";
my $base_web_path = dirname($request_path);
$base_web_path =~ s|^/||;

# this is the list of osnames that the OS generates
my %links = (
    # RHEL 3 variants
    el3AS => 'el3',
    el3ES => 'el3',
    el3WS => 'el3',
    el3Desktop => 'el3',
    rhel3 => 'el3',

    # RHEL 4 variants
    el4AS => 'el4',
    el4ES => 'el4',
    el4WS => 'el4',
    el4Desktop => 'el4',
    rhel4 => 'el4',

    # RHEL 5 variants
    el5Client => 'el5',
    el5Server => 'el5',
    rhel5 => 'el5',
    );

$osname = $links{$osname} if defined $links{$osname};

my %dsamapping = (
    'el3.i386' => 'rh30',
    'el3.x86_64' => 'rh30_64',
    'el4.i386' => 'rh40',
    'el4.x86_64' => 'rh40_64',
    'el5.i386' => 'rh50',
    'el5.x86_64' => 'rh50_64',
    'sles9.i386' => 'sles9',
    'sles9.x86_64' => 'sles9_64',
    'sles10.i386' => 'sles10',
    'sles10.x86_64' => 'sles10_64',
    );

$osname = $dsamapping{$osname .".". $basearch} if defined $dsamapping{$osname .".".  $basearch};

my $url = "";
if ($dellname ne "null_dellname") {
    if (-d ($thisdir . "/${repo_config}/${dellname}/${osname}")) {
        $url = "http://${server_name}/${base_web_path}/${repo_config}/${dellname}/${osname}";
    } elsif (-d ($thisdir . "/${repo_config}/platform_independent/${osname}")) {
        $url = "http://${server_name}/${base_web_path}/${repo_config}/platform_independent/${osname}";
    } elsif (-d ($thisdir . "/${repo_config}")) {
        $url = "http://${server_name}/${base_web_path}/${repo_config}/emptyrepo/";
    } else {
        $url = "http://${server_name}/${base_web_path}/latest/emptyrepo/";
    }
} else {
    if (-d ($thisdir . "/${repo_config}/system.ven_${ven_id}.dev_${dev_id}/${osname}")) {
        $url = "http://${server_name}/${base_web_path}/${repo_config}/system.ven_${ven_id}.dev_${dev_id}/${osname}";
    } elsif (-d ($thisdir . "/${repo_config}/platform_independent/${osname}")) {
        $url = "http://${server_name}/${base_web_path}/${repo_config}/platform_independent/${osname}";
    } elsif (-d ($thisdir . "/${repo_config}")) {
        $url = "http://${server_name}/${base_web_path}/${repo_config}/emptyrepo/";
    } else {
        $url = "http://${server_name}/${base_web_path}/latest/emptyrepo/";
    }
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

if ($debug == 1){
    print "#debug: $repo_config, $dellname, $osname, $basearch, $ven_id, $dev_id\n";
}
