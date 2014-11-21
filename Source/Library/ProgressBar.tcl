
proc ProgressBar {w state {bytes 0} {total {}} {filename {}}} {
# progress bar for put/get operations 
# Original by Steffen Traeger
# converted to widget by Mick O'Donnell
    global progress

    switch $state {
	init	{
	    set progress(percent) "0%"
	    set progress(total) $total
	    set progress(left) 0
	    frame $w 
	    
	    frame $w.frame -bd 4
	    pack $w.frame -side top -fill both
	    frame $w.frame.bar -bd 1 -relief sunken -bg #ffffff
	    pack $w.frame.bar -in $w.frame -side left -padx 10 -pady 5
	    frame $w.frame.bar.dummy -bd 0 -width 250 -height 0
	    pack $w.frame.bar.dummy -in $w.frame.bar -side top -fill x
	    frame $w.frame.bar.pbar -bd 0 -width 0 -height 20
	    pack $w.frame.bar.pbar -in $w.frame.bar -side left
	    label $w.frame.proz -textvariable progress(percent) -width 5 -relief flat -anchor e -bd 1
	    pack $w.frame.proz -in $w.frame -side right -padx 10 -pady 5
	}
	
	update {
	    set cur_width 250
	    catch {
                set progress(percent) "[expr round($bytes) * 100 / $progress(total)]%"
		set cur_width [expr round($bytes * 250 / $progress(total))]} msg
		$w.frame.bar.pbar configure -width $cur_width -bg #000080
		update idletasks
	    }
	    
	done 	{
	    unset progress
	}
    }
}


# Procs for a toplevel progress bar

proc initProgress {label limit} {

    if [winfo exists .progress] {destroy .progress}
    toplevel .progress
    label .progress.label -text $label
    ProgressBar .progress.bar init 0 $limit
    pack .progress.label .progress.bar -side left
    return .progress.bar
}

proc updateProgress {level} {
    ProgressBar .progress.bar update $level
    update
}

proc closeProgress {} {
    ProgressBar .progress.bar done
    destroy .progress
}
