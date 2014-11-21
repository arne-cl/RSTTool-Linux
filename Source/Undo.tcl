# Ops relating to undo


proc clear-undo-stacks {} {
    global UNDO_STACK REDO_STACK UNDO_STOP
    set UNDO_STACK {}
    set REDO_STACK {}
    if [info exists UNDO_STOP] {unset UNDO_STOP}
}
    
proc new-undo-level {op args} {
    global UNDO_STACK UNDO_STOP
    push [list newlevel $args] UNDO_STACK 
    if [info exists UNDO_STOP] {unset UNDO_STOP}
}

proc register-undo-op {op args} {
    global UNDO_STACK UNDO_STOP
    if [info exists UNDO_STOP] {
	return
    }
#    puts "REGISTER ACTION: $op $args"
    push [list $op $args] UNDO_STACK
}

proc show-undo {} {
    global UNDO_STACK REDO_STACK
    puts "----------------"
    foreach item $UNDO_STACK {
	if { [car $item] == "newlevel"} {
	    puts " OP: [second $item]"
	} else {
	    puts "      $item"
	}
    }
    puts "----------------\nredo:"
    foreach item $REDO_STACK {
	if { [car $item] == "newlevel"} {
	    puts " OP: [second $item]"
	} else {
	    puts "      $item"
	}
    }
    puts "----------------"
}

proc pop-undo-stack {} {
    global UNDO_STACK
    return [pop UNDO_STACK]
}


proc undo {} {
    global UNDO_STOP
    set UNDO_STOP 1
    # undo.1
    if [catch "undo.1"] {
	tell-user "Problem with Undo"
	global errorInfo
	puts "Error: in undo:\n$errorInfo"
    }
    unset UNDO_STOP
    redraw-rst
}

proc undo.1 {} {
    global UNDO_STACK REDO_STACK
#    puts "\nUndo Entered"

    # If nothing to undo, return
    if { $UNDO_STACK == {}} {return}

    # There must be an action sequence - first line is an action
    set action [pop-undo-stack]
    set op [car $action]

    while { $op != "newlevel" && $UNDO_STACK != {}} {
	undo-action $op [second $action]
	set action [pop-undo-stack]
	set op [car $action]
    }
    if { $op == "newlevel"} {
	push $action REDO_STACK
    }
}

proc undo-action {op arguments} {
    global REDO_STACK UNUSED_TAGS 
#    puts "* Undo-action entered: $op $arguments"
    # 
    switch -- $op {
	link {
#	    puts "  - unlinking $arguments"
	       # use foreach for list-based assignmnet
	    foreach {nuc sat rel} $arguments {
		unlink-node $sat
	    }

	}

	unlink {
#	    puts "  - linking $arguments"
	    # use foreach for list-based assignmnet
	    foreach {nuc sat rel} $arguments {
		link-nodes $nuc $sat $rel
	    }
	}

	renamerel {
#	    puts "  - renaming rel $arguments"
	    foreach {sat oldname newname} $arguments {
		rename-relation $sat $oldname
	    }
	}

	insertnodeover {
#	    puts "  - deleting node $arguments"
	    set node [second $arguments]
	    if ![member $node $UNUSED_TAGS] {
		destroy-node $node
	    } else {
#		puts " ...but node already destroyed"
	    }
	}

	deletenode {
	    # This should automatically use the same nid
#	    puts "  - creating node: $arguments"
	    set new [new-group-node [second $arguments]]
#	    puts "  - created $new expected: [car $arguments]"
	}

	default {tell-user "undo op not supported: $op"}
    }
    push [list $op $arguments] REDO_STACK
}

proc redo {} {
    global UNDO_STOP
    set UNDO_STOP 1
    if [catch "redo.1"] {
	tell-user "Problem with Undo"
    }
    unset UNDO_STOP
}

proc redo.1 {} {
    global REDO_STACK UNDO_STACK
#    puts "\nRedo Entered:"

    # If nothing to redo, return
    if { $REDO_STACK == {}} {return}

    # There must be an action sequence - first line is a separator
    # Put it onto the UNDO stack
    set action [pop REDO_STACK]
    push $action UNDO_STACK

    # Now, cycle with subactions until next level marker
    set op [car [car $REDO_STACK]]
    while { $op != "newlevel" && $op != {}} {
	set action [pop REDO_STACK]
	redo-action $op [second $action]
	push $action UNDO_STACK
	set op [car [car $REDO_STACK]]
    }
}


proc redo-action {op arguments} {
    global REDO_STACK UNUSED_TAGS NODE 
#    puts "* Redo-action $op $arguments"
    # 
    switch -- $op {
	link {
#	    puts "  - linking $arguments"
	       # use foreach for list-based assignmnet
	    foreach {nuc sat rel} $arguments {
		link-nodes $nuc $sat $rel
	    }

	}

	unlink {
#	    puts "  - unlinking $arguments"
	    # use foreach for list-based assignmnet
	    foreach {nuc sat rel} $arguments {
		unlink-node $sat	   
	    }
	}

	renamerel {
#	    puts "  - renaming rel $arguments"
	    foreach {sat oldname newname} $arguments {
		rename-relation $sat $newname
	    }
	}

	insertnodeover {
	    # This should automatically use the same nid
#	    puts "  - creating node $arguments"
	    set new [new-group-node [third $arguments]]
#	    puts "     (Created $new expected: [second $arguments])"

	    # Reposition the created node over its parent
	    set nid [car $arguments]
	    set NODE($new,xpos) $NODE($nid,xpos)
	    set NODE($new,ypos) $NODE($nid,ypos)
	}

	deletenode {
#	    puts "  - deleting node: $arguments"
	    # Check if node already destroyed by an unlinking
	    if ![member [car $arguments] $UNUSED_TAGS] {
		destroy-node [car $arguments]
	    } else {
#		puts "     ...but node already destroyed"
	    }
	}

	default {tell-user "redo op not supported: $op"}
    }
}
