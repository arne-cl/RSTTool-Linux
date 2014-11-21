#!/usr/local/bin/wish8.3


######################################
## RSTTool3.x
#
#  File: RSTTool.tcl
#  Author: Mick O'Donnell micko@wagsoft.com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/RSTTool/copyright.html
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.

######################################
# Warn if wrong TCL Version

if { $tcl_version < "8.1"} {
    tk_messageBox -message "Sorry, RSTTool requires Tcl/Tk 8.2 or above. See http://www.wagsoft.com/TCL/index.html to download."
    exit
}

if { $tcl_version < "8.2"} {
    tk_messageBox -message "You are using version $tcl_version of Tcl/Tk. It should work, but if you have problems, see http://www.wagsoft.com/TCL/index.html to download a newer version."
update
}


######################################
# Set VERSION/PLATFORM info

global TOOL TOOL_VERSION PLATFORM OPENING_GRAPHIC
set TOOL rsttool
set TOOL_VERSION "3.11 (March 29 2002)"
set PLATFORM $tcl_platform(platform)
set OPENING_GRAPHIC "rsttool1.gif"

if { $PLATFORM != "unix" } {console hide}
wm title . "RST Interface"

######################################
# Determine the root directory

global DIR ROOT SRC PICT_DIR

proc root-dir {} {
    if ![catch "info script"] {
	set dir [file dirname [info script]] 
	if { $dir != "." && $dir != ":"} {return $dir}
    } 

    if ![catch "file nativename [pwd]" result] {
	return $result
    } 

    return  [pwd]
}

if [info exists ::freewrap::patchLevel] {
    # This is the freewrapped version
    set APPTYPE exec
    set DIR [file dirname [info nameofexecutable]]
    set ROOT /MICK/RSTTOO~1/
} else {
    set APPTYPE script
    set DIR [root-dir]
    set ROOT $DIR
}


#########################
# Set Color defaults

global COLORS COLOR TEXT_FONT_FAMILY TEXT_FONT
set COLORS {red green blue black white yellow brown gray #FCD98E #F6C19E}
set COLOR(text) black
set COLOR(relation) red
set COLOR(span) green
set COLOR(background) "#FCD98E"
set COLOR(buttons) "#F6C19E"

######################################
# Load in preferences (if they exist)

global PREFS_FILE 
set PREFS_FILE [file join $DIR ".preferences"]

if [file exists $PREFS_FILE] {
    catch "source $PREFS_FILE"
}

tk_setPalette $COLOR(background)


######################################
# Load the modules

# Define the Dirs
global SRC SHARED LIBRARY RELS ANALYSES

set PICT_DIR [file join $ROOT Picts]
set SRC     [file join $ROOT Source]
set LIBRARY [file join $SRC Library]
set SHARED  [file join $SRC Shared]
set RELS    [file join $DIR Relation-Sets]
set ANALYSES [file join $DIR Analyses]


# Define the files
global SRC_FILES SHARED_FILES LIB_FILES 
set SHARED_FILES {Interface Help Import Segment load-xml Print-win-gdi} 
set LIB_FILES {tcl-extens tk-extens getvalue menuPackage\
         modal-dialog toolbar drawlib scrolled-text1 \
         scrolled-text-dial scrolled-listbox busydialog\
         draw-pdx bug-report maths popup-choose help}
set SRC_FILES {Globals Menus Options Interface StructWin Undo Structurer\
               Enter  Load Save Save3 RelationsFiles OldFormat Nodes Relations\
	       Stats Layout  Draw SSA Print Editrels}

if { $PLATFORM == "windows"} {
    lappend LIB_FILES tk_getOpenFix2
}

# Start the Load


source [file join $SHARED Opener.tcl]
source [file join $LIBRARY ProgressBar.tcl]

set fcount [llength [concat $LIB_FILES  $SHARED_FILES $SRC_FILES]]
open-load $fcount

load-module $LIBRARY $LIB_FILES
load-module $SHARED $SHARED_FILES
load-module $SRC $SRC_FILES
puts "All Files Loaded"

close-load
start-rsttool

# Add the rs2/rs3 extensions to the windows registry
if { $APPTYPE == "exec" && ![info exists REGISTERED] } {
    switch -- [ask-user "Do you want to associate RSTTool documents (.rs2, .rs3) with this application?"] {
	"yes" {
	    global ROOT REGISTERED
	    source $ROOT/Source/Library/registry.tcl
	    set exec [info nameofexecutable]
	    RegisterFileType .rs2 rsttool2File "RSTTool File (vers 2)" $exec
	    RegisterFileType .rs3 rsttool3File "RSTTool File (vers 3)" $exec
	    set REGISTERED 1
	}

	default {
	    set REGISTERED 0
	}
    }
    save-preferences
}


# hide-debug-menu
puts "RSTTool Launched Sucessfully"








