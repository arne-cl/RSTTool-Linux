######################################
## Coder 4.x, RSTTool 3.x, Parser 3.x
#
#  File: Print.tcl
#  Author: Mick O'Donnell micko@wagsoft,com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the Coder License Terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/Coder/copyright.html
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.

global DIR tcl_version DLL_DIR
set DLL_DIR [file join $DIR DLLs]

switch -- $tcl_version {
    "8.1" {
	set gdidir [file join $DLL_DIR GDI811]
	package ifneeded printer 0.9.6.7 "
	    load [file join $gdidir printer.dll]
	    source [file join $gdidir prntcanv.tcl]
	"
    }

    "8.2" {
	set gdidir [file join $DLL_DIR GDI823]
	package ifneeded printer 0.9.6.7 "
	  load [file join $gdidir printer.dll]
	  source [file join $gdidir prntcanv.tcl]
	"
    }
    
    "8.3" -
    "8.4" -
    "8.5" -
    "8.6" {
	set gdidir [file join $DLL_DIR GDI834]
	package ifneeded printer 0.9.6.8 "
	    load [file join $gdidir printer.dll]
	    source [file join $gdidir prntcanv.tcl]
	"
    }
}

package ifneeded gdi 0.9.9.9 [list load [file join $gdidir gdi.dll]]
package ifneeded wmf 0.4.0.2 [list load [file join $gdidir wmf.dll]]
package ifneeded hdc 0.2.0.1 [list tclPkgSetup $gdidir hdc 0.2.0.1 {{hdc.dll load hdc}}]

proc TkPrintInit { dir } {
    load [file join $dir tkprt11.dll] tkprint
    source [file join $dir window.tcl]
}

package ifneeded Tkprint 1.1 "TkPrintInit [file join $DLL_DIR Tkprint1.1]"


##########################
# Functionalities

# 1. myPrintCanvas: send whole canves to printer (Windows or Unix/Linux only)
# 2. myPrintWgts: send a set of canvas widgets to the printer
# 3. mySaveCanvas: save a canvas as either ps, pdx, wmf or emf
#    (only ps and pdx for Unix/Linux/Mac)
# 4. mySaveWgts: save a set of canvas widgets to a file
# 5. myCaptureCanvas: store the canvas in the clipboard for pasting (windows only)
# 6. myCaptureWgts: store the selected widgets into clipboard for pasting (windows only)

# Some functions work on Unix/Linux/Mac, but limited


proc ensure-gdi {} {
    package require wmf
    package require gdi
}


#########################
# FILE SAVING
#########################


proc mySaveCanvas {cnv {file {}}} {

    # if no file, ask
    if { $file == {}} {
	set file [tk_getSaveFile -title "Save to file?"\
		-filetypes  {{"Windows MetaFile" "*.wmf"} {"Windows Enhanced Metafile" "*.emf"}\
		{PostScript {.eps .ps}} {PDX .pdx} } -initialfile "untitled.wmf"]
    }

    if {$file == {}} {return}

    # find the filetype
    switch -- [string tolower [file extension $file]] {
	".ps" -
	".eps" {
	    if [file exists $file] {file delete $file}
	    $cnv postscript -file $file -pagex 0.i -pagey 11.i -pageanchor nw
	    tell-user "Postscript file saved"
	}
	
	".emf" -
	".wmf" -
	".pdx" {
	    set wgts [$cnv find all]
	    mySaveWgts $cnv $wgts $file 
	}

	default {
	    tell-user "Sorry, cannot save canvas in format [file extension $file] yet."
	}
    }
}


