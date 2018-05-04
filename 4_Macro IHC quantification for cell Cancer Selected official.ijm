//Diego intergration code
var sbm=true;
var startingTile=0;
var sharpen_radius=2; sharpen_weight=0.9; 
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

var stats = newArray(2);

var Contrast_Rescale_Factor=0.35;
var sharpen_radius=2; sharpen_weight=0.9; 
var local_radius=2;
var pixelSize=0.645;

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
function SharpBasedThreshold(Original_Image, Threshold_Contrast, Contrast_Rescale_Factor, sharpen_radius, sharpen_weight, local_radius) {

run("Clear Results");
run("Set Scale...", "distance=1 known=0.645 pixel=1 unit=um global");
run("Set Measurements...", "area mean standard min median area_fraction display redirect=None decimal=0");
resetMinAndMax();

Image_Name=Original_Image+"_Sharpen Radius="+sharpen_radius+", Local radius="+local_radius+", Threshold contrast="+Threshold_Contrast+", Contrast rescale factor"+Contrast_Rescale_Factor;
Mask_Name="Mask";
selectImage(Original_Image);
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

close(title+"_Max"); 
ROI0=roiManager("Count"); 	
T1=Adapted_Thresholding(Threshold_Contrast,title+"_Local Contrast");

if (T1==0) {										//si il ny a pas de region thresholded
	selectWindow(Mask_Name);
	run("Select All");
	run("Clear");
} else {											
	roiManager("Select", ROI0); 	
	roiManager("Rename", "Local Contrast Threshold");
	selectWindow(Mask_Name); 
	roiManager("Select", ROI0); 
	run("Clear Outside");
	run("Select None");
	
	selectWindow(title+"_Local Contrast");
	rename(title+"_Local Contrast Rescaled");
	run("Multiply...", "value="+Contrast_Rescale_Factor);					//Cherche de signal dans les regions ou il y assez contraste

	imageCalculator("Add create", title+"_Min",title+"_Local Contrast Rescaled");
	rename(title+"_Local MidGrey");

	imageCalculator("Subtract create", title, title+"_Local MidGrey");
	selectImage("Result of "+title);
	rename(title+"_MidGrey Thresholded");							// augmente le 0.35 des pixel de base pour selectioner 

	T1=Adapted_Thresholding(1,title+"_MidGrey Thresholded");

	close(title); 
	close(title+"_Min"); 
	close(title+"_Local Contrast Rescaled"); 
	close(title+"_Local MidGrey"); 
	close(title+"_MidGrey Thresholded");
	
	if (T1==0) {
		selectWindow(Mask_Name);
		run("Select All");
		run("Clear");
	} else {
		roiManager("Select", ROI0+1); 
		roiManager("Rename", "Local MidGrey Threshold");
		selectWindow(Mask_Name); 
		roiManager("Select", ROI0+1); 
		run("Clear Outside");
		run("Select None");
	}
}

selectWindow(Mask_Name);
run("Options...", "iterations=1 count=7 black do=Close");
rename(Mask_Name);
getRawStatistics(nPixels, mean, min, max);
//close("//Others"); 
selectWindow(Image_Name);
close();
selectWindow(Mask_Name);
}
//Key calculation function
//function thresholdWithCorrectionFactor Input (RGBimage, lower factor of the threshod) Output (thresholded image with a correction factor applied)
function thresholdWithCorrectionFactor(img, factorLower, min, max, method){
	selectImage(img);
	setAutoThreshold(method+" dark");

//	waitForUser("Huang");
	getThreshold(lower,upper);
	
	print(lower+","+upper+","+min+","+max);
	if (lower*factorLower<min){ 
		lower=min;
	}else{
		lower=lower*factorLower;
	}
	if (upper>max){ 
		upper=max;
	}

	setThreshold(lower,upper);		//Here Lower can > upper and cause a white image as a non specific mask and it is normal as lower was multiplied by a factor of factorLower
	setOption("BlackBackground", true);
	run("Convert to Mask");
//	waitForUser("CytokeratinMask");
	
}
//function thresholdWithCorrectionFactor Input (RGB, binary image) Output (RGB image masked by the binary image)

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

function imageResults(imageName,attribute, positionX, positionY) {
	print(substring(list[i], 0, 2)+","+currentCase);
	if (currentCase == substring(list[i], 0, 2)) {
			selectImage(imageName);
//			waitForUser("caseCount"+caseCount+"imageCount"+imageCount+"imageHeight"+imageHeight);

//						waitForUser("x"+placex+"y"+placex+"attr"+attribute);

	
			setPixel(positionX, positionY , attribute);
//						waitForUser("2"+imageName);	
			caseCount = caseCount+1;

			}

		else {
			currentCase = substring(list[i], 0, 2);
			caseCount = caseCount+1;
			imageCount = 0;
			caseArray[caseCount] = currentCase;  
		}
	}
