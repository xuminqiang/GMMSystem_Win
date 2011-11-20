#!/usr/bin/perl

###CAUTION!!!!!!! INFO FOR PROCESSING QUERIES
###feature PCA (PCAfeatmodel.mat in PCAmat2feat.sh ###PCAfeat###) 
###supervector PCA (look for labels in this file "##findpro##") 
#To use saved feature PCA matrix (copy over $current_dir/PCAfeatmodel.mat), set bUseSavedPCAfeatMatrix=1 in PCAmat2feat.sh
#To use saved supervector PCA matrix(copy over ${rootdir}/nap/PCA_${ubmfile}_${pca_dim}), set $bUseSavedPCAsupervecMatrix=1 below in this file
###should copy over old UBM, and set $SKIPUBM=1 when processing queries

use File::Path;
use File::Copy;
#use FindBin;
#use lib "$FindBin::Bin/share"; 
use lib "f:\\code\\gmmsystem_win\\perl\\share";
use tytools;
use strict;



#####################################################################
#                                                                   #
#      Set Parameters                                               #
#                                                                   #
#####################################################################

my $bUseSavedPCAsupervecMatrix=0;
my $bUseSavedPCAfeatMatrix=0;

my $SKIPFEAT     = 1;
my $SKIPUBM      = 0;
my $SKIPCACHE    = 1;
my $SKIPPYRAMID  = 1;
my $SKIPADAPT    = 1;
my $SKIPSUPERVEC = 1;
my $gama = 0;

my $nPartial = 2;

my $bPatchSift=2; # set to 9 for color moment; set to 1 for patch sift; set to 2 for patch sift using Svetlana's code
my $bIncludeBlank=0;
my $nOx=4; #set to 20 (number of blocks) for color_moment, i.e., when (bPatchSift==9)
my $nOy=4; #set to 20 (number of blocks) for color_moment, i.e., when (bPatchSift==9)
#my $nPatchSize='\'16 24\'';
my $nPatchSize=16;

my $feadim = 128; # sift 128; set to 9 when using color_moment

#reduce 0 no 1 dct 2 pca ;     set MaxMatList=5000; in PCAmat2feat.sh to specify the number of files used for estimating feature PCA matrix
my $reduce= 2; #set to 0 (no feature pca) for color moment
my $reduceDim=64; #remained dimension
my $finalDim = 66;
my $slave_num = 1; 
my $mixnum = 512;
my $statenum = 1;
my $supervectype = 1; #1:mean+weight 2:weight 3:raw
my $posecoef = 1.0;

my $current_dir=`chdir`;chomp $current_dir;
print "current dir is : $current_dir\n";

my $bHMM = 0;
my $transType=0; #0 l2r; 1 ergodic; 2 ergodic identical transP prob 3 ergodic biased transp prob
my $bPCA4Supervec = 0; #0: no PCA; 1: retrain and use PCA; 2: use exist PCA(not implemented)

my $bImage = 1;

my $rootdir;
my $img_dir;
my $fea_dir;
my $age_images_mat;
my $cache_dir;

if ($bImage==0) #Video analysis
{
    $rootdir = '/cworkspace/ifp-32-2/hasegawa/xizhou2/Trecvid/DenseSift';
    $img_dir = "$rootdir/../DX";
    $fea_dir = "$rootdir/SIFT_64";
}
elsif($bImage==1) #Object Recognition
{
    $rootdir = "f:\\work\\scene15";
    $img_dir = "e:\\Dataset_data\\scene_categories";
    $fea_dir = "$rootdir\\features";
    $cache_dir = "$rootdir\\caches"
}
elsif($bImage == 2) #Scene Recogniton
{
    $rootdir = '/cworkspace/ifp-32-2/hasegawa/zhenli3/ObjRec/Caltech101';
    $img_dir = "/cworkspace/ifp-32-2/hasegawa/zhenli3/database/Caltech101";
    $fea_dir = "$rootdir/features";
    $cache_dir = "$rootdir/caches"
}
elsif($bImage == 3) #Age Estimation
{
    $rootdir = '/cworkspace/ifp-32-2/hasegawa/xizhou2/AgeEstimation';
    $age_images_mat = "$rootdir/AgeData_Male_CVPR.mat";
}
else #Emotion Recognition
{
    $rootdir = '/cworkspace/ifp-32-2/hasegawa/xizhou2/EmotionRecognition';
#    $age_images_mat = "$rootdir/All_Img_Whole_1.mat";
    $img_dir = "$rootdir/Images/3DExpressionData-2DProjections-NormByNose-Cropped-64by64";
    $fea_dir = "$rootdir/feature_SIFT_3DExpressionData-2DProjections-NormByNose-Cropped-64by64";
}

