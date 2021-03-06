global BG_COLOR1 BG_COLOR2
if ![info exists BG_COLOR1] {set BG_COLOR1 "#FCD98E"}
if ![info exists BG_COLOR2] {set BG_COLOR2 "#F6C19E"}


proc ChooseButton {path choicevar listvar} {
    global BG_COLOR2
    # Returns a button, which when clicked on, offers a list
    # the choice from the list is displayed, and available from the global var: var

    button $path -textvariable $choicevar -bg $BG_COLOR2\
	    -command "choosebutton-action $path $choicevar $listvar"
    return $path
}

proc choosebutton-action {path choicevar listvar} {
    global $choicevar $listvar
    set xpos [winfo pointerx $path]
    set ypos [winfo pointery $path]
    
    set result [popup-choose-from-list [set $listvar] $xpos $ypos]
    if {$result != "cancelled"} {
	set $choicevar $result
    }
}


proc popup-choose-from-list {Items xpos ypos {prompt "Choose One"}} {
    global PCFL_SEL
    set PCFL_SEL {}
    make-popup-choose $Items $prompt $xpos $ypos

    # Wait for some bound event to occur
    tkwait variable PCFL_SEL

    # The selection is in PCFL_SEL - destroy the window and return
    grab release .popupmenu 
    destroy .popupmenu

    return $PCFL_SEL
}


proc make-popup-choose {Items prompt xpos ypos} {
    
    if [winfo exists .popupmenu] {destroy .popupmenu}

    # Define the toplevel window
    toplevel .popupmenu -bg white -width 240 
    wm title .popupmenu $prompt

    # Define the scrolled list (scrolled-listbox defined below)
    set height [min 20 [llength $Items]]
    scrolled-listbox .popupmenu.listbox -width 24 -height $height -bg white -selectmode single

    # Put in the choices
    foreach rel $Items {
	.popupmenu.listbox.choices insert end "$rel"
    }
    
    # Define the buttons
    frame .popupmenu.buttons
    button .popupmenu.buttons.select -text "Select" -default active \
	    -command {select-current-option}
    button .popupmenu.buttons.cancel -text "Cancel" -command {popup-cancel-popup}

    # Pack the screen
    pack .popupmenu.buttons.select .popupmenu.buttons.cancel -side left -anchor n
    pack .popupmenu.listbox .popupmenu.buttons -side top

    # Select the first item
    .popupmenu.listbox.choices see 0
    .popupmenu.listbox.choices selection set 0

    # We want the window hidden while it is moved.
    wm withdraw .popupmenu
    update

    # Ensure all window is on screen
    set windims [split [wm geometry .popupmenu] {+x}]
    set width [lindex $windims 0]
    set height [lindex $windims 1]

    # Find the screen dimensions
    set maxdims [wm maxsize .]
    set maxwidth [lindex $maxdims 0]
    set maxheight [expr [lindex $maxdims 1] - 40]

    if { [expr $width + $xpos] > $maxwidth} {
	set xpos [expr $maxwidth - $width]
    }

    if  { [expr $height + $ypos] > $maxheight} {
	set ypos [expr $maxheight - $height]
    }

    # Now position the window and show it.
    wm geometry .popupmenu "+$xpos+$ypos"
    wm deiconify .popupmenu

    # Grab without global allows the window to be moved
    grab .popupmenu
    focus .popupmenu

    # wm transient means that the popup is always over the main, even if
    # user clicks on a background window and returns by clicking on the main icon
    wm transient .popupmenu .

    # Bring the window to the front (if it is not)
    raise .popupmenu

    # Bind keys and mouseclicks
    bind .popupmenu  <Return> {select-current-option}
    bind .popupmenu  <Up> {up-selection}
    bind .popupmenu  <Down> {down-selection}
    bind .popupmenu.listbox.choices <ButtonRelease> {popup-return-choice %x %y}
    bind .popupmenu <MouseWheel> {popup-mousewheel-scroll %D}
}

proc popup-mousewheel-scroll {dir} {
    if { $dir > 0 } {
	up-selection
    } else {
	down-selection
    }
}

proc up-selection {} {
    set curr [.popupmenu.listbox.choices index active]
    if { $curr == 0 } {bell; return}
    .popupmenu.listbox.choices selection clear active
    .popupmenu.listbox.choices see [incr curr -1]
    .popupmenu.listbox.choices selection set $curr
    .popupmenu.listbox.choices activate $curr
}

proc down-selection {} {
    set curr [.popupmenu.listbox.choices index active]
    set max  [expr [.popupmenu.listbox.choices index end] -1]
    if { $curr == $max } {bell; return}
    incr curr
    .popupmenu.listbox.choices selection clear active
    .popupmenu.listbox.choices see $curr
    .popupmenu.listbox.choices selection set $curr
    .popupmenu.listbox.choices activate $curr
}

proc select-current-option {} {
     global PCFL_SEL
    set PCFL_SEL  [.popupmenu.listbox.choices get active]
}



proc popup-return-choice {x y} {
  global PCFL_SEL
  set PCFL_SEL [.popupmenu.listbox.choices get @$x,$y]
}

proc popup-cancel-popup {} {
  global PCFL_SEL
  set PCFL_SEL "cancelled"
}

