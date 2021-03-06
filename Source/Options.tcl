######################################
## RSTTool 3.x
#
#  File: Options.tcl
#  Author: Mick O'Donnell micko@wagsoft.com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/RSTTool/copyright.html
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.



proc save-options {} {
    global RELATIONS_FILE SCHEME_FILE SCHEME_SRC COLOR

    set SCHEME_FILE $RELATIONS_FILE
    
    set f [modal-dialog .options]
    # wm geometry $f +20+40
    label $f.title -text "File Save Options" 
    
    frame $f.scheme -borderwidth 2   -relief sunken
    label $f.scheme.label -text "Relations:" 
    frame $f.scheme.options  
    
    radiobutton $f.scheme.options.text -text "Save Relations with text"\
	    -variable SCHEME_SRC  -value 0 \
	    -command disable-save-scheme-selection
    radiobutton $f.scheme.options.master -text "Save to Master:"\
	    -variable SCHEME_SRC  -value 1 \
	    -command enable-save-scheme-selection

    frame $f.scheme.file
    label $f.scheme.file.label -text "Master File:" 
    entry $f.scheme.file.entry  -bg white -relief sunken \
	    -textvariable SCHEME_FILE -width 30 -borderwidth 1
    button $f.scheme.file.button -text "Locate" -command {opt-select-scheme-file}\
	    -bg $COLOR(buttons)
    help-button $f.scheme.help scheme
    
    pack  $f.scheme.options.master $f.scheme.options.text -side top -anchor w
    

    # set one of the buttons
    if { $SCHEME_FILE == {} } {
	set SCHEME_SRC 0
	disable-save-scheme-selection 
    } else {
	set SCHEME_SRC 1
	enable-save-scheme-selection
    }

    pack $f.scheme.file.label $f.scheme.file.entry $f.scheme.file.button\
	    -side left  -padx 5 
    
    pack $f.scheme.label $f.scheme.options -side left 
    pack $f.scheme.file -side top  -padx 5
    pack $f.scheme.help -side top  -padx 5
    pack $f.title  $f.scheme -fill x -expand t
    
    frame $f.buttons 
    button $f.buttons.ok -text "Done" -underline 0 \
	    -command "set-save-options-action"  -bg $COLOR(buttons)
    button $f.buttons.cancel -text Cancel -command "return-from-modal $f 0" \
	    -underline 0  -bg $COLOR(buttons)
    bind $f <Return> "set-save-options-action"
    bind $f <Control-c> "return-from-modal $f 0"
    
    pack $f.buttons.ok $f.buttons.cancel  -padx 15 -side left
    pack $f.buttons -pady 10
    post-modal $f
}

proc disable-save-scheme-selection {} {
    .options.scheme.file.label config -fg gray
    .options.scheme.file.button config -state disabled
    .options.scheme.file.entry config -state disabled
    .options.scheme.file.entry config -fg gray
}

proc enable-save-scheme-selection {} {
    .options.scheme.file.label config -fg black
    .options.scheme.file.button config -state normal
    .options.scheme.file.entry config -state normal
    .options.scheme.file.entry config -fg black
}

proc set-save-options-action {} {
    global RELATIONS_FILE SCHEME_SRC SCHEME_FILE
    debug "set-save-options-action"
    if {$SCHEME_SRC == 0 } {
	set RELATIONS_FILE {}
    } else {
	if {$SCHEME_FILE == {} } {
	    return 0
	}
	set RELATIONS_FILE $SCHEME_FILE
    }
    return-from-modal .options 1
}


proc opt-select-scheme-file {} {
  global SCHEME_FILE RELS RELATIONS_FILE
  set SCHEME_FILE [tk_getSaveFile -title "Select Relations File" -initialdir $RELS -initialfile $RELATIONS_FILE -parent .options]
}



