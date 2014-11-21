######################################
## RSTTool 3.x
#
#  File: layout.tcl
#  Author: Mick O'Donnell micko@wagsoft.com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/RSTTool/copyright.html
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.


###########################################
# Layout
# Functions used by RST-Tool for laying-out RSt structures


proc redraw-rst {} {
# 1. Layout the graph
#  a. X-layout
#  b. Y-Layout (for each node with no parents, layout children)
# 2. Draw the links
  global RSTW current_xpos NODE_WIDTH TEXT_NODES GROUP_NODES NODE ORIENTATION
    
    if { $ORIENTATION == "vertical" } {
	return [layout-ssa]
    }
	


    # 1. Set the watch cursor
    start-watch-cursor

    # 1. Clean up from earlier structures
    if [info exists wtn] {unset wtn}
    $RSTW delete all
    
    # reset visibility based on collapsed nodes
    foreach nid [concat $TEXT_NODES $GROUP_NODES] {
	set NODE($nid,visible) 0
    }

    foreach nid [concat $TEXT_NODES $GROUP_NODES] {
	if { $NODE($nid,parent) == {} } {
	    set NODE($nid,visible) 1
	    check-subtree-visibility $nid
	}
    }

  # 2. layout and draw the new
  x-layout

    y-layout
    constrain-scrollbars


# scroll to top left 
#  $RSTW xview moveto 0
#  $RSTW yview moveto 0
  
# Stop the watch cursor
stop-watch-cursor

}

proc constrain-scrollbars {} {
    # Fix up the scrollbars
    global RSTW
    set bbox [$RSTW bbox all]
    set x1 0
    set y1 0
    set x2 [expr [lindex $bbox 2] + 10]
    set y2 [expr [lindex $bbox 3] + 10]
    $RSTW config -scrollregion  [list $x1 $y1 $x2 $y2]
    $RSTW yview moveto 0
}


proc check-subtree-visibility {nid} {
  global NODE
  if { $NODE($nid,collapsed_under) != 1 } {
     foreach cid $NODE($nid,children) {
        set NODE($cid,visible) 1
        check-subtree-visibility $cid
     }
  }
}


proc x-layout {} {
  global NODE GROUP_NODES TEXT_NODES NODE_WIDTH VISITED_GROUP_NODES current_xpos

  # set xpos of group-nodes to 0 (logically false)
  foreach nid $GROUP_NODES {
    set NODE($nid,xpos) 0
  }

  set xinc [expr $NODE_WIDTH + 10]
  set xpos [expr $NODE_WIDTH / 2 + 30]
  set VISITED_GROUP_NODES {}
  foreach nid $TEXT_NODES {
    if $NODE($nid,visible) {
      set NODE($nid,xpos) $xpos
      set xpos [expr $xpos+$xinc]
    } else {
      if [parent-needs-space-p $nid $xpos] {
        set xpos [expr $xpos+$xinc] 
      }
    }
  }

  foreach nid $GROUP_NODES {
    if $NODE($nid,visible) {
      xlayout-group-node $nid
    }
  }
  set current_xpos $xpos
}


proc xlayout-group-node {nid} {
  global NODE  NODE_WIDTH

  # only position nodes which are not yet positioned
  if $NODE($nid,xpos) {return}

  # 1. Collect x coords of constituents
  set x_coords {}

  foreach dep $NODE($nid,children) {
#  [group-relation-p $NODE($dep,relname)]
    if { $NODE($dep,visible) } {
       if { !$NODE($dep,xpos) } {
         xlayout-group-node $dep
       }
       if { [group-relation-p $NODE($dep,relname)] } {
           # we want to place the NODE over its members, not satelites
          lappend x_coords $NODE($dep,xpos)
       }
    }
  }

  if { $x_coords == {} } {
      # group-node, but all children invisible
      # find the first visible text node BEFORE the tn child
      set first_tn [lindex $NODE($nid,span) 0]
      set prev_node [previous-visible-node $first_tn]
      if { $prev_node == 0 } {
	  # no prev node
	  set NODE($nid,xpos)  [expr $NODE_WIDTH / 2 + 30]
      } else {
	  set NODE($nid,xpos) [expr $NODE($prev_node,xpos) +  $NODE_WIDTH + 10]
      }
      
  } else {
      set min [eval min $x_coords] 
      set max [eval max $x_coords]
      set NODE($nid,xpos) [expr $min + ($max - $min) / 2]
  }
}

proc previous-visible-node {nid} {
  global NODE TEXT_NODES
  set pos [lsearch $TEXT_NODES $nid]
  for {set i [expr $pos - 1]} {$i > 0} {incr i -1} {
      set id [lindex $TEXT_NODES $i]
      if $NODE($id,visible) {
        return $id
      }
  }
  return 0
}



### need to stop centering of span nodes
proc parent-needs-space-p {cid current_xpos} {
  global NODE VISITED_GROUP_NODES
  set pid $NODE($cid,parent)

  # if the parent of this invis node is a group node
  # which has no vis children, make space.

  if {$pid != {} && [group-node-p $pid]\
      && ![member $pid $VISITED_GROUP_NODES]} {
     lappend VISITED_GROUP_NODES $pid
     if $NODE($pid,visible) {
       if {![visible-children-p $pid] } {
         set NODE($pid,xpos) $current_xpos
         return 1
       }
     } else {
       return [parent-needs-space-p $pid $current_xpos]
     }
   }
   return 0
}


proc visible-children-p {nid} {
  global NODE
  foreach cid $NODE($nid,children) {
    if $NODE($cid,visible) {return 1}
  }
  return 0
}
  
 
proc y-layout {} {
  global NODE GROUP_NODES TEXT_NODES

  foreach nid [concat $TEXT_NODES $GROUP_NODES] {
    if { $NODE($nid,visible) && $NODE($nid,parent) == {} } {
       y-layout-subtree $nid
    }
  }
}


proc y-layout-subtree {nid } {
    global RSTW NODE Y_TOP DIR
    
    # 1. Re-layout this node
    y-layout-node $nid

    # 2. Re-layout children
    foreach cid $NODE($nid,children) {
	if $NODE($cid,visible) {
	    y-layout-subtree $cid
	}
    }
}

proc y-layout-node {nid} {
    global RSTW NODE Y_TOP YINCR

    #  Position this node under its parent
    set nuc $NODE($nid,parent)
    if {$nuc == {}} {
	# toplevel node - position at top
	set NODE($nid,ypos) $Y_TOP
    } elseif { [group-relation-p $NODE($nid,relname)] } {
	# group node - position under parent
	set NODE($nid,ypos) [expr [lindex [$RSTW bbox [ntw $nuc]] 3] + $YINCR]
    } else {
	set NODE($nid,ypos) $NODE($nuc,ypos)
    }
    redisplay-node $nid
}


