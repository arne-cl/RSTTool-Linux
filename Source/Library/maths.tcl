### Assorted MAths functions


proc div {N D} {
    return [expr ($N + 0.0000) / $D]
}

proc max {args} {
  set max -99999
    foreach arg $args {
	if {$arg > $max} {set max $arg}
    }
  return $max
}

proc min {args} {
    set min 99999999
    foreach arg $args {
	if {$arg < $min} {set min $arg}
    }
    return $min
}

proc sumlist {list} {
  set x 0
  foreach itm $list {
	incr x $itm
  }
  return $x
}


proc integer-p {i} {
    if [catch "expr $i + 1"] {
	return 0
    }
    return 1
}