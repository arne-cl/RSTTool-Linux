# tkfbox.tcl --
#
#	Implements the "TK" standard file selection dialog box. This
#	dialog box is used on the Unix platforms whenever the tk_strictMotif
#	flag is not set.
#
#	The "TK" standard file selection dialog box is similar to the
#	file selection dialog box on Win95(TM). The user can navigate
#	the directories by clicking on the folder icons or by
#	selecting the "Directory" option menu. The user can select
#	files by clicking on the file icons or by entering a filename
#	in the "Filename:" entry.
#
# SCCS: @(#) tkfbox.tcl 1.4 96/08/28 22:17:21
#
# Copyright (c) 1994-1996 Sun Microsystems, Inc.
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

# data()
# itemList

###############################################3
# The 2 toplevel functions

proc tk_getOpenFile {args} {
    return [mtkFDialog open $args]
}
  
proc tk_getSaveFile {args} {
    return [mtkFDialog save $args]
}


###############################################3
# mtkFDialog --
#
#	Implements the TK file selection dialog. This dialog is used when
#	the tk_strictMotif flag is set to false. This procedure shouldn't
#	be called directly. Call tk_getOpenFile or tk_getSaveFile instead.
#

proc mtkFDialog {type argList} {
    global tkPriv data
    
    if [info exists data] {unset data}

    create-file-dialog

    mtkFDialog_Config $type $argList

    mtkFDialog_SetPath $data(selectPath)

    # 6. Withdraw the window, then update all the geometry information
    # so we know how big it wants to be, then center the window in the
    # display and de-iconify it.

    wm withdraw .tkfd
    update idletasks
    set x [expr [winfo screenwidth .tkfd]/2 - [winfo reqwidth .tkfd]/2 \
	    - [winfo vrootx [winfo parent .tkfd]]]
    set y [expr [winfo screenheight .tkfd]/2 - [winfo reqheight .tkfd]/2 \
	    - [winfo vrooty [winfo parent .tkfd]]]
    wm geom .tkfd [winfo reqwidth .tkfd]x[winfo reqheight .tkfd]+$x+$y
    wm deiconify .tkfd
    wm title .tkfd $data(-title)

    # 7. Set a grab and claim the focus too.
    set oldFocus [focus]
    set oldGrab [grab current .tkfd]
    if {$oldGrab != ""} {
	set grabStatus [grab status $oldGrab]
    }

    #Mick: changed to grab global
    grab  .tkfd
    wm transient .tkfd .
    focus .tkfd.f2.ent
    .tkfd.f2.ent delete 0 end
    .tkfd.f2.ent insert 0 $data(selectFile)
    .tkfd.f2.ent select from 0
    .tkfd.f2.ent select to   end
    .tkfd.f2.ent icursor end

   # Ensure the window is fronted
   raise .tkfd
    
    # 8. Wait for the user to respond, then restore the focus and
    # return the index of the selected button.  Restore the focus
    # before deleting the window, since otherwise the window manager
    # may take the focus away so we can't redirect it.  Finally,
    # restore any grab that was in effect.

    tkwait variable tkPriv(selectFilePath)
    catch {focus $oldFocus}
    grab release .tkfd
    wm withdraw .tkfd
    if {$oldGrab != ""} {
	if {$grabStatus == "global"} {
	    grab -global $oldGrab
	} else {
	    grab $oldGrab
	}
    }
    update
    return $tkPriv(selectFilePath)
}


###############################################
#  create-file-dialog

