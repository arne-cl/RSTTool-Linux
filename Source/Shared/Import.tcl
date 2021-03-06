######################################
## Systemic Coder
#
#  File: Import.tcl
#  Author: Mick O'Donnell micko@wagsoft.com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the Systemic Coder License Terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/Coder/copyright.txt
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.

######################################
## RSTTool 
#
#  File: Import.tcl
#  Author: Mick O'Donnell micko@wagsoft.com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms  terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/RSTTool/copyright.html.
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.


# Routines for Text Importing

global IMPORT_FILE  LAST_DIR 

# To-Do: for mac, no window close button
# or make it cancel

############################
## Import

proc import-text {} {
  global TOOL IMPORT_FILE GRAMMAR_FILE SCHEME_SRC 

    if { $TOOL == "rsttool"} {
	global RELATIONS_FILE RELS SCHEMES
	set GRAMMAR_FILE $RELATIONS_FILE
	set SCHEMES $RELS
    }

    if { [prompt-save-current-files] == "cancel" } {
	return
    }

    uninstall-interface 
    make-import-dialog
    
    if { $IMPORT_FILE == {} } {return}
    
    if {[returned-value .import] == 0} {return}


  # load/create the relations/Scheme
    switch -- $SCHEME_SRC  {
	0 {create-scheme}
	1 {copy-scheme $GRAMMAR_FILE}
	2 {
	    switch -- $TOOL {
		coder {load-scheme $GRAMMAR_FILE 1}
		rsttool {load-relations-master $GRAMMAR_FILE}
	    }
	}
    }

    switch -- $TOOL {
	coder {graph-scheme}
	rsttool {set RELATIONS_FILE $GRAMMAR_FILE}
    }

    install-interface segment
    import-file $IMPORT_FILE
}


proc make-import-dialog {} {
    global SCHEME_SRC IMPORT_FILE GRAMMAR_FILE ENCODING BG_COLOR2
    
    #  position this near top of screen
    set f [modal-dialog .import]
    wm protocol .import WM_DELETE_WINDOW "return-from-modal .import 0"
    wm geometry $f +20+40
    label $f.title -text "Create New [tool-specific-label] File" 
    
    frame $f.filename -borderwidth 2 -relief sunken
    label $f.filename.label -text "Text File:" 
    entry $f.filename.entry  -bg white -relief sunken -textvariable IMPORT_FILE\
	    -width 50 -borderwidth 1
    button $f.filename.button -text "Locate" -command {select-import-file} -bg $BG_COLOR2
    help-button $f.filename.help select_import_file
    pack $f.filename.label $f.filename.entry $f.filename.button $f.filename.help\
	    -side left  -padx 5

    if ![info exists ENCODING] {set ENCODING "Standard"}
    
    frame $f.encoding -borderwidth 2 -relief sunken
    label $f.encoding.label -text "Encoding:" 
    entry $f.encoding.entry -textvariable ENCODING
    button $f.encoding.button -text "Choose"  -bg $BG_COLOR2 -command {
	set xpos [winfo  rootx .import.encoding.button]
	set ypos [winfo  rooty .import.encoding.button]
	set encodings [concat "Standard" [lsort -ascii [encoding names]]]
	set choice [popup-choose-from-list $encodings $xpos $ypos "Choose Encoding"]

	if { $choice != "cancelled"} {
	    set ENCODING $choice
	}
    }
    help-button $f.encoding.help import_encoding
    pack $f.encoding.label $f.encoding.entry  $f.encoding.button $f.encoding.help\
	    -side left  -padx 5
    
    frame $f.scheme -borderwidth 2  -relief sunken
    label $f.scheme.label -text "[tool-specific-label]:" 
    frame $f.scheme.options 
    radiobutton $f.scheme.options.create -text "Start from Scratch"\
	    -variable SCHEME_SRC  -value 0 \
	    -command disable-scheme-selection
    
    radiobutton $f.scheme.options.copy -text "Copy From:"\
       -variable SCHEME_SRC  -value 1 \
       -command enable-codings-selection

    radiobutton $f.scheme.options.master -text "Use Master:"\
	    -variable SCHEME_SRC  -value 2 \
	    -command enable-scheme-selection
    
    pack  $f.scheme.options.create  $f.scheme.options.copy $f.scheme.options.master -side top -anchor w
    
    frame $f.scheme.file
    label $f.scheme.file.label -text "[tool-specific-label] File:" 
    entry $f.scheme.file.entry  -bg white -relief sunken \
	    -textvariable GRAMMAR_FILE -width 30 -borderwidth 1
    button $f.scheme.file.button -text "Locate"  -bg $BG_COLOR2 -command {
	select-scheme-file .import
    }
    help-button $f.scheme.file.help scheme
    
    # set one of the buttons
    if { $GRAMMAR_FILE == {} } {
	set SCHEME_SRC 0
	disable-scheme-selection 
    } else {
	set SCHEME_SRC 2
	enable-scheme-selection
    }
    
    pack $f.scheme.file.label $f.scheme.file.entry $f.scheme.file.button $f.scheme.file.help\
	    -side left  -padx 5
    
    pack $f.scheme.label $f.scheme.options -side left 
    pack $f.scheme.file -side top  -padx 5
    
    pack $f.title $f.filename $f.encoding $f.scheme -fill x -expand t
    
    frame $f.buttons 
    button $f.buttons.ok -text "Import" -underline 0 \
	    -command "import-text-action"  -bg $BG_COLOR2
    button $f.buttons.cancel -text Cancel -command "return-from-modal $f 0" \
	    -underline 0  -bg $BG_COLOR2
    bind $f <Return> "import-text-action"
    bind $f <Control-c> "return-from-modal $f 0"
    
    pack $f.buttons.ok $f.buttons.cancel  -padx 15 -side left
    pack $f.buttons -pady 10
    post-modal $f
}

