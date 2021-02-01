'Simple TUI, it's prepared for screenshoting
CONST VERSION.TUI = "0.42"

'SUB TUIinfo(title AS STRING, txt() AS STRING, logo AS INTEGER)
  'Shows more lines of info text (BLIT #1), also LOGO (blitnum)

'FUNCTION TUIwaitingON(title AS STRING) AS STRING
  'Start progress, returns coordinates as string "X,Y" (BLIT #2)

'SUB TUIwaitingProgress(coord AS STRING, perc AS INTEGER)
  'Draw progress into waiting dialog

'SUB TUIwaitingOFF(coord AS STRING)
  'Finish progress (BLIT #2)

'FUNCTION TUIchoice(title AS STRING, txt AS STRING) AS INTEGER
  'Select one from up to 10 choices with keys 0-9 (BLIT #3)

'SUB TUIwarning(title AS STRING, txt AS STRING)
  'Simple warning, wait for any key (BLIT #4)

'FUNCTION TUIquestion(title AS STRING, txt AS STRING) AS INTEGER
  'Question, returns 1 when OK (ENTER) was pressed, 0 else (BLIT #5)

'FUNCTION TUIinput(title AS STRING, txt AS STRING, def AS STRING, en AS STRING) AS STRING
  'Input string, returns text, DEL erase all, BACKSPACE 1 char, ENTER to finish (BLIT #6)

'FUNCTION TUIselect(title AS STRING, txt AS STRING, s AS INTEGER) AS INTEGER
  'Selection checkbox, can select up to 10 choices with keys 0-9 (BLIT #7)

'FUNCTION TUIgetItem(title AS STRING, subtitle AS STRING, txt() AS STRING) AS STRING
  'Shows more lines of text (BLIT #8) and let the user select one

'FUNCTION TUIgetParent(s AS STRING) AS STRING
  'helper for file selector

'FUNCTION TUIgetSelect(path AS STRING, ext AS STRING) AS STRING
  'once-shot file selector
  'ext can be also more extensiions separated by coma (ext = ".BAS,.INC") or "" (select all)

'FUNCTION TUIfileSelect(path AS STRING, ext AS STRING) AS STRING
  '(almost) complete file selector
  'ext can be also more extensiions separated by coma (ext = ".BAS,.INC") or "" (select all)

'FUNCTION TUIemptyON(title AS STRING, ww AS INTEGER, hh AS INTEGER, but AS STRING) AS STRING
  'Shows empty dialog (space), returns coordinates as string "X,Y" (BLIT #9)
  'if but is used, then is show instead of "OK"

'SUB TUIemptyOFF(coord AS STRING)
  'Close empty (BLIT #9)

'SUB TUIwaitForKey
'SUB TUIwaitForNoKey
  'waits for key or until no key pressed

DIM INTEGER ON.TUI, X.TUI, Y.TUI, W.TUI, H.TUI 'for screenshot

CONST CURSOR_SPEED.TUI = 300 'cursor blinking speed in ms
CONST ESC.TUI = CHR$(27), ENTER.TUI = CHR$(10)
DIM STRING TICK.TUI = CHR$(232) 'tick character
DIM INTEGER BC.TUI = RGB(YELLOW), FC.TUI = RGB(GRAY), IC.TUI = RGB(CYAN) 'default colors
DIM INTEGER FONT.TUI = 8 'default font

