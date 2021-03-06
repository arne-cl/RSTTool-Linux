######################################
## RSTTool3.x
#
#  File: Interface.tcl
#  Author: Mick O'Donnell micko@wagsoft.com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/RSTTool/copyright.html
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.


####################################################		   
# Define The RST Frame


proc make-structurer-frame {} {
    global RSTW
    if [winfo exists .structurer] {destroy .structurer}
    frame .structurer

    make-structurer-toolbar

    frame .structurer.frame
    set RSTW [canvas  .structurer.frame.canvas  -bg white -relief sunken\
      -yscrollcommand ".structurer.frame.yscroll set"\
      -xscrollcommand ".structurer.frame.xscroll set"]
    scrollbar .structurer.frame.yscroll -orient vertical\
        -command ".structurer.frame.canvas yview"
    scrollbar .structurer.frame.xscroll -orient horizontal\
        -command ".structurer.frame.canvas xview"

 

    # Pack the Elements
    pack .structurer.frame.yscroll -side right -fill y 
    pack .structurer.frame.xscroll -side bottom -fill x
    pack .structurer.frame.canvas -fill both -expand 1 -side left

    pack .structurer.tbar -side left  -anchor nw
    pack .structurer.frame -side top -fill both -expand true
    return .structurer
}

proc install-structurer {} {
    global RSTW
    redraw-rst
    set-mode link
    bind . <Right>  "$RSTW xview scroll 1 page"
    bind . <Left> "$RSTW xview scroll -1 page"
    bind . <Up>  "$RSTW yview scroll -11 page"
    bind . <Down> "$RSTW yview scroll 1 page"
}


proc uninstall-structurer {} {
    bind . <Right>  {}
    bind . <Left>  {}
    bind . <Up>  {}
    bind . <Down>  {}
}

   


####################################################		   
# Define The Modes toolbar

proc make-structurer-toolbar {} {

  if {[winfo exists .structurer.tbar]} {destroy .structurer.tbar}
  frame .structurer.tbar
  label .structurer.tbar.modetext   -text "Modes" -fg red


  Toolbar .structurer.tbar.mode
  ToolbarItem .structurer.tbar.mode  "Link"  "Click to enter Link mode" {set-mode link}
  ToolbarItem .structurer.tbar.mode  "Unlink" "Click to enter Unlink mode" {set-mode unlink}
  ToolbarItem .structurer.tbar.mode  "Collapse/Expand" "Click to enter Collapse/Expand mode"\
	  {set-mode collapse/expand}

  # Define The ACTION toolbar
  label .structurer.tbar.actiontext -text "Actions" -fg red
  Toolbar .structurer.tbar.action
  ToolbarItem .structurer.tbar.action  "Add Span" "After clicking, select node to add span over" {set-mode span}
  ToolbarItem .structurer.tbar.action  "Add MultiNuc" "After clicking, select node to add multinuc node over" {set-mode multinuc}
  ToolbarItem .structurer.tbar.action  "Add Schema" "After clicking, select node to add Schema over" {set-mode schema}
  ToolbarItem .structurer.tbar.action  "Save PS" "Click here to save ps file" {
          tell-user "Click on the top node of the RST subtree to save"
          set-mode saveps
  }
  ToolbarItem .structurer.tbar.action  "Save PDX" "Click here to save PDX file" {savepdx}
  ToolbarItem .structurer.tbar.action  "Print Canvas" "Click here to send canvas to printer" {
      global RSTW
      print-canvas $RSTW
  }

  ToolbarItem .structurer.tbar.action  "Undo" "Click here to undo last action" {undo}
  ToolbarItem .structurer.tbar.action  "Redo" "Click here to redo last action" {redo}

  ToolbarItem .structurer.tbar.action  "Orientation" "Click here to switch Diagram orientation" {toggle-orientation}
  label .structurer.tbar.comment   -text "------------" -fg red -textvariable COMMENT

  pack .structurer.tbar.modetext .structurer.tbar.mode \
	  .structurer.tbar.actiontext .structurer.tbar.action -side top 
}

