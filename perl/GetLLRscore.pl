#!/usr/bin/perl

use strict;
use File::Path;

if( scalar(@ARGV) < 7 || scalar(@ARGV) >9 )
{
    print "Usage:  GetLLRscore.pl <taretMdl_dir> <UBMfn> <trialListfn> <feature_dir> <OutputScorefn> <code_dir> <current_dir> [fea_ext]\n";
    exit(1);
}

my $tarmdldir	= $ARGV[0];
my $ubmfn		= $ARGV[1];
my $triallist	= $ARGV[2];
my $feadir		= $ARGV[3];
my $scorefn		= $ARGV[4];
my $codedir		= $ARGV[5];
my $curdir		= $ARGV[6];

my $feaext		= "sift";
if(scalar(@ARGV) == 8){
	$feaext		= $ARGV[7];
}

# my $tarmdldir = "F:\\work\\SV\\sre08_10sec_10sec\\male\\gmmfea_hmm_all_refined_1_256\\train";
# my $ubmfn	= "F:\\work\\SV\\sre08_10sec_10sec\\male\\mdl\\hmm_all_refined_1_256_bin";
# my $triallist = "F:\\work\\SV\\sre08_10sec_10sec\\male\\scp\\10sec-10sec_male.ndx";
# my $feadir = "F:\\work\\SV\\sre08_10sec_10sec\\male\\features\\test";
# my $scorefn = "F:\\work\\SV\\sre08_10sec_10sec\\male\\score\\score.txt";
# my $codedir = "D:\\code\\GMMSystem_Win";
# my $curdir = "F:\\work\\SV\\sre08_10sec_10sec\\male\\run";
# my $feaext = "sift";

my $tarscoredir = "$curdir/tmp.score";
my $testfeascpdir = "$curdir/tmp.list";

if(-e "$tarscoredir"){rmtree("$tarscoredir");}
if(-e "$testfeascpdir"){rmtree("$testfeascpdir");}
if(-e "$scorefn"){unlink "$scorefn";}

mkdir("$tarscoredir");
mkdir("$testfeascpdir");

my (@nlines,@ntmps,$line);
my %hash=();

open(FILE,"$triallist") || die "Can not open $triallist for reading.\n";
chomp(@nlines=<FILE>);
close(FILE);

foreach $line(@nlines){
	@ntmps=split(/\s+/,$line);

	if(exists $hash{"$ntmps[0]"}){
		$hash{"$ntmps[0]"} = "$hash{\"$ntmps[0]\"} $ntmps[1]";
	}else{
		$hash{"$ntmps[0]"} = "$ntmps[1]";
	}
}
my ($key,$value);
while(($key,$value) = each(%hash)){
	#print "$key==>$value\n";
	my $tar = $key;
	my $testfeascp = "$testfeascpdir\\$tar"; 
	open(TAR,">$testfeascp") || die "Can not open $testfeascp for writing.\n";
	@ntmps = split(/\s+/,$value);
	foreach my $wav(@ntmps){
		my @nparts = split(/\.|:/,$wav);
		my $fea = "$nparts[0]_$nparts[-1].$feaext";
		print TAR "$feadir\\$fea\n";
	}
	close(TAR);
	
	my $tarmdl = "$tarmdldir\\$tar.$feaext";
	my $tarscorefn = "$tarscoredir\\$tar";
	
	system("$codedir/b/UBMLProb.exe -b $tarmdl $ubmfn $testfeascp $tarscorefn");
	
#	system("perl $codedir/perl/catfiles.pl $tarscorefn >> $scorefn");
}

open(FILE,">$scorefn") || die "Can not open file $scorefn for writing.\n";
while(($key,$value)=each(%hash)){
	open(TAR,"$tarscoredir/$key") || die "Can not open file $tarscoredir/$key for reading.\n";
	chomp(@nlines=<TAR>);
	close(TAR);
	foreach $line(@nlines){
		@ntmps = split(/\s+/,$line);
		print FILE "$key $ntmps[0] $ntmps[-1]\n";
	}
}
close(FILE);

