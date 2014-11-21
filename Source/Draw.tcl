######################################
## RSTTool 3.x
#
#  File: Draw.tcl
#  Author: Mick O'Donnell micko@wagsoft.com
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute  this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms, a copy of which may be viewed at:
#  http://www.wagsoft.com/RSTTool/copyright.html
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.


###########################################
# DRAW
# Functions used by RST-Tool for drawing arcs rst-nodes and
# relation-arcs between them


# local globals: visible_nodes

####################################################
# Draw the RST Tree

proc show-rst {} {
# go through each text and seq node and display it.
    global NODE GROUP_NODES TEXT_NODES RSTW
    
    foreach nid [concat $GROUP_NODES $TEXT_NODES] {
	     debug "show-rst: $nid"
	     if $NODE($nid,visible) {
		 display-node $nid
	     }
   }
}

 
proc clear-drawing {} {
    global RSTW  WTN CURRENT_SAT
    $RSTW delete all
    if [info exists WTN] {unset WTN}
    set CURRENT_SAT {}
}


proc display-node {nid} {
  global NODE RSTW NODE_WIDTH GROUP_NODES WTN COLOR TEXT_FONT ACTUAL_FONT_SIZE
#  puts "display-node: $nid"
  set xpos $NODE($nid,xpos)
  set ypos [expr $NODE($nid,ypos) + 2]

  if [member $nid $GROUP_NODES] {
      set color $COLOR(span)
      set text [make-span-label $NODE($nid,span)]
  } else {
      set color $COLOR(text)
      set text $NODE($nid,text)
  }

  # If no font set yet, record the default
  if ![info exists TEXT_FONT] {

      set wgt [draw-text $RSTW $text $xpos $ypos\
                       "-width $NODE_WIDTH -fill $color"]
      set font [$RSTW itemcget $wgt -font]
      set afont [font actual $font]
      set TEXT_FONT [eval [concat "font create default" $afont]]
      set ACTUAL_FONT_SIZE [font actual $TEXT_FONT -size]
  } else {
      set wgt [draw-text $RSTW $text $xpos $ypos\
                       "-width $NODE_WIDTH -fill $color -font $TEXT_FONT"]
  }
  set NODE($nid,textwgt) $wgt

  set NODE($nid,boxwgt) {}
  $RSTW bind $wgt <Enter> "enter-widget $wgt"
  $RSTW bind $wgt <Leave> "leave-widget $wgt"

  set WTN($wgt) $nid
  display-span $nid
  display-arc $nid

  if { $NODE($nid,collapsed_under) == 1} {
      display-collapsed $nid
  }
}



proc display-span {nid} {
  global RSTW NODE  HALF_NODE_WIDTH  
  debug "display-span: $nid $NODE($nid,span)"
  # draw span line, from start of first node, to end of second
  set span $NODE($nid,span)
  set ypos $NODE($nid,ypos)

    # find the left+rightmost visible nodes
    set leftmost [leftmost-visible $nid]
    set rightmost [rightmost-visible $nid]

  # draw the span-line
  set NODE($nid,spanwgt) [draw-line $RSTW\
        [expr $NODE($leftmost,xpos) - $HALF_NODE_WIDTH] $ypos\
        [expr $NODE($rightmost,xpos) + $HALF_NODE_WIDTH] $ypos]
 }


