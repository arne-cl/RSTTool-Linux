######################################
## RSTTool 3.x
#
#  File: Editrels.tcl
#  Author: Mick O'Donnell micko@wagsoft.com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/RSTTool/copyright.html
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.

# Relations

#############################
# function to pack the Editor


proc make-relations-frame {} {
  global RELTYPE 

  # destroy any existing window
  if {[winfo exists .reledit]} {destroy .reledit}

  frame .reledit 

  make-reledit-tbar
  pack .reledit.tbar -side left  -anchor nw -pady 10

  frame .reledit.main  
  label .reledit.main.label -text "Relations "
  scrolled-listbox .reledit.main.table -width 20 -height 20 -bg white

  pack .reledit.main.label .reledit.main.table -side top
  pack .reledit.main -expand 0 -anchor nw -padx 20

  # Schema selection (only used in schema mode)
  frame .reledit.main.schema 
  label .reledit.main.schema.label -text "Schema:"  -fg red
  pack .reledit.main.schema.label -side top

  set RELTYPE rst
  return .reledit
}

proc install-releditor {} {
    global  RELTYPE 
    set-reledit-mode $RELTYPE
}

proc set-reledit-mode {mode} {
    global RELTYPE
    set RELTYPE $mode
    .reledit.tbar.mode.mononuclear configure -relief raised
    .reledit.tbar.mode.multinuclear configure -relief raised
    .reledit.tbar.mode.schemas configure -relief raised
    pack forget .reledit.tbar.schemaaction .reledit.main.schema
    pack forget .reledit.tbar.rstaction

    switch -- $mode {
	rst {
	    .reledit.tbar.mode.mononuclear configure -relief sunken
	    install-relations rst
	}
	multinuc {
	    .reledit.tbar.mode.multinuclear configure -relief sunken
	    install-relations multinuc
	}
	schemas {
	    .reledit.tbar.mode.schemas configure -relief sunken
	    install-schemas
	}
    }
}
	    
proc make-reledit-tbar {} {
    # Define a toolbar
    if {[winfo exists .reledit.tbar]} {destroy .reledit.tbar}
    
    frame .reledit.tbar

    label .reledit.tbar.filetext -text "File" -fg red
    Toolbar .reledit.tbar.file
    ToolbarItem .reledit.tbar.file  "Load" "Click here to load another relations file"  {
	load-relations-master
	install-releditor
    }
    ToolbarItem .reledit.tbar.file  "Save" "Click here to save current relations file" {save-relations-master}
    ToolbarItem .reledit.tbar.file  "Save as" "Click here to save relations file with new name" {save-relations-master-as}

    pack .reledit.tbar.filetext .reledit.tbar.file -side top -ipady 2
 
    label .reledit.tbar.modetext   -text "Type" -fg red 
    Toolbar .reledit.tbar.mode
    ToolbarItem .reledit.tbar.mode  "Mononuclear" "Edit Normal RST relations" {set-reledit-mode rst}
    ToolbarItem .reledit.tbar.mode  "Multinuclear" "Edit Multinuclear RST relations" {set-reledit-mode multinuc}
    ToolbarItem .reledit.tbar.mode  "Schemas"  "Edit Schemas"  {set-reledit-mode schemas}
    label .reledit.tbar.actiontext -text "Actions" -fg red 
    pack .reledit.tbar.modetext .reledit.tbar.mode   .reledit.tbar.actiontext -side top   -ipady 2


    ## Make distinct toolbars for each mode
    # a) RST
    Toolbar .reledit.tbar.rstaction
    ToolbarItem .reledit.tbar.rstaction "Add Relation"  "Add a relation to defined set" {er-add-relation}
    ToolbarItem .reledit.tbar.rstaction "Delete Relation"  "Deletes current relation from the defined set" {er-delete-relation}
    ToolbarItem .reledit.tbar.rstaction "Rename Relation"  "Renames current relation from defined set" {er-rename-relation}

    # b) Schemas
    Toolbar .reledit.tbar.schemaaction 
    ToolbarItem .reledit.tbar.schemaaction  "New Schema"  "Add a new schema"  {er-add-schema}
    ToolbarItem .reledit.tbar.schemaaction  "Delete Schema"  "Delete current schema" {er-delete-schema}
    ToolbarItem .reledit.tbar.schemaaction  "Rename Schema" "Rename current schema"  {er-rename-schema}
    ToolbarItem .reledit.tbar.schemaaction  "Add Schema Element"  "Add element to current schema"  {er-add-schema-element}
    ToolbarItem .reledit.tbar.schemaaction  "Delete Schema Element"  "Delete element from current schema" {er-delete-schema-element}
    ToolbarItem .reledit.tbar.schemaaction  "Rename Schema Element"  "rename current schema element" {er-rename-schema-element}

}


