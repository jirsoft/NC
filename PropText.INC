'PropText library
'JirSoft 2021
CONST VERSION.PROP = "0.06"

'needed for library to work
DIM STRING offset.PROP(16), width.PROP(16) 'strings with offset and width of font n%
'these 3 variables are needed because of inpossibility of read enviroment
DIM INTEGER fc.PROP = RGB(WHITE), bc.PROP = RGB(BLACK), fnt.PROP = 1 'color, background and current font
DIM INTEGER tb.PROP = 40 'default TAB positions (every 40 pixels)

SUB color.PROP(foreCol%, backCol%)
  'alias for COLOUR command

  fc.PROP = foreCol%
  bc.PROP = backCol%  
  COLOUR foreCol%, backCol%
END SUB

SUB font.PROP(fnt%)
  'alias for FONT command

  fnt.PROP = fnt%
  FONT fnt%
END SUB

SUB printLn.PROP(txt$, addSpace$)
  'simple PRINT command with new line on the end
  'if the string addSpace$ is not empty, then to N-th SPACE (" ") in txt$ is added PX pixels,
  'where PX=ASC(MID$(addSpace$, N, 1))
  
  print.PROP(txt$ + CHR$(10), addSpace$)
END SUB

SUB justify.PROP(txt$, txtWidth%, dx%)
  'special PRINT command with word wrap to txtWidth% written to x-offset dx%

  IF txt$="" THEN EXIT SUB

  LOCAL STRING part = "", orig = txt$, rest, prevPart, prevRest, addSp=""
  LOCAL INTEGER p, w, sp, i, spw

  DO WHILE orig<>""
    IF dx%>0 THEN ?@(dx%);
    rest = orig
    p = 0
    DO WHILE getTextWidth.PROP(fnt.PROP, part)<=txtWidth% AND rest<>""
      p = INSTR(p+1, orig, " ")
      IF p>0 THEN
        prevPart = part
        part = LEFT$(orig, p-1)
        prevRest = rest
        rest = MID$(orig, p+1)
      ELSE
        part = orig
        rest = ""
      ENDIF
    LOOP
    IF getTextWidth.PROP(fnt.PROP, part)>txtWidth% THEN
      IF prevPart<>"" THEN
        part = prevPart
        rest = prevRest
      ELSE
        'ERROR "Not enough width for text"
        'here will be simple print whole word that not fit into set space
      ENDIF
    ENDIF
    IF rest<>"" THEN
      w = txtWidth% - getTextWidth.PROP(fnt.PROP, part)
      addSp = ""
      IF w > 0 THEN
        sp = 0
        spw = 0
        FOR i=1 TO LEN(part)
          IF MID$(part, i, 1)=" " THEN INC sp
        NEXT i
        IF sp>0 THEN spw=w\sp
        FOR i = 1 TO sp-1
          CAT addSp, CHR$(spw)
          INC w, -spw
        NEXT i
        CAT addSp, CHR$(w)    
      ENDIF
      printLn.PROP(part, addSp)
    ELSE
      printLn.PROP(part)
    ENDIF
    orig = rest
    part = ""
  LOOP
END SUB

SUB wrap.PROP(txt$)
  'special PRINT command with word wrap

  IF txt$="" THEN EXIT SUB

  LOCAL STRING part, orig = txt$+" "
  LOCAL INTEGER p = INSTR(orig, " "), space = 0, w, ww = ASC(LEFT$(width.PROP(fnt.PROP),1))

  DO WHILE p>0
    part = LEFT$(orig, p-1)
    orig = MID$(orig, p+1)
    IF part<>"" THEN
      w = getTextWidth.PROP(fnt.PROP, part)
      IF space THEN INC w, getTextWidth.PROP(fnt.PROP, " ") + ww
      IF ww+w+MM.INFO(HPOS)=>MM.HRES THEN
        printLn.PROP("")
        space = 0
      ENDIF
      IF space THEN
        print.PROP(" " + part)
      ELSE
        space = 1
        print.PROP(part)
      ENDIF
    ENDIF
    p = INSTR(orig, " ")
  LOOP
  IF RIGHT$(txt$,1)=" " THEN
    IF getTextWidth.PROP(fnt.PROP, " ")+MM.INFO(HPOS)>MM.HRES THEN
      printLn.PROP("")
    ENDIF
    print.PROP(" ")
  ENDIF
END SUB

