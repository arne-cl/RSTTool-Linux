######################################
## RSTTool 3.x
#
#  File: Structurer.tcl
#  Author: Mick O'Donnell micko@wagsoft.com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/RSTTool/copyright.html
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.


#  RST EDITOR

# 1. On hide, scroll to prior visible node
# on return from edit, reinstantiate visibility

## ADD Message bar to display what one can do at each point.
## perhpas change as mous goes over buttons
## Add: limits on scrolling
## auto-return to same point
## Add relation


#################################
# ORGANISATION

# This code is now split into two parts, 

# A. Basic graphic operations of link, unlink, insert, etc.
# B. User-Request intefaces to these calls.


###############################
# A. BASIC STRUCTURAL OPERATIONS

#------------
# LINK NODES

proc link-nodes {nuc sat {relname {}} {redraw 1}} {
    global NODE RSTW

    lappend NODE($nuc,children) $sat
    set NODE($sat,parent) $nuc
    set NODE($sat,relname) $relname
    
    register-undo-op link $nuc $sat $relname

    # when we link two nodes, we need to redraw
    # the satelite, and each of the parents.
    # this also involves re-calculating the span
    # of each item.
    
    adjust-after-change $nuc $sat link $redraw
    mark-edited
}

#------------
# UNLINK NODES

proc unlink-node {sat {redraw 1}} {
  global NODE GROUP_NODES STRUCTMODE UNDO_STOP

  if { $NODE($sat,parent) == {}} {return}

  # 1. Delete the stored data
  set nuc $NODE($sat,parent)
  delete NODE($nuc,children) $sat
  set NODE($sat,parent) {}
  register-undo-op unlink $nuc $sat $NODE($sat,relname)
  set NODE($sat,relname) {}
  
  
  # 2. Redraw the satelite substructure
  if {$redraw == 1} {y-layout-subtree $sat;constrain-scrollbars}
  
  # 3. If the parent is a sequence, and has no more children,
  #    and we are not inserting a groupnode,delete it
  if { [member $nuc $GROUP_NODES] == 1 &&\
	  [multinuc-children $nuc] == {} &&\
	  [member $STRUCTMODE {span multinuc schema}] != 1 &&\
          [info exists UNDO_STOP] == 0 } {
      destroy-node $nuc $redraw
  } else {
      # Restructure, unless this is a childless group node
      if { [group-node-p $nuc] == 0 || $NODE($nuc,children) != {} }  {
	  restructure-upwards $nuc $redraw
      }
  }
  mark-edited
}

#------------------
# INSERT GROUP NODE 


proc insert-node {nid type relname {redraw 1}} {
    # Click on a node to insert a sequence item above
    global  NODE  

    # If item has parent, Inserting mid-structure
    # Unlink, and reestablish later.
    set parent $NODE($nid,parent)
    if {$parent != {} } {
	set par_relname $NODE($nid,relname)
	unlink-node $nid 0 
    }      

    
    set seq [new-group-node $type]
    
    register-undo-op insertnodeover $nid $seq $type
    
    set NODE($seq,xpos) $NODE($nid,xpos)
    set NODE($seq,ypos) $NODE($nid,ypos)
    
    link-nodes $seq $nid $relname 0

    # reestablish the parent link if needed
    if { $parent != {} } {
	link-nodes $parent $seq $par_relname 0
    }

    if { $redraw == 1} {
	y-layout-subtree $seq
	constrain-scrollbars
    }

    set-mode link
    mark-edited
    return $seq
}

#--------------------
# INSERT SPAN BETWEEN 

proc insert-span-over {nid} {
  global NODE
  # used to tree-insert a span node over a node when
  # it takes on a satelite, e.g.
  #
  #   __               ___
  #  /  \      =>     /   \ 
  # 1    2  3        1    2-3 _
  #                         |/ \
  #                         2   3
  # 
  set par $NODE($nid,parent)
  set relname $NODE($nid,relname)
  unlink-node $nid 0 
  set span [insert-node $nid span Span]
  link-nodes $par $span $relname
}