proc create-file-dialog {} {
    global LIBRARY data tkPriv

    if [winfo exists .tkfd] {destroy .tkfd}
    toplevel .tkfd  -class mtkFDialog
wm withdraw .tkfd
    wm protocol .tkfd WM_DELETE_WINDOW "mtkFDialog_CancelCmd"

    # f1: the frame with the directory option menu
    #
    set f1 [frame .tkfd.f1]
    label .tkfd.f1.lab -text "Directory:" -under 0
    tk_optionMenu .tkfd.f1.menu data(selectPath) ""
    .tkfd.f1.menu config -takefocus 1 -highlightthickness 2
    button .tkfd.f1.up -bitmap @[file join $LIBRARY updir.xbm]
 
    pack .tkfd.f1.up -side right -padx 4 -fill both
    pack .tkfd.f1.lab -side left -padx 4 -fill both
    pack .tkfd.f1.menu -expand yes -fill both -padx 4

    # .tkfd.icons: the IconList that list the files and directories.
    #
    tkIconList .tkfd.icons\
	-browsecmd "mtkFDialog_ListBrowse" \
	-command   "mtkFDialog_ListInvoke"

    # f2: the frame with the OK button and the "file name" field
    #
    frame .tkfd.f2
    label .tkfd.f2.lab -text "File name:" -anchor e -width 14 -under 6
    entry .tkfd.f2.ent -bg white

    # f3: the frame with the cancel button and the file types field
    #
    frame .tkfd.f3
    label .tkfd.f3.lab -text "Files of type:" \
	   -anchor e -width 14 -under 9
    menubutton .tkfd.f3.menu -indicatoron 1 -menu .tkfd.f3.menu.m
    menu .tkfd.f3.menu.m -tearoff 0
    .tkfd.f3.menu config -takefocus 1 -highlightthickness 2 \
	    -relief raised -bd 2 -anchor w

    # the okBtn is created after the typeMenu so that the keyboard traversal
    # is in the right order
    button .tkfd.f2.ok     -text OK     -under 0 -width 6
    button .tkfd.f3.cancel -text Cancel -under 0 -width 6

    # pack the widgets in f2 and f3
    #
    pack .tkfd.f2.ok  -side right -padx 4 -anchor e
    pack .tkfd.f2.lab -side left -padx 4
    pack .tkfd.f2.ent -expand yes -fill both -padx 2 -pady 2
    
    pack .tkfd.f3.cancel -side right -padx 4 -anchor w
    pack .tkfd.f3.lab -side left -padx 4
    pack .tkfd.f3.menu -expand yes -fill x -side right

    # Pack all the frames together. We are done with widget construction.
    #
    pack .tkfd.f1 -side top -fill x -pady 4
    pack .tkfd.f3 -side bottom -fill x
    pack .tkfd.f2 -side bottom -fill x


    pack .tkfd.icons -expand yes -fill both -padx 4 -pady 2


    # Set up the event handlers
    #
    bind .tkfd.f2.ent <Return>  "mtkFDialog_ActivateEnt"
    
    .tkfd.f1.up     config -command "mtkFDialog_UpDirCmd"
    .tkfd.f2.ok     config -command "mtkFDialog_OkCmd"
    .tkfd.f3.cancel config -command "mtkFDialog_CancelCmd"

#    trace variable data(selectPath) w "mtkFDialog_SetPath"

    bind .tkfd <Alt-d> "focus .tkfd.f1.menu"
    bind .tkfd <Alt-t> "focus .tkfd.f3.menu"
    bind .tkfd <Alt-n> "focus .tkfd.f2.ent"
    bind .tkfd <KeyPress-Escape> "tkButtonInvoke .tkfd.f3.cancel"
    bind .tkfd <Alt-o> "mtkFDialog_InvokeBtn Open"
    bind .tkfd <Alt-s> "mtkFDialog_InvokeBtn Save"

    # Build the focus group for all the entries
    #
    tkFocusGroup_Create .tkfd
    tkFocusGroup_BindIn .tkfd  .tkfd.f2.ent "mtkFDialog_EntFocusIn"
    tkFocusGroup_BindOut .tkfd .tkfd.f2.ent "mtkFDialog_EntFocusOut"

    # Create images for use in directory lists
    if ![info exists tkPriv(folderImage)] {
	set tkPriv(folderImage) \
		[image create photo -file [file join $LIBRARY folder.gif]]
	set tkPriv(fileImage)  \
		[image create photo -file [file join $LIBRARY textfile.gif]]
    }
}


###################################################################
# mtkFDialog_Config --
#
#	Configures the TK filedialog according to the argument list
#
proc mtkFDialog_Config {type argList} {
    global data

    set data(type) $type
    
    # 1: the configuration specs
    #
    set specs {
	{-defaultextension "" "" ""}
	{-filetypes "" "" ""}
	{-initialdir "" "" ""}
	{-initialfile "" "" ""}
	{-parent "" "" "."}
	{-title "" "" ""}
    }
    
    # 3: parse the arguments
    #
    tclParseConfigSpec data $specs "" $argList
    
    if  {$data(-title) == ""} {
	if { $type ==  "open"} {
	    set data(-title) "Open"
	} else {
	    set data(-title) "Save As"
	}
    }
    
    # Mick Changes: Sets the initialdir to the path of initialfile 
    #   if initialdir not set.
    # Always wipes the dir path of initialfile
    if { $data(-initialfile) != {} } {
	set filedir [file dirname $data(-initialfile)]
	if { $filedir != {} } {
	    if {$data(-initialdir) == {}} {
		set data(-initialdir) $filedir
	    }
	    set data(-initialfile) [file tail $data(-initialfile)]
	}
    }
    
    # 4: set the default directory and selection according to the -initial
    #    settings
    #
    if { $data(-initialdir) == ""} {
	set data(selectPath) [pwd]
    } else {
	if [file isfile $data(-initialdir)] { 
	    if { $data(-initialfile) == {} } {
		set data(-initialfile) [file tail $data(-initialdir)]
	    }
	    set data(-initialdir) [file dirname $data(-initialdir)]
	}
	
	if ![file isdirectory $data(-initialdir)] {
	    tkfd-tell-user "\"$data(-initialdir)\" is not a valid directory. Using default dir." .tkfd
	    set data(-initialdir) [pwd]
	} 
	set data(selectPath) [lindex [glob $data(-initialdir)] 0]
	set data(selectFile) $data(-initialfile)
    }
    # 5. Parse the -filetypes option
    #
    set data(-filetypes) [tkFDGetFileTypes $data(-filetypes)]

    if {$data(-filetypes) == {}} {
	set data(filter) "*"
	.tkfd.f3.menu config -state disabled
	.tkfd.f3.lab config -fg \
		[.tkfd.f3.menu cget -disabledforeground]
    } else {
	.tkfd.f3.menu.m delete 0 end
	foreach type $data(-filetypes) {
	    set title  [lindex $type 0]
	    set filter [lindex $type 1]
	    .tkfd.f3.menu.m add command -label $title \
		    -command [list mtkFDialog_SetFilter $type]
	}
	mtkFDialog_SetFilter [lindex $data(-filetypes) 0]
	.tkfd.f3.menu config -state normal
	.tkfd.f3.lab config -fg [.tkfd.f3.menu cget -fg]
    }
    wm transient .tkfd $data(-parent)

    if ![winfo exists $data(-parent)] {
	error "bad window path name \"$data(-parent)\""
    }
}

