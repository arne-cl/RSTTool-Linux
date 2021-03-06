
proc load-module {Path Files} {
    global LOADCOUNT
    set ext ".tcl"
    if ![info exists LOADCOUNT] {
	set LOADCOUNT 0
    }

    foreach file $Files {
	puts "Loading $file$ext"
	source [file join $Path $file$ext]
	if [winfo exists .progress] {
	    ProgressBar .progress.bar update [incr LOADCOUNT]
	}
    }
}

proc open-load {files} {
    global TOOL_VERSION OPENING_GRAPHIC PICT_DIR
    set opener [image create photo -file [file join $PICT_DIR $OPENING_GRAPHIC]]
    set windim [wm maxsize .]
    canvas .c -height [image height $opener] -width [image width $opener]
    .c create image 0 0 -anchor nw -image $opener
   
    # Show the Progress bar
    frame .progress
    label .progress.label -text "Loading Files: "
    ProgressBar .progress.bar init 0 $files
    
    pack .progress.label .progress.bar -side left
    
    text .credits -bg white -height 3
    .credits insert 1.0 "Version $TOOL_VERSION\nProgrammed: by: Mick O'Donnell\nEmail: micko@wagsoft.com    Web: http://www.wagsoft.com/"
    pack .c .credits .progress


    # resize the window
    set xpos [expr ([lindex $windim 0] - [image width $opener]) / 2]
    set ypos [expr ([lindex $windim 1] - [image height $opener] -100) / 2]
     wm geometry . "+$xpos+$ypos"
    update
}



proc close-load {} {
    ProgressBar .progress.bar done
    pack forget  .progress
    destroy .progress
}
