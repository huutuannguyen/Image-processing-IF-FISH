tileDimensionX=350;
tileDimensionY=350;
offset=50;
setBatchMode(false);
showMessage("You are running IHC sampling from an 3 channel image");
waitForUser("Please drag and drop the IHC image");
/*
run("Stack to RGB");

run("Split Channels");

run("Merge Channels...", "c1=[_IHC_original.tif (RGB) (red)] c2=[_IHC_original.tif (RGB) (green)] c3=[_IHC_original.tif (RGB) (blue)] create");
selectImage("Composite");
*/
titleIHC = getTitle();
dapiChannel = 3 ; 
greenDotChannel = 2 ; 
redDotChannel = 1 ;
run("Select None");
waitForUser("Please drag and drop the FISH image");
titleFISH = getTitle();
	Dialog.create("Please give the name of the sample");
	  Dialog.addString("Title:", substring(titleIHC,0,lengthOf(titleIHC)-4));
	Dialog.show();
codeIHC=Dialog.getString();
print(codeIHC);


waitForUser("Please open the folder to save IHC and FISH tiles");
folder = getDirectory("Folder");
folderIHC=folder+"IHC tiles/";

File.makeDirectory(folderIHC);
selectImage(titleFISH);

getDimensions(width, height, channels, slices, frames);
samplingNumberX=width/(tileDimensionX-offset);
samplingNumberY=height/(tileDimensionY-offset);
positionX=0;
positionY=0;
saveFolderBlue = folderIHC+"BlueChannelTIFS"+File.separator;
File.makeDirectory(saveFolderBlue);
saveFolderRed = folderIHC+"RedChannelTIFS"+File.separator;
File.makeDirectory(saveFolderRed);
saveFolderGreen = folderIHC+"GreenChannelTIFS"+File.separator;
File.makeDirectory(saveFolderGreen);
k=0;
//save the tile position

//showMessage("Where to store the tile position information?");
tilePosition = File.open(folder+"tile_info.txt"); // display file open dialog

//waitForUser("width"+width);

//waitForUser("height"+height);

folderFISH=folder+"FISH tiles/";
File.makeDirectory(folderFISH);
print(tilePosition, samplingNumberX+";"+samplingNumberY+";");
print(tilePosition, "IHC Tile name; FISH tile name; Position X; Position Y;");

//https://imagej.nih.gov/ij/developer/macro/functions.html
for (y=0; (y+1)<samplingNumberY; y++) {
	for (i=0; (i+1)<samplingNumberX; i++) {
		selectImage(titleIHC);
		makeRectangle(positionX/2, positionY/2, tileDimensionX/2, tileDimensionY/2);
		run("Duplicate...", "duplicate");
		rename("tileSelected");
		Stack.setChannel(dapiChannel);
 		run("Duplicate...", "duplicate channels="+dapiChannel);
		saveAs("Tiff", saveFolderBlue+codeIHC+" Blue_P"+IJ.pad(k,4)+".tif");
		close();	
		selectImage("tileSelected");
		Stack.setChannel(redDotChannel);
		run("Duplicate...", "duplicate channels="+redDotChannel);
		saveAs("Tiff", saveFolderRed+codeIHC+" Red_P"+IJ.pad(k,4)+".tif");
		close();
		selectImage("tileSelected");
		Stack.setChannel(greenDotChannel);
		run("Duplicate...", "duplicate channels="+greenDotChannel);
		saveAs("Tiff", saveFolderGreen+codeIHC+" Green_P"+IJ.pad(k,4)+".tif");	
		close();
		selectImage("tileSelected");
		close();
		k=k+1;
		positionX=positionX+tileDimensionX-offset;
		print(tilePosition, substring(titleIHC,0,lengthOf(titleIHC)-4)+"; "+ substring(titleFISH,0,lengthOf(titleFISH)-4)+";"+IJ.pad(k,4)+";"+ i+";"+ y);
		}
	positionY=positionY+tileDimensionY-offset;
	positionX=0;
	}

setBatchMode(false);

positionX=0;
positionY=0;
k=0;

File.makeDirectory(folderFISH+"TIFF"+File.separator);
codeFISH=replace(codeIHC,"IHC","FISH")
//https://imagej.nih.gov/ij/developer/macro/functions.html
for (y=0; (y+1)<samplingNumberY; y++) {
	for (i=0; (i+1)<samplingNumberX; i++) {
		selectImage(titleFISH);
		makeRectangle(positionX, positionY, tileDimensionX, tileDimensionY);
		run("Duplicate...", "duplicate");
		saveAs("Tiff", folderFISH+"TIFF"+File.separator+codeFISH+ " "+IJ.pad(k,4)+".tif");
		close();
		k=k+1;
		positionX=positionX+tileDimensionX-offset;
		}
	positionY=positionY+tileDimensionY-offset;
	positionX=0;
	}
	showMessage("Jobs done");
	
//change the tile size