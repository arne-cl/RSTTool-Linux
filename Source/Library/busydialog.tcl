# Places a message on the screen


proc busy-dialog {path msg args} {
  global PLATFORM
  if [winfo exists $path] {
     destroy $path
  }
  if {$PLATFORM == "macintosh"} {
    eval "toplevel $path -borderwidth 10 $args ; unsupported1 style $path plainDBox"
  } else {
    eval "toplevel $path -borderwidth 10 $args"
  }

  label $path.lab -text $msg
  pack $path.lab
  return $path
}


proc close-busy-dialog {path msg} {
    $path.lab config -text $msg
    update
    after 2000
    destroy $path
}