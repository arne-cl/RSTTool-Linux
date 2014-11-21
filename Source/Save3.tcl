
#####################################
## SAVING

proc save-rst3 {file} {
    global RST_FILE RSTFORMAT RELATIONS_FILE NODE TEXT_NODES GROUP_NODES\
	    RELATIONS SCHEMAS SCHEMA_ELEMENTS ENCODING
    # Open the file
    set f [open $file w 0600]
    
    # Put the header opener
    puts $f "<rst>"
    puts $f "  <header>"

    # Register an internationalisation encoding (if any)
    if [info exists ENCODING] {
	if { $ENCODING != "Standard"} {
	    puts $f "    <encoding name=\"$ENCODING\" />"
	    tell-user "Saving in $ENCODING format"
	    fconfigure $f -encoding $ENCODING
	}
    }

    # save the relations field
    puts $f "    <relations>"
    foreach rel $RELATIONS(rst)  {
	set rel [string tolower $rel]
	puts $f "      <rel name=\"$rel\" type=\"rst\" />"
    }
    foreach rel $RELATIONS(multinuc)  {
	set rel [string tolower $rel]
	puts $f "      <rel name=\"$rel\" type=\"multinuc\" />"
    }
    
    foreach schema $SCHEMAS {
	foreach rel $SCHEMA_ELEMENTS($schema) {
	    set rel [string tolower $rel]
	    puts $f "      <rel name=\"$rel\" schema=\"$schema\" />"
	}
    }
    
    puts $f "    </relations>"
    puts $f "  </header>"

    # Save the text
    puts $f "  <body>"
    foreach itm $TEXT_NODES {
	if { $NODE($itm,parent) != {} } {
	    set rel [string tolower $NODE($itm,relname)]
	    set parent " parent=\"$NODE($itm,parent)\" relname=\"$rel\""
	} else {
	    set parent ""
	}
	set text [get-text $itm]
	set text [xmlify-text $text]

	puts $f "    <segment id=\"$itm\"$parent>$text</segment>"
    }
    
    foreach itm $GROUP_NODES {
	if { $NODE($itm,parent) != {} } {
	    set rel [string tolower $NODE($itm,relname)]
	    set parent " parent=\"$NODE($itm,parent)\" relname=\"$rel\""
	} else {
	    set parent ""
	}
	puts $f "<group id=\"$itm\" type=\"$NODE($itm,type)\"$parent />"
    }

    # Close the file
    puts $f "  </body>"
    puts $f "</rst>"
    close $f
}



proc xmlify-text {text} {
    regsub -all "<" $text {\&lt;} text
    regsub -all ">" $text {\&gt;} text
    regsub -all "&" $text {\&amp;} text
    regsub -all {"}  $text {\&quot;} text
    regsub -all {'}  $text {\&apos;} text
    return $text
}

proc unxmlify-text {text} {
    regsub -all {\&lt;}  $text "<" text
    regsub -all {\&gt;} $text ">" text
    regsub -all {\&amp;} $text {\&}  text
    regsub -all {\&quot;} $text {"}  text
    regsub -all {\&apos;} $text {'}  text
    return $text
}