SUB TUIinfo(title AS STRING, txt() AS STRING, logo AS INTEGER)
  'Shows more lines of info text (BLIT #1)

  FONT FONT.TUI
  LOCAL INTEGER fow = MM.INFO(FONTWIDTH)
  LOCAL INTEGER foh = MM.INFO(FONTHEIGHT)
  LOCAL INTEGER w = 4*fow + fow*LEN(title) 'minimum width
  LOCAL INTEGER h = foh, i
  LOCAL INTEGER m = BOUND(txt())
 
  FOR i = 0 TO m
    txt(i) = LEFT$(txt(i), MIN(MM.HRES/fow - 4, LEN(txt(i))))
    w = MAX(4*fow + fow*LEN(txt(i)), w)
  NEXT i
  h = m*foh + 5*foh
  LOCAL INTEGER dx = (MM.HRES - w)\2, dy = (MM.VRES - h)\2 

  BLIT READ #1, dx, dy, w, h 
  BOX dx + 0, dy + 0, w, h, 0, BC.TUI, BC.TUI
  BOX dx+fow/4,dy+foh/2,w-fow/2,h-foh*3/4,2,FC.TUI,BC.TUI
  TEXT dx+w\2,dy+1," " + title + " ","CT",,,FC.TUI,BC.TUI
  FOR i = 0 TO m
    TEXT dx+fow,dy+1.5*foh+i*foh,txt(i),"LT",,,FC.TUI,BC.TUI
  NEXT i
  TEXT dx+w\2,dy+h-3/2*foh,"  OK  ","CT",,,BC.TUI,FC.TUI
  IF logo THEN BLIT WRITE logo, dx+fow, dy+foh

  ON.TUI = 1: X.TUI = dx: Y.TUI = dy: W.TUI = w: H.TUI = h 'for screenshot
  

  TUIwaitForKey
  ON.TUI = 0  
  BLIT WRITE #1,dx,dy
  BLIT CLOSE #1
END SUB

FUNCTION TUIwaitingON(title AS STRING) AS STRING
  'Start progress, returns coordinates as string "X,Y" (BLIT #2)

  CONST txt = "Please wait..."
  FONT FONT.TUI
  LOCAL INTEGER fow = MM.INFO(FONTWIDTH)
  LOCAL INTEGER foh = MM.INFO(FONTHEIGHT)
  LOCAL INTEGER w = 4*fow + fow * MAX(LEN(title), LEN(txt)) 'minimum width
  LOCAL INTEGER h = 3.5*foh
  LOCAL INTEGER dx = (MM.HRES-w)\2, dy = (MM.VRES-h)\2 
  
  BLIT READ #2,dx,dy,w,h 
  BOX dx+0,dy+0,w,h,0,BC.TUI,BC.TUI
  BOX dx+fow/4,dy+foh/2,w-fow/2,h-foh*3/4,2,FC.TUI,BC.TUI
  TEXT dx+w\2,dy+1," " + title + " ","CT",,,FC.TUI,BC.TUI
  TEXT dx+w\2,dy+h-3/2*foh,txt,"CT",,,FC.TUI,BC.TUI
  ON.TUI = 1: X.TUI = dx: Y.TUI = dy: W.TUI = w: H.TUI = h 'for screenshot

  TUIwaitingON = STR$(dx) + "," + STR$(dy) + "," + STR$(w) + "," + STR$(h)
END FUNCTION

SUB TUIwaitingProgress(coord AS STRING, perc AS INTEGER)
  'Draw progress into waiting dialog

  FONT FONT.TUI
  LOCAL INTEGER fow = MM.INFO(FONTWIDTH)
  LOCAL INTEGER foh = MM.INFO(FONTHEIGHT)
  LOCAL INTEGER dx = VAL(FIELD$(coord,1,","))
  LOCAL INTEGER dy = VAL(FIELD$(coord,2,","))
  LOCAL INTEGER w = VAL(FIELD$(coord,3,","))
  LOCAL INTEGER h = VAL(FIELD$(coord,4,","))
  LOCAL INTEGER pbw = w - 4 * fow  
  BOX dx + w \ 2 - pbw\2, dy + 4/3*foh, pbw, foh/2, 1, FC.TUI
  BOX dx + w \ 2 - pbw\2, dy + 4/3*foh, pbw * MAX(MIN(perc, 100), 0) \ 100, foh/2, 0, FC.TUI, FC.TUI
END SUB

SUB TUIwaitingOFF(coord AS STRING)
  'Finish progress (BLIT #2)

  LOCAL INTEGER dx = VAL(FIELD$(coord,1,","))
  LOCAL INTEGER dy = VAL(FIELD$(coord,2,","))

  ON.TUI = 0  
  BLIT WRITE #2,dx,dy
  BLIT CLOSE #2
END SUB

