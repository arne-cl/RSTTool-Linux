### GRAPHIC PRIMITIVES ###########################

proc draw-text {window txt x y {options {}}} {
  eval {$window create text} $x $y\
       {-text $txt -anchor n -justify center}\
      $options
}

proc draw-text-left {window txt x y {options {}}} {
  eval {$window create text} $x $y\
       {-text $txt -anchor nw -justify left}\
      $options
}

proc draw-line {window x1 y1 x2 y2} {
  $window create line $x1 $y1  $x2 $y2
}

proc draw-line-between {window p1 {p2 {}}} {
 eval [concat "draw-line" $window $p1 $p2]
}

proc draw-arrow-between {window p1 {p2 {}}} {
 eval [concat "draw-line" $window $p1 $p2]
}

proc draw-rect {window x1 y1 x2 y2} {
  $window create rect $x1 $y1  $x2 $y2
}

proc draw-rect-between {window p1 {p2 {}}} {
 eval [concat "draw-rect" $window $p1 $p2]
}

proc draw-arc {window points} {
  set cmd "$window create line"
  set options {-tag line -joinstyle round -smooth true -arrow first}
  eval [concat $cmd $points $options]
}

proc add-points {p1 p2} {
  list [expr [lindex $p1 0] + [lindex $p2 0]]\
       [expr [lindex $p1 1] + [lindex $p2 1]]
}

proc subtract-points {p1 p2} {
  list [expr [lindex $p1 0] - [lindex $p2 0]]\
       [expr [lindex $p1 1] - [lindex $p2 1]]
}

proc mid-point {p1 p2} {
  add-points $p1 [halve-point [subtract-points $p2 $p1]]
}

proc halve-point {p1} {
  list [expr [lindex $p1 0] / 2]\
       [expr [lindex $p1 1] / 2]
}



proc screen-coords {item canvas} {
# Returns the screen coordes of a canvas item
  set screencorrect "[winfo rootx $canvas] [winfo rooty $canvas]"
  set coords  [$canvas coords $item] 

  set scrollcorrection "[$canvas canvasx 0]\
                  [$canvas canvasy 0]"
  return [add-points [subtract-points $coords $scrollcorrection]\
                     $screencorrect]
}

proc move-item {window item xdelta ydelta} {
  $window move $item $xdelta $ydelta
}


proc point-in-rectangle-p {pt rect} {
    puts "PIRP: $pt/$rect"
    set x [lindex $pt 0]
    set y [lindex $pt 1]
    if { [expr $x -4] < [lindex $rect 0] || [expr $x +4] > [lindex $rect 2] ||\
	    [expr $y -4] < [lindex $rect 1] || [expr $y +4] > [lindex $rect 3] } {
	puts "$pt is outside $rect"
	return 0
    }
    return 1
}




proc widget-width {canv itm} {
    set bbox [$canv bbox $itm]
    return [expr [lindex $bbox 2] - [lindex $bbox 0]]
}

proc widget-height {canv itm} {
    set bbox [$canv bbox $itm]
    return [expr [lindex $bbox 3] - [lindex $bbox 1]]
}