proc appearance-options {} {
    global COLOR TMP_COLOR NODE_WIDTH TMP_NODE_WIDTH TEXT_FONT_FAMILY TMP_TEXT_FONT_FAMILY\
	    TMP_TEXT_FONT_SIZE TEXT_FONT_SIZE
    set TMP_COLOR(text) $COLOR(text)
    set TMP_COLOR(relation) $COLOR(relation)
    set TMP_COLOR(span) $COLOR(span)
    set TMP_COLOR(background) $COLOR(background)
    set TMP_COLOR(buttons) $COLOR(buttons)
    set TMP_NODE_WIDTH $NODE_WIDTH
    
   if [info exists TEXT_FONT_FAMILY] {
        set TMP_TEXT_FONT_FAMILY $TEXT_FONT_FAMILY
   } else {
       set TMP_TEXT_FONT_FAMILY [window-font-family .segment.editor.text]
   }

   if [info exists TEXT_FONT_SIZE] {
        set TMP_TEXT_FONT_SIZE $TEXT_FONT_SIZE
   } else {
       set TMP_TEXT_FONT_SIZE [window-font-size .segment.editor.text]
   }
   
    set f [modal-dialog .aoptions]
    label $f.title -text "Appearance Options" 
    
    # The subframe
    frame $f.appear -borderwidth 2  -relief sunken

   ColorChooser $f.appear.back "Background Color" TMP_COLOR(background)
   ColorChooser $f.appear.butt "Button Color" TMP_COLOR(buttons)
   ColorChooser $f.appear.text "Text Color" TMP_COLOR(text)
   ColorChooser $f.appear.relation "Relation Color" TMP_COLOR(relation)
   ColorChooser $f.appear.span "Span Label Color" TMP_COLOR(span)
   TextChooser $f.appear.nodewidth "Width of Text Columns" TMP_NODE_WIDTH
   pack $f.appear.text $f.appear.relation $f.appear.span\
	   $f.appear.back $f.appear.butt $f.appear.nodewidth -side top


    # Change the font family
    frame $f.font
    label  $f.font.label -text "Font: " 
    button $f.font.change -textvar TMP_TEXT_FONT_FAMILY  -bg $COLOR(buttons)
  
    bind $f.font.change <ButtonRelease-1> {
	set fonts [concat [list "RSTTool default"] [lsort [font families]]]
	set result [popup-choose-from-list $fonts %x %y]
	if {$result != "cancelled"} {
	    set TMP_TEXT_FONT_FAMILY $result
	}
    }
    label  $f.font.label2 -text "Size: " 
    button $f.font.change2 -textvar TMP_TEXT_FONT_SIZE  -bg $COLOR(buttons)
  
    bind $f.font.change2 <ButtonRelease-1> {
	set sizes {8 9 10 11 12 14 16 18 24}
	set result [popup-choose-from-list $sizes %x %y]
	if {$result != "cancelled"} {
	    set TMP_TEXT_FONT_SIZE $result
	}
    }
    pack  $f.font.label $f.font.change  $f.font.label2 $f.font.change2 -side left


    pack  $f.title  $f.appear $f.font -fill x -expand t

    frame $f.buttons 
    button $f.buttons.set -text "Set" -underline 0 \
	    -command "set-appear-options-action"  -bg $COLOR(buttons)
    button $f.buttons.ok -text "Apply" -underline 0 \
	    -command "apply-appear-options-action"  -bg $COLOR(buttons)
    button $f.buttons.cancel -text Cancel -command "return-from-modal $f 0" \
	    -underline 0  -bg $COLOR(buttons)
    bind $f <Return> "set-appear-options-action"
    bind $f <Control-c> "return-from-modal $f 0"
    
    pack $f.buttons.set $f.buttons.ok $f.buttons.cancel  -padx 15 -side left
    pack $f.buttons -pady 10
    post-modal $f
}



proc ColorChooser {path label var} {
    global COLORS COLOR
    frame $path 
    label $path.label -text "$label: " 
    eval [concat "tk_optionMenu  $path.popup $var" $COLORS]
    pack $path.label $path.popup -side left
}

proc TextChooser {path label var} {
    frame $path 
    label $path.label -text "$label: " 
    entry $path.entry -textvariable $var -bg white
    pack $path.label $path.entry -side left
}




proc set-appear-options-action {} {
    apply-appear-options-action
    if [catch "save-preferences"] {
	global DIR
	tell-user "Could not save color options to file [file join $DIR .options]"
    }
}