SUB print.PROP(txt$, addSpace$)
  'print proportional text txt$ with in current font, forecolor and backcolor

  IF txt$="" THEN EXIT SUB

  LOCAL INTEGER i, xx= MM.INFO(HPOS), yy=MM.INFO(VPOS), o, w, ww=ASC(LEFT$(width.PROP(fnt.PROP), 1))
  LOCAL STRING c, addSp = addSpace$
  
  FOR i=1 TO LEN(txt$)
    c = MID$(txt$, i, 1)
    IF ASC(c)>31 THEN
      o = ASC(MID$(offset.PROP(fnt.PROP), ASC(c), 1))
      w = ASC(MID$(width.PROP(fnt.PROP), ASC(c), 1))
      IF w+ww+xx>MM.HRES THEN
        xx = 0
        IF (yy+2*MM.INFO(FONTHEIGHT))>MM.VRES THEN
          PAGE SCROLL 0,0,MM.INFO(FONTHEIGHT),bc.PROP
        ELSE
          INC yy, MM.INFO(FONTHEIGHT)
        ENDIF
      ENDIF
      INC xx, -o
      IF bc.PROP>0 THEN BOX xx+o, yy, w+o+ww, MM.INFO(FONTHEIGHT), 0,,bc.PROP
      TEXT xx, yy, c, "LT",,, fc.PROP, -1
      IF addSp<>"" THEN
        IF c=" " THEN
          INC xx, ASC(LEFT$(addSp, 1))
          addSp = MID$(addSp, 2)
        ENDIF
      ENDIF
      INC xx, w + o + ww
    ELSEIF c=CHR$(8) THEN
      xx = ((xx \ tb.PROP) + 1) * tb.PROP
    ELSEIF c=CHR$(10) THEN
      xx = 0
      IF (yy+2*MM.INFO(FONTHEIGHT))>MM.VRES THEN
        PAGE SCROLL 0,0,MM.INFO(FONTHEIGHT),bc.PROP
      ELSE
        INC yy, MM.INFO(FONTHEIGHT)
      ENDIF
    ENDIF
  NEXT i
  ?@(xx,yy);
END SUB

SUB text.PROP(x%, y%, txt$, alig$, f%, fc%, bc%)
  'draw proportional text txt$ on x%, y% with alignment alig$ in font f% with forecolor f% and backcolor b% 

  IF txt$="" THEN EXIT SUB

  LOCAL INTEGER i, xx=x%, yy=y%, o, w, ww=ASC(LEFT$(width.PROP(f%), 1))
  LOCAL STRING c, a="L"
  FONT f%
  
  IF INSTR(alig$, "R") OR INSTR(alig$, "r")THEN
    w = getTextWidth.PROP(f%, txt$)
    o = ASC(MID$(offset.PROP(f%), ASC(LEFT$(txt$,1)), 1))
    INC xx, -w + o
  ELSEIF INSTR(alig$, "C") OR INSTR(alig$, "c") THEN
    w = getTextWidth.PROP(f%, txt$)
    o = ASC(MID$(offset.PROP(f%), ASC(LEFT$(txt$,1)), 1))
    INC xx, -(w\2) + o
  ENDIF
  IF INSTR(alig$,"B") OR INSTR(alig$,"b") THEN
    CAT a, "B"
  ELSEIF INSTR(alig$,"M") OR INSTR(alig$,"m") THEN
    CAT a, "M"
  ELSE
    CAT a, "T"
  ENDIF
  FOR i=1 TO LEN(txt$)
    c = MID$(txt$, i, 1)
    o = ASC(MID$(offset.PROP(f%), ASC(c), 1))
    w = ASC(MID$(width.PROP(f%), ASC(c), 1))
    INC xx, -o
    IF bc%>0 THEN BOX xx+o, yy, w+o+ww, MM.INFO(FONTHEIGHT), 0,,bc%
    TEXT xx, yy, c, a,,, fc%, -1
    INC xx, w + o + ww
  NEXT i
END SUB