FUNCTION TUIchoice(title AS STRING, txt AS STRING) AS INTEGER
  'Select one from up to 10 choices with keys 0-9 (BLIT #3)
  
  FONT FONT.TUI
  LOCAL INTEGER fow = MM.INFO(FONTWIDTH)
  LOCAL INTEGER foh = MM.INFO(FONTHEIGHT)
  LOCAL INTEGER w = 4*fow + fow*MAX(LEN(title),13) 'minimum 13 chars
  LOCAL INTEGER i,cnt = 0, h = 5*foh
  LOCAL STRING k, keysEnabled = "0123456789"
  
  DO WHILE FIELD$(txt, cnt+1, ",") <> ""
    cnt = cnt + 1
  LOOP
  cnt = MIN(cnt, 10)

  keysEnabled = LEFT$(keysEnabled, cnt) + ESC.TUI

  h = foh*cnt + 4*foh
  FOR i = 1 TO cnt
    w = MAX(w, fow*(2 + LEN(FIELD$(txt, i, ",")) + fow/2))
  NEXT i
  LOCAL INTEGER dx = (MM.HRES-w)\2, dy = (MM.VRES-h)\2 
  
  BLIT READ #3,dx,dy,w,h 
  BOX dx+0,dy+0,w,h,0,BC.TUI,BC.TUI
  BOX dx+fow/4,dy+foh/2,w-fow/2,h-foh*3/4,2,FC.TUI,BC.TUI
  TEXT dx+w\2,dy+1," " + title + " ","CT",,,FC.TUI,BC.TUI
  TEXT dx+w\2,dy+h-3/2*foh,"  OK  ","CT",,,BC.TUI,FC.TUI

  FOR i = 1 TO cnt
    TEXT dx+fow,dy+foh/2+i*foh," " + STR$(i-1) + " " + FIELD$(txt, i, ","),"LT",,,FC.TUI,BC.TUI
  NEXT i
  TEXT dx+w\2,dy+h-3/2*foh," Press 0-" + STR$(cnt-1) + " ","CT",,,BC.TUI,FC.TUI
  ON.TUI = 1: X.TUI = dx: Y.TUI = dy: W.TUI = w: H.TUI = h 'for screenshot

  DO
    k = INKEY$
  LOOP WHILE INSTR(keysEnabled,k)=0 
  DO:LOOP WHILE INKEY$<>"" 
  TUIchoice = ASC(k)-48
  ON.TUI = 0  
  BLIT WRITE #3,dx,dy
  BLIT CLOSE #3
END FUNCTION

SUB TUIwarning(title AS STRING, txt AS STRING)
  'Simple warning, wait for any key (BLIT #4)

  FONT FONT.TUI
  LOCAL INTEGER fow = MM.INFO(FONTWIDTH)
  LOCAL INTEGER foh = MM.INFO(FONTHEIGHT)
  LOCAL INTEGER w = 4*fow + fow*MAX(LEN(title),LEN(txt),8) 'minimum 8 chars
  LOCAL INTEGER h = 5*foh

  LOCAL INTEGER dx = (MM.HRES-w)\2, dy = (MM.VRES-h)\2 

  IF w > MM.HRES THEN
    title = LEFT$(title, MIN(MM.HRES/fow - 4, LEN(title)))
    txt = LEFT$(txt, MIN(MM.HRES/fow - 4, LEN(txt)))
    w = MM.HRES
    dx = (MM.HRES-w)\2
  ENDIF  
  BLIT READ #4,dx,dy,w,h 
  BOX dx+0,dy+0,w,h,0,BC.TUI,BC.TUI
  BOX dx+fow/4,dy+foh/2,w-fow/2,h-foh*3/4,2,FC.TUI,BC.TUI
  TEXT dx+w\2,dy+1," " + title + " ","CT",,,FC.TUI,BC.TUI
  TEXT dx+w\2,dy+1.5*foh,txt,"CT",,,FC.TUI,BC.TUI
  TEXT dx+w\2,dy+h-3/2*foh,"  OK  ","CT",,,BC.TUI,FC.TUI
  ON.TUI = 1: X.TUI = dx: Y.TUI = dy: W.TUI = w: H.TUI = h 'for screenshot

  TUIwaitForKey
  ON.TUI = 0  
  BLIT WRITE #4,dx,dy
  BLIT CLOSE #4
END SUB