##############################################
#	Loads the files and directories into the IconList widget. Also
#	sets up the directory option menu for quick access to parent
#	directories.

proc mtkFDialog_SetPath {path} {
    global data tcl_platform

    set data(selectPath) $path

    set appPWD [pwd]

# Handle Mac and PC toplevel dirs
# Note: Files and folders on mac desktop need to be accessed from each volumes Desktop Folder
    if {  $tcl_platform(platform) == "windows" && $data(selectPath) == "My Computer"} {
          mtkFDialog_Update
          my-cd "$appPWD"
          return
         }

if {   $tcl_platform(platform) == "macintosh" && $data(selectPath) == "Desktop"} {
          mtkFDialog_Update
          my-cd "$appPWD"
          return
         }

   
    

    if [catch "my-cd \"$data(selectPath)\""] {
	# We cannot change directory to $data(selectPath). $data(selectPath)
	# should have been checked before mtkFDialog_Update is called, so
	# we normally won't come to here. Anyways, give an error and abort
	# action.
	tkfd-tell-user "Cannot change to the directory \"$data(selectPath)\".\nPermission denied." .tkfd
	my-cd "$appPWD"
	return
    }


    # Update the Directory: option menu
    #
    set list ""

    # Mick: allow PCs to select other drives
    global tcl_platform
    switch -- $tcl_platform(platform) {
      "windows" {set list [list "My Computer"]}
      "macintosh" {set list [list "Desktop"]}
    }

    set dir ""
    foreach subdir [file split $data(selectPath)] {
	set dir [file join $dir $subdir]
	lappend list $dir
    }

    .tkfd.f1.menu.menu delete 0 end
    foreach path $list {
	.tkfd.f1.menu.menu add command -label $path -command "mtkFDialog_SetPath \"$path\""
    }

    # Restore the PWD to the application's PWD
    #
    my-cd "$appPWD"


    # Change the displayed directory
    mtkFDialog_Update
}


proc mtkFDialog_Update {} {
    global data tkPriv tcl_platform

    # If this is the Mac Desktop or PC "My Computer", just show the lists
if {  $tcl_platform(platform) == "windows" && $data(selectPath) == "My Computer"}  {
     tkf_show-toplevel
          return
         }

if {   $tcl_platform(platform) == "macintosh" && $data(selectPath) == "Desktop"} {
          tkf_show-toplevel
          return
         }



    # if the flter isnt set yet, delay the update
    if {$data(-filetypes) != {}} {
	if ![info exists data(filter)] {return}
    }
    
    set folder $tkPriv(folderImage)
    set file   $tkPriv(fileImage)

     # Turn on the busy cursor. BUG?? We haven't disabled X events, though,
    # so the user may still click and cause havoc ...
    #
    set entCursor [.tkfd.f2.ent cget -cursor]
    set dlgCursor [.tkfd         cget -cursor]
    .tkfd.f2.ent config -cursor watch
    .tkfd         config -cursor watch
    update idletasks
    
    tkIconList_DeleteAll
    my-cd "$data(selectPath)"
    set globlist [lsort -dictionary [glob -nocomplain .* *]]
    delete globlist "."
    delete globlist ".."

    # Make the dir list
    #
    foreach f  $globlist {

	if {[string range $f 0 0] == "~"} {
	    # the file (not path) starts with a tilde
	    # probably a dos temp file
	    # so ignore
	    continue
	}
	if [file isdir $f] {
	    if ![info exists hasDoneDir($f)] {
		tkIconList_Add $folder $f
		set hasDoneDir($f) 1
	    }
	}
    }
    # Make the file list
    #
    if { $data(filter)!= "*"} {
	set files [eval glob -nocomplain $data(filter)]
	set files [concat $files [eval glob -nocomplain [string toupper $data(filter)]]]
	set globlist [lsort -dictionary $files]
    }

    set top 0
    foreach f $globlist {
	if {[string range $f 0 0] == "~"} {
	    # the file (not path) starts with a tilde
	    # probably a dos temp file, so ignore
	    continue
	}
	if ![file isdir $f] {
	    if ![info exists hasDoneFile($f)] {
		tkIconList_Add $file $f
		set hasDoneFile($f) 1
	    }
	}
    }

    tkIconList_Arrange

    # turn off the busy cursor.
    #
    .tkfd.f2.ent config -cursor $entCursor
    .tkfd config -cursor $dlgCursor
}





# This proc gets called whenever data(filter) is set
#
proc mtkFDialog_SetFilter {type} {
    global data

    set data(filter) [lindex $type 1]
    .tkfd.f3.menu config -text [lindex $type 0] -indicatoron 1

    .tkfd.icons.sbar set 0.0 0.0

    # mick
    set oldfile [eval ".tkfd.f2.ent get"]

    if { $oldfile == {}} {set oldfile $data(selectFile)}
    set data(selectFile) [file rootname $oldfile][file extension [lindex $type 1]]
    .tkfd.f2.ent delete 0 end
    .tkfd.f2.ent insert 0 $data(selectFile)
    .tkfd.f2.ent select from 0
    .tkfd.f2.ent select to   end
    .tkfd.f2.ent icursor end

    mtkFDialog_Update
}