#-------------
# DESTROY NODE 

proc destroy-node {nid {redraw 1}} {
    global NODE 
    
    #1. Unlink the node if still connected
    if {$NODE($nid,parent) != {} } {
	unlink-node $nid 
    }
    
    #2. delete the graphic presentation
    if { $redraw == 1} {erase-node $nid}
    
    #3. Remove from node list
    if [text-node-p $nid] {
	tell-user "Error: attempt to delete text node: $nid"
	break
    } else {
	register-undo-op deletenode $nid $NODE($nid,type)
	forget-node $nid
    }
}

#--------------------------
#  Collapse or Expand Nodes 

proc collapse-expand {nid} {
  global NODE RSTW

  if {![info exists NODE($nid,text)]} {return}

  if { $NODE($nid,children) == {} } {
      return
  }

  if { $NODE($nid,collapsed_under) == 1} {

      # The node is in collapsed form, expand
      foreach child  $NODE($nid,children) {
	  show-subtree $child
      }
      set NODE($nid,collapsed_under) 0

  } else {

      # The node is in expanded form, collapse
      foreach child  $NODE($nid,children) {
	  if $NODE($child,visible) {
	      # we have a visible child so hide it
	      hide-subtree $child
	  }
      }
      set NODE($nid,collapsed_under) 1
  }
 
# Redraw the graph
  redraw-rst

# Scroll to new position
  if { $NODE($nid,collapsed_under) == 0 } {
      # collapsed - scroll to the new node position
      #   xscrollto [max [expr $NODE($nid,xpos) - 50] 0]
  }
}

proc hide-subtree {nid} { 
  global NODE
  set NODE($nid,visible) 0
  foreach cid $NODE($nid,children) {
    hide-subtree $cid
  }
}
   
proc show-subtree {nid} { 
    global NODE
    set NODE($nid,visible) 1
    if { $NODE($nid,collapsed_under) == 1} {
	return
    }
    
    foreach cid $NODE($nid,children) {
	show-subtree $cid
    }
}

#---------------------
# RENAME-ARC

proc rename-relation {sat new_relname} {
    global NODE
    register-undo-op renamerel $sat $NODE($sat,relname) $new_relname
    set NODE($sat,relname) $new_relname
    erase-arc $sat
    display-arc $sat
}



##################################
# USER INTERFACE FUNCTIONS
##################################

#-----------------
# CHANGE-STRUCTURE
 
proc change-structure {operation arg1 {arg2 {}} } {
# A general function through which all interface actions
# which cause structural change need to pass.
    global CURRENT_SAT UNDO_STACK REDO_STACK

    # catch missing arg
    if { $arg1 == {} } {
	return 0
    }

    # Register for undo
    new-undo-level $operation $operation $arg1 $arg2

    switch -- $operation {
	link-nodes {ur-link-nodes $arg1 $arg2}
	unlink-node {unlink-node $arg1} 
	insert-node {ur-insert-node $arg1 $arg2}
	change-rel-label {ur-rename-relation $arg1}
	collapse-expand {collapse-expand $arg1}
	default {tell-user "change-structure: unknown option: $operation"}
    }

    set CURRENT_SAT {}

    # Check for cancelled actions
    if {[car [car $UNDO_STACK]] == "newlevel"} {
	puts "cancelled action"
	pop-undo-stack
    } else {
	# A positive action, so wipe the redo stack
	set REDO_STACK {}
    }
}


##################################
# LINK NODES

##################################
# Node Linking

proc select-satelite {sid} {
    global CURRENT_SAT TRACK_MOUSE CLOSEST NODE RSTW
    if { $sid == {} } {return}
    set CURRENT_SAT $sid
    set wgt $NODE($sid,textwgt)

    set TRACK_MOUSE 1
    set CLOSEST {}
    while {$TRACK_MOUSE == 1} {
	track-mouse
	update
	after 50
    }
}