FUNCTION TUIquestion(title AS STRING, txt AS STRING) AS INTEGER
  'Question, returns 1 when OK (ENTER) was pressed, 0 else (BLIT #5)

  FONT FONT.TUI
  LOCAL INTEGER fow = MM.INFO(FONTWIDTH)
  LOCAL INTEGER foh = MM.INFO(FONTHEIGHT)
  LOCAL INTEGER w = 4*fow + fow*MAX(LEN(title),LEN(txt),8) 'minimum 8 chars
  LOCAL INTEGER h = 5*foh
  LOCAL STRING k = ""
  LOCAL INTEGER dx = (MM.HRES-w)\2, dy = (MM.VRES-h)\2 

  BLIT READ #5,dx,dy,w,h 
  BOX dx+0,dy+0,w,h,0,BC.TUI,BC.TUI
  BOX dx+fow/4,dy+foh/2,w-fow/2,h-foh*3/4,2,FC.TUI,BC.TUI
  TEXT dx+w\2,dy+1," " + title + " ","CT",,,FC.TUI,BC.TUI
  TEXT dx+w\2,dy+1.5*foh,txt,"CT",,,FC.TUI,BC.TUI
  TEXT dx+fow,dy+h-3/2*foh,"Cancel","LT",,,BC.TUI,FC.TUI
  TEXT dx+w - fow,dy+h-3/2*foh,"  OK  ","RT",,,BC.TUI,FC.TUI

  ON.TUI = 1: X.TUI = dx: Y.TUI = dy: W.TUI = w: H.TUI = h 'for screenshot

  DO
    k = INKEY$
  LOOP WHILE k<>ESC.TUI AND k<>ENTER.TUI 
  DO:LOOP WHILE INKEY$<>""
  ON.TUI = 0  
  BLIT WRITE #5,dx,dy
  BLIT CLOSE #5
  TUIquestion = (k=ENTER.TUI)
END FUNCTION

FUNCTION TUIselect(title AS STRING, txt AS STRING, s AS INTEGER) AS INTEGER
  'Selection checkbox, can select up to 10 choices with keys 0-9 (BLIT #7)
  
  FONT FONT.TUI
  LOCAL INTEGER fow = MM.INFO(FONTWIDTH)
  LOCAL INTEGER foh = MM.INFO(FONTHEIGHT)
  LOCAL INTEGER w = 4*fow + fow*MAX(LEN(title),19) 'minimum 13 chars
  LOCAL INTEGER i,cnt = 0, h = 5*foh, retStr = s
  LOCAL STRING k, keysEnabled = "0123456789"
  LOCAL STRING mark

  DO WHILE FIELD$(txt, cnt+1, ",") <> ""
    cnt = cnt + 1
  LOOP
  cnt = MIN(cnt, 10)

  keysEnabled = LEFT$(keysEnabled, cnt) + ESC.TUI + ENTER.TUI

  h = foh*cnt + 5*foh
  FOR i = 1 TO cnt
    w = MAX(w, fow*(LEN(FIELD$(txt, i, ","))+7))
  NEXT i
  LOCAL INTEGER dx = (MM.HRES-w)\2, dy = (MM.VRES-h)\2 
  
  BLIT READ #7,dx,dy,w,h 
  BOX dx+0,dy+0,w,h,0,BC.TUI,BC.TUI
  BOX dx+fow/4,dy+foh/2,w-fow/2,h-foh*3/4,2,FC.TUI,BC.TUI
  TEXT dx+w\2,dy+1," " + title + " ","CT",,,FC.TUI,BC.TUI

  FOR i = 1 TO cnt
    IF s AND (1 << (i-1)) THEN
      mark = TICK.TUI
    ELSE
      mark = " "
    ENDIF
    TEXT dx+fow,dy+foh/2 + i*foh," " + STR$(i-1) + " " + mark + " " + FIELD$(txt, i, ","),"LT",,,FC.TUI,BC.TUI
  NEXT i
  TEXT dx+w\2,dy+h-3*foh," Set/Unset with 0-" + STR$(cnt-1) + " ","CT",,,FC.TUI,BC.TUI
  TEXT dx+w\2,dy+h-3/2*foh,"  OK  ","CT",,,BC.TUI,FC.TUI
  ON.TUI = 1: X.TUI = dx: Y.TUI = dy: W.TUI = w: H.TUI = h 'for screenshot

  DO
    DO
      k = INKEY$
    LOOP WHILE INSTR(keysEnabled,k)=0 
    DO:LOOP WHILE INKEY$<>""
    IF ASC(k)>47 THEN
      retStr = retStr XOR (1<<(ASC(k)-48))
      IF retStr AND (1<<(ASC(k)-48)) THEN
        TEXT dx+4*fow,dy+foh/2+(ASC(k)-47)*foh, TICK.TUI,"LT",,,FC.TUI,BC.TUI        
      ELSE
        TEXT dx+4*fow,dy+foh/2+(ASC(k)-47)*foh, " ","LT",,,FC.TUI,BC.TUI        
      ENDIF
    ENDIF
  LOOP WHILE k<>ESC.TUI AND k<>ENTER.TUI

  ON.TUI = 0  
  BLIT WRITE #7,dx,dy
  BLIT CLOSE #7
  IF k = ENTER.TUI THEN 
    TUIselect = retStr
  ELSE
    TUIselect = s
  ENDIF
