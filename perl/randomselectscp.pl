#!/usr/bin/perl
use strict;

my $InputScp		= $ARGV[0];
my $OutputScp		= $ARGV[1];
my $Max_items		= $ARGV[2];
my $codedir			= $ARGV[3];
my $curdir			= $ARGV[4];

my $Logfile			= "$curdir\\matlab.randomselectscp.out";
my $LogfileExt		= "$curdir\\matlab.randomselectscp.out.ext";

open(FILE,'>randomselectscp_run.m') || die @_;
print FILE "path(path,\'$codedir\');\n\n";
print FILE "RandomSelectScp(\'$InputScp\',$Max_items,\'$OutputScp\');\n";
print FILE "fid_LogfileExt=fopen(\'$LogfileExt\',\'w\');\n";
print FILE "fprintf(fid_LogfileExt,\'%s\\n\',[\'$LogfileExt\',\' done!\']);\n";
print FILE "fclose(fid_LogfileExt)\n";
print FILE "exit";
close(FILE);

system("matlab -nosplash -nodesktop -r randomselectscp_run -logfile $Logfile");
