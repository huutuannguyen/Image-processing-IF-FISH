waitForUser("Drag and drop the smaller FISH image for alignment");
title1 = getTitle();
	run("Color Balance...");
	resetMinAndMax();
getDimensions(width1, height1, channels1, slices1, frames1);
	reverse_Image=getBoolean("Do you want FISH image inversion?");	
	if (reverse_Image) {
		selectImage(title1);
run("Rotate... ", "angle="+ 180 +" grid=0 interpolation=Bilinear stack");
	}
	selectWindow(title1);
		run("Color Balance...");
	resetMinAndMax();
	rightOrder1=getBoolean("Is the color order is red, green blue?");	
if (rightOrder1==0) {
	run("Split Channels");
	waitForUser("put back the order Red Green Blue");
	run("Merge Channels...", "c1=[C2-"+title1+"] c2=[C1-"+title1+"] c3=[C3-"+title1 +"] create");
	rename(title1);
}
//title1 = getTitle();
//getDimensions(width1, height1, channels1, slices1, frames1);
	selectWindow(title1);
	Stack.setChannel(1);
	run("Color Balance...");
	resetMinAndMax();
	Stack.setChannel(2);
	run("Color Balance...");
	resetMinAndMax();
		Stack.setChannel(3);
	run("Color Balance...");
	resetMinAndMax();
	selectImage(title1);
		run("Scale...", "x=0.25 y=0.25 z=1.0 width="+width1/4+" height="+height1/4+" depth=3 interpolation=Bilinear average create");

	rename(title1+"_resized");


dapiChannel = 3 ; 
greenDotChannel = 2 ; 
redDotChannel = 1 ;

waitForUser("Drag and drop 2x2binning IHC image to align with the FISH image");
title2half = getTitle();
	rightOrder2=getBoolean("Is the color order is red, green blue?");	
if (rightOrder2==0) {
	run("Split Channels");
	waitForUser("put back the order Red Green Blue");
	run("Merge Channels...", "c1=[C1-"+title2half+"] c2=[C2-"+title2half+"] c3=[C3-"+title2half +"] create create ignore");
}
selectImage(title2half);
getDimensions(width2, height2, channels2, slices2, frames2);
//	run("Scale...", "x=2 y=2 z=1.0 width="+width2*2+" height="+height2*2+" depth=3 interpolation=Bilinear average create");


//getDimensions(width2, height2, channels2, slices2, frames2);

selectWindow(title2half);
	run("Scale...", "x=0.5 y=0.5 z=1.0 width="+width2/2+" height="+height2/2+" depth=3 interpolation=Bilinear average create");
	rename(title2half+"_resized");
	Stack.setChannel(dapiChannel);
	run("Color Balance...");
	resetMinAndMax();
	Stack.setChannel(greenDotChannel);
	run("Color Balance...");
	resetMinAndMax();
		Stack.setChannel(redDotChannel);
	run("Color Balance...");
	resetMinAndMax();
translation_happy=false;
//waitForUser("check alignment");
//	translation=getBoolean("Do you want excecute the translation correction?");
waitForUser("Please open the folder to save aligned FISH and IHC images");
folder = getDirectory("Folder");
saveFolderAligned = folder+"aligned"+File.separator;
File.makeDirectory(saveFolderAligned);

	translation=true;
