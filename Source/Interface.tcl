######################################
## RSTTool
#
#  File: Interface.tcl
#  Author: Mick O'Donnell micko@wagsoft.com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/RSTTool/copyright.txt
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.


# RSTTool-Specific Code for setting up the Rsttool Interface


###############Make-Rsttool-Interface#######################

proc make-rsttool-interface {} {
    reset-interface
    make-rsttool-modebar
    reset-all
    install-interface structurer
}

###############ToolBar#######################

proc make-rsttool-modebar {} {

    def-interface segment "Text"  "Segment and Edit your Text"\
	    [make-segment-frame] install-segmenter uninstall-segmenter
    def-interface structurer "Structurer" "Edit Rhetorical Structure"\
	    [make-structurer-frame] install-structurer uninstall-structurer
    def-interface reledit  "Relations" "Edit the Relations set"\
	    [make-relations-frame] install-releditor
    def-interface stats "Statistics" "View simple states on the RST" [make-stats-frame]
    FileBarAdd .top.filebar.rstfile RST_FILE "RST File"
    FileBarAdd  .top.filebar.relfile RELATIONS_FILE "Relations File"
}

proc scroll-current-interface {delta event} {
    global CURRENT_INTERFACE


      if { $event > 1024 } {
	  set orient xview
      } else {
	  set orient yview
      }

    switch -- $CURRENT_INTERFACE {
	segment {
	    .segment.editor.text $orient scroll [expr (0 - $delta) / 120] units
	}

	structurer {
	    global RSTW 
	  
	    $RSTW $orient scroll [expr (0 - $delta) / 120] units
	}

	
	stats {
	    .stats.main.table $orient scroll [expr (0 - $delta) / 120] units
	}
    }
}


proc start-rsttool {} {
    # Sets up the buttons at the bottom of the Open dialog
    Toolbar .otbar horizontal
    pack .otbar -side bottom
    
    ToolbarItem .otbar "Import Text File"  ""  {
	destroy .c .otbar .credits
	make-rsttool-interface
	import-text
    } 2

    ToolbarItem .otbar "Load RST file" ""  {
	destroy .c .otbar .credits
	make-rsttool-interface
	load-rst
    } 2

    ToolbarItem .otbar "Quit" ""  {Quit} 2
}


