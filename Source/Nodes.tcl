######################################
## RSTTool 3.x
#
#  File: Nodes.tcl
#  Author: Mick O'Donnell micko@wagsoft.com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/RSTTool/copyright.html
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.


# Nodes.tcl

# defines basic procedures for creating and manipulating
# the rst data structures

global NODES TEXT_NODES GROUP_NODES 

# NODES: array of rst nodes, either text or group

# set NODE {}       array holding info about the various nodes
#  NODE($wgt,type): text, span, multinuc, scheme
#  NODE($wgt,text): the text if a text node (trimmed), its span otherwise
#  NODE($wgt,visible): whether the node is displayed or collapsed
#  NODE($wgt,xpos): the pos of the center of the node
#  NODE($wgt,ypos): the pos of the top of the node
#  NODE($wgt,span): list of min/max of component TEXT_NODES
#  NODE($wgt,collapsed_under): 1 if the structure below is hidden.

#  Extra if the node has a parent or is a parent
#  NODE($wgt,relname): the id of the relation to its parent 
#  NODE($wgt,parent): the node-id of the node's parent
#  NODE($wgt,children): the node-id's of the node's children

#  Components of the drawn widget
#  NODE($wgt,textwgt): the id of the text display (if a text node)
#  NODE($wgt,spanwgt): the id of the span-line for the node
#  NODE($wgt,arrowwgt):  the id of the arrow to the parent
#  NODE($wgt,labelwgt):  the id of the label widget
#  NODE($wgt,boxwgt):  the id of the box widget (if any)

# WTN           array mapping widget-id to node-id
# set TEXT_NODES {}    ;# list of ids of text nodes
# set GROUP_NODES {}   ;# list of ids of sequence nodes


####################################
## Reset Data-structures 

proc reset-all {} {
    global RELATIONS RST_FILE TEXT_FILE RELATIONS_FILE CHANGED
    set CHANGED 0
    clear-structure
    init-relations
    set RST_FILE {}
    set TEXT_FILE {}
    set RELATIONS_FILE {}
}

proc clear-structure {} {
    global NODE UNUSED_TAGS LASTTAG TEXT_NODES GROUP_NODES RSTW
    if [info exists NODE] {unset NODE}
    set TEXT_NODES {}
    set GROUP_NODES {}
    set LASTTAG 0
    set UNUSED_TAGS {}
    if [info exists RSTW] {clear-drawing}
    clear-text
    mark-unedited
}


proc clear-node {nid} {
  global NODE
  set NODE($nid,text) {}
  set NODE($nid,type) {}
  set NODE($nid,textwgt)  {}
  set NODE($nid,labelwgt) {}
  set NODE($nid,arrowwgt) {}
  set NODE($nid,spanwgt) {}
  set NODE($nid,boxwgt) {}
  set NODE($nid,collwgt) {}
  set NODE($nid,relname) {}
  set NODE($nid,children) {}
  set NODE($nid,parent) {}
  set NODE($nid,constituents) {}
  set NODE($nid,visible) 1
  set NODE($nid,span)  {}
  set NODE($nid,xpos) 0
  set NODE($nid,ypos) 0
  set NODE($nid,collapsed_under) 0
}

proc new-node {} {
  global UNUSED_TAGS LASTTAG NODE
    if { $UNUSED_TAGS == {} } {
	set id [incr LASTTAG]
    } else {
	set id [pop UNUSED_TAGS]
    }
    clear-node $id
    return $id
}


proc new-text-node {} {
  global  NODE
  set id [new-node]
  set NODE($id,type) text
  set NODE($id,span) "$id $id"
  return $id
}

proc new-group-node {type} {
    global NODE GROUP_NODES
    
    set nid [new-node]
    set NODE($nid,type) $type
  
    # add the node
    lappend GROUP_NODES $nid 
    return $nid
}



proc describe-node {nid} {

  global NODE
  puts "id $nid"
  puts "text $NODE($nid,text)"
  puts "type $NODE($nid,type)"
  puts "textwgt $NODE($nid,textwgt)"
  puts "labelwgt $NODE($nid,labelwgt)"
  puts "arrowwgt $NODE($nid,arrowwgt)"
  puts "spanwgt $NODE($nid,spanwgt)"
  puts "relname $NODE($nid,relname)"
  puts "children $NODE($nid,children)"
  puts "parent $NODE($nid,parent)"
  puts "constituents $NODE($nid,constituents)"
  puts "visible $NODE($nid,visible)"
  puts "span $NODE($nid,span)"
  puts "xpos $NODE($nid,xpos)"
  puts "ypos $NODE($nid,ypos)"
  puts "oldindex $NODE($nid,oldindex)"
  puts "newindex $NODE($nid,newindex)"
}

proc dn {nid} {describe-node $nid}



############################################
# Some logical and data access functions

proc group-node-p {nid} {
  global NODE
  member $NODE($nid,type) {span multinuc schema}
}

proc text-node-p {nid} {
  global NODE
 if { $NODE($nid,type) == "text" } {
   return 1
 }
   return 0
}

