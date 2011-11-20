#!/usr/bin/perl
use FindBin;
use lib "$FindBin::Bin/share"; 
use tytools;

print "HERest.pl NumSlave TmpDir Perldir ALL_HTK_ARGUMENTS\n";
################################################################################
#
# File: HERest.pl
# A perl script for parellel processing of the command 'HERest' from HTK
# 
# It seems that this parellel implelmenation of the 'HERest' does NOT produce
#   the same result. According to the HTK book, it seems that we need to put
#   equal number of data files into each of the processor which is not always
#   possible. So it's still experimental.
#
# Usage:
#	HERest.pl [options] hmmList dataFiles...
#
# For details about the usage, check it by typing "HERest" without any options.
#	
# This perl script is designed to run transparently, e.g., you can run this
#   script as if you run 'HERest'.
#
# This script submits parellel jobs through the SGE (Sun Grid Engine) using
#   an SGE command 'qsub' and checks the job progress using 'qstat'
# 
# It returns when all the parellel jobs are finished
#
# Written by Bowon Lee, 02/22/2006
#
# Department of the Electrical and Computer Engineering
# University of Illinois at Urbana-Champaign
#
################################################################################
#my $BINPATH='/workspace/fluffy0/programs/htk-3.4/bin.linux';
my $BINPATH='d:\code\gmmsystem_win\b';
my $perldir="$ARGV[2]";

# Specify the number of processors
$NP = $ARGV[0];	# Number of processors
if ($NP!~/^\d+$/){die "first argument ($ARGV[0]) must specifies num of slaves!\n";}

my $tmpdir=$ARGV[1];

# Specify the command to be executed
$COMMAND = "HERest";

print "PROCESSING PARALLEL: HERest.pl @ARGV \n";
# Check my user ID
#$USERID = readpipe("whoami");chomp $USERID;

