#!/usr/bin/perl
use strict;

use File::Copy;

my $MODELNAME = $ARGV[0];

# NORMALIZE THE WEIGHTS OF the HMM MODEL 
open(MODEL,$MODELNAME) || die "Unable to open $MODELNAME: $!";
my $NUMMIX;
my @WEIGHTS="";
my $total=0.0;
while(my $l=<MODEL>){
	if($l =~ /NUMMIXES/i){
		my @tmp = split(/\s+/,$l);
		$NUMMIX = $tmp[-1];
	}
	if($l =~ /MIXTURE/i){
		my @tmp = split(/\s+/,$l);
		if(@WEIGHTS eq ""){
			@WEIGHTS="$tmp[-1]";
		}else{
			push(@WEIGHTS,"$tmp[-1]");
		}
		$total += $tmp[-1];
	}
}
for(my $i=0;$i<@WEIGHTS;$i++){
	$WEIGHTS[$i] = $WEIGHTS[$i]/$total;
}
close(MODEL);

my @nlines;
open(MODEL,$MODELNAME) || die "Unable to open $MODELNAME: $!";
@nlines = <MODEL>;
close(MODEL);

my $HMM = "${MODELNAME}.0";
open(HMM,">$HMM") || die "Unable to write to $HMM: $!";
my $mix=0;
foreach my $l(@nlines){
	if($l =~ /MIXTURE/i){
		#print "$l\n";
		my @tmp = split(/\s+/,$l);
		$mix += 1;
		print HMM "$tmp[0] $tmp[1] $WEIGHTS[$mix]\n";
		}else{
		print HMM "$l";
	}
}
close(HMM);

if("$mix" eq "$NUMMIX"){
	copy("${MODELNAME}.0","$MODELNAME");
	unlink("${MODELNAME}.0");
}else{
	print "number of mixture does not match!\n"
}