if (translation==true) {	

	while (translation_happy==false) {
		selectWindow(title1+"_resized");
		run("Duplicate...", "duplicate channels="+dapiChannel);
rename("DAPI_1st_image");

selectWindow(title2half+"_resized");
run("Duplicate...", "duplicate channels="+dapiChannel);
rename("DAPI_2nd_image");
run("Concatenate...", "  title=[Concatenated Stacks] image1=[DAPI_1st_image] image2=[DAPI_2nd_image] image3=[-- None --]");

//setTool("zoom");
//setTool("rectangle");
Stack.setSlice(2);
getDimensions(width3, height3, channels3, slices3, frames3);
makeRectangle(width3/4, height3/4 , width3/2, height3/2);              //Alignment based on 1/4 of an image
waitForUser("select the area for the alignment in the bigger IHC DAPI image");
getSelectionBounds(selection_x, selection_y, selectionWidth, selectionHeight);
run("Align slices in stack...", "method=5 windowsizex="+round(selectionWidth)+" windowsizey="+round(selectionHeight)+" x0="+round(selection_x)+" y0="+round(selection_y)+" swindow=0 subpixel=false itpmethod=0 ref.slice=1 show=true"); //If not round it has error
//setTool("zoom");

translation_X=getResult("dX");
translation_Y=getResult("dY");
waitForUser ("check alignment");
	selectImage("Concatenated Stacks");
close();
selectWindow(title2half);
print("translationVectorX "+translation_X*2); 
print("translationVectorY "+translation_Y*2);
//waitForUser("before translation");
run("Translate...", "x="+(translation_X*2)+" y="+(translation_Y*2)+" interpolation=None stack");
selectWindow(title2half+"_resized");
run("Translate...", "x="+(translation_X)+" y="+(translation_Y)+" interpolation=None stack");

//makeRectangle(0, 0, width1, height1);
//run("Crop");
	selectWindow(title1+"_resized");
run("Duplicate...", "title=FISH duplicate");
run("Split Channels");
selectWindow(title2half+"_resized");
run("Duplicate...", "title=IHC duplicate");
run("Split Channels");

run("Concatenate...", "  title=[Concatenated Stacks] image1=[C1-FISH] image2=[C2-FISH] image3=[C3-FISH] image4=[C1-IHC] image5=[C2-IHC] image6=[C3-IHC] image7=[-- None --]");
run("Grays");
rotat_happy=false;
//waitForUser("check alignment");
	rotat=getBoolean("Do you want an additional rotation?");	
if (rotat==true) {
	

	while (rotat_happy==false) {

setTool("point");
waitForUser("Choose now 1st points of the FISH image for the alignement");
getSelectionCoordinates(x11, y11);
print("Position 11 "+x11[0] +" "+ y11[0]); 
waitForUser("Choose now 1st points of the IHC image for the alignement");
getSelectionCoordinates(x21, y21);
print("Position 21 "+x21[0] +" "+ y21[0]); 

waitForUser("Choose now 2nd points of the FISH image for the alignement");
getSelectionCoordinates(x12, y12);
print("Position 12 "+x12[0] +" "+ y12[0]); 
waitForUser("Choose now 2nd points of the IHC image for the alignement");
getSelectionCoordinates(x22, y22);
print("Position 22 "+x22[0] +" "+ y22[0]); 

Vector1x=(x12[0]-x11[0])/sqrt(pow((x12[0]-x11[0]),2)+pow((y12[0]-y11[0]),2));// dont use ^ as a power be ause fiji don't understand
Vector1y=(y12[0]-y11[0])/sqrt(pow((x12[0]-x11[0]),2)+pow((y12[0]-y11[0]),2));
Vector2x=(x22[0]-x21[0])/sqrt(pow((x22[0]-x21[0]),2)+pow((y22[0]-y21[0]),2));
Vector2y=(y22[0]-y21[0])/sqrt(pow((x22[0]-x21[0]),2)+pow((y22[0]-y21[0]),2));
teta=atan((Vector2x*Vector1y-Vector2y*Vector1x)/(Vector1x*Vector2x+Vector1y*Vector2y));
//newReferencePositionX=(x21[0]-x11[0]*cos(teta)-y11[0]*sin(teta));
//newReferencePositionY=(y21[0]+x11[0]*sin(teta)-y11[0]*cos(teta));
//newCenterPositionX=newReferencePositionX+width1*cos(teta)/2+height1*sin(teta)/2; //O'O vector=O'X+XO
//newCenterPositionY=newReferencePositionY-width1*sin(teta)/2+height1*cos(teta)/2;
//translationVectorX=x11[0]+cos(teta)*newReferencePositionX-sin(teta)*newReferencePositionY-cos(teta)*x21[0]+sin(teta)*y21[0]; 
//translationVectorY=y11[0]+sin(teta)*newReferencePositionX+cos(teta)*newReferencePositionY-sin(teta)*x21[0]-cos(teta)*y21[0]; //center to center translation
//centerOffsetX= //OC'in XY ref: off set from the image of C' in the first image to the center of the image 
//centerOffsetX=-cos(teta)*newCenterPositionX+sin(teta)*newCenterPositionY+width2*cos(teta)/2-sin(teta)*height2/2;
//centerOffsetY=-sin(teta)*newCenterPositionX-cos(teta)*newCenterPositionY+width2*cos(teta)/2+cos(teta)*height2/2;


selectWindow(title2half+"_resized");
//run("Translate...", "x="+(-centerOffsetX)+" y="+(-centerOffsetY)+" interpolation=None stack");
//waitForUser("angle"+(teta*360/(2*PI)));
run("Rotate... ", "angle="+ (teta*360/(2*PI)) +" grid=0 interpolation=Bilinear stack");

//selectWindow(title2);
//run("Rotate... ", "angle="+ (teta*360/(2*PI)) +" grid=0 interpolation=Bilinear stack");

selectWindow(title2half);
run("Rotate... ", "angle="+ (teta*360/(2*PI)) +" grid=0 interpolation=Bilinear stack");

	selectImage("Concatenated Stacks");
close();
	selectWindow(title1+"_resized");
run("Duplicate...", "title=FISH duplicate");
run("Split Channels");
selectWindow(title2half+"_resized");
run("Duplicate...", "title=IHC duplicate");
run("Split Channels");

run("Concatenate...", "  title=[Concatenated Stacks] image1=[C1-FISH] image2=[C2-FISH] image3=[C3-FISH] image4=[C1-IHC] image5=[C2-IHC] image6=[C3-IHC] image7=[-- None --]");
run("Grays");
waitForUser("Check rotation");
	rotat_happy=getBoolean("Are you happy with the rotation?");	

	}
}
selectImage("Concatenated Stacks");
close();

	translation_happy=getBoolean("Are you happy with the translation? If not another translation correction will be lauched again");			
	}
}

//selectImage(title2);
//makeRectangle((width2-width1)/2, (height2-height1)/2, width1, height1);
selectWindow(title2half);


makeRectangle((width2*2-width1)/4, (height2*2-height1)/4, width1/2, height1/2);

run("Crop");	
run("Select None");
waitForUser("Please select the Region of interest (ROI) in the IF image");
getSelectionBounds(x,y,W,L);


selectWindow(title1);
makeRectangle(x*2, y*2, W*2, L*2);
cropNow=getBoolean("Do we crop?");
if (cropNow) run("Crop");	
selectWindow(title2half);
if (cropNow) run("Crop");
selectWindow(title1);
saveAs("Tiff", saveFolderAligned+"_FISH.tif");
//close();
//selectWindow(title2);
//saveAs("Tiff", saveFolderAligned+"_IHC_expanded.tif");
//close();
selectWindow(title2half);
saveAs("Tiff", saveFolderAligned+"_IHC_original.tif");
close("*_resized");
showMessage("Jobs done");	