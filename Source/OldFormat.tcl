######################################
## RSTTool
#
#  File: File1.tcl
#  Author: Mick O'Donnell micko@dai.ed.ac.uk
#
#  Copyright: the author grants you a limited, nonexclusive, royalty-free 
#  right to reproduce and distribute  this file; provided, however, that 
#  use of such software shall be subject to the terms and conditions of 
#  the RSTTool License Terms, a copy of which may be viewed at:
#  http://www.dai.ed.ac.uk/staff/personal_pages/micko/RSTTool/copyright.html
#  This notice must not be removed from the software, and in the event
#  that the software is divided, it should be attached to every part.

######################################
# OLD (RST1) format load and save

proc save-rst1 {file {save_rels_p {}}} {
  global NODE TEXT_NODES GROUP_NODES RELATIONSMASTER

  # Now save the file
   set f [open $file w 0600]

  # save the relations if desired
    
  if { $RELATIONSMASTER == {} } {
    puts $f "start_relations"
    save-relations $f
    puts $f "end_relations"
  } else {
      save-relations [open $RELATIONSMASTER w 0600]
  }

  foreach itm [concat $TEXT_NODES $GROUP_NODES] {
     puts $f $itm
     if [group-node-p $itm] {
        puts $f $NODE($itm,type)
     } else {
        puts $f $NODE($itm,text)
    }
     puts $f $NODE($itm,parent)
     puts $f $NODE($itm,relname)
   }
   close $f
}


###########################
## READ IN OLD FORMAT

proc load-rst1  {file} {
    global NODE TEXT_NODES GROUP_NODES LAST_NODE_ID RELATIONS UNKNOWN_RELS

    set f [open $file r]
    while {[gets $f id] >= 0} {
	clear-node $id
	gets $f text
	gets $f NODE($id,parent)
	gets $f relname
	set NODE($id,relname) [capitalise $relname]

	if { $NODE($id,relname) != {}
	&& [relation-type $NODE($id,relname) ] == 0 } {
	    
	    puts "Load-RST: Unknown relation: $NODE($id,relname) - defaulting."
	    lappend RELATIONS(rst) $NODE($id,relname)
	    lappend UNKNOWN_RELS $NODE($id,relname)
	}

	if { [member $text {span multinuc constit schema}] } {
	    lappend GROUP_NODES $id
	    if { $text == "constit"} {set text schema}
	    set NODE($id,type) $text
	} else {
	    lappend TEXT_NODES $id
	    set NODE($id,text) [string trim $text]
	    regsub -all "\n" $NODE($id,text) " " NODE($id,text)
	    regsub -all "  " $NODE($id,text) " " NODE($id,text)
	    puts "RETURNS removed: $NODE($id,text)"
	    set NODE($id,type) "text"
	    set NODE($id,span) "$id $id"
	    .segment.editor.text insert end  $text
	    new-segment end $id
	}
    }
    close $f


}

    