# mtkFDialogResolveFile --
#
#	Interpret the user's text input in a file selection dialog.
#	Performs:
#
#	(1) ~ substitution
#	(2) resolve all instances of . and ..
#	(3) check for non-existent files/directories
#	(4) check for chdir permissions
#
# Arguments:
#	context:  the current directory you are in
#	text:	  the text entered by the user
#
# Return vaue:
#	[list $flag $directory $file]
#
#	 flag = OK	: valid input
#	      = PATTERN	: valid directory/pattern
#	      = PATH	: the directory does not exist
#	      = FILE	: the directory exists by the file doesn't
#			  exist
#	      = CHDIR	: Cannot change to the directory
#	      = ERROR	: Invalid entry
#
#	 directory      : valid only if flag = OK or PATTERN or FILE
#	 file           : valid only if flag = OK or PATTERN
#
#	directory may not be the same as context, because text may contain
#	a subdirectory name
#
proc mtkFDialogResolveFile {context text} {

    set appPWD [pwd]
    set path [file join $context $text]

    if [catch {file exists $path}] {
	return [list ERROR $path ""]
    }

    if [file exists $path] {
	if [file isdirectory $path] {
	    if [catch {my-cd "$path"}] {
		return [list CHDIR $path ""]
	    }
	    set directory [pwd]
	    set file ""
	    set flag OK
	    my-cd "$appPWD"
	} else {
	    if [catch {my-cd "[file dirname $path]"}] {
		return [list CHDIR [file dirname $path] ""]
	    }
	    set directory [pwd]
	    set file [file tail $path]
	    set flag OK
	    my-cd "$appPWD"
	}
    } else {
	set dirname [file dirname $path]
	if [file exists $dirname] {
	    if [catch {my-cd "$dirname"}] {
		return [list CHDIR $dirname ""]
	    }
	    set directory [pwd]
	    set file [file tail $path]
	    if [regexp {[*]|[?]} $file] {
		set flag PATTERN
	    } else {
		set flag FILE
	    }
	    my-cd "$appPWD"
	} else {
	    set directory $dirname
	    set file [file tail $path]
	    set flag PATH
	}
    }

    return [list $flag $directory $file]
}


# Gets called when the entry box gets keyboard focus. We clear the selection
# from the icon list . This way the user can be certain that the input in the 
# entry box is the selection.
#
proc mtkFDialog_EntFocusIn {} {
    global data

    if { [.tkfd.f2.ent get] != ""} {
	.tkfd.f2.ent selection from 0
	.tkfd.f2.ent selection to   end
	.tkfd.f2.ent icursor end
    } else {
	.tkfd.f2.ent selection clear
    }

    tkIconList_Unselect

    if {$data(type) == "open"} {
	.tkfd.f2.ok config -text "Open"
    } else {
	.tkfd.f2.ok config -text "Save"
    }
}

proc mtkFDialog_EntFocusOut {} {
    .tkfd.f2.ent selection clear
}


# Gets called when user presses Return in the "File name" entry.
#
proc mtkFDialog_ActivateEnt {} {
    global data

    set text [string trim [.tkfd.f2.ent get]]
    set list [mtkFDialogResolveFile $data(selectPath) $text]
    set flag [lindex $list 0]
    set path [lindex $list 1]
    set file [lindex $list 2]
    
    case $flag {
	OK {
	    if {$file == ""} {
		# user has entered an existing (sub)directory
		mtkFDialog_SetPath $path
		.tkfd.f2.ent delete 0 end
	    } else {
		set data(selectPath) $path
		set data(selectFile) $file
		mtkFDialog_Done
	    }
	}
	PATTERN {
	    mtkFDialog_SetPath $path
	    set data(filter) $file
	}
	FILE {
	    if {$data(type) == "open"} {
		tkfd-tell-user "File \"[file join $path $file]\" does not exist." .tkfd
		.tkfd.f2.ent select from 0
		.tkfd.f2.ent select to   end
		.tkfd.f2.ent icursor end
	    } else {
		set data(selectPath) $path
		set data(selectFile) $file
		mtkFDialog_Done 
	    }
	}
	PATH {
	    tkfd-tell-user "Directory \"$path\" does not exist." .tkfd
	    .tkfd.f2.ent select from 0
	    .tkfd.f2.ent select to   end
	    .tkfd.f2.ent icursor end
	}
	CHDIR {
	    tkfd-tell-user "Cannot change to the directory \"$path\".\nPermission denied." .tkfd
	    .tkfd.f2.ent select from 0
	    .tkfd.f2.ent select to   end
	    .tkfd.f2.ent icursor end
	}
	ERROR {
	    tkfd-tell-user "Invalid file name \"$path\"." .tkfd
	    .tkfd.f2.ent select from 0
	    .tkfd.f2.ent select to   end
	    .tkfd.f2.ent icursor end
	}
    }
}

# Gets called when user presses the Alt-s or Alt-o keys.
#
proc mtkFDialog_InvokeBtn {key} {

    if ![string compare [.tkfd.f2.ok cget -text] $key] {
	tkButtonInvoke .tkfd.f2.ok
    }
}

# Gets called when user presses the "parent directory" button
#
proc mtkFDialog_UpDirCmd {} {
    global data tcl_platform

    switch -- $tcl_platform(platform) {
	windows {
	    if { $data(selectPath) != "My Computer"} {
		set dirname [file dirname $data(selectPath)]
		if { $dirname == $data(selectPath) } {
		    mtkFDialog_SetPath "My Computer"
		} else {
		    mtkFDialog_SetPath $dirname
		}
	    }
	}

	macintosh {
               if { $data(selectPath) != "Desktop"} {
		set dirname [file dirname $data(selectPath)]
		if { $dirname == $data(selectPath) } {
		    mtkFDialog_SetPath "Desktop"
		} else {
		    mtkFDialog_SetPath $dirname
		}
	    }
	}

	unix {
	    if [string compare $data(selectPath) "/"] {
		mtkFDialog_SetPath [file dirname $data(selectPath)]
	    }
	}

	default {
	    mtkFDialog_SetPath [file dirname $data(selectPath)]
	}
    }
}

