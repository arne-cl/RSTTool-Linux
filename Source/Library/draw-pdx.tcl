# Proceedures to save a canvas as a pdx file.


proc canvas-to-pdx {canvas {coloredp 1}} {
    global PDX_YMAX PDX_YMIN
    load-pdx-font-mappings
    set PDX_YMIN 0
    set file [tk_getSaveFile -title "Save PDX file to"\
	    -initialfile [default-file ".pdx"]]
    if { $file == {} } {return}
    set str [open "$file" w]
    set wgts [$canvas find all]
    pdx-insert-header $str

    # Find the screen height
    set PDX_YMAX 0
     foreach wgt $wgts {
	 set PDX_YMAX [max $PDX_YMAX [lindex [$canvas bbox $wgt] 1]]
     }
     incr PDX_YMAX 50
	 
    foreach wgt $wgts {
	pdx-convert-wgt $wgt $canvas $str $coloredp
    }
    pdx-insert-trailer $str
    close $str
}


proc region-to-pdx {canvas region {coloredp 1}} {
    global PDX_YMAX PDX_XMIN PDX_YMIN
    load-pdx-font-mappings
    set x1 [lindex $region 0]
    set y1 [lindex $region 1]
    set x2 [lindex $region 2]
    set y2 [lindex $region 3]

    incr y1 -3
    incr x2 3
    incr y2 3
    set PDX_YMAX $y2
    set PDX_YMIN $y1
    set PDX_XMIN $x1 

    
    set file [tk_getSaveFile -title "Save PDX file to"\
	    -initialfile [default-file ".pdx"]]
    if { $file == {} } {return}
    set str [open "$file" w]
    
    set wgts [$canvas find enclosed $x1 $y1 $x2 $y2]


    pdx-insert-header $str
	 
    foreach wgt $wgts {
	pdx-convert-wgt $wgt $canvas $str $coloredp
    }
    pdx-insert-trailer $str
    close $str
}

proc pdx-font-family {font} {
    global PDX_FONT_MAP PDX_FONT_DEFAULT
    foreach item $PDX_FONT_MAP {
	if { $font == [car $item] } {
	    return [second $item]
	}
    }
    return $PDX_FONT_DEFAULT
}

proc pdx-convert-wgt {wgt canvas str coloredp} {
    set coords [$canvas coords $wgt]

    
    # Set the item color
    if { $coloredp == 1 } {
	set color [$canvas itemcget $wgt -fill]
    } else {
	set color "black"
    }
    set colornums [get-pdx-color $color]
    puts $str "$colornums k\n"

    
    switch -- [$canvas type $wgt] {
	text {
	    set txt [$canvas itemcget $wgt -text]

	    set font [$canvas itemcget $wgt -font]
	    puts "$font"
	    switch -- [llength $font] {
		1 {

		    if { [string index $font 0] == "-"} {		
			# this is an xfont name
			# -Adobe-Times-12
			regsub -all -- "-" $font " " font
			set family  [lindex $font 1]
			set size [lindex $font 2]
		    } else {
			set family [font config $font -family]
			set size [font config $font -size]
		    }
		}
		default {
		    # Normal
		    set family  [lindex $font 0]
		    set size [lindex $font 1]
		}
	    }
	    if ![integer-p $size] {set size 12}
	    set pdxfamily [pdx-font-family $family]
	    set bbox [$canvas bbox $wgt]
	    set width [expr [lindex $bbox 2] - [lindex $bbox 0]]
	    set halfwidth [expr $width / 2]
	    set x [expr [lindex $coords 0] - $halfwidth + 2] 
	    set y [expr [lindex $coords 1] - ( $size / 2) + 3]	

	    set lines [find-textwidget-lines $canvas $wgt]
	    foreach line $lines {
		pdx-draw-text $line $x $y $pdxfamily $size $width $str
		set y [expr $y + $size + 3]
	    }
	}
	line {
	    if { [llength $coords] > 4 } {
		set x1 [lindex $coords 0]
		set y1 [lindex $coords 1]
		set x2 [lindex $coords 2]
		set y2 [lindex $coords 3]
		set x3 [lindex $coords 4]
		set y3 [lindex $coords 5]
		
		switch -- [$canvas gettags $wgt] {
		    line {
			
			# draw the arrow head
			set yd 10
			if { $x1 > $x3 } {
			    # arrow to the left
			    set x1 [expr $x1 - 2]
			    pdx-draw-line $x1 $y1 [expr $x1 - 8] [expr $y1 - 2] $str
			    pdx-draw-line $x1 $y1 [expr $x1 - 6] [expr $y1 - 5.6] $str
			} else {
			    # Arr ow to right
			    set x1 [expr $x1 + 2]
			    pdx-draw-line $x1 $y1 [expr $x1 + 8] [expr $y1 - 2] $str
			    pdx-draw-line $x1 $y1 [expr $x1 + 6] [expr $y1 - 5.6] $str
			}
			
			# An arc arrow
			set height [expr $y2 - $y3 ]
			pdx-draw-arc $x1 $y1 $x3 $y3 $height $str
		    }
		    default {
			set x1 [pop coords]
			set y1 [pop coords]
			while { $coords != {} } {
			    set x2  [pop coords]
			    set y2 [pop coords]
			    pdx-draw-line $x1 $y1 $x2 $y2 $str
			    set x1 $x2
			    set y1 $y2
			}
		    }
		}
	    } else {
		pdx-draw-line [lindex $coords 0] [lindex $coords 1]\
			[lindex $coords 2] [lindex $coords 3] $str
	    }
	}
	arc { puts "Arc $wgt: $bbox"}
	
	default {
	    puts "Type: [$canvas type $wgt] not catered to"
	}
    }

}