END FUNCTION

SUB TUIwaitForKey
  DO:LOOP WHILE INKEY$=""
  TUIwaitForNoKey
END SUB

SUB TUIwaitForNoKey
  DO:LOOP WHILE INKEY$<>""
END SUB

FUNCTION TUIgetItem(title AS STRING, subtitle AS STRING, txt() AS STRING) AS STRING
  'Shows more lines of text (BLIT #8) and let the user select one

  FONT FONT.TUI
  LOCAL INTEGER fow = MM.INFO(FONTWIDTH)
  LOCAL INTEGER foh = MM.INFO(FONTHEIGHT)
  LOCAL INTEGER w = 4*fow + fow * MAX(LEN(title),13)
  LOCAL INTEGER h = foh, i
  LOCAL INTEGER m = BOUND(txt()), curs = 1, position = 0, ww = 0
  LOCAL INTEGER maxItems = MIN((MM.VRES \ foh) - 7, m)
  LOCAL INTEGER pbMax = foh * m
  LOCAL INTEGER pbWin = foh * maxItems
  LOCAL INTEGER pbLen = pbWin / pbMax * pbWin
  LOCAL INTEGER running = 1, prev = -1, prevCurs = -1
  LOCAL STRING k

  LOCAL FLOAT pbPos
  IF m > maxItems THEN pbPos = (pbWin - pbLen) / (m - maxItems)

  TUIgetItem = ""

  w = MAX(4*fow + fow * LEN(subtitle), w)  
  FOR i = 1 TO m
    IF LEN(txt(i)) > ((MM.HRES\fow)-2) THEN 
      txt(i) = LEFT$(txt(i),(MM.HRES\fow)-2)
    ENDIF
    ww = MAX(ww, LEN(txt(i)))
  NEXT i
  w = MAX(4*fow + fow*ww, w)
  h = MIN(maxItems, m) * foh+5.5*foh
  LOCAL INTEGER dx = (MM.HRES-w)\2, dy = (MM.VRES-h)\2 

  BLIT READ #8,dx,dy,w,h 
  BOX dx+0,dy+0,w,h,0,BC.TUI,BC.TUI
  BOX dx+fow/4,dy+foh/2,w-fow/2,h-foh*3/4,2,FC.TUI,BC.TUI
  TEXT dx+w\2,dy+1," " + title + " ","CT",,,FC.TUI,BC.TUI
  TEXT dx+w\2,dy+1+foh," " + subtitle + " ","CT",,,FC.TUI,BC.TUI
  TEXT dx+fow,dy+h-3/2*foh,"Cancel","LT",,,BC.TUI,FC.TUI
  TEXT dx+w - fow,dy+h-3/2*foh,"  OK  ","RT",,,BC.TUI,FC.TUI

  ON.TUI = 1: X.TUI = dx: Y.TUI = dy: W.TUI = w: H.TUI = h 'for screenshot

  DO WHILE running
    IF position <> prev OR curs <> prevCurs THEN
      FOR i = 1 TO MIN(m, maxItems)
        IF i+position = curs THEN
          TEXT dx+fow,dy+1.5*foh+foh*i,txt(position + i) + SPACE$(ww - LEN(txt(position + i))),"LT",,,BC.TUI,FC.TUI
          TUIgetItem = txt(position + i)
        ELSE
          TEXT dx+fow,dy+1.5*foh+foh*i,txt(position + i) + SPACE$(ww - LEN(txt(position + i))),"LT",,,FC.TUI,BC.TUI
        ENDIF
      NEXT i
      IF m > maxItems THEN
        BOX dx + w - 2*fow, dy + 2.5*foh, fow, pbWin, 1, FC.TUI, BC.TUI
        BOX dx + w - 2*fow, dy + 2.5*foh + position * pbPos, fow, pbLen, 0, FC.TUI, FC.TUI
      ENDIF
      prev = position
      prevCurs = curs
    ENDIF
    k = INKEY$
    IF k <> "" THEN
      SELECT CASE k
      CASE CHR$(128) 'up
        IF curs > (position + 1) THEN
          INC curs, -1
        ELSE
          IF position > 0 THEN
            INC position, -1
            INC curs, -1
          ENDIF            
        ENDIF

      CASE CHR$(129) 'down
        IF curs < maxItems+position THEN
          INC curs, 1
        ELSE
          IF position+maxItems < m THEN
            INC curs, 1
            INC position, 1
          ENDIF
        ENDIF

      CASE CHR$(27) 'ESC
        TUIgetItem = ""
        running = 0
      
      CASE CHR$(10) 'ENTER
        running = 0

      END SELECT
    ENDIF 
  LOOP
  
  ON.TUI = 0  
  BLIT WRITE #8,dx,dy
  BLIT CLOSE #8
