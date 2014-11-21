# TCL EXTENSIONS


proc append-strings {args} {
# Returns the input string-list as a single string.
 set result ""
 foreach arg $args {
   append result $arg
 }
 return $result
}

proc string-replace {string old new} {
  set pos [string first $old $string]
  set len [string length $old]
  switch -- $pos {
    -1  {return -1}
    0 {return "$new[string range $string $len end]"}
    default {
       set pre [string range $string 0 [expr $pos -1]]
       set post [string range  $string [expr $pos + $len] end]
       return $pre$new$post
      }
    }
}


proc delete-newlines {text} {
    # Removes linebreaks from the text.
    eval concat [split $text \n]
}


proc delete-duplicates {list} {
    # Removes all duplicates from the list.
    set result {}
    foreach itm $list {
	if ![member $itm $result] {
	    lappend result $itm
	}
    }
    return $result
}


proc delete-nulls {list} {
    # Deletes empty lists from the list.
    set result {}
    foreach itm $list {
	if { $itm != {}} {
	    lappend result $itm
	}
    }
    return $result
}

proc set-difference {list1 list2} {
    # Returns a list consisting of the elements in list1 which are not in list2.
    set result {}
    foreach itm $list1 {
	if ![member $itm $list2] {
	    lappend result $itm
	}
    }
    return $result
}

proc intersection {l1 l2} {
    # returns the elements that are common to list l1 and l2.
    set result {}
    foreach item $l1 {
	if [member $item $l2] {
	    lappend result $item
	}
    }
    return $result
}

proc set-equal {set1 set2} {
    # Returns 1 if set1 and set2 contain the same elements, in whatever order. Else returns 0
    # Lists should contain no duplicates.
    if { [llength $set1] != [llength $set2] } {
	return 0
    }

    foreach itm $set1 {
	if { [lsearch $set2 $itm] == -1 } {
	    return 0
	}
    }
    return 1
}


proc intersect-p {list1 list2} {
    # Returns 1 if list1 and list2 have a common element, else 0.
    foreach itm $list1 {
	if [member $itm $list2] {
	    return 1
	}
    }
    return 0
}



proc subset-p {set1 set2} {
    # Returns 1 if all elements of list1 are in list2.
    foreach itm $set1 {
	if ![member $itm $set2] {
	    return 0
	}
    }
    return 1
}



##################################


proc ldelete { list value } {
#  Returns the list with all matches of the value deleted.
# (From Welch examples)

    set ix [lsearch -exact $list $value]
        if {$ix >= 0} {
                return [lreplace $list $ix $ix]
        } else {
                return $list
        }
}

proc delete {var value} {
# Destructively deletes all instances of value from the list in variable 'var'.
    upvar $var list
    set ix [lsearch -exact $list $value]
   
    if {$ix >= 0} {
	set list [lreplace $list $ix $ix]
    } 
    return $list
}


proc lappend-new {var value} {
    upvar $var list
    if ![info exists list] {set list {}}
    if { [lsearch -exact $list $value] == -1} {
	lappend list $value
    } 
    return $list
}


proc concat! {var list2} {
    upvar $var list
    if ![info exists list] {
	set list $list2
    } else {
	set list [concat $list $list2]
    }
    return $list
}

proc substitute {var old new} {
    # replaces old for new in a flat list -destructive

    upvar $var list
    set ix [lsearch -exact $list $old]
   
    if {$ix >= 0} {
	set list [lreplace $list $ix $ix $new]
    } 
    return $list
}

##################################
# has-tag
proc has-tag {canv item tag} {
# Returns non-nil if item in canvas has given tag
 lsearch [lindex [$canv itemconfigure $item -tags] 4] $tag
}

proc member {item list} {
 if { [lsearch $list $item] == -1 } {
  return 0
 } else {
  return 1
 }
}



proc debug {{str {}}} {
  global DEBUG
    if ![info exists DEBUG] {set DEBUG 0}
  if { $str == {} } {
   # debug with no arg toggles debug on/off
     if { $DEBUG == 1 } {
        set DEBUG 0
        puts "debug is off"
      } else { 
          set DEBUG 1
         puts "debug is on"
     }
  } elseif { $DEBUG == 1 } {
      puts $str
 }
}

proc start-debug {{file ./coder-debug}} {
  global DEBUG
  set DEBUG 1
}

proc push {value var} {
    upvar $var list
    set list [concat [list $value] $list]
    return $list
}


proc pop {var} {
    upvar $var list
    set val [lindex $list 0]
    set list [lrange $list 1 end]
    return $val
}

proc pop-from-end {var} {
    upvar $var list
    set last [expr [llength $list] -1]
    set val [lindex $list $last]
    set list [lrange $list 0 end-1]
    return $val
}


