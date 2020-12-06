'Simple TUI, it's prepared for screenshoting
CONST VERSION.TUI = "0.10"
DIM INTEGER ON.TUI, X.TUI, Y.TUI, W.TUI, H.TUI 

CONST CURSOR_SPEED.TUI = 300 'cursor blinking speed in ms
CONST ESC.TUI = CHR$(27), ENTER.TUI = CHR$(10)
CONST TICK.TUI = CHR$(232)

SUB TUIinfo(title AS STRING, txt() AS STRING, logo AS INTEGER)
  'Shows more lines of info text (BLIT #1)

  LOCAL INTEGER w = 16, h = 16, i
  LOCAL INTEGER b = RGB(YELLOW), f = RGB(GRAY)
  LOCAL INTEGER m = BOUND(txt())
 
  FOR i = 0 TO m
    IF LEN(txt(i)) > 98 THEN txt(i) = LEFT$(txt(i),98)
    w = MAX(16+8*LEN(txt(i)), w)
  NEXT i
  h = m*16+70
  LOCAL INTEGER dx = (MM.HRES-w)\2, dy = (MM.VRES-h)\2 

  BLIT READ #1,dx,dy,w,h 
  BOX dx,dy,w,h,0,b,b
  BOX dx+3,dy+8,w-6,h-11,2,f,b
  TEXT dx+w\2,dy+1," " + title + " ","CT",8,,f,b
  FOR i = 0 TO m
    TEXT dx+8,dy+24+i*16,txt(i),"LT",8,,f,b
  NEXT i
  TEXT dx+w\2,dy+h-24,"  OK  ","CT",8,,b,f
  ON.TUI = 1: X.TUI = dx: Y.TUI = dy: W.TUI = w: H.TUI = h 'for screenshot
  
  IF logo THEN BLIT WRITE logo, dx+8, dy+20

  DO:LOOP WHILE INKEY$="" 
  DO:LOOP WHILE INKEY$<>"" 
  ON.TUI = 0  
  BLIT WRITE #1,dx,dy
  BLIT CLOSE #1
END SUB

FUNCTION TUIwaitingON(title AS STRING) AS STRING
  'Start progress, returns coordinates as string "X,Y" (BLIT #2)

  CONST txt = "Please wait..."
  LOCAL INTEGER w = 32 + MAX(8*LEN(title), 8*LEN(txt)) 'minimum width
  LOCAL INTEGER h = 48
  LOCAL INTEGER b = RGB(YELLOW), f = RGB(GRAY)
  LOCAL INTEGER dx = (MM.HRES-w)\2, dy = (MM.VRES-h)\2 
  
  BLIT READ #2,dx,dy,w,h 
  BOX dx,dy,w,h,0,b,b
  BOX dx+3,dy+8,w-6,h-11,2,f,b
  TEXT dx+w\2,dy+1," " + title + " ","CT",8,,f,b
  TEXT dx+w\2,dy+24,txt,"CT",8,,f,b
  ON.TUI = 1: X.TUI = dx: Y.TUI = dy: W.TUI = w: H.TUI = h 'for screenshot

  TUIwaitingON = STR$(dx) + "," + STR$(dy) + "," + STR$(w) + "," + STR$(h)
END FUNCTION