proc find-top-nuc {nid} {
 global NODE
 if {$NODE($nid,parent) == {} } {
   return $nid
 } else {
   return [find-top-nuc $NODE($nid,parent)]
 }
}


proc find-node-nucleus {nid} {
    global NODE

    
    if [text-node-p $nid] {
	return $nid
    }

    set children $NODE($nid,children)

    # this condition should never be met.
    if { $children == {} } {
	return $nid
    }

    # Else, we have a group node
    set type $NODE($nid,type)
    foreach cid $children {
	if { [relation-type $NODE($cid,relname)] == $type } {
	    return $cid
	}
    }
    return {}
}

proc find-bottom-nuc {nid} {
    # Locates and returns the core nuclear text-node
    # For multinuc and schemas, just select the leftmost
    if [text-node-p $nid] {
	return $nid
    }
    return [find-bottom-nuc [find-node-nucleus $nid]]
}
	


proc node-has-satelites-p {nid} {
 global NODE
 foreach child $NODE($nid,children) {
    if { [rst-relation-p $NODE($child,relname)] } {
      return 1
    }
 }
 return 0
}

proc node-is-satelite-p {nid} {
    global NODE
    return [rst-relation-p $NODE($nid,relname)]
}

##################################################
#  NODE DELETION

proc forget-node {nid} {
    global UNUSED_TAGS NODE GROUP_NODES TEXT_NODES

    # 2. Unlink it from any parent
     if { $NODE($nid,parent) != {} } {
	 unlink-node1 $nid
     }

    #3. Unlink any children
     foreach cid $NODE($nid,children) {
	 unlink-node $cid
     }

     # 3. If a group node, remove from the list
     if [member $nid $GROUP_NODES] {
	 delete GROUP_NODES $nid
     } else {
	 delete TEXT_NODES $nid
     }

     # 1. Make this nid available again
    push $nid UNUSED_TAGS

 }

proc unlink-node1 {sat} {
    global NODE GROUP_NODES

  # 1. handle missed clicks
  if { $sat == {} || $NODE($sat,parent) == {} } {return}

  # 1. Delete the stored data
  set nuc $NODE($sat,parent)
  delete NODE($nuc,children) $sat

  set NODE($sat,parent) {}
  set NODE($sat,relname) {}

  # 3. If the parent is a sequence, and has no more children,
  #      delete it
  if { [member $nuc $GROUP_NODES] &&\
        $NODE($nuc,children) == {} } {
     forget-node $nuc
    return
  } 

  # check upwards to see if a span has changed
  recalculate-span $nuc
  mark-edited
}

proc nid-position {nid} {
    global TEXT_NODES
    if { $nid == ""} {return ""}
    set pos [lsearch -exact $TEXT_NODES $nid]
    if { $pos == -1} {
	puts "Error: nid-position: $nid not in TEXT_NODES!!"
	tell-user "Error: nid-position: $nid not in TEXT_NODES!!"
	return "??"
    }
    return [incr pos]
}


####################################
# Span functions

proc recalculate-span {nid} {
    global NODE
    set NODE($nid,span) [find-node-span $nid]
    
    # Perhaps a hack, but a check to stop null spans
    # the cause may have been fixed.
    if {  $NODE($nid,span) == " "} {
	if { $NODE($nid,children) == {}} {
	    forget-node $nid
	    return
	}
    }
    set par $NODE($nid,parent)
    if  { $par != {} } {recalculate-span $par}
}


proc find-node-span {nid} {
    global NODE

    switch -- $NODE($nid,type) {
	
	span { # span is min/max of nuc and all its satelites
	    # The must be children, if none, exit gracefully
	    if { $NODE($nid,children) == {}} {
		puts "SPAN NODE WITH NO CHILDREN!!!!: $nid"
		return {}
	    }
	    foreach child $NODE($nid,children) {

		# should have only one matching child
		if { $NODE($child,relname) == "Span" } {

		    set min [lindex $NODE($child,span) 0]
		    set max [lindex $NODE($child,span) 1]

		    foreach sat $NODE($child,children) {	

			set min [leftmost [lindex $NODE($sat,span) 0] $min]
			set max [rightmost [lindex $NODE($sat,span) 1] $max]
		    }
		}
	    }
	    # if no span node yet (not yet read in)
	    # use the existing rel (there must be an rst rel)
	    if ![info exists min] {
		set rstnode [lindex $NODE($nid,children) 0]
		return [find-node-span [lindex $NODE($nid,children) 0]]
	    }
	}
	text { set min $nid; set max $nid }
	default { # dealing with multinuc or schema node
	    set min {}
	    set max  {}
	    foreach child $NODE($nid,children) {
		if [group-relation-p $NODE($child,relname)] {
		    set min [leftmost [lindex $NODE($child,span) 0] $min]
		    set max [rightmost [lindex $NODE($child,span) 1] $max]
		}
	    }
	}
    }
    
    set result "$min $max"
    return "$min $max"
}




proc set-subtree-node-span {nid} {
  global NODE

    # this function is like reset-parent-node-span, but works downwards
    
    #1. Ensure span of all children is known
    foreach child $NODE($nid,children) {
	if { $NODE($child,span) == {} || [text-node-p $child] == 1} {
	    set-subtree-node-span $child
	}
    }

    #2. Set span of present node
    set NODE($nid,span) [find-node-span $nid]
}


