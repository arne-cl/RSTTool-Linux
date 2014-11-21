# General Code for defining Interfaces for Coder, RSTTool, Parser and Grapher
# Mick O'Donnell



proc def-interface {name title rollovermsg frame  {openproc {}} {closeproc {}}} {
    global INTERFACE BUTTON_FONT COLOR
    set INTERFACE($name,frame) $frame
    set INTERFACE($name,title) $title
    set INTERFACE($name,button)\
	    [ToolbarItem .top.toolbar $title $rollovermsg "install-interface $name" 2]
    
    .top.toolbar config -bg $COLOR(background)
    $INTERFACE($name,button) config -font $BUTTON_FONT
    set INTERFACE($name,openproc) $openproc
    set INTERFACE($name,closeproc) $closeproc
}

proc install-interface {interface} {
    global CURRENT_INTERFACE INTERFACE

    if {$CURRENT_INTERFACE == $interface} {return}
    if { $CURRENT_INTERFACE != {} } {
	uninstall-interface $CURRENT_INTERFACE
    } 

    set CURRENT_INTERFACE $interface
    toggle-button $interface "flat"
    
    if [info exists INTERFACE($interface,frame)] {
	pack  $INTERFACE($interface,frame) -side top -expand t -fill both
	if { $INTERFACE($interface,openproc) != {}} {$INTERFACE($interface,openproc) }
    } else {
	tell-user "install-interface: No interface for $interface"
    }
}


proc uninstall-interface {{interface {}}} {
    global INTERFACE CURRENT_INTERFACE

    if { $interface == {} } {set interface $CURRENT_INTERFACE}
    if { $interface == {} } {return}
    set CURRENT_INTERFACE {}
    toggle-button $interface "raised"
    if [info exists INTERFACE($interface,frame)] {
	if {$INTERFACE($interface,closeproc) != {} } { $INTERFACE($interface,closeproc)}
	pack forget $INTERFACE($interface,frame)
    } else {
	tell-user "uninstall-interface: No interface for $interface"
    }
}

proc toggle-button {interface dir} {
    global INTERFACE BUTTON_FONT BUTTON_FONT_BOLD COLOR 
    if [info exists INTERFACE($interface,button)] {
	$INTERFACE($interface,button) configure -relief $dir
	if { $dir == "flat" } {
	    $INTERFACE($interface,button) configure -font $BUTTON_FONT_BOLD\
		    -bg $COLOR(background)
	} else {
	    $INTERFACE($interface,button) configure -font $BUTTON_FONT -bg $COLOR(buttons)
	}
    } else {
	tell-user "toggle-button: No interface for $interface"
    }
}

proc reset-interface {} {
    global CURRENT_INTERFACE COLOR PLATFORM

    # Resets the interface back to start, and binds some events
    set CURRENT_INTERFACE {}
    wm protocol . WM_DELETE_WINDOW Quit
    fullsize .

    # Install the menuBar
    make-menubar
    . configure -menu .menuBar

    pack forget all
    if { $PLATFORM != "macintosh"} {
	bind all <Control-z> {wm iconify .}
    }
    bind . <MouseWheel> {
	scroll-current-interface %D %s
    }

    # Reset the modebar
    if [winfo exists .top] {destroy .top}
    frame .top 
    Toolbar .top.toolbar horizontal
    .top.toolbar config -bg $COLOR(buttons)
    pack .top.toolbar  -side left -padx 5 -anchor w -fill y

    # Install the rollover and file display
    FileBar .top.filebar 
    pack .top.filebar -side left -expand 1 -fill x -padx 0.1c
    pack .top -fill x -expand 0 
}





proc start-watch-cursor {} {
    global OLDFOCUS  OLDCURSOR1 OLDCURSOR2
    set OLDFOCUS [focus]
    set OLDCURSOR1 [lindex [. config -cursor] 4]
    focus .
    . config -cursor watch
    update
}

proc stop-watch-cursor {} {
    global OLDFOCUS  OLDCURSOR1 OLDCURSOR2
    catch "focus $OLDFOCUS"
    . config -cursor $OLDCURSOR1
}


# The FileBar is a widget used by most interfaces
# it has 2 parts, one showing the current file (depending on context)
# The other showing any rollover messages

proc FileBar {path}  {
    # The file bar (packed last so it gets minimal space)
    frame $path -bg red
    label $path.msg  -relief raised -textvariable ROLLOVER_MSG 
    pack $path.msg -side bottom -fill x -expand t
    add-rollover-message $path.msg\
	    "This space displays describes what is under the mouse"

    return $path

}

proc FileBarAdd {path filevar filelabel} {
    if [winfo exists $path] {destroy $path}
    frame $path
    label $path.label -text "$filelabel:"
    label $path.display -relief sunken -textvariable $filevar -bg "white"
    pack $path.label -side left
    pack $path.display -side left -expand t -fill x
    pack $path -side top -fill x -expand t 
    add-rollover-message $path.display\
		"This space displays the filepath of the current $filelabel (if any)"
    return $path
}


proc Quit {} {
    global CHANGED

    # Save the preferences
    if [catch "save-preferences"] {
	tell-user "Problem saving preferences. Not saved"
    }
    
    # if the resources are not loaded yet
    if { [prompt-save-current-files] != "cancelled" } {
	exit
    }

    
}