proc mySaveWgts {cnv wgts file} {

    # find the filetype
    switch -- [string tolower [file extension $file]] {
	".emf" -
	".wmf" {
	    if [file exists $file] {file delete $file}
	    mySaveWgts.gdi $cnv $wgts $file 
	}

	".ps" -
	".eps" {
	    # Copy the widgets to a new canvas, and then save the canvas
	    if [file exists $file] {file delete $file}
	    set cnv1 [copy-canvas $cnv $wgts]
	    $cnv1 postscript -file $file -pagex 0.i -pagey 11.i -pageanchor nw
	    destroy .tmp
	}

	".pdx" {
	    wgts-to-pdx $cnv $wgts $file
	}

	default {
	    tell-user "Sorry, cannot save canvas in format [file extension $file] yet."
	}
    }
}

proc mySaveWgts.gdi {cnv wgts file} {
    # ensure extensions are loaded
    ensure-gdi

    # Create a pointer to the wmfdc
    set wmfdc [copy-wgts-to-wmfdc $cnv $wgts]

    # Copy to the clipboard
    wmf copy $wmfdc -file [file nativename $file]

    # Delete the data
    wmf delete $wmfdc
}


#########################
# CAPTURE TO CLIPBOARD
#########################

proc myCaptureCanvas {cnv} {
    
    set wgts [$cnv find all]
    myCaptureWgts $cnv $wgts
}

proc myCaptureWgts {cnv wgts} {
        
    # ensure extensions are loaded
    ensure-gdi

    # Create a pointer to the wmfdc
    set wmfdc [copy-wgts-to-wmfdc $cnv $wgts]

    # Copy to the clipboard
    wmf copy $wmfdc

    # Delete the data
    wmf delete $wmfdc
}



proc copy-wgts-to-wmfdc {cnv wgts} {
    # Create the wmf handle
    set hDCname [wmf open]
    # set hDC [hdc addr $hDCname]
    
    # Draw the widgets to the wmf
    gdi-copy-widgets $hDCname $cnv $wgts
    
    # close the 
    return [wmf close $hDCname]
}

proc gdi-copy-widgets {hDCname cnv wgts} {

    # 1. Capture the bbox of these widgets to find the xy offset
    set bbox [eval [concat "$cnv bbox" $wgts]]
    set xoffset [lindex $bbox 0]
    set yoffset [lindex $bbox 1]

    foreach wgt $wgts {
	set coords1 [$cnv coords $wgt]
	# Correct the coords for offset
	set coords {}
	while { $coords1 != {}} {
	    set x [expr [pop coords1] - $xoffset]
	    set y [expr [pop coords1] - $yoffset]
	    lappend coords $x
	    lappend coords $y
	}

	set color [$cnv itemcget $wgt -fill]
	
	switch --  [$cnv type $wgt] {
	    text {
		set x [lindex $coords 0]
		set y [lindex $coords 1]

		set attribs {}
		foreach attrib [$cnv itemconfigure $wgt] {
		    set val [lindex $attrib 3]
		    if { $val != {}} {
			set attribs "$attribs [lindex $attrib 0] [lindex $attrib 4]"
		    }
		}

		set txt [$cnv itemcget $wgt -text]
		set fontdetails [font actual [$cnv itemcget $wgt -font]]
		set family [getarg  -family $fontdetails]

		set size [getarg  -size $fontdetails]
		set slant [getarg  -slant $fontdetails]
		if { $slant != "italic"} {
		    set slant ""
		}
		set weight [getarg  -weight $fontdetails]
		set font "\{$family\} $size $slant $weight"
		set anchor [$cnv itemcget $wgt -anchor]
		set bbox [$cnv bbox $wgt]
		# Add 2 because some seems to be lost in the translation
		set wdth [expr [lindex $bbox 2] - [lindex $bbox 0] +2]
		set hgth [expr [lindex $bbox 3] - [lindex $bbox 1] ]
		# $cnv create line $x $y [expr $x + $wdth] $y -fill red
		# $cnv create line $x [expr $y + $hgth] [expr $x + $wdth] [expr $y + $hgth] -fill red
		gdi text $hDCname $x $y -text $txt -fill $color -font $font -anchor $anchor\
			-width $wdth

#		gdi line  $hDCname $x $y [expr $x + $wdth] $y -fill red
	#	gdi line  $hDCname $x [expr $y + $hgth] [expr $x + $wdth] [expr $y + $hgth] -fill red
	    }
	    
	    line {

		set attribs {}
		foreach attrib [$cnv itemconfigure $wgt] {
		    set val [lindex $attrib 3]
		    if { $val != {}} {
			set attribs "$attribs [lindex $attrib 0] [lindex $attrib 4]"
		    }
		}

		set joinstyle [$cnv itemcget $wgt -joinstyle]
		set smooth [$cnv itemcget $wgt -smooth]
		set splinesteps [$cnv itemcget $wgt -splinesteps]
		switch -- $smooth {
		    0 {set smooth false}
		    1 -
		    "bezier" {set smooth true}
		}
		
		# Smoothed lines come out terrible, better unsmoothed
		set smooth false

		eval "gdi line $hDCname $coords -fill $color -joinstyle $joinstyle\
			-smooth $smooth -splinesteps $splinesteps"
	    }
	    
	    arc { 
		tell-user "Type: [$cnv type $wgt] not catered to"
		# eval "gdi arc $hDCname $coords "-outline $outline"
	    }
	    
	    rectangle {
		set outline [$cnv itemcget $wgt -outline]

		set attribs {}
		foreach attrib [$cnv itemconfigure $wgt] {
		    set val [lindex $attrib 3]
		    if { $val != {}} {
			set attribs "$attribs [lindex $attrib 0] [lindex $attrib 4]"
		    }
		}

		eval "gdi rectangle $hDCname $coords -outline $outline"
	    }
	    
	    default {
		
		tell-user "Type: [$cnv type $wgt] not catered to"
	    }
	}
    }
}