# managing modes
proc set-mode {mode} {
    global RSTW STRUCTMODE
    . config -cursor {}
    if ![info exists STRUCTMODE] { set STRUCTMODE link }
    struct-toggle-button $STRUCTMODE "raised"
    set STRUCTMODE $mode
    struct-toggle-button $STRUCTMODE "sunken"
    
    # reset default bindings
    bind $RSTW <ButtonPress-1> {}
    $RSTW bind nodes <Button-1> {}
    
    switch -- $mode {
	link   { 
	    $RSTW config -cursor sb_h_double_arrow
	    $RSTW bind nodes <Button-1> {}
	    bind $RSTW <Shift-ButtonPress-1> {
		set SHIFTCLICKED [clicked-node %x %y]
	    }
	    bind $RSTW <ButtonPress-1> {
		global SHIFTCLICKED CURRENT_SAT
		if  { $SHIFTCLICKED == -1 } {
		    select-satelite [clicked-node %x %y]
		} else {
		    # link nodes
		    set CURRENT_SAT $SHIFTCLICKED
		    select-nucleus [clicked-node %x %y]
		    set SHIFTCLICKED -1
		}		
	    }
	    bind $RSTW <ButtonRelease-1> {
		global SHIFTCLICKED
		if { $SHIFTCLICKED == -1 } {
		    select-nucleus [clicked-node %x %y]
		}
	    }
	}
	      
	unlink { 
	    $RSTW config -cursor X_cursor
	    bind $RSTW <ButtonRelease-1> {
		change-structure unlink-node [clicked-node %x %y]
	    }
	}
	
	saveps {
	    bind $RSTW <ButtonRelease-1> {
		save-subtree-as-ps  [clicked-node %x %y]
	    }
	    $RSTW config -cursor top_side
	}

	savepdx {
	    bind $RSTW <ButtonRelease-1> {
		save-subtree-as-pdx  [clicked-node %x %y]
	    }
	    $RSTW config -cursor top_side
	}
	
	collapse/expand {
	    bind $RSTW <ButtonRelease-1> {
		change-structure collapse-expand [clicked-node %x %y]
	    }
	    $RSTW config -cursor sb_v_double_arrow
	}
	
	default {
	    bind $RSTW <ButtonRelease-1> {
		change-structure insert-node  [clicked-node %x %y]
	    }
	    $RSTW config -cursor top_side
	}
    }
}



proc struct-toggle-button {mode dir} {
    switch -- $mode {
	link   {.structurer.tbar.mode.link configure -relief $dir}
	unlink {.structurer.tbar.mode.unlink configure -relief $dir}
	collapse/expand {.structurer.tbar.mode.collapse/expand configure -relief $dir}
	schema  {.structurer.tbar.action.add_schema configure -relief $dir}
	saveps {.structurer.tbar.action.save_ps configure -relief $dir}
	savepdx {.structurer.tbar.action.save_pdx configure -relief $dir}
	default {.structurer.tbar.action.add_$mode configure -relief $dir}
    }
}



proc start-watch-cursor {} {
    global OLDFOCUS RSTW OLDCURSOR1 OLDCURSOR2
    set OLDFOCUS [focus]
    set OLDCURSOR1 [lindex [. config -cursor] 4]
    set OLDCURSOR2 [lindex [$RSTW config -cursor] 4]
    focus .
    . config -cursor watch
    $RSTW config -cursor watch
    update
}

proc stop-watch-cursor {} {
    global OLDFOCUS RSTW OLDCURSOR1 OLDCURSOR2
    catch "focus $OLDFOCUS"
    . config -cursor $OLDCURSOR1
    $RSTW config -cursor $OLDCURSOR2
}


proc savepdx {} {
    set text "Capture entire structure or subtree selected by you?"
    set result [tk_dialog .d1 {File Clear} $text warning 0 {All} {Subtree} "Cancel"]
    switch -- $result {
	0 {global RSTW; canvas-to-pdx $RSTW}
	1 {
	    tell-user "Click on the top node of the RST subtree to save"
	    set-mode savepdx
	}
    }
}


proc save-subtree-as-pdx {nid} {
    global RSTW DIR
    
    if { $nid !={} } {
	#1. Find all the widgets involved
	region-to-pdx $RSTW [find-subtree-region $nid]
	set-mode link
    }
}

proc toggle-orientation {} {
    global ORIENTATION
    
    if { $ORIENTATION == "horizontal" } {
	set ORIENTATION vertical
    } else {
	set ORIENTATION horizontal
    }
    redraw-rst
}