proc select-nucleus {nid} {
    global CURRENT_SAT TRACK_MOUSE NODE
    set TRACK_MOUSE 0
    update
    
    unbox-node $CURRENT_SAT

    if { $CURRENT_SAT != {}\
	    && $NODE($CURRENT_SAT,parent) == {}\
	    && $nid != {}\
	    && $nid != $CURRENT_SAT\
	    && [circular-link-p $nid $CURRENT_SAT] == 0} {
	change-structure link-nodes $nid $CURRENT_SAT
    }
    set CURRENT_SAT {}
}


proc ur-link-nodes {nuc sat} {
    # Result of user releasing mouse over nucleus
    # after drag from satelite in Link mode.
    
    # Ensure Relname is set
    set relname [choose-relation $nuc $sat]
    
    # if cancelled, dont make a link
    if { $relname == {} || $relname == "cancelled" } {
	return "cancelled"
    }

    # If the satelite has rst-satelites, create a span over them
    if { [node-has-satelites-p $sat] } {
	set sat [insert-node $sat span Span]
    }
    
    # If the nucleus is already an rst-satelite, create a span over it
    if { [node-is-satelite-p $nuc] } {
	# we need to unlink currentnuc, create a span over it
	# then re-link the span as currentnuc was
	insert-span-over $nuc
    }
    
    # Link the nodes
    link-nodes $nuc $sat $relname
}



#--------------------
# UR-RENAME-RELATION

proc ur-rename-relation {sat} {
    global NODE RSTW
    
    set curr_relname $NODE($sat,relname)
    set type [relation-type $curr_relname]
    if { $type == "schema"} { 
	set type [schema-type $curr_relname]
    }

    set new_relname [choose-label $sat $type]
    if { $new_relname == "cancelled"} {
	return "cancelled"
    }

    if { $type == "multinuc" } {
	set par $NODE($sat,parent)
	foreach child $NODE($par,children) {
	    if { $NODE($child,relname) == $curr_relname } {
		rename-relation $child  $new_relname
	    }
	}
    } else {
	rename-relation $sat $new_relname
    }    

    mark-edited
}


#---------------
# INSERTING NODES

proc ur-insert-node {nid {type {}}} {
    global STRUCTMODE

    # Ensure a type is provided
    if { $type == {} } {set type $STRUCTMODE}
    
    # Select a relation name
    set relname [choose-relation {} $nid $type]
    if { $relname == "cancelled"} {return cancelled}

    insert-node $nid $type $relname 1
}



##################################################
# Graph Change Server 

proc adjust-after-change {nuc sat op {redraw 1}} {
  global NODE
  # if we link with an rst rel, then we need to adjust
  # the span of the nuc's parent.
  # else, for multinuc/schema rels, adjust the nuc.
  if [rst-relation-p $NODE($sat,relname)] {
     if  { $NODE($nuc,parent) != {} } {
	 restructure-upwards $NODE($nuc,parent) $redraw
     }
  } else {
     # Adjust nucleus
     restructure-upwards $nuc $redraw
  }

  # Ajust satelite
  if $redraw {
      y-layout-subtree $sat 	
      constrain-scrollbars
  }
}


