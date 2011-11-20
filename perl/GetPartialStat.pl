#!/usr/bin/perl
use File::Basename;
use File::Path;

$scplist = $ARGV[0];
$ubmfn = $ARGV[1];
$gmmfeadir = $ARGV[2];
$idn = $ARGV[3];
$code_dir= $ARGV[4];
$current_dir=$ARGV[5];
$src_dir = $ARGV[6];
$des_dir = $ARGV[7];

if ($current_dir=~/^\s*$/){die "CURRENTDIR in GetPartialStat.pl wrong!!!\n";}

use FindBin;
use lib "$FindBin::Bin/share"; 
use tytools;

$parr = readFile($scplist);

@tmpscp = ();
$curpath = ();
foreach $curfn (@$parr)
{
	$curmdl = $curfn;
	($curmdl) = split(/\s+/,$curfn);
	
	writeText("$current_dir/tmplist_ml_${idn}.scp", $curfn . "\n");

    #$curmdl =~ s/$src_dir/$gmmfeadir/;
	my($idx,$pos,$pre) = {-1,0,-1};
	while(1){
		$idx = index( $curmdl, $src_dir, $pos );
		substr $curmdl, $idx, length($src_dir), $gmmfeadir ;
		if($idx == $pre){
			last;
		}else{
			$idx = $idx+length($src_dir)-1;
			$pre = $idx;
			$pos = $idx;
			}
	}
	
    $tmppath = dirname($curmdl);
    unless (-e $tmppath)
    {
     #   system("mkdir -p $tmppath");
	    mkdir $tmppath;
    }
	#$curmdl =~ s/\//\_/g;

	mySys("$code_dir/b/LAdapt -A -a $des_dir $src_dir -p 0 -b -o -c 0 -f wmv ${ubmfn}_bin $curmdl $current_dir/tmplist_ml_${idn}.scp");
}