END FUNCTION

FUNCTION TUIgetParent(s AS STRING) AS STRING
  'helper for file selector

  TUIgetParent = s
  IF UCASE$(s) <> "A:/" THEN
    IF RIGHT$(TUIgetParent, 1) = "/" THEN
      TUIgetParent = LEFT$(TUIgetParent, LEN(TUIgetParent) - 1)
    ENDIF
    DO WHILE RIGHT$(TUIgetParent, 1) <> "/"
      TUIgetParent = LEFT$(TUIgetParent, LEN(TUIgetParent) - 1)
    LOOP      
  ENDIF
END FUNCTION

FUNCTION TUIfileSelect(path AS STRING, ext AS STRING) AS STRING
  '(almost) complete file selector

  CHDIR path
  LOCAL INTEGER fs = 1
  DO WHILE fs
    TUIfileSelect = TUIgetSelect(path, ext)
    IF TUIfileSelect = "<ROOT>" THEN
      path = "A:/"
      CHDIR path
    ELSEIF TUIfileSelect = "<UP>" THEN
      path = TUIgetParent(path)
      CHDIR path
    ELSEIF RIGHT$(TUIfileSelect, 6) = " <DIR>" THEN
      path = path + LEFT$(TUIfileSelect, LEN(TUIfileSelect) - 6) + "/"
      CHDIR path
    ELSE
      fs = 0
    ENDIF
  LOOP
END FUNCTION

FUNCTION TUIgetSelect(path AS STRING, ext AS STRING) AS STRING
  'once-shot file selector

  LOCAL STRING f
  LOCAL INTEGER i
  LOCAL INTEGER cnt, cntExt = -1

  FOR i = 1 TO LEN(ext)
    IF FIELD$(ext, i, ",") <> "" THEN INC cnt
  NEXT i
  IF cnt > 0 THEN
    LOCAL STRING ex(cnt)
    FOR i = 1 TO LEN(ext)
      IF FIELD$(ext, i, ",") <> "" THEN
        INC cntExt
        ex(cntExt) = UCASE$(FIELD$(ext, i, ","))
      ENDIF
    NEXT i
  ELSE
    ext = ""
  ENDIF

  cnt = 1
  f = DIR$("", ALL)
  DO WHILE f <> ""
    IF LEFT$(f, 1) <> "." THEN
      IF MM.INFO(FILESIZE f) < 0 THEN
        INC cnt
      ELSEIF ext = "" THEN
        INC cnt
      ELSE
        FOR i = 0 TO cntExt
          IF UCASE$(RIGHT$(f, LEN(ex(i)))) = ex(i) THEN
            INC cnt
            EXIT FOR
          ENDIF
        NEXT i
      ENDIF
    ENDIF
    f = DIR$()
  LOOP
  
  IF path <> "A:/" THEN
    INC cnt
  ENDIF
  LOCAL STRING fn(cnt)

  cnt = 1 
  fn(cnt) = "<ROOT>"
  IF path <> "A:/" THEN
    INC cnt
    fn(cnt) = "<UP>"
  ENDIF

  f = DIR$("", ALL)
  DO WHILE f <> ""
    IF LEFT$(f, 1) <> "." THEN
      IF MM.INFO(FILESIZE f) < 0 THEN
        INC cnt
        fn(cnt) = f + " <DIR>"
      ELSEIF ext = "" THEN
        INC cnt
        fn(cnt) = f
      ELSE
        FOR i = 0 TO cntExt
          IF UCASE$(RIGHT$(f, LEN(ex(i)))) = ex(i) THEN
            INC cnt
            fn(cnt) = f
            EXIT FOR
          ENDIF
        NEXT i
      ENDIF
    ENDIF
    f = DIR$()
  LOOP
  SORT fn(),,2
  TUIgetSelect = TUIgetItem("SELECT " + ext + " FILE", path, fn())
