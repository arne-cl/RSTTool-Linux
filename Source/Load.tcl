######################################
## RSTTool
#
#  File: Load.tcl
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


#######################################
## LOAD

proc load-rst {{rstfile {}}} {
    global RST_FILE RSTFORMAT TEXT_FILE  TEXT_NODES GROUP_NODES\
	    LASTTAG UNUSED_TAGS NODE DIR UNKNOWN_RELS

    if { [prompt-save-current-files] == "cancel"} {
	return 0
    }

    if { $rstfile == {}} {

	set default [default-directory rst]
	set initialfile [car [lsort [glob -nocomplain [file join $default "*.rs?"]]]]
	if { $initialfile == {}} {
	    set $initialfile untitled.rs3
	} else {
	    set initialfile [file tail $initialfile]
	}
	set rstfile [tk_getOpenFile\
		-filetypes {{{RST Files} {.rs3 .rs2 .rst .xml}}}\
		-initialfile  $initialfile -initialdir $default]
	if {$rstfile == {}} {return}
	
	if ![file exists $rstfile] {
	    tell-user "File not found: $rstfile"
	    return 0
	}
    }

    set RST_FILE $rstfile
    set TEXT_FILE {}

    #1. wipe the internal structure and canvas
    clear-structure
    init-relations
    clear-drawing
    start-watch-cursor
    set UNKNOWN_RELS {}

    switch -- [string tolower [file extension $RST_FILE]] {
	".rs2" -
	"xml" -
	".rs3" {
	    if [catch "load-rst2 \"$RST_FILE\"" result] {
		global errorInfo
		set msg [split $errorInfo "\n"]
		set msg [lindex $msg 0]
		tell-user "File: $RST_FILE is not an RSTTool file, or is corrupted. If the file was saved using RSTTool as a .rs2 or .rs3 file, please send the file to the author: micko@wagsoft.com. \nError message was:\n $msg"
		stop-watch-cursor
		return 0
	    }
	    
	    if { $result == 0 } {
		stop-watch-cursor
		return 0
	    }
	}
	
	".rst" {
	    if { [load-rst1 $RST_FILE] == 0 } {
		stop-watch-cursor
		return 0
	    }
	}
	default {
	    if { [load-rst2 $RST_FILE] == 0 } {
		stop-watch-cursor
		return 0
	    }
	}
    }

    # Establish child field
    set LASTTAG 0
    set used_tags [concat $TEXT_NODES $GROUP_NODES] 
    foreach nid $used_tags {
	set LASTTAG [max $LASTTAG $nid]
	if { $NODE($nid,parent) != {} } {
	    lappend NODE($NODE($nid,parent),children) $nid
	}
    }


    # If there were undefined relations (defaulted to mononuc)
    # then check if we can reclassify them using the parent type
    # (e.g., if parent of a rel is always multinuc)
    if { $UNKNOWN_RELS != {} } {
	tell-user "There were [llength $UNKNOWN_RELS] undefined relations. These have been automatically defined for you."

	check-relation-types $UNKNOWN_RELS
    }


    # find unused tags
    set UNUSED_TAGS {}
    for  {set i 1} {$i<$LASTTAG} {incr i} {
	if ![member $i $used_tags] {
	    lappend UNUSED_TAGS $i
	}
    }
    # Establish span field, start at any top nodes
    foreach nid $GROUP_NODES {
	if {$NODE($nid,span) == {} } {
	    set-subtree-node-span $nid
	}
    }

    # Change the window title
    wm title . [file tail $RST_FILE]

    # Layout/Draw the net
    stop-watch-cursor
    redraw-rst
    set-mode link
    mark-unedited
    clear-stats
    install-interface structurer
}





##############################
## LOADING


proc load-rst2-wc {file} {
    # Loads the codings, displaying a watch cursor
    start-watch-cursor
    if [catch "load-rst2 \"$file\""] {
	stop-watch-cursor
	BugReport "Error in loading $file. Check file and if ok send to micko@wagsoft.com with following details:"
	return 0
    }
    stop-watch-cursor
}
    
proc load-rst2  {file {encoding {}}} {
    # Expects a heirarchically structured xml form.
    # Only Segment tags can include free text.

    global ENCODING ROOT RELATIONS_FILE
    
    load-xml $file $encoding
    set rstform [parse-xml {encoding group rel}]

    #####################################
    # Check for international encoding
    # if $encoding is non-nil, this is the second pass through
    if { $encoding == {}} {
	set encoding  [get-xml-element $rstform {rst header encoding name}]
	if { $encoding != {} } {
	    # Call the function again but this time read in encoded mode.
	    set ENCODING $encoding
	    return [load-rst2 $file $encoding]
	} else {
	    if [info exists ENCODING] {unset ENCODING}
	}
    } else {
	set ENCODING $encoding
    }


    ###############################
    # parse the relations
    set reldef  [get-xml-element $rstform {rst header relations}]
    set relmaster [get-xml-element $reldef {relations file}]
    if { $relmaster == {} } {
	set RELATIONS_FILE {}
	init-relations
	foreach rel [get-xml-elements $reldef {relations rel}] {
	    parse-xml-relation $rel
	}
    } else {
	set relmaster [verify-relations-master $relmaster]
	if {$relmaster == {} } {
	    tell-user "No Relations file: loading without."
	    set RELATIONS_FILE {}
	    init-relations
	} elseif {$relmaster == "cancelled"} {
	    return 0
	} else {
	    load-relations-master $relmaster
	}
    }

    ################################
    # PARSE the body
    process-body [get-xml-element $rstform {rst body}]

    return 1
}

