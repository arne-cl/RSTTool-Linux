######################################
## RSTTool2.0 & Coder3.0
#
#  File: Segment.tcl
#  Author: Mick O'Donnell micko@dai.ed.ac.uk
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms, a copy of which may be viewed at:
#  http://www.dai.ed.ac.uk/staff/personal_pages/micko/RSTTool/copyright.html
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.


# Architecture:
#
#  text is segmented and edited in the editor. 
#  The Structurer can add structural details to
#    the datastructures, but doesn't change the text.
#  When saving, we save the text with structural annotations.

# Thus, no loss of formatting information.
# Switch to editing is quicker.

# when we create a segment, we also create its structure element.
# when we delete a segment, check to see if any parent structure to lose.

##########################################
# CONSTRUCT THE SEGMENTER INTERFACE

proc make-segment-frame {} {
    global PICT_DIR

    if [winfo exists .segment] {destroy .segment}
    frame .segment

    # Define the three window elements
    make-segmenter-tbar
    # FileBar .segment.topbar CODINGS_FILE "Codings file"
    scrolled-text .segment.editor -font "-*-Courier-Medium-R-Normal--16-140-*-*-*-*-*-*"

    # Define a few icons and bindings
    set sep_icn [file join $PICT_DIR sep.bmp ]
    image create bitmap .sep -file $sep_icn -foreground green
    .segment.editor.text tag config break -foreground red

    # Pack the subwindows
    pack .segment.tbar -side left  -anchor nw  -pady 1c
    # pack .segment.topbar -side top -fill x -expand t -anchor nw
    pack .segment.editor -side bottom -fill both -expand true -anchor n\
	     -pady 0.2c -padx 0.1c
    # pack .segment.editor -side left -pady 0.2c -padx 0.1c  -anchor nw -expand 1 -fill both

    return .segment
}

proc make-segmenter-tbar {} {
    global TOOL
    # Define a toolbar
    if {[winfo exists .segment.tbar]} {destroy .segment.tbar}
    
    frame .segment.tbar 

    Toolbar .segment.tbar.mode vertical "Modes:"
    ToolbarItem .segment.tbar.mode  "Segment"\
	    "In Segment mode, mouse-clicks add/remove segment boundaries"\
	    segmentmode
    ToolbarItem .segment.tbar.mode  "Edit" "In Edit mode, you can add/modify/delete text"\
	    editmode

    Toolbar .segment.tbar.action vertical "Segment:"
    ToolbarItem .segment.tbar.action  "Sentences"\
	    "Click here to place segment marks at sentence boundaries" {segment-sentences}
    ToolbarItem .segment.tbar.action  "Paragraphs"\
	    "Click here to place segment boundaries at paragraph boundaries" {segment-paragraphs}
   


    Toolbar .segment.tbar.find vertical "Search:"
    ToolbarItem .segment.tbar.find  "Find"\
	    "Click here to search for text" {segment-find}
    ToolbarItem .segment.tbar.find "Find Again" "Click here to find the next occurence of the text" {segment-findagain}

    pack  .segment.tbar.mode .segment.tbar.action  -pady 0.1c
    if { $TOOL == "coder"} {
	Toolbar .segment.tbar.other vertical "Other:"
	ToolbarItem .segment.tbar.other "Color Code"\
		"Each coding will be colored depending on its features"\
		{segment-select-colorcode %x %y}
	pack .segment.tbar.other -pady 0.1c
    }
#	    .segment.tbar.findtext .segment.tbar.find  -side top     
}

proc segment-find {} {
}

proc search-text-wgt {wgt} {
    global SRCHQUERY
    #  position this near top of screen
    set f [modal-dialog .search]
    wm geometry $f +20+20
    frame $f.top 
    label $f.top.label -text "Search for text: "
    entry $f.top.entry -bg white -relief sunken -textvariable SRCHQUERY\
	    -width 60 -borderwidth 1
    pack $f.top.label  $f.top.entry -side left -padx 5

    frame $f.bot
    button $f.bot.done -text "Find" -command "find-next $wgt $SRCHQUERY"

    button $f.bot.cancel -text "Close" -command  "destroy $f"
    pack $f.bot.done  $f.bot.cancel -side left -padx 15
    bind $f <Return>  {global SRCHQUERY;return-from-modal .asker "$SRCHQUERY"}
    bind $f <Control-c> "return-from-modal .asker 0"
   
    pack $f.top $f.bot -side top
}

proc find-next {wgt text} {
    selection clear -displayof $wgt
    if { $text == {} } {bell; return}
    # set currpos [$wgt index
    set pos [$wgt search $text 1.0]
    $wgt see $pos
    set len [string length $text]
    $wgt tag add sel $pos $pos + $len chars
}

