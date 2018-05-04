//Diego intergration code

var caseArray = newArray(6);//number of cases in the batch
var batchNumber = "6";

var caseCount = -1;
var imageCount = 0;
var currentCase = " ";
var tileCount = -1;

var nucleiCount = 0;
var area = 0;
var nucleiLow = 0.001;
var nucleiHigh = 0.02;

var signal = 0;
var background = 0;
var SBR = 0;

var imageName="";

var nucleiName = "Blue";  
var cytokeratinName = "Green";
var her2Name = "Red";
var minCYTO=4294967296;
var maxCYTO=0;
var minHER2Mask=65536;
var maxHER2Mask=65536;
var stats = newArray(2);
var	factorCytokeratinMask=1;
var	factorRedNonSpecific=1;
var factorCYTONonSpecific=1;
var happy=false;
var factorNuclei=1;
//Key calculation function
//function thresholdWithCorrectionFactor Input (RGBimage, lower factor of the threshod) Output (thresholded image with a correction factor applied)
function thresholdWithCorrectionFactor(img, factorLower){
	selectImage(img);

	setAutoThreshold("Default dark");
	getThreshold(lower,upper);
	setThreshold(lower*factorLower,upper);
	setOption("BlackBackground", true);
//	waitForUser("redNonS");
	run("Convert to Mask");
}
//function thresholdWithCorrectionFactor Input (RGB, binary image) Output (RGB image masked by the binary image)