proc make-span-label {span} {
  # returns a text-lable for the span
    if { $span == " "} {return ""}
    if { [lindex $span 0] == [lindex $span 1] } {
	return "[nid-position [lindex $span 0]]"
    } else {
	return "[nid-position [lindex $span 0]]-[nid-position [lindex $span 1]]"
    }
}


proc leftmost {n1 n2} {
    if { $n2 == {} } {return $n1}
    if { $n1 == {} } {return $n2}
    if { [nid-position $n1] < [nid-position $n2] } {
	return $n1
    } 
    return $n2
}

proc rightmost {n1 n2} {
    if { $n2 == {} } {return $n1}
    if { $n1 == {} } {return $n2}
    if { [nid-position $n1] > [nid-position $n2] } {
	return $n1
    } 
    return $n2
}


#############################################
# Finding visible Span

proc leftmost-visible {nid} {
    global NODE
    
    # return null if not visible
    if { $NODE($nid,visible) == 0} {return ""}

    # deal with the case of text nodes
    if [text-node-p $nid] {return $nid}

    # only group nodes left - find leftmost vis child
    set leftmost {}
    set leftmost_pos 99999
    foreach child $NODE($nid,children) {
	if { $NODE($child,visible) == 1 && \
		[group-relation-p $NODE($child,relname)] } {
	    set child_pos [nid-position [lindex $NODE($child,span) 1]]
	    if { $child_pos <  $leftmost_pos } {
		set leftmost $child
		set leftmost_pos $child_pos
	    }
	}
    }

    if { $leftmost == {} } {
	# there are no visible group-childs
	return $nid
    } else {
	return [extended-leftmost-visible $leftmost $leftmost_pos]
    }
}	


proc extended-leftmost-visible {nid nid_pos} {
    global NODE
    # returns the leftmost point of a node or its rst dependents
    
    set leftmost $nid
    set leftmost_pos $nid_pos
    
    foreach child $NODE($nid,children)  {
	if { $NODE($child,visible) == 1 && \
		[rst-relation-p $NODE($child,relname)] } {

	    # following cond is just a check, should not be needed
            if { $NODE($child,span) != {} } {
		set child_pos [nid-position [lindex $NODE($child,span) 1]]
		if { $child_pos <  $leftmost_pos } {
		    set leftmost $child
		    set leftmost_pos $child_pos
		}
	    }
	}
    }
    if { $leftmost == $nid } {
	# there are no visible rst-childs left of nid
	return [leftmost-visible $nid]
    } else {
	return [extended-leftmost-visible $leftmost $leftmost_pos]
    }
}	


proc rightmost-visible {nid} {
    global NODE
    
    # return null if not visible
    if { $NODE($nid,visible) == 0} {return ""}

    # deal with the case of text nodes
    if [text-node-p $nid] {return $nid}

    # only group nodes right - find rightmost vis child
    set rightmost {}
    set rightmost_pos 0
    foreach child $NODE($nid,children) {
	if { $NODE($child,visible) == 1 && \
		[group-relation-p $NODE($child,relname)] } {
	    set child_pos [nid-position [lindex $NODE($child,span) 0]]
	    if { $child_pos >  $rightmost_pos } {
		set rightmost $child
		set rightmost_pos $child_pos
	    }
	}
    }

    if { $rightmost == {} } {
	# there are no visible group-childs
	return $nid
    } else {
	return [extended-rightmost-visible $rightmost $rightmost_pos]
    }
}	


proc  extended-rightmost-visible {nid nid_pos} {
    global NODE

    # returns the rightmost point of a node or its rst dependents

    set rightmost $nid
    set rightmost_pos $nid_pos

    foreach child $NODE($nid,children)  {
	if { $NODE($child,visible) == 1 && \
		[rst-relation-p $NODE($child,relname)] } {

	    if {  [lindex $NODE($child,span) 0] == {}} {
		puts "Childspan is null: $child : \"$NODE($child,span)\""
		set-subtree-node-span $child
	    } 
	    set child_leftmost  [lindex $NODE($child,span) 0]
	    set child_pos [nid-position $child_leftmost]
	    
	    if { $child_pos >  $rightmost_pos } {
		set rightmost $child
		set rightmost_pos $child_pos
	    }
	}
    }
    if { $rightmost == $nid } {
	# there are no visible rst-childs right of nid
	return [rightmost-visible $nid]
    } else {
	return [extended-rightmost-visible $rightmost $rightmost_pos]
    }
}	
			

proc multinuc-children {nid} {
    global NODE
    set result {}
    foreach cid $NODE($nid,children) {
	if [group-relation-p $NODE($cid,relname)] {
	    lappend result $cid
	}
    }
    return $result
}

proc sat-before-nuc {sat} {
    global NODE
    set par $NODE($sat,parent)

    set sat_leftmost [lindex $NODE($sat,span) 0]
    set nuc_leftmost [lindex $NODE($par,span) 0]

    if { $sat_leftmost < $nuc_leftmost } {return 1}
    return 0
}
    