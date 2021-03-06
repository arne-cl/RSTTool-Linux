# Functions to read in xml into an array,
# and Functions to access the xml as an embedded structure

proc load-xml {file {encoding {} }} {
    # Loads in the xml into array XMLSEG
    # Also sets LASTSEG and CURRSEG

     #  Parse in the xml form
    set text [read-file $file $encoding]
    load-xml-from-text $text
}


proc load-xml-from-text {text} {
    # We need this so that other routines can extract
    # out between two tags by string search and handle the contained text.

    global LASTSEG XMLSEG CURRSEG
    set i 0
    if [info exists XMLSEG] {unset XMLSEG}

    # Show the Progress bar
    initProgress "Loading xml: " [string length $text]

    set start [string first "<" $text]

    while { $start != -1 } {
	
	incr i
	incr start
	updateProgress $start

	# Test the last char in the <>: < /> -needs no closer; < ?> - a comment
	set endpos [expr [string-first ">" $text $start] - 1]
	switch -- [string index $text $endpos]  {
	    "?" {
		# We have a comment
		incr i -1
		 set start [string-first "<" $text $endpos]
		continue
	    }

	    "/" {
		# This element needs no close tag
		set tagstruct [string range $text $start [expr $endpos - 1]]
		set XMLSEG($i,endneeded) 0
	    }

	    default {
		set tagstruct [string range $text $start $endpos]
		set XMLSEG($i,endneeded) 1
	    }
	}
	
	# Locate the tag
	set XMLSEG($i,tag)  [string tolower [stringpop tagstruct]]
	set XMLSEG($i,args) [parse-args  $tagstruct]

	# Find the start of the next segment
	set segend [string-first "<" $text $endpos]
	
	set text1 [string range $text [expr $endpos +2] [expr $segend -1]]
	set XMLSEG($i,text) [xml-decode $text1]
	
	# Increment curr
	set start $segend
    }

    set CURRSEG 1
    set LASTSEG [expr $i + 1]
    
    closeProgress
}

proc load-xml-from-text-quick {text} {
    # We need this so that other routines can extract
    # out between two tags by string search and handle the contained text.

    global LASTSEG XMLSEG CURRSEG
    set i 0
    if [info exists XMLSEG] {unset XMLSEG}
    
    set segs [split $text "<"]

    # Show the Progress bar
    initProgress "Loading xml: " [llength $segs]

    foreach seg $segs {
	incr i
	updateProgress $i

	# Test the last char in the <>: < /> -needs no closer; < ?> - a comment
	set endpos [expr [string first ">" $seg] - 1]
	switch -- [string index $seg $endpos]  {
	    "?" {
		# We have a comment
		incr i -1
		continue
	    }

	    "/" {
		# This element needs no close tag
		set tagstruct [string range $seg 0 [expr $endpos - 1]]
		set XMLSEG($i,endneeded) 0
	    }

	    default {
		set tagstruct [string range $seg 0 $endpos]
		set XMLSEG($i,endneeded) 1
	    }
	}
	
	# Locate the tag
	set XMLSEG($i,tag)  [string tolower [stringpop tagstruct]]
	set XMLSEG($i,args) [parse-args  $tagstruct]

	# Find the start of the next segment
	set text1 [string range $seg [expr $endpos +2] end]
	set XMLSEG($i,text) [xml-decode $text1]
    }

    set CURRSEG 1
    set LASTSEG [expr $i + 1]
    
    closeProgress
}




