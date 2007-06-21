#!/usr/bin/perl -w -T
# vim:et:ts=4:sw=4:ai:tw=0
use strict;

use CGI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

print "Content-type: text/plain\n";
print "\n";

use Data::Dumper;

use CGI;
my $cgi = new CGI;

print "DEBUG: " . $cgi->param() . "\n\n\n";

print "START\n";
print Dumper(%ENV);
print "\nEND\n";
