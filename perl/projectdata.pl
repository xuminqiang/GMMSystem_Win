#!/usr/bin/perl
use strict;

#echo PCAmat2feat.sh currdir matlabdir matlist featlist reduceDim
#mat dir $1/feature_mat/

my $curdir		= $ARGV[0];
my $codedir		= $ARGV[1];
my $MatListFile	= $ARGV[2];
my $FeatListFile= $ARGV[3];
my $nn			= $ARGV[4];

my $Logfile = "$curdir/matlab.projectdata.$nn.out";
my $LogfileExt = "$curdir/matlab.projectdata.$nn.out.ext";

open(FILE,">projectdata_${nn}_run.m") || die @_;
print FILE "path(path,\'$codedir\')\n";
print FILE "load(\'$curdir/PCAfeatmodel.mat\',\'PCAfeatmodel\');\n";
print FILE "PCAmatrixW=PCAfeatmodel.W;\n";
print FILE "ProjectData(PCAmatrixW,\'$MatListFile\',\'$FeatListFile\',\'$curdir\')\n";
print FILE "fid_LogfileExt=fopen(\'$LogfileExt\',\'w\');\n";
print FILE "fprintf(fid_LogfileExt,\'%s\\n\',[\'$LogfileExt\',\' done!\']);\n";
print FILE "fclose(fid_LogfileExt)\n";
print FILE "exit\n";
close(FILE);

system("matlab -nosplash -nodesktop -r projectdata_${nn}_run -logfile $Logfile");