#########################
# PRINT CANVAS
#########################

# 1. Print single page

proc myPrintCanvas {cnv} {
    global tcl_version

    switch -- $tcl_version {
	"8.1" -
	"8.2" {
	    
	    # Use the irox version if it works
	    if ![catch "myPrintCanvas.irox $cnv"] {
		return
	    }
	    
	    # Else use the Swartz version
	    catch "myPrintCanvas.schwartz $cnv"
	}

	"8.3" -
	"8.4" {
	    myPrintCanvas.schwartz $cnv
	}
    }
}

proc my-require-tkprint-irox {} {
    global tcl_version DLL_DIR
    if {[info procs "ide_print_canvas"] == {}} {
	switch -- $tcl_version {
	    "8.1" {load [file join $DLL_DIR TkPrintIrox tkprint81.dll]}
	    "8.2" {load [file join $DLL_DIR TkPrintIrox tkprint82.dll]}
	}
    }
}

proc myPrintCanvas.irox {cnv} {
    my-require-tkprint-irox
    
    ide_print_canvas $cnv
}

proc myPrintCanvas.findleton {cnv} {
    global tcl_version
    
    # direct printing doesnt work in version 8.3/4
    package require Tkprint
    switch -- $tcl_version {
	"8.3" -
	"8.4" {
	    # This fails due to faults in the dll
	    xxx
	    MetaFile $cnv -file tmp.emf
	    PrintMetaFile tmp.emf
	    file delete tmp.emf
	} 
	
	default {
	    PrintCanvas $cnv -position 0.0,0.0 -paginate 1 -colordepth 24
	}
    }
}

proc myPrintCanvas.schwartz {cnv} {
    # ensure dlls are loaded
    package require gdi
    package require printer
    printer::print_widget $cnv
}


proc myPrintWgts {cnv wgts} {
    global tcl_version
    set cnv1 [copy-canvas $cnv $wgts]

    switch -- $tcl_version {
	"8.1" - 
	"8.2" {
	    myPrintCanvas.schwartz $cnv1

	    # my-require-tkprint-irox
	    # ide_print_canvas $cnv1
	}

	"8.3" -
	"8.4" {
	    # ensure dlls are loaded
	    package require gdi
	    package require printer
	    printer::print_widget $cnv1
	}
    }
    destroy .tmp
}


