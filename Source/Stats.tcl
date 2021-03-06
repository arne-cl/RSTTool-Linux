#########################################
# Stats.tcl


proc make-stats-frame {} {
    global STATS_FILTER STATS_LABEL
    if [winfo exists .stats] {destroy .stats}
    frame .stats
    
    make-stats-tbar
    pack .stats.tbar -side top  -anchor nw -padx 0.5c
    
    ##################
    ## The CONTENT Frame
    frame .stats.main

    label  .stats.main.label -font "Courier 12" -textvariable STATS_LABEL
    label  .stats.main.label2 -font "Courier 12" -textvariable STATS_LABEL2
    pack .stats.main.label -side top -anchor nw

    scrolled-listbox .stats.main.table -bg white -relief sunken -font "Courier 12"

    #    bind  .stats.main.table.choices <ButtonRelease> {stats-set-current %x %y}
    pack .stats.main.table -side top -expand 1 -fill both
    pack .stats.main -expand 1 -fill both -pady 0.2c -padx 0.5c
    
    return .stats
}

proc make-stats-tbar {} {
    global COLOR

    # Define a toolbar
    if {[winfo exists .stats.tbar]} {destroy .stats.tbar}
    
    frame .stats.tbar -relief sunken 
    
    frame .stats.tbar.controls
    button  .stats.tbar.controls.apply -text "Show Results" -command {stats-do-study} -height 1\
	    -bg $COLOR(buttons)
    button  .stats.tbar.controls.save -text "Save Results" -command {stats-save-study} -height 1\
	    -bg $COLOR(buttons)
    pack .stats.tbar.controls.apply .stats.tbar.controls.save -side top -padx 20    
    pack  .stats.tbar.controls -side right -expand 1 -fill y
    
    frame .stats.tbar.type
    label .stats.tbar.type.label -text "Type:"
    tk_optionMenu .stats.tbar.type.choice STATS_OP "Descriptive" 
    # "Comparative"    
    #    .stats.tbar.type.choice.menu entryconfigure 0 -command {stats-hide-syschoose}
    #    .stats.tbar.type.choice.menu entryconfigure 1 -command {stats-show-syschoose}
    help-button .stats.tbar.type.help stats_type
    pack  .stats.tbar.type.label .stats.tbar.type.choice .stats.tbar.type.help -side left
    
    frame .stats.tbar.filter
    label .stats.tbar.filter.label -text "Include:"
    tk_optionMenu .stats.tbar.filter.choice STATS_FILTER  "RST Only" "RST+Schemas"    
    help-button .stats.tbar.filter.help stats_filter
    defhelp stats_filter "STATS FILTERING

In counting relations, use 'RST Only' if you want to exclude the Schema links,
and select 'RST+Schemas' if you want Schema links included. Links to Spans are not counted in either case."
    pack  .stats.tbar.filter.label .stats.tbar.filter.choice .stats.tbar.filter.help -side left


    frame .stats.tbar.mncount
    label .stats.tbar.mncount.label -text "Count Multinuclear Nodes:"
    tk_optionMenu .stats.tbar.mncount.choice STATS_MNCOUNT  "Once Only" "Once for each member"    
    help-button .stats.tbar.mncount.help stats_mncount
    defhelp stats_mncount "STATS: Counting mulinuclear relations

In counting multinuclear relations, use 'Once Only' if you want multinuclear nodes to
count once only, regardless of the number of elements joined. Select 'Once for each member' if you desire to count one for each member of the structure."
    pack  .stats.tbar.mncount.label .stats.tbar.mncount.choice .stats.tbar.mncount.help -side left
    pack .stats.tbar.type  .stats.tbar.filter   .stats.tbar.mncount -side top -expand 1 -fill x -padx 0.5


}

proc clear-stats {} {
    .stats.main.table.choices delete 0 end
}

proc stats-do-study {} {
   global STATS_OP TEXT_NODES GROUP_NODES
    clear-stats
    switch -- $STATS_OP {
	"Descriptive" {descriptive-stats [concat $TEXT_NODES $GROUP_NODES]}
	"Comparative" {comparative-stats $TEXT_NODES $GROUP_NODES}
    }
}

proc stats-save-study {} {
    global STATS_OP STATS_FILTER STATS_LABEL
    # ensure the display is up to date.
    set file [tk_getSaveFile -title "Save Results as"\
         -initialfile [default-file .stats]]
    if { $file == {} } { return }
    stats-do-study

    set str [open $file w]
    switch -- $STATS_OP {
	"Descriptive" {
	    puts $str "Descriptive Statistics for file: [default-file]."
	    puts $str "Date: [clock format [clock seconds] -format %c]"
	    puts $str "Filter: $STATS_FILTER"
	    puts $str "[.stats.main.table.choices get 0]"
	    puts $str "---------------------------------------"
	    puts $str "$STATS_LABEL"
	    puts $str "---------------------------------------"
	    foreach line [.stats.main.table.choices get 1 end] {
		puts $str $line
	    }
	    close $str
	}
   	"Comparative" {
	    puts $str "Comparative Statistics for files: [default-file] and $COMPARE_FILE."
	    puts $str "Date: [clock -format "%c"]"
	    puts $str "Filter: $STATS_FILTER"
	    puts $str "---------------------------------------"
	    puts $str "[.stats.main.table.choices get 1.0 end]"
	    close $str
	}
    }
}

