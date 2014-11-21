######################################
## RSTTool3.x
#
#  File: Print.tcl
#  Author: Mick O'Donnell micko@wagsoft.com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/RSTTool/copyright.html
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.


# Print

proc print-canvas {cnv} {
    global PLATFORM tk_version RSTW
    switch -- $PLATFORM {
	windows {
	    switch -- $tk_version {
		8.4 {
		    tell-user "Sorry, no direct printing of canvases from Tcl/Tk 8.4 yet. Requires versions 8.0-8.2."}
		8.3 {
		    tell-user "Sorry, no direct printing of canvases from Tcl/Tk 8.3 yet. Requires versions 8.0-8.2."
		}
		
		default { 
		    global DIR
		    set version [string index $tk_version end]
		    set printer_dll [file join $DIR DLLs tkprint8$version.dll]
		    if ![file exists $printer_dll] {
			tell-user "Could not locate required dll file: $printer_dll. Exiting print."
			return
		    }
		    
		    if [catch "load $printer_dll"] {
			tell-user "Error in loading  required dll file: $printer_dll. Exiting print."
			return
		    }
		    ide_print_canvas $cnv
		}
	    }
	}
	
	unix {
	    set print_region [$RSTW configure -scrollregion]
	    set file /tmp/Tmp[pid]
	    $RSTW postscript -file $file \
		    -pagex 0.i -pagey 11.i -pageanchor nw
	    busy-dialog .busdial "Printing $file..."
	    exec lpr $file 
	    close-busy-dialog .busdial "Document printed!"
	    file delete $file
	}
	macintosh {
	    tell-user "Sorry, We can't print directly for Macs yet."
	}
    }
}

### CODE to Manage PS file saving

proc save-subtree-as-ps {nid} {
  global RSTW DIR
  if { $nid !={} } {
    set print_region [find-subtree-region $nid]
	    
    set file [tk_getSaveFile -title "Save Postscript as"\
         -initialfile [default-file ".ps"]]
    if { $file == {} } { return }
    set x1 [lindex $print_region 0]
    set y1 [max 1 [lindex $print_region 1]] ;# ensure y is at least 1
    set x2 [lindex $print_region 2]
    set y2 [lindex $print_region 3]
    $RSTW postscript -file $file \
                   -x $x1 -y $y1\
                   -width [expr $x2 - $x1 +5]\
                   -height [expr $y2 - $y1 +5]\
                   -pagex 0.i -pagey 11.i -pageanchor nw
  set-mode link
  }
}


proc old-find-subtree-region {nid} {
  global NODE
  set node_region [find-node-region $nid]
  foreach cid $NODE($nid,children) {
   if {$NODE($cid,visible) == 1} {
      set node_region [unify-node-regions $node_region [find-subtree-region $cid]]
   }
  }
  return $node_region
}


proc find-subtree-region {nid} {
    # new version
    global NODE RSTW

    # Find the involved wgts
    set wgts [list $NODE($nid,textwgt) $NODE($nid,spanwgt)]
    set waiting $NODE($nid,children)
    while { $waiting != {} } {
	set nid1 [pop waiting]
	if {$NODE($nid1,visible) == 1} {
	    set waiting [concat $waiting $NODE($nid1,children)]
	    foreach wgt [list $NODE($nid1,textwgt) $NODE($nid1,spanwgt)\
		    $NODE($nid1,arrowwgt) $NODE($nid1,labelwgt)] {
		if { $wgt != {} } {
		    lappend wgts $wgt
		}
	    }
	}
    }

    # Now, find the region
    set bbox [eval [concat "$RSTW bbox " $wgts]]
    return $bbox
}


# Old -no longer used
proc find-node-region {nid} {
  global NODE HALF_NODE_WIDTH
  set xmin [expr $NODE($nid,xpos) - $HALF_NODE_WIDTH]
  set xmax [expr $NODE($nid,xpos) + $HALF_NODE_WIDTH]
  set ymin $NODE($nid,ypos)
  set ymax [lindex [bottom-point [ntw $nid]] 1]
  return "$xmin $ymin $xmax $ymax"
}

# Old -no longer used
proc unify-node-regions {reg1 reg2} {
  return "[min [lindex $reg1 0] [lindex $reg2 0]]\
          [min [lindex $reg1 1] [lindex $reg2 1]]\
          [max [lindex $reg1 2] [lindex $reg2 2]]\
          [max [lindex $reg1 3] [lindex $reg2 3]]"
}