proc clear-text {} {
    .segment.editor.text delete 1.0 end
}

#################################
# EXIT the Interface

proc uninstall-segmenter {} {
    update-structure 
    bind .segment.editor.text <Button-1> {}
    bind .segment.editor.text <Double-ButtonPress-1> {}
    bind .segment.editor.text <Triple-ButtonPress-1> {}
    bind .segment.editor.text <Motion> {}
    bind .segment.editor.text <KeyPress> {}
    bind .segment.editor.text <Button-1> {}
    bind .segment.editor.text <KeyPress-Delete> {}
    bind .segment.editor.text <KeyPress-BackSpace> {}
}


proc install-segmenter {} {
    global CURRENT
    segmentmode
    
    # Jump to the current
    if { [info exists CURRENT] == 1 && $CURRENT != {} } {
	set end [lindex [.segment.editor.text tag nextrange $CURRENT 1.0] 0]
	set lastbreak [.segment.editor.text tag prevrange break $end]
	if { $lastbreak != ""} { 
	    .segment.editor.text yview [lindex $lastbreak 0]
	}
	#	.segment.editor.text tag configure 
    }
    segment-colorcode
}
	

proc update-structure {} {
    global LASTSEG TEXT_NODES
    set TEXT_NODES {}
    # 1. Find the ordered list of segments
    set breaks [.segment.editor.text tag ranges "break"]
    initProgress "Analysing text segments" [llength $breaks]
    set LASTSEG 1.0
    set count 1
    while { $breaks != {} } {
	set startm [pop breaks]
	set endm [pop breaks]
	incr count 2
	updateProgress $count
	if { [.segment.editor.text index "$startm+1 char"] != $endm} {
	    set start [split $startm "."]
	    set line [lindex $start 0]
	    set startchar [expr [lindex $start 1] + 1]
	    set endchar [lindex [split $endm "."] 1]
	    for {set char $startchar} {$char<=$endchar} {incr char} {
		grab-seg "$line.$char"
	    }
	} else {
	    grab-seg $endm
	}
    }
    closeProgress
}

proc grab-seg {endm} {
    global LASTSEG NODE TEXT_NODES
    set seg [segtag "$endm - 1 char"]
    set NODE($seg,text) [string trim [.segment.editor.text get $LASTSEG $endm]]
    regsub -all "\n" $NODE($seg,text) " " NODE($seg,text)
    regsub -all "  " $NODE($seg,text) " " NODE($seg,text)
    set LASTSEG $endm
    lappend TEXT_NODES $seg
}



proc segtag {indx} {
    set tags [.segment.editor.text tag names $indx]
    foreach tag $tags {
	if { $tag != "break" && $tag != "sel" } {return $tag}
    }
    error [concat "segtag: No tag: " $tags]
}




#################
# MODES
proc segmentmode {} {
    rollover-message "Segment Mode"
    bind .segment.editor.text <Button-1> {segment-at-current;break}
    bind .segment.editor.text <Double-ButtonPress-1> {break}
    bind .segment.editor.text <Triple-ButtonPress-1> {break}
    bind .segment.editor.text <Motion> {break}
   
    .segment.editor.text tag bind break <Enter> {
	rollover-message "Click to delete segment boundary"
	.segment.editor.text config -cursor X_cursor
    }
    .segment.editor.text tag bind break <Leave> {
	rollover-message "Click to insert segment boundary"
	.segment.editor.text config -cursor bottom_tee
    }
    .segment.editor.text config -cursor bottom_tee
    .segment.tbar.mode.edit configure -relief raised
    .segment.tbar.mode.segment configure -relief sunken
    bind .segment.editor.text <KeyPress> {bell;break}
}

proc editmode {} {
    rollover-message "Edit Mode"
    .segment.editor.text tag bind break <Enter> {}
    .segment.editor.text tag bind break <Leave> {}
    bind .segment.editor.text <Motion> {}
    bind .segment.editor.text <Control-d> {show-debug-menu;break}
    bind .segment.editor.text <KeyPress> { 
#	puts "keypress: %k / %A / %K"
	if { "%K" == "Caps_Lock" } {continue}
	if [boundary-in-selection] {
	    warn-boundary
	    break
	} else {
	    set segend [.segment.editor.text tag nextrange break "insert"]
	    if { $segend == {}} {
		tell-user "Cannot add text after final segment marker!"
		break
	    } else {
		mark-edited
	    }
	}
    }
    bind .segment.editor.text <Button-1> {}
    # disallow delete of segmarks
    bind .segment.editor.text <KeyPress-Delete> {
      if { [boundary-in-selection] != 0 ||\
           [boundary-p "insert"] == 1} {
		warn-boundary; break
	} 
	mark-edited
    }
    bind .segment.editor.text <KeyPress-BackSpace> {
      if { [boundary-in-selection] != 0 ||\
           [boundary-p "insert - 1 char"] == 1} {warn-boundary; break}
    }
    .segment.editor.text config -cursor xterm
    .segment.tbar.mode.edit configure -relief sunken
    .segment.tbar.mode.segment configure -relief raised
}


