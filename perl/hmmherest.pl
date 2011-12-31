#!/usr/bin/perl 
use FindBin;
use File::Copy;
use File::Path;
use lib "$FindBin::Bin/share"; 
use tytools;
use strict;
#TRAIN HMM (single CPU can handle at least 16,000 pics * 128 dim)

#perl d:\work\scene15\GMMSystem_win/perl/hmmherest.pl d:\work\scene15/HCopy.cfg d:\work\scene15/scp/herest.scp d:\work\scene15/mdl/hmm_all_refined_1_512 512 D:\work\scene15\run d:\work\scene15\GMMSystem_win/perl 1 1 D:\work\scene15\run/hinit.scp 0 10
if ($#ARGV!=9 && $#ARGV!=10) {die "hmmherest.pl HCopy.cfg TRAINSCP MODELFILENAME NUMMIX CURRDIR PERLDIR NUMSTATE NUMSLAVE HINITSCP transType [refineitenum]\n";}

my $transType=$ARGV[9]; #-1 L2R fixed .996 /.004   0 L2R / 1 ERGODIC / 2 Ergodic Identical Prob /3 Ergodic Biased Prob
my $updateOnly='';
if ($transType==2 ||$transType==3 || $transType==-1){
    $updateOnly=' -u mvw '; #mean variance weight only, NO transP update
}
my $selftransprob=0.8; #used only when transType==3

my $MODELFILENAME=$ARGV[2];
my $NoHCompV=0;
my $NUMSLAVE=$ARGV[7];
my $HINITSCP=$ARGV[8];
my $refineitenum=0; #num of refines after reaching mix
if ($#ARGV==10 && $ARGV[10]=~/[\d\+\.]+/){
    $refineitenum=$ARGV[10];
}
my $NoHCompV=0;
my $NUMMIX=$ARGV[3];
my $TRAINSCP=$ARGV[1];
my $MODELNAME='default';
my $current_dir=$ARGV[4];
my $SCRIPTPATH=$ARGV[5];

#my $BINPATH='/workspace/fluffy0/programs/htk-3.4/bin.linux';
my $BINPATH='d:\code\gmmsystem_win\b';
my $NUMSTATE=$ARGV[6]; #num of emitting states
my $HTKnumstate=$NUMSTATE+2;
my $skipHINIT=0;
$skipHINIT=1 if ($NUMSTATE==1);

#HCOPY example
#NUMCHANS = 128
#TARGETKIND = USER
#NATURALREADORDER = T
#BINARYACCFORMAT

print "START UBM...\n";
my $time = localtime(time);
print "$time\n";


open(TRAINLIST,"$TRAINSCP")||die "train files list open fail\n";
my @trainfiles=<TRAINLIST>;

rmtree("$current_dir/tmp.hmm");
#mySys("rm -rf $current_dir/tmp.hmm");
mkdir "$current_dir/tmp.hmm" unless -d "$current_dir/tmp.hmm";

#print "$trainfiles[0]\n";
#getc;

my $hcopycfgfile=@ARGV[0];

open(CFG,"$hcopycfgfile") || die "Unable to open cfg/HCopy.cfg!";
my %HTKCFG=(); #global
foreach my $l (<CFG>) { 
	my(@ls)=split(/\s+/,$l);
	if ($#ls == 2 and $ls[1]=~/\=/) {$HTKCFG{$ls[0]}=$ls[2]; }
	else {die "NOT TWO ITEMS: @ls \n";}
	}
close(CFG);

my $lastdir;

&TrainEventGMMFGlobal;

copy("$lastdir/$MODELNAME","$MODELFILENAME");	
#system("cp $lastdir/$MODELNAME $MODELFILENAME");

###################

sub TrainEventGMMFGlobal{

##################################################################
# Section 3: Use HCompV to compute the global mean and variance of cepstrum
    print "HCompV... \n";
    my $time = localtime(time);
	print "$time\n";

# First, create the HMM training config file, with subset of %HTKCFG
open(CFG,">$current_dir/tmp.hmm/Htrain.cfg") || die "Unable to write to $current_dir/tmp.hmm/Htrain.cfg: $!";
foreach my $entry ("NATURALREADORDER","NUMCHANS",'TARGETKIND')
{ print CFG "$entry = $HTKCFG{$entry}\n"; }

if (exists $HTKCFG{'BINARYACCFORMAT'}){ print CFG "BINARYACCFORMAT = $HTKCFG{'BINARYACCFORMAT'}\n"; }
close(CFG);

# Create the "proto" HMM
my $CURMMF="$current_dir/tmp.hmm/mmf";
mkdir "$CURMMF" unless -d "$CURMMF";
my $MMF="$CURMMF/proto";
open(MMF,">$MMF") || die "Unable to write to $MMF: $!";
print MMF '~o <VecSize> ',$HTKCFG{'NUMCHANS'},' <', $HTKCFG{'TARGETKIND'}, ">\n";
print MMF "~h \"proto\"\n<BeginHMM>\n <NumStates> 3\n <State> 2\n"; #
print MMF "  <Mean> $HTKCFG{'NUMCHANS'}\n   ";
foreach (1..$HTKCFG{'NUMCHANS'}) { print MMF " 0.0"; }
print MMF "\n  <Variance> $HTKCFG{'NUMCHANS'}\n   ";
foreach (1..$HTKCFG{'NUMCHANS'}) { print MMF " 1.0"; }
print MMF "\n <TransP> 3\n 0.0 1.0 0.0\n 0.0 0.6 0.4\n 0.0 0.0 0.0\n";
print MMF "<EndHMM>\n";
close MMF;


#generate train mlf  FEtmp/
open (SINGLETRAINMLF,">$current_dir/tmp.hmm/single_${MODELNAME}\.mlf") || die "write single mlf error\n";
print SINGLETRAINMLF "#\!MLF\!#\n";
foreach my $f (0..$#trainfiles){
    my $fname=$trainfiles[$f];
    chomp $fname;
#    print "$fname\n";
#    getc;
    $fname=~s/^(.*\/)(.+)(\.[a-zA-Z]+)$/$2/;
#    print "fnamefname: $fname\n";
#    open (LL,">lll");
#print LL "$fname\n";
#close LL;
#    getc;
    print SINGLETRAINMLF "\"\*\/$fname\.lab\"\n${MODELNAME}\n\.\n";
}
close SINGLETRAINMLF;

if ($NoHCompV==0){
# Now run HCompV with the prototype
mkdir "$CURMMF/protophones" unless -d "$CURMMF/protophones";
system("${BINPATH}/HCompV -A -T 1 -I $current_dir/tmp.hmm/single_${MODELNAME}\.mlf -C $current_dir/tmp.hmm/Htrain.cfg -m -f 0.001 -S $TRAINSCP -M $CURMMF/protophones $CURMMF/proto");
}
##### create HMMs for THIS event
# Read in the mean and variance vector from mmf/protophones/proto
open(PROTO,"$CURMMF/protophones/proto") || die "Unable to read $CURMMF/protophones/proto: $!";

my $PROTOMEAN;
my $PROTOVAR;

while(my $l=<PROTO>) {
    if($l =~ /Mean/i) 
    { $PROTOMEAN = <PROTO>; }
    elsif($l =~ /Variance/i) 
    { $PROTOVAR = <PROTO>; }
}
close(PROTO);

# Read in the variance floors
my $MMF="$CURMMF/protophones/vFloors";
open(VFLOORS,$MMF) || die "Unable to open $MMF: $!";
my @VFLOORS=<VFLOORS>;
close(VFLOORS);

# Create the HMM prototypes -- just copy from protophones/proto
my $HMM = "$CURMMF/protophones/$MODELNAME";
open(HMM,">$HMM") || die "Unable to write to $HMM: $!";
# Write the ~observation macro
print HMM '~o <VecSize> ',$HTKCFG{'NUMCHANS'},' <', $HTKCFG{'TARGETKIND'}, ">\n";
# Write the ~vfloors macro
print HMM @VFLOORS;

print HMM "~h \"$MODELNAME\"\n", "<BeginHMM>\n", " <NumStates> $HTKnumstate\n";

foreach my $state (2..($HTKnumstate-1)) {
    print HMM " <State> $state\n";
    print HMM "  <Mean> $HTKCFG{'NUMCHANS'}\n   $PROTOMEAN";
    print HMM "  <Variance> $HTKCFG{'NUMCHANS'}\n   $PROTOVAR";
}

if ($transType==0){

# Print the transition probability matrix for an L2R HMM
print HMM " <TransP> $HTKnumstate\n";
foreach my $m (1..$HTKnumstate) {
    foreach my $n (1..$HTKnumstate) {
	if($m==1 && $n==2) { print HMM " 1.0"; }
	elsif($m==$n && $m>1 && $n<$HTKnumstate) { print HMM " 0.6"; }  
	elsif($m==$n-1 && $m>1 && $m<$HTKnumstate) { print HMM " 0.4"; } 
	else { print HMM " 0.0"; }
    }
    print HMM "\n";
}

} #L2R
elsif ($transType==-1){

# Print the transition probability matrix for an L2R HMM
print HMM " <TransP> $HTKnumstate\n";
foreach my $m (1..$HTKnumstate) {
    foreach my $n (1..$HTKnumstate) {
	if($m==1 && $n==2) { print HMM " 1.0"; }
	elsif($m==$n && $m>1 && $n<$HTKnumstate) { print HMM " 0.996"; }  
	elsif($m==$n-1 && $m>1 && $m<$HTKnumstate) { print HMM " 0.004"; } 
	else { print HMM " 0.0"; }
    }
    print HMM "\n";
}

} #L2R fixed transp
elsif($transType==1||$transType==2){ #ergodic identical initial transp
print HMM " <TransP> $HTKnumstate\n";
foreach my $m (1..$HTKnumstate) {
    my $a=1/($HTKnumstate-2);
    my $b=1/($HTKnumstate-1);
    foreach my $n (1..$HTKnumstate) {
	if($m==1 && $n>1 && $n <$HTKnumstate-1){ print HMM " $a";}
	elsif($m==1 && $n==$HTKnumstate-1){my $ar=1-$a*($HTKnumstate-3);print HMM " $ar";}
	elsif($m>1 && $m <$HTKnumstate && $n>1 && $n<$HTKnumstate) { print HMM " $b";}
	elsif($m>1 && $m <$HTKnumstate && $n==$HTKnumstate) { my $br=1-$b*($HTKnumstate-2);print HMM " $br";}
	else { print HMM " 0.0"; }
    }
    print HMM "\n";
}
}
elsif($transType==3){ #ergodic biased initial transp
my    $changeprob=(1-$selftransprob)/($HTKnumstate-2);
print HMM " <TransP> $HTKnumstate\n";
foreach my $m (1..$HTKnumstate) {
    my $a=1/($HTKnumstate-2);
    foreach my $n (1..$HTKnumstate) {
	if($m==1 && $n>1 && $n <$HTKnumstate-1){ print HMM " $a";}
	elsif($m==1 && $n==$HTKnumstate-1){my $ar=1-$a*($HTKnumstate-3);print HMM " $ar";}
	elsif($m>1 && $m <$HTKnumstate && $n>1 && $n<$HTKnumstate && $m!=$n) { print HMM " $changeprob";}
	elsif($m>1 && $m <$HTKnumstate && $n>1 && $n<$HTKnumstate && $m==$n) { my $br=1-$changeprob*($HTKnumstate-2);print HMM " $br";}
	else { print HMM " 0.0"; }
    }
    print HMM "\n";
}

}
print HMM "<EndHMM>\n";
close HMM;

my $globalphf="$current_dir/tmp.hmm/$MODELNAME";
open (GLOBALPHF,">$globalphf")||die "$globalphf create fail\n";
print GLOBALPHF "${MODELNAME}\n";
close GLOBALPHF;

mkdir "$CURMMF/hinited" unless -d "$CURMMF/hinited";

my $modeltoest="$CURMMF/protophones/$MODELNAME";
if (!-e $modeltoest){die "HInit or HERest input not generated: $modeltoest !!\n";}

if ($skipHINIT==0){
print "\n== now HInit... \n";
my $time = localtime(time);
print "$time\n";
system("${BINPATH}/HInit $updateOnly -m 1 -A -T 1 -C $current_dir/tmp.hmm/Htrain.cfg -S $HINITSCP -M $CURMMF/hinited/ -I $current_dir/tmp.hmm/single_${MODELNAME}\.mlf -H $modeltoest $globalphf");

$modeltoest="$CURMMF/hinited/$MODELNAME";
if (!-e $modeltoest){die "HInit output not generated: $modeltoest !!\n";}
}
print "== now HRest...   ";

mkdir "$CURMMF/herested" unless -d "$CURMMF/herested";

my $time = localtime(time);
print "$time\n";
#system("date");
system("${SCRIPTPATH}/HERest.pl $NUMSLAVE $current_dir ${SCRIPTPATH} $updateOnly -w 1.0001 -m 1 -C $current_dir/tmp.hmm/Htrain.cfg -S $TRAINSCP -M $CURMMF/herested/ -I $current_dir/tmp.hmm/single_${MODELNAME}\.mlf -H $modeltoest $globalphf");
print "herested at $current_dir/tmp.hmm/mmf/herested/$MODELNAME\n";


$lastdir="$CURMMF/herested";
if (!-e "$lastdir/$MODELNAME"){
    die "First HERest.pl run failed: No  $lastdir/$MODELNAME !!!\n The following line fails!! \n ${SCRIPTPATH}/HERest.pl $NUMSLAVE $current_dir ${SCRIPTPATH} $updateOnly -w 1.0001 -m 1 -C $current_dir/tmp.hmm/Htrain.cfg -S $TRAINSCP -M $CURMMF/herested/ -I $current_dir/tmp.hmm/single_${MODELNAME}\.mlf -H $modeltoest $globalphf\n";
}
my $nmix=2;
my $lastmix;
while($nmix<=$NUMMIX){
#for($nmix=2; $nmix <= $NUMMIX; $nmix = $nmix*2) {

    print "mix $nmix ..\n";
	my $time = localtime(time);
	print "$time\n";
#   system("date");
	# Create the HHEd script for upmixing
	open(HEDF,">$current_dir/tmp.hmm/upmix$nmix.hhed") || die "Unable to write to upmix$nmix.hhed: $!";
    my $laststate=$HTKnumstate-1;
	print HEDF "MU $nmix \{ *.state\[2-${laststate}\].mix \}\n";
	close HEDF;
	

	# Upmix the MMF
	mkdir "$CURMMF/${nmix}G0" unless -d "$CURMMF/${nmix}G0";
	system("${BINPATH}/HHEd -C $current_dir/tmp.hmm/Htrain.cfg -A -T 1 -H $lastdir/$MODELNAME -M $CURMMF/${nmix}G0 $current_dir/tmp.hmm/upmix$nmix.hhed $globalphf");
	mkdir "$CURMMF/${nmix}G1" unless -d	"$CURMMF/${nmix}G1";

	system("${SCRIPTPATH}/HERest.pl $NUMSLAVE $current_dir ${SCRIPTPATH} $updateOnly -w 1.0001 -m 1 -C $current_dir/tmp.hmm/Htrain.cfg -S $TRAINSCP -M $CURMMF/${nmix}G1 -I $current_dir/tmp.hmm/single_${MODELNAME}\.mlf -H $CURMMF/${nmix}G0/$MODELNAME $globalphf");
	#normalize the weights of HMM.
	system("perl ${SCRIPTPATH}/HWeightNormalize.pl $CURMMF/${nmix}G1/$MODELNAME");
	
	$lastdir="$CURMMF/${nmix}G1";
    $lastmix=$nmix;
    if ($nmix<$NUMMIX && $NUMMIX<$nmix*2){$nmix=$NUMMIX;}
    else{$nmix=$nmix*2;}
	#$nmix=$nmix+1;
     }

my $pmix=$lastmix;
$lastdir="$CURMMF/${pmix}G1";

move("$lastdir","${lastdir}.0");
#system("mv $lastdir ${lastdir}.0");
my $lastrefinedir="${lastdir}.0";
foreach my $refineidx(1..$refineitenum){
    my $newrefinedir="${lastdir}.${refineidx}";
	mkdir "$newrefinedir" unless -d	"$newrefinedir";
	system("${SCRIPTPATH}/HERest.pl $NUMSLAVE $current_dir ${SCRIPTPATH} $updateOnly -w 1.0001 -m 1 -C $current_dir/tmp.hmm/Htrain.cfg -S $TRAINSCP -M $newrefinedir -I $current_dir/tmp.hmm/single_${MODELNAME}\.mlf -H $lastrefinedir/$MODELNAME $globalphf");
	#normalize the weights of HMM.
	system("perl ${SCRIPTPATH}/HWeightNormalize.pl $newrefinedir/$MODELNAME");
    $lastrefinedir=$newrefinedir;
    }
move("$lastrefinedir","${lastdir}");
#system("mv $lastrefinedir ${lastdir}");

print "final model in $lastdir/$MODELNAME\n";

}#sub TrainEventGMMF{

########################################
