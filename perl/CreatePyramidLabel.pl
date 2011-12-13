#!/usr/bin/perl
use strict;

#mySys("perl $code_dir/perl/createpyramidlabel.pl $pos_scp.$i $nPyramidPiece $feamode $i $code_dir $current_dir");

my $pos_scp			= $ARGV[0];
my $nPyramidPiece	= $ARGV[1];
my $feamode			= $ARGV[2];
my $nn				= $ARGV[3];
my $code_dir		= $ARGV[4];
my $current_dir		= $ARGV[5];

my $Logfile			= "$current_dir\\matlab.CreatePyramid.$nn.out";
my $LogfileExt		= "$current_dir\\matlab.CreatePyramid.$nn.out.ext";
#print "$pos_scp\n";

open(FILE,">CreatePyramid_run_${nn}.m") || die @_;
print FILE "path(path,\'$code_dir\\matlab\');\n";
print FILE "CreatePyramidLabel(\'$pos_scp\',str2num(\'$nPyramidPiece\'))\n";
print FILE "fid_LogfileExt=fopen(\'$LogfileExt\',\'w\');\n";
print FILE "fprintf(fid_LogfileExt,\'%s\\n\',[\'$LogfileExt\',\' done!\']);\n";
print FILE "fclose(fid_LogfileExt)\n";
print FILE "exit";

system("matlab -nosplash -nodesktop -r CreatePyramid_run_${nn} -logfile $Logfile");

