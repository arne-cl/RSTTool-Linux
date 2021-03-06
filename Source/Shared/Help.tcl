proc help-button {path key} {
  global TINY_FONT COLOR
  button $path -text "Help" -command "help $key"\
             -width 3 -font $TINY_FONT  -bg $COLOR(buttons)
  return $path
}


global HELPS

proc defhelp {key text} {
  global HELPS
  set HELPS($key) $text
}

proc help {key} {
    global HELPS
    if ![info exists HELPS($key)] {
	tell-user "No HELP for $key. Complain to implementer."
	return
    }
    scrolled-text-dialog .helpwin "Coder Help"  $HELPS($key) -height 16
}