proc restructure-upwards {nid {redraw 1}} {
  global NODE 
  debug "restructure-upwards: $nid $redraw"

  # stop when no change in span nor in pos of node
  set adjust_needed 0

  #1. if the current node is a group node,
  #   its pos and span may need to be adjusted
  if { [group-node-p $nid] } {

    # a) If a group node, adjust its x position
    if { $redraw } {
      set NODE($nid,xpos) 0
      xlayout-group-node $nid
      set adjust_needed 1
    }

    # b) Adjust the span of this node
    set span [find-node-span $nid]

    if {$span != $NODE($nid,span)} {
      # span has changed
      set NODE($nid,span) $span

      # mark a change has taken place
      set adjust_needed 1
    }

    #  c) redraw this node if needed
    if { $adjust_needed && $redraw != 0 && $NODE($nid,visible)} {
      # check if the node has been drawn before
      redisplay-node $nid
      redraw-child-arcs $nid
    }

  } else {set adjust_needed 1}

 
  # 2. adjusts the span of parent nodes considering the expansion
  # of the current node.
  # Apply to parent also
  set par $NODE($nid,parent)
  if { $adjust_needed  && $par != {} } {

    # if the current node links to its parent via rst,
    # then the parent is unaffected, but its parent
    # may need adjustment
    if [rst-relation-p $NODE($nid,relname)] {
      if  { $NODE($par,parent) != {} } {
	  restructure-upwards $NODE($par,parent) $redraw
      }
    } else {
      # Adjust nucleus
      restructure-upwards $par $redraw
    }
  }
}


proc track-mouse {} {
    global  RSTW CLOSEST CURRENT_SAT
    set closest [wgt-under-mouse]
    if { $closest == $CLOSEST} { return}
    if { $CLOSEST != {} && $CLOSEST != $CURRENT_SAT} { unbox-wgt $CLOSEST}

    # box the node if it is a link candidate
    set nid [WTN $closest]
    if {    $nid != {} \
         && $CURRENT_SAT != $nid\
         && [circular-link-p $nid $CURRENT_SAT] == 0} {
       box-node $nid
    }
    set CLOSEST $closest
}


##################################################
#  Relations Functions 

proc choose-relation {nuc sat {type {}} } {
    global NODE RSTW

    # Choose the node at which the list is displayed
    if [info exists NODE($nuc,textwgt)] {
	set nid $nuc
    } else {
	set nid $sat
    }

    # Select a type if undefined
    if { $type == {} } {
	if { [member $NODE($nuc,type) {multinuc schema}] } {
	    # ambiguous between rst or group 
	    set xpos [winfo pointerx $RSTW]
	    set ypos [winfo pointery $RSTW]
	    set type [popup-choose-from-list [list $NODE($nuc,type) rst] $xpos $ypos]
	    #set coords [screen-coords [ntw $nid] $RSTW]
	    # set type [popup-choose-from-list [list $NODE($nuc,type) rst]\
		    [expr int([lindex $coords 0])]\
		    [expr int([lindex $coords 1])] ]
	} else {
	    set type rst
	}
    }

    switch -- $type {
	
	multinuc {
	    if { $nuc != {} } {
		set relname [find-multinuc-type $nuc]
		if { $relname != {} } {return $relname}
	    }
	    return [choose-label $nid multinuc]
	}
	
	schema {
	    if { $nuc != {} } {
		set schematype [find-schema-type $nuc]
		if { $schematype != {} } {
		    return [choose-label $nid $schematype]
		}
	    }
	    return [choose-label $nid schema]
	}

	span {return "Span"}

	rst { return [choose-label $nid rst]}

	cancelled { return "cancelled"}

	default  {
	    tell-user "choose-relation: should get here."
	    return $type
	}
    }
}



####################################################
# THE relation popup Menu

proc choose-label {nid type} {
    global RELATIONS RSTW SCHEMAS SCHEMA_ELEMENTS

    if [member $type {rst schema multinuc}] {
	# Choose from the defined set
	set range $RELATIONS($type)
    } else { 
	# this must be a schema type, choose from that set
	set range $SCHEMA_ELEMENTS($type)
    }

    if { $type == "schema" && $range == {} } {
	tell-user "No Schemas yet defined. Please use the Relations interface."
	return cancelled
    }

    set xpos [winfo pointerx $RSTW]
    set ypos [winfo pointery $RSTW]
    return [popup-choose-relation $range $xpos $ypos $type]
}

proc popup-choose-relation-old {items xpos ypos {type {}}} {
    popup-choose-from-list $items $xpos $ypos
}