my $code_dir = 'f:\code\gmmsystem_win';
my $bin_dir = "$code_dir\\b";

my $bFollowFeaSCP = 1; #if bFollowFeaSCP = 1 and gmmfea_scp is not specified, $gmmfea_scp = "${rootdir}/scp/gmmfea_${ubmfile}_reduce${reduce}_dim${reduceDim}_follow.scp" (get all files in $feascp);

my $ubmfn = "$rootdir/mdl/hmm_all_refined_${statenum}_${mixnum}"; #if gmmfea_scp is not specified, $ubmfn = "$rootdir/mdl/ubm_$mixnum"; 
my $fea_scp = "$rootdir/scp/feature_co.scp";#"$rootdir/scp/fea_sift_standard_128_64.scp"; #SCP for adaptation; if fea_scp is not specified, we use the all feature extracted

my $herest_scp = ''; #SCP for UBM estimation; if herest_scp is not specified, we randomly select feature files from $fea_scp

my $gmmfea_scp = ''; #if gmmfea_scp is not specified, $gmmfea_scp = "${rootdir}/scp/gmmfea_${ubmfile}_reduce${reduce}_dim${reduceDim}.scp" (get all files in <DIR>gmmfea_${ubmfile}<DIR>);

my $output_vecs = '';#"$rootdir/class/Img_ubm_yamaha_512_reduce${reduce}_dim${reduceDim}_all"; #if output_vecs is not specified, $output_vecs = "$rootdir/class/Img_${ubmfile}_reduce${reduce}_dim${reduceDim}";
my $max_items4herest = 20000;  #maximum feature files for UBM estimation
my $max_items4pca = 2000; #maximum supervectors for supervector PCA estimation
my $pca_dim = 1000;

###Pyramid parameter setting
my $pos_scp = "$rootdir/scp/pos.scp";
my $nPyramidPiece = 2;
my $bFixPyramidShape = 0;
my $nPartialNum = 8;
my $partial_fea_scp = "$rootdir/run/partialfea.scp";
my $feamode = 'b';

if( $bFixPyramidShape == 0 )
{
    $nPartialNum = 0;
    for (my $i=1; $i<=$nPyramidPiece; $i++)
    {
	$nPartialNum += $i*$i;
    }
}
    
