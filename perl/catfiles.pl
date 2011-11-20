#!/usr/bin/perl
use strict;
use warnings;

foreach my $file(@ARGV){
	my @nlines;
	open(FILE,"$file") || die "can NOT open file $file for reading.\n";
	chomp(@nlines=<FILE>);
	close(FILE);
	print join("\n",@nlines);
	print "\n";
}

