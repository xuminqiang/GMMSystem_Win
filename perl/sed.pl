#!/usr/bin/perl
use strict;

my $expr		= $ARGV[0];
my $src_file	= $ARGV[1];

my @nlines;
open(FILE,"$src_file") || die "can NOT open file $src_file for reading.\n";
chomp(@nlines=<FILE>);
close(FILE);

print join("$expr\n",@nlines);
print "$expr\n";