# Gets called when user presses the "OK" button
#
proc mtkFDialog_OkCmd {} {
    global data

    set text [tkIconList_Get]
    if { $text != ""} {
	set file [file join $data(selectPath) $text]
	if [file isdirectory $file] {
	    mtkFDialog_ListInvoke $text
	    return
	}
    }

    mtkFDialog_ActivateEnt
}

# Gets called when user presses the "Cancel" button
#
proc mtkFDialog_CancelCmd {} {
    global tkPriv

    set tkPriv(selectFilePath) ""
}

# Gets called when user browses the IconList widget (dragging mouse, arrow
# keys, etc)
#
proc mtkFDialog_ListBrowse {text} {
    global data

    if {$text == ""} {
	return
    }

    set file [file join $data(selectPath) $text]
    if ![file isdirectory $file] {
	.tkfd.f2.ent delete 0 end
	.tkfd.f2.ent insert 0 $text

	if ![string compare $data(type) open] {
	    .tkfd.f2.ok config -text "Open"
	} else {
	    .tkfd.f2.ok config -text "Save"
	}
    } else {
	.tkfd.f2.ok config -text "Open"
    }
}

# Gets called when user invokes the IconList widget (double-click, 
# Return key, etc)
#
proc mtkFDialog_ListInvoke {text} {
    global data

    if {$text == ""} {
	return
    }
    set file [file join $data(selectPath) $text]
    if [file isdirectory $file] {
	set appPWD [pwd]
	if [catch {my-cd "$file"}] {
	    tkfd-tell-user "Cannot change to the directory \"$file\".\nPermission denied." .tkfd
	} else {
	    my-cd "$appPWD"
	    mtkFDialog_SetPath $file
	}
    } else {
	set data(selectFile) $file
	mtkFDialog_Done 
    }
}


# mtkFDialog_Done --
#
#	Gets called when user has input a valid filename.  Pops up a
#	dialog box to confirm selection when necessary. Sets the
#	tkPriv(selectFilePath) variable, which will break the "tkwait"
#	loop in mtkFDialog and return the selected filename to the
#	script that calls tk_getOpenFile or tk_getSaveFile
#
proc mtkFDialog_Done {{selectFilePath ""}} {
    global data tkPriv
    if ![string compare $selectFilePath ""] {
	set selectFilePath [file join $data(selectPath) $data(selectFile)]
	set tkPriv(selectFile)     $data(selectFile)
	set tkPriv(selectPath)     $data(selectPath)

	if {[file exists $selectFilePath] && 
	    ![string compare $data(type) save]} {

	    set reply [ask-user "File \"$selectFilePath\" already exists.\nDo you want to overwrite it?" .tkfd]
	    if ![string compare $reply "no"] {
		return
	    }
	}
    }
    set tkPriv(selectFilePath) $selectFilePath
}



#----------------------------------------------------------------------
#
#		      I C O N   L I S T
#
# This is a pseudo-widget that implements the icon list inside the 
# mtkFDialog dialog box.
#
#----------------------------------------------------------------------

# tkIconList --
#
#	Creates an IconList widget.
#
proc tkIconList {w args} {

    global data

    #	Configure the widget variables of IconList, according to the command
    #	line arguments.
    #
    # 1: the configuration specs
    #
    set specs {
	{-browsecmd "" "" ""}
	{-command "" "" ""}
    }
    
    # 2: parse the arguments
    #
    tclParseConfigSpec data $specs "" $args
    
    #	Creates an IconList widget by assembling a canvas widget and a
    #	scrollbar widget. Sets all the bindings necessary for the IconList's
    #	operations.
    
    frame $w
    scrollbar $w.sbar -orient horizontal -highlightthickness 0 -takefocus 0
    canvas $w.canvas -bd 2 -relief sunken -width 400 -height 120 -takefocus 1 -bg white
    pack $w.sbar -side bottom -fill x -padx 2
    pack $w.canvas -expand yes -fill both
    
    $w.sbar config -command "$w.canvas xview"
    $w.canvas config -xscrollcommand "$w.sbar set"

    # Initializes the max icon/text width and height and other variables
    #
    set data(maxIW) 1
    set data(maxIH) 1
    set data(maxTW) 1
    set data(maxTH) 1
    set data(numItems) 0
    set data(curItem)  {}
    set data(noScroll) 1

    # Creates the event bindings.
    #
    bind $w.canvas <Configure> "tkIconList_Arrange"

    bind $w.canvas <1>         "tkIconList_Btn1    %x %y"
    bind $w.canvas <B1-Motion> "tkIconList_Motion1 %x %y"
    bind $w.canvas <Double-1>  "tkIconList_Double1 %x %y"
    bind $w.canvas <ButtonRelease-1> "tkCancelRepeat"
    bind $w.canvas <B1-Leave>  "tkIconList_Leave1 %x %y"
    bind $w.canvas <B1-Enter>  "tkCancelRepeat"

    bind $w.canvas <Up>        "tkIconList_UpDown -1"
    bind $w.canvas <Down>      "tkIconList_UpDown 1"
    bind $w.canvas <Left>      "tkIconList_LeftRight -1"
    bind $w.canvas <Right>     "tkIconList_LeftRight  1"
    bind $w.canvas <Return>    "tkIconList_ReturnKey"
    bind $w.canvas <KeyPress>  "tkIconList_KeyPress %A"
    bind $w.canvas <Control-KeyPress> ";"
    bind $w.canvas <Alt-KeyPress>  ";"

    bind $w.canvas <FocusIn>   "tkIconList_FocusIn"

    return $w
}

