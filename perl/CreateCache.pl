#!/usr/bin/perl

#Create directories for cache files

if( scalar(@ARGV) != 6 )
{
    print "Usage:  CreateCache.pl <ubm> <basescp> <srcdir> <des_dir> <slavenum> <code_dir>\n";
    exit(1);
}

use FindBin;
use lib "$FindBin::Bin/share"; 

use tytools;

$ubm = $ARGV[0];
$basescp = $ARGV[1];
$srcdir = $ARGV[2];
$desdir = $ARGV[3];
$slavenum = $ARGV[4];
$code_dir = $ARGV[5];

mySys("perl $code_dir/perl/splitscp.pl $basescp $slavenum");
# for( $i=0;$i<$slavenum; $i++ )
# {
    # mySys("qsub -cwd $code_dir/sh/CreateCache.sh ${code_dir}/b $desdir $srcdir $ubm $basescp.$i");
# }
# mySys("$code_dir/perl/tasksitter.pl `whoami` CreateCache.sh");

for( $i=0;$i<$slavenum; $i++ )
{
	mySys("${code_dir}/b/CreateCache -b -A -a $desdir $srcdir -t 20 $ubm $basescp.$i");
	#$1/CreateCache -b -A -a $2 $3 -t 20 $4 $5
}