proc disable-scheme-selection {} {
  .import.scheme.file.label config -fg gray
  .import.scheme.file.button config -state disabled
  .import.scheme.file.entry config -state disabled
  .import.scheme.file.entry config -fg gray
}

proc enable-scheme-selection {} {
    .import.scheme.file.label config -text "Scheme File"
  .import.scheme.file.label config -fg black
  .import.scheme.file.button config -state normal
  .import.scheme.file.entry config -state normal
  .import.scheme.file.entry config -fg black
}

proc enable-codings-selection {} {
    .import.scheme.file.label config -text "Codings File"
    .import.scheme.file.label config -fg black
    .import.scheme.file.button config -state normal
    .import.scheme.file.entry config -state normal
    .import.scheme.file.entry config -fg black
}

proc tool-specific-label {} {
    global TOOL
    switch -- $TOOL {
	rsttool {return "Relations"}
	coder   {return "Scheme"}
    }
}

proc import-text-action {} {
    global SCHEME_SRC GRAMMAR_FILE IMPORT_FILE
    
    if ![check-file $IMPORT_FILE "Text file"]  {
	return 0
    }
    if {$SCHEME_SRC != 0 } {
	if ![check-file $GRAMMAR_FILE "[tool-specific-label] master"] {
	    return 0
	}
    }
    return-from-modal .import 1
}


proc create-scheme {} {
    global TOOL GRAMMAR_FILE
    switch -- $TOOL {
	rsttool {init-relations}
	coder {
	    set GRAMMAR_FILE {}
	    clear-systems 
	    set root [GetValue "Provide a name which covers all units you are coding?"]
	    set root [label-to-name $root]
	    if { $root == ""} {set root unit}
	    defroot $root
	    add-system-under $root
	}
    }
}

proc create-master-scheme {} {
  set scheme_file [get-new-file-name "Name of [tool-specific-label] file to create?"]
}

proc copy-scheme {file} {
    if { $file == "" || [file exists $file] != 1} {
	tell-user "Specified file is not an existing codings file: $file"
	return
    }
    load-scheme-from-codings-file $file
}


proc select-import-file {} {
  global IMPORT_FILE DIR
  set IMPORT_FILE [tk_getOpenFile -title "Select Text File" -parent .import\
	  -initialfile "*.txt"\
	  -initialdir $DIR\
	  -filetypes {{{Plain Text} {.txt}} {{All Files} {.*}}}]
}

proc select-scheme-file {par} {
  global GRAMMAR_FILE SCHEMES TOOL ANALYSES
    switch -- $TOOL {
	rsttool {
	    set GRAMMAR_FILE [tk_getOpenFile -title "Select Relations File"\
		    -initialfile "*.rel"\
		    -initialdir $SCHEMES -parent $par\
		    -filetypes [list [list "Relations Files" [list ".rel"]] {{All Files} {.*}}]]
	}
	coder {
	    if { [lindex [.import.scheme.file.label config -text] 4] ==  "Codings File"} {
		set initfile "*.cd3"
		set lab "Codings"
		set initdir $ANALYSES
		set filetypes [list ".cd3" ".cd2"]
	    } else {
		set initfile "*.scheme"
		set lab "Scheme"
		set initdir $SCHEMES
		set filetypes [list ".scheme"]
	    }
	    set GRAMMAR_FILE [tk_getOpenFile -title "Select $lab File"\
		    -initialfile $initfile\
		    -initialdir $initdir -parent $par\
		    -filetypes [list [list "$lab Files" $filetypes] {{All Files} {.*}}]]
	}
    }

}


proc check-file {file description} {
  if  {$file == {} } {
    tell-user "Please specify $description before proceeding." .import
    return 0
  }
  if ![file exists $file] {
    tell-user "Cannot locate $description: $file." .import
    return 0
  }
  return 1
}

defhelp select_import_file "Select a plain text file which you want to annotate.
If your text is currently in word-processor format, e.g., Microsoft Word, then select
the \"Save as Text\" option in the word-processor when saving."

defhelp import_encoding "To work with the usual European font (ascii) use
\"Standard\". Else select the encoding for your language. For instance, Japanese
files are usually euc-jp or shiftjis."

global TOOL
switch -- $TOOL {
    rsttool {
	defhelp scheme "A scheme defines the set of RST relations to
use while coding.  Every RST analysis is saved with its scheme
attached. When creating a new analysis (with the Import Text option),
you can either start your own set from scratch (Create New), or use an
existing scheme.  An existing scheme can be taken from another RST
analysis (Copy From), or can be loaded from a master scheme (Use
Master). A master scheme is an RST scheme saved without any associated
analysis."

}

    coder {

defhelp scheme "A scheme defines the set of categories you wish to code the text for, organised in a system network. The scheme can be saved along with the codings, in the same file. Alternatively, the scheme can be saved as a separate file, with a pointer to this scheme file included in the codings file. 

   When creating a new analysis (with the Import Text option), you can either start your own scheme from scratch (Create New), or use an existing scheme (Use Master).  An existing scheme is loaded from a master scheme, which is a coding scheme saved without any associated analysis."
}
}



proc load-file {filename} {
  global ENCODING
  if { $filename == {} } {return}

  # 2. Load the named file
  .segment.editor.text delete 1.0 end
  .segment.editor.text insert end  [string trimright [read-file $filename $ENCODING]]

  rollover-message "Imported file:  $filename"
}


puts "import-text loaded"