proc stringpop {var} {
# Works on strings where pop works on lists
    upvar $var string1
    set pos [string first " " $string1]
    if { $pos == -1 } {
	set val $string1
	set string1 ""
    } else {
	set val [string range $string1 0 [expr $pos -1]]
	set string1 [string trim [string range $string1 [expr $pos+ 1] end]]
    }
    return $val
}




proc list-replace {old new list} {
    # recurses down embedded lists to replace each instance of old with new
    set newlist {}
    foreach itm $list {
	if { $itm == $old} {
           lappend newlist $new
	} elseif { [lindex $itm 1] == {} } {
	    # not a list
	    lappend newlist $itm
	} else {
	    # a list
	    lappend newlist [list-replace $old $new $itm]
	}
    }
    return $newlist
}


proc first {list} {
  return [lindex $list 0]
}

proc last {list} {
  return [lindex $list [expr [llength $list] - 1]]
}

proc car {list} {
  return [lindex $list 0]
}

proc cdr {list} {
  return [lrange $list 1 end]
}

proc second {list} {
  return [lindex $list 1]
}

proc third {list} {
  return [lindex $list 2]
}

proc fourth {list} {
  return [lindex $list 3]
}

proc list-p {arg} {
    switch -- [llength $arg] {
	1 {return 0}
	default {return 1}
    }
}


proc write-file {file text} {

    if [file exists  $file] {file delete $file}
    if [catch "set str [open $file w]"] {
	debug "Error in opening file for writing: $file"
	tell-user  "Could not open file for writing: $file"
	return 0
    }
    puts $str $text
    close $str
    return 1
}


proc read-file {file {encoding {}}} {
    # returns a file as a string
    set file [string trim $file]
    
    if [catch "set str [open $file r]"] {
	tell-user "Error in opening file for reading: $file. Readability: [file readable $file] Existence: [file exists $file]"
	return 0
    }
    
    if {$encoding != {} && $encoding != "Standard"} {
	if [catch "fconfigure $str -encoding $encoding"] {
	    tell-user "Couldn't read $file with encoding $encoding. Reading unencoded."
	} else {
	    tell-user "Reading text as Encoded: $encoding"
	}
    }
    set result [read $str]
    close $str
    return $result
}


proc string-capitalise {string} {
    # capitalises the first element of string
    return "[string toupper [string index $string 0]][string range $string 1 end]"
}
    

proc null {arg} {
    if { $arg == {} } {
	return 1
    } 
    return 0
}

proc lreverse {list} {
    if { $list == {} } {return {} }
    set head [pop list]
    set rest [lreverse $list]
    lappend rest $head
    return $rest
}

# Given a list of key/val, and a key, returns the val.
# e.g., find fred {{fred 1} {mary 2} {john 3}}
# --> 1
proc find {key list} {
    foreach item $list {
	if { [lindex $item 0] == $key } {
	    return [lindex $item 1]
	}
    }
}


proc date {} {
    return [clock format [clock seconds] -format %c]
}
 


proc getarg {key list} {
# Returns the value in list immediately following key
    for {set i 0} {$i < [llength $list]} {incr i 2} {
	if { [lindex $list $i] == $key } {
	    return [lindex $list [expr $i + 1]]
	}
    }
    return {}
}

proc getargs { list} {
    # input {-a 1 -b 2 ...}
    # output: { {-a 1} {-b 2} ...}
    set result {}
    for {set i 0} {$i < [llength $list]} {incr i 2} {
	lappend result {[lindex $list $i] [lindex $list [expr $i + 1]]}
    }
    return $result
}




# Version 8.1, 8.2 etc cannot handle a start index for string first
global tcl_version
if { $tcl_version > 8.2 } {
    
    proc string-first {find str start} {
	return [string first $find $str $start]
    }
} else {
    proc string-first {find str start} {
	set substr [string range $str $start end]
	set pos  [string first $find $substr]
	if { $pos > -1 } {
	    return [expr $pos + $start]
	}
	return -1
    }
}

proc one-or-many {list {conj "and"}} {
    if {[llength $list] < 2 } {
	return [lindex $list 0]
    }
    return [concat $conj $list]
}


# by WPD (http://www.pbcomm-inc.com)
proc isnum { x } {
    expr { [string trim $x "0123456789"] == "" && $x != "" } 
}

# by WPD (http://www.pbcomm-inc.com)
proc isletter { x } {
    expr { [string trim [string tolower $x] "abcdefghijklmnopqrstuvwxyz"]
    == "" && $x != "" } 
}

proc capitalise {string} {
    set first  [string toupper [string range $string 0 0]]
    set rest   [string tolower [string range $string 1 end]]
    return "$first$rest"
}