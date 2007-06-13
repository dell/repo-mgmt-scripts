#!/usr/bin/perl -w -T
use strict;

use CGI;
my $cgi = new CGI;

use File::Basename;
use Cwd 'abs_path';     # aka realpath()

print "Content-type: text/plain\n\n";

my $ven_id = $cgi->param('sys_ven_id') || "0";
my $dev_id = $cgi->param('sys_dev_id') || "0";
my $osname = $cgi->param('osname') || "null_OS";
my $repo_config = $cgi->param('repo_config') || "latest";
my $dellname = $cgi->param('dellname') || "null_dellname";
my $thisdir=abs_path(dirname($0));

my $server_name = $ENV{"SERVER_NAME"} || "linux.dell.com";
my $request_path = $ENV{"SCRIPT_NAME"} || "/repo/hardware/mirrors.pl";
my $base_web_path = dirname($request_path);


# sanitize ven id
if ($ven_id !~ m/^0x/){
    # prepend 0x if necessary (old clients forgot this)
    $ven_id = "0x" . $ven_id;
}
# only allow valid hex digits
$ven_id =~ s/[^0-9a-fA-F]//g;
# convert to numeric
my $num_ven_id = hex($ven_id);
# and then back to sanitized string with correct format (zero-padded)
$ven_id = sprintf("0x%04x", $num_ven_id);

# sanitize dev id
if ($dev_id !~ m/^0x/){
    # prepend 0x if necessary (old clients forgot this)
    $dev_id = "0x" . $dev_id;
}
# only allow valid hex digits
$dev_id =~ s/[^0-9a-fA-F]//g;
# convert to numeric
my $num_dev_id = hex($dev_id);
# and then back to sanitized string with correct format (zero-padded)
$dev_id = sprintf("0x%04x", $num_dev_id);

$base_web_path =~ s|^/||;
$server_name =~ s|/$||;

my $url = "";
if ($dellname ne "null_dellname") {
    if (-d ($thisdir . "/${repo_config}/${dellname}/${osname}")) {
        $url = "http://${server_name}/${base_web_path}/${repo_config}/${dellname}/${osname}\n";
    } else {
        $url = "http://${server_name}/${base_web_path}/${repo_config}/emptyrepo/\n";
    }
} else {
    if (-d ($thisdir . "/${repo_config}/system.ven_${ven_id}.dev_${dev_id}/${osname}")) {
        $url = "http://${server_name}/${base_web_path}/${repo_config}/system.ven_${ven_id}.dev_${dev_id}/${osname}\n";
    } else {
        $url = "http://${server_name}/${base_web_path}/${repo_config}/emptyrepo/\n";
    }
}


print $url;
print $url;
print $url;
