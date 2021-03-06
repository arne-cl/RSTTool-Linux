

# Allow SSA layout

proc layout-ssa {} {
    global TEXT_NODES GROUP_NODES RSTW NODE MAXX ACTUAL_FONT_SIZE

    set halfwidth [expr ($ACTUAL_FONT_SIZE / 2) + 2]

    # Clear the display
    $RSTW delete all

    # Place the text nodes on the right hand side of the screen
    draw-textnodes

    # set the MAXX to 0
    set MAXX 0

    # Starting with each Nucleus, layout/draw the subtrees
    foreach nid $GROUP_NODES {
	if { $NODE($nid,parent) == {} } {
	    ssa-layout-tree $nid 10
	}
    }

    # Move textnodes to the correct position
    foreach nid $TEXT_NODES {
	puts "MOVING $nid/$NODE($nid,textwgt) $MAXX"
	$RSTW move $NODE($nid,textwgt) $MAXX 0
	set NODE($nid,x) $MAXX
	set NODE($nid,xend) [expr $NODE($nid,x) + $NODE($nid,width)]
	set NODE($nid,yend) [expr $NODE($nid,y) + $NODE($nid,height)]
    }

    # Draw Horizontal lines
    foreach nid [concat $TEXT_NODES $GROUP_NODES] {
	set parent $NODE($nid,parent)
	if { $parent != {} } {

	    # if a Text Node, draw line from label to text
	    if [text-node-p $nid] {
		# Find the labels endpoint
		set bbox [$RSTW bbox $NODE($nid,labelwgt)]
		set x1 [expr [lindex $bbox 2] + 3]
		set x2 [expr $NODE($nid,x) - 3]
		set y [expr $NODE($nid,y) + $halfwidth]
		draw-line $RSTW $x1 $y $x2 $y
	    }
	}
    }

    # Draw vertical lines 
    # Foreach node, find children nodes, and take the ymin and ymax


    foreach nid [concat $GROUP_NODES $TEXT_NODES] {
	set type $NODE($nid,type)
	puts "Type: $type"
	switch -- $type {

	    text -
	    span {
		set bbox [$RSTW bbox $NODE($nid,labelwgt)]
		set x  [expr [lindex $bbox 2] + 3]
		
		# Link each child to the vertical bar
		foreach cid $NODE($nid,children) {
		    set y1 [expr [lindex $bbox 1] + $halfwidth]
		    set bbox [$RSTW bbox $NODE($cid,labelwgt)]
		    set x2 [expr [lindex $bbox 0] - 3]
		    set y2 [expr [lindex $bbox 1] + $halfwidth]
		    draw-line $RSTW $x $y1 $x2 $y2
		}
	    }
	    schema -
	    multinuc {
		set bbox [$RSTW bbox $NODE($nid,labelwgt)]
		set x  [expr [lindex $bbox 2] + 3]
		
		# Link each child to the vertical bar
		foreach cid $NODE($nid,children) {
		    if  { [relation-type $NODE($cid,relname)] == $type } {
			set y [expr $NODE($cid,y) + $halfwidth]
			set x2 [expr [lindex [$RSTW bbox $NODE($cid,labelwgt)] 0] - 3]
			draw-line $RSTW $x $y $x2 $y
		    } else {
			set y1 [expr [lindex $bbox 1] + $halfwidth]
			set bbox [$RSTW bbox $NODE($cid,labelwgt)]
			set x2 [expr [lindex $bbox 0] - 3]
			set y2 [expr [lindex $bbox 1] + $halfwidth]
			draw-line $RSTW $x $y1 $x2 $y2
		    }
		}

		set min 9999
		set max 0
		foreach cid $NODE($nid,children) {
		    if  { [relation-type $NODE($cid,relname)] == $type } {
			set min [min $min $NODE($cid,y)]
			set max [max $max $NODE($cid,y)]
		    }
		}
		
		if { $min != $max } {
		    incr min $halfwidth
		    set max [expr $max + $halfwidth]
		    
		    
		    draw-line $RSTW $x $min $x $max
		}
	    }
	}
    }

    # Constrain the scrollbars
    constrain-scrollbars

    update
}

