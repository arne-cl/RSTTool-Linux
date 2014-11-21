global COLOR
if ![info exists COLOR(background)] {set COLOR(background) "#FCD98E"}
if ![info exists COLOR(buttons)] {set COLOR(buttons) "#F6C19E"}


proc Toolbar {name {direction vertical} {label {}}} {
    global ToolbarDir
    set ToolbarDir($name) $direction
    frame $name 
    if { $label != ""} {
	label $name.label -text $label -fg red
	if { $direction == "vertical" } {
	    pack $name.label -side top -anchor nw -fill x
	} else {
	    pack $name.label -side left -anchor nw 
	}
    }
}


proc ToolbarItem {Tbar Text Msg Cmd {height 1}} {
    global ToolbarDir COLOR BUTTON_FONT
    set Iname $Tbar.[label-to-name $Text]
    button $Iname -text $Text -command $Cmd -height $height -bg $COLOR(buttons)

    if [info exists BUTTON_FONT] {
	$Iname config -font $BUTTON_FONT
    }

    if { $ToolbarDir($Tbar) == "vertical" } {
	pack $Iname -side top -anchor nw -fill x
    } else {
	pack $Iname -side left -anchor nw 
    }

    # Set s a variable which can be displayed in a message display space
    if { $Msg != "" } {
	add-rollover-message $Iname $Msg
    }
    return $Iname
}


proc add-rollover-message {wgt message} {
    # Sets a variable to hold rollover message
    # Put a widget in your interface teo display it, e.g.,
    # label .lexicon.msg -relief sunken -textvariable ROLLOVER_MSG
    bind $wgt <Enter> "rollover-message \"$message\""
    bind $wgt <Leave> "rollover-message {}"
}

proc rollover-message {message} {
    # Sets a variable to hold rollover message
    # Put a widget in your interface to display it, e.g.,
    # label .lexicon.msg -relief sunken -textvariable ROLLOVER_MSG
    global ROLLOVER_MSG
    set ROLLOVER_MSG $message
}





proc label-to-name {Label} {
   regsub -all  {\ } $Label _ Label
  return [string tolower $Label]
}