proc warn-boundary {} {
    bell
    tell-user "Can't delete text containing segment boundaries. Use Segment Mode to remove segment boundararies first."
}


######################################
# Define Procedures

proc import-file {file} {
    global TOOL CURRENT TEXT_FILE 
    
    switch -- $TOOL {
	rsttool {
	    global RST_FILE
	    set RST_FILE {}
	    wm title . [file tail [file rootname $file]].rs3
	    clear-structure
	}
	coder   {
	    global CODINGS_FILE
	    clear-codings
	    set CODINGS_FILE [file rootname $file].cd2
	    wm title . $CODINGS_FILE
	}
    }
    set TEXT_FILE $file
    load-file $file
   
    set CURRENT [new-text-node]
    new-segment end $CURRENT
    editmode
}


#######################################
## SEGMENTATION

proc new-segment {indx tag} {
    if { $tag == "sel" } {error "sel"}
    set wgt [.segment.editor.text image create $indx -image .sep]
    set pos [.segment.editor.text index $wgt]
    
    .segment.editor.text tag add break $pos
    .segment.editor.text tag add $tag  $pos
    mark-edited
}



proc segment-at {index} {
    global NODE

    #1. Find the end of segment mark
    set range [.segment.editor.text tag nextrange break $index]
    if { $range == {}} {
	bell
	return
    }
	
    set range1 [lindex $range 0]
    set range2 [lindex $range 1]

    #2. Find the tag index
    set segno [segtag  $range1]

    #3. Give it a new segment name
    .segment.editor.text tag remove $segno $range1 $range2
    .segment.editor.text tag add [new-text-node] $range1 $range2

    #4. Create a segment mark at $index
    new-segment $index $segno

    # Wipe any display info
    set NODE($segno,text) {}
    catch ".segment.editor.text tag remove sel sel.first sel.last"
}

proc segment-sentences {} {
    segment-at-string "\."   {"e.g." "eg." "i.e." "ie." "etc." "..." "vs." "cf." "et al."}
    segment-at-string "!" {"!!"}
    segment-at-string "?"  "??"
    segment-paragraphs
}
    

proc segment-paragraphs {} {
    # put a segmark if this line not blank, and next is.
    set end [.segment.editor.text index "end - 1 line"]
    set line 1
    while { [.segment.editor.text compare $line.end <= $end] != 0 } {
	set text [.segment.editor.text get $line.0 $line.end]
	if { [string trimright $text] != "" &&\
		[line-has-paragraph-break $line] == 0} {

	    set nextline [expr $line + 1]
	    set next [.segment.editor.text get $nextline.0 $nextline.end]
	    if { [string trimright $next] == "" } {
		segment-at  $line.end
	    }
	}
	incr line
    }
}

proc line-has-paragraph-break {line} {

    set lastbreak [.segment.editor.text tag prevrange "break" $line.end $line.0]
    if { $lastbreak != {} } {
	set postbreak [string trim [.segment.editor.text get [lindex $lastbreak 1] $line.end]]
	if {$postbreak == ""} {return 1}
    }
    return 0
}


proc segment-at-string {string  {exceptions {}}} {

# run thru the text and find each segment mark
# and store the mark-position on the list
# then run thru the text (backwards) inserting the seg mark.
# Avoid putting seg-mark where previous token is a seg-mark.

    set len [string length $string]
    .segment.editor.text mark set segstart 1.0
    
    set segend [.segment.editor.text search  -nocase -forw $string segstart end]
    while {$segend != {} && [.segment.editor.text compare segstart < $segend] } {

	# Move to the end of any repeated punctuation marks
	while { [.segment.editor.text get "$segend + 1 char"] == $string } {
	    set segend [.segment.editor.text index "$segend + 1 char"]
	}

	if ![exception-case-p $segend $len $exceptions] {
	    
	    segment-at "$segend + $len chars"
	    set segend [.segment.editor.text index "$segend + 1 char"]
	}
	

	    
	.segment.editor.text mark set segstart "$segend + $len chars"
	set segend [.segment.editor.text search -nocase -forw $string segstart end]
    }
}