proc stats-hide-syschoose {} {
    # DESTROY THE SYSTEM CHOOSER (COMPSTATS) IF EXISTS
    if {[winfo exists .stats.tbar.system]} {
	pack forget .stats.main.label2
	destroy .stats.tbar.system 
    }
}

proc stats-show-syschoose {} {
    
    pack  .stats.main.label2 -before .stats.main.label -anchor w
    # make the system chooser
    # destroy any old version
    if {[winfo exists .stats.tbar.system]} {
	destroy .stats.tbar.system
    }

    # for comparative only
    frame .stats.tbar.system
    label .stats.tbar.system.label -text "System to split on:"
    eval [concat "tk_optionMenu .stats.tbar.system.choice STATS_SYSTEM" [all-systems-sorted]]
    help-button .stats.tbar.system.help stats_system
    defhelp stats_system "See manual"

    pack .stats.tbar.system.label -side left
    pack .stats.tbar.system.choice -side left -expand 1 -fill x
    pack .stats.tbar.system.help -side left

    pack .stats.tbar.system -after .stats.tbar.filter.help -in .stats.tbar.filter  -side left -padx 1c
}

proc descriptive-stats {nodes} {
    global STATS_LABEL STATS_FILTER NODE STATS_MNCOUNT
 
    set tcount 0

    # Keep track of visited multinuc nodes
    set seen_multinucs {}

    set RELS {}

    # Calculate distribution
    foreach node $nodes {
	 set rel $NODE($node,relname)
	if { $rel == "" } {set rel top}

	switch -- [relation-type $rel] {
	    span {continue}
	    rst { 
		# Count nuc-sat vs sat-nuc
		if ![info exists ordering($rel,sat_nuc)] {set ordering($rel,sat_nuc) 0}
		if ![info exists ordering($rel,nuc_sat)] {set ordering($rel,nuc_sat) 0}
		if [sat-before-nuc $node] {
		    incr ordering($rel,sat_nuc)
		} else {
		    incr ordering($rel,nuc_sat)
		}
	    }
	    multinuc {
		if { $STATS_MNCOUNT == "Once Only"} {
		    if [member $NODE($node,parent) $seen_multinucs] {
			continue
		    } else {
			lappend seen_multinucs $NODE($node,parent)
		    }
		}   
	    }
	    default { 
		if { $STATS_FILTER == "RST Only" } {
		    continue
		}   
	    }
	}

	if ![member $rel $RELS] {lappend RELS $rel}
	
	incr tcount
	if [info exists count($rel)] {
	    incr count($rel)
	} else {
	    set count($rel) 1
	}
	
    }

   # set the label
    set STATS_LABEL [format " %-20s  %7s  %7s     %7s" Relation N Mean  S^N:N^S]
    set form " %-20s  %7i %7s  %7s"

    # print results
    .stats.main.table.choices insert end "Total Relations: $tcount ($STATS_FILTER, Counting Multinucs: $STATS_MNCOUNT)"
    foreach rel [lsort $RELS] {

	if {[string length $rel] > 20} {
	    set relstr [string range $rel 0 19]
	} else { 
	    set relstr $rel
	}
	set mean [expr 100.00 * ($count($rel) + 0.00) / $tcount]
	set mean [format "%7.1f%%" $mean]

	if [info exists ordering($rel,nuc_sat)] {
	    set sn_ns "$ordering($rel,sat_nuc):$ordering($rel,nuc_sat)"
	} else {
	    set sn_ns ""
	}
	.stats.main.table.choices insert end [format $form $relstr $count($rel) $mean $sn_ns]
    }    
    .stats.main.table.choices insert end "---------------------------------------"

}


proc count-occurences {feature nodes} {
    global NODE 
    set count 0
    foreach node $nodes {
	if [member $feature $NODE($node,features)] {incr count}
    }
    return $count
}


proc count-sys-occurences {system nodes} {
    global NODE SYSTEM
    set count 0
    set features $SYSTEM($system,features)
    foreach node $nodes {
	if [intersect-p $features $NODE($node,features)] {incr count}
    }
    return $count
}




    

defhelp stats_type "STASTICAL ANALYSIS TYPES

You can obtain two statistcal views of your codings:

  - Descriptive Statistics: provides the means, standard deviation, etc.
    for  each feature;
  - Comparative Statistics: you divide the codings into two or more subsets,
    which are then contrasted."