proc tmp {} {
    # For all nodes, draw a line from label to parent
    # For now, triang arc for rst rels
    
    if { [relation-type $NODE($nid,relname)] == "rst"} {
	set y2 [expr [lindex $bbox 0] + $halfwidth]
	draw-line $RSTW $x1 $y1 $x2 $y2
    } else {
	draw-line $RSTW $x1 $y1 $x2 $y2
    }
    set x2 [expr [lindex $bbox 0] -3]
    set y1 [expr $NODE($nid,y) + $halfwidth]
    set y2 $y1
    set x2 [expr $NODE($nid,x) - 3]
    
    
    
    # Label to parent	    
    set bbox [$RSTW bbox $NODE($nid,labelwgt)]
    set x1  [expr [lindex $bbox 2] + 3]
    
    if { [relation-type $NODE($nid,relname)] == "rst"} {
	set y2 [expr [lindex $bbox 0] + $halfwidth]
	draw-line $RSTW $x1 $y1 $x2 $y2
    } else {
	draw-line $RSTW $x1 $y1 $x2 $y2
    }
}



proc ssa-layout-tree {nid xoffset} {
    global TEXT_NODES GROUP_NODES RSTW NODE COLOR TEXT_FONT MAXX
    puts "ssa-layout-tree: $nid $xoffset"
    # The ypos is the ypos of its chief nucleus
    set cid [find-bottom-nuc $nid]
    set ypos $NODE($cid,y)

    # If this is a dependent, draw the relation:
    if { $NODE($nid,parent) != {} } {
	set text $NODE($nid,relname)
	set color $COLOR(relation)
    } else {
	
	# Draw the span label
	set text [make-span-label $NODE($nid,span)]
	set color $COLOR(span)
    }

    # Draw it
    set NODE($nid,labelwgt) [draw-text-left $RSTW $text $xoffset $ypos\
	    "-fill $color -font $TEXT_FONT"]
    
    set width [widget-width $RSTW $NODE($nid,labelwgt)]
    if [group-node-p $nid] {
	set NODE($nid,x) $xoffset
	set NODE($nid,y) $ypos
	set NODE($nid,height) [widget-height $RSTW $NODE($nid,labelwgt)]
	set NODE($nid,width) $width
    }
	

    # Maintain a record of the maximum rightward reach
    incr xoffset  [expr $width + 10]
    set MAXX [max $MAXX $xoffset]

    # Draw each of the children
    foreach cid $NODE($nid,children) {
	puts "  Child: $cid $NODE($cid,type)"
	ssa-layout-tree $cid $xoffset
    }
}
    

proc draw-textnodes {} {
    global TEXT_NODES RSTW NODE TEXT_FONT
    # 1. Place the text nodes on the right hand side of the screen
    set xpos 0
    set ypos 10
    set yinc 8
    set xwidth 350
    set color black
    foreach nid $TEXT_NODES {
	set NODE($nid,x) $xpos
	set NODE($nid,y) $ypos
	set NODE($nid,textwgt) [draw-text-left $RSTW $NODE($nid,text) $xpos $ypos\
                       "-width $xwidth -fill $color -font $TEXT_FONT"]

	
	set NODE($nid,height) [widget-height $RSTW $NODE($nid,textwgt)]
	set NODE($nid,width) [widget-width $RSTW $NODE($nid,textwgt)]
	set NODE($nid,xend) [expr $NODE($nid,x) + $NODE($nid,width)]
	set NODE($nid,yend) [expr $NODE($nid,y) + $NODE($nid,height)]
	set ypos [expr $ypos +  $NODE($nid,height)+ $yinc]
    }
}
