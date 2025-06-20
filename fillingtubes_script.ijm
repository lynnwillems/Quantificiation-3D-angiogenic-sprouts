/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ File(label="Pixel classifier", style="file") pixel_class
#@ String (label = "File suffix", value = ".nd2") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.
//Parameters
filt_size = 3000;
closing_gap = 12;
auto_threshold = "Otsu"; //Otsu, Default, Huang
max_holefilling = 700000;
gpu = "NVIDIA GeForce RTX 3070";

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

//Extract a string from another string at the given input smaller string (eg ".")
function getBasename(filename, SubString){
  dotIndex = indexOf(filename, SubString);
  basename = substring(filename, 0, dotIndex);
  return basename;
}


function processFile(input, output, file) {
	//File and ROI names
	name = getBasename(file, ".nd2");
	
	//Open image
	run("Bio-Formats Importer", "open=[" + input + File.separator + file + "] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_1");
	
	getVoxelSize(width, height, depth, unit);
	image_prop = "channels=1 slices=" + nSlices + " frames=1 pixel_width=" + width + " pixel_height=" + height + " voxel_depth=" + depth;
	
	setMinAndMax(0, 4095);
	
	run("Run Pixel Classification Prediction", "projectfilename=" + pixel_class + " inputimage=" + file + " pixelclassificationtype=Segmentation");
	
	run("Properties...", image_prop);
	Stack.setXUnit(unit);
	
	setThreshold(255, 255);
	run("Convert to Mask", "background=Dark black");
	rename("binary");
	
	
	tube_filling("binary", filt_size, closing_gap, auto_threshold, max_holefilling, true);
	
	setBatchMode(false);
	
	saveAs("Tiff", output + File.separator + name + ".tif");
	
	//Close non important windows
	close("*");
	run("Collect Garbage");
	
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("Processing: " + input + File.separator + file);
	print("Saving to: " + output);
}

function distance_dilation_3D(image, closing_gap, batch_mode){
	selectWindow(image);
	if (batch_mode == "yes") {
		setBatchMode(true);
	}
	else {
		setBatchMode(false);
	}

	//Get calibration
	getVoxelSize(width, height, depth, unit);
	slices = nSlices;
	
	//3D dilation with distance transform
	run("Distance Transform 3D");
	setThreshold(-1000000000000000000000000000000.0000, (closing_gap));
	run("Convert to Mask", "method=Default background=Dark black");
	
	//Assign proper calibration
	Stack.setXUnit(unit);
	run("Properties...", "channels=1 slices=[slices] frames=1 pixel_width=[width] pixel_height=[width] voxel_depth=[depth]");
	
	return;
}

function distance_erosion_3D(image, closing_gap, batch_mode){
	selectWindow(image);
	if (batch_mode == "yes") {
		setBatchMode(true);
	}
	else {
		setBatchMode(false);
	}

	//Get calibration
	getVoxelSize(width, height, depth, unit);
	slices = nSlices;
	
	//Generate the inverted image
	run("Duplicate...", "duplicate");
	run("Invert", "stack");
	rename("inverted");
	
	//3D dilation with distance transform
	run("Distance Transform 3D");
	setThreshold(-1000000000000000000000000000000.0000, (closing_gap));
	run("Convert to Mask", "method=Default background=Dark black");
	
	//Assign proper calibration
	Stack.setXUnit(unit);
	run("Properties...", "channels=1 slices=[slices] frames=1 pixel_width=[width] pixel_height=[width] voxel_depth=[depth]");
	
	//Reinvert
	run("Invert", "stack");
	
	//Close in between steps
	close("inverted");
	
	return;
}

function size_filter_3D(image, minimum_size, maximum_size, batch_mode){
	selectWindow(image);
	if (batch_mode == "yes") {
		setBatchMode(true);
	}
	else {
		setBatchMode(false);
	}
	
	//Size filtering GPU
	
	//Call CLIJ2
	run("CLIJ2 Macro Extensions", "cl_device=[" + gpu + "]");
	Ext.CLIJ2_clear();
	
	// morpho lib j flood fill components labeling
	connected = "connected";
	Ext.CLIJ2_push(image);
	Ext.CLIJx_morphoLibJFloodFillComponentsLabeling(image, connected);
	
	// exclude labels outside size range
	filtered = "filtered";
	Ext.CLIJ2_excludeLabelsOutsideSizeRange(connected, filtered, minimum_size, maximum_size);
	Ext.CLIJ2_pull(filtered);
	
	//Binarize
	setThreshold(1, 1000000000000000000000000000000.0000);
	run("Convert to Mask", "method=Default background=Dark black");
	
	//Close in between steps
	Ext.CLIJ2_clear();
	
	return;
}

//Fills 3D holes of a certain size range in 3D
function fill_3D(image, minimum_size, maximum_size, batch_mode){
	if (batch_mode == "yes") {
		setBatchMode(true);
	}
	else {
		setBatchMode(false);
	}
	
	//Invert image
	selectWindow(image);
	run("Duplicate...", "duplicate");
	run("Invert", "stack");
	rename("inverted");
	
	size_filter_3D(image, minimum_size, maximum_size, batch_mode);
	rename("filtered");
	
	imageCalculator("Add create stack", image, "filtered");
	
	//Close in between steps
	Ext.CLIJ2_clear();
	close("inverted");
	close("filtered");
	
	return;
}


/*filt_size = 3000; //Filter size for small object to delete to clean the image
closing_gap = 12; //Estimated gap for closing the 3D holes
auto_threshold = "Otsu"; //Otsu, Default, Huang //If the image is not a binary. The auto threshold desired
max_holefilling = 700000; // Pixels for the minimum hole size
*/
function tube_filling(image, filt_size, closing_gap, auto_threshold, max_holefilling, batch_mode){
	selectWindow(image);
	if (batch_mode == "yes") {
		setBatchMode(true);
	}
	else {
		setBatchMode(false);
	}
	
	selectWindow(image);
	setAutoThreshold("Default dark no-reset");
	run("Convert to Mask", "background=Dark black");
	
	//Get calibration
	getVoxelSize(width, height, depth, unit);
	slices = nSlices;
		
	size_filter_3D(image, filt_size, 1000000000, "yes");
	rename("filtered");
	
	distance_dilation_3D("filtered", closing_gap, "yes");
	rename("dilation");
	
	fill_3D("dilation", 0, max_holefilling, "yes");
	rename("filled");
	
	distance_erosion_3D("filled", closing_gap+1, "yes");
	rename("filled_eroded_" + closing_gap);
	
	//Assign proper calibration
	Stack.setXUnit(unit);
	run("Properties...", "channels=1 slices=[slices] frames=1 pixel_width=[width] pixel_height=[width] voxel_depth=[depth]");

}		
