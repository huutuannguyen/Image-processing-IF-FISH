var pixelSize=0.3225;
var numberGreenDot=0;	
var redDotNumber=0;	
var sharpen_radius=2; sharpen_weight=0.9; 
function canonicArray(n){	
	cArr=newArray(n);
for (i=0;i<n;i++){
		cArr[i]=i;
print(cArr[i]);
}
return cArr;
}
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
function blurfilter(Original_Image, Threshold_Contrast, Contrast_Rescale_Factor, sharpen_radius, sharpen_weight, local_radius) {

run("Clear Results");
run("Set Scale...", "distance=1 known="+pixelSize+" pixel=1 unit=um global");
run("Set Measurements...", "area mean standard min median area_fraction display redirect=None decimal=0");
selectImage(Original_Image);



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

ROI0=roiManager("Count"); 	
T1=Adapted_Thresholding(Threshold_Contrast,title+"_Local Contrast");
//waitForUser("2");
	close(title); 
	close(title+"_Min"); 
	close(title+"_Max"); 

	
return ROI0;

	}
function contrast_singleROI_calculation(img, roi) {
//waitForUser("3");
//selectImage(title+"_Local Contrast Origin");
//roi=newArray(ROI0,ROI_position);
selectImage(img);
//Array.print(roi);
roiManager("Select", roi);
getSelectionBounds(xroi,yroi,wroi,hroi);
makeRectangle(xroi-1,yroi-1,wroi+2,hroi+2);
getRawStatistics(nPixels, mean, min, max);
run("Measure");
MaxSignal=getResult("Max");
MinSignal=getResult("Min");
Contrast=(MaxSignal-MinSignal)/(MaxSignal+MinSignal);
return Contrast;

}
	function contrast_calculation(img, roi) {
//waitForUser("3");
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
Contrast=(MaxSignal-MinSignal)/(MaxSignal+MinSignal);
return Contrast;

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
macro "calibation"{
showMessage("You are running FISH image threshold correction test");
waitForUser("Please drag and drop the 3 channel FISH image to be tested");

waitForUser("Please select a region of interest");
run("Duplicate...", "title=originImage duplicate");
run("Set Scale...", "distance=1 known="+pixelSize+" unit=um global");
showMessage("Where to store the correction factors?");

logRecord = File.open(""); // display file open dialog

//showMessage("Where to store the cluster size and ingrated intensity?");

//clusterRecord = File.open(""); // display file open dialog
redCountThreshold=4;
wsStatus = true;
filterDAPI = true;
Gblur =false;
gotIt=false;
dapiChannel = 3 ; 
greenDotChannel = 2 ; 
redDotChannel = 1 ;
gaussianBlur = 1;
redNoise = 30; 
greenNoise = 30 ; 
blueNoise= 50 ; 
roiManager("Reset");
redDotTotal=0;
greenDotTotal=0;
factorBlueNonSpecific=1;
factorRedNonSpecific=1;
factorBlue=1;
factorRed=1;
factorAutofluo=1;
factorGreen=1;
sumlocalMax=0;
calibrationFactor=1;
redDotLimit=15;
maxNucleiSize=2000;
maxGreenDotArea=25;
calibrationHappy=false;
setBatchMode(false);
title = getTitle();
getDimensions(width, height, channels, slices, frames);
Stack.setChannel(redDotChannel);
run("Red");
Stack.setChannel(dapiChannel);
run("Blue");
Stack.setChannel(greenDotChannel);
run("Green");
//Create a Blur version of the image
run("Duplicate...", "title=gBlur duplicate");
	if (Gblur) {
		run("Gaussian Blur...", "sigma="+gaussianBlur+" stack");
	}
run("Set Measurements...", "area mean standard modal min integrated median area_fraction display redirect=None decimal=6");
//substract background with rolling ball filter
Stack.setChannel(greenDotChannel); //major change
resetMinAndMax();
run("Duplicate...", "title=DAPInonSpecific");
	selectImage("gBlur");
Stack.setChannel(redDotChannel);
run("Subtract Background...", "rolling=30 slice");
run("Duplicate...", "title=redBallRolled");

//Mask DAPI using the red channel
	run("Color Balance...");
	resetMinAndMax();
//Mask for autofluorescence red for green signal

	selectImage("originImage");
	run("Select None");
	Stack.setChannel(redDotChannel);
	run("Color Balance...");
	resetMinAndMax();
	
		run("Duplicate...", "title=membrane");
		
		run("Duplicate...", "title=redContrast");
	run("Duplicate...", "title=redDotAutoFluo");

	Step4_OK=false;
	while (Step4_OK==false) {
	Dialog.create("Factor for green autofluorescence");
	Dialog.addNumber("factorGreenAutofluo",factorAutofluo)
	Dialog.show();
	factorAutofluo = Dialog.getNumber();
	
	
	selectImage("redDotAutoFluo");
	run("Duplicate...", "title=redDotAutoFluo2");
	//start threshold

	setAutoThreshold("Huang dark");
    getThreshold(lower,upper);
    setThreshold(lower*factorAutofluo,upper);
        
	setOption("BlackBackground", true);

   	//finish threshold 
	Step4_OK=getBoolean("Are you happy with the thresholding?");

		if (Step4_OK==false) 	{
			selectImage("redDotAutoFluo2");
		run("Close");
}

else{
	
	selectImage("redDotAutoFluo");
	run("Close");
	selectImage("redDotAutoFluo2");
	rename("redDotAutoFluo");
}
	}
		selectImage("redDotAutoFluo");
	run("Make Binary");
	run("Invert");
	run("Divide...", "value=255.000");

	
	selectImage("redContrast");	
	run("Unsharp Mask...", "radius="+sharpen_radius+" mask="+sharpen_weight);
Step1_OK=false;
while (Step1_OK==false) {
Dialog.create("Please adjust blue autofluorescence with the green channel");
Dialog.addNumber("factorBlueNonSpecific",factorBlueNonSpecific)
Dialog.show();
factorBlueNonSpecific = Dialog.getNumber();


selectImage("DAPInonSpecific");
run("Duplicate...", "title=DAPInonSpecific2");
//start threshold
setAutoThreshold("Yen dark");
getThreshold(lower,upper);
setThreshold(lower*factorBlueNonSpecific,upper);
setOption("BlackBackground", true);
//finish threshold 
waitForUser("Check the threshold");
Step1_OK=getBoolean("Are you happy with the thresholding? dont scare about the green dot detected");

	if (Step1_OK==false) 	{
		selectImage("DAPInonSpecific2");
	run("Close");
}
}
//waitForUser("Check");
selectImage("DAPInonSpecific2");
run("Convert to Mask");
//waitForUser("Check");
selectImage("DAPInonSpecific");
run("Close");

selectImage("DAPInonSpecific2");
rename("DAPInonSpecific");
selectImage("DAPInonSpecific");
run("Invert");
	run("Create Selection");
	run("Clear Results");
	run("Measure");
	greenFluoArea=getResult("Area");
	run("Clear Results");

		getDimensions(width, height, channels, slices, frames);
	SignalProportion= greenFluoArea/(0.104*0.104*width*height);
//			waitForUser(""+SignalProportion+","+greenFluoArea+","+width+","+height);
	/*	
run("Extend Image Borders", "left=2 right=2 top=2 bottom=2 fill=White");
run("Dilate");
run("Dilate");
run("Erode");
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
*/
run("Divide...", "value=255.000");
//
//waitForUser("DAPInonSpecific after");
selectImage("gBlur");
Stack.setChannel(greenDotChannel);
run("Select None");
run("Subtract Background...", "rolling=15 slice");
//Mask red channel by creating redDotMask from green channel 
run("Duplicate...", "title=redDotMask");
run("Color Balance...");
	resetMinAndMax();
	Step6_OK=false;
	while (Step6_OK==false) {
	Dialog.create("Please adjust the factor for red channel mask from green channel");
	Dialog.addNumber("factorRedNonSpecific",factorRedNonSpecific)
	Dialog.show();
	factorRedNonSpecific = Dialog.getNumber();
	selectImage("redDotMask");
	run("Duplicate...", "title=redDotMask2");

setAutoThreshold("Otsu dark");
getThreshold(lower,upper);
setThreshold(lower*factorRedNonSpecific,upper);
   	setOption("BlackBackground", true);
   	//finish threshold 
   	waitForUser("Check the threshold. Click the thresholded image before clicking OK");
	Step6_OK=getBoolean("Are you happy with the thresholding?");

		if (Step6_OK==false) 	{
			selectImage("redDotMask2");
		run("Close");
}
else{
	selectImage("redDotMask");
	run("Close");
selectImage("redDotMask2");
rename("redDotMask");
}
}
	selectImage("redDotMask");
//	waitForUser("check redDotMask");
//Create a 3 channel image composing c
//waitForUser("");
run("Convert to Mask");
run("Invert");
run("Divide...", "value=255.000");

selectImage("gBlur");
run("Duplicate...", "duplicate");
run("Split Channels");
selectImage("C1-gBlur-1");
run("32-bit");
selectImage("C2-gBlur-1");
run("32-bit");
imageCalculator("Multiply create 32-bit stack", "C3-gBlur-1" ,"redDotMask");
imageCalculator("Multiply create 32-bit stack", "C2-gBlur-1" ,"redDotAutoFluo");
imageCalculator("Multiply create 32-bit stack", "redBallRolled" ,"redDotMask");
selectImage("Result of redBallRolled");
rename("redBallRolledWithoutAutofluo");
selectImage("redBallRolled");
//close();

run("Merge Channels...", "c1=C1-gBlur-1 c2=[Result of C2-gBlur-1] c3=[Result of C3-gBlur-1] create keep");
rename("gBlur2");
run("Stack to RGB");
rename("finalOutline");
			
//imageCalculator("Multiply create 32-bit stack", "Result of C2-gBlur-1" ,"redDotMask");
//rename("membrane");
//run("Gaussian Blur...", "sigma="+gaussianBlur*10);
//run("Find Edges");

//run("Invert");

//run("Divide...", "value=10");

selectImage(title);
Stack.setChannel(dapiChannel);
run("Duplicate...", "title=dapiMask");

selectImage("Result of C2-gBlur-1");
close();

//	selectImage("C3-gBlur-1");
//	run("Duplicate...", "title=enhancedNucleiRecognitionMask");
//	run("Gaussian Blur...", "sigma="+gaussianBlur*2);

	if (filterDAPI) {
	imageCalculator("Multiply create 32-bit stack", "dapiMask" ,"DAPInonSpecific");
	rename("dapiMaskFiltered");
	}

//	waitForUser("Check");
	selectImage("originImage");
	Stack.setChannel(redDotChannel);
	run("Duplicate...", "title=redDotChannelForDAPIMask");
//		waitForUser("Check");
	imageCalculator("Multiply create 32-bit stack", "redDotChannelForDAPIMask" ,"redDotAutoFluo");
//			waitForUser("Check");
	selectImage("Result of redDotChannelForDAPIMask");
	rename("redBlurForDAPIMask");
	run("Gaussian Blur...", "sigma="+gaussianBlur);
	selectImage("redDotChannelForDAPIMask");
//	close();	
	imageCalculator("Multiply create 32-bit stack", "dapiMaskFiltered" ,"redBlurForDAPIMask");



//		waitForUser("Check");
	selectImage("Result of dapiMaskFiltered");
	rename("BlueRedCombined");
	run("Gaussian Blur...", "sigma="+gaussianBlur*2);
	selectImage("redBlurForDAPIMask");
//	close();
	selectImage("BlueRedCombined");
	factorBlueRedMax=1;

	Step2_OK=false;
	
	while (Step2_OK==false) {
			selectImage("finalOutline");
		
			selectImage("BlueRedCombined");

	run("Color Balance...");
	resetMinAndMax();
	run("Duplicate...", "title=dapiMaskFiltered2");
	//start threshold

	setAutoThreshold("MinError dark");
		getThreshold(lower1,upper1);
		run("Threshold...");
	waitForUser("Please adjust the factor for selecting nuclei without taking autofluorescence");
	getThreshold(lower2,upper2);
	factorBlue=lower2/lower1;
	blueRedMax=upper2*1.2;

			

//	setOption("BlackBackground", true);
//finish threshold 
Step2_OK=getBoolean("Click OK");


		if (Step2_OK==false) 	{
			selectImage("dapiMaskFiltered2");
		run("Close");
}
else{
		selectImage("BlueRedCombined");
	run("Close");
	selectImage("dapiMaskFiltered2");
//waitForUser("check dapiMaskFiltered2");
	rename("dapiMaskFiltered");
}
}
waitForUser("check dapiMaskFiltered-1");
				
run("Convert to Mask");
waitForUser("check dapiMaskFiltered-2");
	if (wsStatus){
		run("Watershed");
	}
waitForUser("check dapiMaskFiltered-3");
	run("Fill Holes");
run("ROI Manager...", "");
//waitForUser("check");
//un("Extend Image Borders", "left=1 right=1 top=1 bottom=1 fill=White");
//run("Erode");
//run("Extend Image Borders", "left=-1 right=-1 top=-1 bottom=-1 fill=White");
//waitForUser("check");
roiBeforeGrossDetection=roiManager("Count");
//	totalNucleiBeforeDeclustering = roiAfterGrossDetection-roiBeforeGrossDetection;
run("Analyze Particles...", "size=30-30000 pixel circularity=0-1.00 clear add");
roiAfterGrossDetection=roiManager("Count");
//totalNucleiBeforeDeclustering = roiAfterGrossDetection-roiBeforeGrossDetection;

selectImage("dapiMaskFiltered-ext");
close();
selectImage("dapiMaskFiltered-ext-ext");
close();
//Dialog.create("Is it a highly amplified case?");
//Dialog.addCheckbox("highlyAmplified", true);
//Dialog.show();
//highlyAmplified=Dialog.getCheckbox();			
//Finer nuclei selection			


//			selectImage("redDotChannelForDAPIMask");
//			run("8-bit");
//			run("Invert");
			

			Dialog.create("Please adjust the factor for selecting the blue noise for nuclei segmentation");
	Dialog.addNumber("blueNoise",blueNoise)
	Dialog.show();
	blueNoise = Dialog.getNumber();
	selectImage("originImage");
	Stack.setChannel(dapiChannel);
	run("Duplicate...", "title=dapiMax");
	
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
				
				run("Thresholded Blur", "radius=4 threshold=20 softness=5 strength=2");

//				run("Find Maxima...", "noise=" + blueNoise+ " output=[Maxima Within Tolerance]");
//	close("membrane");
//				selectImage("Result of redDotChannelForDAPIMask");
//				rename("membrane");

	
//	waitForUser("Threshold find edges");
	//Finer nuclei selection


//				imageCalculator("Multiply create 32-bit stack", "dapiMaxMask" ,"dapiMax");
				selectImage("dapiMax");
				run("8-bit");
				newImage("dapiMaxMask", "8-bit black", width,height , 1);
//		waitForUser("0 1 index2 "+ index2+"roiAfterGrossDetection"+roiAfterGrossDetection+ "ind "+ind);
				roiManager("Deselect");
				roiManager("Select",selectionArray);
//				waitForUser("Combine");
selectionArrayLength=selectionArray.length; 
if (selectionArrayLength>1) {				roiManager("OR");		}

//		waitForUser("0 2");
//				setBatchMode("show");

				run("Fill");
				run("Select All");
				run("Divide...", "value=255.000");
				rename("dapiMaxMask");
selectImage("dapiMax");
run("Invert");

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

//				waitForUser("Check dapiMaxMasked");
				run("Thresholded Blur", "radius=4 threshold=20 softness=5 strength=1");
//							run("Find Maxima...", "noise=" + blueNoise+ " output=[Maxima Within Tolerance]");
		

//				run("Enhance Contrast...", "saturated=0.3 normalize");
//				setBatchMode("show");
				selectImage("membrane");				
//				run("Enhance Contrast...", "saturated=0.3 normalize");

				run("Morphological Filters", "operation=Opening element=Disk radius=10");
				run("Morphological Filters", "operation=Gradient element=Disk radius=2");	
				run("Invert");
				imageCalculator("Multiply create 32-bit stack", "membrane-Opening-Gradient" ,"dapiMaxMasked");
				selectImage("Result of membrane-Opening-Gradient");
				rename("membraneMasked");
//				waitForUser("Check membraneMasked");

				run("8-bit");
//				run("Invert");	

					setBatchMode("show");
				
				run("Thresholded Blur", "radius=2 threshold=15 softness=5 strength=2");		
	
//					setBatchMode("show");

				selectImage("membraneMasked");					

//				run("Multiply...", "value=0.8");
//				imageCalculator("Multiply create 32-bit stack", "dapiMaxMasked" ,"membraneMasked");
//				run("Thresholded Blur", "radius=4 threshold=20 softness=5 strength=5");		

//				selectImage("Result of dapiMaxMasked");
//				rename("dapiMaxMaskedEnhanced");	
//				run("8-bit");
	
				run("Find Maxima...", "noise=" + blueNoise+ " output=[Segmented Particles]");
				rename("dapiMaxMaskedSegmented");
				run("Find Maxima...", "noise=" + blueNoise+ " output=[Maxima Within Tolerance]");
				rename("dapiMaxMaskedSegmentedMaxima");
//							waitForUser(selectionArray[0]);	
				roiManager("Select",selectionArray);
//				waitForUser("Combine");

if (selectionArrayLength>1) {				roiManager("OR");		}

				totalNucleiBeforeDeclustering=roiManager("Count");
//									setBatchMode("show");
		run("Analyze Particles...", "size=25-"+maxNucleiSize+" pixel circularity=0-1.00 add");
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
				run("Invert");
//				if (!(roiAfterGrossDetection==ROIcontrol1)) 
//				{
//					roiAfterGrossDetection=ROIcontrol1;
//					waitForUser("Check problem why roiAfterGrossDetection not =ROIcontrol1");
//				}
				
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
	selectImage("dapiMaskFiltered");
	close();
	selectImage("DAPInonSpecific");
	close();
	/*
		for (index = 0 ; index < totalNucleiBeforeDeclustering ;index++){
			setBatchMode(false);
			highlyAmplified=false;
						selectImage("dapiMax");
				roiManager("Select", index);
				run("Create Mask");
				rename("dapiMaxMask");
				run("Divide...", "value=255.000");
	//imageCalculator("Multiply create 32-bit stack", "dapiMaxMask" ,"enhancedNucleiRecognitionMask");
	//	selectImage("Result of dapiMaxMask");
	//		rename("enhancedNucleiRecognitionMaskMasked");
	//			run("8-bit");		
				imageCalculator("Multiply create 32-bit stack", "dapiMaxMask" ,"dapiMax");
				selectImage("Result of dapiMaxMask");
				rename("dapiMaxMasked");
				run("8-bit");
				roiManager("Select", index);
				run("Invert");
				run("Find Edges");
				run("Invert");			
				run("Thresholded Blur", "radius=4 threshold=20 softness=5 strength=5");	
						
				imageCalculator("Multiply create 32-bit stack", "membrane" ,"dapiMaxMask");
				selectImage("Result of membrane");
				rename("membraneMasked");
				run("8-bit");
				roiManager("Select", index);
				run("Invert");			
				run("Thresholded Blur", "radius=4 threshold=20 softness=5 strength=5");	
				
//				imageCalculator("Add create 32-bit", "dapiMaxMasked","enhancedNucleiRecognitionMaskMasked");
//					selectImage("Result of dapiMaxMasked");			
//			waitForUser("process multiplification");
//				rename("dapiMaxMaskedEnhanced");
//				roiManager("Select", index);		
//				run("Invert");

//			waitForUser("check Multiply");
				imageCalculator("Multiply create 32-bit stack", "dapiMaxMasked" ,"membraneMasked");	
				selectImage("Result of dapiMaxMasked");
				run("8-bit");
//					waitForUser("check Multiply");
					roiManager("Select", index);		
			

					
//			roiManager("Select", index);
//			run("Create Mask");
//			rename("dapiMaxMask");
//			run("Divide...", "value=255.000");
//			imageCalculator("Multiply create 32-bit stack", "dapiMaxMask" ,"dapiMax");
//			rename("dapiMaxMasked");
//			roiManager("Select", index);		
//			run("8-bit");
//			run("Invert");
//			waitForUser("Find Edges");
//			run("Find Edges");
//			run("Invert");
//			run("Thresholded Blur", "radius=2 threshold=20 softness=1 strength=2");
//			run("Find Maxima...", "noise=30 output=[Segmented Particles] exclude");
//			run("Gaussian Blur...", "sigma="+gaussianBlur);
//			waitForUser("before watershed");
//			run("Classic Watershed", "input=dapiMaxMasked mask=dapiMaxMask use min=0 max=100");
//			rename("DAPIgrayscaleDeclumped");
			
			/*
			run("Threshold...");
					setAutoThreshold("Huang dark");
					setOption("BlackBackground", true);
					run("Convert to Mask");
					selectImage("RedDotClusterDeclumped");
					ROIBeforeRedRegionIdentification =roiManager("Count");
					run("Analyze Particles...", "size=1-20 add");
					redDotIdentifiedRegionNumber=roiManager("Count")-ROIBeforeRedRegionIdentification;
			
//			roiManager("Select", index);
//			waitForUser("Segmented Particles");
			run("Find Maxima...", "noise="+blueNoise+" output=[Segmented Particles]");

			rename("dapiMaskSegmented");
//			waitForUser("after segmentation");
			run("Find Maxima...", "noise="+blueNoise+" output=[Maxima Within Tolerance]");
			rename("dapiMaskSegmentedMaxima");
			roiManager("Select", index);
			ROIcontrol=roiManager("Count");
//			waitForUser("before analyze particle");
			run("Analyze Particles...", "size=30-"+maxNucleiSize+" pixel circularity=0-1.00 add");

				if (roiManager("Count") == ROIcontrol){
				roiManager("Select", index);
				roiManager("Add");
				}
			selectImage("membraneMasked");
			close();
//			selectImage("dapiMaxMaskedEnhanced");
//			close();
			selectImage("Result of dapiMaxMasked");
			close();
			selectImage("dapiMaxMasked");
			close();		
			selectImage("dapiMaxMask");
			close();
			selectImage("dapiMaskSegmented");
			close();		
			selectImage("dapiMaskSegmentedMaxima");
			close();
//			selectImage("enhancedNucleiRecognitionMaskMasked");
//			close();
		}
	}

print("Nuclei index ; Red Spot Number ; Green Spot Number ; Ratio red/green");
				setBatchMode(false);
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
selectImage("dapiMaskFiltered");
close();
selectImage("DAPInonSpecific");
close();
*/
totalNucleiAfterDeclustering = roiManager("Count");

totalNuclei=totalNucleiAfterDeclustering-totalNucleiBeforeDeclustering;
happy=false;
jump=false;
processAll=false;

for (index = 0 ; index < totalNuclei;index++){
	redDotNumber=0;
	greenDotNumber=0;
	redDotArea=0;
	highlyAmplified=false;
	selectImage("originImage");
	roiManager("Select", index+totalNucleiBeforeDeclustering);
	Step5_OK=false;
	Step8_OK=false;
		if (processAll==false) {waitForUser("Check the nucleus selected");
			jump=getBoolean("Do you want to jump to next nucleus?");}
		//choose the nucleus for adjusting the autofluo
 if ((jump==0)||(processAll==true)) {


	newImage("Nuclei-"+(index+1), "8-bit black", width,height , 1);
	roiManager("Select", index+totalNucleiBeforeDeclustering);
	roiManager("Rename", "Nuclei-"+(index+1));
	run("Fill");
	run("Select All");
//	run("Duplicate...", "title=Background_of_nuclei-"+(index+1));
// 	waitForUser("check background of nuclei");
//	selectImage("Nuclei-"+(index+1));
//	run("Select All");
	run("Divide...", "value=255.000");
	selectImage("finalOutline");
	roiManager("Select", index+totalNucleiBeforeDeclustering);
	run("Set Drawing Color...");
	setForegroundColor(0, 0, 255);
//	roiManager("Deselect");
	roiManager("Draw");
	setForegroundColor(255, 255, 255);
	imageCalculator("Multiply create 32-bit stack", "gBlur2" ,"Nuclei-"+(index+1));
//	run("Gaussian Blur...", "sigma="+gaussianBlur);
	rename("Nuclei-"+(index+1)+"mesure");
////////////////////////////////////////////////////////////////////////////////Detection of green signal
	selectImage("Nuclei-"+(index+1)+"mesure");
	Stack.setChannel(greenDotChannel);
	run("Duplicate...", "title=greenDotThresholdedMasked");
	
//	imageCalculator("Multiply create 32-bit stack", "redDotAutoFluo" ,"greenDotThresholded");
//	rename("greenDotThresholdedMasked");

							while ((Step5_OK==false)&&(happy==false)) {
								Dialog.create("Please adjust the factor for thresholding green channel");
								Dialog.addNumber("factorGreen",factorGreen)
								Dialog.show();
								factorGreen = Dialog.getNumber();
								selectImage("greenDotThresholdedMasked");
								run("Duplicate...", "title=greenDotThresholdedMasked2");
								//start threshold
								roiManager("Select", index+totalNucleiBeforeDeclustering);	
								setAutoThreshold("Yen dark");
							    getThreshold(lower,upper);
							    setThreshold(lower*factorGreen,upper);
							    
								setOption("BlackBackground", true);
								
							
							   	//finish threshold 
							   	waitForUser("Check the threshold of green signal");
								Step5_OK=getBoolean("Are you happy with the thresholding?");
							
									if (Step5_OK==false) 	{
										selectImage("greenDotThresholdedMasked2");
									run("Close");
							}
							
							else{				
								selectImage("greenDotThresholdedMasked");
								run("Close");
							selectImage("greenDotThresholdedMasked2");
							rename("greenDotThresholdedMasked");
							rename("greenDotWithoutAutoFluo");
							run("Convert to Mask");
							}
								}
				if ((Step5_OK==false)&&(happy==true)) {
				selectImage("greenDotThresholdedMasked");
				roiManager("Select", index+totalNucleiBeforeDeclustering); //Very important for local threshold method
				setAutoThreshold("Yen dark");
			    getThreshold(lower,upper);
			    setThreshold(lower*factorGreen,upper);
			   	setOption("BlackBackground", true);
			   	rename("greenDotWithoutAutoFluo");
				}
		run("8-bit");
		run("Convert to Mask");
		wsStatusGreen = false;
			if (wsStatusGreen){
			run("Watershed");
		}

	run("Select None");
	run("Duplicate...", "title=greenSignalArea");
//	run("Dilate");															//Dilate in order to increase the size of recognized area of green, incase it is autofluorescence, it will be bigger and easer to remove
	ROIbeforeRedDetect=roiManager("Count");
		greenDotNumber=0;
	    ROIbeforeGreenRegionDetect=roiManager("Count");
		run("Analyze Particles...", "size=1-1500 circularity=0-1.00 pixel add");

		greenRegionNumber=roiManager("Count")-ROIbeforeGreenRegionDetect;
	

//Calculation of background intensity
//	waitForUser("After analyze particle");
	selectImage("greenSignalArea");
	run("Invert");
	
	imageCalculator("Multiply create 32-bit stack", "greenSignalArea" ,"Nuclei-"+(index+1)); //for avoiding actefact due to autofluorescence removal, use redBallRolled instead of redBallRolledWithoutAuto otherwise the area around the removal   
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
	
	if (greenBackgroundArea< 10000) {roiManager("Add");} 						//If green background Area is bigger than a nucleus, it means that it is no background detected then the backgroud is in fact the detected "signal" area
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
	greenBackgroundMean=getResult("Mean");
	run("Clear Results");
	minGreenDotIntensity=greenBackgroundMean; 
		
			//	waitForUser("after threshold");
				
				if (greenRegionNumber>0) 
					{for (j= 0; j<greenRegionNumber; j++) {
					selectImage("originImage");
					Stack.setChannel(greenDotChannel);
					roiManager("Select", (roiManager("Count")-greenRegionNumber+j-greenDotNumber));
					roiManager("Rename", "Nuclei-"+(index+1)+"_greenSpotRegions"+j+1);
																											//Change here
	
					while ((Step8_OK==false)&&(happy==false)) {
					Dialog.create("Please adjust the sentivity of green dot detection");
					Dialog.addNumber("greenNoise",greenNoise)
					Dialog.show();
					greenNoise = Dialog.getNumber();
					selectImage("gBlur");
					Stack.setChannel(greenDotChannel);
					roiManager("Select", (ROIbeforeGreenRegionDetect+j));
					//start threshold
//					waitForUser("click OK");
					run("Find Maxima...", "noise="+greenNoise+" output=[Single Points]");	
					rename("greenMaximaDetected");
//				   	waitForUser("click OK");
				   	//finish threshold 
				   	waitForUser("Check the dots selected");
					Step8_OK=getBoolean("Are you happy with the finding?");
						if (Step8_OK==false) 	{
						selectImage("greenMaximaDetected");
						run("Close");
				}
				}
	
		if ((Step8_OK==true)||(happy==true)) {
					selectImage("gBlur");
					Stack.setChannel(greenDotChannel);
					roiManager("Select", (ROIbeforeGreenRegionDetect+j));
					roiManager("Rename", "Nuclei-"+(index+1)+"_greenSpotRegions"+j+1);
					run("Clear Results");
					run("Find Maxima...", "noise="+greenNoise+" output=[Maxima Within Tolerance]");
					rename("greenMaximaDetected");
					roiManager("Select", (ROIbeforeGreenRegionDetect+j));	
					run("Measure");
					greenClusterArea=getResult("IntDen");
					greenClusterArea=greenClusterArea/255;
					run("Clear Results");
//					close();
//					selectImage("gBlur");
//					waitForUser("check");
//					Stack.setChannel(greenDotChannel);
//					roiManager("Select", (ROIbeforeGreenRegionDetect+j));
//					run("Find Maxima...", "noise="+greenNoise+" output=[Single Points]");	
//					rename("greenMaximaDetected");
//		waitForUser("redDotCluster");
	   	}
	   	
//					run("Find Maxima...", "noise="+greenNoise+" output=[Maxima Within Tolerance]"); //there is a space before the output
				//	rename("MaxGreenPoint");
					ROIbeforeGreenDotDetection=roiManager("Count");
			//		waitForUser("");			
				//	selectImage("MaxGreenPoint");
					run("Analyze Particles...", "size=0-10 pixel display add");
					greenDotNumber=roiManager("Count")-ROIbeforeGreenDotDetection;
			//		waitForUser("");
					close();
					numberGreenDot=0;							//Differ to greenDotNumber because the latter includes autofluorescent
					if (greenDotNumber>0) {
						for (y=0; y<greenDotNumber;y++){
						run("Clear Results");		
						selectImage("originImage");
						Stack.setChannel(redDotChannel);
						roiManager("Select", (ROIbeforeGreenDotDetection+y));												
						run("Measure");					
						redAutoFluo=getResult("Median");			//add here condition to improve green recognition
						greenDotArea=getResult("Area");	
						run("Clear Results");	
						greenDotArea=greenDotArea/(pixelSize*pixelSize);
						selectImage("originImage");				
						roiManager("Select", (ROIbeforeGreenDotDetection+y));
						
						getSelectionBounds(GCx,GCy,GCw,GCh);
						if ((GCw+GCh)<4) makeRectangle(GCx-1, GCy-1, GCw+2, GCh+2);
						run("Find Maxima...", "noise="+redNoise/4+" output=Count");
						NoRedNonSpecific=getResult("Count");
						if ((NoRedNonSpecific==0)&&(redAutoFluo<redSignalAverage*2)&&(greenDotArea<maxGreenDotArea)){
							run("Clear Results");
							selectImage("originImage");
							Stack.setChannel(greenDotChannel);
							roiManager("Select", (ROIbeforeGreenDotDetection+y));
							run("Measure");
							greenDotIntensity=getResult("Mean");
							run("Clear Results");
									if (greenDotIntensity>minGreenDotIntensity) {				//Version V5 I adjust the green dot to only specific greens are detected
//										waitForUser(minGreenDotIntensity);
//										waitForUser(greenDotIntensity);
										minGreenDotIntensity=minGreenDotIntensity+(greenDotIntensity-minGreenDotIntensity)/5;
									}
									else {
										minGreenDotIntensity=minGreenDotIntensity-(minGreenDotIntensity-greenDotIntensity)/5;
									}
								
							selectImage("finalOutline");
						roiManager("Select", (ROIbeforeGreenDotDetection+y))	;
	
						roiManager("Rename", "Nuclei-"+(index+1)+"_greenSpots_detected"+y+1);				//check why some greenSpots detected are named region and why some green dots were not detected
						run("Set Drawing Color...");
						setForegroundColor(0, 255, 0);
			//			roiManager("Deselect");
						roiManager("Draw");
						setForegroundColor(255, 255, 255);
						numberGreenDot++;									
							}
						}
					}
					}
				} //end detection green dots
//	waitForUser("check redBallRolled Nuclei-");

//////////////////////////////////////////////
	imageCalculator("Multiply create 32-bit stack", "redBallRolledWithoutAutofluo" ,"Nuclei-"+(index+1)); //for avoiding actefact due to autofluorescence removal, use redBallRolled instead of redBallRolledWithoutAuto otherwise the area around the removal   
	selectImage("Result of redBallRolledWithoutAutofluo");
	rename("redDotThresholded");//important change
	run("Color Balance...");
	resetMinAndMax();

	Step3_OK=false;
				while ((Step3_OK==false)&&(happy==false)) {
				Dialog.create("Please adjust the factor for threshold the red channel");
				Dialog.addNumber("factorRed",factorRed)																		//if put the threshold too high ROI can be decreased to only one pixel and no maximum can be detected
				Dialog.show();
				factorRed = Dialog.getNumber();
				
				
				selectImage("redDotThresholded");
				run("Duplicate...", "title=redDotThresholded2");
				//start threshold
				roiManager("Select", index+totalNucleiBeforeDeclustering);
				setAutoThreshold("Yen dark");
			    getThreshold(lower,upper);
			    setThreshold(lower*factorRed,upper);
			   	setOption("BlackBackground", true);
			//   	waitForUser("click OK");
			   	//finish threshold 
			   	waitForUser("Check the thresholded image obtained");
				Step3_OK=getBoolean("Are you happy with the thresholding?");
			
					if (Step3_OK==false) 	{
						selectImage("redDotThresholded2");
					run("Close");
			}
			else{
				selectImage("redDotThresholded");
				run("Close");
			selectImage("redDotThresholded2");
			rename("redDotThresholded");
//			run("Select None");
//			run("Duplicate...", "title=redBackground");
//			selectImage("redDotThresholded");
			}
			}
//waitForUser("click OK");
	if ((Step3_OK==false)&&(happy==true)) {
	selectImage("redDotThresholded");
//	run("Select None");
//	run("Duplicate...", "title=redBackground");
//	selectImage("redDotThresholded");
	roiManager("Select", index+totalNucleiBeforeDeclustering);
//	waitForUser("");
	setAutoThreshold("Yen dark");
	 getThreshold(lower,upper);
    setThreshold(lower*factorRed,upper);
     setOption("BlackBackground", true);
//	waitForUser("click OK");
   	}

run("Convert to Mask");
	run("Select None");
	run("Duplicate...", "title=redSignalArea");
	selectImage("redDotThresholded");
	wsStatusRed = true;
		if (wsStatusRed){
		run("Watershed");
	}
//run("Dilate");

	ROIbeforeRedDetect=roiManager("Count");

	run("Analyze Particles...", "size=1-2500 pixel circularity=0.10-1.00 display exclude add");
//waitForUser("Check red spot region");

	redRegionNumber=roiManager("Count")-ROIbeforeRedDetect;
		selectImage("originImage");
		Stack.setChannel(redDotChannel);	
	roiManager("Select", index+totalNucleiBeforeDeclustering);
//		waitForUser(" check red spot region");
		run("Find Maxima...", "noise="+redNoise*3+" output=[Maxima Within Tolerance]");		
		run("Clear Results");
		run("Analyze Particles...", "size=1-10 pixel summarize");
		IJ.renameResults("Results");
		 if (nResults>0) {
		redDotFirstScan=getResult("Count");}
		else redDotFirstScan=0;

		run("Clear Results");
		close();
		if(redDotFirstScan>redCountThreshold){highlyAmplified=true;}
		ROIbeforeBackground=roiManager("Count");
	selectImage("redSignalArea");
	run("Invert");
	
	imageCalculator("Multiply create 32-bit stack", "redSignalArea" ,"Nuclei-"+(index+1)); //for avoiding actefact due to autofluorescence removal, use redBallRolled instead of redBallRolledWithoutAuto otherwise the area around the removal   
	selectImage("Result of redSignalArea");
	rename("redBackground");
	
	run("Select None");
	run("8-bit");
	run("Invert");
	run("Create Selection");

	run("Clear Results");
	run("Measure");
	redBackgroundArea=getResult("Area");
	run("Clear Results");	
	if (redBackgroundArea< 10000) {roiManager("Add");} 	

	selectImage("originImage");
	Stack.setChannel(redDotChannel);	
	roiManager("Select", roiManager("count")-1);
//		waitForUser("Check area of background");
	run("Measure");
	redBackgroundMean=getResult("Mean");
	run("Clear Results");
//	roiManager("Select", roiManager("count")-1); //Take the background selection
//	roiManager("Delete");			
	selectImage("redSignalArea");
	close();
	selectImage("redBackground");
	close();

	print(redBackgroundMean+":background Intensity");
//Calculation of background intensity
//	waitForUser("After analyze particle");
//	run("Duplicate...", "title=redChannelBackground"+(index+1));
//	waitForUser("redChannelBackground??");
//	selectImage("redBackground");
//	setAutoThreshold("Huang dark");
//	run("Convert to Mask");
//	roiManager("Select", totalNucleiBeforeDeclustering+index);
//	run("Invert");
//	run("Select None");
//	run("Invert");
//	run("Create Selection");
//	roiManager("Add");
//	waitForUser("background Selection");
//	selectImage("originImage");
//	Stack.setChannel(redDotChannel);	
//	roiManager("Select", roiManager("count")-1);
//	run("Measure");
//	backgroundIntensity=getResult("Mean");
//	selectImage("redChannelBackground"+(index+1));
//	run("Close");
//	run("Clear Results");
//	roiManager("Select", roiManager("count")-1); //Take the background selection
//	roiManager("Delete");			
//	selectImage("redBackground");
//	close();
//	roiManager("Select", ROIbeforeBackground+1);
//	waitForUser("Check ROI");
//	print(backgroundIntensity+":background Intensity");
//	selectImage("redBackground");
//	close();
	imageCalculator("Multiply create 32-bit stack", "redBallRolled" ,"Nuclei-"+(index+1)); //for avoiding actefact due to autofluorescence removal, use redBallRolled instead of redBallRolledWithoutAuto otherwise the area around the removal   
	selectImage("Result of redBallRolled");
	rename("redBallRolled Nuclei-"+(index+1));//important change
//	waitForUser("Analyze  Nuclei"+(index+1));
	Step7_OK=false;
	Step5_OK=false;
	Step8_OK=false;
	p=0;
	if (redRegionNumber>0) {
	for (i= 0; i<redRegionNumber; i++) {
					MeanAreaIntensityNonAmplified=4294967296;
//Define the local maxima and image segmentation within the region of interest 
					newImage("Nuclei-"+(index+1)+"_redSpots_region"+(i+1), "8-bit black", width,height , 1);
					roiManager("Select", (ROIbeforeRedDetect+i));
					run("Fill");
					run("Select All");
					run("Divide...", "value=255.000");
					imageCalculator("Multiply create 32-bit stack", "redBallRolled Nuclei-"+(index+1),"Nuclei-"+(index+1)+"_redSpots_region"+(i+1));
					rename("redDotClusters in Nuclei-"+(index+1));
//					waitForUser("check cluster");
					roiManager("Select", (ROIbeforeRedDetect+i));
///Red noise selection
					while ((Step7_OK==false)&&(happy==false)) {
					Dialog.create("Please adjust the sentivity of detection");
					Dialog.addNumber("redNoise",redNoise)
					Dialog.show();
					redNoise = Dialog.getNumber();
					
			//start threshold
					if (highlyAmplified) {		
					run("Clear Results");
					selectImage("redDotClusters in Nuclei-"+(index+1));
					roiManager("Select", (ROIbeforeRedDetect+i));
					run("Find Maxima...", "noise="+redNoise+" output=[Point Selection]");
//					waitForUser("redSignalMeanBeforeMeasurement");
					run("Measure");
					run("Summarize");
//					waitForUser("nResults:"+nResults);
					if (nResults>4) {
					redSignalMean=getResult("Mean",nResults-4);
//					waitForUser("Value of Mean:"+redSignalMean);
					}
					else {
						redSignalMean=getResult("Mean");
					}
//					waitForUser("redSignalMean:"+redSignalMean);
					selectImage("redDotClusters in Nuclei-"+(index+1)); //or redBallRolled Nuclei-"+(index+1)
					roiManager("Select", (ROIbeforeRedDetect+i));
						FWHM=(redSignalMean-redBackgroundMean)/2;
					if (FWHM<30) {
						FWHM=30;
					}
					run("Find Maxima...", "noise="+FWHM+" output=[Maxima Within Tolerance]");			//cluster identification, width half maxima
					run("Clear Results");		//Need to be changed
					}
					else {
						selectImage("redBallRolled Nuclei-"+(index+1));
						roiManager("Select", (ROIbeforeRedDetect+i));
//						waitForUser(" check red spot region");
						run("Find Maxima...", "noise="+redNoise+" output=[Single Points]");			
						}
					rename("redDotCluster2");
				//   	waitForUser("click OK");
				   	//finish threshold 
				   		waitForUser("Check the red dots obtained, compare to the originImage");
					Step7_OK=getBoolean("Are you happy with the finding?");
				
//						if (Step7_OK==false) 	{ 								Mean that we always remove the RedDotCluster2 and relaunch the selection afterwards whatever the value of Step7_OK
							selectImage("redDotCluster2");
						run("Close");
//				}
				}
	//Single Points
		if ((Step7_OK==true)||(happy==true)) {
					selectImage("redDotClusters in Nuclei-"+(index+1));
					if (highlyAmplified) {
					run("Clear Results");
					selectImage("originImage");
					Stack.setChannel(redDotChannel);
					roiManager("Select", (ROIbeforeRedDetect+i));
					// major change: measure the peak intensity and width half maxima	
					run("Find Maxima...", "noise="+redNoise+" output=[Point Selection]");
//					waitForUser("redSignalMeanBeforeMeasurement");
					run("Measure");
					run("Summarize");
					if (nResults>4) {
					redSignalMean=getResult("Mean",nResults-4);
//					waitForUser("Value of Mean:"+redSignalMean);
					}
					else {
						redSignalMean=getResult("Mean");
					}
//					waitForUser("redSignalMean:"+redSignalMean);
					selectImage("originImage");
					Stack.setChannel(redDotChannel);
					roiManager("Select", (ROIbeforeRedDetect+i));
					run("Find Maxima...", "noise="+redNoise+" output=Count");
					NumberMaxima=getResult("Count");
					FWQM=(redSignalMean-redBackgroundMean)/4;											//Full width quater maxima
					if (FWQM<30) {
						FWQM=30;
					}
					if (NumberMaxima<1) {						
					FWHM=4294967296;
						} 
						
					selectImage("originImage"); //or redBallRolled Nuclei-"+(index+1)
					Stack.setChannel(redDotChannel);
					roiManager("Select", (ROIbeforeRedDetect+i));
					run("Find Maxima...", "noise="+FWQM+" output=[Maxima Within Tolerance]");			//cluster identification, width half maxima
					run("Clear Results");	
					

					}																						//May be some cluster detected at the beginning was not taken in account
					else {
						selectImage("originImage");
						Stack.setChannel(greenDotChannel);
						roiManager("Select", (ROIbeforeRedDetect+i));
						run("Clear Results");
						run("Measure");
						MeanAreaIntensityNonAmplified=getResult("Mean");	
						run("Clear Results");
						selectImage("redBallRolled Nuclei-"+(index+1)); 
						roiManager("Select", (ROIbeforeRedDetect+i));
						run("Find Maxima...", "noise="+redNoise+" output=[Maxima Within Tolerance]");		//When we mesure like this, the dot mixed in a population of dot and big area will not be recognized
						roiManager("Select", (ROIbeforeRedDetect+i));
		//				run("Measure");
//						waitForUser("measure Area");
		//				AreaNonAmplified=getResult("IntDen");
		//				AreaNonAmplified=AreaNonAmplified/255;
//						waitForUser(AreaNonAmplified);
		//				run("Clear Results");
		//				close();
		//				selectImage("redBallRolled Nuclei-"+(index+1)); 
		//				roiManager("Select", (ROIbeforeRedDetect+i));		
		//				run("Find Maxima...", "noise="+redNoise+" output=[Single Points]");			
						}
					rename("redDotCluster2");
//		waitForUser("redDotCluster");
	   	}
   					selectImage("redDotCluster2");
					ROIBeforeLocalMaxDetection=roiManager("Count");
//										waitForUser("maxima detection");
					run("Analyze Particles...", "size=1-15 pixel circularity=0-1.00 add");					//detect Maxima within Tolerance area
					redDotMaximaNumber=roiManager("Count")-ROIBeforeLocalMaxDetection;
					sumlocalMax=0;
							selectImage("redDotClusters in Nuclei-"+(index+1));
							close();

//					calculation of signal peak

							for (k=0; k<redDotMaximaNumber; k++){											//Cluster splitting
							run("Clear Results");
							selectImage("originImage");
							Stack.setChannel(redDotChannel);	
							roiManager("Select", (ROIBeforeLocalMaxDetection+k));	
//							waitForUser("select the local max detection");
							run("Measure");
							localMaxIntensity = getResult("Max");											//Measure
							localMaxArea = getResult("Area");
							getSelectionBounds(xCluster, yCluster, widthCluster, heightCluster);
							run("Clear Results");
							selectImage("originImage");
//							print(logRecord, localMaxArea);
							Stack.setChannel(greenDotChannel);
							roiManager("Select", (ROIBeforeLocalMaxDetection+k));
							run("Measure");
							areaIntensity=getResult("Mean");	
							run("Clear Results");		
							if ((highlyAmplified==0)&&(areaIntensity>MeanAreaIntensityNonAmplified)){areaIntensity=MeanAreaIntensityNonAmplified;} 				//If a negative case, we still use the mean intensity of the cluster to decide whether it is an autofluorescent area
//							getSelectionBounds(x, y, widthDot, heightDot);
		//					if (highlyAmplified==0) {localMaxArea=AreaNonAmplified;}									//here localMaxArea and areaIntensity of not highly amplified cases are those of the cluster containing the dots
											
//							print(logRecord, x+";"+ y+";"+ localMaxArea+";"+ localMaxIntensity);
							roiManager("Select", (ROIBeforeLocalMaxDetection+k));
							greenNonSpecific=greenNoise/4;
							if (greenNonSpecific<30) {greenNonSpecific=30;}
							run("Find Maxima...", "noise="+greenNonSpecific+" output=Count");           //arbitrary choosen greenNoise/4
							greenMaxima=getResult("Count");
							run("Clear Results");		
							redDotNumberPerCluster=0;	
//							waitForUser((localMaxArea/(2*0.104006)));
//							waitForUser(areaIntensity);
									if ((localMaxArea>0)&&(greenMaxima<1)&&(areaIntensity<1.2*minGreenDotIntensity)&&((localMaxArea/0.104006)<redDotLimit)) {						//Very important Count as a red dot only if it is not a local maxima for green chanel, small green signal intensity and size is small enough	
									selectImage("originImage");
									Stack.setChannel(redDotChannel);
									roiManager("Select", (ROIBeforeLocalMaxDetection+k));	
//								
										if (highlyAmplified) {
											DotCountNotCorrected=round(localMaxArea/(2*pixelSize*pixelSize));
											
											if (calibrationHappy==false) {

												gotIt=getBoolean("Do you have the exact dot count of this cluster?");
												if (gotIt==true) {
													waitForUser("Check the count of this cluster");
													Dialog.create("Please give the number of red dots within this cluster");
													Dialog.addNumber("Real red dot number",DotCountNotCorrected)
													Dialog.show();
													RealNumber = Dialog.getNumber();
													calibrationFactor=RealNumber/DotCountNotCorrected;
												    calibrationHappy=true;
												}
											}

											redDotNumberPerCluster=calibrationFactor*DotCountNotCorrected;			//Red number calculation
											redDotNumber=redDotNumber+redDotNumberPerCluster;
											redDotArea=redDotArea+localMaxArea;
										}
										else {
										redDotNumber=redDotNumber+1;	
										}
											selectImage("finalOutline");
											roiManager("Select", (ROIBeforeLocalMaxDetection+k));
											//getSelectionBounds(xDot, yDot, widthDot, heightDot);
											run("Set Drawing Color...");
											setForegroundColor(255, 0, 0); //mark red
										//			roiManager("Deselect");
											//makePoint(xDot+h, yDot+h);
//											roiManager("Add");
		//									print("Local Max"+localMaxIntensity+" background"+backgroundIntensity);
//											waitForUser("");
											roiManager("Draw");
											roiManager("Select", (ROIBeforeLocalMaxDetection+k));
											roiManager("Rename", "Nuclei-"+(index+1)+"_redSpots_detected"+p);					///////////////////////k=0 here??????????????
											setForegroundColor(255, 255, 255);//return to white
												p=p+1;
												selectImage("finalOutline");																							//write the number of red dot beside
											//setForegroundColor(255, 255, 255);
											setColor(255, 255, 255);
											 setFont("Monospaced", 9);
											 if (redDotNumberPerCluster>0) {drawString(redDotNumberPerCluster, xCluster-1, yCluster+4);}												//Some cluster dont have score????					
	//								else {drawString(0, xCluster-1, yCluster+4);}
							}



	}

							
							selectImage("Nuclei-"+(index+1)+"_redSpots_region"+(i+1));
							close();	

							selectImage("redDotCluster2");
							close();	
	}

	}
						
//	close();
//	roiManager("Select", (roiManager("Count")-redRegionNumber+i-redDotNumber));
//	roiManager("Rename", "Nuclei-"+(index+1)+"_redSpots_region"+(i+1));
//	waitForUser("");
//			run("Find Maxima...", "noise="+redNoise+" output=[Segmented Particles]");
//			rename("redSegmented");
//			run("Find Maxima...", "noise="+redNoise+" output=[Maxima Within Tolerance]");
//			rename("redSegmentedMaxima");

//	rename("redSegmentedMaxima");

//	roiManager("Select", (roiManager("Count")-redRegionNumber+i-redDotNumber));
//	ROIcontrol=roiManager("Count");
//	run("Analyze Particles...", "size=100-5000 pixel circularity=0-1.00 add");
//	redDotAdded=roiManager("Count")-ROIcontrol;
//		for (m= 0; m<redDotAdded; m++) {
//		selectImage("originImage");
//		Stack.setChannel(redDotChannel);
//		roiManager("Select", (roiManager("Count")-redDotAdded+m));
	
//////////////verify ereything
//	ROIbeforeRedDotDetection=roiManager("Count");
//	run("Analyze Particles...", "size=0-1 pixel display add");
//	waitForUser("click OK");
//	redDotNumber=redDotNumber+roiManager("Count")-ROIbeforeRedDotDetection;
//	waitForUser("");

//	close();
//		if (redDotNumber>0) {
//			for (y=0; y<redDotNumber;y++){
//			roiManager("Select", (roiManager("Count")-y-1));
//			roiManager("Rename", "Nuclei-"+(index+1)+"_redSpots_detected"+y+1);
//			selectImage("finalOutline");
		
//			roiManager("Select", (roiManager("Count")-y-1));
//			run("Set Drawing Color...");
//			setForegroundColor(255, 0, 0); //mark red
//			roiManager("Deselect");
//			roiManager("Draw");
//			setForegroundColor(255, 255, 255);//return to white
//waitForUser("Check the nuclei");

			
				selectImage("redDotThresholded");	
				close();		
				if ((redDotNumber+numberGreenDot)>0) {
				print((index+1)+"; "+ redDotArea +"; "+redDotNumber+" ; "+numberGreenDot+" ; "+(redDotNumber/numberGreenDot));
				}		
						
				if (happy==0) {
				selectImage("finalOutline");
				waitForUser("finalOutline result image");
				happy=getBoolean("Do we end the threshold setting with this nucleus?");
				}


//				selectImage("redDotThresholded");				waitForUser("Identification of dots is done!");
//				run("Close");	
				redDotTotal=redDotTotal+redDotNumber;
				greenDotTotal=greenDotTotal+numberGreenDot;	
//				waitForUser("close Nuclei");
				selectImage("Nuclei-"+(index+1));
				selectImage("Nuclei-"+(index+1));
				run("Close");
//								waitForUser("close Nuclei");
				selectImage("Nuclei-"+(index+1)+"mesure");
				run("Close");	
				selectImage("greenDotWithoutAutoFluo");
				run("Close");	
				selectImage("redBallRolled Nuclei-"+(index+1));
				run("Close");	
//				selectImage("redBackground");
//				run("Close");
			}

//				selectImage("greenDotThresholded");
//				run("Close");
		if (processAll==false) {processAll=getBoolean("do you want to process until the end now?");
		happy=processAll; //If processAll=false, happy=false
//		setBatchMode(processAll);
				}

}

	selectImage("gBlur2");
	close();
	selectImage("dapiMax");
	close();
	selectImage("dapiMask");
	close();	
//	selectImage("originImage");
//	close();
	selectImage("redDotAutoFluo");
	run("Close");	


//print the obtained parameter to a txt file

selectImage("originImage");
run("Select None");
	Stack.setChannel(redDotChannel);
	
	run("Duplicate...", "title=originRed");
//	setAutoThreshold("MinError dark");
//		getThreshold(lowerR1,upperR1);
		run("Threshold...");
	waitForUser("Please adjust the factor for selecting HER2 without taking autofluorescence");
	getThreshold(lowerR2,upperR2);
			
waitForUser("select the biggest size of a red dot");
run("Clear Results");
run("Measure");
redDotLimit=getResult("Area");
intensityOfRed=getResult("Mean");
redDotLimit=redDotLimit/(pixelSize*pixelSize);
run("Clear Results");
selectImage("redContrast");	
run("Restore Selection");
getSelectionBounds(xroir,yroir,wroir,hroir);
makeRectangle(xroir-1,yroir-1,wroir+2,hroir+2);
getRawStatistics(nPixels, mean, min, max);
run("Measure");
MaxRedSignal=getResult("Max");
MinRedSignal=getResult("Min");
redContrastThreshold=0.6*(MaxRedSignal-MinRedSignal)/(MaxRedSignal+MinRedSignal);

Dialog.create("Please adjust the red dot limit size in pixel, current red dot size threshold is "+redDotLimit);
Dialog.addNumber("redDotLimit",redDotLimit)
Dialog.show();
redDotLimit = Dialog.getNumber();
selectImage("originImage");

	
	
	Stack.setChannel(greenDotChannel);
	run("Select None");
	run("Duplicate...", "title=originGreen");
//	setAutoThreshold("Huang dark");
//		getThreshold(lowerR1,upperR1);
		run("Threshold...");
	waitForUser("Please adjust the factor for selecting CEP17 without taking autofluorescence");
	getThreshold(lowerG2,upperG2);
waitForUser("select the biggest size of a green dot");
run("Clear Results");
run("Measure");

maxGreenDotArea=getResult("Area");
maxGreenSignalIntensity=getResult("Mean");
maxGreenDotArea=maxGreenDotArea/(pixelSize*pixelSize);
run("Clear Results");
Dialog.create("Please adjust the factor for selecting the max size of a green dot in pixel, current maxGreenDotArea size threshold is"+maxGreenDotArea);
Dialog.addNumber("maxGreenDotArea",maxGreenDotArea)
Dialog.show();
maxGreenDotArea = Dialog.getNumber();
	selectImage("originImage");
	Stack.setChannel(dapiChannel);
run("Select None");
	
	run("Duplicate...", "title=originDapi");
//	setAutoThreshold("Huang dark");
//		getThreshold(lowerR1,upperR1);
		run("Threshold...");
	waitForUser("Please adjust the factor for selecting Nuclei without taking autofluorescence");
	getThreshold(lowerB2,upperB2);
waitForUser("select the biggest size of a nucleus");
roiManager("Add");
NucleusPos=roiManager("Count")-1;
run("Clear Results");
run("Measure");
maxNucleiSize=getResult("Area");
maxNucleiSize=maxNucleiSize/(pixelSize*pixelSize);
contrast=contrast_singleROI_calculation("originDapi",NucleusPos);
run("Clear Results");
Dialog.create("Please adjust the factor for selecting the max size of a nuclei in pixel, current nucleus size threshold is"+maxNucleiSize);
Dialog.addNumber("maxNucleiSize",maxNucleiSize)
Dialog.show();
maxNucleiSize = Dialog.getNumber();
selectImage("originImage");
waitForUser("Select a stroma area characterized by high autofluorescence in both red and green channel");
run("Clear Results");
	Stack.setChannel(redDotChannel);
run("Measure");
autofluoRedInNucleus=getResult("Median");
run("Clear Results");
	Stack.setChannel(greenDotChannel);
run("Measure");
autofluoGreenInNucleus=getResult("Median");
autofluoRedGreenThreshold=autofluoRedInNucleus+autofluoGreenInNucleus;
waitForUser("maxGreenDotArea"+maxGreenDotArea+"maxNucleiSize"+maxNucleiSize+"redDotLimit"+redDotLimit);
print("average green dot:"+(greenDotTotal/totalNuclei)+", average red dot:"+(redDotTotal/totalNuclei)+", ratio:"+(redDotTotal/greenDotTotal));

print(logRecord, factorBlueNonSpecific+";"+factorRedNonSpecific +"; "+factorAutofluo+";"+factorBlue +";"+factorRed  +"; "+factorGreen+"; "+blueNoise +"; "+redNoise+"; "+greenNoise+"; "+calibrationFactor +"; "+ maxNucleiSize+"; "+maxGreenDotArea+"; "+ redDotLimit +"; "+blueRedMax+"; "+autofluoRedGreenThreshold+";"+lowerB2+";"+upperB2+";"+lowerR2+";"+upperR2+";"+lowerG2+";"+upperG2+";"+intensityOfRed+";"+redContrastThreshold);
	selectImage("finalOutline");
showMessage("Jobs done");
}