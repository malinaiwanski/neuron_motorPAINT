#@ String (label="outputFolder") outputFolder
#@ Integer (label="i") i
#@ Float (label="threshold", value=0.8) threshold
#@ Float (label="overlap",value=0.6) overlap
#@ Float (label="snr",value=0.4) snr

import sys

from ij import IJ
from ij import WindowManager

import java.io.File as File

from fiji.plugin.trackmate import TrackMate
from fiji.plugin.trackmate import Model
from fiji.plugin.trackmate import SelectionModel
from fiji.plugin.trackmate import Settings
from fiji.plugin.trackmate import Logger
from fiji.plugin.trackmate.detection import LogDetectorFactory
from fiji.plugin.trackmate.tracking.overlap import OverlapTrackerFactory
from fiji.plugin.trackmate.gui.displaysettings import DisplaySettingsIO
from fiji.plugin.trackmate.visualization.hyperstack import HyperStackDisplayer
import fiji.plugin.trackmate.features.FeatureFilter as FeatureFilter
 


from fiji.plugin.trackmate.action import ExportTracksToXML
# We have to do the following to avoid errors with UTF8 chars generated in 
# TrackMate that will mess with our Fiji Jython.

sys.path.append('//HIVE3029/student_Hannah/')


#outputFolder = '//HIVE3029/student_Hannah/'



reload(sys)
sys.setdefaultencoding('utf-8')
	
	
# Get currently selected image

imp = WindowManager.getCurrentImage()
#imp = IJ.openImage('https://fiji.sc/samples/FakeTracks.tif')
#imp.show()

	
#-------------------------
# Instantiate model object
#-------------------------
	
model = Model()
	
# Set logger
model.setLogger(Logger.IJ_LOGGER)

logger = Logger.IJ_LOGGER

		
	
#------------------------
# Prepare settings object
#------------------------
	
settings = Settings(imp)
	
# Configure detector
settings.detectorFactory = LogDetectorFactory()
settings.detectorSettings = {
    'DO_SUBPIXEL_LOCALIZATION' : True,
    'RADIUS' : 5.,
    'TARGET_CHANNEL' : 1,
    'THRESHOLD' : threshold,
    'DO_MEDIAN_FILTERING' : False,
} 
	
	
# Configure tracker
settings.trackerFactory = OverlapTrackerFactory()
settings.trackerSettings = {
	    'SCALE_FACTOR' : 1.,
	    'MIN_IOU' : overlap,
	    'IOU_CALCULATION' : 'PRECISE',
}
	
	
# Add the analyzers for some spot features.
# Here we decide brutally to add all of them.
settings.addAllAnalyzers()
	
# We configure the initial filtering to discard spots 
# with a quality lower than 1.
settings.initialSpotFilterValue = 0.0
	
	
# Configure spot filters - Classical filter on quality
##filter1 = FeatureFilter('QUALITY', 1, True)
#settings.addSpotFilter(filter1)
filter2 = FeatureFilter('SNR_CH1', snr, True)
settings.addSpotFilter(filter2)
	
logger.log(str(settings))		
	

	
#----------------------
# Instantiate trackmate
#----------------------
	
trackmate = TrackMate(model, settings)
	
#------------
# Execute all
#------------
	
	
ok = trackmate.checkInput()
if not ok:
	sys.exit(str(trackmate.getErrorMessage()))
	
ok = trackmate.process()
if not ok:
	sys.exit(str(trackmate.getErrorMessage()))
	
	
	
#----------------
# Display results
#----------------
	
model.getLogger().log('Found ' + str(model.getTrackModel().nTracks(True)) + ' tracks.')
	
# A selection.
sm = SelectionModel( model )
	
# Read the default display settings.
ds = DisplaySettingsIO.readUserDefault()
	
# The viewer.
displayer =  HyperStackDisplayer( model, sm, imp, ds ) 
displayer.render()
	
	
	
	
#-----------------------------------
#Export detections and tracks as xml
#-----------------------------------
print(outputFolder, i)	
	
#outputFolder= "//HIVE3029/student_Hannah/"
outFile = File(outputFolder, "TM_LoG_Overlap_Tracks"+str(i)+".xml")
ExportTracksToXML.export(model, settings, outFile)

#model.getLogger().log( str( model ) )	

##runtrackmate(