# Check for the input script file following the option '-S'
#   and output HMM model file following the option '-M'
@ARGIN = @ARGV[3..$#ARGV];
foreach $n (0..$#ARGIN)  {
    $NSCP = $n+1 if($ARGIN[$n] eq "-S");
    $NMMF = $n+1 if($ARGIN[$n] eq "-M");
}
#print "DEBUG::::: $ARGIN[$#ARGIN] is the last arg\n";

$scpi = "$ARGIN[$NSCP]";
$mmfi = "$ARGIN[$NMMF]";

# Open the input script and compute the script size for each processor
open(SCP,"$scpi") || die "Cannot open $scpi: $!";
$NLINES = 0;
foreach (<SCP>) { $NLINES += 1; }
if ($NLINES<$NP){
    print "$NLINE data files, not enough to distribute to $NP slaves!! Ctrl C to aborted HERest.pl\n";
    getc;
    die;
}

$SCPSIZE = int($NLINES/$NP);
close(SCP);

# Create a list of divided data set
@scpn = ();
foreach $n (1..$NP)  {
    $scpn[$n-1] = "$scpi";
    $scpn[$n-1] = getFileNameExt($scpn[$n-1]);
    $scpn[$n-1] =~ s/(.*)(\..*)/\1\_$n\2/g;
    $scpn[$n-1] = $tmpdir.'/'.$scpn[$n-1];
}

# Divide the data set and write them into each script file
open(SCP,"$scpi") || die "Cannot open $scpi: $!";
$n = 0;
$nlines = 0;
foreach $line (<SCP>) {
    if( ($nlines == $SCPSIZE * $n) && ($n != $NP ) ) {	
	close(SCPPL);
	open(SCPPL, ">$scpn[$n]");
	print "writing to $scpn[$n]\n";
	$n = $n + 1;
    }
    print SCPPL "$line";
    $nlines += 1;
}
close(SCPPL);
print "small scp files done\n";
close(SCP);
# Create command for each processor
@commands = ();
foreach $n (1..$NP)  {
    $commands[$n-1] = "$BINPATH/$COMMAND";
    foreach $narg (0..$#ARGIN-1) {
	unless($narg == $NSCP ) {
	    if($ARGIN[$narg] =~ m/\*/)
	    { $commands[$n-1] = "$commands[$n-1] '$ARGIN[$narg]'"; }
 	    else
	    { $commands[$n-1] = "$commands[$n-1] $ARGIN[$narg]"; }
	}
	$commands[$n-1] = "$commands[$n-1] $scpn[$n-1]" if($narg == $NSCP);
#	print "DEBUG:::::::$scpn[$n-1]\n";
    }
    $commands[$n-1] = "$commands[$n-1] -p $n";
    $commands[$n-1] = "$commands[$n-1] $ARGIN[$#ARGIN]";
}


# Write script for each processor and submit the job
# foreach $n (0..$NP-1)  {
    # $scps = "$tmpdir/$COMMAND\_$n.sh";
    # open(SGESCP,">$scps") || die "Cannot open $scps: $!";
    # print SGESCP '#!/bin/bash';
    # print SGESCP "\n";
    # print SGESCP '#$ -S /bin/bash';
    # print SGESCP "\n";
    # print SGESCP '#$ -cwd';
    # print SGESCP "\n";
    # print SGESCP "\n";
    # print SGESCP "PATH=\$PATH:/cworkspace/ifp-32-1/hasegawa/programs/htk-3.4/HTKTools/";
    # print SGESCP "\n";
    # print SGESCP "export PATH";
    # print SGESCP "\n";
    # print SGESCP "$commands[$n]\n";
    # close SGESCP;
	# system("qsub $scps");
# }
foreach $n (0..$NP-1)  {
    $scps = "$tmpdir/$COMMAND\_$n.pl";
    open(SGESCP,">$scps") || die "Cannot open $scps: $!";
    print SGESCP '#!/usr/bin/perl';
    print SGESCP "\n";
    print SGESCP "\n";
    print SGESCP "system(\'$commands[$n]\')\n";
    close SGESCP;
	system("perl $scps");
}

# Wait until all the jobs are completed
#print "TASKSITTER waiting for completion of $USERID ${COMMAND}\_\n";
#system("$perldir/tasksitter.pl $USERID ${COMMAND}\_");

print "Done\n";

##Check any errors
# print "Checking any errors: ";
# @errors = readpipe("cat $COMMAND*.sh.e*");
# $errorcheck = $#errors + 1;
# if($errorcheck) {
    # system("cat $COMMAND*.sh.e* > ${tmpdir}/${COMMAND}\_errors");
    # print "errors in $COMMAND_errors\n";
# }
# else{print "None!\n";}

# Merge the results
print "Merging results: ";
$command = "${BINPATH}/HERest";
foreach $narg (0..$#ARGIN-1) {
    unless($narg == $NSCP || $narg == $NSCP-1) {
	if($ARGIN[$narg] =~ m/\*/)
	{ $command = "$command '$ARGIN[$narg]'"; }
	else
	{ $command = "$command $ARGIN[$narg]"; }
    }
}
$command = "$command -p 0";
#$command = "$command ";
#$command = "$command $ARGIN[$#ARGIN] $mmfi\/\*.acc";
$command = "$command $ARGIN[$#ARGIN]";
foreach $n(1..$NP)
{
$command = "$command $mmfi\/\HER${n}.acc";
}
system("$command");
print "MERGING BY DOING: $command\n";
# Clean temporary files
#print "Cleaning temporary files: ";

# foreach $n (0..$NP-1)  {
# #    system("rm -f $scpn[$n]");
    # system("rm -f $COMMAND\_$n.sh.e*");
    # system("rm -f $COMMAND\_$n.sh.o*");
# }		
# print "Done. \$COMMAND_\$n.sh.e/o\* removed\n";

# # If error occurred, then print this message
# if($errorcheck) {
    # print STDERR "Error occured: Please check ${tmpdir}/$COMMAND\_errors\n";
# }