proc apply-appear-options-action {} {
    global COLOR TMP_COLOR NODE_WIDTH TMP_NODE_WIDTH  HALF_NODE_WIDTH\
	    TMP_TEXT_FONT_FAMILY TEXT_FONT_FAMILY TEXT_FONT\
	    TMP_TEXT_FONT_SIZE TEXT_FONT_SIZE YINCR ACTUAL_FONT_SIZE

    if ![integer-p $TMP_NODE_WIDTH] {
	tell-user "Text Column width must be an integer!" .aoptions
	return
    }

    set redraw 0

    if {  $NODE_WIDTH != $TMP_NODE_WIDTH } {
	set NODE_WIDTH $TMP_NODE_WIDTH
	set HALF_NODE_WIDTH  [expr $NODE_WIDTH / 2]
	set redraw 1
    }

    if { $COLOR(background) != $TMP_COLOR(background)} {
	set COLOR(background) $TMP_COLOR(background)
	tk_setPalette $COLOR(background)
    }

    if { $COLOR(buttons) != $TMP_COLOR(buttons)} {
	set COLOR(buttons) $TMP_COLOR(buttons)
	recolor-buttons
    }

    if { $COLOR(text) != $TMP_COLOR(text)} {
	set COLOR(text) $TMP_COLOR(text)
	set redraw 1
    }
    if { $COLOR(relation) != $TMP_COLOR(relation)} {
	set COLOR(relation) $TMP_COLOR(relation)
	set redraw 1
    }
    if { $COLOR(span) != $TMP_COLOR(span) } {
	set COLOR(span) $TMP_COLOR(span)
	set redraw 1
    }

    if ![info exists TEXT_FONT_FAMILY] {
	set TEXT_FONT_FAMILY [window-font-family .segment.editor.text]
    } 
    if ![info exists TEXT_FONT_SIZE] {
	set TEXT_FONT_SIZE [window-font-size .segment.editor.text]
    } 

    set fontchanged 0
    if { $TEXT_FONT_FAMILY != $TMP_TEXT_FONT_FAMILY } {


	set TEXT_FONT_FAMILY $TMP_TEXT_FONT_FAMILY
	set fontchanged 1
    }
    if { $TEXT_FONT_SIZE != $TMP_TEXT_FONT_SIZE } {
	set TEXT_FONT_SIZE $TMP_TEXT_FONT_SIZE
	set fontchanged 1
    }

    if { $fontchanged == 1} {
	if { $TEXT_FONT_FAMILY == "RSTTool default"} {
	    set TEXT_FONT "default"
	} else {
	    set TEXT_FONT [font create -family $TEXT_FONT_FAMILY -size $TEXT_FONT_SIZE]
	}
	set ACTUAL_FONT_SIZE [font actual $TEXT_FONT -size]
	puts "FONT SIZE:  $TEXT_FONT_SIZE ACTUAL: $ACTUAL_FONT_SIZE"
	set YINCR [expr 30 + $ACTUAL_FONT_SIZE - 8]

	.segment.editor.text config -font $TEXT_FONT
	set redraw 1
    }

    if { $redraw == 1} {
	redraw-rst
    }
    return-from-modal .aoptions 1
}


proc window-font-family {window} {
    return [lindex [lindex [$window config -font] 3] 0]
}

proc window-font-size {window} {
    return [lindex [lindex [$window config -font] 3] 1]
}



proc recolor-buttons {{path .}} {
    global COLOR
    foreach wid [winfo children $path] {
	if { [winfo class $wid] == "Button"} {
	    $wid config -bg $COLOR(buttons)
	} else {
	    recolor-buttons $wid
	}
    }
}



proc save-preferences {} {
    global COLOR DIR NODE_WIDTH REGISTERED
    set file [file join $DIR .preferences]
    set str [open $file w]
    puts $str "global COLOR NODE_WIDTH REGISTERED"
    puts $str "set COLOR(text) $COLOR(text)"
    puts $str "set COLOR(relation) $COLOR(relation)"
    puts $str "set COLOR(span) $COLOR(span)"
    puts $str "set COLOR(background) $COLOR(background)"
    puts $str "set COLOR(buttons) $COLOR(buttons)"
    puts $str "set NODE_WIDTH $NODE_WIDTH"
    puts $str "set HALF_NODE_WIDTH  [expr $NODE_WIDTH / 2]"
    if [info exists REGISTERED] {
	puts $str "set REGISTERED $REGISTERED"
    }
    close $str
    return 1
}

