

proc scrolled-text {name args} {
# Returns a scrollable text widget
# $name.text is the actual text widger
# $name.title is the title
#
# Args: (all optional)
# -height <integer>
# -font <font-spec>
# -titlevar varname : variable containing the name of the frame title
  set height [getarg -height $args]
  if { $height == {} } {set height 40}
  frame $name 
# -height $height
  frame $name.textwindow
  frame $name.msgbar -height 10
  label $name.msgbar.title -textvariable [getarg -titlevar $args] -width 40 -relief raised

  text  $name.text  -bg white -relief sunken -wrap word\
    -yscrollcommand "$name.scroll set"
  scrollbar $name.scroll -command "$name.text yview"


  set font [getarg -font $args]
  if { $font != {} } {
    $name.text configure -font $font
  }
  
  pack $name.msgbar.title  -side left  -fill x
  if { [getarg -messagebar $args] == "t"} {
     text $name.msgbar.msg -bg grey  -height 1.2
     pack $name.msgbar.msg -fill x -expand 1 -side right
  }

  pack $name.scroll -in $name.textwindow -side right -fill y 
  pack $name.text -in $name.textwindow -fill both -expand 1 -side left


  pack $name.msgbar -fill x  -side top
  pack $name.textwindow -side top -expand 1 -fill both
  return $name

}