# tkIconList_AutoScan --
#
# This procedure is invoked when the mouse leaves an entry window
# with button 1 down.  It scrolls the window up, down, left, or
# right, depending on where the mouse left the window, and reschedules
# itself as an "after" command so that the window continues to scroll until
# the mouse moves back into the window or the mouse button is released.
#
# Arguments:
# w -		The IconList window.
#
proc tkIconList_AutoScan {} {

    global tkPriv data
    set w .tkfd.icons

    if {![winfo exists $w]} return
    set x $tkPriv(x)
    set y $tkPriv(y)

    if $data(noScroll) {
	return
    }
    if {$x >= [winfo width $w.canvas]} {
	$w.canvas xview scroll 1 units
    } elseif {$x < 0} {
	$w.canvas xview scroll -1 units
    } elseif {$y >= [winfo height $w.canvas]} {
	# do nothing
    } elseif {$y < 0} {
	# do nothing
    } else {
	return
    }

    tkIconList_Motion1 $x $y
    set tkPriv(afterId) [after 50 tkIconList_AutoScan]
}

# Deletes all the items inside the canvas subwidget and reset the IconList's
# state.
#
proc tkIconList_DeleteAll {} {
    global data itemList

    .tkfd.icons.canvas delete all
    catch {unset data(selected)}
    catch {unset data(rect)}
    catch {unset data(list)}
    catch {unset itemList}
    set data(numItems) 0
    set data(curItem)  {}
}

# Adds an icon into the IconList with the designated image and text
#
proc tkIconList_Add {image text} {
    global data itemList textList
    set w .tkfd.icons

    set iTag [$w.canvas create image 0 0 -image $image -anchor nw]
    set tTag [$w.canvas create text  0 0 -text  $text  -anchor nw]
    set rTag [$w.canvas create rect  0 0 0 0 -fill "" -outline ""]
    
    set b [$w.canvas bbox $iTag]
    set iW [expr [lindex $b 2]-[lindex $b 0]]
    set iH [expr [lindex $b 3]-[lindex $b 1]]
    if {$data(maxIW) < $iW} {
	set data(maxIW) $iW
    }
    if {$data(maxIH) < $iH} {
	set data(maxIH) $iH
    }
    
    set b [$w.canvas bbox $tTag]
    set tW [expr [lindex $b 2]-[lindex $b 0]]
    set tH [expr [lindex $b 3]-[lindex $b 1]]
    if {$data(maxTW) < $tW} {
	set data(maxTW) $tW
    }
    if {$data(maxTH) < $tH} {
	set data(maxTH) $tH
    }
    
    lappend data(list) [list $iTag $tTag $rTag $iW $iH $tW $tH $data(numItems)]
    set itemList($rTag) [list $iTag $tTag $text $data(numItems)]
    set textList($data(numItems)) [string tolower $text]
    incr data(numItems)
}

# Places the icons in a column-major arrangement.
#
proc tkIconList_Arrange {} {
    global data
    set w .tkfd.icons

    if ![info exists data(list)] {
	if {[info exists w.canvas] && [winfo exists $w.canvas]} {
	    set data(noScroll) 1
	    $w.sbar config -command ""
	}
	return
    }

    set W [winfo width  $w.canvas]
    set H [winfo height $w.canvas]
    set pad [expr [$w.canvas cget -highlightthickness] + \
	[$w.canvas cget -bd]]

    incr W -[expr $pad*2]
    incr H -[expr $pad*2]

    set dx [expr $data(maxIW) + $data(maxTW) + 4]
    if {$data(maxTH) > $data(maxIH)} {
	set dy $data(maxTH)
    } else {
	set dy $data(maxIH)
    }
    set shift [expr $data(maxIW) + 4]

    set x [expr $pad * 2]
    set y [expr $pad * 1]
    set usedColumn 0
    foreach pair $data(list) {
	set usedColumn 1
	set iTag [lindex $pair 0]
	set tTag [lindex $pair 1]
	set rTag [lindex $pair 2]
	set iW   [lindex $pair 3]
	set iH   [lindex $pair 4]
	set tW   [lindex $pair 5]
	set tH   [lindex $pair 6]

	set i_dy [expr ($dy - $iH)/2]
	set t_dy [expr ($dy - $tH)/2]

	$w.canvas coords $iTag $x                 [expr $y + $i_dy]
	$w.canvas coords $tTag [expr $x + $shift] [expr $y + $t_dy]
	$w.canvas coords $tTag [expr $x + $shift] [expr $y + $t_dy]
	$w.canvas coords $rTag $x $y [expr $x+$dx] [expr $y+$dy]

	incr y $dy
	if {[expr $y + $dy] >= $H} {
	    set y [expr $pad * 1]
	    incr x $dx
	    set usedColumn 0
	}
    }

    if {$usedColumn} {
	set sW [expr $x + $dx]
    } else {
	set sW $x
    }

    if {$sW < $W} {
	$w.canvas config -scrollregion "$pad $pad $sW $H"
	$w.sbar config -command ""
	$w.canvas xview moveto 0
	set data(noScroll) 1
    } else {
	$w.canvas config -scrollregion "$pad $pad $sW $H"
	$w.sbar config -command "$w.canvas xview"
	set data(noScroll) 0
    }

    set data(itemsPerColumn) [expr ($H-$pad)/$dy]
    if {$data(itemsPerColumn) < 1} {
	set data(itemsPerColumn) 1
    }

    if {$data(curItem) != {}} {
	tkIconList_Select [lindex [lindex $data(list) $data(curItem)] 2] 0
    }
}

