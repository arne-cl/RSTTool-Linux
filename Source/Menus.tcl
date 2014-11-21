######################################
## RSTTool 3.x
#
#  File: Menus.tcl
#  Author: Mick O'Donnell micko@wagsoft.com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/RSTTool/copyright.html
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.




##################################
# MENUS for RSTTool
##################################

proc make-menubar {} {
    global PLATFORM

    # Define the control key to use for each platform
    switch -- $PLATFORM {
	windows { set META_KEY "Control"}
	unix { set META_KEY "Meta"}
	default {set META_KEY "Meta"}
    }

    if [winfo exists .menuBAr] {destroy .menuBar}
    MenuBar .menuBar
    
    ##################
    # FILE
    
    Menu .menuBar File
    MenuItem .menuBar File "Load RST" {load-rst} $META_KEY-l
    MenuItem .menuBar File "Save RST" {save-rst} $META_KEY-s
    MenuItem .menuBar File "Save RST As..." {save-rst-as}

    MenuSeparator .menuBar File 
    MenuItem .menuBar File "Import Text" {import-text} $META_KEY-i
    MenuItem .menuBar File "Save Text As..." {save-text}
    MenuSeparator .menuBar File 
    MenuItem .menuBar File "Quit" {Quit}
    


    ##################
    # OPTIONS

    Menu .menuBar Structurer
    MenuItem .menuBar Structurer "Print Diagram" {global RSTW; myPrintCanvas $RSTW}
    MenuItem .menuBar Structurer "Save Diagram As..." {global RSTW; mySaveCanvas $RSTW}  
    MenuItem .menuBar Structurer "Capture Diagram to Clipboard" {global RSTW; myCaptureCanvas $RSTW}
    # MenuItem .menuBar Structurer "Print Subtree" {PrintSubtree}
    # MenuItem .menuBar Structurer "Save Subtree As..." {SaveSubtree}  
    # MenuItem .menuBar Structurer "Capture Subtree to Clipboard" {CaptureSubtree}


    ##################
    # OPTIONS

    Menu .menuBar Options
    MenuItem .menuBar Options "File Save Options..." {save-options}
    MenuItem .menuBar Options "Appearance Options..." {appearance-options}

    ##################
    # HELP
     
    Menu .menuBar Help
    MenuItem .menuBar Help "RSTTool Help" {
	global DIR
	help::init $DIR/Manual/HTML/rsttool.help
    } $META_KEY-h

    MenuItem .menuBar Help "RSTTool Help (HTML)" {
	global  DIR 
	show-webpage [file join $DIR "Manual" "HTML" "index.html"]
    }
    
    MenuItem .menuBar Help "About RSTTool" {aboutBox}
    MenuItem .menuBar Help "Release Notes" {
	global DIR
	set file [file join $DIR Release-Notes.txt]
	if ![file exists  $file] {
	    tell-user "Cannot find file: $file"
	} else {
	    set text [read-file $file]
	    scrolled-text-dialog .rn "RSTTool Release Notes" $text
	}
    }
    
    ##################
    # DEBUG

    Menu .menuBar Debug
    MenuItem .menuBar Debug "Reset Interface" {
	make-rsttool-interface
    }
    MenuItem .menuBar Debug "Reload Source" {
        global SRC SRC_FILES
	load-module $SRC $SRC_FILES
    }
    MenuItem .menuBar Debug "Reload Library" {
        global LIBRARY LIB_FILES
	load-module $LIBRARY $LIB_FILES
    }
    MenuItem .menuBar Debug "size" {puts "Window Geom: [wm geometry .] Maxsize: [wm maxsize .]"}
    MenuItem .menuBar Debug "Debug On" {global DEBUG; set DEBUG 1}
    MenuItem .menuBar Debug "Debug Off" {global DEBUG; set DEBUG 0}
    MenuItem .menuBar Debug "Hide Debug Menu" {hide-debug-menu}
    MenuItem .menuBar Debug "Eval" {
	set str [ask-user-for-string "Query?"]
	puts "Result: [eval $str]"
    }
    MenuItem .menuBar Debug "Show Console" {console show}

    hide-debug-menu

    ##############
    # BINDINGS
    bind all <Control-d> {show-debug-menu}
}


proc aboutBox {} {
    global TOOL_VERSION
    tk_messageBox -icon info -type ok -title "About RSTTool" -message \
	    "RSTTool Version $TOOL_VERSION\n
    Mick O'Donnell\n
    micko@wagsoft.com\n
    http:/www.wagsoft.com/RSTTool/"
}

proc hide-debug-menu {} {
    if {[.menuBar index "Debug"] > 0} {
	.menuBar delete "Debug"
    }
}

proc show-debug-menu {} {
 
    if ![catch {.menuBar index "Debug"}]  {return}
    .menuBar add cascade -menu .menuBar.debug -label "Debug" -underline 0

}