#my $remain_ratio = 0.9;
my @remains = (1.0);
foreach my $remain_ratio (@remains)
{

    open(HCFG,">$rootdir/HCopy.cfg") || die"HCopy write fail\n";
    if ($reduce==0){
	print HCFG "NUMCHANS = $feadim\n";
    }
    else{
	print HCFG "NUMCHANS = $finalDim\n";
    }
    print HCFG "TARGETKIND = USER\n";
    print HCFG "NATURALREADORDER = F\n";
    print HCFG "BINARYACCFORMAT = F\n";
    print HCFG "MIXWEIGHTFLOOR = 1.005\n";
    print HCFG "MAPTAU = 0\n";
    close(HCFG);


#create sub-directories
recursiveMakeDirectory4Linux("${rootdir}/mdl");
recursiveMakeDirectory4Linux("${rootdir}/scp");
recursiveMakeDirectory4Linux("${rootdir}/score");
recursiveMakeDirectory4Linux("${rootdir}/tmp");
recursiveMakeDirectory4Linux("${rootdir}/nap");
recursiveMakeDirectory4Linux("${rootdir}/class");
recursiveMakeDirectory4Linux("${rootdir}/supervec");
recursiveMakeDirectory4Linux("${rootdir}/list");

$ubmfn = "$rootdir/mdl/ubm_$mixnum" if( $ubmfn =~ /^$/ );
my $ubmfile = getFileNameOnly($ubmfn); #    mySys("$code_dir/sh/gmmherest.sh $code_dir/perl $rootdir/HCopy.cfg $herest_scp $ubmfn $mixnum $current_dir");

my $realfilelist="$rootdir/class/realfilelist_Img_${ubmfile}_reduce${reduce}_dim${reduceDim}";
#####################################################################
#                                                                   #
#      Feature extraction                                           #
#                                                                   #
#####################################################################


print "== START FEATURE EXTRACTION...\n";
my $time = localtime(time);
print "$time\n";
unless ($SKIPFEAT==1){
#extract 'sift' feature
if( $bImage == 3 ) #age estimation
{
    # mySys("perl $code_dir/perl/splitscp.pl $fea_scp $slave_num");
    # my $ptmpfn = readFile($fea_scp);
    # my $srclen = @$ptmpfn;
    # my $perlen = int($srclen / $slave_num);
    # for( my $i=0; $i<${slave_num}; $i++ )
    # {
	# my $startidx = $perlen*$i+1;
	# #mySys("qsub -cwd $code_dir/sh/agefeatureext.sh $age_images_mat $startidx $fea_scp.$i test_imgs 64 64 $i $code_dir $current_dir");
	# mySys("$code_dir/sh/agefeatureext.sh $age_images_mat $startidx $fea_scp.$i test_imgs 64 64 $i $code_dir $current_dir");
    # }
    # mySys("$code_dir/perl/tasksitter.pl `whoami` agefeatureext.sh");
	print "This branch is not available now.\n";
}
else  #not age estimation
{

#get scp for feature extraction
system("perl $code_dir/perl/createlist4sift.pl $img_dir $fea_dir ${rootdir}/scp/fea_ext.scp");
system("perl $code_dir/perl/splitscp.pl ${rootdir}/scp/fea_ext.scp $slave_num");

#mySys("rm -rf $current_dir/reallists");
rmtree("$current_dir/reallists");
mkdir "$current_dir/reallists";
if (! -e "$current_dir/feature_mat"){mkdir "$current_dir/feature_mat";}
for( my $i=0; $i<${slave_num}; $i++ )
{
	unlink("$current_dir/matlab.feature_extraction.$i.out.ext");
}
for( my $i=0; $i<${slave_num}; $i++ )
{
    #mySys("qsub -cwd $code_dir/sh/feature_extraction.sh ${rootdir}/scp/fea_ext.scp $i $code_dir $current_dir $reduce $reduceDim $bPatchSift $bIncludeBlank $nOx $nOy $nPatchSize 64 64");
	mySys("$code_dir/perl/feature_extraction2.pl ${rootdir}/scp/fea_ext.scp $i $code_dir $current_dir $reduce $reduceDim $bPatchSift $bIncludeBlank $nOx $nOy $nPatchSize");
	}
#system("$code_dir/perl/tasksitter.pl `whoami` feature_extraction");
my $wait = 1;
while($wait){
	sleep(15);
	print "Checking job progress: ";
	my $nproc=${slave_num};
	for( my $i=0; $i<${slave_num}; $i++ )
	{
		if(-e "$current_dir/matlab.feature_extraction.$i.out.ext") {
			$nproc -= 1;
		}
	}
	if($nproc == 0){$wait = 0;}
	print "$nproc jobs are still running...\n";
}

#mySys("rm -f $current_dir/realmatlist.scp $current_dir/realfeatlist.scp");
unlink("$current_dir/realmatlist.scp");
unlink("$current_dir/realfeatlist.scp");

for( my $i=0; $i<${slave_num}; $i++ ){
    mySys("perl $code_dir/perl/catfiles.pl $current_dir/reallists/realmatlist.$i.scp >> $current_dir/realmatlist.scp");
    mySys("perl $code_dir/perl/catfiles.pl $current_dir/reallists/realfeatlist.$i.scp >> $current_dir/realfeatlist.scp");
}

if ($reduce==2){
print "== START feature PCA ...\n";
print my $time = localtime(time);
print "\n";

	#generate the PCA projection matrix
    #system("qsub -cwd $code_dir/sh/PCAmat2feat.sh $current_dir $code_dir/matlab  $current_dir/realmatlist.scp $current_dir/realfeatlist.scp $reduceDim $bUseSavedPCAfeatMatrix");
	mySys("perl $code_dir/perl/PCAmat2feat.pl $current_dir $code_dir/matlab  $current_dir/realmatlist.scp $current_dir/realfeatlist.scp $reduceDim $bUseSavedPCAfeatMatrix");
    #system("$code_dir/perl/tasksitter.pl `whoami` PCAmat2feat.sh");
	my $wait = 1;
	while($wait){
		sleep(15);
		print "Checking job progress: ";
		my $nproc = 1;
		if(-e "$current_dir/matlab.PCAmat2feat.out.ext") {
			$nproc -= 1;
		}
		if($nproc == 0){$wait = 0;}
		print "$nproc jobs are still running...\n";
	}
	
    # project features by PCA 
    for( my $i=0; $i<${slave_num}; $i++ )
    {
	#system("qsub -cwd $code_dir/sh/projectdata.sh $current_dir $code_dir/matlab  $current_dir/reallists/realmatlist.$i.scp $current_dir/reallists/realfeatlist.$i.scp $i");
		mySys("perl $code_dir/perl/projectdata.pl $current_dir $code_dir/matlab  $current_dir/reallists/realmatlist.$i.scp $current_dir/reallists/realfeatlist.$i.scp $i");
    }
    #system("$code_dir/perl/tasksitter.pl `whoami` projectdata");    
	my $wait = 1;
	while($wait){
		sleep(15);
		print "Checking job progress: ";
		my $nproc=${slave_num};
		for( my $i=0; $i<${slave_num}; $i++ )
		{
			if(-e "$current_dir/matlab.projectdata.$i.out.ext") {
				$nproc -= 1;
			}
		}
		if($nproc == 0){$wait = 0;}
		print "$nproc jobs are still running...\n";
	}
	
}

# combine the appearance features with x,y information
for( my $i=0; $i<${slave_num}; $i++ ) 
{
    #system("qsub -cwd $code_dir/sh/combineposfea.sh $current_dir $code_dir/matlab $current_dir/reallists/realfeatlist.$i.scp $posecoef $i");
	mySys("perl $code_dir/perl/combineposfea.pl $current_dir $code_dir/matlab $current_dir/reallists/realfeatlist.$i.scp $posecoef $i");
}
#system("$code_dir/perl/tasksitter.pl `whoami` combineposfea");
{
	my $wait = 1;
	while($wait){
		sleep(15);
		print "Checking job progress: ";
		my $nproc=${slave_num};
		for( my $i=0; $i<${slave_num}; $i++ )
		{
			if(-e "$current_dir/matlab.combineposfea.$i.out.ext") {
				$nproc -= 1;
			}
		}
		if($nproc == 0){$wait = 0;}
		print "$nproc jobs are still running...\n";
	}
}

# prepare the feature scps
copy("$current_dir/realfeatlist.scp","$rootdir/scp/feature_sift.scp");
system("perl $code_dir/perl/sed.pl .pos $rootdir/scp/feature_sift.scp > $rootdir/scp/pos.scp");
system("perl $code_dir/perl/sed.pl .co $rootdir/scp/feature_sift.scp > $rootdir/scp/feature_co.scp");
#mySys("cp $current_dir/realfeatlist.scp $rootdir/scp/feature_sift.scp" );
#mySys("sed 's#\$#.pos#' $rootdir/scp/feature_sift.scp > $rootdir/scp/pos.scp");
#mySys("sed 's#\$#.co#' $rootdir/scp/feature_sift.scp > $rootdir/scp/feature_co.scp");

$fea_scp = "$rootdir/scp/feature_co.scp" if( $fea_scp =~ /^$/ );
$pos_scp = "$rootdir/scp/pos.scp" if( $pos_scp =~ /^$/ );

} #not age est

print "== feature extraction done !\n";
my $time = localtime(time);
print "$time\n";

} #skip feature


$fea_scp = "$current_dir/realfeatlist.scp" if( $fea_scp =~ /^$/ );

#####################################################################
#                                                                   #
#      UBM training                                                 #
#                                                                   #
#####################################################################

print "== START UBM...\n";
my $time = localtime(time);
print "$time\n";


if( $herest_scp =~ /^$/ )
{
    #get scp for gmmherest
	$herest_scp = "$rootdir/scp/herest.scp";
	if(-e "$current_dir/matlab.randomselectscp.out.ext"){unlink("$current_dir/matlab.randomselectscp.out.ext");}
    #mySys("csh $code_dir/sh/randomselectscp.sh $fea_scp $herest_scp $max_items4herest $code_dir $current_dir");
	mySys("perl $code_dir/perl/randomselectscp.pl $fea_scp $herest_scp $max_items4herest $code_dir/matlab $current_dir");
	
	my $wait = 1;
	while($wait){
		sleep(15);
		print "Checking job progress: ";
		my $nproc = 1;
		if(-e "$current_dir/matlab.randomselectscp.out.ext") {
			$nproc -= 1;
		}
		if($nproc == 0){$wait = 0;}
		print "$nproc jobs are still running...\n";
	}
	
    #get scp for HInit
	if(-e "$current_dir/matlab.randomselectscp.out.ext"){unlink("$current_dir/matlab.randomselectscp.out.ext");}
	mySys("perl $code_dir/perl/randomselectscp.pl $fea_scp $current_dir/hinit.scp 1000 $code_dir/matlab $current_dir");
 	my $wait = 1;
	while($wait){
		sleep(15);
		print "Checking job progress: ";
		my $nproc = 1;
		if(-e "$current_dir/matlab.randomselectscp.out.ext") {
			$nproc -= 1;
		}
		if($nproc == 0){$wait = 0;}
		print "$nproc jobs are still running...\n";
	}  
}


##SHOULD ELIMINATE TINY FILESmySys("cut -d ' ' -f 2 ${rootdir}/scp/fea_ext.scp >${rootdir}/scp/all.scp");

unless($SKIPUBM==1){
#train ubm
#write config file for HERest

    if(1)#$bHMM)
    {
	#mySys("rm -rf $current_dir/tmp.hmm");
	rmtree("$current_dir/tmp.hmm");
	mySys("perl $code_dir/perl/hmmherest.pl $rootdir/HCopy.cfg $herest_scp $ubmfn $mixnum $current_dir $code_dir/perl $statenum ${slave_num} $current_dir/hinit.scp $transType 10");
    }
    else
    {
	mySys("rm -rf $current_dir/tmp.ubm");
	mySys("$code_dir/sh/gmmherest.sh $rootdir/HCopy.cfg $herest_scp $ubmfn $mixnum $current_dir $code_dir/perl ${slave_num}");
    }
}


## always save a binary version of the UBM model
#Change the format of ubm to match Xi's system
writeText("$current_dir/blank.lst","");
#system("cat > $rootdir/tmp/tmpubmlist.scp&");
mySys("$bin_dir/LAdapt -A -h -o -c 1000000 $ubmfn ${ubmfn}_bin $current_dir/blank.lst");



if (! -e $ubmfn){die "Error ERROR: UBM NOT GENERATED: $ubmfn \n";}
else {print "UBM GENERATED: $ubmfn\n";}
#####################################################################
#                                                                   #
#      Create Cache                                                 #
#                                                                   #
#####################################################################
print "== START CreateCache...\n";
my $time = localtime(time);
print "$time\n";

unless ($SKIPCACHE==1)
{
    mySys("perl $code_dir/perl/CreateCacheDir.pl $fea_scp $fea_dir $cache_dir");
    mySys("perl $code_dir/perl/CreateCache.pl ${ubmfn}_bin $fea_scp $fea_dir $cache_dir $slave_num $code_dir");
    #mySys("$code_dir/sh/CreateCache_DT.sh $current_dir $code_dir/matlab ${ubmfn}_bin $fea_scp $fea_dir $cache_dir $slave_num");
}

#####################################################################
#                                                                   #
#      Pyramid                                                      #
#                                                                   #
#####################################################################
print "== START Pyramid...\n";
my $time = localtime(time);
print "$time\n";

unless ($SKIPPYRAMID==1)
{
    $pos_scp = $fea_scp if( $pos_scp eq "" );
    
    system("perl $code_dir/perl/splitscp.pl $pos_scp $slave_num");

    if( $bFixPyramidShape == 1 )
    {
	for( my $i=0; $i<${slave_num}; $i++ )
	{
	    mySys("qsub -cwd $code_dir/sh/createpyramidlabel_fixshape.sh $pos_scp.$i $feamode $i $code_dir $current_dir");
	}
    mySys("$code_dir/perl/tasksitter.pl `whoami` createpyramidlabel_fixshape.sh");
    }
    else
    {
	for( my $i=0; $i<${slave_num}; $i++ )
	{
	    #mySys("qsub -cwd $code_dir/sh/createpyramidlabel.sh $pos_scp.$i $nPyramidPiece $feamode $i $code_dir $current_dir");
		mySys("perl $code_dir/perl/createpyramidlabel.pl $pos_scp.$i $nPyramidPiece $feamode $i $code_dir $current_dir");
		}
    #mySys("$code_dir/perl/tasksitter.pl `whoami` createpyramidlabel.sh");
	{
	my $wait = 1;
	while($wait){
		sleep(15);
		print "Checking job progress: ";
		my $nproc=${slave_num};
		for( my $i=0; $i<${slave_num}; $i++ )
		{
			if(-e "$current_dir/matlab.CreatePyramid.$i.out.ext") {
				$nproc -= 1;
			}
		}
		if($nproc == 0){$wait = 0;}
		print "$nproc jobs are still running...\n";
	}
}
    }
	
    my $parr1 = readFile($fea_scp);
    my $parr2 = readFile($pos_scp);
    my @doutput;
    for( my $i=0; $i<@$parr1; $i++ )
    {
        push @doutput, "$parr1->[$i] $parr2->[$i].pyramid";
    }
        
    writeText($partial_fea_scp,join("\n",@doutput));
}


#####################################################################
#                                                                   #
#      Adaptation                                                   #
#                                                                   #
#####################################################################
print "== START ADAPTATION...\n";
my $time = localtime(time);
print "$time\n";
copy("$fea_scp","$realfilelist");
#system("cp $fea_scp $realfilelist");
if (!-e $fea_scp){die "ERROR: failed when copying file list from $fea_scp!!\n";}
unless ($SKIPADAPT==1){
#if belonging to video analysis, adapt according to folders
#else adapt according to files
if( $bImage == 0 ) #bImage==1 part not checked by Xiaodan
{
	system("perl $code_dir/perl/splitscp_fold.pl $fea_scp $slave_num");
	recursiveMakeDirectory4Linux("${rootdir}/gmmfea_${ubmfile}_${remain_ratio}");

	#Adapt for each folder
	for( my $i=0; $i<${slave_num}; $i++ )
	{
		system("qsub -cwd $code_dir/sh/getstat4fold.sh $code_dir/perl $fea_scp.$i $ubmfn ${rootdir}/gmmfea_${ubmfile}_${remain_ratio} $i $code_dir $remain_ratio");
	}
	system("$code_dir/perl/tasksitter.pl `whoami` getstat4fold.sh");
}
else
{ # continue checking from here  xiaodan
    if ($nPartial < 0)
    {
	    system("perl $code_dir/perl/splitscp.pl $fea_scp $slave_num");
	    recursiveMakeDirectory4Linux("${rootdir}/gmmfea_$ubmfile");
    }
    else
    {
	    system("perl $code_dir/perl/splitscp.pl $partial_fea_scp $slave_num");
	    recursiveMakeDirectory4Linux("${rootdir}/gmmfea_$ubmfile");
    }

	#Adapt for each image
	for( my $i=0; $i<${slave_num}; $i++ )
	{
	    if( $bHMM )
	    {
		    mySys("qsub -cwd $code_dir/sh/getstat4hmm.sh /$code_dir/perl $fea_scp.$i $ubmfn ${rootdir}/gmmfea_$ubmfile $i $code_dir $current_dir $rootdir/HCopy.cfg");
	    }
	    else
	    {
	        if ($nPartial<0)
	        {
		    mySys("qsub -cwd $code_dir/sh/getstat.sh /$code_dir/perl $fea_scp.$i $ubmfn ${rootdir}/gmmfea_$ubmfile $i $code_dir $current_dir");
		}
		else
		{
		    #mySys("qsub -cwd $code_dir/sh/getpartialstat.sh $code_dir/perl $partial_fea_scp.$i $ubmfn ${rootdir}/gmmfea_${ubmfile} $i $code_dir $current_dir $fea_dir $cache_dir $gama");
			mySys("perl $code_dir/perl/GetPartialStat.pl $partial_fea_scp.$i $ubmfn ${rootdir}/gmmfea_${ubmfile} $i $code_dir $current_dir $fea_dir $cache_dir");
		}
	    }
	}
	#mySys("$code_dir/perl/tasksitter.pl `whoami` getpartialstat.sh");
	#mySys("$code_dir/perl/tasksitter.pl `whoami` getstat.sh");
}

print "adapt passed (SKIPADAPT= $SKIPADAPT)\n";
}#unless SKIPADAPT


#####################################################################
#                                                                   #
#      Get supervector                                              #
#                                                                   #
#####################################################################
print "== START GET SUPERVECTOR...\n";
my $time = localtime(time);
print "$time\n";

unless ($SKIPSUPERVEC==1){

if( $gmmfea_scp =~ /^$/ )
{
    if( $bFollowFeaSCP == 0 )
    {
	$gmmfea_scp = "${rootdir}/scp/gmmfea_${ubmfile}_${remain_ratio}_reduce${reduce}_dim${reduceDim}.scp";

	print "-----${rootdir}/gmmfea_${ubmfile}_${remain_ratio}----\n";
	#Get scp list for gmmfea
	my $pgmmfea_list = getFilenamesInDir("${rootdir}/gmmfea_${ubmfile}_${remain_ratio}");

	my @output = grep {$_="${rootdir}/gmmfea_${ubmfile}_${remain_ratio}/$_";} @$pgmmfea_list;
	writeText("$gmmfea_scp",join("\n",(sort @output)));
    }
    else
    {
	$gmmfea_scp = "${rootdir}/scp/gmmfea_${ubmfile}_reduce${reduce}_dim${reduceDim}_follow.scp";
	print "fea_scp=$fea_scp\n";
	my $ptmpfn = readFile($fea_scp);
	my $srclen = @$ptmpfn;
	#my @tmpfns = grep( s/\//\_/g, @$ptmpfn);
    #my @output = grep {$_="${rootdir}/gmmfea_${ubmfile}/$_";} @tmpfns;
	my $gmmdir = "${rootdir}/gmmfea_${ubmfile}";
	#my @output = grep( s/$fea_dir/$gmmdir/, @$ptmpfn);
	
	my @output = ("");;
	foreach my $curfile(@$ptmpfn){
		my($idx,$pos) = {-1,0};
		$idx = index( $curfile, $fea_dir, $pos );
		substr $curfile, $idx, length($fea_dir), $gmmdir ;
		push(@output,"$curfile");
	}	
	#writeText("$gmmfea_scp",join("\n", @output));
	writeText("$gmmfea_scp",join("\n", @$ptmpfn));
    }
}

if( $output_vecs =~ /^$/ )
{
    $output_vecs = "$rootdir/class/Img_${ubmfile}_reduce${reduce}_dim${reduceDim}.mat";
    if( $bPCA4Supervec == 1 )
    {
	$output_vecs = "${output_vecs}_pca";
    }
    if( $bFollowFeaSCP == 1 )
    {
	$output_vecs = "${output_vecs}_follow";
    }
}

print "\n$output_vecs\n";

#get the number of gmmfea files
my $ptmp = readFile($gmmfea_scp);

my $sss = @$ptmp;
print "~~~~~~~~~~~$sss~~~~\n";

if ($nPartial >= 0)
{
    my $pcaflag = -1;
    if ($bPCA4Supervec==1)
    {
        if ($bUseSavedPCAsupervecMatrix==1)
        {
            $pcaflag = 0;
        }else{
            $pcaflag = $pca_dim;
        }        
    }
    
    for( my $i=0; $i<$nPartialNum; $i++ )
    {
        #mySys("qsub -cwd $code_dir/sh/getsupervec4partial.sh ${ubmfn}_bin $gmmfea_scp $output_vecs $pcaflag ${rootdir}/nap/PCA_${ubmfile}_${pca_dim} $max_items4pca $i $supervectype $code_dir $current_dir");
		mySys("perl $code_dir/perl/GetSupervector4Partial.pl ${ubmfn}_bin $gmmfea_scp $output_vecs $pcaflag ${rootdir}/nap/PCA_${ubmfile}_${pca_dim} $max_items4pca $i $supervectype $code_dir $current_dir");
    }
}
else
{
#the number of gmmfea files is larger than the maximum number for PCA estimation
if( $bPCA4Supervec == 1 && @$ptmp > $max_items4pca)
{
    mySys("csh $code_dir/sh/randomselectscp.sh $gmmfea_scp ${gmmfea_scp}.pca $max_items4pca $code_dir $current_dir");

    my @outputlist = ();
    mySys("perl $code_dir/perl/splitscp.pl ${gmmfea_scp}.pca $slave_num");
    for( my $i=0; $i<$slave_num; $i++ )
    {
	if( $bHMM )
	{
	    mySys("qsub -cwd $code_dir/sh/writesupervec4hmm.sh ${gmmfea_scp}.pca.$i ${ubmfn} ${gmmfea_scp}.pca.$i.mat $i $code_dir $current_dir");
	}
	else
	{
	    mySys("qsub -cwd $code_dir/sh/writesupervec.sh ${gmmfea_scp}.pca.$i ${ubmfn}_bin ${gmmfea_scp}.pca.$i.mat $i $code_dir $current_dir");
	}
	push @outputlist, "${gmmfea_scp}.pca.$i.mat";
    }
    writeText("${rootdir}/list/gmmfea.pca.list",join("\n",@outputlist));
    mySys("$code_dir/perl/tasksitter.pl `whoami` writesupervec");
    
#    print "aaaaa\n";
	if ($bUseSavedPCAsupervecMatrix==0) ####findpro####
	{
		mySys("qsub -cwd $code_dir/sh/findprojectspace.sh ${rootdir}/list/gmmfea.pca.list ${rootdir}/nap/PCA_${ubmfile}_${pca_dim} $pca_dim $code_dir $current_dir");
	}
    
    #get matrices for supervectors
    my @outputlist = ();
    mySys("perl $code_dir/perl/splitscp.pl ${gmmfea_scp} $slave_num");
    for( my $i=0; $i<$slave_num; $i++ )
    {
	if( $bHMM )
	{
	    mySys("qsub -cwd $code_dir/sh/writesupervec4hmm.sh ${gmmfea_scp}.$i ${ubmfn} ${gmmfea_scp}.$i.mat $i $code_dir $current_dir");
	}
	else
	{
	    mySys("qsub -cwd $code_dir/sh/writesupervec.sh ${gmmfea_scp}.$i ${ubmfn}_bin ${gmmfea_scp}.$i.mat $i $code_dir $current_dir");
	}
	push @outputlist, "${gmmfea_scp}.$i.mat";
    }
    writeText("${rootdir}/list/gmmfea.list",join("\n",@outputlist));
	##findpro##   
	if ($bUseSavedPCAsupervecMatrix==0)
	{
		mySys("$code_dir/perl/taskwaiter.pl `whoami` writesupervec findprojectspace.sh");
	}
	elsif($bUseSavedPCAsupervecMatrix==1)##findpro##
	{
		mySys("$code_dir/perl/taskwaiter.pl `whoami` writesupervec");
	}
} # many utts, select some for PCA
else #don't need PCA or few utts, use all for PCA
{
    #get matrices for supervectors
    my @outputlist = ();
    mySys("perl $code_dir/perl/splitscp.pl ${gmmfea_scp} $slave_num");
    for( my $i=0; $i<$slave_num; $i++ )
    {
	if( $bHMM )
	{
	    mySys("qsub -cwd $code_dir/sh/writesupervec4hmm.sh ${gmmfea_scp}.$i ${ubmfn} ${gmmfea_scp}.$i.mat $i $code_dir $current_dir");
	}
	else
	{
	    mySys("qsub -cwd $code_dir/sh/writesupervec.sh ${gmmfea_scp}.$i ${ubmfn}_bin ${gmmfea_scp}.$i.mat $i $code_dir $current_dir");
	}
	push @outputlist, "${gmmfea_scp}.$i.mat";
    }
    writeText("${rootdir}/list/gmmfea.list",join("\n",@outputlist));
    mySys("$code_dir/perl/tasksitter.pl `whoami` writesupervec");

    if( $bPCA4Supervec == 1 )
    {
	print "bbbbbbbb\n";
	##findpro##
	if ($bUseSavedPCAsupervecMatrix==0)
	{
		mySys("qsub -cwd $code_dir/sh/findprojectspace.sh ${rootdir}/list/gmmfea.list ${rootdir}/nap/PCA_${ubmfile}_${pca_dim} ${pca_dim} $code_dir $current_dir");
		mySys("$code_dir/perl/taskwaiter.pl `whoami` findprojectspace.sh");
	}
    }
} #few utts, use few for PCA

if( $bPCA4Supervec )
{ 
    print "cccccccccccccccccc\n";
    mySys("qsub -cwd $code_dir/sh/getpcasupervec.sh ${rootdir}/list/gmmfea.list ${rootdir}/nap/PCA_${ubmfile}_${pca_dim} $output_vecs $code_dir $current_dir");
    mySys("$code_dir/perl/tasksitter.pl `whoami` getpcasupervec");
}
else
{
    print "dddddddddddddddddddddddd\n";
    mySys("qsub -cwd $code_dir/sh/getsupervec.sh ${rootdir}/list/gmmfea.list $output_vecs $code_dir $current_dir");
    mySys("$code_dir/perl/tasksitter.pl `whoami` getsupervec");
}
}

}

}