END FUNCTION

FUNCTION TUIinput(title AS STRING, txt AS STRING, def AS STRING, en AS STRING) AS STRING
  'Input string, returns text, DEL erase all, BACKSPACE 1 char, ENTER to finish (BLIT #6)
 
  FONT FONT.TUI
  LOCAL INTEGER fow = MM.INFO(FONTWIDTH)
  LOCAL INTEGER foh = MM.INFO(FONTHEIGHT)
  LOCAL INTEGER w = 4*fow + fow*MAX(LEN(title),LEN(txt),LEN(def),23) 'minimum 8 chars
  LOCAL INTEGER h = 6*foh, change = 0
  LOCAL STRING k = ""
  LOCAL INTEGER dx = (MM.HRES-w)\2, dy = (MM.VRES-h)\2 
  LOCAL INTEGER cursorX, cursorY, cursorON, cursorINT, charPos

  BLIT READ #6,dx,dy,w,h 

  TUIinput = def
  BOX dx+0,dy+0,w,h,0,BC.TUI,BC.TUI
  BOX dx+fow/4,dy+foh/2,w-fow/2,h-foh*3/4,2,FC.TUI,BC.TUI
  BOX dx+fow,dy+2.5*foh,w-2*fow,foh,0,IC.TUI, IC.TUI
  TEXT dx+w\2,dy+1," " + title + " ","CT",,,FC.TUI,BC.TUI

  TEXT dx+fow,dy+1+foh,txt,"LT",,,FC.TUI, BC.TUI
  TEXT dx+fow,dy+2.5*foh,def,"LT",,,FC.TUI,IC.TUI
  TEXT dx+fow,dy+h-3/2*foh,"Cancel","LT",,,BC.TUI,FC.TUI
  TEXT dx+w - fow,dy+h-3/2*foh,"  OK  ","RT",,,BC.TUI,FC.TUI
  ON.TUI = 1: X.TUI = dx: Y.TUI = dy: W.TUI = w: H.TUI = h 'for screenshot

  cursorX = dx+LEN(def)*fow: cursorY = dy+3.5*foh
  IF LEN(def) < ((w-2*fow)\fow) THEN INC cursorX, fow

  cursorON = 0: cursorINT = TIMER  
  DO
    IF TIMER-cursorINT > CURSOR_SPEED.TUI THEN
      cursorON = 1 - cursorON
      IF cursorON THEN
        LINE cursorX, cursorY, cursorX + fow, cursorY,2,FC.TUI
      ELSE
        LINE cursorX, cursorY, cursorX + fow, cursorY,2,BC.TUI
      ENDIF
      cursorINT = TIMER
    ENDIF
    k = INKEY$
    
    SELECT CASE k
      CASE CHR$(160)  'SHIFT DEL, delete all
        TUIinput = ""
        change = 1
        LINE cursorX, cursorY, cursorX + fow, cursorY,2,BC.TUI
        cursorX = dx + fow
         
      CASE CHR$(8)    'BACKSPACE, delete left character
        charPos = (cursorX - dx)\fow          
        IF TUIinput<>"" AND charPos > 1 THEN
          TUIinput = LEFT$(TUIinput, charPos - 2) + MID$(TUIinput, charPos)
          LINE cursorX, cursorY, cursorX + fow, cursorY,2,BC.TUI
          INC cursorX, -fow
          change = 1
        ENDIF

      CASE CHR$(127)    'DEL, delete right character
        charPos = (cursorX - dx)\fow          
        IF charPos <= LEN(TUIinput) THEN
          TUIinput = LEFT$(TUIinput, charPos - 1) + MID$(TUIinput, charPos + 1)
          change = 1
        ENDIF

      CASE CHR$(130)    'LEFT
        IF cursorX > dx + fow THEN
          LINE cursorX, cursorY, cursorX + fow, cursorY,2,BC.TUI
          INC cursorX, -fow
        ENDIF

      CASE CHR$(131)    'RIGHT
        IF cursorX <= dx + fow*LEN(TUIinput) THEN
          LINE cursorX, cursorY, cursorX + fow, cursorY,2,BC.TUI
          INC cursorX, fow
          IF cursorX > dx+w-2*fow THEN
            INC cursorX, -fow
          ENDIF
        ENDIF

      CASE ELSE
        IF INSTR(en,k)>0 THEN
          charPos = (cursorX - dx)\fow          
          IF LEN(TUIinput) < (w\fow - 2) THEN
            TUIinput = LEFT$(TUIinput, charPos - 1) + k + MID$(TUIinput, charPos)
            change = 1
            LINE cursorX, cursorY, cursorX + fow, cursorY,2,BC.TUI
            IF cursorX < dx+w-2*fow THEN
              INC cursorX, fow
            ENDIF
          ENDIF
        ENDIF
    END SELECT

    IF change THEN
      BOX dx+fow,dy+2.5*foh,w-2*fow,foh,0,IC.TUI, IC.TUI
      TEXT dx+fow,dy+2.5*foh,TUIinput,"LT",,,FC.TUI,IC.TUI
      change = 0
    ENDIF
  LOOP WHILE k<>ESC.TUI AND k<>ENTER.TUI 
  ON.TUI = 0  
  BLIT WRITE #6,dx,dy
  BLIT CLOSE #6
  IF k=ESC.TUI THEN TUIinput = ""
