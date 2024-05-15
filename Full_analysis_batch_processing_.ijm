function full_MPAnalysis(x_bead,y_bead,diameter,nSDPSF,threshold,snr, overlap, path_OUT, path ){
	// Integer  x_bead 
	x_bead = parseInt(x_bead);
	// Integer  y_bead 
	y_bead = parseInt(y_bead);
	// Integer (value=55) diameter 
	diameter = parseInt(diameter);
	// Float (value=5) nSDPSF 
	nSDPSF = parseFloat(nSDPSF);
	// Float (value=0.7) threshold
	threshold = parseFloat(threshold);
	// Float (value=0.4) snr
	snr = parseFloat(snr);
	// Float (value=0.6) overlap
	overlap = parseFloat(overlap);
	
	//Mainfolder will automatically be filled with subfolders
	//path_OUT = getDirectory("Main folder");
	
	//Choose the folder with videos
	//path = getDirectory("Input directory");
	
	
	path_OUT = substring(path_OUT,0,lengthOf(path_OUT)-1);
	path_OUT = path_OUT+"_Analysis/";
	File.makeDirectory(path_OUT);
	
	//Fast temporal median options
	fastFrameWind=10;
	slowFrameWind=300;
	suffix = ".tif";
	
	//DoM Detection parameters for Bead tracking
	
	nSNR = 15.0;

	//Reconstruction parameters
	nMaxLocalization = 20;
	nPxRecon = 20;
	
	
	list = getFileList(path);
	
	for (i = 0; i < list.length; i++)
	
	{
		
		if(endsWith(list[i], suffix))
		
		{
			filename=list[i];
			filenamefull = path+list[i];
			print("Open file:");
			print(filenamefull);
			
			filenamebase = substring(filename,0,lengthOf(filename)-lengthOf(suffix));
			print(filenamebase);
			output_subfolder = substring(filename,0,12);
			if  (i == 0)
			{
				File.makeDirectory(path_OUT+output_subfolder);
				subpath_OUT = path_OUT+output_subfolder+"/";
				//This is output folder for this sample, cell and ROI
				print("Output path where all results will be saved:");
				print(subpath_OUT);
			}
			//open file
			print("Open video part..");
			//Note that files are opened in the order 0,1,10,11 etc so the number of the file is extracted to keep track of the actual order such that results are saved properly
			if (matches(filenamebase, ".*Pos0.ome")) {num = 0;} else
			if (matches(filenamebase, ".*Pos0_[0-9].ome")) {num = substring(filenamebase,lengthOf(filenamebase)-5,lengthOf(filenamebase)-4 );} else
			if (matches(filenamebase, ".*Pos0_[0-9][0-9].ome")) {num = substring(filenamebase,lengthOf(filenamebase)-6,lengthOf(filenamebase)-4);}
			print(num);
			open(filenamefull);
			
			//get file ID
			openImageID=getImageID();
			origTitle=getTitle();
			Wpx = getWidth();
			Hpx = getHeight();
			nFrameN = nSlices;
			
			print(Wpx,Hpx, nFrameN);
			
			//Adjust scale and properties
			run("Properties...", "channels=1 slices=1 frames="+toString(nFrameN)+" pixel_width=1.0000 pixel_height=1.0000 voxel_depth=1.0000 frame=[1 frame] global");
			run("Set Scale...", "distance=1 known=1 unit=pixel global");
			print("Adjusted Properties");
			Wpx = getWidth();
			Hpx = getHeight();
			nFrameN = nSlices;
			print("Width, Height, Frame number, pixel size is now 1, frame number is time axes");
			print(Wpx,Hpx, nFrameN);
	
	        print(x_bead);
			//DoM Bead Tracking 
			//Draw ROI over bead of interest
			print("Bead Tracking...");
			x_coordinate = x_bead-(diameter*0.5);
			y_coordinate = y_bead-(diameter*0.5);
			print(x_coordinate, y_coordinate);
			makeOval(x_coordinate , y_coordinate , diameter, diameter);
			roiManager("Add");
			roiManager("Select", 0);
			roiManager("Save", subpath_OUT +"BeadROI.roi");
			run("Detect Molecules", "task=[Detect molecules and fit] psf="+toString(nSDPSF)+" intensity="+toString(nSNR)+" pixel=65 parallel=500 fitting=5");
			selectWindow("Results");
			resFilename = subpath_OUT +"Beads_Results_"+toString(num)+".csv";
			saveAs("Results", resFilename);
			close("Results");
			
			
			//Median filtering 
			print("Fast temporal median filtering...");
			//ORIGINAL
			//MAke sure nothing is selected such that the whole fov is duplicated
			run("Select None");
			run("Duplicate...", "title=medi_20 duplicate");
			run("Use Opened Image and Run", "window="+toString(fastFrameWind)+" begin=1 end=0 file=tif show output=[]");		
			print("Fast temporal median filtered the video with fast frame window",fastFrameWind);
			medi20ID = getImageID();
			medi20 = getTitle();
			
			//subtract
			imageCalculator("Subtract create stack", origTitle, medi20);
			print("Subtracted filtered stack from Original");
			subtract20ID=getImageID();
			//close median
			selectImage(medi20ID);
			close();
			//close original
			selectWindow(origTitle);
			close();
			
			//SUBTRACTED
			selectImage(subtract20ID);
			run("Use Opened Image and Run", "window="+toString(slowFrameWind)+" begin=1 end=0 file=tif show output=[]");		
			print("Fast temporal median filtered the subtracted image with slow frame window",slowFrameWind);
			subtract20ID=getImageID();
			
			
			//TrackMate detection and tracking 
			print("Detection and Tracking of Motor...");
			//print("Run TrackMate with LoG detection intial threshold: "+toString(threshold)+" and Signal to noise filter "+toString(snr)+" minimal Overlap for tracking "+toString(overlap)+"");
			run("TM LoG Overlap", "outputfolder="+toString(subpath_OUT)+" i="+toString(num)+" threshold="+toString(threshold)+" overlap="+toString(overlap)+" snr="+toString(snr)+"");
			//run("TM LoG Overlap", "outputfolder="+toString(subpath_OUT)+" i="+toString(i)+" threshold=0.5 overlap=0.6 snr=0.4");
			
			path_and_xml_file = ""+toString(subpath_OUT)+"TM_LoG_Overlap_Tracks"+toString(num)+".xml";
			print(path_and_xml_file);
			//Convert xml to Results.csv
			run("TrackMate import", "open="+toString(path_and_xml_file)+" pixel=1");
			//Open xml
			run("Detect Molecules", "task=[Fit detected molecules] psf=1.8 intensity=2 pixel=65 parallel=500 fitting=3 mark");
			
			//Save Results
			selectWindow("Results");
			resFilename = subpath_OUT + "Results_"+toString(num)+".csv";
			saveAs("Results", resFilename);
			
			//Reconstruct
			run("Reconstruct Image", "for=[All particles] pixel="+toString(nPxRecon)+" width="+toString(Wpx)+" height="+toString(Hpx)+" sd=[Localization precision] value=10 cut-off cut="+toString(nMaxLocalization)+" x_offset=0 y_offset=0 range=1-10 render=Z-stack z-distance=100 lut=Fire z=0 z_0=0");
			reconstructID=getImageID();
			reconFilename =  subpath_OUT + "Reconstruction_"+toString(num)+".tif";
			saveAs("Tiff", reconFilename);
					
			
			//Close the images, videos and Results table
			run("Close All");
			close("Results");
			
			print("Done with video number",num);
			
		}
	
	}
	print("Fully DONE");
	selectWindow("Log");
	saveAs("Text", subpath_OUT +"Log.txt");
	close("log");
	
	//Open all reconstructions and stack and max project them
	list = getFileList(subpath_OUT);
	
	for (i = 0; i < list.length; i++)
	
	{
		
		if(endsWith(list[i], suffix))
		
		{
			filename=list[i];
			filenamefull = subpath_OUT+list[i];
			open(filenamefull);
		}
	}
			
	run("Images to Stack", "use");
	stacks = getTitle();
	run("Z Project...", "projection=[Max Intensity]");
	MAX_project = getTitle(); 
	maxFilename = subpath_OUT + "MAX_projection_Reconstructions.tif";
	saveAs("Tiff", maxFilename);
	
	//Clean up for next round
	roiManager("Delete");
	run("Close", stacks);
	run("Close", stacks);
	
}
open("F:/PERSONAL/Malina/NanoscopeII/mP_LastRound/Analysis_parameters_v1.csv");
Table.rename("Analysis_parameters_v1.csv", "Results");
number = 0;
end = nResults();
for (i = 0; i < end; i++){
	open("F:/PERSONAL/Malina/NanoscopeII/mP_LastRound/Analysis_parameters_v1.csv");
	Table.rename("Analysis_parameters_v1.csv", "Results");
	
	
	x  = getResultString("x_bead", number);
	y  = getResultString("y_bead", number);
	d  = getResultString("diameter", number);
	n  = getResultString("nSDPSF", number);
	t  = getResultString("threshold", number);
	s  = getResultString("snr", number);
	o  = getResultString("overlap", number);
	
	pOUT  = getResultString("path_OUT", number);
	p     = getResultString("path", number);
	print(number, i, "out of", nResults());
	full_MPAnalysis(x  ,y ,d ,n, t ,s , o , pOUT , p);
	
	number = number +1;
	
}
print("DONE :)");