proc verify-relations-master {relmaster} {
    global RELATIONS_FILE RELS RST_FILE
    if [file exists $relmaster] {
	return $relmaster
    }
    
    ## 1. Check if the file is in the Relations DIR.
    set fname [file tail $relmaster]
    set altpath [file join $RELS $fname]
    if [file exists $altpath] {
	switch -- [ask-user "The recorded Relations file was not found at:\n   $relmaster.\n  Should I use the following instead?\n  $altpath"] {
	    yes { return $altpath }
	}
    }


    # Try in the same directory as the RST File
    set altpath [file join [file dirname $RST_FILE] $fname]
    if [file exists $altpath] {
	switch -- [ask-user "The recorded Relations file was not found at:\n   $relmaster.\n  Should I use the following instead?\n  $altpath"] {
	    yes { return $altpath }
	}
    }
    
    # No Alternatives - offer load/search
    switch -- [tk_dialog .relfind "Relations file location"\
	    "Relations $relmaster has been moved." \
	    {} 0  Locate "Try Without" "Cancel Load"] {
	0 { 
	    set newfile [tk_getOpenFile -initialfile [file tail $relmaster]\
		    -initialdir [file dirname $RST_FILE]]
	    if { $newfile != {} } {
		return $newfile
	    } else {
		return "cancelled"
	    }
	}
	1 {  return {} }
	
	2 { return "cancelled"} 
    }
}


proc process-body {body} {
    global NODE TEXT_NODES GROUP_NODES RELATIONS UNKNOWN_RELS
    

    #2. Load in group defins.
    foreach grp [get-xml-elements $body {body group}] {
	set id [get-xml-element $grp {group id}]
	clear-node $id
	set parent [get-xml-element $grp {group parent}]
	set relname [capitalise [get-xml-element $grp {group relname}]]
	lappend GROUP_NODES $id
	set NODE($id,type) [get-xml-element $grp {group type}]
	if {$NODE($id,type) == "constit"} {
	    set NODE($id,type) "schema"
	}
	if {$parent != {}} {
	    set NODE($id,parent) $parent
	    set NODE($id,relname)  $relname
	    if { [relation-type $relname] == 0 } {
		# not defined, autodefine
		lappend RELATIONS(rst) $relname

		puts "load-rst2: Unknown relation: $relname - defining as mononuclear."
		lappend UNKNOWN_RELS $relname
	    }
	}
    }

    #3. Load in segment defins
    foreach seg [get-xml-elements $body {body segment}] {
	set id [get-xml-element $seg {segment id}]
	set parent [get-xml-element $seg {segment parent}]
	clear-node $id
	lappend TEXT_NODES $id
	
	if { $parent != {} } {
	    set relname [capitalise [get-xml-element $seg {segment relname}]]
	    set NODE($id,parent) $parent
	    set NODE($id,relname) $relname
	    if { [relation-type $relname] == 0 } {
		# not defined, autodefine
		lappend RELATIONS(rst) $relname

		puts "load-rst2: Unknown relation: $relname - defining as mononuclear."
		lappend UNKNOWN_RELS $relname
	    }
	}
	set NODE($id,type) text
	set NODE($id,span) "$id $id"
	set text [lindex $seg 3]
	set text [unxmlify-text $text]

	set NODE($id,text) [string trim $text]
	regsub -all "\n" $NODE($id,text) " " NODE($id,text)
	regsub -all "  " $NODE($id,text) " " NODE($id,text)
	.segment.editor.text insert end  $text

        new-segment end $id
    }
}


proc parse-args {args} {
    set result {}
    set args [lindex $args 0]
    foreach arg $args {
	set arg  [split $arg {=}]
	set value [lindex $arg 1]
	regsub  -all {\"} $value {} value
	lappend result [list [string tolower [lindex $arg 0]]  $value]
    }
    return $result
}

proc parse-xml-relation {rel} {
    global RELATIONS SCHEMAS SCHEMA_ELEMENTS

    set name [capitalise [get-xml-element $rel {rel name}]]
    set type [get-xml-element $rel {rel type}]
    set schema [get-xml-element $rel {rel schema}]
    set schema [capitalise $schema]
    
    if { $schema != {} } {set type "schema"}
    if { $type == "constit" } {set type "schema"}
    
    lappend RELATIONS($type) $name
    
    # store the elements of each schema
    if { $type == "schema" } {
	if ![member $schema $SCHEMAS] {
	    lappend SCHEMAS $schema
	}
	lappend SCHEMA_ELEMENTS($schema) $name
    }
}