SUB initAll.PROP
  'initialise proportional offsets and widths for all built-in fonts

  'FONT1
  offset.PROP( 1)=    "0000000000000000000000000000000032111142211313111111111113311211111111111111111111111"
  CAT offset.PROP( 1),"1111121211211111111311311111121111111132110000000111111021101101112011011000011000020"
  CAT offset.PROP( 1),"1101000030000001000003003003111001000000133100030004011111100111100112111111123312220"
  width.PROP( 1)=    "2000000000000000000000000000000314666614465262665666666662256566666666665666666666666"
  CAT width.PROP( 1),"6665646457466566566155265666655666666515668888888777667847686677774866876888875888848"
  CAT width.PROP( 1),"6687888825577576777555885885777887888888755788558844865656676565577454566776633265447"
  'FONT2
  offset.PROP( 2)=    "0000000000000000000000000000000054232346432425233233233335312133122222223222122222221"
  CAT offset.PROP( 2),"1122363431422222322332312222233222223464200000000000000000000000000000000000000000000"
  CAT offset.PROP( 2),"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  width.PROP( 2)=    "20000000000000000000000000000004268697433794928778778777724:9:78;99988:979:9;9999:89:"
  CAT width.PROP( 2),";;9973837;5998988997697;9899878999897515844444444444444444444444444444444444444444444"
  CAT width.PROP( 2),"4444444444444444444444444444444444444444444444444444444444444444444444444444444444444"
  'FONT3
  offset.PROP( 3)=    "0000000000000000000000000000000064220175653646523222222226632321121234126123021212212"
  CAT offset.PROP( 3),"2011173420123222322634603122434330232563200000000000000000000000000000000000000000000"
  CAT offset.PROP( 3),"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  width.PROP( 3)=    "3000000000000000000000000000000548<<?>4558:3837<8<<<<<<<<33:<:;>><=<;:><3:=:@<><?=<=<"
  CAT width.PROP( 3),"=@>==495:@7;;;;;8;:36:3@:;;;8:8::@;:;737;55555555555555555555555555555555555555555555"
  CAT width.PROP( 3),"5555555555555555555555555555555555555555555555555555555555555555555555555555555555555"
  'FONT4
  offset.PROP( 4)=    "0000000000000000000000000000000043111143311414112111111114421211111111112111111111111"
  CAT offset.PROP( 4),"1111131311211111211231211111112111111242110000000111111031111111113122112111112110031"
  CAT offset.PROP( 4),"2101010050000003000005005005333003000000355300050035011111111211111111122221234412321"
  width.PROP( 4)=    "2000000000000000000000000000000314777723377272775777777771257577777777775777777777777"
  CAT width.PROP( 4),"777773737757777767754757777777677777751577:::::::777777:47787777784866876888885889:48"
  CAT width.PROP( 4),"68:9:9::16677674777665::5::5777::7::::::7557::65::45:77777777677777777755667622276467"
  'FONT5
  offset.PROP( 5)=    "00000000000000000000000000000000:6344396855;6;54755445545::35353344445445445443444544"
  CAT offset.PROP( 5),"33444667647553444356644464455454535345;7400000000000000000000000000000000000000000000"
  CAT offset.PROP( 5),"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  width.PROP( 5)=    "400000000000000000000000000000074=A?AA5;;??5=4>?8>=??==?=45@?@>@A?@??=@?<?@>??A?A??@?"
  CAT width.PROP( 5),"AA@A@;>;<@9>????@A=;<?>A=???=>>??A?@?=3>@77777777777777777777777777777777777777777777"
  CAT width.PROP( 5),"7777777777777777777777777777777777777777777777777777777777777777777777777777777777777"
  'FONT6
  offset.PROP( 6)=    "000000000000000000000000000000000000000000404<02413222222>004000000000000000000000000"
  CAT offset.PROP( 6),"0000000000:00000000000000000000000000000000000000000000000000000000000000000000000000"
  CAT offset.PROP( 6),"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  width.PROP( 6)=    "500000000000000000000000000000099999999999D9H99L@MKLLLLLL799H999999999999999999999999"
  CAT width.PROP( 6),"9999999999>99999999999999999999999999999999999999999999999999999999999999999999999999"
  CAT width.PROP( 6),"9999999999999999999999999999999999999999999999999999999999999999999999999999999999999"
  'FONT7
  offset.PROP( 7)=    "0000000000000000000000000000000021000011100201001000000001100100000000001000000000000"
  CAT offset.PROP( 7),"0000010100100000000100100000000000000122000000000000000000000000000000000000000000000"
  CAT offset.PROP( 7),"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  width.PROP( 7)=    "1000000000000000000000000000000213555523355252553555555552245455555555553555555555555"
  CAT width.PROP( 7),"5555535355455555555344355555555555555313552222222222222222222222222222222222222222222"
  CAT width.PROP( 7),"2222222222222222222222222222222222222222222222222222222222222222222222222222222222222"

  LOCAL INTEGER f, i
  FOR f = 1 TO 7
    FOR i = 1 TO 255
      MID$(width.PROP(f),i,1) = CHR$(ASC(MID$(width.PROP(f),i,1))-48)
      MID$(offset.PROP(f),i,1) = CHR$(ASC(MID$(offset.PROP(f),i,1))-48)
    NEXT i
  NEXT f
