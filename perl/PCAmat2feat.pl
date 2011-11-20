#!/usr/bin/perl
use strict;

#echo PCAmat2feat.pl currdir matlabdir matlist featlist reduceDim
#mat dir $1/feature_mat/

my $curdir		= $ARGV[0];
my $codedir		= $ARGV[1];
my $MatListFile	= $ARGV[2];
my $FeatListFile= $ARGV[3];
my $reduceDim	= $ARGV[4];
my $bUseSavedPCAfeatMatrix = $ARGV[5];

my $Logfile = "$curdir/matlab.PCAmat2feat.out";
my $LogfileExt = "$curdir/matlab.PCAmat2feat.out.ext";

open(FILE,'>PCAmat2feat_run.m') || die @_;
print FILE "path(path,\'$codedir\')\n";
print FILE "PCAmat2feat(\'$curdir\',\'$codedir\',\'$MatListFile\',\'$FeatListFile\',$reduceDim,$bUseSavedPCAfeatMatrix,\'$LogfileExt\')\n";
print FILE "exit\n";
close(FILE);

system("matlab -nosplash -nodesktop -r PCAmat2feat_run -logfile $Logfile");