proc pdx-draw-line {x1 y1 x2 y2 str} {
    global PDX_YMAX PDX_XMIN PDX_YMIN

    # Move drawing region to 0,0
    if  [info exists PDX_YMIN] {
	set y1 [expr $y1 - $PDX_YMIN]
	set y2 [expr $y2 - $PDX_YMIN]
    }

    if  [info exists PDX_XMIN] {
	set x1 [expr $x1 - $PDX_XMIN]
	set x2 [expr $x2 - $PDX_XMIN]
    }


    # Adjust for the fact that PDX has 0,0 at bottom, tcl/tk at top
    if [info exists PDX_YMAX] {
	set y1 [expr $PDX_YMAX - $PDX_YMIN - $y1]
	set y2 [expr $PDX_YMAX - $PDX_YMIN - $y2]
    }



    puts $str "q
1 0 0 1 0 0 cm
$x1 $y1 m
$x2 $y2 L
Q
S"
}

proc pdx-draw-arc {x1 y1 x2 y2 height str} {
    global PDX_YMAX PDX_XMIN PDX_YMIN

 # Move drawing region to 0,0
    if  [info exists PDX_YMIN] {
	set y1 [expr $y1 - $PDX_YMIN]
	set y2 [expr $y2 - $PDX_YMIN]
    }

    if  [info exists PDX_XMIN] {
	set x1 [expr $x1 - $PDX_XMIN]
	set x2 [expr $x2 - $PDX_XMIN]
    }

    if [info exists PDX_YMAX] {
	set y1 [expr $PDX_YMAX - $PDX_YMIN - $y1]
	set y2 [expr $PDX_YMAX - $PDX_YMIN - $y2]
	set height [expr 0 - $height]
    }

   

    if { $x1 > $x2 } {
	set added -30
    } else { 
	set added 30
    }
    set xmid [expr $x2 - $x1]
    set x3 [expr $x1 + $added]
    set x4 [expr $x2 - $added]
    set y3 [expr $y1 + $height]
    puts $str "q
1 0 0 1 0 0 cm
$x1 $y1 m
$x3 $y3 $x4 $y3 $x2 $y2 c
Q
S"
}


