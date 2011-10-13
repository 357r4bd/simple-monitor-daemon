#!/bin/env perl -w
use strict;
use Getopt::Long;

# given a format string using the variable names
# one can get a formatted string with the values
# contained in the given status file

# example:
#   perl query_status.pl "%host%:%rundir%/%output%" < e1.finished
#
# This would return the string "bluedawg.loni.org:/mnt/estrabd/e1/e1.output.tgz"
# if 'e1.finished' looked contained at least the following 3 lines:
#  host=bluedawg.loni.org
#  rundir=/mnt/work/estrabd/e1
#  output=e1.output.tgz

my $FORMAT = '';
GetOptions("F=s" => \$FORMAT);

# build hash of values in status file

my %VALUES=();
while (<>) {
 chomp;
 $_ =~ m/(.*)=(.*)/;
 $VALUES{$1}=$2;
}

# run search and replace on format
$FORMAT =~ s/%([\s\w\d]+?)%/exists($VALUES{$1}) ? $VALUES{$1} : "%$1%"/ge;
print $FORMAT;