SUB TUIwaitingProgress(coord AS STRING, perc AS INTEGER)
  'Draw progress into waiting dialog

  LOCAL INTEGER dx = VAL(FIELD$(coord,1,","))
  LOCAL INTEGER dy = VAL(FIELD$(coord,2,","))
  LOCAL INTEGER w = VAL(FIELD$(coord,3,","))
  LOCAL INTEGER h = VAL(FIELD$(coord,4,","))
  
  BOX dx + w \ 2 - 50, dy + 18, 100, 4, 1, RGB(BLACK)
  BOX dx + w \ 2 - 50, dy + 18, MAX(MIN(perc, 100), 0), 4, 0, RGB(BLACK), RGB(BLACK)
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
  
  LOCAL INTEGER w = 16 + 8*MAX(4+LEN(title),13) 'minimum 13 chars
  LOCAL INTEGER i,cnt = 0, h = 80
  LOCAL INTEGER b = RGB(YELLOW), f = RGB(GRAY)
  LOCAL STRING k, keysEnabled = "0123456789"
  
  DO WHILE FIELD$(txt, cnt+1, ",") <> ""
    cnt = cnt + 1
  LOOP
  cnt = MIN(cnt, 10)

  keysEnabled = LEFT$(keysEnabled, cnt) + ESC.TUI

  h = 16*cnt + 64
  FOR i = 1 TO cnt
    w = MAX(w, 8*(LEN(FIELD$(txt, i, ","))+6))
  NEXT i
  LOCAL INTEGER dx = (MM.HRES-w)\2, dy = (MM.VRES-h)\2 
  
  BLIT READ #3,dx,dy,w,h 
  BOX dx,dy,w,h,0,b,b
  BOX dx+3,dy+8,w-6,h-11,2,f,b
  TEXT dx+w\2,dy+1," " + title + " ","CT",8,,f,b
  FOR i = 1 TO cnt
    TEXT dx+8,dy+8+i*16," " + STR$(i-1) + " " + FIELD$(txt, i, ","),"LT",8,,f,b
  NEXT i
  TEXT dx+w\2,dy+h-24," Press 0-" + STR$(cnt-1) + " ","CT",8,,b,f
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

  LOCAL INTEGER w = 16 + 8*MAX(4+LEN(title),LEN(txt),8) 'minimum 8 chars
  LOCAL INTEGER h = 80
  LOCAL INTEGER b = RGB(YELLOW), f = RGB(GRAY)
  
  IF w>800 THEN
    w = 800
    title = LEFT$(title, MIN(LEN(title),98))
    txt = LEFT$(txt, MIN(LEN(txt),98))
  ENDIF
  LOCAL INTEGER dx = (MM.HRES-w)\2, dy = (MM.VRES-h)\2 
  
  BLIT READ #4,dx,dy,w,h 
  BOX dx+0,dy+0,w,h,0,b,b
  BOX dx+3,dy+8,w-6,h-11,2,f,b
  TEXT dx+w\2,dy+1," " + title + " ","CT",8,,f,b
  TEXT dx+w\2,dy+24,txt,"CT",8,,f,b
  TEXT dx+w\2,dy+h-24,"  OK  ","CT",8,,b,f
  ON.TUI = 1: X.TUI = dx: Y.TUI = dy: W.TUI = w: H.TUI = h 'for screenshot

  DO:LOOP WHILE INKEY$="" 
  DO:LOOP WHILE INKEY$<>"" 
  ON.TUI = 0  
  BLIT WRITE #4,dx,dy
  BLIT CLOSE #4
END SUB

FUNCTION TUIquestion(title AS STRING, txt AS STRING) AS INTEGER
  'Question, returns 1 when OK (ENTER) was pressed, 0 else (BLIT #5)

  LOCAL INTEGER w = 16 + 8*MAX(4+LEN(title),LEN(txt),8) 'minimum 8 chars
  LOCAL INTEGER h = 80
  LOCAL STRING k = ""
  LOCAL INTEGER b = RGB(YELLOW), f = RGB(GRAY)
  LOCAL INTEGER dx = (MM.HRES-w)\2, dy = (MM.VRES-h)\2 

  BLIT READ #5,dx,dy,w,h 
  BOX dx,dy,w,h,0,b,b
  BOX dx+3,dy+8,w-6,h-11,2,f,b
  TEXT dx+w\2,dy+1," " + title + " ","CT",8,,f,b
  TEXT dx+w\2,dy+24,txt,"CT",8,,f,b
  TEXT dx+8,dy+h-24,"Cancel","LT",8,,b,f
  TEXT dx+w-8,dy+h-24,"  OK  ","RT",8,,b,f
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