END FUNCTION

FUNCTION TUIemptyON(title AS STRING, ww AS INTEGER, hh AS INTEGER, but AS STRING) AS STRING
  'Shows empty dialog (space), returns coordinates as string "X,Y" (BLIT #9)
  'if but is used, then is show instead of "OK"

  FONT FONT.TUI
  LOCAL STRING button = but
  IF button = "" THEN button = "  OK  "
  LOCAL INTEGER fow = MM.INFO(FONTWIDTH)
  LOCAL INTEGER w = MAX(4 * fow + fow * LEN(title), 2 * fow + ww, fow*(4+LEN(button))) 'minimum width
  LOCAL INTEGER foh = MM.INFO(FONTHEIGHT)
  LOCAL INTEGER h = 3 * foh + hh 'height

  
  LOCAL INTEGER dx = (MM.HRES-w)\2, dy = (MM.VRES-h)\2 
  
  BLIT READ #9,dx,dy,w,h 
  BOX dx+0,dy+0,w,h,0,BC.TUI,BC.TUI
  BOX dx+fow/4,dy+foh/2,w-fow/2,h-foh*3/4,2,FC.TUI,BC.TUI
  TEXT dx+w\2,dy+1," " + title + " ","CT",,,FC.TUI,BC.TUI
  TEXT dx+w\2,dy+h-3/2*foh,button,"CT",,,BC.TUI,FC.TUI
  ON.TUI = 1: X.TUI = dx: Y.TUI = dy: W.TUI = w: H.TUI = h 'for screenshot

  TUIemptyON = STR$(dx) + "," + STR$(dy) + "," + STR$(dx + fow) + "," + STR$(dy + foh + 1)
END FUNCTION

SUB TUIemptyOFF(coord AS STRING)
  'Close empty (BLIT #9)

  LOCAL INTEGER dx = VAL(FIELD$(coord,1,","))
  LOCAL INTEGER dy = VAL(FIELD$(coord,2,","))

  ON.TUI = 0  
  BLIT WRITE #9, dx, dy
  BLIT CLOSE #9
END SUB


