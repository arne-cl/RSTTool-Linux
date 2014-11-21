# Enter.tcl

# Code to handle Enter and Leaving of text widgets

# We keep track of various contexts affecting the
# widget and act accordingly.

# CONTEXTS
#
# a) STRUCTMODE: link  unlink collapse/expand schema multinuc span saveps 
# b) CURRENT_SAT: has a satelite already been selected

# ACTIONS
#
# a) BOX node if node relevant to mode
# b) Change CURSOR if relevant


###################################3
## ENTERING Events

proc enter-widget {wgt} {
    global  STRUCTMODE NODE RSTW

    set nid [WTN $wgt]
    # Make sure this node is relevant.
    if ![applicable-node-p $nid] {
	return
    }

    # Box the Node
    box-node $nid

    # See if cursor needs changing
    switch -- $STRUCTMODE {
	collapse/expand {
	    if { $NODE($nid,collapsed_under) == 1 } {
		$RSTW config -cursor bottom_side
	    } else {
		$RSTW config -cursor top_side
	    }
	}
    }
}

## Philosophy -- whenever an enter occurs, check if
## the box should be boxed.

## Boxed nodes are automatically unboxed when left.
## Ensure that a node slected while mouse-down does a leave.

# proc check-box-needed {wgt} 

proc applicable-node-p {nid} {
  global STRUCTMODE NODE CURRENT_SAT

  if { $nid == {} } {return 0}
  set parent $NODE($nid,parent)
  switch -- $STRUCTMODE {
      saveps { }
      link {
	  if { $CURRENT_SAT == {} } {
	      if { $parent != {} } {return 0}
	  } else {
	      if { $CURRENT_SAT == $nid } {return 0}
	      if { [circular-link-p $nid $CURRENT_SAT] == 1} {return 0}
	  } 
      }
      unlink  { if {$parent == {} } {return 0}}
      collapse/expand { 
	  if { $NODE($nid,children) == {} } {return 0}
      }
	  
      default { }
  }
  return 1
}

proc box-node {nid {source {}}} {
    global RSTW NODE CURRENT_SAT

    if { $NODE($nid,boxwgt) != {} } {return}
    set wgt $NODE($nid,textwgt)
    set bbox [$RSTW bbox $wgt]
    set x1 [lindex $bbox 0]
    set y1 [lindex $bbox 1]
    set x2 [lindex $bbox 2]
    set y2 [lindex $bbox 3]
    set NODE($nid,boxwgt) [$RSTW create rect $x1 $y1 $x2 $y2]
    $RSTW raise $wgt
#    $RSTW bind $wgt <Leave> "unbox-wgt $wgt leave1"
}


####################################
## LEAVE EVENTS

proc leave-widget {wgt} {
    global STRUCTMODE NODE RSTW

    set nid [WTN $wgt]
    if { $nid == {} } {return}

    # Unbox if needed
    if { $NODE($nid,boxwgt) != {} } {
	unbox-wgt $wgt
    }

    # See if Cursor Change needed
    switch -- $STRUCTMODE {
	collapse/expand {
	    $RSTW config -cursor sb_v_double_arrow
	}
    }
}
	
proc unbox-node {nid} {
    global NODE
    if ![info exists NODE($nid,textwgt)] {
      puts "Error: unbox-node: nid: $nid has no textwgt"
      return
    }
    set wgt $NODE($nid,textwgt)
    unbox-wgt $wgt
}

proc unbox-wgt {wgt {source {}}} {
    global RSTW NODE
    set nid [WTN $wgt]

    if { $nid != {} && $NODE($nid,boxwgt) != {} } {
	$RSTW delete $NODE($nid,boxwgt)
	set NODE($nid,boxwgt) {}
	#       $RSTW bind $wgt <Leave> {}
    }
}