END SUB

SUB initFont.PROP(fnt%)
  'initialise proportional offsets and widths for complete font f%

  LOCAL INTEGER c, x, y, o, w

  FONT fnt%
  offset.PROP(fnt%) = STRING$(255,0)
  width.PROP(fnt%) = CHR$((MM.INFO(FONTWIDTH)\8)+1) + STRING$(254, 0)
  PAGE WRITE 1
  FOR c=32 TO 255
    o = -1
    w = -1
    TEXT 0, 0, CHR$(c), "LT",fnt%,,RGB(WHITE), RGB(BLACK)
    FOR x=0 TO MM.INFO(FONTWIDTH)-1
      FOR y=0 TO MM.INFO(FONTHEIGHT)-1
        IF PIXEL(x, y)>0 THEN
          o = x
          EXIT FOR
        ENDIF      
      NEXT y
      IF o>=0 THEN EXIT FOR
    NEXT x
    IF o<0 THEN o=0
    MID$(offset.PROP(fnt%), c, 1) = CHR$(o)
    FOR x=MM.INFO(FONTWIDTH)-1 TO 0 STEP -1
      FOR y=0 TO MM.INFO(FONTHEIGHT)-1
        IF PIXEL(x, y)>0 THEN
          w = x
          EXIT FOR
        ENDIF      
      NEXT y
      IF w>=0 THEN EXIT FOR
    NEXT x
    IF w<0 THEN w=MM.INFO(FONTWIDTH)\4
    MID$(width.PROP(fnt%), c, 1) = CHR$(w-o+1)
  NEXT c
  PAGE WRITE 0
END SUB

FUNCTION getTextWidth.PROP(f%, txt$) AS INTEGER
  'get width of proportional text txt$ drawn in font f% in pixels

  getTextWidth.PROP = 0
  IF txt$="" THEN EXIT FUNCTION

  LOCAL INTEGER i, ww = ASC(LEFT$(width.PROP(f%), 1)), ch
  FOR i = 1 TO LEN(txt$)
    ch = ASC(MID$(txt$, i, 1))
    IF ch>0 THEN INC getTextWidth.PROP, ASC(MID$(width.PROP(f%), ch, 1)) + ww
  NEXT i
  INC getTextWidth.PROP, -ww
END FUNCTION

SUB tab.PROP(t%)
  'set TAB position to every t% pixels

  tb.PROP = t%
END SUB

SUB justifyLine.PROP(txt$, txtWidth%, dx%)
  'special PRINT-one-line command with word wrap to txtWidth% written to x-offset dx%
  'in txt$ will stay non printed rest

  IF txt$="" THEN EXIT SUB

  LOCAL STRING part = "", orig = txt$, rest, prevPart, prevRest, addSp=""
  LOCAL INTEGER p, w, sp, i, spw

  IF dx%>0 THEN ?@(dx%);
  rest = orig
  p = 0
  DO WHILE getTextWidth.PROP(fnt.PROP, part)<=txtWidth% AND rest<>""
    p = INSTR(p+1, orig, " ")
    IF p>0 THEN
      prevPart = part
      part = LEFT$(orig, p-1)
      prevRest = rest
      rest = MID$(orig, p+1)
    ELSE
      part = orig
      rest = ""
    ENDIF
  LOOP
  IF getTextWidth.PROP(fnt.PROP, part)>txtWidth% THEN
    IF prevPart<>"" THEN
      part = prevPart
      rest = prevRest
    ELSE
      'ERROR "Not enough width for text"
      'here will be simple print whole word that not fit into set space
    ENDIF
  ENDIF

  IF rest<>"" THEN
    w = txtWidth% - getTextWidth.PROP(fnt.PROP, part)
    addSp = ""
    IF w > 0 THEN
      sp = 0
      spw = 0
      FOR i=1 TO LEN(part)
        IF MID$(part, i, 1)=" " THEN INC sp
      NEXT i
      IF sp>0 THEN spw=w\sp
      FOR i = 1 TO sp-1
        CAT addSp, CHR$(spw)
        INC w, -spw
      NEXT i
      CAT addSp, CHR$(w)    
    ENDIF
    printLn.PROP(part, addSp)
  ELSE
    printLn.PROP(part)
  ENDIF

  txt$ = rest
END SUB