proc install-relations {{type rst}} {
    global RELATIONS

    pack  .reledit.tbar.rstaction
    
    .reledit.main.label config -text "Relations"
    
    # Delete all entries
    .reledit.main.table.choices delete 0 end
    
    switch -- $type {
	rst { 
	    foreach rel $RELATIONS(rst) {
		.reledit.main.table.choices insert end "$rel"
	    }
	}
	
	multinuc { 
	    foreach rel $RELATIONS(multinuc) {
                .reledit.main.table.choices insert end "$rel"
	    }
	}
    }
    .reledit.main.table.choices see 0
    .reledit.main.table.choices selection set 0
}


proc er-add-relation {} {
    global RELTYPE RELATIONS
    set relname [GetValue "Type in name of relation"]
    if { $relname == {} } {return} 
    if [member $relname [list-all-relations]] {
	tell-user "relation already in use."
	return
    }
    lappend RELATIONS($RELTYPE) $relname  
    .reledit.main.table.choices insert end "$relname"
    .reledit.main.table.choices see end 
    .reledit.main.table.choices selection clear active
    .reledit.main.table.choices selection set end 
    mark-relations-edited
}

proc er-delete-relation {} {
    global RELTYPE RELATIONS

    set currindex [.reledit.main.table.choices curselection]
    set relname [.reledit.main.table.choices get active]
    if [relation-in-use $relname] {
	if { [ask-user "Relation in use: really delete?"] != "yes"} {
	    return 0
	}
	unlink-all-relations $relname
    }

    # Now delete the relation from the global list
    set RELATIONS($RELTYPE) [ldelete $RELATIONS($RELTYPE) $relname]

    # Delete the relation from the display
    .reledit.main.table.choices delete $currindex
    .reledit.main.table.choices see $currindex
    .reledit.main.table.choices selection set $currindex
    mark-relations-edited
}

proc er-rename-relation {} {
    global RELTYPE RELATIONS
    set currindex [.reledit.main.table.choices curselection]
    set relname [.reledit.main.table.choices get active]
    set newrelname [GetValue "New Relation Name?" $relname]
    if { $newrelname == {} } {return} 
    if { $newrelname == $relname } {
	tell-user "no change -- ignoring."
	return
    }
    if [member $newrelname [list-all-relations]] { 
	tell-user "relation already exists -- ignoring."
	return
    }
    
    # we have a valid rename
    # a) delete all old entries
    set pos [lsearch $RELATIONS($RELTYPE) $relname]
    set RELATIONS($RELTYPE)\
	    [lreplace $RELATIONS($RELTYPE) $pos $pos $newrelname]
    
    # a) register the new entry in the listbox
    .reledit.main.table.choices delete $currindex
    .reledit.main.table.choices insert $currindex $newrelname
    .reledit.main.table.choices selection set $currindex
    mark-relations-edited
    rename-all-relations $relname $newrelname
}


proc install-schemas {} {
    global SCHEMAS CURRENT_SCHEMA

    .reledit.main.label config -text "Constituents"

    ##2. Make the schema selector
    # destroy any old version
    if {[winfo exists .reledit.main.schema.type]} {
	destroy .reledit.main.schema.type
    }
    
    # make the Schema choice menu
    if { $SCHEMAS == {} } {
	tk_optionMenu .reledit.main.schema.type CURRENT_SCHEMA {}
    } else {
	eval [concat "tk_optionMenu .reledit.main.schema.type CURRENT_SCHEMA" $SCHEMAS]
    }
    for {set i [expr [llength $SCHEMAS] - 1]} {$i >= 0} {incr i -1} {
	.reledit.main.schema.type.menu entryconfigure $i\
		-command "install-schema [lindex $SCHEMAS $i]"
    }

    # Pack the Schema controls
    pack .reledit.tbar.schemaaction -ipady 2
    pack .reledit.main.schema.type 
    pack forget .reledit.main.label .reledit.main.table
    pack .reledit.main.schema -side top
    pack  .reledit.main.label .reledit.main.table 
    install-schema [lindex $SCHEMAS 0] 
}

proc er-add-schema {} {
  global SCHEMAS SCHEMA_ELEMENTS RELATIONS
  set schema [GetValue "Name of Schema to Add?"]
  if { $schema == {} } {return} 
  if {[member $schema $SCHEMAS]} {
     tell-user "Schema already exists"
     return
  }
  lappend SCHEMAS $schema
  set SCHEMA_ELEMENTS($schema) {}  
  pack forget .reledit.tbar.schemaaction .reledit.main.schema 
  install-schemas 
  install-schema $schema
  mark-relations-edited
  }

