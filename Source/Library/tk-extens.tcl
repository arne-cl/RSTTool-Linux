## TK-EXTENSIONS.TCL

# Extensions to Tcl/Tk Graphical widgit language

proc tell-user {message {parent {}}} {
   set oldgrab [grab current]
   if { $oldgrab != {}} {grab release $oldgrab}
   if {$parent != {}} {
	 tk_messageBox -message $message -type ok -icon warning -parent $parent
   } else { 
	tk_messageBox -message $message -type ok -icon warning
   }
   if { $oldgrab != {}} {grab -global $oldgrab}
}

proc ask-user {prompt  {parent {}}} {
   set oldgrab [grab current]
   grab release $oldgrab
    if {$parent != {}} {
	return [tk_messageBox -message $prompt -type yesno  -parent $parent]
    } else {
	return [tk_messageBox -message $prompt -type yesno]
    }
}


proc ask-user-for-string {prompt} {
    global ASKQUERY
    #  position this near top of screen
    set f [modal-dialog .asker]
    wm geometry $f +20+20
    frame $f.top 
    label $f.top.label -text $prompt
    entry $f.top.entry -bg white -relief sunken -textvariable ASKQUERY\
	    -width 60 -borderwidth 1
    pack $f.top.label  $f.top.entry -side left -padx 5

    frame $f.bot 
    button $f.bot.done -text "Done" -command {global ASKQUERY; return-from-modal .asker "$ASKQUERY"}
    button $f.bot.cancel -text "Cancel" -command  "return-from-modal .asker 0"
    pack $f.bot.done  $f.bot.cancel -side left -padx 15
    bind $f <Return>  {global ASKQUERY;return-from-modal .asker "$ASKQUERY"}
    bind $f <Control-c> "return-from-modal .asker 0"
   
    pack $f.top $f.bot -side top

    post-modal $f
}



proc ensure-visible {win xpos ypos} {
    # places window near to point, but all on screen
    update
    set changed 0
    set windims [split [wm geometry $win] {+x}]
    set width [lindex $windims 0]
    set height [lindex $windims 1]
    set maxdims [wm maxsize .]
    set maxwidth [lindex $maxdims 0]
    set maxheight [lindex $maxdims 1]

    if {$xpos < 0} {
	set xpos  0
	set changed 1
    } 

     if {$ypos < 0} {
	set ypos  0
	set changed 1
    } 

    if  { [expr $height + $ypos] > $maxheight} {
	set ypos [expr $maxheight - $height]
	set changed 1
    }

    if { [expr $width + $xpos] > $maxwidth} {
	set xpos [expr $maxwidth - $width]
	set changed 1
    }

    if  { [expr $height + $ypos] > $maxheight} {
	set ypos [expr $maxheight - $height]
	set changed 1
    }


    if { $changed == 1} {
	wm geometry $win "+$xpos+$ypos"
    }
}


proc fullsize {win} {
    global PLATFORM tk_version
    
    if {  $PLATFORM == "windows" && $tk_version >= "8.3"} {
	wm state $win zoomed
	return
    }

  # set top corner
  set xincr 1
  set yincr 1
  switch -- $PLATFORM {
   macintosh {set xincr 1; set yincr 20}
   unix {set xincr 0; set yincr 20}
  }
  wm geometry $win "+$xincr+$yincr"

  # set size
  set maxsize [wm maxsize $win]
  set width [lindex $maxsize 0]
  set height [lindex $maxsize 1]
  if {$height > 800} {set height 800}
  if {$width > 1000} {set width 1000}
  puts "Setting winsize to: [expr $width -$xincr -$xincr]x[expr $height  - $yincr]"
  wm geometry $win "[expr $width -$xincr -$xincr]x[expr $height  - $yincr]"
  update
  puts "Winsize is:  [wm geometry $win]"
}




global tcl_platform
switch -- $tcl_platform(platform) {
    "windows" {
	proc show-webpage {url} {
	    eval exec [auto_execok start] [list $url] &
	}
    }

    "unix" {
	proc show-webpage {url} {
	    exec netscape [list $url] &
	}
    }

    "macintosh" {
proc show-webpage {url} {
 global env
	if  ![info exists env(BROWSER)] {
	    set env(BROWSER) "Browse the Internet"
	}
	if {[catch {
	    AppleScript execute\
                    "tell application \"$env(BROWSER)\"
	             open url \"$url\"
	             end tell
	            "} emsg] 
	} then {
	    error "Error displaying $url in browser\n$emsg"
	}
    }
}
}