proc display-arc {sat} {
  global RSTW NODE TEXT_NODES COLOR TEXT_FONT YINCR ACTUAL_FONT_SIZE
  set nuc $NODE($sat,parent)
  if {$nuc == {}} {return}

  
  set wgt [ntw $nuc]
  
  # set some variables
  set ypos $NODE($sat,ypos)
  set reltype [relation-type $NODE($sat,relname)]
  set color $COLOR(relation)
  set satpnt "$NODE($sat,xpos) $NODE($sat,ypos)"
  
  set nucbot [bottom-point $wgt ]

  set label $NODE($sat,relname)
  set yshift [expr $ACTUAL_FONT_SIZE + ($ACTUAL_FONT_SIZE / 2)]
# puts "YSHIFT: $yshift ACTUAL_FONT_SIZE: $ACTUAL_FONT_SIZE / [font actual $TEXT_FONT -size]"
  switch -- $reltype {
      schema  { 
	  set NODE($sat,arrowwgt) \
		  [$RSTW create line [lindex $nucbot 0] [lindex $nucbot 1]\
		  [lindex $satpnt 0] [lindex $nucbot 1]\
		  [lindex $satpnt 0] [lindex $satpnt 1]]
	  set labelx [car $satpnt]
	  set labely [expr [second $satpnt] - $yshift]
	  set labelpnt [list $labelx $labely]
      }
      multinuc { 
	  set NODE($sat,arrowwgt)\
		  [draw-line-between $RSTW $nucbot $satpnt]
	  set labelx [car $nucbot]
	  set labely [expr [second  $satpnt] - $yshift]
	  set labelpnt [list $labelx $labely]
      }
      span {
	  set NODE($sat,arrowwgt)\
		  [draw-line-between $RSTW $nucbot $satpnt]
      }
      rst {  #draw an rst linker (an arc from nuctop to sattop)
	  set nucpnt [add-points [$RSTW coords [ntw $nuc]] {0 -2}]
	  set midpnt [subtract-points [mid-point $nucpnt $satpnt] "0 20"] 
	  set labelx [car $midpnt]
	  set labely [expr [second $midpnt] -  $yshift + 6]
	  set labelpnt [list $labelx $labely]
#	  set labelpnt [subtract-points $midpnt {0 6}]
	  # If this satelite is the second to the left, 
	  # then move it a bit more to the left
	  # (todo)  -- same to the right


	  set NODE($sat,arrowwgt)\
		  [draw-arc $RSTW [concat $nucpnt $midpnt $satpnt]]
      }
      default { 
	  tell-user "No reltype: $reltype for $sat $NODE($sat,relname)" 
      }
  }
  # Draw the Label
  if { $reltype != "span" } {
      set NODE($sat,labelwgt) [draw-text $RSTW $label $labelpnt\
	      "-fill $color -tag $reltype -font $TEXT_FONT"]
      $RSTW bind $NODE($sat,labelwgt) <ButtonRelease-1> "change-structure change-rel-label $sat"
  }
}

proc display-collapsed {nid} {
   global RSTW NODE 

    set wgt $NODE($nid,textwgt)
    set bbox [$RSTW bbox $wgt]
    set x1 [lindex $bbox 0]
    set x2 [lindex $bbox 2]
    set y2 [lindex $bbox 3]  
    set midx [expr $x1 + ($x2  - $x1) / 2]
    set x1 [expr $midx - 30]
    set x2 [expr $midx + 30]
    set lowy [expr $y2 + 20]
    set NODE($nid,collwgt) [$RSTW create line $midx $y2 $x1 $lowy $x2 $lowy $midx $y2]
}



proc erase-subtree {nid} {
  global NODE
  if $NODE($nid,visible) {
    erase-node $nid
    foreach cid $NODE($nid,children) {
      erase-subtree $cid
    }
  }
}
  
proc erase-node {nid} {
  global RSTW NODE
  debug "erase-node: $nid $NODE($nid,spanwgt)"
  if $NODE($nid,visible) {
    $RSTW delete [ntw $nid]
    $RSTW delete $NODE($nid,spanwgt)
    if { $NODE($nid,boxwgt) != {} } {
	$RSTW delete $NODE($nid,boxwgt)
	set NODE($nid,boxwgt) {}
    }
    if { $NODE($nid,collwgt) != {} } {
	$RSTW delete $NODE($nid,collwgt)
	set NODE($nid,collwgt) {}
    }
    set WTN([ntw $nid]) {}
    set NODE($nid,textwgt) {}
    set NODE($nid,spanwgt) {}
    erase-arc $nid
  }
}

proc erase-arc {nid} {
  global RSTW NODE
  debug "erase-arc: $nid"
  if { $NODE($nid,arrowwgt) != {} } {
      $RSTW delete $NODE($nid,arrowwgt)
      $RSTW delete $NODE($nid,labelwgt)
      set NODE($nid,arrowwgt) {}
      set NODE($nid,labelwgt) {}
  }
}

proc redraw-subtree {nid} {
  global NODE
    debug "redraw-subtree: $nid"
  erase-node $nid
  display-node $nid
  foreach cid $NODE($nid,children) {
    if $NODE($cid,visible) {
      redraw-subtree $cid
    }
  }
}

proc redisplay-node {nid} {
# wipes the old version before drawing
  global NODE
    debug "redisplay-node: $nid"
   if { $NODE($nid,textwgt) != {} } {
         erase-node $nid
   }
      
    display-node $nid
}

proc redraw-child-arcs {nid} {
# redraws the child-arcs pointing at this node
  global NODE 
  debug "redraw-child-arcs: $nid"
  foreach cid $NODE($nid,children) {
    if $NODE($cid,visible) {
     erase-arc $cid
     display-arc $cid
    }
  }
}


