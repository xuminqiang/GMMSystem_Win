######################################################################################
#### SVFeatExtract.pl

#!/usr/bin/perl
use strict;
## Usage: $code_dir/perl/SVFeatExtract.pl ${rootdir}/scp/fea_ext.scp $i $code_dir $current_dir

my $scp 	= $ARGV[0];
my $codedir = $ARGV[1];
my $curdir	= $ARGV[2];
my $mfccorder = $ARGV[3];
my $nn		= $ARGV[4];

#write config for parameter extraction.
	open(HCFG,">$curdir/lparam.cfg") || die"lparam.cfg write fail\n";

	print HCFG "0	#HTK if 1, WAV if 0\n";
    print HCFG "300	#low cut-off\n";
    print HCFG "3400	#high cut-off\n";
    print HCFG "20	#num of filter banks\n";
    print HCFG "20	#frame length in ms\n";
    print HCFG "10	#frame shift in ms\n";
	print HCFG "$mfccorder	#num of mfcc order\n";
	print HCFG "0	#static mfcc 0\n";
	print HCFG "1	#static mfcc\n";
	print HCFG "0	#dynamic mfcc 0\n";
	print HCFG "1	#dynamic mfcc\n";
	print HCFG "0	#acce mfcc 0\n";
	print HCFG "0	#acce mfcc\n";
    close(HCFG);	

my @nlines;
open(FILE, "$scp") || die @_;
chomp(@nlines=<FILE>);
close(FILE);

open(FEAT,">$curdir\\reallists\\realfeatlist.${nn}.scp") || die "Can not open reallists file.\n";

for(my $i=0; $i<@nlines; $i=$i+1){
	my @tmp = split(/\s+/,$nlines[$i]);
	my $srcwav = $tmp[0];
	my $desfea = $tmp[1];
	
	system("$codedir\\b\\PreCut2 $srcwav $curdir\\tmpwav");
	#system("$codedir\\b\\lparam $curdir\\tmpwav $curdir\\tmp5 $curdir/lparam.cfg");
	system("$codedir\\b\\lparam $curdir\\tmpwav $curdir\\tmp1 $curdir/lparam.cfg");
	system("$codedir\\b\\lCMS $curdir\\tmp1 $curdir\\tmp2");
	system("$codedir\\b\\lRASTA $curdir\\tmp2 $curdir\\tmp3");
	system("$codedir\\b\\Prolongdata $curdir\\tmp3 $curdir\\tmp4 300");
	system("$codedir\\b\\Fwarping $codedir\\b\\normtable.txt $curdir\\tmp4 $curdir\\tmp5 300");
	system("$codedir\\b\\HTKtohtk $curdir\\tmp5 $desfea 0");
	
	print FEAT "$desfea\n";

}
close(FEAT);

