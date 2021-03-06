######################################
## RSTTool
#
#  File: Save.tcl
#  Author: Mick O'Donnell micko@wagsoft.com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute  this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/RSTTool/copyright.html
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.

###################################################




###################################################
# Save RST


proc prompt-save-current-files {} {
    global CHANGED

    # Files not loaded yet
    if ![info exists CHANGED] {return}

    if {[prompt-save-current-analysis] == "cancelled"} {
	return cancelled
    }

    if {[prompt-save-current-relations] == "cancelled"} {
	return cancelled
    }
}
    
proc prompt-save-current-analysis {} {
    global CHANGED TEXT_FILE RST_FILE
    # if changes to the codings or scheme, prompt for save.
    # if relations
    
    if { $CHANGED == 1 } {
	set result [tk_dialog .d1 {File Clear} "Save Current Work?"\
		warning 0 {Yes} {No} "Cancel"]
	switch -- $result {
	    0 {return [save-rst]}
	    2 {return cancelled}
	}
    }
}

proc prompt-save-current-relations {} {
    global RELATIONS_FILE RELATIONS_MODIFIED
    if { $RELATIONS_FILE == {}} { return}
    if { $RELATIONS_MODIFIED == 1 } {
    set result [tk_dialog .d1 {File Clear} "Save Relations File?"\
		warning 0 {Yes} {No} "Cancel"]
	switch -- $result {
	    0 {return [save-relations-master]}
	    2 {return cancelled}
	}
    }
}

proc mark-edited {} {
    global CHANGED
    if { $CHANGED != 1} {
	set CHANGED 1
	MenuItemEnable .menuBar "File" "Save RST"
    }
}

proc mark-unedited {} {
    global CHANGED UNDO_STACK REDO_STACK
    if {$CHANGED != 0} {
	set CHANGED 0
	MenuItemDisable .menuBar "File" "Save RST"
    }
    set UNDO_STACK {}
    set REDO_STACK {}
}


proc default-directory {{type {}}} {
    global DIR RST_FILE TEXT_FILE RELATIONS_FILE ANALYSES

    switch -- $type {
	rst {
	    if [valid-filevar-p RST_FILE] {
		return [file dirname $RST_FILE]
	    }
	    if [valid-filevar-p TEXT_FILE] {
		return [file dirname $TEXT_FILE]
	    }

	    if [valid-dirvar-p ANALYSES] {
		return $ANALYSES
	    }

	    return $DIR
	}

	text {
	    if [valid-filevar-p TEXT_FILE] {
		return [file dirname $TEXT_FILE]
	    }
	    if [valid-filevar-p RST_FILE] {
		return [file dirname $RST_FILE]
	    }

	    if [valid-dirvar-p ANALYSES] {
		return $ANALYSES
	    }

	    return $DIR
	}
	relations {
	    if [valid-filevar-p RELATIONS_FILE] {
		return [file dirname $RELATIONS_FILE]
	    }
	    return [default-directory rst]
	}
    }
    
    return  $DIR
}

proc default-file {{ext {}}} {
    global RST_FILE TEXT_FILE DIR

    if [valid-filevar-p RST_FILE] {
	if { $ext == {}} {set ext [file extension $RST_FILE]}
	return [file join [file root $RST_FILE]$ext]
    }
    if { $ext == {}} {set ext ".rs3"}
    if [valid-filevar-p TEXT_FILE] {
	return [file join [file root $TEXT_FILE]$ext]
    }
    return [file join $DIR untitled$ext]
}

proc valid-filevar-p {var} {

    upvar $var path
    global $var
    if ![info exists $var] {return 0}
    if { $path == ""} {return 0}
    if ![file exists $path] {return 0}
    return 1
}

proc valid-dirvar-p {var} {

    upvar $var path
    global $var
    if ![info exists $var] {return 0}
    if { $path == ""} {return 0}
    if ![file isdirectory $path] {return 0}
    return 1
}



#####################
### SAVE

# The primary format is xml
# to save as another form requires selection from the save-as
# menu.
# maybe prompt if load-form different from xml.

# rels can be in a master (so they should be updated)
# or in the document.
# if RELATIONS_FILE is {}, include

proc save-rst {{file {}}} {
    global RST_FILE CURRENT_INTERFACE

    if {$file != {} } {
	set RST_FILE $file
    }
    
    if { $RST_FILE == {} } {
	return [save-rst-as]
    }

    # ensure the TEXT_NODES list is up to date
    if { $CURRENT_INTERFACE == "segment"} {
        update-structure
    }
    switch -- [string tolower [file extension $RST_FILE]] {
	cancel {return cancelled}
	.rst {save-rst1 $RST_FILE}
	.rs2 {save-rst2 $RST_FILE}
	.xml {save-rst3 $RST_FILE}
	.rs3 {save-rst3 $RST_FILE}
	default {tell-user "Save-RST: Unknown Format: [file extension $RST_FILE]";return cancel}
    }
    mark-unedited
    # Change the window title
    wm title . [file tail $RST_FILE]
}