# Gets called when the user invokes the IconList (usually by double-clicking
# or pressing the Return key).
#
proc tkIconList_Invoke {} {
    global data
    set w .tkfd.icons
    if {$data(-command) != "" && [info exists data(selected)]} {
	eval $data(-command) [list $data(selected)]
    }
}

# tkIconList_See --
#
#	If the item is not (completely) visible, scroll the canvas so that
#	it becomes visible.
proc tkIconList_See {rTag} {
    global data itemList
    set w .tkfd.icons

    if $data(noScroll) {
	return
    }
    set sRegion [$w.canvas cget -scrollregion]
    if ![string compare $sRegion {}] {
	return
    }

    if ![info exists itemList($rTag)] {
	return
    }

    set bbox [$w.canvas bbox $rTag]
    set pad [expr [$w.canvas cget -highlightthickness] + \
	[$w.canvas cget -bd]]

    set x1 [lindex $bbox 0]
    set x2 [lindex $bbox 2]
    incr x1 -[expr $pad * 2]
    incr x2 -[expr $pad * 1]

    set cW [expr [winfo width $w.canvas] - $pad*2]

    set scrollW [expr [lindex $sRegion 2]-[lindex $sRegion 0]+1]
    set dispX [expr int([lindex [$w.canvas xview] 0]*$scrollW)]
    set oldDispX $dispX

    # check if out of the right edge
    #
    if {[expr $x2 - $dispX] >= $cW} {
	set dispX [expr $x2 - $cW]
    }
    # check if out of the left edge
    #
    if {[expr $x1 - $dispX] < 0} {
	set dispX $x1
    }

    if {$oldDispX != $dispX} {
	set fraction [expr double($dispX)/double($scrollW)]
	$w.canvas xview moveto $fraction
    }
}

proc tkIconList_SelectAtXY {x y} {
    global data
    set w .tkfd.icons
    tkIconList_Select [$w.canvas find closest \
	[$w.canvas canvasx $x] [$w.canvas canvasy $y]]
}