FUNCTION TUIinput(title AS STRING, txt AS STRING, def AS STRING, en AS STRING) AS STRING
  'Input string, returns text, DEL erase all, BACKSPACE 1 char, ENTER to finish (BLIT #6)
 
  LOCAL INTEGER w = 16 + 8*MAX(4+LEN(title),LEN(txt),LEN(def),23) 'minimum 8 chars
  LOCAL INTEGER h = 100, change = 0
  LOCAL STRING k = ""
  LOCAL INTEGER b = RGB(YELLOW), f = RGB(GRAY)
  LOCAL INTEGER dx = (MM.HRES-w)\2, dy = (MM.VRES-h)\2 
  LOCAL INTEGER cursorX, cursorY, cursorON, cursorINT

  BLIT READ #6,dx,dy,w,h 

  TUIinput = def
  BOX dx,dy,w,h,0,b,b
  BOX dx+3,dy+8,w-6,h-11,2,f,b
  BOX dx+8,dy+40,w-16,16,0,RGB(CYAN),RGB(CYAN)
  TEXT dx+w\2,dy+1," " + title + " ","CT",8,,f,b
  TEXT dx+8,dy+22,txt,"LT",8,,f,b
  TEXT dx+8,dy+40,def,"LT",8,,f,RGB(CYAN)
  TEXT dx+8,dy+h-24,"Cancel","LT",8,,b,f
  TEXT dx+w-8,dy+h-24,"  OK  ","RT",8,,b,f
  ON.TUI = 1: X.TUI = dx: Y.TUI = dy: W.TUI = w: H.TUI = h 'for screenshot

  cursorX = dx+LEN(def)*8: cursorY = dy+56
  IF LEN(def) < ((w-16)\8) THEN INC cursorX, 8

  cursorON = 0: cursorINT = TIMER  
  DO
    IF TIMER-cursorINT > CURSOR_SPEED.TUI THEN
      cursorON = 1 - cursorON
      IF cursorON THEN
        TEXT cursorX, cursorY, CHR$(223), "LT",8 ,, f, b
      ELSE
        TEXT cursorX, cursorY, " ", "LT",8 ,, f, b
      ENDIF
      cursorINT = TIMER
    ENDIF
    k = INKEY$
    
    SELECT CASE k
      CASE CHR$(127)  'DEL, delete all
        TUIinput = ""
        change = 1
        TEXT cursorX, cursorY, " ", "LT",8 ,, f, b
        cursorX = dx + 8
         
      CASE CHR$(8)    'BACKSPACE, delete last character
        IF TUIinput<>"" THEN
          IF LEN(TUIinput) < ((w-16)\8) THEN
            TEXT cursorX, cursorY, " ", "LT",8 ,, f, b
            INC cursorX, - 8
          ENDIF
          TUIinput = LEFT$(TUIinput, LEN(TUIinput) - 1)
          change = 1
        ENDIF

      CASE ELSE
        IF INSTR(en,k)>0 THEN
          IF LEN(TUIinput) < ((w-16)\8) THEN
            TUIinput = TUIinput + k
            change = 1
            TEXT cursorX, cursorY, " ", "LT",8 ,, f, b
            IF LEN(TUIinput) < ((w-16)\8) THEN
              INC cursorX, 8
            ENDIF
          ELSE
            TUIinput = LEFT$(TUIinput, LEN(TUIinput)-1) + k
            change = 1
          ENDIF
        ENDIF
    END SELECT

    IF change THEN
      BOX dx+8,dy+40,w-16,16,0,RGB(CYAN),RGB(CYAN)
      TEXT dx+8,dy+40,TUIinput,"LT",8,,f,RGB(CYAN)
      change = 0
    ENDIF
  LOOP WHILE k<>ESC.TUI AND k<>ENTER.TUI 
  ON.TUI = 0  
  BLIT WRITE #6,dx,dy
  BLIT CLOSE #6
  IF k=ESC.TUI THEN TUIinput = ""
END FUNCTION