#########################
# SUPPORT FUNCTIONS
#########################

proc copy-canvas {cnv wgts} {
    if [winfo exists .tmp] {destroy .tmp}
    toplevel .tmp
    canvas .tmp.canv -bg white
    pack .tmp.canv -fill both -expand t
    
    # 1. Capture the bbox of these widgets to find the xy offset
    # (We will set 0 to the top-lhs of the widgets)
    set bbox [eval [concat "$cnv bbox" $wgts]]
    set xoffset [lindex $bbox 0]
    set yoffset [lindex $bbox 1]

#BETTER - RETRIEVE ALL ARGS and substitute in new x/y
    foreach wgt $wgts {
	set coords1 [$cnv coords $wgt]
	# Correct the coords for offset
	set coords {}
	while { $coords1 != {}} {
	    set x [expr [pop coords1] - $xoffset]
	    set y [expr [pop coords1] - $yoffset]
	    lappend coords $x
	    lappend coords $y
	}

	set color [$cnv itemcget $wgt -fill]
	
	switch --  [$cnv type $wgt] {
	    text {
		
		set x [lindex $coords 0]
		set y [lindex $coords 1]
		set txt [$cnv itemcget $wgt -text]
		set attribs {}
		foreach attrib [$cnv itemconfigure $wgt] {
		    set var [lindex $attrib 0]
		    set val [lindex $attrib 3]
		    if { $val != {}} {
			switch -- $var {
			    "-font" {
				set attribs "$attribs [lindex $attrib 0] \{[lindex $attrib 4]\}"
			    }
			    default {
				set attribs "$attribs [lindex $attrib 0] [lindex $attrib 4]"
			    }
			}
		    }
		}
		eval [concat ".tmp.canv create text $x $y -text \{$txt\}" $attribs]
	    }
	    
	    line {
		set joinstyle [$cnv itemcget $wgt -joinstyle]
		set smooth [$cnv itemcget $wgt -smooth]
		if { $smooth == "bezier"} {set smooth t}
		eval [concat ".tmp.canv create line" $coords "-joinstyle $joinstyle"\
			"-smooth $smooth -fill $color"]
	    }
	    
	    arc { puts "Arc $wgt: $bbox"}
	    
	    rectangle {
		set outline [$cnv itemcget $wgt -outline]
		set attribs {}
		foreach attrib [$cnv itemconfigure $wgt] {
		    set val [lindex $attrib 3]
		    if { $val != {}} {
			set attribs "$attribs [lindex $attrib 0] [lindex $attrib 4]"
		    }
		}
		puts "RECT attribs: $attribs"
		eval [concat ".tmp.canv create rectangle" $coords $attribs]
	    }
	    
	    default {
		
		puts "Type: [$cnv type $wgt] not catered to"
	    }
	}
    }
    return .tmp.canv
}


proc addToCanvasMenu {menubar menu cnv} {
    MenuSeparator $menubar $menu
    MenuItem $menubar $menu "Print Diagram" "myPrintCanvas $cnv" 
    MenuItem $menubar $menu "Save Diagram As..." "save-canvas-as $cnv"  
    MenuItem $menubar $menu "Capture to Clipboard" "myCaptureCanvas $cnv"
}



proc myPrintMetafile {{file {}}} {
    if { $file == {}} {
	set file [tk_getOpenFile -title "Select Metafile to print"\
		-filetypes {{Metafile {*.emf *.wmf}}}]
	if  { $file == {}} {return}
    }
    package require Tkprint
    PrintMetaFile $file
}


proc print-ps {file} {
    global DLL_DIR
    
    exec $DLL_DIR/Pfile/prfile32.exe /q [file nativename $file] &
}