proc segment-at-current {} {

    # if clicked on a segment marker, remove it.
    if  [boundary-p "current"] {
	join-segments current
    } else {
	segment-at  current 
    }
}

proc boundary-p {index} {
    foreach tag [.segment.editor.text tag names $index] {
	if { $tag == "break"} {return 1}
    }
    return 0
}

proc boundary-in-selection {} {

    # eliminate for no selection case
    if { [.segment.editor.text tag ranges sel] == {}} {return 0}

    set nextbreak [lindex [.segment.editor.text tag nextrange break sel.first] 0]
    if [.segment.editor.text compare sel.last > $nextbreak] {
	# we have a boundary
	return 1
    }
    return 0
}

proc exception-case-p {point len exceptions} {
    # true if segment mark already present
    if [boundary-p "$point + $len char"] {
	return 1
    }

    foreach exception $exceptions {
	set len [string length $exception]
	set space [.segment.editor.text get "$point - $len chars" "$point + $len chars"]
	if {[string first $exception $space] > -1 } {
	    return 1
	}
    }

    # check for "1." cases.  
    if { [.segment.editor.text get $point] == "."} {
	set pre [.segment.editor.text get "$point - 1 char"]
	if { $pre >= 0 &&  $pre <= 9 } {
	    return 1
	}
    }
    return 0
}
			 

proc join-segments {index} {

    #. Ensure we can remove the segmarker
    set rightend [lindex [.segment.editor.text tag nextrange break "$index + 1 char"] 0]
    if { $rightend == {}} {
	tell-user "Cannot delete final segment marker!"
	return
    }

    # 2.  Change the next segmarker to the deleted tag
    set lefttag  [segtag $index]
    set righttag [segtag  $rightend]
    .segment.editor.text tag delete $righttag
    .segment.editor.text tag add $lefttag $rightend

    # remove structural info on the  right segment
    forget-node $righttag 

    # remove the old segmarker
    .segment.editor.text delete $index
    mark-edited
}

proc get-text {seg} {
    set segend [lindex [.segment.editor.text tag ranges $seg] 0]
    set segstart [lindex [.segment.editor.text tag prevrange break $segend] 1]
    if { $segstart == {} } {set segstart 1.0}
    return  [.segment.editor.text get $segstart $segend]
}


proc segment-colorcode {} {
    global SEGMENT_COLOR_SYSTEM TEXT_NODES SYSTEM NODE
    set colors {red blue brown green orange pink purple yellow} 

    # Remove any existing color tags
    if [winfo exists .segment.tbar.colcode] {destroy .segment.tbar.colcode}
    foreach color $colors {
	.segment.editor.text tag delete $color
    }
    .segment.editor.text tag delete gray


    if ![info exists SEGMENT_COLOR_SYSTEM] {return}
    if ![info exists SYSTEM($SEGMENT_COLOR_SYSTEM,features)] {set SEGMENT_COLOR_SYSTEM ""}

    if { $SEGMENT_COLOR_SYSTEM == ""} {
	return
    }
    set features $SYSTEM($SEGMENT_COLOR_SYSTEM,features)

    # place the color code
    frame .segment.tbar.colcode

    set count -1
    label .segment.tbar.colcode.code -text "CODE:" 
    pack .segment.tbar.colcode.code -side top -anchor nw
    

    foreach feature $features {
	incr count
	set color [lindex $colors $count]
	label .segment.tbar.colcode.$count -text $feature -fg $color
	pack .segment.tbar.colcode.$count  -anchor nw
	.segment.editor.text tag config $color -foreground $color
    }
    label .segment.tbar.colcode.none -text "not applicable" -fg grey
    pack .segment.tbar.colcode -pady 0.2c

    foreach nid $TEXT_NODES {

	if { $NODE($nid,ignore) == 1} {

	    set color grey
	} else {
	    set feat [intersection $features $NODE($nid,features)]
	    if { $feat == {}} {
		set color grey
	    } else {
		set order [lsearch -exact $features $feat ]
		set color [lindex $colors $order]
	    }
	}
	set segend [lindex [.segment.editor.text tag ranges $nid] 0]
	set segstart [lindex [.segment.editor.text tag prevrange break $segend] 1]
	if { $segstart == {} } {set segstart 1.0}
	.segment.editor.text tag add $color $segstart $segend 
    }
}


proc segment-select-colorcode {x y} {
    global  SEGMENT_COLOR_SYSTEM
    set systems [all-active-systems]
    set color [popup-choose-from-list $systems 30 30]
    if { $color != "cancelled"} {
	set SEGMENT_COLOR_SYSTEM $color
	segment-colorcode
    }
}