proc save-rst-as {} {
    global RST_FILE TEXT_FILE
    set defdir [default-directory rst]
    
    if {$RST_FILE != {} } {
	set deffile [file tail $RST_FILE]
    } elseif { $TEXT_FILE != {} } {
	set deffile [file tail $TEXT_FILE]
    } else {
	set deffile "untitled.rs3"
    }

    set file [tk_getSaveFile -filetypes {{{RST Version 3} {.rs3}} {{RST Version 2} {.rs2}} {{RST Version 1} {.rst}}}\
	    -initialfile $deffile -initialdir $defdir]
    if { $file == {} } {
	return cancelled
    }

    save-rst $file
}


proc save-text {{file {}}} {
    global TEXT_FILE CURRENT_INTERFACE RST_FILE
    
    if {$file == {} } {
	if {$TEXT_FILE != {} } {
	    set default $TEXT_FILE
	} elseif {$RST_FILE != {} } {
	    set default [file rootname $RST_FILE].txt
	} else {
	    set default [file join $DIR "Analyses" "untitled.txt"]
	}
	set defdir [file dirname $default]
	set deffile [file tail $default]
	set file [tk_getSaveFile -initialfile $deffile -initialdir $defdir]
	if { $file == {} } {
	    return cancelled
	}
    }

    set TEXT_FILE $file

    # ensure the TEXT_NODES list is up to date
    if { $CURRENT_INTERFACE == "segment"} {
        update-structure
    }
    
    set text [.segment.editor.text get 1.0 end]
    write-file $file $text
}




### RST FILE FORMAT rs2
#
## XML based format

proc tmp {} {
    "<rst>
    <header>
    <relations file=\"ddd.rels\"></relations>

    or <relations>
    <rel name=\"exception\" type=\"rst\">
    <rel name=\"conjunction\" type=\"multinuc\">
    <rel name=\"introduction\" type=\"constit\" schema=\"document\">
    </relations>
    </header>
    <body>
    <segment id=1 par=13 rel=\"span\">The cat sat.</segment>
    <segment id=2 par=1 rel=\"exception\">except on Wednesday.</segment>
    <group id =13 type=span>
    </body>
    </rst>"
}


#####################################
## SAVING

proc save-rst2 {file} {
    global RST_FILE RSTFORMAT RELATIONS_FILE NODE TEXT_NODES GROUP_NODES\
	    RELATIONS SCHEMAS SCHEMA_ELEMENTS ENCODING
    # Open the file
    set f [open $file w 0600]
    
    # Put the header opener
    puts $f "<rst>"
    puts $f "  <header>"

        # Register an internationalisation encoding (if any)
    if [info exists ENCODING] {
	if { $ENCODING != "Standard"} {
	    puts $f "    <encoding name=\"$ENCODING\" />"
	    tell-user "Saving in $ENCODING format"
	    fconfigure $f -encoding $ENCODING
	}
    }
    
    # save the relations field
    if { $RELATIONS_FILE != {} } {
	puts $f "    <relations file=\"$RELATIONS_FILE\"></relations>"
	save-relations-master $RELATIONS_FILE
    } else {
	puts $f "    <relations>"
	foreach rel $RELATIONS(rst)  {
	    set rel [string tolower $rel]
	    puts $f "      <rel name=\"$rel\" type=\"rst\">"
	}
	foreach rel $RELATIONS(multinuc)  {
	    set rel [string tolower $rel]
	    puts $f "      <rel name=\"$rel\" type=\"multinuc\">"
	}

	foreach schema $SCHEMAS {
	    foreach rel $SCHEMA_ELEMENTS($schema) {
		set rel [string tolower $rel]
		puts $f "      <rel name=\"$rel\" schema=\"$schema\">"
	    }
	}

	puts $f "    </relations>"
    }
    puts $f "  </header>"

    # Save the text
    puts $f "  <body>"
    foreach itm $TEXT_NODES {
	if { $NODE($itm,parent) != {} } {
	    set rel [string tolower $NODE($itm,relname)]
	    set parent " parent=$NODE($itm,parent) relname=\"$rel\""
	} else {
	    set parent ""
	}
	set text [get-text $itm]
	regsub -all "<" $text {\&lt;} text
	regsub -all ">" $text {\&gt;} text

	puts $f "    <segment id=$itm$parent>$text</segment>"
    }
    
    foreach itm $GROUP_NODES {
	if { $NODE($itm,parent) != {} } {
	    set rel [string tolower $NODE($itm,relname)]
	    set parent " parent=$NODE($itm,parent) relname=\"$rel\""
	} else {
	    set parent ""
	}
	puts $f "<group id=$itm type=\"$NODE($itm,type)\"$parent>"
    }

    # Close the file
    puts $f "  </body>"
    puts $f "</rst>"
    close $f
    mark-unedited
}

