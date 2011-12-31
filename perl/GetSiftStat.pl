#!/usr/bin/perl
use File::Basename;
use File::Path;
#use lib "/cworkspace/ifp-32-2/hasegawa/xizhou2/Trecvid/code/perl/share"; 
use FindBin;
use lib "$FindBin::Bin/share"; 
use tytools;

$scplist = $ARGV[0];
$ubmfn = $ARGV[1];
$gmmfeadir = $ARGV[2];
$idn = $ARGV[3];
$code_dir= $ARGV[4];
$current_dir=$ARGV[5];
$src_dir = $ARGV[6];
$des_dir = $ARGV[7];
if( scalar(@ARGV) == 9 )
{
    $hcopy_cfg = $ARGV[8];
}

if ($current_dir=~/^\s*$/){die "CURRENTDIR in GetSiftStat.pl wrong!!!\n";}
$parr = readFile($scplist);

@tmpscp = ();
$curpath = ();
foreach $curfn (@$parr)
{
	$curmdl = $curfn;
#	$fpath = getFilePath($curfn);
    
	writeText("$current_dir/tmplist_ml_${idn}.scp", $curfn . "\n");
	$curmdl =~ s/$src_dir/$gmmfeadir/;
    
	#print "$curmdl\n";
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
	$curmdl =~ s/\//\\/g;
	#print "$curmdl\n";
	
	
    $tmppath = dirname($curmdl);
	#print "tmppath = $tmppath\n";
	if (!(-e $tmppath))
    {
        system("mkdir $tmppath");
    }
	#$curmdl =~ s/\//\_/g;
	
	if( scalar(@ARGV) == 8 )
	{
	    mySys("$code_dir/b/LAdapt -A -a $des_dir $src_dir -b -o -c 0 -f wmv ${ubmfn}_bin ${curmdl} $current_dir/tmplist_ml_${idn}.scp");
	    
	}	
	else
	{
	    mySys("perl $code_dir/perl/hmmmapmw.pl $hcopy_cfg $current_dir/tmplist_ml_${idn}.scp $ubmfn ${curmdl} $current_dir");
	}
}
