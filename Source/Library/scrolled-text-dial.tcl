proc scrolled-text-dialog {name title text args} {
    global std-exit
# Returns a scrollable text widget
# $name.text is the actual text widger
# $name.title is the title
#
# Args: (all optional)
# -height <integer>
# -font <font-spec>
# -titlevar varname : variable containing the name of the frame title

    toplevel $name -class Dialog
    wm title $name $title 
    frame $name.textwindow
    text  $name.text  -bg white -relief sunken -wrap word\
	    -yscrollcommand "$name.scroll set"
	
    scrollbar $name.scroll -command "$name.text yview"

    set font [getarg -font $args]
    if { $font != {} } {
	$name.text configure -font $font
    }

    set height [getarg -height $args]
    if { $height != {} } {
	$name.text configure -height $height
    }

    $name.text insert end $text
    pack $name.textwindow -side top -expand 1 -fill both
    pack $name.text -in $name.textwindow -fill both -expand 1 -side left
    pack $name.scroll -in $name.textwindow -side right -fill y 

    button $name.button -text "OK" -command "set std-exit 1"
    pack $name.button -side bottom

    # 4. Set up a binding for <Return>
    # set a grab, and claim the focus too.
    bind $name <Return> "$name.button flash; set std-exit 1"
    
    set oldFocus [focus]
    tkwait visibility $name
    grab set $name
    wm transient $name .
    focus $name
    
    # 5. Wait for the user to respond, then restore the focus
    # and return the index of the selected button.
    
    tkwait variable std-exit
    destroy $name
    focus $oldFocus
    return 1
}


proc scrolled-text-dialog-nonmodal {name title text args} {
    global std-exit
# Returns a scrollable text widget
# $name.text is the actual text widger
# $name.title is the title
#
# Args: (all optional)
# -height <integer>
# -font <font-spec>
# -titlevar varname : variable containing the name of the frame title

    toplevel $name -class Dialog
    wm title $name $title 
    frame $name.textwindow
    text  $name.text  -bg white -relief sunken -wrap word\
	    -yscrollcommand "$name.scroll set"
	
    scrollbar $name.scroll -command "$name.text yview"

    set font [getarg -font $args]
    if { $font != {} } {
	$name.text configure -font $font
    }

    set height [getarg -height $args]
    if { $height != {} } {
	$name.text configure -height $height
    }

    $name.text insert end $text
    pack $name.textwindow -side top -expand 1 -fill both
    pack $name.text -in $name.textwindow -fill both -expand 1 -side left
    pack $name.scroll -in $name.textwindow -side right -fill y 

    button $name.button -text "OK" -command "destroy $name"
    pack $name.button -side bottom

    # 4. Set up a binding for <Return>
    # set a grab, and claim the focus too.
    bind $name <Return> "destroy $name"
}

