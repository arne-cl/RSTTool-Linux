

proc scrolled-listbox {name args} {
# Returns a scrollable listbox
# $name.listbox is the actual listbox widger
# $name.title is the title
#
# Args: (as listbox)
  set bg [getarg -bg $args]
  frame $name -bg $bg
  listbox $name.choices -yscrollcommand "$name.scroll set"
  scrollbar $name.scroll -command "$name.choices yview"

  for {set i 0} {$i < [llength $args]} {incr i 2} {
      $name.choices configure [lindex $args $i]\
	      [lindex $args [expr $i + 1]]
  }

  pack $name.scroll -side right -fill y 
  pack $name.choices -fill both -expand 1 -side left
  return $name
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