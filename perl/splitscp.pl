#Split scp file for SPJ

if( scalar(@ARGV) != 2 && scalar(@ARGV) != 3 )
{
    print "Usage:  splitscp.pl <basescp> <splitnum> [des_dir]\n";
    exit(1);
}

use FindBin;
use lib "$FindBin::Bin/share"; 
use tytools;

use strict;

my $basefile =$ARGV[0];
my $snum = $ARGV[1];
my $rootdir = getFilePath( $basefile );
my $desfile;

if( scalar(@ARGV) == 3 )
{
    my $srcfile = getFileNameExt($basefile);
    my $despath = $ARGV[2];
    $despath =~ s/\/$//;    # strip trailing /
    $desfile = $despath . "/" . $srcfile;
}
else
{
    $desfile = $basefile;
}

my $parr = readFile($basefile);
my $srclen = @$parr;
my $perlen = int($srclen / $snum);

for( my $i=0; $i<$snum-1; $i++ )
{
    writeText( $desfile . "." . $i, join("\n", @$parr[($i*$perlen)..(($i+1)*$perlen-1)]) . "\n" );
}
my $tmpnum = $snum-1;
writeText( $desfile . "." . $tmpnum, join("\n", @$parr[(($snum-1)*$perlen)..($srclen-1)]) . "\n" );	   

my $outpath = getFilePath( $desfile );
print "done...$snum scp files are wroten to \'${outpath}/\'\n";
