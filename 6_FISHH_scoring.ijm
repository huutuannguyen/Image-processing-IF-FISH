var startingTile=0;//665
var sbm=true;
var higlyAmplifiedTissue=true;
var	redCountThreshold=0;
var redContrastThreshold=0.3;				//for selecting the contrast
var greenContrastThreshold=0.85;
var typicalNucleiSize=1300;										//In pixel
var caseArray = newArray(6);
var NucleiArea=0;
var Threshold_Contrast=450;
var Contrast_Rescale_Factor=0.35;
var sharpen_radius=2; sharpen_weight=0.9; 
var local_radius=1;
var pixelSize=0.3225;
var MinSignal=0;
var MeanSignal=0;
function Adapted_Thresholding(Th,Im) {
	selectWindow(Im);
	getRawStatistics(nPixels, mean, min, max);
	if (max<Th) { 
		T=0;
	} else {
		run("Duplicate...", " ");
		rename("Im_Copy");
		run("Subtract...", "value="+Th);
		run("Max...", "value=255");
		setThreshold(1,255);
		run("Create Selection");
		roiManager("Add");
//		waitForUser("Check and delete");
		run("Select None");
		close("Im_Copy");
		T=1;
		resetThreshold;
		}
	return T
}
function maskFromImage(img,theMask) {
	selectImage(theMask);
//		waitForUser("theMask");
	run("Duplicate...", "title=Masque");
	run("Divide...", "value=255");

	imageCalculator("Multiply create", img,"Masque");

	rename("img2");

	selectImage(img);
	close();
	selectImage("img2");
	rename(img);
	selectImage("Masque");
	close();
	}
function blurfilter(Original_Image, selectedChannel, Threshold_Contrast, Contrast_Rescale_Factor, sharpen_radius, sharpen_weight, local_radius) {

run("Clear Results");
pixelSize=0.3225;
run("Set Scale...", "distance=1 known="+pixelSize+" pixel=1 unit=um global");
run("Set Measurements...", "area mean standard min integrated median area_fraction display redirect=None decimal=0");
selectImage(Original_Image);
Stack.setChannel(selectedChannel);


Image_Name=Original_Image+"_Sharpen Radius="+sharpen_radius+", Local radius="+local_radius+", Threshold contrast="+Threshold_Contrast+", Contrast rescale factor"+Contrast_Rescale_Factor;
Mask_Name="MaskMask";
run("Select None");

run("Duplicate...", " ");
rename(Image_Name);
run("Duplicate...", " ");
title="Sharp";
rename(title);
//run("Remove Outliers...", "radius=2 threshold=500 which=Bright");
run("Unsharp Mask...", "radius="+sharpen_radius+" mask="+sharpen_weight);
Width=getWidth();
Height=getHeight();
newImage(Mask_Name, "8-bit white", Width, Height, 1);
run("Select None");

selectWindow(title);
run("Duplicate...", " ");
rename(title+"_Max");
run("Duplicate...", " ");
rename(title+"_Min");

selectWindow(title+"_Max");
run("Maximum...", "radius="+local_radius);
selectWindow(title+"_Min");
run("Minimum...", "radius="+local_radius);

imageCalculator("Subtract create", title+"_Max",title+"_Min");
rename(title+"_Local Contrast");
run("Duplicate...", " ");
rename(title+"_Local Contrast Origin");
selectImage(title+"_Local Contrast");
//waitForUser("1");

T1=Adapted_Thresholding(Threshold_Contrast,title+"_Local Contrast");
//waitForUser("2");
	close(title); 
	close(title+"_Min"); 
	close(title+"_Max"); 

	

	}
		function contrast_singleROI_calculation(img, roi) {
//waitForUser("3");
//selectImage(title+"_Local Contrast Origin");
//roi=newArray(ROI0,ROI_position);
selectImage(img);
//Array.print(roi);
roiManager("Select", roi);
//getSelectionBounds(xroi,yroi,wroi,hroi);
//makeRectangle(xroi-1,yroi-1,wroi+2,hroi+2);
getRawStatistics(nPixels, mean, min, max);
run("Measure");
MaxSignal=getResult("Max");
MinSignal=getResult("Min");
//MeanSignal=getResult("Mean");
Contrast=(MaxSignal-MinSignal)/(MaxSignal+MinSignal);
//print("MaxSignal"+MaxSignal+"MinSignal"+MinSignal+"Contrast"+Contrast);
return Contrast;

}
	function contrast_calculation(img, roi) {

//selectImage(title+"_Local Contrast Origin");
//roi=newArray(ROI0,ROI_position);
selectImage(img);
//Array.print(roi);
roiManager("Select", roi);
roiManager("AND"); //merge two region of interest: one is mask and one is nuclei
getRawStatistics(nPixels, mean, min, max);
run("Measure");
MaxSignal=getResult("Max");
MinSignal=getResult("Min");
MeanSignal=getResult("Mean");
//waitForUser("3");
Contrast=(MaxSignal-MinSignal)/(MaxSignal+MinSignal);
return Contrast;

}
macro "MACRO_Batch_Counting"{

showMessage("You are running FISH segmentation and count");

showMessage("Please select the folder containing raw FISH tiles");
//I:\experiment\IHC FISH\Joint project with Daniel\BC2\aligned z01 d\FISH\TIFF
//input="E:/Tuan/IHC FISH/Joint project with Daniel/BC2/FISH/2Z01 BC2/2z01 left flower aliged/FISH tiles/TIFF/";

input=getDirectory("Input directory");
print(input);
//cancerPosition="I:/experiment/IHC FISH/Joint project with Daniel/BC2/skbr3/tile heatmap 3/0.txt";
cancerPosition=substring(input,0,lengthOf(input)-16)+"Tiles heatmap"+File.separator+"cancerArea.txt";

//cancerPosition=File.openDialog("Choose the file where image cancer position were stored"); 
print(cancerPosition);
CPstring=File.openAsString(cancerPosition); //open the file as a string
CProws=split(CPstring,"\n"); // split by using ; and enumerate
CPArray = newArray(lengthOf(CProws));
for (i=0;i<lengthOf(CProws);i++){
CPArray[i]=parseInt(CProws[i]);
//print(CPArray[i]);
}
//showMessage("Please create the folder for processed FISH tiles");	
//output="I:/experiment/IHC FISH/Joint project with Daniel/BC2/skbr3/output FISH 3/";
output=substring(input,0,lengthOf(input)-16)+"output FISH"+File.separator;
File.makeDirectory(output);
print(output);
//Dialog.create("File type");
//Dialog.addString("File suffix: ", ".tif", 5);
//Dialog.show();
suffix = ".tif";
run("Clear Results");
//showMessage("Please create your FISH count result");
f = File.open(output+"result.txt"); // display file open dialog
print(f);
print(f, "Image name; Code; Cell code; No of green dot; No of  red dot; Nucleus size; Nucleus position X; Nucleus position Y;averageGreenInNucleus;averageRedInNucleus; Averaged green area; Averaged red area; greenContrast; redContrast");
//ROIfromIHC=getDirectory("Please select the folder containing ROI from IHC");//print(inDir);
ROIfromIHC=substring(input,0,lengthOf(input)-16)+"roi IF"+File.separator;

//ROIfromIHC="I:/experiment/IHC FISH/Joint project with Daniel/BC2/skbr3/roi IF 3/";
print(ROIfromIHC);
ROIFISH=substring(input,0,lengthOf(input)-16)+"roi FISH"+File.separator;

File.makeDirectory(ROIFISH);
//ROIFISH=getDirectory("Please select the folder containing ROI for saving FISH roi");//print(inDir);
//File.open(ROIfromIHC);
//ROIFISH="I:/experiment/IHC FISH/Joint project with Daniel/BC2/Aligned 2/ROI FISH save/";
//ROIFISH="I:/experiment/IHC FISH/Joint project with Daniel/BC2/skbr3/FISH roi 3/";
print(ROIFISH);

run("ROI Manager...");
processFolder(input, output,cancerPosition, CPArray, ROIfromIHC, suffix, f,ROIFISH);
setBatchMode(false);
}