proc pdx-draw-arrowhead {x1 y1 x2 y2  str} {
    global PDX_YMAX PDX_XMIN PDX_YMIN

 # Move drawing region to 0,0
    if  [info exists PDX_YMIN] {
	set y1 [expr $y1 - $PDX_YMIN]
	set y2 [expr $y2 - $PDX_YMIN]
    }

    if  [info exists PDX_XMIN] {
	set x1 [expr $x1 - $PDX_XMIN]
	set x2 [expr $x2 - $PDX_XMIN]
    }

    if [info exists PDX_YMAX] {
	set y1 [expr $PDX_YMAX - $PDX_YMIN - $y1]
	set y2 [expr $PDX_YMAX - $PDX_YMIN - $y2]
    }
    puts $str "q
1 0 0 1 $x1 $y1 cm
193.129 424.567 186.497 412.734 3 2 Ah
Q"
}


proc pdx-draw-text {text x1 y1 fontfamily fontsize width str} {
    global PDX_YMAX PDX_XMIN PDX_YMIN
      # Move drawing region to 0,0
    if  [info exists PDX_YMIN] {
	set y1 [expr $y1 - $PDX_YMIN]
    }

    if  [info exists PDX_XMIN] {
	set x1 [expr $x1 - $PDX_XMIN]
    }
    
    if [info exists PDX_YMAX] {
	set y1 [expr $PDX_YMAX - $PDX_YMIN - $y1]
	set y1 [expr $y1 - $fontsize - $fontsize -6]
    }

   
    puts $str "/$fontfamily $fontsize [expr $fontsize + 1] 0 1 z
\[1 0 0 1 $x1 $y1\] e
$width -5.08801 0 21.72 tbx
($text) t
T"
}

