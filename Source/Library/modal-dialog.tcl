
# modal dialog
proc modal-dialog {path args} {
  global PLATFORM
  if [winfo exists $path] {
     destroy $path
  }
  if {$PLATFORM == "macintosh"} {
    eval "toplevel $path -borderwidth 10 $args ; unsupported1 style $path plainDBox"
  } else {
    eval "toplevel $path -borderwidth 10 $args"
  }
  return $path
}




   
proc post-modal {path} {
  global modal_val
  if [info exists modal_val] {unset modal_val}

  tkwait visibility $path

  # wm transient means that the popup is always over the main, even if
  # user clicks on a background window and returns by clicking on the main icon
  wm transient $path .
  
  # This ensures the window is at the top
  wm deiconify $path
  focus $path
  grab $path
  tkwait variable modal_val($path)
  grab release $path
  destroy $path
  return $modal_val($path)
}


proc return-from-modal {path val} {
  global modal_val
  set modal_val($path) $val
}

proc returned-value {path} {
    global modal_val
    if  [info exists modal_val($path)] {return $modal_val($path)}
}

proc modal-test {} {

set f [modal-dialog .tmp]
message $f.msg -text "Create New Coding File"
entry $f.entry -textvariable prompt(result)
set b [frame $f.buttons -bd 10]
pack $f.msg $f.entry $f.buttons -side top -fill x
button $b.ok -text OK -command {return-from-modal $f 1} \
    -underline 0
  button $b.cancel -text Cancel -command {return-from-modal $f 0} \
    -underline 0
  pack $b.ok -side left
  pack $b.cancel -side right

  post-modal $f
}




