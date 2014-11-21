

proc BugReport {message} {
    global BG_COLOR1  errorInfo
    bell
    if [winfo exists .bugreport] {destroy .bugreport}
    toplevel .bugreport -bg $BG_COLOR1
    wm title .bugreport "Error Report"

    label .bugreport.lab -text $message
    scrolled-text .bugreport.error -height 12
    button .bugreport.done -text "Done" -command {destroy .bugreport}
    .bugreport.error.text insert end  $errorInfo
    pack .bugreport.lab -side top -anchor n

    pack .bugreport.error -side top  -anchor nw -expand t -fill both
    pack .bugreport.done -side top -anchor n 
    return .bugreport
}
    
    