function heatMapThreshold(redHeatmap,greenHeatmap,blueHeatmap, fileInfo){
	selectImage(greenHeatmap);
	run("Duplicate...", "title=greenHeatmapThresholded");
	getDimensions(width, height, channels, slices, frames);
	print(width, height, channels, slices, frames);
	setBatchMode("show");

	
	setAutoThreshold("Huang dark");
		run("Threshold...");
	waitForUser("check greenHeatmap for thresholding method");

		getDimensions(width, height, channels, slices, frames);

	getThreshold(min, max);
	isCellLine=(width*height)<100;			//detect if it is cell line or tissue by number of tile
	print(isCellLine);
	if (isCellLine) setThreshold(min/100,max);
	run("Convert to Mask");
		for (i= 0;i<width; i++) {
				for(j=0;j<height;j++){
						pixelValue=getPixel(i,j);
						if (pixelValue>0){
							n=j*width+i;
							print(fileInfo, IJ.pad(n,4));						//position of the tile
											}
										}
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
function cellSegmentation(DAPIChannel,CytoChannel,HER2Channel, CytokeratinAreaMask, redNonSpecificThresholded, filename, filecode, blueNoise, sizeFactor) { 
	//print(substring(list[i], 0, 2)+","+currentCase);

			totalNucleiArea=0;
			selectImage(CytokeratinAreaMask);			//in order to get rid of the stroma
			roiManager("Deselect");
			run("Duplicate...", "title=cancerArea");
//			run("Make Binary");					//Sometime it doesnt understand that this is a binary image
//			run("Invert");
			run("Fill Holes");
//			waitForUser("beforeDilation");

		run("Options...", "iterations=3 count=1 black edm=Overwrite do=Erode");
		
		run("Options...", "iterations=3 count=1 black edm=Overwrite do=Dilate");

			run("Select None");
			setAutoThreshold("Huang dark");
			run("Create Selection");
			run("Set Measurements...", "area mean integrated display redirect=None decimal=6");
				selectImage(DAPIChannel);
			run("Duplicate...", "title=Noyau");
			run("Duplicate...", "title=nucleusMask");
			run("Duplicate...", "title=thresholdedNuclei");

			
			setAutoThreshold("MinError dark");
			getThreshold(minErrorMin, minErrorMax);
			setThreshold(minErrorMin*0.8,minErrorMax);

			run("Convert to Mask");
	
							maskFromImage("thresholdedNuclei", redNonSpecificThresholded);

		
				selectImage("nucleusMask");
			setAutoThreshold("MinError dark");
			getThreshold(minErrorMin, minErrorMax);
			setThreshold(minErrorMin*0.8,minErrorMax);
			run("Convert to Mask");
			run("Fill Holes");
			imageCalculator("Multiply create 32-bit", "nucleusMask","CytokeratinMask-ext-ext");
			selectImage("Result of nucleusMask");
			rename("nucleusMask1");
				selectImage(CytoChannel);
			run("Duplicate...", "title=membrane");
				selectImage(HER2Channel);
			run("Duplicate...", "title=HER2");
			selectWindow("Noyau");
			run("Thresholded Blur", "radius=7 threshold=120 softness=5 strength=2");	
			
//			run("Gaussian Blur...", "sigma=3");
//			waitForUser("");
	//		run("Morphological Filters", "operation=Opening element=Disk radius=6");	

			selectWindow("membrane");
			run("Unsharp Mask...", "radius="+sharpen_radius+" mask="+sharpen_weight);
			selectWindow("HER2");
			run("Unsharp Mask...", "radius="+sharpen_radius+" mask="+sharpen_weight);
//			waitForUser("Now try to enhance membrane");
			imageCalculator("Multiply create 32-bit", "HER2","membrane");			
			selectImage("Result of HER2");
			rename("enhancedMembrane");
			run("Invert");
			run("8-bit");
			selectWindow("membrane");
			setAutoThreshold("Huang dark");
			run("Convert to Mask");
			imageCalculator("OR create 32-bit", "thresholdedNuclei","membrane");
			selectWindow("Result of thresholdedNuclei");

			run("8-bit");
			imageCalculator("Multiply create 32-bit", "Noyau","enhancedMembrane");
			selectWindow("Result of Noyau");
			run("16-bit");
			run("Restore Selection");
//There is somethind did not work in batchmode for BM3131 maybe thresholded blur function
			
			run("Find Maxima...", "noise="+blueNoise+" output=[Point Selection]");
			selectWindow("Result of Noyau");
			run("Find Maxima...", "noise="+blueNoise+" output=[Segmented Particles]");
			//selectImage("Result of Nuclei Segmented");
	//					waitForUser("Before segment");
			rename("SegmentedNuclei");
			selectWindow("Result of Noyau");
			run("Morphological Filters", "operation=Opening element=Disk radius=7");
			rename("Noyau-opened");		
			run("Find Maxima...", "noise="+blueNoise+" output=[Maxima Within Tolerance]");	
			rename("Noyau-maxima");	
			selectImage("Noyau-opened");		
			setAutoThreshold("Default dark");		
			run("Convert to Mask");

			imageCalculator("OR create", "Noyau-opened","Noyau-maxima");
			
			run("8-bit");
//		run("Options...", "iterations=1 count=1 black edm=Overwrite do=Dilate");
			rename("cellMask1");
			
				imageCalculator("OR create", "cellMask1","nucleusMask1");
			rename("cellMask");

			close("Noyau-opened");
			close("Noyau-maxima");
			close("*nucleusMask*");
			close("cellMask1");
			imageCalculator("AND create 32-bit", "cellMask","SegmentedNuclei");
			rename("SegmentedCell");
			run("8-bit");
			ROIcontrol2=roiManager("Count");
			run("Analyze Particles...", "size="+120/sizeFactor+"-"+7000/sizeFactor+" pixel add");
			voronoiNumber=roiManager("Count")-ROIcontrol2;
								count=0;
//			waitForUser("Before filtering");
	for (i=0; i<voronoiNumber; i++) { 

	
		selectWindow("Result of Noyau");
	     roiManager("Select", ROIcontrol2+i);
//	     waitForUser("");
		run("Find Maxima...", "noise="+blueNoise+" output=Count");
		 NumberMaxima=getResult("Count");
//		waitForUser(NumberMaxima);
		 if (NumberMaxima==0) {									//if there is two cell then delete the old cell file ////////////////////problem here
//		 	waitForUser("Count 1");
		 		 roiManager("Select", ROIcontrol2+i);
//		 		 waitForUser("before Delete");
		 	     roiManager("Delete");
		 	     voronoiNumber=voronoiNumber-1;
		 	     i=i-1;
		 }
		 else { 
//		 	waitForUser("before rename "+i);
		 	     	run("Clear Results");
		 selectWindow("thresholdedNuclei");
	     roiManager("Select", ROIcontrol2+i);
		run("Measure");
		pixelSum=getResult("IntDen");
		run("Clear Results");
		nucleiArea=pixelSum/255;
		nucleiArea=nucleiArea/(pixelSize*pixelSize);
//		waitForUser(nucleiArea);
		totalNucleiArea=totalNucleiArea+nucleiArea;
//		 selectWindow("DAPIChannel");
//	     roiManager("Select", ROIcontrol2+i);
//		run("Measure");
//		blueIntensity=getResult("Mean");
//		run("Clear Results");
//		blueIntensity=blueIntensity/
		if ((nucleiArea/(sizeFactor*sizeFactor))>750) {
			roiManager("Select", ROIcontrol2+i);
		roiManager("Delete");
//		waitForUser("check");
		voronoiNumber=voronoiNumber-1;
		i=i-1;

			}//biggest nucleus is 310
			else {		 	
							roiManager("Select", ROIcontrol2+i);
				roiManager("rename", filename+" cell "+count); 
				count++;
}
		}	
		 }
		if ((roiManager("Count")>0)&&(totalNucleiArea/(sizeFactor*sizeFactor)>100)) { 									//delete all tiles having total Nuclei Area too small
	 	 roiManager("Deselect"); 
	 	 saveROI=true;
		 }
//		 else{waitForUser(totalNucleiArea/(sizeFactor*sizeFactor));}
//			waitForUser("afterDeletation");
		selectImage("cancerArea");
		close();
		selectImage("SegmentedCell");
		close();
		selectImage("SegmentedNuclei");
		close();
		selectImage("thresholdedNuclei");
		close();
				selectImage("enhancedMembrane");
		close();
				selectImage("membrane");
		close();
				selectImage("cellMask");
		close();

		selectImage("HER2");
		close();
			//								waitForUser("After detection");
			selectWindow("Noyau");
		close();			
		selectImage("Result of Noyau");
		close();

return saveROI
	}
macro "MACRO1"{

//run("Close All");
	inExtension = ".tif"
	reportFile = " ";
//inDir = "D:/Image processing IHC FISH project/2ABottom right/aligned/IHC tile 2A/BlueChannelTIFS/";
	inDir = getDirectory("Choose the Blue channel folder in the Batch Input Directory "); 
//	inDir="I:/experiment/IHC FISH/Joint project with Daniel/BC2/Aligned 2/IHC tiles/BlueChannelTIFS/";
	print("inDir = "+inDir+";");
//	output="D:/Image processing IHC FISH project/2ABottom right/aligned/Output IHC/";
output=substring(inDir,0,lengthOf(inDir)-26)+"Output IHC"+File.separator;

File.makeDirectory(output);
//	output=getDirectory("Output directory where the IHC result tiles are saved");//print(inDir);
	print("output"+output+";");
//	output="I:/experiment/IHC FISH/Joint project with Daniel/BC2/Aligned 2/IHC 4/";
//	showMessage("Where to store the result?");
	ResultRecord = File.open(output+"result.txt"); // display file open dialog
print(ResultRecord, "Tile name; Code; signal HER2; background HER2;  Signal CYTO; Background Cyto; Cell code; cell HER2 signal;cellHER2Area; cell Cytokeratin Signal; cellTotalArea; ROI_x; ROI_y; ROIWidth; ROIHeight");
//heatMap = getDirectory("Please open the folder for saving tile heatmaps");
//heatMap="D:/Image processing IHC FISH project/tile heatmap/";
heatMap=substring(inDir,0,lengthOf(inDir)-26)+"Tiles heatmap"+File.separator;
File.makeDirectory(heatMap);
//heatMap = "I:/experiment/IHC FISH/Joint project with Daniel/BC2/Aligned 2/Tiles heatmap 4/";
print("heatMap"+heatMap+";");
//ROIplace="D:/Image processing IHC FISH project/roi/";

ROIplace=substring(inDir,0,lengthOf(inDir)-26)+"roi IF"+File.separator;
File.makeDirectory(ROIplace);
//ROIplace=getDirectory("Where is the place to store ROI for these tiles");//print(inDir);
		print("ROIplace"+ROIplace+";");
//	ROIplace="I:/experiment/IHC FISH/Joint project with Daniel/BC2/Aligned 2/ROI4/";

//positionFile=File.openDialog("Choose the file where image position information were stored"); 
		
		positionFile=substring(inDir,0,lengthOf(inDir)-26)+"tile_info.txt";
		print(positionFile);
	positionFileString=File.openAsString(positionFile); //open the file as a string
	rows=split(positionFileString, ";"); // split by using ; and enumerate
	 xTileNumber=parseFloat(rows[0])-0.5;
	 xTileNumber=parseInt(xTileNumber);
	 yTileNumber=parseFloat(rows[1])-0.5;
	 yTileNumber=parseInt(yTileNumber);
//	 print(xTileNumber+"  "+ yTileNumber);
	imageWidth = xTileNumber;
	imageHeight = yTileNumber;

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
	
	pathfile=File.openDialog("Choose the file where the threshold correction factors are stored"); 
	filestring=File.openAsString(pathfile); //open the file as a string
	print(filestring);
	
	rows=split(filestring, ";"); // split by using ; and enumerate
	 factorRedNonSpecific=parseFloat(rows[0]);
	 factorCytokeratinMask=parseFloat(rows[1]);
	minHER2Mask=parseFloat(rows[2]);
	maxHER2Mask=parseFloat(rows[3]);
	maxCYTO=parseFloat(rows[4]);	
	 nucleiNoise=parseFloat(rows[5]);
	 blueNoise=parseFloat(rows[6]);							//For segmentation
	 Threshold_Contrast=parseInt(rows[7]);
//	 blueNoise=parseFloat(rows[7]);
	//for (i=0; i<2; i++) { 
		list = getFileList(inDir); 

//waitForUser("Check the corrections factors: factorRedNonSpecific "+ factorRedNonSpecific+"; factorCytokeratinMask "+factorCytokeratinMask+"; minHER2Mask " +minHER2Mask+"; maxHER2Mask " +maxHER2Mask+"; maxCYTO" +maxCYTO+"; factorNuclei"+factorNuclei  );	

	//for (i=0; i<2; i++) { 
	

HER2Channel=1;
CytoChannel=2;
totalTileNo=list.length;

/*
waitForUser("Please open the reference having a lot of red autofluorescence");
rename("redHighAutoFluo");
Step1_OK=false;
while (Step1_OK==false) {
Dialog.create("Please adjust the factor for selecting the autofluorescence in the red channel");
Dialog.addNumber("factorHERNonSpecific",factorHERNonSpecific)
Dialog.show();
factorHERNonSpecific = Dialog.getNumber();

selectImage("redHighAutoFluo");
run("Duplicate...", "title=HER2nonspecific");
//start threshold
setAutoThreshold("Yen dark");
waitForUser("check");
getThreshold(minHER2,maxHER2);
minHER2=minHER2*factorHERNonSpecific;
setThreshold(minHER2,maxHER2);
setOption("BlackBackground", true);
//finish threshold 
Step1_OK=getBoolean("Are you happy with the thresholding? ");

	if (Step1_OK==false) 	{
		selectImage("HER2nonspecific");
	run("Close");
}
}
waitForUser("Please open the reference having a lot of green autofluorescence");
rename("greenHighAutoFluo");

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
getThreshold(minCYTO,maxCYTO);
minCYTO=minCYTO*factorCYTONonSpecific;
setThreshold(minCYTO,maxCYTO);
setOption("BlackBackground", true);
//finish threshold 
Step2_OK=getBoolean("Are you happy with the thresholding? ");

	if (Step2_OK==false) 	{
		selectImage("CytoNonSpecific");
	run("Close");
}
}
*/
//overall threshold value
	setBatchMode(sbm);
 	newImage(nucleiName, "16-bit", imageWidth, imageHeight, 0);
  	newImage(cytokeratinName, "16-bit", imageWidth, imageHeight, 0);
  	newImage(her2Name, "16-bit", imageWidth, imageHeight, 0);
	adjustingNumber4AlienFile=0;
	for (i=startingTile; i<list.length; i++) { 
if (endsWith(list[i],".tif")){
		roiManager("reset");
		out=0;
		saveROI=1;
		positionX=(i-adjustingNumber4AlienFile) % xTileNumber;
		positionY=(i-adjustingNumber4AlienFile-positionX)/xTileNumber;		//start from y=0
//		waitForUser(list[i]);
			path = inDir+list[i];
	name = "";
 
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
		
//			waitForUser(path);
		cytoPath=replace(path,nucleiName,cytokeratinName);
			open(cytoPath);
//			waitForUser(cytoPath);
		ID1=getImageID();
		run("Set Scale...", "distance=1 known=0.645 unit=um global");
			run("Set Measurements...", "area mean standard modal min median area_fraction limit redirect=None decimal=6");
			open(replace(path,nucleiName,her2Name));
			ID4=getImageID();
			selectImage(ID4);
			run("Set Scale...", "distance=1 known=0.645 unit=um global");
//			waitForUser("redNonSpec");
			run("Duplicate...", "title=redNonSpecific");
			run("Duplicate...", "title=originalRedChannel");
			selectImage(ID1);
			run("Duplicate...", "title=greenBeforeTreatment");
			open(path);
			run("Set Scale...", "distance=1 known=0.645 unit=um global");
			rename("DAPIchannel");
			filename=list[i];
				

	thresholdWithCorrectionFactor("redNonSpecific", factorRedNonSpecific, minHER2Mask, maxHER2Mask,"Yen");					///////////minHER2 is the level for HER2 autofluorescence selection 
//					waitForUser("check 2");
//waitForUser("redNonSpecific before erode");
	run("Clear Results");
	selectImage("redNonSpecific");
	run("Select None");
	run("Convert to Mask");
	setAutoThreshold("Huang dark");																		
	run("Create Selection");
	run("Measure");																										//redNonSpecific should be white	
			getDimensions(widthTile, heightTile, channelsTile, slicesTile, framesTile);
//	waitForUser("check redNonSpecific Mask");
	areaRedNonSpecific = getResult("Area");
		MeanRedNonSpecific = getResult("Mean");
	areaRedNonSpecific=areaRedNonSpecific/(pixelSize*pixelSize*widthTile*heightTile);
			run("Select None");
//	waitForUser(MeanRedNonSpecific+"check areaRedNonSpecific"+areaRedNonSpecific);			
	if ((areaRedNonSpecific<0.99)||(MeanRedNonSpecific<255))
	{		//waitForUser("check redNonSpecific Mask");
		run("Select None");
		run("Invert");
	}

	selectImage("redNonSpecific");

//	waitForUser("check redNonSpecific Mask");
//	run("Extend Image Borders", "left=1 right=1 top=1 bottom=1 fill=Black");
//	run("Erode");
		run("Clear Results");
//	waitForUser("redNonSpecific after erode");

	maskFromImage("greenBeforeTreatment", "redNonSpecific");
//						waitForUser("check 3");
	selectImage(ID1);
	run("Duplicate...", "title=CytoNonSpecific");
		selectImage("CytoNonSpecific");
		getThreshold(mini,maxi);
		setThreshold(maxCYTO,maxi);
		setOption("BlackBackground", true);
		selectImage("CytoNonSpecific");
		run("Convert to Mask");
		run("Measure");
		areaCytoNonSpecific = getResult("Area");
		areaCytoNonSpecific=areaCytoNonSpecific/(pixelSize*pixelSize*widthTile*heightTile);

	//		if ((areaCytoNonSpecific>0)&&(areaCytoNonSpecific<0.99)) {
	run("Invert");
	//}
		getDimensions(width, height, channels, slices, frames);
	AutoFluorProportion= areaCytoNonSpecific/(pixelSize*pixelSize*width*height);
	
	NonValid=(AutoFluorProportion>0.01)&&(AutoFluorProportion<0.99); //if autofluorescence is too big, there is a lot of chance that it is signal
	
		areaCytoNonSpecific=areaCytoNonSpecific/(pixelSize*pixelSize);

	//Step 2: Detection of cytokeratin 
		Step2_OK=false;


//waitForUser("check");
		selectImage("greenBeforeTreatment");
				run("Duplicate...", "title=CytokeratinMask");
				
		run("Unsharp Mask...", "radius="+sharpen_radius*3+" mask="+sharpen_weight/2);
//		SharpBasedThreshold("greenBeforeTreatment", Threshold_Contrast, Contrast_Rescale_Factor, sharpen_radius, sharpen_weight, local_radius);
//		selectImage("Mask");
//		rename("CytokeratinMask");
//		waitForUser("CytokeratinMask");
		
//		print(maxCYTO);	

		thresholdWithCorrectionFactor("CytokeratinMask", factorCytokeratinMask, maxCYTO/100000, maxCYTO,"Huang"); 					///////////maxCYTO is the maximum threshold level for cyto selection before reaching the autofluorescence
//		waitForUser("CytokeratinMask2");
		selectImage("CytokeratinMask");

	
//		selectImage(ID1);
//		setAutoThreshold("Default dark");
//		getThreshold(min, max);
//		max=4000;
//		setThreshold(min, max);	
		
		

		//run("Options...", "iterations=1 count=1 black edm=Overwrite do=[Fill Holes]");
		//run("Erode");
		//run("Dilate") ;
					
		run("Extend Image Borders", "left=3 right=3 top=3 bottom=3 fill=Black"); //To verify

		run("Options...", "iterations=3 count=1 black edm=Overwrite do=Dilate");

		run("Extend Image Borders", "left=-3 right=-3 top=-3 bottom=-3 fill=Black");
		
		IDM1=getImageID();
		NameIDM1=getTitle();

		if (NonValid==0) {
		maskFromImage(NameIDM1,"CytoNonSpecific");
		}


		
		//......................................................				

		selectImage("CytokeratinMask-ext");
		close();
		run("Set Measurements...", "area mean standard modal min median area_fraction limit redirect=None decimal=6");

//				waitForUser("before segmentation");
sizeFactor=2;


//	waitForUser("Check roi 1");
	ROIcontrol1=roiManager("Count");

	saveROI=cellSegmentation("DAPIchannel", ID1,"originalRedChannel", NameIDM1, "redNonSpecific" , filename, i, blueNoise, sizeFactor); //segmentation based on originImage can be improved
//waitForUser("after segmentation");
roiAfter=roiManager("Count");
	
		cellNumber=roiAfter-ROIcontrol1;
//waitForUser("treatedNuclei");

//	waitForUser("Check roi 2");
//	cellNumber=roiManager("Count");
	
//waitForUser("greenBeforeTreatmentCheck");

	
	
/*		open(replace(path,nucleiName,cytokeratinName));
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
		*/
		//DAPI mask	at the end you have the area outside of nuclei
		open(path); 
		run("Set Scale...", "distance=1 known="+pixelSize+" unit=um global");
//		rename("treatedNuclei");
		ID2=getImageID();
//		waitForUser("");
		run("Thresholded Blur", "radius=7 threshold=120 softness=5 strength=2");
		run("Find Maxima...", "noise="+nucleiNoise+" output=Count");
				count = getResult("Count");
				if (count<3) nucleiNoise=nucleiNoise/2;
		selectImage(ID2);
		run("Find Maxima...", "noise="+nucleiNoise+" output=[Maxima Within Tolerance]");
//		waitForUser("Check");
		IDN1=getImageID();
//		run("Dilate");
//		run("Watershed");
//waitForUser("1");
//		ROIcontrol3=roiManager("Count");
//				waitForUser("Check 1");
//		run("Analyze Particles...", "size=100-5000 pixel circularity=0-1.00 add");


//		NucleiNumber=roiManager("Count")-ROIcontrol3;
		run("Select None");
		run("Fill Holes");
		run("Watershed");	
		run("Invert");	
		run("Duplicate...", "Image2.TIF");


		IDN2=getImageID();

//		run("Extend Image Borders", "left=8 right=8 top=8 bottom=8 fill=Black"); //To verify
//		waitForUser("1");
		run("Options...", "iterations=1 count=1 black edm=Overwrite do=Erode");
//		waitForUser("2");
		IDN4=getImageID();	
//		waitForUser("");
//		run("Extend Image Borders", "left=-8 right=-8 top=-8 bottom=-8 fill=Black");
//		run("Invert");
		selectImage(IDN1);		

//		run("Extend Image Borders", "left=1 right=1 top=1 bottom=1 fill=Black"); //enlarge the nuclei
		run("Options...", "iterations=20 count=1 black edm=Overwrite do=Dilate");
		IDN5=getImageID();		
//waitForUser(IDN5);
		imageCalculator("Multiply create", IDN5,IDN4 );
//		waitForUser("after Multiplication");
		IDN3=getImageID();
		selectImage(IDN1);
 		close();	
 		selectImage(IDN2);
 		close();
// 		 		selectImage("treatedNuclei Maxima");
// 		close();	
 

imageCalculator("Multiply create", NameIDM1,IDN3); 
	selectImage("Result of "+NameIDM1);
	rename("finalMask");

//	waitForUser("finalMask");
	run("8-bit");

//	selectImage(IDN3);
//	close();
//			waitForUser("cytomask");

//				
//		selectImage(IDM1);
//		close();
//		selectImage(IDM2);
//		close();		
		//......................................................

		
		//HER2 signal in the area surrounded the nuclei and in highly expressed cytokeratin area

		selectImage("finalMask");
		run("Select None");
		run("Duplicate...", "title=CytokeratinMaskComplementary");
		
		run("Select None");
		run("Invert");

//		waitForUser("Cyto and redNonSpecific");
		imageCalculator("Multiply create","CytokeratinMaskComplementary","redNonSpecific");
		selectImage("Result of CytokeratinMaskComplementary");
		rename("backgroundMask");
//		run("Extend Image Borders", "left=0 right=1 top=0 bottom=1 fill=Black");
		setAutoThreshold("Huang dark");
		run("Create Selection");
//		run("Extend Image Borders", "left=-1 right=-1 top=-1 bottom=-1 fill=Black");
//s		waitForUser("backgroundMaskCheck");
		
//			if (i==482) {waitForUser("3");}
		selectImage(ID4);
		run("Set Measurements...","area mean standard modal min median area_fraction limit redirect=None decimal=6");
		run("Clear Results");
		run("Restore Selection");
//		waitForUser(" measure red");
//		setThreshold(0, 4095*0.90);
//      waitForUser("backgroundMaskCheck");
 		run("Measure");
		backgroundHER2 = getResult("Mean");

		selectImage("finalMask");
		setAutoThreshold("Huang dark");
		run("Create Selection");
			run("Clear Results");	
		selectImage(ID4);
		run("Restore Selection");	
//		waitForUser("signalCheck");	
		run("Measure");
		signalHER2= getResult("Mean");
		areaHER2 = getResult("Area");
		print(signalHER2+","+areaHER2);
 		SBRHER2=signalHER2-backgroundHER2; //??????SBR= signal/background!!
 		if (SBRHER2<0){
 			SBRHER2=0;
 			}	
// 			waitForUser(her2Name+","+signalHER2+","+ backgroundHER2+","+SBRHER2+","+positionX+","+positionY);
		imageResults(her2Name,SBRHER2,positionX,positionY);


		//			roiManager("Deselect");

// 		close();	
		//......................................................
		run("Clear Results");
		selectImage("finalMask");
			setAutoThreshold("Huang dark");
		run("Create Selection");

		//......................................................

		//Cytokeratin signal measurement
		open(replace(path,nucleiName,cytokeratinName));
		ID5=getImageID();
run("Set Scale...", "distance=1 known="+pixelSize+" unit=um global");
		run("Set Measurements...","area mean standard modal min median area_fraction limit redirect=None decimal=6");
		run("Restore Selection");
//		resetMinAndMax();
//		setThreshold(0, 4095*0.90);//this line should be deleted
//		waitForUser("Check");
//		resetMinAndMax();

 		run("Measure");
// 		waitForUser("Check");
		signalCYTO = getResult("Mean");
		areaCYTO = getResult("Area");
		selectImage("backgroundMask");
			setAutoThreshold("Huang dark");
		run("Create Selection");

		run("Clear Results");
		areaCYTORatio=areaCYTO/(pixelSize*pixelSize*width*height);

		selectImage(ID5);
		run("Restore Selection");	
//		resetMinAndMax();
		run("Measure");

		backgroundCYTO= getResult("Mean");
//				waitForUser("signal Cyto"+signalCYTO+"; area Cyto"+areaCYTORatio+"; background"+backgroundCYTO);
		
 		SBRCYTO=signalCYTO-backgroundCYTO; //??????SBR= signal/background!!
 		contrastCYTO=SBRCYTO/(signalCYTO+backgroundCYTO);

 		if (SBRCYTO<0){
 			SBRCYTO=0;
 			}	
		
 			if ((signalCYTO<(maxCYTO/100))||(areaCYTORatio<0.01)||(contrastCYTO<-0.01)) {
 			SBRCYTO=0;
// 			waitForUser("signal Cyto"+signalCYTO+"; Max Cyto"+maxCYTO+"; Area cyto"+areaCYTORatio+"; Contrast"+contrastCYTO);//check here
 			out=true;
 			}
 				imageName=cytokeratinName;
		imageResults(imageName,SBRCYTO, positionX,positionY);
 					//	
 		selectImage(ID4);
 		NameID4=getTitle();
 		SharpBasedThreshold(NameID4, Threshold_Contrast, Contrast_Rescale_Factor, sharpen_radius, sharpen_weight, local_radius);
 		selectImage("Mask");
 		rename("realHER2");
 		setAutoThreshold("Default dark");
 		run("Create Selection");

 		run("Clear Results");
run("Measure");
areaCheck=getResult("Area");		
run("Clear Results");
areaCheck=areaCheck/(pixelSize*pixelSize);
//		waitForUser(widthroi);
 		if (areaCheck<(0.99*widthTile*heightTile)) {									//Otherwise there is no selection 
		roiManager("Add");

 			
 		maskROIposition=roiManager("Count")-1;
 		 		roiManager("Select", maskROIposition);
	roiManager("Rename", "sharpenedRedSignal");
}
else{ out=1;}
//		close();
 //		waitForUser(her2Name+","+signalCYTO+","+ backgroundCYTO+","+SBRCYTO+","+positionX+","+positionY);

		selectImage("finalMask");
			setAutoThreshold("Huang dark");
		run("Create Selection");

run("Clear Results");
run("Measure");
areaCheck=getResult("Area");		
run("Clear Results");
areaCheck=areaCheck/(pixelSize*pixelSize);
//		waitForUser(widthroi);
if (areaCheck<(0.99*widthTile*heightTile)) {									//Otherwise there is no selection 
		roiManager("Add");}
		else {out=1;
//		waitForUser(widthroi+""+widthTile);
		}
		
	//Treatment of redChannel


			ROITotal=roiManager("Count");
//waitForUser("");
		a=ROITotal-2;
		b=ROITotal-1;
		selection=newArray(a,b);	
			if (roiManager("Count")>1) 
			{roiManager("Select", selection);
				
			roiManager("AND");}																	//Intersection of roi defined by nuclei and red
//		waitForUser(her2Name+","+signalCYTO+","+ backgroundCYTO+","+SBRCYTO+","+positionX+","+positionY);

run("Clear Results");
run("Measure");
areaCheck=getResult("Area");		
run("Clear Results");
areaCheck=areaCheck/(pixelSize*pixelSize);
//		waitForUser(widthroi);
if (areaCheck<(0.99*widthTile*heightTile)) {									//Otherwise there is no selection 
		roiManager("Add");
		
		selectImage(ID4);		
		run("Duplicate...", "title=finalOutlineRed");
 		run("Set Drawing Color...");
 		c=roiManager("Count")-1;
 		roiManager("Select", c);	
		setForegroundColor(255, 255, 255); //mark red

	//			roiManager("Deselect");
		run("Draw", "slice");
		setForegroundColor(255, 255, 255);
	
		//......................................................
//		waitForUser("");
		imageCount = imageCount+1;
//		selectImage("redNonSpecific");
//		close();				
	selectImage("finalOutlineRed");

	saveAs("Tiff", output+"outline" +substring(list[i],0,lengthOf(list[i])-8)+(i-adjustingNumber4AlienFile)+"red.tif");
			selectImage("outline" +substring(list[i],0,lengthOf(list[i])-8)+(i-adjustingNumber4AlienFile)+"red.tif");
 close();
}
		else {cellNumber=0;
//		waitForUser(widthroi+""+widthTile);
		}
		selectImage("CytokeratinMaskComplementary");
		run("Create Selection");
		run("Clear Results");
run("Measure");
areaCheck=getResult("Area");		
run("Clear Results");
areaCheck=areaCheck/(pixelSize*pixelSize);
//		waitForUser(widthroi);
if (areaCheck<(0.99*widthTile*heightTile)) {	
		roiManager("Add");

		ComplementaryMaskROIPosition=roiManager("Count");
//		waitForUser("4");
		print(ComplementaryMaskROIPosition);
		roiManager("Select", ComplementaryMaskROIPosition-1);
//waitForUser(ROIplace);

}
else {out=1;}
selectedNuclei=newArray();



if ((cellNumber>0)&&(out==0)){
			for (k=0; k<cellNumber; k++) {  
				

//				waitForUser(" 1");
		run("Set Measurements...","area mean standard modal min integrated median area_fraction limit redirect=None decimal=6");
		run("Clear Results");		
//		selectImage("finalMask");
//				waitForUser(ComplementaryMaskROIPosition);
		ComplementaryMaskROIPosition1=ComplementaryMaskROIPosition-1;
				ROIcontrolk=ROIcontrol1+k;
//		waitForUser(ROIcontroli);
		ray=newArray(ComplementaryMaskROIPosition1,ROIcontrolk,maskROIposition);
//waitForUser(ray[1]);
//		roiManager("Select", ray);
//		roiManager("AND");
//		waitForUser(" before measure");
//		run("Measure");
//		pixelSumBackground=getResult("IntDen");
//		run("Clear Results");
//		signalArea=pixelSumBackground/255;
		run("Clear Results");
		selectImage(ID5);
		 //Call it Array it is not happy, put directly in the selection it is not happy...
		roiManager("Select", ray);
		roiManager("AND");											//select the area having both cytokeratim mask and inside the nucleus
//		waitForUser(" before measure");
		run("Measure");
		cellCytoSignal=getResult("Mean");
		cellCytoArea=getResult("Area");
		cellCytoArea=cellCytoArea/(pixelSize*pixelSize*widthTile*heightTile);
		run("Clear Results");
		selectImage("realHER2");

		selectImage("originalRedChannel");
			roiManager("Select", ray);
		roiManager("AND");
//		waitForUser(" before measure");
		run("Measure");
		cellHER2Signal=getResult("Mean");
		cellHER2Area=getResult("Area");
		cellHER2Area=cellHER2Area/(pixelSize*pixelSize*widthTile*heightTile);
			run("Clear Results");
	
	if ((cellHER2Area>0)&&(cellHER2Area<0.99)) {
run("Clear Results");
		roiManager("Select", ROIcontrolk);
		getSelectionBounds(ROI_x, ROI_y, ROIWidth, ROIHeight);
		run("Measure");
		cellTotalArea=getResult("Area");
		cellTotalArea=cellTotalArea/(pixelSize*pixelSize);
		run("Clear Results");
		selectedNuclei=Array.concat(selectedNuclei,ROIcontrolk);
		roiAfterk=roiAfter+k;
		cellName=Roi.getName;	
		print(ResultRecord, filename+";"+IJ.pad(i,4)+";"+signalHER2+" ;"+backgroundHER2+" ;"+signalCYTO+";"+backgroundCYTO +";"+cellName+" ;"+cellHER2Signal+";"+cellHER2Area+";"+cellCytoSignal+";"+cellTotalArea+";"+ROI_x+";"+ROI_y+";"+ROIWidth+";"+ROIHeight);

	}

			}
if (selectedNuclei.length<1) saveROI=0;
//run("Close All");
if (out==false) {


if (saveROI) {
	print(saveROI+", "+out); 
roiManager("Select",selectedNuclei);

roiManager("Save Selected", ROIplace+"tile_IHC"+IJ.pad(i-adjustingNumber4AlienFile,4)+".zip"); 	

}
}
}

//waitForUser("saveROI"+saveROI+"out"+out);
// (roiManager("Count")>0) {
//roiManager("reset");
//}
/* It was for detecting the segmentation from FISH image in order to align with IHC's but later I realized that we just need a factor of 2 in the relation between FISH ROI coordiates selected by the FISH image and the roi from IHC segmentation
title2 = getTitle();

getDimensions(width2, height2, channels2, slices2, frames2);
selectImage("DAPIchannel");
 run("Scale...", "x=2 y=2 z=1.0 width="+width2*2+" height="+height2*2+" depth=1 interpolation=Bilinear average create");
 rename("DAPIchannel_expanded");
 selectImage(ID1);
 run("Scale...", "x=2 y=2 z=1.0 width="+width2*2+" height="+height2*2+" depth=1 interpolation=Bilinear average create");
 rename("green_expanded");
  selectImage("originalRedChannel");
  run("Select None");
 run("Scale...", "x=2 y=2 z=1.0 width="+width2*2+" height="+height2*2+" depth=1 interpolation=Bilinear average create");
 rename("originalRedChannel_expanded");
 selectImage(NameIDM1);
 run("Scale...", "x=2 y=2 z=1.0 width="+width2*2+" height="+height2*2+" depth=1 interpolation=Bilinear average create");
 rename(NameIDM1+"_expanded");
 selectImage("redNonSpecific");
 run("Scale...", "x=2 y=2 z=1.0 width="+width2*2+" height="+height2*2+" depth=1 interpolation=Bilinear average create");
 rename("redNonSpecific_expanded");
 sizeFactor=2;
 ROIcontrol4=roiManager("Count");
saveROI=cellSegmentation("DAPIchannel_expanded", "green_expanded","originalRedChannel_expanded", NameIDM1+"_expanded", "redNonSpecific_expanded" ,ROIplace, filename, i, blueNoise, sizeFactor); //segmentation based on originImage can be improved
cellDetected=roiManager("Count")-ROIcontrol4;

selectedNuclei2=newArray(); //for the expanded image
*/
selectImage("originalRedChannel");
close();
selectImage("CytokeratinMaskComplementary");
close();
selectImage("finalMask");
close();
selectImage("backgroundMask");
close();
selectImage("CytokeratinMask");
close();

selectImage("greenBeforeTreatment");
close();

selectImage("redNonSpecific");
close();

close("*thresholdedNuclei*");
		selectImage("CytoNonSpecific");
		close();
selectImage(ID5);
close();
selectImage(IDN3);
close();
selectImage(""+replace(list[i],nucleiName,cytokeratinName));
close();
selectImage(NameIDM1);
close();
selectImage(ID2);
close();
selectImage(ID4);
close();
				selectImage("realHER2");
		close();
	selectImage("DAPIchannel");
	close();

close("*Sharp*");

close("*Result*");
//waitForUser("6 check the remaining image for closing");
}
else {
adjustingNumber4AlienFile=adjustingNumber4AlienFile++;}
		}
		
		File.close(ResultRecord);
		cancerArea=File.open(heatMap+File.separator+"cancerArea.txt"); 
     heatMapThreshold(her2Name,cytokeratinName,nucleiName, cancerArea);

  		selectImage(nucleiName);
	saveAs("Tiff", heatMap+substring(list[0],0,lengthOf(list[0])-4)+"_"+nucleiName+".tif");
		selectImage(her2Name);
		saveAs("Tiff",  heatMap+substring(list[0],0,lengthOf(list[0])-4)+"_"+her2Name+".tif");
		selectImage(cytokeratinName);
		saveAs("Tiff",  heatMap+substring(list[0],0,lengthOf(list[0])-4)+"_"+cytokeratinName+".tif");
		selectImage("greenHeatmapThresholded");
		saveAs("Tiff",  heatMap+substring(list[0],0,lengthOf(list[0])-4)+"_greenHeatmapThresholded.tif");

		setBatchMode(false);  
		showMessage("Job done");
} 

//work for all images?