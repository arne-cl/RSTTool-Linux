global RST_FILE TEXT_FILE

set RST_FILE {}


global NODE TEXT_NODES GROUP_NODES WTN LAST_NODE_ID RSTW
global maxlen  NODE_WIDTH HALF_NODE_WIDTH  Y_TOP YINCR\
       currentsat RELATIONS DEBUG SHIFTCLICKED ORIENTATION

set DEBUG 0
set maxlen 20
set NODE_WIDTH 100
set HALF_NODE_WIDTH [expr $NODE_WIDTH / 2]
set Y_TOP 30
set YINCR 30
set SHIFTCLICKED -1
set ORIENTATION horizontal

global TEXT_FONT_SIZE TEXT_LINES TINY_FONT  TEXT_FONT PLATFORM
set TEXT_FONT_SIZE 12 ; # size of text in text window

switch -- $PLATFORM {
  unix    {set TINY_FONT "-Adobe-Times-Plain-R-Normal--10-100-*-*-*-*-*-*"}
  default {set TINY_FONT "-Adobe-Times-Plain-R-Normal--7-70-*-*-*-*-*-*"}
}

global BUTTON_FONT BUTTON_FONT_BOLD

set BUTTON_FONT [font create -family "Arial" -size 12 -weight normal]
set BUTTON_FONT_BOLD [font create -family "Arial" -size 12 -weight bold]