function canonicArray(n){	
	cArr=newArray(n);
for (i=0;i<n;i++){
		cArr[i]=i;
print(cArr[i]);
}
return cArr;
}
function canonicSubset(n,m){		//return an array from n to m	
x=m-n;
	csArr=newArray(x);
for (i=0;i<x;i++){
		csArr[i]=n+i;
print(csArr[i]);
}
return csArr;
}
function processFolder(input, output,cancerPosition, CPArray, ROIfromIHC, suffix, f,ROIplace) {
	list= getFileList(input);
i=0;
//pathfile=substring(input,0,lengthOf(input)-15)+"correction factor FISH.txt";
//pathfile="I:/experiment/IHC FISH/Joint project with Daniel/BC2/skbr3/correction factor FISH.txt";
pathfile=File.openDialog("Choose the file where the threshold correction factors are stored"); 
print(pathfile);
//waitForUser("copy them ");
filestring=File.openAsString(pathfile); //open the file as a string
print(filestring);
rows=split(filestring, ";"); // split by using ; and enumerate
 factorBlueNonSpecific=parseFloat(rows[0]);
 factorRedNonSpecific=parseFloat(rows[1]);
 
 factorAutofluo=parseFloat(rows[2]); 
//		waitForUser("check threshold factorBlue"+ factorBlue);
 factorBlue=parseFloat(rows[3]);
 factorRed=parseFloat(rows[4]);
 factorGreen=parseFloat(rows[5]);
 blueNoise= parseFloat(rows[6]);
 redNoise= parseFloat(rows[7]);
 greenNoise= parseFloat(rows[8]);
 calibrationFactor=parseFloat(rows[9]);
 maxNucleiSize=parseFloat(rows[10]);
 redDotLimit=parseFloat(rows[11]);
 maxGreenDotArea=parseFloat(rows[12]);
 blueRedMax=parseFloat(rows[13]);
 autofluoRedGreenThreshold=parseFloat(rows[14]);
  minBlueSignalIntensity=parseFloat(rows[15]);
maxBlueSignalIntensity=parseFloat(rows[16]);
 minRedSignalIntensity=parseFloat(rows[17]);
maxRedSignalIntensity=parseFloat(rows[18]);
 minGreenSignalIntensity=parseFloat(rows[19]);
maxGreenSignalIntensity=parseFloat(rows[20]);
intensityOfRed=parseFloat(rows[21]);
redContrastThreshold=parseFloat(rows[22]);
// 		if (File.isDirectory(list[i]))
//		processFolder("" + input + list[i]);

		minRedSignalIntensity=minRedSignalIntensity*0.8;
	for (i=startingTile; i < list.length; i++) {
		for (j=0;j<lengthOf(CPArray);j++){
			fileNumber=parseInt(substring(list[i],lengthOf(list[i])-8, (lengthOf(list[i])-4)));
			if (fileNumber==CPArray[j]) {
				if(endsWith(list[i], suffix)) {
//					if (i>startingTile) 
					setBatchMode(sbm);

				processFile(input, output, list[i], i, factorBlueNonSpecific, factorRedNonSpecific, factorBlue, factorRed, factorAutofluo, factorGreen, redNoise, greenNoise, blueNoise, calibrationFactor,redDotLimit, maxNucleiSize, f,ROIplace, blueRedMax,maxGreenDotArea);

				}
			//else {waitForUser("suffix problem");}
			}
//							else {waitForUser("fileNumber"+fileNumber+"CParray"+CPArray[j]);}
		}
				run("Clear Results");
				roiManager("Reset");
	}
		showMessage("Jobs done");
}
function processFile(input, output, file, linecount, factorBlueNonSpecific, factorRedNonSpecific, factorBlue, factorRed, factorAutofluo, factorGreen, redNoise, greenNoise, blueNoise, calibrationFactor,redDotLimit,maxNucleiSize, f, ROIplace, blueRedMax, maxGreenDotArea) {
	roiManager("Reset");	 
	dapiChannel = 3 ; 
	greenDotChannel = 2 ; 
	redDotChannel = 1 ;
	intensityCoefficient=parseInt(intensityOfRed/350+0.5);	// divided by 700 or 900?
	
setForegroundColor(255, 255, 255);
run("Collect Garbage");	
	open(input+File.separator+file);
	selectImage(file);
		code=parseInt(substring(file,(lengthOf(file)-8),(lengthOf(file)-4)));
// 		 		waitForUser("check"+ROIfromIHC+"tile"+IJ.pad(code,4)+".zip");
			ROIBeforeCellROIAdded=roiManager("Count");
 		if (File.exists(ROIfromIHC+"tile_IHC"+IJ.pad(code,4)+".zip")) { 
		roiManager("open", ROIfromIHC+"tile_IHC"+IJ.pad(code,4)+".zip"); 
//		waitForUser(ROIfromIHC+"tile_IHC"+IJ.pad(code,4)+".zip");
		numberOfCell=roiManager("Count")-ROIBeforeCellROIAdded;
 		
	selectImage(file);

	run("Set Scale...", "distance=1 known="+pixelSize+" pixel=1 unit=um global");
	run("Select None");
//		waitForUser("check ROI");
	run("Duplicate...", "title=originImage duplicate");

	wsStatus = true;
	filterDAPI = true;
	Gblur =false;
	

	gaussianBlur = 1;
	redDotTotal=0;
	greenDotTotal=0;
	//Load ROI from IHC 
	

	//	
	title = getTitle();
	getDimensions(width, height, channels, slices, frames);
	
	//Create a Blur version of the image
	run("Duplicate...", "title=gBlur duplicate");
		if (Gblur) {
			run("Gaussian Blur...", "sigma="+gaussianBlur+" stack");
		}
	
	run("Set Measurements...", "area mean standard modal min integrated median area_fraction display redirect=None decimal=6");
	//substract background with rolling ball filter
	Stack.setChannel(greenDotChannel); //major change
	
run("Duplicate...", "title=MembraneG");
run("Duplicate...", "title=DAPInonSpecific");
	selectImage("gBlur");
Stack.setChannel(redDotChannel);
run("Subtract Background...", "rolling=30 slice");
run("Duplicate...", "title=redBallRolled");

//		waitForUser("before thresholding");
selectImage("DAPInonSpecific");
	setAutoThreshold("Yen dark");
	getThreshold(lower,upper);
	if (lower*factorBlueNonSpecific> upper) lower=upper/factorBlueNonSpecific;
	setThreshold(lower*factorBlueNonSpecific,upper);
	setOption("BlackBackground", true);
	
//	waitForUser("check 1.2"+lower+"factorBlueNonSpecific"+factorBlueNonSpecific+"upper"+upper);
	run("Convert to Mask");
	
		run("Invert");
		
	run("Create Selection");
	run("Clear Results");
	run("Measure");
	greenFluoArea=getResult("Area");
	run("Clear Results");

//	waitForUser("after Convert");
		getDimensions(width, height, channels, slices, frames);
	AutoFluorProportion= greenFluoArea/(pixelSize*pixelSize*width*height);
//	waitForUser("greenFluoArea"+greenFluoArea+"lessAutoFLuo"+AutoFluorProportion);
	LessAutoFluo=(AutoFluorProportion<0.05)||(AutoFluorProportion>0.999);

	if (LessAutoFluo)  {

//		waitForUser("show");
	run("Extend Image Borders", "left=2 right=2 top=2 bottom=2 fill=White");
run("Dilate");																		//First to delete green signal (2 pixels)
run("Dilate");
run("Erode");																		//Second to delete space inside of autofluorescence materials
run("Erode");
run("Erode");
run("Erode");
run("Erode");
run("Erode");
run("Dilate");
run("Dilate");
run("Dilate");
run("Dilate");
run("Extend Image Borders", "left=-2 right=-2 top=-2 bottom=-2 fill=White");

	
	run("Divide...", "value=255.000");
	selectImage("originImage");
	Stack.setChannel(greenDotChannel);
//		waitForUser("check dsafdsa");	
ROI0=roiManager("Count");
blurfilter("originImage", greenDotChannel, Threshold_Contrast, Contrast_Rescale_Factor, sharpen_radius, sharpen_weight, local_radius);


	
		//delete autofluorescence in the green chanel

	selectImage("originImage");
		run("Select None");
		Stack.setChannel(redDotChannel);
		run("Duplicate...", "title=membrane");
		run("Duplicate...", "title=redContrast");
		run("Duplicate...", "title=redDotAutoFluo");
	
	
		setAutoThreshold("Huang dark");
	    getThreshold(lower,upper);
	    	if (lower*factorAutofluo<upper) {
	    setThreshold(lower*factorAutofluo,upper);

	redAutoLower=lower*factorAutofluo;        
		setOption("BlackBackground", true);
		run("Make Binary");
		run("Invert");
		run("Divide...", "value=255.000");
	    	}
	    	else{
		run("Multiply...", "value=255.000"); //Saturate that = no filter
	    	}

	//
	selectImage("redContrast");	
	run("Unsharp Mask...", "radius="+sharpen_radius+" mask="+sharpen_weight);
	
	run("Select None");
	run("Duplicate...", "title=redContrastMax");
	run("Duplicate...", "title=redContrastMin");	
	

selectWindow("redContrastMax");
run("Maximum...", "radius="+local_radius);
selectWindow("redContrastMin");
run("Minimum...", "radius="+local_radius);

imageCalculator("Subtract create", "redContrastMax","redContrastMin");
rename("RedLocalContrast");

close("redContrastMax");
close("redContrastMin");
	selectImage("gBlur");
	Stack.setChannel(greenDotChannel);
//	waitForUser("try red green combine");	
	run("Subtract Background...", "rolling=15 slice");
	//Mask red channel by creating redDotMask from green channel 
	run("Duplicate...", "title=redDotMask");

	setAutoThreshold("Otsu dark");
	getThreshold(lower,upper);
	setThreshold(lower*factorRedNonSpecific,upper);
	run("Convert to Mask");
	
	run("Invert");
	run("Divide...", "value=255.000");
	greenAutoLower=lower*factorRedNonSpecific;
	
	
	selectImage("gBlur");
	Stack.setChannel(redDotChannel);
	run("Red");
	Stack.setChannel(dapiChannel);
	run("Blue");
	Stack.setChannel(greenDotChannel);
	run("Green");
	  
	run("Duplicate...", "duplicate");

	run("Select None");
	run("Split Channels");
	selectImage("C1-gBlur-1");
	run("32-bit");


	imageCalculator("Multiply create 32-bit stack", "redBallRolled" ,"redDotMask");
	selectImage("Result of redBallRolled");
	rename("redBallRolledWithoutAutofluo");

	selectImage("C3-gBlur-1");
	run("32-bit");
	imageCalculator("Multiply create 32-bit stack", "C3-gBlur-1" ,"redDotMask");

	selectImage("C2-gBlur-1");
	run("32-bit");
	imageCalculator("Multiply create 32-bit stack", "C2-gBlur-1" ,"redDotAutoFluo");
	selectImage("redBallRolled");

	run("Merge Channels...", "c1=C1-gBlur-1 c2=[Result of C2-gBlur-1] c3=[Result of C3-gBlur-1] create keep");
	rename("gBlur2");
	run("Stack to RGB");
	rename("finalOutline");

//	selectImage("Result of C2-gBlur-1");
//	run("Subtract Background...", "rolling=10 slice");
	// Create Mask From DAPI
	selectImage("MembraneG");
	run("8-bit");
		selectImage("membrane");
	run("8-bit");
	imageCalculator("Multiply create 32-bit stack", "membrane" ,"MembraneG"); 				//redDotAutoFluo is still the original image
close("membrane");
	selectImage("Result of membrane");
	rename("membrane");
//run("Unsharp Mask...", "radius="+sharpen_radius+" mask="+sharpen_weight);
//	run("Find Edges");

	selectImage(title);
	Stack.setChannel(dapiChannel);
	
	run("Duplicate...", "title=dapiLocalAuto");
	run("Duplicate...", "title=dapiMask");
	
//	selectImage("C3-gBlur-1");
//	run("Duplicate...", "title=enhancedNucleiRecognitionMask");
//	run("Gaussian Blur...", "sigma="+gaussianBlur+" stack");
	
		if (filterDAPI) {
		imageCalculator("Multiply create 32-bit stack", "dapiMask" ,"DAPInonSpecific");
		rename("dapiMaskFiltered");}
	selectImage("dapiLocalAuto");
	run("Unsharp Mask...", "radius="+sharpen_radius+" mask="+sharpen_weight);
	run("Median...", "radius=4");
	selectImage("originImage");
	Stack.setChannel(redDotChannel);
	run("Duplicate...", "title=redDotChannelForDAPIMask");
//		waitForUser("Check");
	imageCalculator("Multiply create 32-bit stack", "redDotChannelForDAPIMask" ,"redDotAutoFluo");
//			waitForUser("Check");
	selectImage("Result of redDotChannelForDAPIMask");
	rename("redBlurForDAPIMask");
	run("Gaussian Blur...", "sigma="+gaussianBlur);
	
//		waitForUser("Check");
		imageCalculator("Multiply create 32-bit stack", "dapiMaskFiltered" ,"redBlurForDAPIMask");

	selectImage("Result of dapiMaskFiltered");
	rename("BlueRedCombined");
	run("Gaussian Blur...", "sigma="+gaussianBlur*2);
	selectImage("redBlurForDAPIMask");
	close();
	selectImage("BlueRedCombined");
		run("8-bit");

//	run("Color Balance...");
//	resetMinAndMax();
//waitForUser("Check");
//	selectImage("BlueRedCombined");	
		run("Duplicate...", "title=BlueRedMask");
		setAutoThreshold("Yen dark");		
		getThreshold(lowerY,upperY);
		
	selectImage("BlueRedCombined");
			run("8-bit");	
		setAutoThreshold("MinError dark");
		setBatchMode("show");
		getThreshold(lower,upper);
//		waitForUser(lowerY+","+upper);
				if (lowerY<upper*0.50) lowerY=upper*0.50;
//		if (lowerY>500*lower) factorBlue=0.8;		//if LowerY too big than should decrease the threshold
		if (upper>blueRedMax*1.2) {
		upper=blueRedMax*1.2;
		}


	selectImage("BlueRedMask");
	if (lowerY*1.5<upper/2){
		lowerY=upper/3;
	}
		setThreshold(lowerY*1.5,upperY);

		
		run("Make Binary");
		run("Invert");
		imageCalculator("Multiply create 32-bit stack", "BlueRedCombined" ,"BlueRedMask");
		close("BlueRedCombined");
		
	selectImage("Result of BlueRedCombined");	
	rename("BlueRedCombined");	
				run("8-bit");	
				
if (lower*factorBlue <7) lower=7/factorBlue;	

if (lower*factorBlue >(lowerY/3.5)) lower=lowerY/(3.5*factorBlue);				//upper bound based on lowerY
		if (upper>lower*factorBlue) {
		setThreshold(lower*factorBlue,upper);
		}else{
		setThreshold(lower,upper);
//		waitForUser("upper"+upper);
		}
		selectImage("BlueRedCombined");	
		run("Duplicate...", "title=BlueRedCombined2");				//for avoiding the wrong selection of the background
//setBatchMode("show");
		setThreshold(lower*factorBlue,upper);
//				waitForUser(lower+","+lowerY+","+factorBlue+","+upper);
		run("Select None");
		run("Make Binary");
		run("Create Selection");
		selectImage("BlueRedCombined");	
		
		run("Restore Selection");
		run("Clear Results");
		run("Measure");
		DapiIntensityCheck=getResult("Median");																					//everywhere changes mean to median
	//	waitForUser(DapiIntensityCheck);
		selectImage("BlueRedCombined");	
		

		run("Clear Results");
		selectImage("BlueRedCombined2");
		run("Select None");
		run("Invert");
		run("Create Selection"); 
	selectImage("BlueRedCombined");	
		
		run("Restore Selection");
		run("Clear Results");
		run("Measure");
		DapiBackgroundCheck=getResult("Median");	
//		waitForUser(DapiBackgroundCheck);
		selectImage("BlueRedCombined");		
				setThreshold(lower*factorBlue,upper);
		run("Make Binary");		
		if (DapiIntensityCheck<DapiBackgroundCheck) {run("Invert");}
		//run("Options...", "iterations=1 count=1 black do=Dilate");
//		run("Watershed");

	run("Fill Holes");	
	run("ROI Manager...", "");
//	run("Extend Image Borders", "left=1 right=1 top=1 bottom=1 fill=White");
//	run("Erode");
//	run("Extend Image Borders", "left=-1 right=-1 top=-1 bottom=-1 fill=White");
//waitForUser("check DAPI Mask");

	//Number of cells in IHC
//	selectAllROI=canonicArray(numberOfCell);
//	roiManager("Select",selectAllROI);
// roiManager("Combine");
// if (roiManager("Count")>0) {
//roiManager("Add");
//}
//waitForUser("check 1");


	roiBeforeGrossDetection=roiManager("Count"); 
	run("Analyze Particles...", "size=50-500000 pixel circularity=0-1.00 add");
	
//	print("factorblue "+ factorBlue);
//setBatchMode("show");
		selectImage("BlueRedCombined");	
		run("Create Selection"); 		
		close("BlueRedCombined2");	

roiAfterGrossDetection=roiManager("Count");
	totalNucleiBeforeDeclustering = roiAfterGrossDetection-roiBeforeGrossDetection;
selectionArray=newArray();
selectionArray=canonicSubset(roiBeforeGrossDetection,roiAfterGrossDetection);
//selectionArray=Array.concat(selectionArray,canonicSubset(roiBeforeGrossDetection,roiAfterGrossDetection));

			run("Clear Results");
			selectImage("originImage");
			Stack.setChannel(redDotChannel);
			run("Restore Selection");
			run("Measure");
			redSignalAverage=getResult("Median");
			run("Clear Results");	
			selectImage("originImage");
			Stack.setChannel(greenDotChannel);
			run("Restore Selection");
			run("Measure");
			greenSignalAverage=getResult("Median");
			run("Clear Results");

			selectImage("redDotChannelForDAPIMask");
			run("8-bit");
			run("Invert");
			
//				run("Multiply...", "value=0.1");
//				selectImage("redDotChannelForDAPIMask");
	
//				imageCalculator("Add create 8-bit stack", "redDotChannelForDAPIMask","membrane");
//				waitForUser("0 2");
		
//				run("Gaussian Blur...", "sigma=1");		
				run("Thresholded Blur", "radius=4 threshold=20 softness=5 strength=2");

//				run("Find Maxima...", "noise=" + blueNoise+ " output=[Maxima Within Tolerance]");
//	close("membrane");
//				selectImage("Result of redDotChannelForDAPIMask");
//				rename("membrane");

	
//	waitForUser("Threshold find edges");
	//Finer nuclei selection

		selectImage("originImage");
		run("Select None");	
		Stack.setChannel(dapiChannel);

				newImage("dapiMaxMask", "8-bit black", width,height , 1);
//		waitForUser("0 1 index2 "+ index2+"roiAfterGrossDetection"+roiAfterGrossDetection+ "ind "+ind);
				roiManager("Deselect");
				roiManager("Select",selectionArray);
//				waitForUser("Combine");
selectionArrayLength=selectionArray.length; 
if (selectionArrayLength>1) {				roiManager("OR");		}

setForegroundColor(255, 255, 255);
if (selectionArrayLength>0)				run("Fill");

//		waitForUser("0 2");
//				setBatchMode("show");

				run("Select All");
				run("Divide...", "value=255.000");
				rename("dapiMaxMask");
				
				selectImage("dapiMaskFiltered");				

				
				run("Morphological Filters", "operation=Opening element=Disk radius=5");
			run("Thresholded Blur", "radius=7 threshold=15 softness=5 strength=1");
		run("Duplicate...", "title=dapiMax");
//			setBatchMode("show");

//				imageCalculator("Multiply create 32-bit stack", "dapiMaxMask" ,"dapiMax");

				run("Find Maxima...", "noise=160 output=[Maxima Within Tolerance]");
		run("Options...", "iterations=19 count=1 black edm=Overwrite do=Dilate");


//				run("Watershed");
		rename("NucleiMask1");
		selectImage("dapiMaskFiltered");

		run("Duplicate...", "title=NucleiMask2");
				setAutoThreshold("Huang dark");
run("Convert to Mask");
run("Fill Holes");
//waitForUser("1");
				imageCalculator("Multiply create 32-bit stack", "NucleiMask1" ,"NucleiMask2");
				rename("NucleiMask");
				run("8-bit");
				close("NucleiMask1");
					close("NucleiMask2");			

//run("Invert");				
				selectImage("dapiMax");
				run("8-bit");
//				imageCalculator("Multiply create 32-bit stack", "dapiMaxMask" ,"enhancedNucleiRecognitionMask");
//				rename("enhancedNucleiRecognitionMaskMasked");
//				run("8-bit");
				imageCalculator("Multiply create 32-bit stack", "redDotChannelForDAPIMask" ,"dapiMax");

//				run("close");				

			run("8-bit");
				close("dapiMax");
				selectImage("Result of redDotChannelForDAPIMask");	
//				waitForUser("Result of redDotChannelForDAPIMask");
	//			run("Invert");
				rename("dapiMax");			
				imageCalculator("Multiply create 8-bit stack", "dapiMaxMask" ,"dapiMax");
				selectImage("Result of dapiMaxMask");
				rename("dapiMaxMasked");
				roiManager("Select",selectionArray);
//				waitForUser("Combine");

if (selectionArrayLength>1) {				roiManager("OR");		}
//				run("Invert");
			
//				run("Unsharp Mask...", "radius="+sharpen_radius+" mask="+sharpen_weight);
//				run("Invert");			
//				run("Gaussian Blur...", "sigma=1");
				
				run("Thresholded Blur", "radius=4 threshold=20 softness=5 strength=1");
//							run("Find Maxima...", "noise=" + blueNoise+ " output=[Maxima Within Tolerance]");

//				run("Enhance Contrast...", "saturated=0.3 normalize");
//				setBatchMode("show");
				selectImage("membrane");	
//				waitForUser("check membrane");		
				run("Morphological Filters", "operation=Opening element=Disk radius=10");
				run("Morphological Filters", "operation=Gradient element=Disk radius=2");	
//				run("Enhance Contrast...", "saturated=0.3 normalize");
				run("Invert");
//				waitForUser("check membrane 2");	
				imageCalculator("Multiply create 32-bit stack", "membrane-Opening-Gradient" ,"dapiMaxMasked");
				selectImage("Result of membrane-Opening-Gradient");
				rename("membraneMasked");
					


				run("8-bit");
//				run("Invert");	

					setBatchMode("show");
//				run("Gaussian Blur...", "sigma=1");
				run("Thresholded Blur", "radius=1 threshold=15 softness=5 strength=1");		
	
//					setBatchMode("show");

				selectImage("membraneMasked");					

//			waitForUser("Check membraneMasked");
//				run("Multiply...", "value=0.8");
//				imageCalculator("Multiply create 32-bit stack", "dapiMaxMasked" ,"membraneMasked");
//				run("Thresholded Blur", "radius=4 threshold=20 softness=5 strength=1");		

//				selectImage("Result of dapiMaxMasked");
//				rename("dapiMaxMaskedEnhanced");	
//				run("8-bit");
	
				run("Find Maxima...", "noise=" + blueNoise+ " output=[Segmented Particles]");
				rename("dapiMaxMaskedSegmented");
				setAutoThreshold("Yen dark");
				run("Create Selection");			
				
				roiManager("Add");
				roiManager("Select",roiManager("Count")-1);					
				roiManager("Rename","segmentedMaskPos");	
				segmentedMaskPos=roiManager("Count")-1;
				
				newImage("dapiMaxMaskedSegmentedMaxima", "8-bit black", width,height , 1);
				
				roiManager("Select",selectionArray);	 
if (selectionArrayLength>1) {				roiManager("OR");	
				roiManager("Add");
	}

				
				roiManager("Select",roiManager("Count")-1);		
				roiManager("Rename","dapiMaxMaskedSegmentedMaxima");
				roiManager("Select",segmentedMaskPos);	
				SelectionArrayAddedPos=roiManager("Count")-1;
				roiManager("Select",segmentedMaskPos);	
				selectionArrayNuclei=newArray(SelectionArrayAddedPos,segmentedMaskPos);
			
				roiManager("Select",selectionArrayNuclei);
//				waitForUser("segmentedMaskPos"+segmentedMaskPos+"SelectionArrayAddedPos"+SelectionArrayAddedPos);
				if (selectionArrayLength>1) {				
					
				roiManager("Select",selectionArrayNuclei);
				roiManager("AND");	
				}
				run("Fill");				
				run("Select None");
				setAutoThreshold("Yen dark");
				run("Create Selection");
				run("Convert to Mask");		
//				run("Watershed");}

				roiManager("Select",segmentedMaskPos);	
				
				roiManager("Delete");
				ROIcontrol1=roiManager("Count");
//				roiManager("Select",SelectionArrayAddedPos);	
//				roiManager("Delete");
//									setBatchMode("show");
imageCalculator("Multiply create 32-bit stack", "dapiMaxMaskedSegmentedMaxima" ,"NucleiMask");
run("8-bit");
run("Watershed");
		run("Analyze Particles...", "size=100-"+maxNucleiSize*5+" pixel circularity=0-1.00 add");
//								waitForUser("1");

//					setBatchMode("show");
		close("redDotChannelForDAPIMask");
			/*
			for (index = 0 ; index < totalNucleiBeforeDeclustering ;index++){
				
				selectImage("dapiMax");
				roiManager("Select", roiBeforeGrossDetection+index);
				run("Create Mask");
				selectImage("Mask");
				rename("dapiMaxMask");
				run("Divide...", "value=255.000");
//				imageCalculator("Multiply create 32-bit stack", "dapiMaxMask" ,"enhancedNucleiRecognitionMask");
//				rename("enhancedNucleiRecognitionMaskMasked");
//				run("8-bit");		

				selectImage("dapiMaxSegmentedMaxima");
				roiManager("Select", roiBeforeGrossDetection+index);
				ROIcontrol=roiManager("Count");
//				waitForUser("maxNucleiSize"+maxNucleiSize);
				run("Analyze Particles...", "size=30-"+maxNucleiSize+" pixel circularity=0-1.00 add");


				//				waitForUser(roiAfterGrossDetection+"Check"+ROIcontrol);
//					print("blueNoise "+ blueNoise);
//						waitForUser("check segmentation");
					if (roiManager("Count") == ROIcontrol){
					run("Clear Results");
					roiManager("Select", roiBeforeGrossDetection+index);
					run("Measure");								//if the nucleus is not cut, its size should be verified before added
					NucArea=getResult("Area");
					NucArea=NucArea/(pixelSize*pixelSize);
					run("Clear Results");
					if (NucArea<maxNucleiSize) {
					roiManager("Add");
					}
					}
					
				selectImage("dapiMaxMasked");
				close();		
				selectImage("dapiMaxMask");
				close();
				selectImage("dapiMaskSegmented");
				close();		
				selectImage("dapiMaskSegmentedMaxima");
				close();
				selectImage("membraneMasked");
				close();
				selectImage("dapiMaxMaskedEnhanced");
				close();
				}
		}
		*/
				selectImage("dapiMaxMasked");
				close();		
				selectImage("dapiMaxMask");
				close();
				selectImage("dapiMaxMaskedSegmented");
				close();		
				selectImage("dapiMaxMaskedSegmentedMaxima");
				close();
				selectImage("membraneMasked");
				close();
				selectImage("membrane");
//				run("Invert");
				if (!(roiAfterGrossDetection==ROIcontrol1)) 
				{
					roiAfterGrossDetection=ROIcontrol1;
	//				waitForUser("Check problem why roiAfterGrossDetection not =ROIcontrol1");
				}
				
	print("Nuclei index ; Red Spot Number ; Green Spot Number ; Ratio red/green");
		totalROIAfterDeclustering = roiManager("Count");
		print("Total ROIS ", totalROIAfterDeclustering);

	totalNuclei=totalROIAfterDeclustering-roiAfterGrossDetection;

	
	setForegroundColor(255,255,255);
	selectImage("redDotMask");
	close();
	selectImage("C1-gBlur-1");
	close();
	selectImage("C2-gBlur-1");
	close();
	selectImage("C3-gBlur-1");
	close();
	selectImage("Result of C3-gBlur-1");
	close();

	selectImage("DAPInonSpecific");
	close();
	

//waitForUser(roiAfterGrossDetection+"abab 6"+totalNuclei);
//	waitForUser("Check ROIcontrol1"+ROIcontrol1+"Check roiAfterGrossDetection"+roiAfterGrossDetection+"Check Nuclei indentified"+totalNuclei);
	for (index2 = 0 ; index2 < totalNuclei;index2++){
//	if (index2==22){waitForUser("totalNuclei="+totalNuclei+"roiAfterGrossDetection="+roiAfterGrossDetection+"totalNuclei="+totalNuclei);}
//setBatchMode(false);		
		blueMaximaR=0;
		run("Collect Garbage");	
contrastRatio="Nan";

	img="Sharp_Local Contrast Origin";
	ind=index2+roiAfterGrossDetection;
    roiArray=newArray(ROI0,ind);
    Array.print(roiArray);
    //waitForUser;
	greenContrast=contrast_singleROI_calculation(img, ind);
//	waitForUser("greenCOn"+greenContrast);
	selectImage("RedLocalContrast");
	roiManager("Select",ind);
	run("Clear Results");
	run("Measure");
	MeanBackground=getResult("Mean");
	run("Clear Results");
	redContrast=contrast_singleROI_calculation("RedLocalContrast", ind);													//Average contrast of all red channel in a nuclei
//	waitForUser("MinSignal"+MinSignal);
		selectImage("originImage");
		setBatchMode("show");
		run("Select None");
		Stack.setChannel(dapiChannel);	
		roiManager("Deselect");
		roiManager("Select", ind);
		run("Clear Results");
		run("Measure");
		localBlueIntensity=getResult("Median");


		selectImage("originImage");
		run("Select None");
		Stack.setChannel(redDotChannel);	
		roiManager("Deselect");
		roiManager("Select", ind);
		run("Clear Results");
		run("Measure");
		averageRedInNucleus=getResult("Median");

				selectImage("originImage");
		run("Select None");
		Stack.setChannel(greenDotChannel);	
		roiManager("Deselect");
		roiManager("Select", ind);
		run("Clear Results");
		run("Measure");
		averageGreenInNucleus=getResult("Median");
		run("Clear Results");
		autofluoRedGreen=averageRedInNucleus+averageGreenInNucleus;

		if ((localBlueIntensity>0.5*minBlueSignalIntensity)&&(localBlueIntensity<1.5*maxBlueSignalIntensity)) {rightlocalBlueIntensity=true;}
else {rightlocalBlueIntensity=false;}
		
	//waitForUser(contrast);
		if ((redContrast>redContrastThreshold)&&(greenContrast >greenContrastThreshold)&&(autofluoRedGreen <1.5*autofluoRedGreenThreshold)&&(rightlocalBlueIntensity)) {				//it should be around 0.5 if in focus

//					waitForUser("averageRedInNucleus"+averageRedInNucleus+"averageGreenInNucleus"+averageGreenInNucleus+"redAutoLower"+redAutoLower+"greenAutoLower"+greenAutoLower);
		redDotNumber=0;
		greenDotNumber=0;
		redDotArea=0;
		highlyAmplified=true;
		newImage("Nuclei-"+(index2+1), "8-bit black", width,height , 1);
//		waitForUser("0 1 index2 "+ index2+"roiAfterGrossDetection"+roiAfterGrossDetection+ "ind "+ind);
		roiManager("Deselect");
		roiManager("Select", ind);
//		waitForUser("0 2");
		roiManager("Rename", "Nuclei-"+(index2+1));
		Roi.getBounds(Cell_x, Cell_y, Cell_width, Cell_height);
		run("Colors...", "foreground=white background=black selection=yellow");
		run("Fill");
		run("Select All");
		run("Divide...", "value=255.000");

		//Make link between FISH and IHC: print greenDotNumber redDotNumber with the cell name
		nucleiCenterPosition_X=(Cell_x+ Cell_width/2)/2;
		nucleiCenterPosition_Y=(Cell_y+ Cell_height/2)/2;
		c=0;
		notfound=true;
		found=false;
					kount=roiManager("Count");
				while ((c<numberOfCell)&&notfound&&(kount>0)) {				
					selectImage("finalOutline");
	//				waitForUser(ROIBeforeCellROIAdded+"&"+c);
	//			waitForUser("Check");
					roiManager("Select", (ROIBeforeCellROIAdded+c));
					nucleiCenterPosition_X1=nucleiCenterPosition_X+3;
					nucleiCenterPosition_1X=nucleiCenterPosition_X-3;
					nucleiCenterPosition_1Y=nucleiCenterPosition_Y-3;					
					nucleiCenterPosition_Y1=nucleiCenterPosition_Y+3;
					contain=((Roi.contains(nucleiCenterPosition_X, nucleiCenterPosition_1Y)||Roi.contains(nucleiCenterPosition_X1, nucleiCenterPosition_Y))||(Roi.contains(nucleiCenterPosition_X, nucleiCenterPosition_Y1)||Roi.contains(nucleiCenterPosition_X1, nucleiCenterPosition_Y1)))||((Roi.contains(nucleiCenterPosition_1X, nucleiCenterPosition_Y1)||Roi.contains(nucleiCenterPosition_1X, nucleiCenterPosition_Y))||(Roi.contains(nucleiCenterPosition_X, nucleiCenterPosition_1Y)||Roi.contains(nucleiCenterPosition_1X, nucleiCenterPosition_1Y))); //All 8 positions around the center
	//				waitForUser(contain);
					if (contain>0) {
						cellName=Roi.getName;
						roiManager("Select", index2+roiAfterGrossDetection);
						roiManager("Rename", cellName);
						//if ((redDotNumber+totalGreenPerNucleus)>0) {
							found=true;
							notfound=false;
	//										if (cellName=="2z01 IF Blue_P0007.tif cell 22") waitForUser("Check bug");

						}
																								//I dont delete the cell when it is found since one IHC cell can correspond with several FISH cell
					c=c+1;
					kount=roiManager("Count");
				}							
//				if (notfound) {		roiManager("Deselect");			
//					roiManager("Select", (ind));
//					setBatchMode("show");

//				waitForUser("Not found");}
						//}
	if (found) {				
					//roiManager("Select", (ROIBeforeCellROIAdded+c));
					//roiManager("Delete");
					//numberOfCell=numberOfCell-1;
					//c=c-1;
//if (kount==0) waitForUser("Check bug");

		selectImage("finalOutline");
		roiManager("Select", index2+roiAfterGrossDetection);
					run("Clear Results");
					run("Measure");
					NucleiArea=getResult("Area");
					NucleiArea=NucleiArea/(pixelSize*pixelSize);
					run("Clear Results");
		roiManager("Select", index2+roiAfterGrossDetection);
		run("Set Drawing Color...");
		setForegroundColor(0, 0, 255);
	//	roiManager("Deselect");
		roiManager("Draw");
		setForegroundColor(255, 255, 255);
		imageCalculator("Multiply create 32-bit stack", "gBlur2" ,"Nuclei-"+(index2+1));
	//	run("Gaussian Blur...", "sigma="+gaussianBlur);
		rename("Nuclei-"+(index2+1)+"mesure");


//green dot count
		selectImage("Nuclei-"+(index2+1)+"mesure");
		Stack.setChannel(greenDotChannel);
		run("Duplicate...", "title=greenDotThresholded");
		imageCalculator("Multiply create 32-bit stack", "redDotAutoFluo" ,"greenDotThresholded");
		selectImage("Result of redDotAutoFluo");
		rename("greenDotWithoutAutoFluo");
		roiManager("Select", index2+roiAfterGrossDetection);	
		setAutoThreshold("Yen dark");
	    getThreshold(lower,upper);
	    setThreshold(lower*factorGreen,upper);
	    
		setOption("BlackBackground", true);
//			waitForUser("before green dot threshold");

		run("8-bit");
		run("Convert to Mask");
		wsStatusGreen = false;
			if (wsStatusGreen){
			run("Watershed");
		}

	run("Select None");
	run("Duplicate...", "title=greenSignalArea");

	ROIbeforeRedDetect=roiManager("Count");
//waitForUser("1 1");
	    ROIbeforeGreenRegionDetect=roiManager("Count");
		run("Analyze Particles...", "size=2-1400 circularity=0-1.00 pixel add");

		greenRegionNumber=roiManager("Count")-ROIbeforeGreenRegionDetect;
//	waitForUser("1 2");

//Calculation of background intensity
//	waitForUser("After analyze particle");
	selectImage("greenSignalArea");
	run("Invert");
	
	imageCalculator("Multiply create 32-bit stack", "greenSignalArea" ,"Nuclei-"+(index2+1)); //for avoiding actefact due to autofluorescence removal, use redBallRolled instead of redBallRolledWithoutAuto otherwise the area around the removal   
	selectImage("Result of greenSignalArea");
	rename("greenBackground");
	
	run("Select None");
	run("8-bit");
	run("Invert");
	run("Create Selection");

	run("Clear Results");
	run("Measure");
	greenBackgroundArea=getResult("Area");
	run("Clear Results");	
//	waitForUser("c'est quoi ca??");
	if (greenBackgroundArea< 1000) {roiManager("Add");} 
//	waitForUser("background Selection");
	selectImage("greenSignalArea");
	close();
	selectImage("greenBackground");
	close();
		selectImage("originImage");																	//Measure now the green background
	Stack.setChannel(greenDotChannel);	
	roiManager("Select", roiManager("count")-1);
//		waitForUser("Check area of background");
	run("Clear Results");
	run("Measure");
	greenBackgroundMean=getResult("Median");
	run("Clear Results");
	minGreenDotIntensity=minGreenSignalIntensity; 
//	waitForUser(minGreenDotIntensity);
		totalGreenPerNucleus=0;
//		greenDotSizeSum=0;
greenClusterAreaSum=0;
blueMaximaG=0;
	if (greenRegionNumber>0) 
			{for (j= 0; j<greenRegionNumber; j++) {
				
					selectImage("originImage");
					Stack.setChannel(greenDotChannel);
					roiManager("Select", (ROIbeforeGreenRegionDetect+j));
					roiManager("Rename", cellName+"Nuclei-"+(index2+1)+"_greenSpotRegions"+j+1);
//			waitForUser("before green dot maxima");
//					selectImage("gBlur");
//					Stack.setChannel(greenDotChannel);
					roiManager("Select", (ROIbeforeGreenRegionDetect+j));
//			waitForUser("2");
						getSelectionBounds(GCx,GCy,GCw,GCh);
						if ((GCw==1)&&(GCy==1)) makeRectangle(GCx-1, GCy-1, GCw+2, GCh+2);
					run("Clear Results");
					run("Find Maxima...", "noise="+greenNoise+" output=[Maxima Within Tolerance]");
					roiManager("Select", (ROIbeforeGreenRegionDetect+j));	
					run("Measure");
//					greenClusterArea=getResult("IntDen");
//					greenClusterArea=greenClusterArea/255;
//					waitForUser(greenClusterArea);
					greenClusterArea=getResult("Area");
					greenClusterArea=greenClusterArea/(pixelSize*pixelSize);

//					waitForUser(greenClusterArea);
					run("Clear Results");
//					selectImage("gBlur");
//					Stack.setChannel(greenDotChannel);
//					roiManager("Select", (ROIbeforeGreenRegionDetect+j));
//					run("Find Maxima...", "noise="+greenNoise+" output=[Single Points]"); //there is a space before the output
				//	rename("MaxGreenPoint");
					ROIbeforeGreenDotDetection=roiManager("Count");
					run("Analyze Particles...", "size=0-"+maxGreenDotArea+" pixel circularity=0.2-1.00 add");
					greenDotNumber=roiManager("Count")-ROIbeforeGreenDotDetection;
					
					close("*Maxima*");

					
					numberGreenDot=0;

			if (greenDotNumber>0) {
 			//2^32
				for (y=0; y<greenDotNumber;y++){
						run("Clear Results");
						
						selectImage("originImage");
						run("Select None");
						Stack.setChannel(greenDotChannel);	
						roiManager("Deselect");
						roiManager("Select", (ROIbeforeGreenDotDetection+y));
						run("Clear Results");
						run("Measure");
						localGreenIntensity=getResult("Median");
					
						selectImage("originImage");
						Stack.setChannel(redDotChannel);
						roiManager("Select", (ROIbeforeGreenDotDetection+y));												
						run("Measure");					
						redAutoFluo=getResult("Median");			//add here condition to improve green recognition
						greenDotArea=getResult("Area");	
						run("Clear Results");		
						greenDotArea=greenDotArea/(pixelSize*pixelSize);
						
						selectImage("originImage");
						Stack.setChannel(redDotChannel);				
						roiManager("Select", (ROIbeforeGreenDotDetection+y));
						if ((GCw+GCh)<4) makeRectangle(GCx-1, GCy-1, GCw+2, GCh+2);
						run("Find Maxima...", "noise="+redNoise/1.2+" output=Count");
						NoRedNonSpecific=getResult("Count");
								selectImage("originImage");
						Stack.setChannel(redDotChannel);				
						roiManager("Select", (ROIbeforeGreenDotDetection+y));
						
						if ((GCw+GCh)<4) makeRectangle(GCx-1, GCy-1, GCw+2, GCh+2);
						run("Find Maxima...", "noise="+greenNoise+" output=Count");			//Find if there is real dot there by applying more string Noise
						NoRedSpecific=getResult("Count");
						if (NoRedSpecific>0) {NoRedNonSpecific=0;
						redAutoFluo=redSignalAverage;}
//					waitForUser("NoRedNonSpecific"+NoRedNonSpecific+"NoRedNonSpecific==0"+(NoRedNonSpecific==0)+"redNoise"+redNoise/4);
if ((localGreenIntensity>0.5*minGreenSignalIntensity)&&(localGreenIntensity<1.7*maxGreenSignalIntensity)) {rightlocalGreenIntensity=true;}
else {rightlocalGreenIntensity=false;}
if ((NoRedSpecific>0)&&(rightlocalGreenIntensity==false)) rightlocalGreenIntensity=true;
if ((redSignalAverage)>minRedSignalIntensity*2) {redSignalAverage=minRedSignalIntensity*2;}
							selectImage("dapiLocalAuto");							
						roiManager("Select", (ROIbeforeGreenDotDetection+y));
//							makeRectangle(GCx-1, GCy-1, GCw+2, GCh+2);												
							run("Find Maxima...", "noise="+blueNoise*8+" output=Count");     
							blueMaximaG=getResult("Count");

//				roiManager("Rename", cellName+"Nuclei-"+(index2+1)+"not good, red maxima OK is"+ (NoRedNonSpecific==0)+"red autofluo small= "+(redAutoFluo<redSignalAverage*5)+"green Area small "+(greenDotArea<maxGreenDotArea)+"rightlocalGreenIntensity"+rightlocalGreenIntensity+"(blueMaxima<1)"+(blueMaximaG<1));							
					if ((NoRedNonSpecific==0)&&(redAutoFluo<redSignalAverage*5)&&(greenDotArea<maxGreenDotArea)&&rightlocalGreenIntensity&&(blueMaximaG<1)){
						run("Clear Results");			
						selectImage("originImage");
						Stack.setChannel(greenDotChannel);
						roiManager("Select", (ROIbeforeGreenDotDetection+y));
						run("Measure");
						greenDotIntensity=getResult("Median");
		//				greenDotSize=getResult("Area");
						run("Clear Results");

								if (greenDotIntensity>minGreenDotIntensity) {
//							waitForUser(minGreenDotIntensity);
//							waitForUser(greenDotIntensity);
							minGreenDotIntensity=minGreenDotIntensity+(greenDotIntensity-minGreenDotIntensity)/5;
						}
						else {
							minGreenDotIntensity=minGreenDotIntensity-(minGreenDotIntensity-greenDotIntensity)/5;
						}
				selectImage("finalOutline");
				greenClusterAreaSum=greenClusterAreaSum+greenClusterArea;  								//If that is a dot then add the size
				roiManager("Select", (ROIbeforeGreenDotDetection+y));
				roiManager("Rename", cellName+"Nuclei-"+(index2+1)+"_greenSpots_detected"+y+1);
				run("Set Drawing Color...");
				setForegroundColor(0, 255, 0);
	//			roiManager("Deselect");
				roiManager("Draw");
				setForegroundColor(255, 255, 255);
	//			greenDotSizeSum=greenDotSizeSum+greenDotSize;
				numberGreenDot++;
		//	selectImage("MaxGreenPoint");
				}
				else {
				selectImage("finalOutline");
				roiManager("Select", (ROIbeforeGreenDotDetection+y));
				run("Measure");
				roiManager("Rename", cellName+"Nuclei-"+(index2+1)+"not good, red maxima OK is"+ (NoRedNonSpecific==0)+"red autofluo small= "+(redAutoFluo<redSignalAverage*5)+"green Area small "+(greenDotArea<maxGreenDotArea)+"rightlocalGreenIntensity"+rightlocalGreenIntensity+"(blueMaxima<1)"+(blueMaximaG<1));
					
					}
				}

			}
						totalGreenPerNucleus=totalGreenPerNucleus+numberGreenDot;

			}
		}
				totalGreenDotSize=greenClusterAreaSum/(pixelSize*pixelSize);
		
		selectImage("greenDotThresholded");
		close();

//		waitForUser("check redBallRolled Nuclei-");
//Red detection

		imageCalculator("Multiply create 32-bit stack", "redBallRolledWithoutAutofluo" ,"Nuclei-"+(index2+1)); //for avoiding actefact due to autofluorescence removal, use redBallRolled instead of redBallRolledWithoutAuto otherwise the area around the removal   
		selectImage("Result of redBallRolledWithoutAutofluo");
		rename("redDotThresholded");//important change
		roiManager("Select", index2+roiAfterGrossDetection);
		setAutoThreshold("Yen dark");
	    getThreshold(lower,upper);
	    setThreshold(lower*factorRed,upper);
	   	setOption("BlackBackground", true);
		run("8-bit");
		run("Convert to Mask");
		wsStatusRed = true;
			if (wsStatusRed){
			run("Watershed");
		}
//		waitForUser("after red threshold");

	run("Select None");
//  run("Duplicate...", "title=redSignalArea");
//	imageCalculator("Multiply create 8-bit stack", "redSignalArea" ,"redDotAutoFluo");
//	selectImage("redSignalArea");
//	close();
//	selectImage("Result of redSignalArea");
//	rename("redSignalArea");
//	waitForUser("after red threshold-0");
	//Why before I wanted to increase the size of the area of redots having 1 pixel size?						
//	run("Analyze Particles...", "size=1-2500 pixel circularity=0-1.00 display");
close("redSignalArea");
localIntDenSum=0;
//Calculation of background intensity
run("Clear Results");
		selectImage("originImage");
		Stack.setChannel(redDotChannel);
		roiManager("Select", index2+roiAfterGrossDetection);
		getSelectionBounds(RFSx,RFSy,RFSw,RFSh);				
		if ((RFSw<30) && (RFSh<30) ) {makeRectangle(RFSx-1, RFSy-1, RFSw+2, RFSh+2);}
		else{roiManager("Select",  index2+roiAfterGrossDetection);}
																											
//		waitForUser(" check red spot region");

//		
		run("Find Maxima...", "noise="+redNoise/1.1+" output=[Maxima Within Tolerance]");
		rename("signalAtFirstScan");
		
		run("Find Maxima...", "noise="+redNoise/1.1+" output=[Segmented Particles]");
		rename("NucleiSegmented");
		imageCalculator("Multiply create 32-bit stack", "NucleiSegmented" ,"Nuclei-"+(index2+1)); //for avoiding actefact due to autofluorescence removal, use redBallRolled instead of redBallRolledWithoutAuto otherwise the area around the removal   
		selectImage("Result of NucleiSegmented");
		rename("NucleiSegmentedMasked");	
		roiManager("Select", index2+roiAfterGrossDetection);	
		run("Clear Results");
			ROIbeforeRedDetect=roiManager("Count");
				run("8-bit");
//				waitForUser("check");
		run("Analyze Particles...", "size=1-"+maxNucleiSize*2+" pixel display summarize add");			//For having small dots 
			redRegionNumber=roiManager("Count")-ROIbeforeRedDetect;


//		IJ.renameResults("Results");
//waitForUser("check");
 		if (nResults>0) {
		redDotFirstScan=nResults ;

		}
		else {redDotFirstScan=0;}
//		print(redDotFirstScan);
		run("Clear Results");
close("NucleiSegmentedMasked");

close("NucleiSegmented");

nSize=round(NucleiArea/typicalNucleiSize+0.5);

redDotFirstScan=redDotFirstScan/nSize;
highlyAmplified=true;
	
	ROIbeforeBackground=roiManager("Count");
	selectImage("signalAtFirstScan");
	run("Invert");
	
	imageCalculator("Multiply create 32-bit stack", "signalAtFirstScan" ,"Nuclei-"+(index2+1)); //for avoiding actefact due to autofluorescence removal, use redBallRolled instead of redBallRolledWithoutAuto otherwise the area around the removal   
	selectImage("Result of signalAtFirstScan");
	rename("redBackground");
	
		run("Select None");
	run("8-bit");
	run("Invert");
	run("Create Selection");

	run("Clear Results");
	run("Measure");
	redBackgroundArea=getResult("Area");
	print(redBackgroundArea);
	run("Clear Results");	
	if (redBackgroundArea< maxNucleiSize) {roiManager("Add");} 	

//waitForUser("background Selection");
	selectImage("signalAtFirstScan");
//	waitForUser("signalAtFirstScan");
	
	close();
	selectImage("redBackground");
	close();
	
	selectImage("originImage");
	Stack.setChannel(redDotChannel);	
	roiManager("Select", roiManager("count")-1);
//		waitForUser("Check area of background");
	run("Measure");
	redBackgroundMean=getResult("Median");
	run("Clear Results");
	selectImage("redContrast");
	
	roiManager("Select", roiManager("count")-1);
//		waitForUser("Check area of background");
	run("Measure");
	redBackgroundMeanEnhanced=getResult("Median");
	run("Clear Results");
//	waitForUser("Check area of background");
//	roiManager("Select", roiManager("count")-1); //Take the background selection
//	roiManager("Delete");			
	if(roiManager("Count") < 10) {
	showMessage("Roi Manager was closed 5");
}
	//
	//	ROIbeforeRedDetect=roiManager("Count");
	//	run("Analyze Particles...", "size=1-2000 pixel circularity=0.10-1.00 add");
	//	waitForUser(greenDotNumber);
	//	redRegionNumber=roiManager("Count")-ROIbeforeRedDetect;
		imageCalculator("Multiply create 32-bit stack", "redBallRolled" ,"Nuclei-"+(index2+1)); //for avoiding actefact due to autofluorescence removal, use redBallRolled instead of redBallRolledWithoutAuto otherwise the area around the removal   
		selectImage("Result of redBallRolled");
		rename("redBallRolled Nuclei-"+(index2+1));//important change
		p=0;
		redClusterAreaSum=0;
		redClusterNumber=0;
		positionArray=newArray();
		redDotNumberArray=newArray();

		if (redRegionNumber>0) 
		{for (i= 0; i<redRegionNumber; i++) {
redSignalMean=redBackgroundMean;
	//Select the maxima within the region of interest 
					newImage("Nuclei-"+(index2+1)+"_redSpots_region"+(i+1), "8-bit black", width,height , 1);
					roiManager("Select", (ROIbeforeRedDetect+i));
					
setForegroundColor(255, 255, 255);
					run("Fill");
					run("Select All");
//					run("Erode");
					run("Divide...", "value=255.000");
	
					imageCalculator("Multiply create 32-bit stack", "Nuclei-"+(index2+1)+"_redSpots_region"+(i+1),"redBallRolled Nuclei-"+(index2+1));
					rename("redDotClusters in Nuclei-"+(index2+1));
//					waitForUser(highlyAmplified);
					roiManager("Select", (ROIbeforeRedDetect+i));
					roiManager("Rename", cellName+"cluster"+i+", highly amplified="+highlyAmplified);
					
//					waitForUser("measure of signal intensity 0");
					if (highlyAmplified)  {
					run("Clear Results");
//					selectImage("originImage");
					selectImage("redContrast");
//					Stack.setChannel(redDotChannel);						
					roiManager("Select", (ROIbeforeRedDetect+i));				
					getSelectionBounds(xClust, xClust, widthClust, heightClust);
					if ((widthClust<2)&&(widthClust<2)) makeRectangle(xClust-1, xClust-1, widthClust+2, heightClust+2);
					run("Find Maxima...", "noise="+redNoise*9+" output=Count");
					NumberMaxima=getResult("Count");	
					if (NumberMaxima>0) {	
					run("Find Maxima...", "noise="+redNoise*9+" output=[Point Selection]");	
					run("Measure");
					run("Summarize");
					if (nResults>4) {
					redSignalMean=getResult("Mean",nResults-4);
		//			waitForUser("Value of Mean:"+redSignalMean);
					}
					else {
					redSignalMean=getResult("Max");
					}

					}
					else redSignalMean=redBackgroundMeanEnhanced;
//

//					waitForUser("Noise:"+(redSignalMean-redBackgroundMean)/2);

//									waitForUser("redSignalMean"+redSignalMean+"redBackgroundMean"+redBackgroundMean);//Full width quater maxima
					maxFWHM=(intensityOfRed*6-redBackgroundMeanEnhanced)*intensityCoefficient/2;
					minFWHM=(intensityOfRed-redBackgroundMeanEnhanced)*intensityCoefficient/2;
					FWHM=(400+ (abs((redSignalMean*1.2-redBackgroundMeanEnhanced)*intensityCoefficient/2)/(maxFWHM-minFWHM)*1000))*(parseInt(redSignalMean/intensityOfRed+0.5));	//FWHM is calculated as normalized contrast multiplied by a correction facotr rednoise/100
					
					if (FWHM==0) {
						FWHM=4294967296;
					}
					if (FWHM<redNoise*4) {
						FWHM=redNoise*4;
					}
					if (FWHM<400) {
					FWHM=400;
					}
					if (FWHM>(redNoise*25)) {
						FWHM=redNoise*25;
					}
					if ((intensityOfRed<1200)&&(FWHM>1200)) {
					FWHM=1200;
					}	
					if (NumberMaxima<1) {						
					FWHM=4294967296;																//delete the area which has no signal	
//					waitForUser("Cluster not choosen");
						} 																				//remove all false negative cluster
//						selectImage("originImage"); //or redBallRolled Nuclei-"+(index2+1)
//					Stack.setChannel(redDotChannel);	
					selectImage("redContrast");		
					roiManager("Select", (ROIbeforeRedDetect+i));								
					roiManager("Rename", cellName+"cluster identifed with higlyAmplified and FWHM="+FWHM);
//					waitForUser("Check FWHM"+FWHM+"RedNoise*10="+redNoise*10+"redNoise*23="+redNoise*23);
					if (higlyAmplifiedTissue) {
					run("Find Maxima...", "noise="+FWHM+" output=Count");	
						NumberMaxima=getResult("Count");	
					if (NumberMaxima<1) {FWHM=FWHM/2;
					}
					}
						//					Stack.setChannel(redDotChannel);	
					selectImage("redContrast");			
					run("Find Maxima...", "noise="+FWHM+" output=[Maxima Within Tolerance]");			//cluster identification, width half maxima
					run("Clear Results");	
//					waitForUser("cluster identification"+FWHM);
					}		
//					{
//					selectImage("redDotClusters in Nuclei-"+(index2+1));
//					roiManager("Select", (ROIbeforeRedDetect+i));
//					run("Find Maxima...", "noise="+redNoise+" output=[Maxima Within Tolerance]");			
//					}
					else {	
						selectImage("originImage");
						Stack.setChannel(greenDotChannel);
						roiManager("Select", (ROIbeforeRedDetect+i));
						run("Clear Results");
						run("Measure");
						MeanAreaIntensityNonAmplified=getResult("Median");	
						run("Clear Results");
						selectImage("originImage"); 						
						Stack.setChannel(redDotChannel);
						roiManager("Select", (ROIbeforeRedDetect+i));
						getSelectionBounds(RCx,RCy,RCw,RCh);

						
						if ((RCw==1) || (RCh==1) ) {makeRectangle(RCx-1, RCy-1, RCw+2, RCh+2);}
						else{roiManager("Select", (ROIbeforeRedDetect+i));}
						
						run("Find Maxima...", "noise="+redNoise+" output=[Maxima Within Tolerance]");
//						waitForUser("single dot"+redNoise);
//						roiManager("Select", (ROIbeforeRedDetect+i));	
//						run("Measure");
//						AreaNonAmplified=getResult("IntDen");
//						AreaNonAmplified=AreaNonAmplified/255;
//						run("Clear Results");
//						close();
//						selectImage("redBallRolled Nuclei-"+(index2+1));
//						roiManager("Select", (ROIbeforeRedDetect+i));
//					run("Find Maxima...", "noise="+redNoise+" output=[Single Points]");			
						}
						
						rename("redDotCluster2");
					ROIBeforeLocalMaxDetection=roiManager("Count");
					
						roiManager("Select", (ROIbeforeRedDetect+i));
//						roiManager("Select", (ROIbeforeRedDetect+i));					
//					waitForUser("RedDotMaxima-1");
//if (FWHM==1574)  waitForUser("check cluster");
//					run("Analyze Particles...", "size=1-"+redDotLimit*1.2+" pixel circularity=0-1.00 add");					//round 2 detect cluster (detect Maxima within Tolerance)					
					run("Analyze Particles...", "size=1-"+redDotLimit+" pixel circularity=0.1-1 add");		
//					waitForUser("RedDotMaxima after detection round 2-1");
					redDotMaximaNumber=roiManager("Count")-ROIBeforeLocalMaxDetection;
					sumlocalMax=0;
					selectImage("redDotClusters in Nuclei-"+(index2+1));
					close();
					selectImage("redDotCluster2");
					close();
//	if(redDotMaximaNumber>redCountThreshold){highlyAmplified=true;}
				for (k=0; k<redDotMaximaNumber; k++){
							selectImage("originImage");
							Stack.setChannel(redDotChannel);	
							roiManager("Select", (ROIBeforeLocalMaxDetection+k));	
						
							run("Measure");		
							localRedIntensity = getResult("Median");		
							localMaxIntensity = getResult("Max");
							localMaxArea = getResult("Area");
							localIntDen = getResult("IntDen");
														
							getSelectionBounds(xCluster, yCluster, widthCluster, heightCluster);
							run("Clear Results");
							selectImage("RedLocalContrast");
							
							roiManager("Select", (ROIBeforeLocalMaxDetection+k));	
//							redCon=contrast_calculation("redContrast", roiArray);
							//getSelectionBounds(xroi,yroi,wroi,hroi);
//							makeRectangle(xCluster-1,yCluster-1,widthCluster+2,heightCluster+2);
//							getRawStatistics(nPixels, mean, min, max);
							run("Clear Results");								
							run("Measure");
//							MaxSignal=getResult("Max");
//							MinSignal=getResult("Min");
							MeanSignal=getResult("Mean");
							run("Clear Results");	
//							selectImage("redContrast");									
//							roiManager("Select", (ROIBeforeLocalMaxDetection+k));					
//							run("Measure");
//							run("Clear Results");
//							if (MinSignal<minHER2InNuclei) MinSignal=minHER2InNuclei;
							redCon=(MeanSignal-MeanBackground)/(MeanSignal+MeanBackground);
							
				//			waitForUser("redCon"+redCon+"MeanSignal"+MeanSignal+"MeabBackgroundSignal"+MeanBackground);
				//			if (MeanSignal<MeanBackground*2) redCon=0;				//discard all cluster having small absolute contrast
				//			MeanSignal=0;
				//			MinSignal=0;
				//			MaxSignal=0;
				//			MeanBackground=0;
//							waitForUser(redCon);
//							print("MaxSignal"+MaxSignal+"MinSignal"+MinSignal+"Contrast"+redCon);
//							redCon=contrast_singleROI_calculation("RedLocalContrast",(ROIBeforeLocalMaxDetection+k));
//							greenCon=contrast_singleROI_calculation(img,(ROIbeforeRedDetect+i));
							
//							contrastRatio=redCon/greenCon;
							selectImage("originImage");
							Stack.setChannel(greenDotChannel);
							roiManager("Select", (ROIBeforeLocalMaxDetection+k));		
							run("Measure");		
							areaIntensity=getResult("Median");	//green intensity
							run("Clear Results");							
//							if ((widthCluster==1)&&(heightCluster==1))
							makeRectangle(xCluster-1, yCluster-1, widthCluster+2, heightCluster+2);
//							waitForUser("areaIntensity");
		
//							selectImage("membrane");
							
							if (highlyAmplified==0){areaIntensity=MeanAreaIntensityNonAmplified;} 				//If a negative case, we still use the mean intensity of the cluster to decide whether it is an autofluorescent area
//							if (highlyAmplified==0) {localMaxArea=AreaNonAmplified;}
							greenNonSpecific=greenNoise/5;//normally 1.4
							if (greenNonSpecific<10) {greenNonSpecific=10;}
							run("Find Maxima...", "noise="+greenNonSpecific+" output=Count");            //arbitrary choosen greenNoise/4
							greenMaxima=getResult("Count");
							selectImage("originImage");
							Stack.setChannel(greenDotChannel);
							makeRectangle(xCluster-1, yCluster-1, widthCluster+2, heightCluster+2);					
							run("Find Maxima...", "noise="+greenNoise+" output=Count");          
							greenMaximaCheck=getResult("Count");												//if it is a green dots, don't delete
							if (greenMaximaCheck>0) {greenMaxima=0;
							areaIntensity=minGreenSignalIntensity/3;}
//							waitForUser("autofluorescence detection");
							run("Clear Results");		
							redDotNumberPerCluster=0;
							
							selectImage("dapiLocalAuto");						
							roiManager("Select", (ROIBeforeLocalMaxDetection+k));	
							makeRectangle(xCluster-1, yCluster-1, widthCluster+2, heightCluster+2);														
							run("Find Maxima...", "noise="+blueNoise*22+" output=Count");     //10 is too low
							blueMaximaR=getResult("Count");    
if ((localRedIntensity>minRedSignalIntensity*0.5)&&(localRedIntensity<maxRedSignalIntensity*1.7)) {rightRedIntensity=true;}
else {rightRedIntensity=false;}

//							waitForUser("localMaxArea"+round(localMaxArea/(pixelSize*pixelSize)));	
//							waitForUser(minGreenDotIntensity);		
										angleAtPeak=localRedIntensity/(localMaxArea/(pixelSize*pixelSize));
										thresholdPeak=(minRedSignalIntensity/redDotLimit);
										validAngle=(angleAtPeak>thresholdPeak);	
//										if (!validAngle) waitForUser("angleAtPeak"+angleAtPeak+"thresholdAtPeak"+thresholdPeak);					
									if ((localMaxArea>0)&&(greenMaxima<1)&&(areaIntensity<2.5*minGreenSignalIntensity)&&(areaIntensity<1.2*minGreenDotIntensity)&&((localMaxArea/(pixelSize*pixelSize))<(0.9*redDotLimit))&&rightRedIntensity&&validAngle&&(redCon>redContrastThreshold)&&(blueMaximaR<1)) {						//Count as a red dot only if it is not a local maxima for green chanel and have an avereage intensity small enough										
										selectImage("originImage");
										Stack.setChannel(greenDotChannel);
										
										run("Find Maxima...", "noise="+greenNoise+" output=Count");
												greenSignalDetected=getResult("Count"); 
											selectImage("originImage");
										Stack.setChannel(greenDotChannel)									
										run("Find Maxima...", "noise="+greenNonSpecific+" output=[Maxima Within Tolerance]"); 
										run("Invert");
										run("Create Selection");
										run("Measure");
										greenNonSpecArea=getResult("Area");
											greenNonSpecArea=greenNonSpecArea/(pixelSize*pixelSize);
											
											if ((1<greenNonSpecArea)&&(greenNonSpecArea<(0.99*width*height)&&(greenSignalDetected==0))){
											roiManager("Select", (ROIBeforeLocalMaxDetection+k));
											roiManager("Rename", "not good, greenNonSpecArea too high="+greenNonSpecArea);
												}
												else {
										redClusterAreaSum=redClusterAreaSum+localMaxArea;  
										if (highlyAmplified) {									
											if (localRedIntensity<redBackgroundMean) {localRedIntensity=redBackgroundMean;}
										redDotNumberPerCluster=parseInt((((localRedIntensity-redBackgroundMean)/(localRedIntensity+redBackgroundMean))*(localMaxArea/(pixelSize*pixelSize))+0.137)/0.6*calibrationFactor+0.5); //calibrationFactor*localMaxArea*localRedIntensity/(4*pixelSize*pixelSize*intensityOfRed)+0.5);		//Supposing there is 2 pixel per red cluster
										redDotNumber=redDotNumber+redDotNumberPerCluster;
										redDotArea=redDotArea+localMaxArea;}
										else {redDotNumberPerCluster=1;
										redDotNumber=redDotNumber+1;	
										}

//					waitForUser("localIntDen"+localIntDen);

																localIntDenSum=localIntDenSum+localIntDen;
					
	//				waitForUser("localIntDenSum"+localIntDenSum);
	//															 if (redDotNumberPerCluster>0) {										
																 	roiManager("Select", (ROIBeforeLocalMaxDetection+k));
															roiManager("Rename", cellName+"-localRedIntensity"+localRedIntensity+"-contrast"+redCon);		
																					
													redDotNumberArray=Array.concat(redDotNumberArray,redDotNumberPerCluster);
																				ROIBeforeLocalMaxDetectionk=ROIBeforeLocalMaxDetection+k;
													positionArray=Array.concat(positionArray,ROIBeforeLocalMaxDetectionk);	
													redClusterNumber=redClusterNumber+1;
													
//													waitForUser("localIntDenSum"+ROIBeforeLocalMaxDetectionk+"redClusterNumber"+redDotNumberPerCluster);
													
//												}
					
									if (cellName=="2T Blue_P0099.tif cell 33") waitForUser("9");
												}
														}
													else{	selectImage("finalOutline");
																roiManager("Select", (ROIBeforeLocalMaxDetection+k));
																roiManager("Rename", "localMaxArea>0"+(localMaxArea>0)+"greenMaxima number OK="+(greenMaxima==0)+"green Intensity signal smaller min greenSignal OK="+(areaIntensity<2.5*minGreenSignalIntensity)+"green areaIntensity OK="+ (areaIntensity<1.2*minGreenDotIntensity)+"localMaxArea small enough="+((localMaxArea/(pixelSize*pixelSize))<(0.9*redDotLimit))+"rightRedIntensity"+rightRedIntensity+"validAngle"+validAngle+"redCon>redContrastThreshold"+(redCon>redContrastThreshold)+"(blueMaxima<1)"+(blueMaximaR<1));	
														}																													
										}
				}
						
//					selectImage("Nuclei-"+(index2+1)+"_redSpots_region"+(i+1));
//				run("Close");	
				close("Nuclei-"+(index2+1)+"_redSpots_region*");

//	waitForUser("localIntDenSum"+localIntDenSum);																																			
	}


	oneDotIntDen=intensityOfRed*redDotLimit*pixelSize*pixelSize/7;	
//	localIntDenSum=localIntDenSum/oneDotIntDen;
	IntDenThreshold=oneDotIntDen;
//	waitForUser("localIntDenSum"+localIntDenSum+"IntDen threshold"+IntDenThreshold+"redClusterNumber"+redClusterNumber);
	if (localIntDenSum>IntDenThreshold) highlyAmplified=1;
	
	if (highlyAmplified) {for (m=0;m<redClusterNumber;m++) {
											selectImage("finalOutline");
											roiManager("Select", positionArray[m]);
											//waitForUser("positionArray[m]"+positionArray[m]+"redDotNumberArray"+redDotNumberArray[m]);
											//getSelectionBounds(xDot, yDot, widthDot, heightDot);
											run("Set Drawing Color...");
											setForegroundColor(255, 0, 0); //mark red
											roiManager("Draw");
											roiManager("Select", positionArray[m]);
											
											getSelectionBounds(xCluster, yCluster, widthCluster, heightCluster);
											setForegroundColor(255, 255, 255);//return to white
											selectImage("finalOutline");
											//setForegroundColor(255, 255, 255);
											setColor(255, 255, 255);
											 setFont("Monospaced", 9);
											 drawString(redDotNumberArray[m], xCluster-1, yCluster+4);
												}
	}
	else {redDotNumber=redClusterNumber;
	for (m=0;m<redClusterNumber;m++) {
											selectImage("finalOutline");
											roiManager("Select", positionArray[m]);
											getSelectionBounds(xDot, yDot, widthDot, heightDot);
											
											makeRectangle(xDot+widthDot/2, yDot+heightDot/2, 1, 1);
											run("Set Drawing Color...");
											setForegroundColor(255, 0, 0); //mark red
											run("Draw", "slice");
}
											// drawString(redDotNumberArray[m], xCluster-1, yCluster+4);
	}
	
	
		close("redDotThresholded");	

																						
if ((redDotNumber+totalGreenPerNucleus)>0) {
		redDotTotal=redDotTotal+redDotNumber;
		greenDotTotal=greenDotTotal+totalGreenPerNucleus;
}	
																							
totalRedClusterArea=parseInt(redClusterAreaSum/(pixelSize*pixelSize));
		close("Nuclei-*");
//		run("Close");
//		selectImage("Nuclei-"+(index2+1)+"mesure");
//		run("Close");	
																				
		close("greenDotWithoutAutoFluo");
		close("redBallRolled Nuclei-*");
//	print(redDotNumber+";"+NucleiArea+";"+nucleiCenterPosition_X+";"+nucleiCenterPosition_Y+";"+totalGreenDotSize+";"+totalRedClusterArea);
	print(f, substring(file,0,lengthOf(file)-4)+";"+IJ.pad(linecount,4)+";"+ cellName +";"+ totalGreenPerNucleus+";"+redDotNumber+";"+NucleiArea+";"+nucleiCenterPosition_X+";"+nucleiCenterPosition_Y+";"+averageGreenInNucleus+";"+averageRedInNucleus+";"+totalGreenDotSize+";"+totalRedClusterArea+";"+greenContrast+";"+redContrast);
//	waitForUser("close the image");


roiManager("Save", ROIplace+"tile_FISH"+IJ.pad(code,4)+".zip"); 	
				
					}
					else{	selectImage("finalOutline");						//If not found in IHC image
												roiManager("Select", index2+roiAfterGrossDetection);
											roiManager("Rename", "not found in IHC");	
									}		
		}
		else{selectImage("finalOutline");						//If blue
												roiManager("Select", index2+roiAfterGrossDetection);
											roiManager("Rename", "red contrast acceptable="+(redContrast >redContrastThreshold)+"green contrast acceptable="+(greenContrast >greenContrastThreshold)+"(autofluoRedGreen <1.5*autofluoRedGreenThreshold)"+(autofluoRedGreen <1.5*autofluoRedGreenThreshold)+"rightlocalBlueIntensity"+(rightlocalBlueIntensity));	
			}
							checkIndex=((index2/50)==parseInt(index2/50));			//clear memory each 15 cells
				wait(10); 
	}
	
//setBatchMode(false);
//		waitForUser("after one cycle");		
//	waitForUser("close the image");
		 	selectImage("finalOutline");
	saveAs("Tiff", output+"outline" +file+".tif");
	}
}

//	     setResult("Tile number", linecount, linecount);
//	  setResult("Average green dot", linecount, greenDotTotal/totalNuclei);
// setResult(" average red dot", linecount, redDotTotal/totalNuclei);
 // setResult("ratio", linecount, redDotTotal/greenDotTotal);
 //	 setOption("ShowRowNumbers", false);
	//  updateResults;
	// saveAs("results", output+substring(file,0,lengthOf(file)-4)+"counting result.csv");

	run("Clear Results");

//	if (linecount==startingTile) waitForUser("Check");
	
	run("Close All");	
	
 		}
	   
 		
	