proc xml-decode {text} {
    
    regsub -all {&lt;} $text "<" text
    regsub -all {&gt;} $text ">" text
    regsub -all {&amp;} $text {\&} text
    regsub -all {&apos;} $text "'" text
    regsub -all {&quot;} $text {"} text
    return $text
}

# set text [xml-decode "FRED&lt;&gt;&amp;&apos;&quot;END"]

proc xml-encode {text} {

    regsub -all {\&} $text {\&amp;} text
    regsub -all "<" $text {\&lt;} text
    regsub -all ">" $text {\&gt;} text
    regsub -all "'" $text  {\&apos;} text
    regsub -all {"} $text {\&quot;} text
    return $text
}


proc parse-args {args} {

    set args [string trim $args 0]
    if { $args == {} } {
	return {}
    }

    regsub -all "=" $args " = " args
    regsub -all "  " $args " " args
    regsub -all {\\\"} $args {"} args

    if { [string index $args 0] == "\{" } {
	set args [string range $args 1 end-1]
    }
    set result [parse-args1 $args]
    return $result
}

proc parse-args1 {args} {
    # if firstchar is a bracket, remove
    set args [lindex $args 0]
    set args [string trim $args]

    if { $args == {} } {
	return {}
    }

    # We have at least one arg
    set var [stringpop args]

    # For some reason extra spaces in the input are treated as an argument
    if {  $var == "\{\}"} {
	return [parse-args1 $args]
    }

    set eqsign [stringpop args]
    if { $eqsign != "=" } {
	puts "ERROR in parse-args, expected '=': /$eqsign $args/"
	return
    } 
    
    set args [string trim $args]

    if {[string index $args 0] == "\""} {
	set args [string range $args 1 end]
	set endpos [string first "\"" $args]
	set val [string range $args 0 [expr $endpos -1]]
	set args [string range $args [expr $endpos + 1] end]
    } else {
	set val [stringpop args]
    }

    set val [xml-decode $val]
    
    # Add the rest of the args
    return [concat [list [list $var $val]] [parse-args1 $args]]
}
	




###################
# Parse-XML

proc parse-xml { {no_closetag_needed {}} {xmldepth 0}} {
    global XMLSEG LASTSEG CURRSEG 
    # interpret the start segment
    set tag $XMLSEG($CURRSEG,tag)
    set lastseg $CURRSEG

#    puts "[string repeat " " $xmldepth] Looking for tag: $tag"

    # if a tag with no closer, return it
 #     puts "TAGS $no_closetag_needed"

    if { $XMLSEG($CURRSEG,endneeded) == 0  || [member $tag $no_closetag_needed] == 1} {
# 	puts "[string repeat " " $xmldepth] -- but no closetag needed"
	return [list $tag $XMLSEG($CURRSEG,args)]
    }

    incr CURRSEG

    # look for end of tagset
    set endtag "/$tag"

    set substruct {}

    while { $CURRSEG < $LASTSEG } {

	if { $XMLSEG($CURRSEG,tag) == $endtag } {
# 	    puts "[string repeat " " $xmldepth] -- Matched tag: $endtag"
	    return [list $tag $XMLSEG($lastseg,args) $substruct $XMLSEG($lastseg,text)]
	} else {
	    lappend substruct [parse-xml $no_closetag_needed [expr $xmldepth + 1]]
	}
	incr CURRSEG
    }

    tell-user "Error: parse-xml: Tag $tag not matched: $substruct"
    error "Error: Tag $tag not matched: $substruct"
}




proc get-xml-element {form path} {
    return [first [get-xml-elements $form $path]]
}


proc get-xml-elements {form path} {

    set thistag [lindex $path 0]
    if {$thistag == {} } {
	tell-user "get-xml-elements: null path element"
	break
    }

    # match the formtag and the pathtag
    if { $thistag != [lindex $form 0] } {
	return {}
    }

    # we have a match
    set Tail [lrange $path 1 end]

    if  {$Tail == {} } {
	# this is the element to retrieve
	return [list $form]
    }

    # If only one more tag, allow it to match args
    if { [llength $Tail] == 1} {
	set lasttag [lindex $Tail 0]
	foreach arg [lindex $form 1] {
	    if { $lasttag == [lindex $arg 0] } {
		return [list [lindex $arg 1]]
	    }
	}
    } 

    # else, match on the structure
    set results {}

    foreach subform [lindex $form 2] {
	set result [get-xml-elements $subform $Tail]
	if { $result != {} } {
	    set results [concat $results $result]
	}
    }
    
    return $results
}