proc popup-choose-relation {items xpos ypos {type {}}} {
    # A modified version of popup-choose-from-list
    global PCFL_SEL
    set PCFL_SEL {}
    make-popup-choose $items "Choose One"  $xpos $ypos

    if [member $type {rst multinuc}] {
	button .popupmenu.buttons.add -text "Add New" -command "add-new-relation $type"
	pack .popupmenu.buttons.add -before .popupmenu.buttons.cancel -side left -anchor n
    }

    # Wait for some bound event to occur
    tkwait variable PCFL_SEL

    # The selection is in PCFL_SEL - destroy the window and return
    grab release .popupmenu 
    destroy .popupmenu

    return $PCFL_SEL
}




proc add-new-relation {type} {
  global  RELATIONS   pcfl_selection
  set relname [GetValue "Type in name of relation"]
  if { $relname == {} } {return} 
  if [member $relname [concat $RELATIONS(rst) $RELATIONS(multinuc) $RELATIONS(schema)]] {
     tell-user "relation already exists"
     return
  }

  lappend RELATIONS($type) $relname  
  mark-edited
  set pcfl_selection $relname

}


##################################################
# General Functions 


proc wgt-under-mouse {} {
    global RSTW
    set x1  [$RSTW canvasx [expr [winfo pointerx $RSTW] -  [winfo rootx $RSTW]]]
    set y1  [$RSTW canvasy [expr [winfo pointery $RSTW] - [winfo rooty $RSTW]]]
    set wgts [$RSTW find overlapping [expr $x1 - 4] [expr $y1 - 4] [expr $x1 + 4] [expr $y1 + 4]]
    foreach wgt $wgts {
	if { [WTN $wgt] != {} } {return $wgt}
    }
    return {}
}

proc circular-link-p {nid sid} {
  global NODE
  set par $NODE($nid,parent) 
  if { $par == {}} {return 0}
  if { $par == $sid } {return 1}
  return [circular-link-p $par $sid]
}


proc bottom-point {item} {
  global RSTW
  list [lindex [$RSTW coords $item] 0]\
       [lindex [$RSTW bbox $item] 3]
}
  
proc clicked-widget {x y} {
 global RSTW WTN
 debug "clicked-widget: $x $y"
 set x1 [$RSTW canvasx $x] 
 set y1 [$RSTW canvasy $y]
 set wgts [$RSTW find overlapping [expr $x1-2] [expr $y1-2]\
      [expr $x1+2] [expr $y1+2]]

 if { [lindex $wgts 1] != {} } {
   foreach wgt $wgts {

      if [info exists WTN($wgt)] {
       return $wgt
     }
   }
 } else {
  return $wgts
 }
}

proc clicked-node {x y} {
  debug "clicked-node: [WTN [clicked-widget $x $y]]"
  WTN [clicked-widget $x $y]
}

proc WTN {widget} {
  global WTN
  if [info exists WTN($widget)] {
    return $WTN($widget)
  } 
}

proc ntw {nid} {
  global NODE
  return $NODE($nid,textwgt)
}

# 1. Function to move a given node to a given y-height

proc ymove-node {nid ydelta} {
  global NODE RSTW
# change its pos 
  move-item $RSTW [ntw $nid] 0 $ydelta

# move its arrow down the distance
  if [info exists NODE($nid,arrowwgt)] {
     move-item $RSTW $NODE($nid,arrowwgt)   0 $ydelta
     move-item $RSTW $NODE($nid,spanwgt) 0 $ydelta
     move-item $RSTW $NODE($nid,labelwgt)   0 $ydelta
  }

# Move its children down
  foreach child $NODE($nid,children) {
     ymove-node $child $ydelta
  }
}


proc xscrollto {x} {
    global RSTW
    
    set width [lindex [lindex [$RSTW config -scrollregion] 4] 2]
    $RSTW xview moveto [expr $x / $width.000]
}





