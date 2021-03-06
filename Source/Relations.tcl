######################################
## RSTTool 3.x
#
#  File: Relations.tcl
#  Author: Mick O'Donnell micko@wagsoft.com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/RSTTool/copyright.html
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.



###################################
# RELATIONS STUFF 

proc init-relations {} {
    global RELATIONS SCHEMAS SCHEMA_ELEMENTS
    #initialise globals
    set RELATIONS(rst) {}
    set RELATIONS(multinuc) {}
    set RELATIONS(schema) {}
    set SCHEMAS {}
    if [info exists SCHEMA_ELEMENTS] {
	unset SCHEMA_ELEMENTS 
    }
}

proc list-all-relations {} {
    global RELATIONS 
    return [concat $RELATIONS(rst) $RELATIONS(multinuc) $RELATIONS(schema)]
}

proc relation-type {rel} {
  global RELATIONS
  if { $rel == "Span" } {
    return span
  } elseif [member $rel $RELATIONS(rst)] {
    return rst
  } elseif [member $rel $RELATIONS(multinuc)] {
    return multinuc
  } elseif [member $rel $RELATIONS(schema)] {
    return schema
  } else {
     
    return 0
  }
}


proc group-relation-p {rel} {
  global RELATIONS
  if { $rel == "Span" || [member $rel $RELATIONS(multinuc)]\
      || [member $rel $RELATIONS(schema)] } {
    return 1
  } else { return 0 }
}

proc rst-relation-p {rel} {
  global RELATIONS

  if {$rel == {} } {return 0}

  return [member $rel $RELATIONS(rst)]
}


proc multinuc-relation-p {rel} {
  global RELATIONS

  if {$rel == {} } {return 0}

  return [member $rel $RELATIONS(multinuc)]
}

proc rst-or-multinuc-relation-p {rel} {
  global RELATIONS
  if {$rel == {} } {return 0}
  if [member $rel $RELATIONS(rst)] {return 1}
  if [member $rel $RELATIONS(multinuc)] {return 1}
  return 0
}

proc find-multinuc-type {nid} {
  global NODE RELATIONS
  foreach child $NODE($nid,children) {
    if { [member $NODE($child,relname) $RELATIONS(multinuc)] } {
      return $NODE($child,relname)
    }
 }
}

proc find-schema-type {nid} {
    global NODE RELATIONS SCHEMAS SCHEMA_ELEMENTS
    foreach child $NODE($nid,children) {
	set rel $NODE($child,relname)
	if [member $rel $RELATIONS(schema)] {
	    set schema [schema-type $rel]
	    if { $schema != {} } {
		return $schema
	    }
	}
    }
    # no prior element
    return "schema"
}


proc schema-type {relation} {
    global  SCHEMAS SCHEMA_ELEMENTS
    foreach schema $SCHEMAS {
        if [member $relation $SCHEMA_ELEMENTS($schema)] {
	    return $schema
        }
    }
    return {}
}

proc relation-in-use {rel} {
    global NODE TEXT_NODES GROUP_NODES
    foreach nid [concat $TEXT_NODES $GROUP_NODES] {
	if { $NODE($nid,relname) == $rel } {
	    return 1
	}
    } 
    return 0
}

proc schema-in-use {schema} {
    global SCHEMA_ELEMENTS
    foreach element  $SCHEMA_ELEMENTS($schema) {
	if [relation-in-use $element] {
	    return 1
	}
    }
    return 0
}


proc rename-all-relations {oldrel newrel} {

    global NODE TEXT_NODES GROUP_NODES
    foreach nid [concat $TEXT_NODES $GROUP_NODES] {
	if { $NODE($nid,relname) == $oldrel } {
	    set NODE($nid,relname) $newrel
	}
    } 
    redraw-rst
}


proc unlink-all-relations {rel} {

    global NODE TEXT_NODES GROUP_NODES
    foreach nid [concat $TEXT_NODES $GROUP_NODES] {
	if { $NODE($nid,relname) == $rel } {
	    unlink-node $nid 0
	}
    } 
    redraw-rst
}



proc check-relation-types {unknown} {
    global NODE TEXT_NODES GROUP_NODES RELATIONS
    # Check if some of unknown relations (defaulted to mononuc)
    # should have been multinuc rels
    if [info exists parents_of_rel] {unset parents_of_rel}
    
    # Find the parents of each relation
    foreach nid [concat $GROUP_NODES $TEXT_NODES] {
	if [member $NODE($nid,relname) $unknown] {
	    lappend parents_of_rel($NODE($nid,relname)) $NODE($nid,parent)
	}
    }
    
    # Now, for each rel, identify its type
    foreach rel $unknown {
	set count(text) 0
	set count(span) 0
	set count(multinuc) 0
	set count(schema) 0
	foreach pid $parents_of_rel($rel) {
	    incr count($NODE($pid,type))
	}
	
	if { $count(text) == 0 && $count(span) == 0 } {
	    if { $count(multinuc) > 0  } {
		if { $count(schema) > 0 } {
		    set type rst
		} else {
		    set type multinuc
		    set RELATIONS(rst) [ldelete $RELATIONS(rst) $rel]
		    puts "Redefining relation $rel as Multinuclear"
		    lappend RELATIONS(multinuc) $rel
		}
	    } elseif {$count(schema) > 0} {
		global SCHEMAS SCHEMA_ELEMENTS
		# Find the schema-type
		set stype ""
		foreach pid $parents_of_rel($rel) {
		    set stype [find-schema-type $pid]
		    if { $stype != "schema" } {
			break
		    }
		}
		if { $stype == "schema" || $stype == "" } {
		    set tail "Scheme"
		    set stype $rel$tail
		    lappend SCHEMAS $stype
		}

		set RELATIONS(rst) [ldelete $RELATIONS(rst) $rel]
		puts "Redefining relation $rel as element of schema $stype"
		lappend RELATIONS(schema) $rel
		lappend SCHEMA_ELEMENTS($stype) $rel
	    }

	}
    }
}
			
			