function maskNegativeFromImage(img,theMask) {
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

function imageResults(imageName,attribute) {
	//print(substring(list[i], 0, 2)+","+currentCase);
	if (currentCase == substring(list[i], 0, 2)) {
			selectImage(imageName);
			placex = 10*caseCount + floor(imageCount/imageHeight);
			placey = imageCount-(imageHeight*floor(imageCount/imageHeight));
			setPixel(placex, placey , attribute);	
			}

		else {
			currentCase = substring(list[i], 0, 2);
			caseCount = caseCount+1;
			imageCount = 0;
			caseArray[caseCount] = currentCase;  
		}
	}

function percentile(stats,limit,min, max){
		x=stats[1]/stats[0];               //if stats[1]=0 and stats[0]=0?
		if (x<limit) {	
			min=min+10;
			setThreshold(min, max);
			run("Measure");
			stats[0] = getResult("%Area");
			stats[1] = getResult("Mean");
			percentile(stats,limit,min, max);
		} 
		return stats;
}

macro "MACRO1"{
	tileDimensionX=350;
tileDimensionY=350;
setBatchMode(false);
showMessage("You are running selection of a ROI from an 3 channel IHC image for correction factor adjustment");
waitForUser("Please drag and drop the original .zvi IHC image ");
	run("Color Balance...");
	resetMinAndMax();
waitForUser("Please find select the ROI within the IHC image for the test, it should contain good signals and some artefacts");
run("Duplicate...", "duplicate");
rename("ROI_IHC");
title = "ROI_IHC";
	showMessage("Where to store the IHC correction factors?");
	logRecord = File.open(""); // display file open dialog
//	print(logRecord, "factorRedNonSpecific ; factorCytokeratinMask ; minHER2Mask ; maxHER2Mask ; maxCYTO; factorNuclei");
dapiChannel = 3 ; 
greenDotChannel = 2 ; 
redDotChannel = 1 ;
getDimensions(width, height, channels, slices, frames);
samplingNumberX=width/tileDimensionX;
samplingNumberY=height/tileDimensionY;
positionX=0;
positionY=0;
waitForUser("Please open the folder to save processed IHC images files for the verification");
folder = getDirectory("Folder");
saveFolderBlue = folder+"BlueChannelTIFS"+File.separator;
File.makeDirectory(saveFolderBlue);
saveFolderRed = folder+"RedChannelTIFS"+File.separator;
File.makeDirectory(saveFolderRed);
saveFolderGreen = folder+"GreenChannelTIFS"+File.separator;
File.makeDirectory(saveFolderGreen);
k=0;
//https://imagej.nih.gov/ij/developer/macro/functions.html
for (y=0; (y+1)<samplingNumberY; y++) {
	for (i=0; (i+1)<samplingNumberX; i++) {
		selectImage(title);
		makeRectangle(positionX, positionY, tileDimensionX, tileDimensionY);
		run("Duplicate...", "duplicate");
		rename("tileSelected");
		Stack.setChannel(dapiChannel);
 		run("Duplicate...", "duplicate channels="+dapiChannel);
		saveAs("Tiff", saveFolderBlue+substring(title,0,lengthOf(title)-4)+"Blue_P"+IJ.pad(k,4)+".tif");
		close();
		selectImage("tileSelected");
		Stack.setChannel(redDotChannel);
		run("Duplicate...", "duplicate channels="+redDotChannel);
		saveAs("Tiff", saveFolderRed+substring(title,0,lengthOf(title)-4)+"Red_P"+IJ.pad(k,4)+".tif");
		close();
		selectImage("tileSelected");
		Stack.setChannel(greenDotChannel);
		run("Duplicate...", "duplicate channels="+greenDotChannel);
		saveAs("Tiff", saveFolderGreen+substring(title,0,lengthOf(title)-4)+"Green_P"+IJ.pad(k,4)+".tif");	
		close();
		selectImage("tileSelected");
		close();
		k=k+1;
		positionX=positionX+tileDimensionX;
		}
	positionY=positionY+tileDimensionY;
	positionX=0;
	}
///////////////////////////////////////// end sampling

run("Close All");
	inExtension = ".tif"
	reportFile = " ";
	imageWidth = 10*lengthOf(caseArray);
	imageHeight = 200;
	inDir = folder+"BlueChannelTIFS"+File.separator;
//	outDir = "D:\\EPFL\\image processing\\FIJI\\Image processing problem to solve\\Diego code with explaination\\Output\\";
	//print(inDir);


	count = 0; 


	n = 0;

	//countFiles(inDir, nucleiName);
	//print("the nuclei count is "+count);
	//count = 0; 
	//countFiles(inDir, cytokeratinName);
	//print("the cytokeratin count is "+count);
	//count = 0; 
	//countFiles(inDir, her2Name);
	//print("the her2 count is "+count);
	//count = 0; 

	run("Set Measurements...", "area mean standard modal min median area_fraction limit redirect=None decimal=6");
  	list = getFileList(inDir); 
	print(inDir);

	//for (i=0; i<2; i++) { 
		list = getFileList(inDir); 
	print(inDir);

	//for (i=0; i<2; i++) { 
	
	for (i=0; i<list.length; i++) { 
			newImage(nucleiName, "16-bit", imageWidth, imageHeight, 0);
  	newImage(cytokeratinName, "16-bit", imageWidth, imageHeight, 0);
  	newImage(her2Name, "16-bit", imageWidth, imageHeight, 0);
  	
  	setBatchMode(false); //if you set it = true the images will not appear
  	
		if (endsWith(list[i], "/")) {
		processFiles(""+inDir+list[i], inExtension, nucleiName, cytokeratinName,her2Name); 

		}
		else if (indexOf(list[i], nucleiName) !=-1) { 
			showProgress(n++, count); 
			path = inDir+File.separator+list[i];
	name = "";

	if (endsWith(path, inExtension)) { 
	
		//Nuclei counting
/*		open(replace(path,nucleiName,cytokeratinName));
		cytokeratinMask();
		run("Options...", "iterations=3 count=1 black edm=Overwrite do=Dilate");		
		run("Fill Holes");
		
		ID1=getImageID();
		open(path); 
		ID0=getImageID();
		applyMask(ID1,ID0);

		selectImage(ID0);		
		nucleiDensity=countNuclei();	
		imageName=nucleiName;
		imageResults(nucleiName,nucleiDensity); 	
		print("The nuclei count is "+nucleiDensity);       					
		selectImage(ID0);
		close();	
		selectImage(ID1);
		close();
*/		//......................................................				

		//Cytokeratin mask
		//Step 1: Autofluorescence suppression
if (happy==false) {


			open(replace(path,nucleiName,cytokeratinName));
		ID1=getImageID();
			run("Color Balance...");
	resetMinAndMax();
			run("Set Measurements...", "area mean standard modal min median area_fraction limit redirect=None decimal=6");
		open(replace(path,nucleiName,her2Name));
		ID4=getImageID();
			run("Color Balance...");
	resetMinAndMax();

		Step1_OK=false;
while (Step1_OK==false) {
Dialog.create("Please adjust the factor for selecting the autofluorescence in the HER2 channel");
Dialog.addNumber("factorRedNonSpecific",factorRedNonSpecific)
Dialog.show();
factorRedNonSpecific = Dialog.getNumber();

	selectImage(ID4);
	run("Duplicate...", "title=redNonSpecific");
	selectImage(ID1);
	run("Duplicate...", "title=greenBeforeTreatment");
	//waitForUser("greenBeforeTreatmentCheck");
	selectImage("redNonSpecific");
	setAutoThreshold("Default dark");
	getThreshold(lower,upper);
	setThreshold(lower*factorRedNonSpecific,upper);
	setOption("BlackBackground", true);
	
//	waitForUser("redNonS");

	

Step1_OK=getBoolean("This is the autofluorescence selected. Are you happy with the thresholding? ");
	if (Step1_OK==false) 	{
		selectImage("redNonSpecific");
	run("Close");

}else{
	if (minHER2Mask>lower*factorRedNonSpecific){
		minHER2Mask=lower*factorRedNonSpecific;
		}
			//		if (maxHER2Mask>upper){maxHER2Mask=upper;}
	}
}
	selectImage("redNonSpecific");
	run("Convert to Mask");
	run("Invert");
	maskNegativeFromImage("greenBeforeTreatment", "redNonSpecific");

ID1="greenBeforeTreatment";
//waitForUser("greenBeforeTreatmentCheck");
	selectImage("redNonSpecific");
	run("Convert to Mask");
	run("Invert");


	run("Create Selection");

	
///////////////

selectImage(ID1);
run("Duplicate...", "title=greenHighAutoFluo");
Step2_OK=false;
while (Step2_OK==false) {
Dialog.create("Please adjust the factor for selecting the autofluorescence in the green channel");
Dialog.addNumber("factorGreenNonSpecific",factorCYTONonSpecific)
Dialog.show();
factorCYTONonSpecific = Dialog.getNumber();

selectImage("greenHighAutoFluo");
run("Duplicate...", "title=CytoNonSpecific");
//start threshold
setAutoThreshold("Yen dark");
//waitForUser("check");
getThreshold(maxCYTO,maxi);
maxCYTO=maxCYTO*factorCYTONonSpecific;
setThreshold(maxCYTO,maxi);
setOption("BlackBackground", true);
//finish threshold 
waitForUser("Check threshold of the autofluorescence selected!");
Step2_OK=getBoolean("This is the autofluorescence selected. Are you happy with the thresholding? ");

	if (Step2_OK==false) 	{
		selectImage("CytoNonSpecific");
	run("Close");
}
}

		//Step 2: Detection of cytokeratin
		Step3_OK=false;
//		waitForUser("maxCYTO"+maxCYTO);
			
while (Step3_OK==false) {
		Dialog.create("Please adjust the factor for selecting the cytokeratin signal (do not care about autofluorescence)");
		Dialog.addNumber("factorCytokeratinMask",factorCytokeratinMask)
		Dialog.show();
		factorCytokeratinMask = Dialog.getNumber();
//		waitForUser("check");
		selectImage(""+ID1);
		run("Duplicate...", "title=CytokeratinMask");
			selectImage("CytokeratinMask");

		setAutoThreshold("Default dark");
		getThreshold(lower,upper);

		setThreshold(lower*factorCytokeratinMask,maxCYTO);
		setOption("BlackBackground", true);


	

waitForUser("Check threshold of the cytomask detected!");
Step3_OK=getBoolean(" Are you happy with the thresholding?");

	if (Step3_OK==false) 	{
		selectImage("CytokeratinMask");
	run("Close");
	
}
else
{	
		if (lower*factorCytokeratinMask<minCYTO) {
			minCYTO=lower*factorCytokeratinMask;
			}
		}
}
		selectImage("CytokeratinMask");
		run("Convert to Mask");


//		selectImage(ID1);
//		setAutoThreshold("Default dark");
//		getThreshold(min, max);
//		max=4000;
//		setThreshold(min, max);	
		
		run("Extend Image Borders", "left=2 right=2 top=2 bottom=2 fill=Black"); //To verify

		run("Options...", "iterations=2 count=1 black edm=Overwrite do=Dilate");

		run("Extend Image Borders", "left=-2 right=-2 top=-2 bottom=-2 fill=Black");
		
		run("Make Binary");
		run("Create Selection");
		//run("Options...", "iterations=1 count=1 black edm=Overwrite do=[Fill Holes]");
		//run("Erode");
		//run("Dilate") ;

	IDM1=getImageID();
		//......................................................				

		run("Set Measurements...", "area mean standard modal min median area_fraction limit redirect=None decimal=6");
		open(replace(path,nucleiName,cytokeratinName));
		run("Make Binary");
		run("Create Selection");
		setAutoThreshold("Default dark");
		getThreshold(min, max);
		max=4000;
		setThreshold(min, max);	
		run("Measure");
		stats[0] = getResult("%Area");
		stats[1] = getResult("Mean");
		stats=percentile(stats,150,min,max);
		close();
		//DAPI mask	at the end you have the area outside of nuclei
		open(path); 
		ID2=getImageID();
			IDN1=getImageID();
//			waitForUser("");
					Step4_OK=false;
			
while (Step4_OK==false) {
		Dialog.create("Please adjust the factor for selecting Nuclei");
		Dialog.addNumber("factorNuclei",factorNuclei)
		Dialog.show();
		factorNuclei = Dialog.getNumber();

		selectImage(IDN1);
		run("Duplicate...", "title=Nuclei");

		setAutoThreshold("Huang dark");
		getThreshold(lower,upper);

		setThreshold(lower*factorNuclei,upper);
		setOption("BlackBackground", true);


	

waitForUser("Check the nuclei detected!");
Step4_OK=getBoolean("Are you happy with the thresholding?");

	if (Step4_OK==false) 	{
		selectImage("Nuclei");
	run("Close");
	
}

}
//waitForUser("");
		selectImage(IDN1);
		run("Close");
		IDN1="Nuclei";
		selectImage(IDN1);		
		run("Convert to Mask");
		run("Fill Holes");
		run("Invert");	
		run("Duplicate...", "Image2.TIF");
		IDN2=getImageID();
//		run("Extend Image Borders", "left=8 right=8 top=8 bottom=8 fill=Black"); //to verify first
		run("Options...", "iterations=8 count=1 black edm=Overwrite do=Erode");
//		run("Extend Image Borders", "left=-8 right=-8 top=-8 bottom=-8 fill=Black");
		run("Invert");
		imageCalculator("Multiply create", IDN1,IDN2 );
//		waitForUser("");
		IDN3=getImageID();
		selectImage(IDN1);
 		close();	
 		selectImage(IDN2);
 		close();	
 		selectImage(IDN3);
 		IDM2=getImageID();

	names = newArray(nImages); 
	ids = newArray(nImages); 
	for (j=0; j < ids.length; j++){ 
		selectImage(j+1); 
		ids[j] = getImageID(); 
		names[j] = getTitle(); 
		//print(ids[i] + " = " + names[i]); 
		}
		if (ids.length>1){	
			imageCalculator("Multiply create", names[ids.length-2],names[ids.length-1]); //product of nuclei and cytokeratin?
//			waitForUser(" check");
			IDM3=getImageID();

			selectImage(names[ids.length-2]);
			close();
			selectImage(names[ids.length-1]);
			close();		
			}	
selectImage(IDM3);
	run("Convert to Mask");
	run("Create Selection");

//				
//		selectImage(IDM1);
//		close();
//		selectImage(IDM2);
//		close();		
		//......................................................

		
		//HER2 signal in the area surrounded the nuclei and in highly expressed cytokeratin area
		selectImage(ID4);
		run("Set Measurements...","area mean standard modal min median area_fraction limit redirect=None decimal=6");
		run("Restore Selection");
		setThreshold(0, 4095*0.90);
 		run("Measure");
		background = getResult("Mean");
		run("Make Inverse");
		run("Measure");
		signal= getResult("Mean");
 		SBR=signal-background; //??????SBR= signal/background!!
 		if (SBR<0){
 			SBR=0;
 			}	

 			imageName=her2Name;
		imageResults(imageName,SBR);
 		selectImage(ID4);
// 		close();	
		//......................................................

		selectImage(IDM3);
		run("Create Selection");

		//......................................................

		//Cytokeratin signal measurement
		open(replace(path,nucleiName,cytokeratinName));
		ID5=getImageID();

		run("Set Measurements...","area mean standard modal min median area_fraction limit redirect=None decimal=6");
		run("Restore Selection");
		setThreshold(0, 4095*0.90);
 		run("Measure");
		background = getResult("Mean");
		run("Make Inverse");
		run("Measure");
		signal= getResult("Mean");
 		SBR=signal-background; //??????SBR= signal/background!!
 		if (SBR<0){
 			SBR=0;
 			}	
 				imageName=cytokeratinName;
		imageResults(imageName,SBR);
 		selectImage(ID5);
 		run("Color Balance...");
		resetMinAndMax();
 		waitForUser("Check the final result: HER2 signal inside of CytoMask");
 		
 		waitForUser("Check the corrections factors: factorRedNonSpecific "+ factorRedNonSpecific+"; factorCytokeratinMask "+factorCytokeratinMask+"; minHER2Mask " +minHER2Mask+"; maxHER2Mask " +maxHER2Mask+"; maxCYTO" +maxCYTO+"; factorNuclei"+factorNuclei  );	
//		close();
 		selectImage(IDM3);
 		close();
		//......................................................

		imageCount = imageCount+1;
		
//		selectImage("redNonSpecific");
//		close();
			

run("Close All");
       } 
	       if (happy==false){
	       happy=getBoolean("Are you happy with the correction factors obtained?");
	       }
		}
     } 
 } 
print(logRecord, factorRedNonSpecific+";"+factorCytokeratinMask+" ;" +minHER2Mask+" ;" +maxHER2Mask+" ;" +maxCYTO+" ;"+ factorNuclei);
 showMessage("Job done!");
		} 