proc pdx-insert-header {str} {
    puts $str "%!PS-Adobe-3.0 EPSF-3.0
%%Creator: Mayura Draw, Version 3.6
%%Title: d12.pdx
%%CreationDate: Thu Jul 06 16:48:187:18:10 2000
%%BoundingBox: 118 403 493 686
%%DocumentFonts: ArialMT
%%Orientation: Portrait
%%EndComments
%%BeginProlog
%%BeginResource: procset MayuraDraw_ops
%%Version: 3.6
%%Copyright: (c) 1993-99 Mayura Software
/PDXDict 100 dict def
PDXDict begin
% width height matrix proc key cache
% definepattern -\> font
/definepattern { %def
  7 dict begin
    /FontDict 9 dict def
    FontDict begin
      /cache exch def
      /key exch def
      /proc exch cvx def
      /mtx exch matrix invertmatrix def
      /height exch def
      /width exch def
      /ctm matrix currentmatrix def
      /ptm matrix identmatrix def
      /str
      (xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx)
      def
    end
    /FontBBox \[ %def
      0 0 FontDict /width get
      FontDict /height get
    \] def
    /FontMatrix FontDict /mtx get def
    /Encoding StandardEncoding def
    /FontType 3 def
    /BuildChar { %def
      pop begin
      FontDict begin
        width 0 cache { %ifelse
          0 0 width height setcachedevice
        }{ %else
          setcharwidth
        } ifelse
        0 0 moveto width 0 lineto
        width height lineto 0 height lineto
        closepath clip newpath
        gsave proc grestore
      end end
    } def
    FontDict /key get currentdict definefont
  end
} bind def

% dict patternpath -
% dict matrix patternpath -
/patternpath { %def
  dup type /dicttype eq { %ifelse
    begin FontDict /ctm get setmatrix
  }{ %else
    exch begin FontDict /ctm get setmatrix
    concat
  } ifelse
  currentdict setfont
  FontDict begin
    FontMatrix concat
    width 0 dtransform
    round width div exch round width div exch
    0 height dtransform
    round height div exch
    round height div exch
    0 0 transform round exch round exch
    ptm astore setmatrix

    pathbbox
    height div ceiling height mul 4 1 roll
    width div ceiling width mul 4 1 roll
    height div floor height mul 4 1 roll
    width div floor width mul 4 1 roll

    2 index sub height div ceiling cvi exch
    3 index sub width div ceiling cvi exch
    4 2 roll moveto

    FontMatrix ptm invertmatrix pop
    { %repeat
      gsave
        ptm concat
        dup str length idiv { %repeat
          str show
        } repeat
        dup str length mod str exch
        0 exch getinterval show
      grestore
      0 height rmoveto
    } repeat
    pop
  end end
} bind def

% dict patternfill -
% dict matrix patternfill -
/patternfill { %def
  gsave
    eoclip patternpath
  grestore
  newpath
} bind def

/img { %def
  gsave
  /imgh exch def
  /imgw exch def
  concat
  imgw imgh 8
  \[imgw 0 0 imgh neg 0 imgh\]
  /colorstr 768 string def
  /colorimage where {
    pop
    { currentfile colorstr readhexstring pop }
    false 3 colorimage
  }{
    /graystr 256 string def
    {
      currentfile colorstr readhexstring pop
      length 3 idiv
      dup 1 sub 0 1 3 -1 roll
      {
        graystr exch
        colorstr 1 index 3 mul get 30 mul
        colorstr 2 index 3 mul 1 add get 59 mul
        colorstr 3 index 3 mul 2 add get 11 mul
        add add 100 idiv
        put
      } for
      graystr 0 3 -1 roll getinterval
    } image
  } ifelse
  grestore
} bind def

/arrowhead {
  gsave
    \[\] 0 setdash
    strokeC strokeM strokeY strokeK setcmykcolor
    2 copy moveto
    4 2 roll exch 4 -1 roll exch
    sub 3 1 roll sub
    exch atan rotate dup scale
    arrowtype
    dup 0 eq {
      -1 2 rlineto 7 -2 rlineto -7 -2 rlineto
      closepath fill
    } if
    dup 1 eq {
      0 3 rlineto 9 -3 rlineto -9 -3 rlineto
      closepath fill
    } if
    dup 2 eq {
      0 -0.5 rlineto -6 -6 rlineto -1.4142 1.4142 rlineto
      5.0858 5.0858 rlineto -5.0858 5.0858 rlineto
      1.4142 1.4142 rlineto 6 -6 rlineto closepath fill
    } if
    dup 3 eq {
      0 0.5 rlineto -7 1.5 rlineto 1 -2 rlineto -1 -2 rlineto 7 1.5 rlineto
      closepath fill
    } if
    dup 4 eq {
      0 -0.5 rlineto -9 -2.5 rlineto 0 6 rlineto 9 -2.5 rlineto
      closepath fill
    } if
    dup 5 eq {
      currentpoint newpath 3 0 360 arc
      closepath fill
    } if
    dup 6 eq {
      2.5 2.5 rmoveto 0 -5 rlineto -5 0 rlineto 0 5 rlineto
      closepath fill
    } if
    pop
  grestore
} bind def

/setcmykcolor where { %ifelse
  pop
}{ %else
  /setcmykcolor {
     /black exch def /yellow exch def
     /magenta exch def /cyan exch def
     cyan black add dup 1 gt { pop 1 } if 1 exch sub
     magenta black add dup 1 gt { pop 1 } if 1 exch sub
     yellow black add dup 1 gt { pop 1 } if 1 exch sub
     setrgbcolor
  } bind def
} ifelse

/RE { %def
  findfont begin
  currentdict dup length dict begin
    { %forall
      1 index /FID ne { def } { pop pop } ifelse
    } forall
    /FontName exch def dup length 0 ne { %if
      /Encoding Encoding 256 array copy def
      0 exch { %forall
        dup type /nametype eq { %ifelse
          Encoding 2 index 2 index put
          pop 1 add
        }{ %else
          exch pop
        } ifelse
      } forall
    } if pop
  currentdict dup end end
  /FontName get exch definefont pop
} bind def

/spacecount { %def
  0 exch
  ( ) { %loop
    search { %ifelse
      pop 3 -1 roll 1 add 3 1 roll
    }{ pop exit } ifelse
  } loop
} bind def

/WinAnsiEncoding \[
  39/quotesingle 96/grave 130/quotesinglbase/florin/quotedblbase
  /ellipsis/dagger/daggerdbl/circumflex/perthousand
  /Scaron/guilsinglleft/OE 145/quoteleft/quoteright
  /quotedblleft/quotedblright/bullet/endash/emdash
  /tilde/trademark/scaron/guilsinglright/oe/dotlessi
  159/Ydieresis 164/currency 166/brokenbar 168/dieresis/copyright
  /ordfeminine 172/logicalnot 174/registered/macron/ring
  177/plusminus/twosuperior/threesuperior/acute/mu
  183/periodcentered/cedilla/onesuperior/ordmasculine
  188/onequarter/onehalf/threequarters 192/Agrave/Aacute
  /Acircumflex/Atilde/Adieresis/Aring/AE/Ccedilla
  /Egrave/Eacute/Ecircumflex/Edieresis/Igrave/Iacute
  /Icircumflex/Idieresis/Eth/Ntilde/Ograve/Oacute
  /Ocircumflex/Otilde/Odieresis/multiply/Oslash
  /Ugrave/Uacute/Ucircumflex/Udieresis/Yacute/Thorn
  /germandbls/agrave/aacute/acircumflex/atilde/adieresis
  /aring/ae/ccedilla/egrave/eacute/ecircumflex
  /edieresis/igrave/iacute/icircumflex/idieresis
  /eth/ntilde/ograve/oacute/ocircumflex/otilde
  /odieresis/divide/oslash/ugrave/uacute/ucircumflex
  /udieresis/yacute/thorn/ydieresis
\] def

/SymbolEncoding \[
  32/space/exclam/universal/numbersign/existential/percent
  /ampersand/suchthat/parenleft/parenright/asteriskmath/plus
  /comma/minus/period/slash/zero/one/two/three/four/five/six
  /seven/eight/nine/colon/semicolon/less/equal/greater/question
  /congruent/Alpha/Beta/Chi/Delta/Epsilon/Phi/Gamma/Eta/Iota
  /theta1/Kappa/Lambda/Mu/Nu/Omicron/Pi/Theta/Rho/Sigma/Tau
  /Upsilon/sigma1/Omega/Xi/Psi/Zeta/bracketleft/therefore
  /bracketright/perpendicular/underscore/radicalex/alpha
  /beta/chi/delta/epsilon/phi/gamma/eta/iota/phi1/kappa/lambda
  /mu/nu/omicron/pi/theta/rho/sigma/tau/upsilon/omega1/omega
  /xi/psi/zeta/braceleft/bar/braceright/similar
  161/Upsilon1/minute/lessequal/fraction/infinity/florin/club
  /diamond/heart/spade/arrowboth/arrowleft/arrowup/arrowright
  /arrowdown/degree/plusminus/second/greaterequal/multiply
  /proportional/partialdiff/bullet/divide/notequal/equivalence
  /approxequal/ellipsis/arrowvertex/arrowhorizex/carriagereturn
  /aleph/Ifraktur/Rfraktur/weierstrass/circlemultiply
  /circleplus/emptyset/intersection/union/propersuperset
  /reflexsuperset/notsubset/propersubset/reflexsubset/element
  /notelement/angle/gradient/registerserif/copyrightserif
  /trademarkserif/product/radical/dotmath/logicalnot/logicaland
  /logicalor/arrowdblboth/arrowdblleft/arrowdblup/arrowdblright
  /arrowdbldown/lozenge/angleleft/registersans/copyrightsans
  /trademarksans/summation/parenlefttp/parenleftex/parenleftbt
  /bracketlefttp/bracketleftex/bracketleftbt/bracelefttp
  /braceleftmid/braceleftbt/braceex
  241/angleright/integral/integraltp/integralex/integralbt
  /parenrighttp/parenrightex/parenrightbt/bracketrighttp
  /bracketrightex/bracketrightbt/bracerighttp/bracerightmid
  /bracerightbt
\] def

/patarray \[
/leftdiagonal /rightdiagonal /crossdiagonal /horizontal
/vertical /crosshatch /fishscale /wave /brick
\] def
/arrowtype 0 def
/fillC 0 def /fillM 0 def /fillY 0 def /fillK 0 def
/strokeC 0 def /strokeM 0 def /strokeY 0 def /strokeK 1 def
/pattern -1 def
/mat matrix def
/mat2 matrix def
/nesting 0 def
/deferred /N def
/c /curveto load def
/C /curveto load def
/e { gsave concat 0 0 moveto } bind def
/F {
  nesting 0 eq { %ifelse
    pattern -1 eq { %ifelse
      fillC fillM fillY fillK setcmykcolor eofill
    }{ %else
      gsave fillC fillM fillY fillK setcmykcolor eofill grestore
      0 0 0 1 setcmykcolor
      patarray pattern get findfont patternfill
    } ifelse
  }{ %else
    /deferred /F def
  } ifelse
} bind def
/f { closepath F } bind def
/K { /strokeK exch def /strokeY exch def
     /strokeM exch def /strokeC exch def } bind def
/k { /fillK exch def /fillY exch def
     /fillM exch def /fillC exch def } bind def
/L /lineto load def
/m /moveto load def
/n /newpath load def
/N {
  nesting 0 eq { %ifelse
    newpath
  }{ %else
    /deferred /N def
  } ifelse
} def
/S {
  nesting 0 eq { %ifelse
    strokeC strokeM strokeY strokeK setcmykcolor stroke
  }{ %else
    /deferred /S def
  } ifelse
} bind def
/s { closepath S } bind def
/Tx { fillC fillM fillY fillK setcmykcolor show
      0 leading neg translate 0 0 moveto } bind def
/t { %def
  fillC fillM fillY fillK setcmykcolor
  align dup 0 eq { %ifelse
    pop show
  }{ %else
    dup 1 eq { %ifelse
      pop dup stringwidth pop 2 div neg 0 rmoveto show
    }{ %else
      dup 2 eq { %ifelse
        pop dup stringwidth pop neg 0 rmoveto show
      }{ %else
        pop
        dup stringwidth pop jwidth exch sub
        1 index spacecount
        dup 0 eq { %ifelse
          pop pop show
        }{ %else
          div 0 8#040 4 -1 roll widthshow
        } ifelse
      } ifelse
    } ifelse
  } ifelse
  0 leading neg translate 0 0 moveto
} bind def
/T { grestore } bind def
/TX { pop } bind def
/tbx { pop exch pop sub /jwidth exch def } def
/u {} def
/U {} def
/*u { /nesting nesting 1 add def } def
/*U {
  /nesting nesting 1 sub def
  nesting 0 eq {
    deferred cvx exec
  } if
} def
/w /setlinewidth load def
/d /setdash load def
/B {
  nesting 0 eq { %ifelse
    gsave F grestore S
  }{ %else
    /deferred /B def
  } ifelse
} bind def
/b { closepath B } bind def
/z { /align exch def pop /leading exch def exch findfont
     exch scalefont setfont } bind def
/Pat { /pattern exch def } bind def
/cm { 6 array astore concat } bind def
/q { mat2 currentmatrix pop } bind def
/Q { mat2 setmatrix } bind def
/Ah {
  pop /arrowtype exch def
  currentlinewidth 5 1 roll arrowhead
} bind def
/Arc {
  mat currentmatrix pop
    translate scale 0 0 1 5 -2 roll arc
  mat setmatrix
} bind def
/Bx {
  mat currentmatrix pop
    concat /y1 exch def /x1 exch def /y2 exch def /x2 exch def
    x1 y1 moveto x1 y2 lineto x2 y2 lineto x2 y1 lineto
  mat setmatrix
} bind def
/Rr {
  mat currentmatrix pop
    concat /yrad exch def /xrad exch def
    2 copy gt { exch } if /x2 exch def /x1 exch def
    2 copy gt { exch } if /y2 exch def /y1 exch def
    x1 xrad add y2 moveto
    matrix currentmatrix x1 xrad add y2 yrad sub translate xrad yrad scale
    0 0 1 90 -180 arc setmatrix
    matrix currentmatrix x1 xrad add y1 yrad add translate xrad yrad scale
    0 0 1 180 270 arc setmatrix
    matrix currentmatrix x2 xrad sub y1 yrad add translate xrad yrad scale
    0 0 1 270 0 arc setmatrix
    matrix currentmatrix x2 xrad sub y2 yrad sub translate xrad yrad scale
    0 0 1 0 90 arc setmatrix
    closepath
  mat setmatrix
} bind def
/Ov {
  mat currentmatrix pop
    concat translate scale 1 0 moveto 0 0 1 0 360 arc closepath
  mat setmatrix
} bind def
end
%%EndResource
%%EndProlog
%%BeginSetup
%PDX g 3 3 0 0
%%IncludeFont: ArialMT
PDXDict begin
%%EndSetup
%%Page: 1 1
%%BeginPageSetup
/_PDX_savepage save def

15 15 \[300 72 div 0 0 300 72 div 0 0\]
{ %definepattern
  2 setlinecap
  7.5 0 moveto 15 7.5 lineto
  0 7.5 moveto 7.5 15 lineto
  2 setlinewidth stroke
} bind
/rightdiagonal true definepattern pop

15 15 \[300 72 div 0 0 300 72 div 0 0\]
{ %definepattern
  2 setlinecap
  7.5 0 moveto 0 7.5 lineto
  15 7.5 moveto 7.5 15 lineto
  2 setlinewidth stroke
} bind
/leftdiagonal true definepattern pop

15 15 \[300 72 div 0 0 300 72 div 0 0\]
{ %definepattern
  2 setlinecap
  0 7.5 moveto 15 7.5 lineto
  2 setlinewidth stroke
} bind
/horizontal true definepattern pop

15 15 \[300 72 div 0 0 300 72 div 0 0\]
{ %definepattern
  2 setlinecap
  7.5 0 moveto 7.5 15 lineto
  2 setlinewidth stroke
} bind
/vertical true definepattern pop

15 15 \[300 72 div 0 0 300 72 div 0 0\]
{ %definepattern
  2 setlinecap
  0 7.5 moveto 15 7.5 lineto
  7.5 0 moveto 7.5 15 lineto
  2 setlinewidth stroke
} bind
/crosshatch true definepattern pop

30 30 \[300 72 div 0 0 300 72 div 0 0\]
{ %definepattern
  2 setlinecap
  0 7.5 moveto 30 7.5 lineto
  0 22.5 moveto 30 22.5 lineto
  7.5 0 moveto 7.5 7.5 lineto
  7.5 22.5 moveto 7.5 30 lineto
  22.5 7.5 moveto 22.5 22.5 lineto
  1 setlinewidth stroke
} bind
/brick true definepattern pop

30 30 \[300 72 div 0 0 300 72 div 0 0\]
{ %definepattern
  2 2 scale
  2 setlinecap
  7.5 0 moveto 15 7.5 lineto
  0 7.5 moveto 7.5 15 lineto
  7.5 0 moveto 0 7.5 lineto
  15 7.5 moveto 7.5 15 lineto
  0.5 setlinewidth stroke
} bind
/crossdiagonal true definepattern pop

30 30 \[300 72 div 0 0 300 72 div 0 0\]
{ %definepattern
  2 2 scale
  1 setlinecap
  0 7.5 moveto 0 15 7.5 270 360 arc
  7.5 15 moveto 15 15 7.5 180 270 arc
  0 7.5 moveto 7.5 7.5 7.5 180 360 arc
  0.5 setlinewidth stroke
} bind
/fishscale true definepattern pop

30 30 \[300 72 div 0 0 300 72 div 0 0\]
{ %definepattern
  1 setlinecap 0.5 setlinewidth
  7.5 0 10.6 135 45 arcn
  22.5 15 10.6 225 315 arc
  stroke
  7.5 15 10.6 135 45 arcn
  22.5 30 10.6 225 315 arc
  stroke
} bind
/wave true definepattern pop

WinAnsiEncoding /_ArialMT /ArialMT RE

newpath 0 setlinecap 0 setlinejoin 10 setmiterlimit
1 setlinewidth \[\] 0 setdash
118 403 moveto 118 686 lineto 493 686 lineto 493 403 lineto closepath clip
newpath
%%EndPageSetup"
}

proc pdx-insert-trailer {str} {
 puts $str "%%PageTrailer
_PDX_savepage restore
%%Trailer
end
showpage
%%EOF"
}


proc get-pdx-color {color} {
    switch -- $color {
	red {return "0 1 1 0"}
	green {return "0.8 0.2 1 0"}
	brown {return "0.4 0.8 1 0"}
	blue {return "1 1 0.2 0"}
	black {return "1 1 1 0"}
	white {return "0 0 0 0"}
	yellow {return "0 0 0.6 0"}
	gray {return "0.4 0.4 0.4 0"}
	default {return "1 1 1 0"}
    }
}



proc tmp {} {
"
x1 y1 x2 y2 x3 y3 curveto -

This operator draws a curve from the current point to the point (x3,
y3) using points (x1, y1) and (x2, y2) as control points.  The curve
is a B�zier cubic curve. In such a curve, the tangent of the curve at
the current point will be a line segment running from the current
point to (x1, y1) and the tangent at (x3, y3) is the line running from
(x3, y3) to (x2, y2).


% First line describes the circle
% last is y height of top of arc
% On before xmost side of circle
% 4th is rotation??
0 -1 1 0 0 490 cm
% 140.11 -138.155 200.794 200.794 308.233 370.326 Arc
% First is starting degrees (pen) // second isending degrees
% 3: y radius 4: x radius
9 -9 200 2 300 300 Arc

x-coord y-coord r ang1 ang2 arc - 

This operator adds an arc to the current path. The arc is generated by
sweeping a line segment of length r, and tied at the point (x-coord
y-coord), in a counter-clockwise direction from an angle ang1 to an
angle ang2. Note: a straight line segment will connect the current
point to the first point of the arc, if they are not the same.
"
}


proc find-textwidget-lines {canvas wgt} {
    # Tcl/Tk lacks functions to return the linebreaks in a text widget
    # This is a hack to find these by manipulating the selection
    set txt [$canvas itemcget $wgt -text]
    set font [$canvas itemcget $wgt -font]
    set bbox [$canvas bbox $wgt]
    set width [expr [lindex $bbox 2] - [lindex $bbox 0]]
    if { [font measure $font $txt] <= $width } {
	return [list $txt]
    }

    # We have a multiword item
    set result {}

    set len [string length $txt]
    set segstart 0
    set lastwordend {}
    set segend 1
    while { $segend < $len } {
	if { [lindex $txt $segend] == " " } {
	    # we have a word end
	    set seg [lrange $txt $segstart [expr $segend -1]]
	    set segwidth [font measure $font $seg]
	    if { $segwidth > $width } {
		# We have gone outside the bounds, use last word boundary
		if { $lastwordend == {} } {
		    # There is no lastword boundary, one word fills the line
		    lappend result [lrange $txt $segstart [expr $segend-1]]
		    set segstart [expr $segend + 1]
		    set segend $segstart
		} else {
		    lappend result [lrange $txt $segstart $lastwordend]
		    set segstart [expr $lastwordend + 1]
		    set segend $segstart
		}
	    } else {
		set lastwordend [expr $segend - 1]
	    }
	}
	incr segend
    }

    # Add on the last segment
    if { $segstart < $len } {
	lappend result [lrange $txt $segstart end]
    }

    # Return the results
    return $result
}
		
    
# load-pdx-font-mappings
#
# PDX files use font names distinct from those in Tcl.
proc load-pdx-font-mappings {} {
    global PDX_FONT_MAP PDX_FONT_DEFAULT LIBRARY
    set file [file join $LIBRARY "FONT_MAP"]
    if [file exists $file] {
	set text [read-file [file join $LIBRARY "FONT_MAP"]]
	set lines [split $text "\n"]
	set PDX_FONT_MAP {}
	foreach line $lines {
	    set result [split $line ":"]
	    set tclname [string trim [car $result]]
	    set pdxname [string trim [second $result]]
	    if { $tclname == "default" } {
		set PDX_FONT_DEFAULT $pdxname
	    } else {
		lappend PDX_FONT_MAP [list $tclname $pdxname]
	    }
	}
    } else {
	set PDX_FONT_MAP {{"Times" "_TimesNewRomanPSMT"} {"Arial" "ArialMT"}}
	set PDX_FONT_DEFAULT "_TimesNewRomanPSMT"
    }
}