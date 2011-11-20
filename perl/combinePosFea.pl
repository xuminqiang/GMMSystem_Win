#!/usr/bin/perl
use strict;

my $curdir		= $ARGV[0];
my $codedir		= $ARGV[1];
my $FeatListFile= $ARGV[2];
my $coef		= $ARGV[3];
my $nn			= $ARGV[4];

my $Logfile		= "$curdir\\matlab.combineposfea.$nn.out";
my $LogfileExt	= "$curdir\\matlab.combineposfea.$nn.out.ext";

open(FILE, ">combineposfea_${nn}_run.m") || die @_;
print FILE "path(path,\'$codedir\');\n";
print FILE "combinePosFea(\'$FeatListFile\',$coef)\n";
print FILE "fid_LogfileExt=fopen(\'$LogfileExt\',\'w\');\n";
print FILE "fprintf(fid_LogfileExt,\'%s\\n\',[\'$LogfileExt\',\' done!\']);\n";
print FILE "fclose(fid_LogfileExt)\n";
print FILE "exit";

system("matlab -nosplash -nodesktop -r combineposfea_${nn}_run -logfile $Logfile");
