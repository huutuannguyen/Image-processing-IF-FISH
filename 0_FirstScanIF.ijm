//Diego intergration code
var sharpen_radius=2; sharpen_weight=0.9; 

var Threshold_Contrast=50;
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
var pixelSize=1;

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
thresholded=0;
run("Clear Results");
run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel global");
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
//waitForUser("Check Threshold_Contrast in Local Contrast Image");
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
		thresholded=1;
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
return thresholded
}
//Key calculation function
//function thresholdWithCorrectionFactor Input (RGBimage, lower factor of the threshod) Output (thresholded image with a correction factor applied)
function thresholdWithCorrectionFactor(img, factorLower, min, max){
	selectImage(img);
	setAutoThreshold("Huang dark");


	getThreshold(lower,upper);
	
	print(lower+","+upper+","+min+","+max);
//		waitForUser("Huang");
//	waitForUser("");
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
	setAutoThreshold("Huang dark");
	run("Convert to Mask");
		getDimensions(width, height, channels, slices, frames);
		print(width, height, channels, slices, frames);
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
			run("Make Binary");					//Sometime it doesnt understand that this is a binary image
			run("Invert");
			run("Fill Holes");
//			waitForUser("beforeDilation");
			run("Erode");
			run("Erode");
			run("Erode");
			run("Dilate");
			run("Dilate");
			run("Dilate");
			run("Select None");
			setAutoThreshold("Huang dark");
			run("Create Selection");
			run("Set Measurements...", "area mean integrated display redirect=None decimal=6");
				selectImage(DAPIChannel);
			run("Duplicate...", "title=Noyau");
			run("Duplicate...", "title=thresholdedNuclei");
			setAutoThreshold("Huang dark");
			run("Convert to Mask");
							maskFromImage("thresholdedNuclei", redNonSpecificThresholded);
				selectImage(CytoChannel);
			run("Duplicate...", "title=membrane");
				selectImage(HER2Channel);
			run("Duplicate...", "title=HER2");
			selectWindow("Noyau");
			run("Gaussian Blur...", "sigma=3");
			
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
			rename("cellMask");
			run("8-bit");
			imageCalculator("Multiply create 32-bit", "Noyau","enhancedMembrane");
			selectWindow("Result of Noyau");
			run("16-bit");
			run("Restore Selection");
//						waitForUser("Before detection");
			run("Find Maxima...", "noise="+blueNoise+" output=[Point Selection]");
	//								waitForUser("After detection");
			selectWindow("Result of Noyau");
			run("Find Maxima...", "noise="+blueNoise+" output=[Segmented Particles]");
			//selectImage("Result of Nuclei Segmented");
			rename("SegmentedNuclei");
			imageCalculator("AND create 32-bit", "cellMask","SegmentedNuclei");
			rename("SegmentedCell");
			run("8-bit");
			ROIcontrol2=roiManager("Count");
			run("Analyze Particles...", "size="+200/sizeFactor+"-"+2000/sizeFactor+" pixel exclude add");
			voronoiNumber=roiManager("Count")-ROIcontrol2;
								count=0;
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
		if (((nucleiArea/(sizeFactor*sizeFactor))>200)||((nucleiArea/(sizeFactor*sizeFactor))<30)) {
			roiManager("Select", ROIcontrol2+i);
		roiManager("Delete");
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
		selectImage("cancerArea");
		close();
		selectImage("SegmentedCell");
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
	run("Close All");
	run("Collect Garbage");	
//https://imagej.nih.gov/ij/developer/macro/functions.html
	inDir = getDirectory("Choose input folder where there is IHC tiles"); 
	outDir = getDirectory("Choose output .txt folder"); 
setBatchMode(true);
	run("Set Measurements...", "area mean standard modal min median area_fraction limit redirect=None decimal=6");
  //	list = getFileList(inDir); 
  	
	HER2Channel=1;
	CytoChannel=2;
	DapiChannel=3;

/*
	for (z=0; z<list.length; z++) { 
if (endsWith(list[z],".TIF")){

		roiManager("reset");
			path = inDir+File.separator+list[z];
//	name = "";

			open(path);
			nameIF=getTitle();
		run("Set Scale...", "distance=1 known=0.645 unit=um global");
		
//waitForUser("Drag and drop IHC image");
		bigIHCimage = getTitle();
			run("Set Measurements...", "area mean standard modal min median area_fraction limit redirect=None decimal=6");
						getDimensions(widthTile, heightTile, channelsTile, slicesTile, framesTile);
						*/
Dialog.create("Give the first image number");
Dialog.addNumber("tile number:",0);
Dialog.show();			
firstImage=Dialog.getNumber();
Dialog.create("Give the image title");
Dialog.addString("Image title:","");
Dialog.show();			
bigIHCimage=Dialog.getString();
 				ResultRecord = File.open(outDir+"_resultLeft.txt"); // display file open dialog
resultTiles=outDir+File.separator;

		print(ResultRecord, "Title;cellHER2Signal;cellCytoSignal;cellTotalArea;positionX;positionY;ROI_x;ROI_y;ROIWidth;ROIHeight");
samplingNumberY=10;
samplingNumberX=10;
//tileDimensionX=widthTile/10;
//tileDimensionY=heightTile/10;
offset=0;

positionX=0;
positionY=0;
k=0;

//File.makeDirectory(inDir+substring(nameIF, 0,lengthOf(nameIF)-4)+File.separator);
/*
File.makeDirectory(outDir+substring(nameIF, 0,lengthOf(nameIF)-4)+File.separator);

	
//https://imagej.nih.gov/ij/developer/macro/functions.html
for (y=0; y<samplingNumberY; y++) {
	for (i=0; i<samplingNumberX; i++) {
		selectImage(nameIF);
		makeRectangle(positionX, positionY, tileDimensionX, tileDimensionY);
		run("Duplicate...", "duplicate");
		run("Select None");
		saveAs("Tiff", Tiles+IJ.pad(i,4)+"_"+IJ.pad(y,4)+".tif");

		close();
		k=k+1;
		positionX=positionX+tileDimensionX-offset;
		}
	positionY=positionY+tileDimensionY-offset;
	positionX=0;
	}
*/
	///___________
	list2 = getFileList(inDir); 
  	run("Close All");
  	Tiles=inDir;
	for (m=firstImage; m<list2.length; m++) { 		
				run("Collect Garbage");		
pos_i=abs(parseInt(m/10-0.5));
pos_y=m-pos_i*10;
				pathTile = Tiles+File.separator+IJ.pad(pos_i,4)+"_"+IJ.pad(pos_y,4)+".tif";
//	name = "";

			open(pathTile);	
			nameTile=getTitle();
			getDimensions(tileDimensionX,tileDimensionY,ch,sl,fr);
			widthTile=tileDimensionX*10;
			heightTile=tileDimensionY*10;
			i= parseInt(substring(nameTile, lengthOf(nameTile)-13,lengthOf(nameTile)-9));			
			y= parseInt(substring(nameTile, lengthOf(nameTile)-8,lengthOf(nameTile)-4));
			positionX=i*tileDimensionX;
			positionY=y*tileDimensionY;
		run("Set Scale...", "distance=1 known=0.645 unit=um global");
//			showMessage("Where to store the result?");

		selectImage(nameTile);
			run("Split Channels");
			redImageName=nameTile+" (red)";
			
			blueImageName=nameTile+" (blue)";
			
			greenImageName=nameTile+" (green)";
//			selectImage(bigIHCimage+" (blue)");
//redImageName="C"+HER2Channel+"-"+bigIHCimage;
			selectImage(redImageName);
			ID4=getImageID();
			run("Set Scale...", "distance=1 known=0.645 unit=um global");

			run("Duplicate...", "title=redNonSpecific");
			run("Duplicate...", "title=originalRedChannel");
	//		selectImage(bigIHCimage+" (green)");
//greenImageName="C"+CytoChannel+"-"+bigIHCimage;

			selectImage(greenImageName);

			run("Duplicate...", "title=greenBeforeTreatment");
	//		selectImage(bigIHCimage+" (blue)");
//blueImageName="C"+DapiChannel+"-"+bigIHCimage;
			selectImage(blueImageName);
			run("Set Scale...", "distance=1 known=0.645 unit=um global");

			selectImage("greenBeforeTreatment");
				run("Duplicate...", "title=CytokeratinMask");

//		thresholdWithCorrectionFactor("CytokeratinMask", factorCytokeratinMask, GreenMin, GreenMax); 					///////////maxCYTO is the maximum threshold level for cyto selection before reaching the autofluorescence

/*
run("Duplicate...", "title=CytoMask");					//to threshold negative Cytoarea
setAutoThreshold("Yen dark");
run("Convert to Mask");
waitForUser("Check CytoMask ");
run("Options...", "iterations=5 count=1 black edm=Overwrite do=Dilate");

run("Options...", "iterations=10 count=1 black edm=Overwrite do=Erode");

run("Options...", "iterations=5 count=1 black edm=Overwrite do=Dilate");
run("8-bit");
run("Divide...", "value=255.000");

imageCalculator("Multiply create 32-bit stack", "CytoMask" ,blueImageName);
waitForUser("Check CytoMask closeed");
close(blueImageName);
selectImage("Result of CytoMask");
rename(blueImageName);
waitForUser("Check blueImageName");*/
saveROI=SharpBasedThreshold("CytokeratinMask", Threshold_Contrast, Contrast_Rescale_Factor, sharpen_radius, sharpen_weight, local_radius);
		
close("*Sharp*");
close("CytokeratinMask");

 		selectImage("Mask");
 		rename("CytokeratinMask");
//waitForUser("check");
	setAutoThreshold("Default dark");
	run("Convert to Mask");
				
		run("Extend Image Borders", "left=3 right=3 top=3 bottom=3 fill=Black"); //To verify

		run("Options...", "iterations=3 count=1 black edm=Overwrite do=Dilate");

		run("Extend Image Borders", "left=-3 right=-3 top=-3 bottom=-3 fill=Black");
		NameIDM1=getTitle();
		
		//////////////Nuclei detection
//selectImage(bigIHCimage+" (blue)");
		selectImage(blueImageName);

		run("Set Scale...", "distance=1 known="+pixelSize+" unit=um global");
//		rename("treatedNuclei");
		ID2=getImageID();
nucleiNoise=1;
	run("Find Maxima...", "noise="+nucleiNoise+" output=[Segmented Particles]");
			rename("SegmentedNuclei");
		selectImage(ID2);	
		run("Find Maxima...", "noise="+nucleiNoise+" output=[Maxima Within Tolerance]");
	

			IDN1=getImageID();
		run("Extend Image Borders", "left=6 right=6 top=6 bottom=6 fill=Black"); //To verify

		run("Options...", "iterations=6 count=1 black edm=Overwrite do=Dilate");

		run("Extend Image Borders", "left=-6 right=-6 top=-6 bottom=-6 fill=Black");

//		waitForUser("Check");
		ROIcontrol1=roiManager("Count");
		rename("grayScaleOpenedNuclei");
//run("Watershed");

//		selectImage(blueImageName);

			
	imageCalculator("Multiply create", "SegmentedNuclei","grayScaleOpenedNuclei" );
		run("8-bit");
			imageCalculator("Multiply create", "Result of SegmentedNuclei","CytokeratinMask-ext-ext" );
rename("finalNucleiSegmented");
			
		run("Analyze Particles...", "size="+20+"-"+700+" pixel exclude add");	
//		run("Watershed");

//		ROIcontrol3=roiManager("Count");
//				waitForUser("Check 1");
//		run("Analyze Particles...", "size=100-5000 pixel circularity=0-1.00 add");

		cellNumber=roiManager("Count")-ROIcontrol1;
		run("Select None");
		run("Fill Holes");
		run("Watershed");	
//		run("Invert");	
		run("Duplicate...", "Image2.TIF");


		IDN2=getImageID();

		run("Extend Image Borders", "left=9 right=9 top=9 bottom=9 fill=Black"); //To verify
//		waitForUser(IDN2);		
		run("Options...", "iterations=9 count=1 black edm=Overwrite do=Dilate");
		IDN4=getImageID();	
//		waitForUser("");

		
		run("Extend Image Borders", "left=-9 right=-9 top=-9 bottom=-9 fill=Black");
	close("grayScaleOpenedNuclei");
		selectImage(IDN1);
		run("Invert");
		imageCalculator("Multiply create", IDN1,IDN4 );
//		waitForUser("Nuclei ring");
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
//	waitForUser("Check roi 3");

		
		//HER2 signal in the area surrounded the nuclei and in highly expressed cytokeratin area

close("*ext*");
		selectImage("finalMask");
		run("Select None");
//		run("Duplicate...", "title=CytokeratinMaskComplementary");
		
//	waitForUser("CytokeratinMaskComplementary");
//		run("Select None");
	//	run("Invert");
		
//		waitForUser("4");

//waitForUser(ROIplace);

		///////////////Red detection
		 		selectImage(ID4);
 		NameID4=getTitle();
 		SharpBasedThreshold(NameID4, Threshold_Contrast, Contrast_Rescale_Factor, sharpen_radius, sharpen_weight, local_radius);
 //				close("SegmentedNuclei*");

close("*Sharp*");
 		selectImage("Mask");
 		rename("realHER2");
 		setAutoThreshold("Default dark");
 	run("Convert to Mask");

	imageCalculator("Multiply create", "finalMask","realHER2");
	rename("HER2signal");

 		setAutoThreshold("Default dark");
 	run("Create Selection");
		wait(50);

		run("Measure");
		area=getResult("Area");
		area=area/(pixelSize*pixelSize*tileDimensionX*tileDimensionY);
//		waitForUser("widthTile"+widthTile+"pixelSize"+pixelSize+"tileDimensionY"+tileDimensionY+"tileDimensionX"+tileDimensionX+"area"+area));		
		if (area<0.99) {
		roiManager("Add");
	//Treatment of redChannel
 
maskROIposition=roiManager("Count")-1;
 			selectedNuclei=newArray();
	close("Result of*");
	close("CytokeratinMask");
	

close("realHER2");
close("finalMask");

close("originalRedChannel");
close("redNonSpecific");
close("greenBeforeTreatment");
close("C3-*");
			for (k=0; k<cellNumber; k++) {  
	//			checkK=((k/5)==parseInt(k/5));			//clear memory each 5 cells
	//			if (checkK) 		
				run("Collect Garbage");		

		run("Set Measurements...","area mean standard modal min integrated median area_fraction limit redirect=None decimal=6");
		run("Clear Results");		
//		selectImage("finalMask");
//				waitForUser(ComplementaryMaskROIPosition);
				ROIcontrolk=ROIcontrol1+k;
//		waitForUser(ROIcontroli);
		ray=newArray(ROIcontrolk,maskROIposition);
//waitForUser(ray[0]);
//		roiManager("Select", ray);
//		roiManager("AND");
//		waitForUser(" before measure");
//		run("Measure");
//		pixelSumBackground=getResult("IntDen");
//		run("Clear Results");
//		signalArea=pixelSumBackground/255;
		run("Clear Results");
//		selectImage(bigIHCimage+" (green)");

			selectImage(greenImageName);

							 //Call it Array it is not happy, put directly in the selection it is not happy...
		roiManager("Select", ray);
		roiManager("AND");											//select the area having both cytokeratim mask and inside the nucleus

		run("Measure");
		cellCytoSignal=getResult("Mean");
		run("Clear Results");
//	selectImage(bigIHCimage+" (red)");	
		selectImage(redImageName);
			roiManager("Select", ray);
		roiManager("AND");

		run("Measure");
		
		cellHER2Signal=getResult("Mean");
		cellHER2Area=getResult("Area");
		cellHER2Area=cellHER2Area/(pixelSize*pixelSize*widthTile*heightTile);
			run("Clear Results");
//			waitForUser("print results record"+cellHER2Area);


if ((cellHER2Area>0)&&(cellHER2Area<0.99)) {

		run("Clear Results");
		roiManager("Select", ROIcontrolk);
		getSelectionBounds(ROI_x, ROI_y, ROIWidth, ROIHeight);
		run("Measure");
		cellTotalArea=getResult("Area");
		cellTotalArea=cellTotalArea/(pixelSize*pixelSize);
		run("Clear Results");
		ROI_x=ROI_x+positionX;
		ROI_y=ROI_y+positionY;
		print(ResultRecord, bigIHCimage+";"+cellHER2Signal+";"+cellCytoSignal+";"+cellTotalArea+";"+positionX+";"+positionY+";"+ROI_x+";"+ROI_y+";"+ROIWidth+";"+ROIHeight);


	}
					run("Collect Garbage");		

			}
				}
				selectImage("HER2signal");
		saveAs("Tiff", resultTiles+nameTile+""+m+".tif");
				run("Collect Garbage");		

					run("Close All");

	}
			print(ResultRecord, "Done;");

						File.close(ResultRecord);
					run("Close All");
						
				run("Collect Garbage");	

					run("Collect Garbage");		


setBatchMode(false);
		showMessage("Job done");

		
			}
