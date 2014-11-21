#############################################
# scrolled-text dialog item

proc Scrolled-text {name args} {
# Returns a scrollable text widget
# $name.text is the actual text widget
# $name.title is the title
#
# Args: (all optional)
# -height <integer>
# -font <font-spec>
# -titlevar varname : variable containing the name of the frame title
    
    set height [getarg -height $args]
    if { $height == {} } {set height 40}
    set bg [getarg -bg $args] 
    if { $bg == "" } {set bg white }
    frame $name -height $height -bg $bg
    frame $name.textwindow -bg $bg
    label $name.title -textvariable [getarg -titlevar $args] -text [getarg -title $args]  -bg $bg
    
    text  $name.text  -bg white -relief sunken\
	    -yscrollcommand "$name.scroll set" -height $height 
    scrollbar $name.scroll -command "$name.text yview"
    set messagebar [getarg -messagebar $args]
    if { $messagebar == "t"} {
	frame $name.msgbar -height 10
	text  $name.msg  -bg grey -relief raised -height 1.2
    }
    set font [getarg -font $args]
    if { $font != {} } {
	$name.text configure -font $font
    }
    pack $name.title  -side top  -fill x

    if {$messagebar == "t"} {
	pack $name.msg -in $name.msgbar -fill x -expand 1 -side top
	pack $name.msgbar -fill x  -side top
    }
    pack $name.text -in $name.textwindow -fill both -expand 1 -side left
    pack $name.scroll -in $name.textwindow -side right -fill y 
    pack $name.textwindow -side top -expand 1 -fill both

}

