global BG_COLOR1 BG_COLOR2
if ![info exists BG_COLOR1] {set BG_COLOR1 "#FCD98E"}
if ![info exists BG_COLOR2] {set BG_COLOR2 "#F6C19E"}

proc MenuBar {menubar} {

    global BG_COLOR2
    if [winfo exists $menubar] {destroy $menubar}
    menu $menubar -tearoff 0 -bg $BG_COLOR2
    return $menubar
}

proc Menu {menubar menu} {

    global BG_COLOR1
    set menuname $menubar.[label-to-name $menu]
    $menubar add cascade -menu $menuname -label $menu -underline 0
    menu $menuname -tearoff 0 -bg $BG_COLOR1
    return $menuname
}

proc MenuAtPos {menubar menu pos} {
  set menuname $menubar.[label-to-name $menu]
  $menubar insert $pos cascade -menu $menuname -label $menu -underline 0
  menu $menuname -tearoff 0
}

proc MenuItem {menubar menu label cmd {Key {}}} {
    set menuname $menubar.[label-to-name $menu]

    # Delete the item if it exists
    set menuitem [MenuFindItem $menuname $label]
    if { $menuitem != {} } {
	$menuname delete $menuitem
    }

   $menuname add command -label $label -command $cmd\
            -underline 0
    if { $Key != {} } {
	$menuname entryconfigure last -accelerator $Key
	bind all <$Key> $cmd
    }
}



proc MenuCheck { menubar menu label var { command  {} } } {

   set menuname $menubar.[label-to-name $menu]
   $menuname add check -label $label -command $command \
	-variable $var
}


proc MenuSeparator {menubar menu} {
   set menuname $menubar.[label-to-name $menu]
   $menuname add separator
}


proc SubMenu { menubar menu label submenu} {
  # creates a cascading menu entry. If submenu already exists, then wipes it
   set menuname $menubar.[label-to-name $menu]
   if [winfo exists $submenu] {destroy $submenu}
   menu $submenu -tearoff 0
  $menuname add cascade -label $label -menu $submenu
}

proc SubMenuAdd {submenu label cmd} {
  $submenu add command -label $label -command $cmd
}

# example
proc example1 {} {
  MenuBar .menuBar
  Menu .menuBar Test
  MenuItem .menuBar Test "Print 1" {puts 1}
  SubMenu .menuBar Test "Actions" .submenu
  SubMenuAdd .submenu "Print A" {puts a}
}


proc label-to-name {Label} {
   regsub -all  {\ } $Label _ Label
  return [string tolower $Label]
}



proc MenuItemEnable {menubar menu label} {
    
    if ![winfo exists $menubar] {return 0}
    set menuname $menubar.[label-to-name $menu]
    set menuitem [MenuFindItem $menuname $label]
    $menuname entryconfigure $menuitem -state normal
}


proc MenuItemDisable {menubar menu label} {
    if ![winfo exists $menubar] {return 0}
    set menuname $menubar.[label-to-name $menu]
    set menuitem [MenuFindItem $menuname $label]
    $menuname entryconfigure $menuitem -state disabled
}

proc MenuItemExists {menubar menu label} {
    if ![winfo exists $menubar] {return 0}
    set menuname $menubar.[label-to-name $menu]
    if { [MenuFindItem $menuname $label] == {}} {
	return 0
    }
    return 1
}



proc MenuFindItem {menu label} {
    set lastitem [$menu index end]
    if { $lastitem == "none"} {return {}}
    set item 0
    while { $item <= $lastitem } {
	if ![catch "$menu entryconfigure $item -label" label1] {
	    if { [lindex $label1 4] == $label } {
		return $item
	    }
	}
	incr item
    }
    return {}
}