proc tkIconList_Select {rTag {callBrowse 1}} {
    global data itemList
    set w .tkfd.icons
    if ![info exists itemList($rTag)] {
	return
    }
    set iTag   [lindex $itemList($rTag) 0]
    set tTag   [lindex $itemList($rTag) 1]
    set text   [lindex $itemList($rTag) 2]
    set serial [lindex $itemList($rTag) 3]

    if ![info exists data(rect)] {
        set data(rect) [$w.canvas create rect 0 0 0 0 \
	    -fill #a0a0ff -outline #a0a0ff]
    }
    $w.canvas lower $data(rect)
    set bbox [$w.canvas bbox $tTag]
    eval $w.canvas coords $data(rect) $bbox

    set data(curItem) $serial
    set data(selected) $text
    
    if {$callBrowse} {
	if [string compare $data(-browsecmd) ""] {
	    eval $data(-browsecmd) [list $text]
	}
    }
}

proc tkIconList_Unselect {} {
    global data
    set w .tkfd.icons

    if [info exists data(rect)] {
	$w.canvas delete $data(rect)
	unset data(rect)
    }
    if [info exists data(selected)] {
	unset data(selected)
    }
    set data(curItem)  {}
}

# Returns the selected item
#
proc tkIconList_Get {} {
    global data
    set w .tkfd.icons

    if [info exists data(selected)] {
	return $data(selected)
    } else {
	return ""
    }
}


proc tkIconList_Btn1 {x y} {
    global data
    focus .tkfd.icons.canvas
    tkIconList_SelectAtXY  $x $y
}

# Gets called on button-1 motions
#
proc tkIconList_Motion1 {x y} {
    global tkPriv
    set tkPriv(x) $x
    set tkPriv(y) $y

    tkIconList_SelectAtXY $x $y
}

proc tkIconList_Double1 {x y} {
    global data

    if {$data(curItem) != {}} {
	tkIconList_Invoke
    }
}

proc tkIconList_ReturnKey {} {
    tkIconList_Invoke
}

proc tkIconList_Leave1 {x y} {
    global tkPriv

    set tkPriv(x) $x
    set tkPriv(y) $y
    tkIconList_AutoScan
}

proc tkIconList_FocusIn {} {
    global data

    if ![info exists data(list)] {
	return
    }

    if {$data(curItem) == {}} {
	set rTag [lindex [lindex $data(list) 0] 2]
	tkIconList_Select $rTag
    }
}

# tkIconList_UpDown --
#
# Moves the active element up or down by one element
#
# Arguments:
# w -		The IconList widget.
# amount -	+1 to move down one item, -1 to move back one item.
#
proc tkIconList_UpDown {amount} {
    global data

    if ![info exists data(list)] {
	return
    }

    if {$data(curItem) == {}} {
	set rTag [lindex [lindex $data(list) 0] 2]
    } else {
	set oldRTag [lindex [lindex $data(list) $data(curItem)] 2]
	set rTag [lindex [lindex $data(list) [expr $data(curItem)+$amount]] 2]
	if ![string compare $rTag ""] {
	    set rTag $oldRTag
	}
    }

    if [string compare $rTag ""] {
	tkIconList_Select $rTag
	tkIconList_See $rTag
    }
}

# tkIconList_LeftRight --
#
# Moves the active element left or right by one column
#
# Arguments:
# w -		The IconList widget.
# amount -	+1 to move right one column, -1 to move left one column.
#
proc tkIconList_LeftRight {amount} {
    global data

    if ![info exists data(list)] {
	return
    }
    if {$data(curItem) == {}} {
	set rTag [lindex [lindex $data(list) 0] 2]
    } else {
	set oldRTag [lindex [lindex $data(list) $data(curItem)] 2]
	set newItem [expr $data(curItem)+($amount*$data(itemsPerColumn))]
	set rTag [lindex [lindex $data(list) $newItem] 2]
	if ![string compare $rTag ""] {
	    set rTag $oldRTag
	}
    }

    if [string compare $rTag ""] {
	tkIconList_Select $rTag
	tkIconList_See $rTag
    }
}

#----------------------------------------------------------------------
#		Accelerator key bindings
#----------------------------------------------------------------------

# tkIconList_KeyPress --
#
#	Gets called when user enters an arbitrary key in the listbox.
#
proc tkIconList_KeyPress {key} {
    global tkPriv
    set w .tkfd.icons
    append tkPriv(ILAccel,$w) $key
    tkIconList_Goto $tkPriv(ILAccel,$w)
    catch {
	after cancel $tkPriv(ILAccel,$w,afterId)
    }
    set tkPriv(ILAccel,$w,afterId) [after 500 tkIconList_Reset]
}

proc tkIconList_Goto {text} {
    global data textList tkPriv
    
    if ![info exists data(list)] {
	return
    }

    if {[string length $text] == 0} {
	return
    }

    if {$data(curItem) == {} || $data(curItem) == 0} {
	set start  0
    } else {
	set start  $data(curItem)
    }

    set text [string tolower $text]
    set theIndex -1
    set less 0
    set len [string length $text]
    set len0 [expr $len-1]
    set i $start

    # Search forward until we find a filename whose prefix is an exact match
    # with $text
    while 1 {
	set sub [string range $textList($i) 0 $len0]
	if {[string compare $text $sub] == 0} {
	    set theIndex $i
	    break
	}
	incr i
	if {$i == $data(numItems)} {
	    set i 0
	}
	if {$i == $start} {
	    break
	}
    }

    if {$theIndex > -1} {
	set rTag [lindex [lindex $data(list) $theIndex] 2]
	tkIconList_Select $rTag 0
	tkIconList_See $rTag
    }
}

proc tkIconList_Reset {} {
    global tkPriv
    set w .tkfd.icons
    catch {unset tkPriv(ILAccel,$w)}
}


## MICK added to allow switching drive
# called whenever data(selectDrive) is set.
proc mtkFDialog_SetDrive {args} {
    global data

    mtkFDialog_SetPath $data(selectDrive)
}

# Mick: Routine to handle toplevel of Windows and Mac
# For drive changing

proc tkf_show-toplevel {} {
    global data tkPriv tcl_platform

    # Turn on the busy cursor. BUG?? We haven't disabled X events, though,
    # so the user may still click and cause havoc ...
    #
    set entCursor [.tkfd.f2.ent cget -cursor]
    set dlgCursor [.tkfd cget -cursor]
    .tkfd.f2.ent config -cursor watch
    .tkfd         config -cursor watch
    update idletasks
    
    tkIconList_DeleteAll

    # Make the dir list
    #
    foreach drv [file volume] {
		tkIconList_Add  $tkPriv(folderImage) [string toupper $drv]
    }

    tkIconList_Arrange 

    # Update the Directory: option menu
    #
    .tkfd.f1.menu.menu delete 0 end
    set var data(selectPath)
    switch -- $tcl_platform(platform) {
      windows {set label "My Computer"}
      macintosh {set label "Desktop"}
   }
  
    .tkfd.f1.menu.menu add command -label $label -command [list set $var  $label]

    # turn off the busy cursor.
    .tkfd.f2.ent config -cursor $entCursor
    .tkfd         config -cursor $dlgCursor
}


proc my-cd {path} {
    global tcl_platform
    
    if {[lindex $path 1] != ""} {
	set string ""
	foreach item $path {
	    set string [concat $string " " $item]
	}
	set path $string
    }
    if  { $tcl_platform(platform) == "macintosh" && $path == "Desktop" } {return}
    
    cd "$path"
}


proc my-pwd {} {
    global mtkfCURRDIR
    if ![info exists mtkfCURRDIR] {set mtkfCURRDIR [pwd]}
    return $mtkfCURRDIR
}


proc tkfd-tell-user {message {parent {}}} {
   set oldgrab [grab current]
   if { $oldgrab != {}} {grab release $oldgrab}
   if {$parent != {}} {
	 tk_messageBox -message $message -type ok -icon warning -parent $parent
   } else { 
	tk_messageBox -message $message -type ok -icon warning
   }
   if { $oldgrab != {}} {grab -global $oldgrab}
}