proc er-delete-schema {} {
    global SCHEMAS SCHEMA_ELEMENTS CURRENT_SCHEMA RELATIONS
    if { $CURRENT_SCHEMA == {}} { return }

    # Warn if schema in use, and unlink any instances
    if [schema-in-use $CURRENT_SCHEMA] {
	if { [ask-user "Schema in use: really delete?"] != "yes"} {
	    return 0
	}
	foreach element  $SCHEMA_ELEMENTS($CURRENT_SCHEMA) {
	    unlink-all-relations $element
	}
    }

    # Delete the schema
    foreach element  $SCHEMA_ELEMENTS($CURRENT_SCHEMA) {
	set RELATIONS(schema) [ldelete $RELATIONS(schema) $element]
    }	
    set SCHEMA_ELEMENTS($CURRENT_SCHEMA) {}
    set SCHEMAS [ldelete $SCHEMAS $CURRENT_SCHEMA]
    set CURRENT_SCHEMA [lindex $SCHEMAS 0]
    install-schemas 
    mark-relations-edited
}

proc er-rename-schema {} {
  global SCHEMAS SCHEMA_ELEMENTS CURRENT_SCHEMA RELATIONS
    if { $CURRENT_SCHEMA == {}} { return }

  set newname [GetValue "Edit Schema Name?" $CURRENT_SCHEMA]
  if { $newname == {} } {return} 
  if { $newname == $CURRENT_SCHEMA } {
      tell-user "no change -- ignoring."
      return
   }
  if {[member $newname $SCHEMAS]} { 
      tell-user "Schema already exists -- ignoring."
      return
  }
 
  #1. change the element in schemas
  set pos [lsearch $SCHEMAS $CURRENT_SCHEMA]
  set SCHEMAS [lreplace $SCHEMAS $pos $pos $newname]

  #2. transfer the elements in SCHEMA_ELEMENTS
  set SCHEMA_ELEMENTS($newname) $SCHEMA_ELEMENTS($CURRENT_SCHEMA)
  set SCHEMA_ELEMENTS($CURRENT_SCHEMA) {}


  #3. change the display
  install-schema $newname

  mark-relations-edited
}

proc er-add-schema-element {} {
 global SCHEMA_ELEMENTS CURRENT_SCHEMA RELATIONS
    if { $CURRENT_SCHEMA == {}} { return }
 set relname [GetValue "Type in name of schema element"]
 if { $relname == {} } {return} 
 if [member $relname [list-all-relations]] {
     tell-user "Element name already in use"
     return
 }
 lappend SCHEMA_ELEMENTS($CURRENT_SCHEMA) $relname 
 lappend RELATIONS(schema) $relname 
 .reledit.main.table.choices insert end "$relname"
 .reledit.main.table.choices see end 
 .reledit.main.table.choices selection clear active
 .reledit.main.table.choices selection set end 
 mark-relations-edited
}

proc er-delete-schema-element {} {
  global SCHEMA_ELEMENTS CURRENT_SCHEMA RELATIONS
  if { $CURRENT_SCHEMA == {}} { return }
  set currindex [.reledit.main.table.choices curselection]
  set relname [.reledit.main.table.choices get active]

  if [relation-in-use $relname] {
      if { [ask-user "Relation in use: really delete?"] != "yes"} {
	  return 0
      }
      unlink-all-relations $relname
  }

  .reledit.main.table.choices delete $currindex
  delete SCHEMA_ELEMENTS($CURRENT_SCHEMA) $relname
  delete RELATIONS(schema) $relname
  .reledit.main.table.choices see $currindex
  .reledit.main.table.choices selection set $currindex
    mark-relations-edited
}

proc er-rename-schema-element {} {
  global SCHEMA_ELEMENTS CURRENT_SCHEMA RELATIONS

    if { $CURRENT_SCHEMA == {}} { return }
    set element [.reledit.main.table.choices get active]
    set newrelname [GetValue "New Element Name?" $element]
    if { $newrelname == {} } {return} 
    if { $newrelname == $element } {
	tell-user "no change -- ignoring."
	return
    }
    
    ## BUG - doesnt check if element name exists in other schema
    if [member $newrelname [list-all-relations]] { 
	tell-user "Schema Element nmae already in use -- ignoring."
	return
    }
    
    # we have a valid element
    # a) delete all old entries
    set pos [lsearch $SCHEMA_ELEMENTS($CURRENT_SCHEMA) $element]
    set SCHEMA_ELEMENTS($CURRENT_SCHEMA)\
	    [lreplace $SCHEMA_ELEMENTS($CURRENT_SCHEMA) $pos $pos $newrelname]

    set pos [lsearch $RELATIONS(schema) $element]
    set RELATIONS(schema)\
	    [lreplace $RELATIONS(schema) $pos $pos $newrelname]
    
    # a) register the new entry in the listbox
    install-schema $CURRENT_SCHEMA
    rename-all-relations $element $newrelname
    mark-relations-edited
}



proc install-schema {schema} {
    global SCHEMA_ELEMENTS CURRENT_SCHEMA 
    set CURRENT_SCHEMA $schema
    
    puts "install-schema: $schema"
    # Delete all entries
    .reledit.main.table.choices delete 0 end
    
    # Add the new
    if { $schema == {}} { return }
    foreach schema $SCHEMA_ELEMENTS($schema) {
	.reledit.main.table.choices insert end $schema
    }
    .reledit.main.table.choices selection set 0 
}




