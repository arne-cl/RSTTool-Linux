######################################
## RSTTool
#
#  File: RelationsFiles.tcl
#  Author: Mick O'Donnell micko@wagsoft.com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute  this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/RSTTool/copyright.html
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.


###########################
# LOAD and Save of relations masters


proc save-relations-master  {{file {}}} {
    global RELATIONS_FILE
    if { $file == {} } {
	set file $RELATIONS_FILE
    }
    if { $file == {} } {
	return [save-relations-master-as]
    }
    set str [open $file w 0600]
    save-relations $str
    close $str
}

proc save-relations-master-as  {} {
    global RELATIONS_FILE DIR TEXT_FILE RST_FILE
    if [file exists [file join $DIR Relation-Sets]] {
	set defdir [file join $DIR Relation-Sets]
    } else {
	set defdir $DIR
    }

   if {$RELATIONS_FILE != {} } {
	set default $RELATIONS_FILE
    } elseif {$TEXT_FILE != {} } {
	set default [file join $defdir [file rootname $TEXT_FILE].rels]
    } elseif {$RST_FILE != {}} {
	set default  [file join $defdir [file rootname $RST_FILE].rels]
    } else {
	set default [file join $defdir "untitled.rels"]
    }
    
    set defdir [file dirname $default]
    set deffile [file tail $default]
    set file [tk_getSaveFile -initialfile $deffile -initialdir $defdir]
    if { $file == {} } {
	return cancelled
    }
    save-relations-master $file
}
    
proc save-relations {str} {
  global RELATIONS SCHEMAS SCHEMA_ELEMENTS

  foreach rel $RELATIONS(rst) {
     puts $str "$rel rst"
  }

  foreach rel $RELATIONS(multinuc) {
     puts $str "$rel multinuc"
  }

  foreach schema $SCHEMAS {
    foreach rel $SCHEMA_ELEMENTS($schema) {
     puts $str "$rel constit $schema"
    }
  }
 }


#####################################
# Load Relations

proc load-relations-master {{file {}}} {
    global RELATIONS_FILE RELATIONS SCHEMAS SCHEMA_ELEMENTS DIR

    if { $file == {} } {
      if { $RELATIONS_FILE != {} } {
	  set default $RELATIONS_FILE 
	} elseif [file exists [file join $DIR Relation-Sets]] {
	  set default [file join $DIR Relation-Sets]
      } else {
	  set default $DIR
      }

	set file [tk_getOpenFile  -initialdir $default]
	if { $file == {} } {return}
    }

    set RELATIONS_FILE $file

    init-relations

    set relationstream [open $file]
    foreach rel [split [read $relationstream] \n] {
	process-relation-entry $rel
    }
    close $relationstream
    mark-relations-unedited
}

proc mark-relations-edited {} {
    global RELATIONS_MODIFIED
    mark-edited
    set RELATIONS_MODIFIED 1
}

proc mark-relations-unedited {} {
    global RELATIONS_MODIFIED
    set RELATIONS_MODIFIED 0
}



proc process-relation-entry {rel} {
    global RELATIONS SCHEMAS SCHEMA_ELEMENTS
    switch -- [lindex $rel 0] {
	{}      {}
	-       {}	
	default {
	    set type [lindex $rel 1]
	    if { $type == {} } { set type rst }
	    set name  [capitalise [lindex $rel 0]]

	    if { $type == "constit" } {
		set type "schema"
		 # store the elements of each schema
		set schema [capitalise [lindex $rel 2]]
		if ![member $schema $SCHEMAS] {
		    lappend SCHEMAS $schema
		}
		lappend SCHEMA_ELEMENTS($schema) $name
	    }

	    lappend RELATIONS($type) $name
	}
    }
}