FUNCTION TUIselect(title AS STRING, txt AS STRING, s AS INTEGER) AS INTEGER
  'Selection checkbox, can select up to 10 choices with keys 0-9 (BLIT #7)
  
  LOCAL INTEGER w = 16 + 8*MAX(4+LEN(title),13) 'minimum 13 chars
  LOCAL INTEGER i,cnt = 0, h = 80, retStr = s
  LOCAL INTEGER b = RGB(YELLOW), f = RGB(GRAY)
  LOCAL STRING k, keysEnabled = "0123456789"
  LOCAL STRING mark

  DO WHILE FIELD$(txt, cnt+1, ",") <> ""
    cnt = cnt + 1
  LOOP
  cnt = MIN(cnt, 10)

  keysEnabled = LEFT$(keysEnabled, cnt) + ESC.TUI + ENTER.TUI

  h = 16*cnt + 80
  FOR i = 1 TO cnt
    w = MAX(w, 8*(LEN(FIELD$(txt, i, ","))+7))
  NEXT i
  LOCAL INTEGER dx = (MM.HRES-w)\2, dy = (MM.VRES-h)\2 
  
  BLIT READ #7,dx,dy,w,h 
  BOX dx,dy,w,h,0,b,b
  BOX dx+3,dy+8,w-6,h-11,2,f,b
  TEXT dx+w\2,dy+1," " + title + " ","CT",8,,f,b
  FOR i = 1 TO cnt
    IF s AND (1 << (i-1)) THEN
      mark = TICK.TUI
    ELSE
      mark = " "
    ENDIF
    TEXT dx+8,dy+8+i*16," " + STR$(i-1) + " " + mark + " " + FIELD$(txt, i, ","),"LT",8,,f,b
  NEXT i
  TEXT dx+w\2,dy+h-42," Set/Unset with 0-" + STR$(cnt-1) + " ","CT",8,,f,b
  TEXT dx+w\2,dy+h-24," OK ","CT",8,,b,f
  ON.TUI = 1: X.TUI = dx: Y.TUI = dy: W.TUI = w: H.TUI = h 'for screenshot

  DO
    DO
      k = INKEY$
    LOOP WHILE INSTR(keysEnabled,k)=0 
    DO:LOOP WHILE INKEY$<>""
    IF ASC(k)>47 THEN
      retStr = retStr XOR (1<<(ASC(k)-48))
      IF retStr AND (1<<(ASC(k)-48)) THEN
        TEXT dx+32,dy+8+(ASC(k)-47)*16, TICK.TUI,"LT",8,,f,b        
      ELSE
        TEXT dx+32,dy+8+(ASC(k)-47)*16, " ","LT",8,,f,b        
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

SUB TUIwaitForNoKey
  DO:LOOP WHILE INKEY$<>""
END SUB

FUNCTION TUIgetItem(title AS STRING, txt() AS STRING) AS STRING
  'Shows more lines of text (BLIT #1) and let the user select one

  CONST maxItems = 5
  LOCAL INTEGER w = 32 + 8 * LEN(title), h = 16, i
  LOCAL INTEGER b = RGB(YELLOW), f = RGB(GRAY)
  LOCAL INTEGER m = BOUND(txt()), curs = 0, position = 0
  LOCAL INTEGER pbLen = (1 + maxItems) ^ 2 / (1 + m) * 16, ww = 0
  LOCAL INTEGER pbPos = pbLen / (1 + maxItems), running = 1, prev = -1, prevCurs = -1
  LOCAL STRING k

  TUIgetItem = ""

  FOR i = 0 TO m
    IF LEN(txt(i)) > 98 THEN txt(i) = LEFT$(txt(i),98)
    ww = MAX(ww, LEN(txt(i)))
  NEXT i
  w = MAX(24+8*ww, w)
  h = MIN(maxItems, m) * 16+70
  LOCAL INTEGER dx = (MM.HRES-w)\2, dy = (MM.VRES-h)\2 

  BLIT READ #1,dx,dy,w,h 
  BOX dx,dy,w,h,0,b,b
  BOX dx+3,dy+8,w-6,h-11,2,f,b
  TEXT dx+w\2,dy+1," " + title + " ","CT",8,,f,b
  TEXT dx+8,dy+h-24,"Cancel","LT",8,,b,f
  TEXT dx+w-8,dy+h-24,"  OK  ","RT",8,,b,f
  ON.TUI = 1: X.TUI = dx: Y.TUI = dy: W.TUI = w: H.TUI = h 'for screenshot

  DO WHILE running
    IF position <> prev OR curs <> prevCurs THEN
      FOR i = 0 TO MIN(m, maxItems)
        IF i+position = curs THEN
          TEXT dx+8,dy+24+i*16,txt(position + i) + SPACE$(ww - LEN(txt(position + i))),"LT",8,,b,f
          TUIgetItem = txt(position + i)
        ELSE
          TEXT dx+8,dy+24+i*16,txt(position + i) + SPACE$(ww - LEN(txt(position + i))),"LT",8,,f,b
        ENDIF
      NEXT i
      IF m > maxItems THEN
        BOX dx + w - 12, dy + 24, 4, (1 + maxItems) * 16, 1, RGB(BLACK), RGB(YELLOW)
        BOX dx + w - 11, dy + 24 + position * pbPos, 2, pbLen, 0, RGB(BLACK), RGB(BLACK)
      ENDIF
      prev = position
      prevCurs = curs
    ENDIF
    k = INKEY$
    IF k <> "" THEN
      SELECT CASE k
      CASE CHR$(128) 'up
        IF curs > position THEN
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
  BLIT WRITE #1,dx,dy
  BLIT CLOSE #1
END FUNCTION

