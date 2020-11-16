OPTION EXPLICIT
OPTION DEFAULT NONE
OPTION BASE 0

CONST VERSION = "0.2"

CONST FILECHARS.NC = "abcdefghijklmnopqrstuvxyzABCDEFGHIJKLMNOPQRSTUVXYZ0123456789()_-."

CONST MAX_ITEMS.NC = 500 'max number of items in pane
CONST MAX_ROWS.NC = 32   'max row in list display
DIM STRING SELECTED.NC   'current selected item
DIM STRING CUR_PATH.NC = NCgetPath(MM.INFO$(CURRENT))     'current path
DIM STRING MANUAL.NC = CUR_PATH.NC + "MANUAL.TXT"
DIM STRING MENU.NC(11) LENGTH 7 'menu
DIM INTEGER EN_MENU.NC(11)      'menu enabled
DIM INTEGER CURSOR.NC(1)        'cursor position in pane
DIM INTEGER POS.NC(1)           'items list position in pane
DIM INTEGER COUNT.NC(1)         'number of items in pane
DIM STRING PATH.NC(1)           'current path in pane
DIM STRING ITEM.NC(1, MAX_ITEMS.NC) 'items storage

DIM INTEGER ACTIVE.NC = 0 '0 cursor on left

CONST CURSOR_TIME = 300   'NCinput cursor blink speed in ms
DIM INTEGER CURSOR_X.NC, CURSOR_Y.NC, CURSOR_ON.NC, CURSOR_INT.NC = 0 'cursor position

DIM INTEGER HLP.NC        'temporary integer var
DIM INTEGER HIDDEN.NC = 0 'not show hidden files
DIM STRING STR.NC         'temporary string var

NCinit

NCchangeDir(0,"A:/")
NCchangeDir(1,"A:/")
NCdrawCL(PATH.NC(ACTIVE.NC))

NCcursor(0,1)

ON KEY NCkey
DO:LOOP
END

SUB NCkey
  'main SUB for key control

  SELECT CASE KEYDOWN(1)
    CASE 128  'up
      NCup
  
    CASE 129  'down
      NCdown

    CASE 9    'TAB
      NCcursor(ACTIVE.NC,0)
      ACTIVE.NC = 1 - ACTIVE.NC
      NCcursor(ACTIVE.NC,1)

    CASE 10   'ENTER
      SELECTED.NC = FIELD$(ITEM.NC(ACTIVE.NC,CURSOR.NC(ACTIVE.NC)+POS.NC(ACTIVE.NC)),1,"|") 
      IF LEFT$(SELECTED.NC,1) = "D" THEN
        NCcursor(ACTIVE.NC,0)
        PATH.NC(ACTIVE.NC) = NCchangePath(PATH.NC(ACTIVE.NC), MID$(SELECTED.NC,2))
        NCchangeDir(ACTIVE.NC,PATH.NC(ACTIVE.NC))
        NCdrawCL(PATH.NC(ACTIVE.NC))
        NCcursor(ACTIVE.NC,1)
      ELSE
        NCaction(PATH.NC(ACTIVE.NC), SELECTED.NC)
      ENDIF

    CASE 145  'F1
      IF EN_MENU.NC(0) THEN
        NChelp
      ENDIF

    CASE 146  'F2
      IF EN_MENU.NC(1) THEN
        IF SELECTED.NC <> "D.." THEN
          IF LEFT$(SELECTED.NC,1)="D" THEN
            NCwaitingON("GET SIZE")
            HLP.NC = NCmeasure(CUR_PATH.NC+MID$(SELECTED.NC,2))
            NCwaitingOFF     
            NCwarning("GET SIZE","'"+MID$(SELECTED.NC,2)+"' has "+STR$(HLP.NC>>16,0,0)+" bytes in " + STR$(HLP.NC AND &hFFFF,0,0)+" items")
          ELSE
            HLP.NC = MM.INFO(FILESIZE CUR_PATH.NC+MID$(SELECTED.NC,2))
            NCwarning("GET SIZE","'"+MID$(SELECTED.NC,2)+"' has "+STR$(HLP.NC,0,0)+" bytes")
          ENDIF
        ENDIF
      ENDIF

    CASE 147  'F3
      IF EN_MENU.NC(2) THEN
        IF LEFT$(SELECTED.NC,1)="F" THEN
          NCview
        ENDIF
      ENDIF

    CASE 148  'F4
      IF EN_MENU.NC(3) THEN
        NCwarning("WARNING","Pressed F4")
      ENDIF

    CASE 149  'F5
      IF EN_MENU.NC(4) THEN
        IF PATH.NC(0)=PATH.NC(1) THEN
          'COPY as new name
          STR.NC = NCinput("COPY AS","New name for '"+MID$(SELECTED.NC,2)+"'",NCnewName(PATH.NC(1-ACTIVE.NC),MID$(SELECTED.NC,2)),FILECHARS.NC)
          IF STR.NC <> MID$(SELECTED.NC,2) AND STR.NC <> "" THEN
            IF LEFT$(SELECTED.NC,1)="F" THEN
              NCcopyFile(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2),PATH.NC(1-ACTIVE.NC)+STR.NC,1)     
            ELSE
              NCcopyDir(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2)+"/",PATH.NC(1-ACTIVE.NC)+STR.NC+"/",1)     
            ENDIF
          ENDIF                  

        ELSE
          IF LEFT$(SELECTED.NC,1)="D" THEN
            'COPY DIR
            IF NCquestion("COPY DIR", "Copy '"+MID$(SELECTED.NC,2)+"' to '"+PATH.NC(1-ACTIVE.NC)+"'?") THEN
              NCcopyDir(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2)+"/",PATH.NC(1-ACTIVE.NC)+MID$(SELECTED.NC,2)+"/")     
            ENDIF
          ELSE
            'COPY FILE
            IF NCquestion("COPY FILE", "Copy '"+MID$(SELECTED.NC,2)+"' to '"+PATH.NC(1-ACTIVE.NC)+"'?") THEN
              NCcopyFile(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2),PATH.NC(1-ACTIVE.NC)+MID$(SELECTED.NC,2))
            ENDIF
          ENDIF
        ENDIF        
      ENDIF

    CASE 150  'F6
      IF EN_MENU.NC(5) THEN
        IF PATH.NC(0)=PATH.NC(1) THEN 'RENAME
          NCrenameItem
        
        ELSE 'MOVE
          IF LEFT$(SELECTED.NC,1)="D" THEN
            'MOVE DIR
            IF NCquestion("MOVE DIR", "Move '"+MID$(SELECTED.NC,2)+"' to '"+PATH.NC(1-ACTIVE.NC)+"'?") THEN
              'NCcopyDir(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2)+"/",PATH.NC(1-ACTIVE.NC)+MID$(SELECTED.NC,2)+"/")     
              'NCdeleteDir(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2))
              'IF INSTR(PATH.NC(0),PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2))>0 THEN
              '  PATH.NC(0) = NCparrent(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2))
              'ENDIF
              'IF INSTR(PATH.NC(1),PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2))>0 THEN
              '  PATH.NC(1) = NCparrent(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2))
              'ENDIF
              'NCchangeDir(0,PATH.NC(0))
              'NCchangeDir(1,PATH.NC(1))
              'NCcursor(ACTIVE.NC,1)
            ENDIF
            
          ELSE
            'MOVE FILE
            NCmoveFile(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2),PATH.NC(1-ACTIVE.NC)+MID$(SELECTED.NC,2))
          ENDIF
        ENDIF        
      ENDIF

    CASE 151  'F7
      IF EN_MENU.NC(6) THEN
        STR.NC = NCinput("MAKE NEW DIRECTORY","Directory name:","NewDir", FILECHARS.NC)
        IF STR.NC<>"" THEN
          ON ERROR SKIP
          MKDIR CUR_PATH.NC+STR.NC
          IF MM.ERRNO THEN 
            NCerror("MakeDir '" + STR.NC + "' ERROR")
          ELSE
            NCchangeDir(0,PATH.NC(0))
            NCchangeDir(1,PATH.NC(1))
            NCcursor(ACTIVE.NC,1)
          ENDIF
        ENDIF
      ENDIF

    CASE 152  'F8, DEL 127 is sometimes stuck...
      IF EN_MENU.NC(7) THEN
        NCdelete
      ENDIF

    CASE 153  'F9

    CASE 154  'F10
      IF EN_MENU.NC(9) THEN
        IF NCquestion("QUIT", "Are you redy to leave me alone?") THEN
          CHDIR PATH.NC(ACTIVE.NC)
          CLS
          END
        ENDIF
      ENDIF

    CASE 155  'F11
      IF EN_MENU.NC(10) THEN
        NCwarning("WARNING","Pressed F11")
      ENDIF

    CASE 156  'F12
      IF EN_MENU.NC(11) THEN
        NCchangeDir(1-ACTIVE.NC,PATH.NC(ACTIVE.NC))        
      ENDIF

    CASE ASC("H"), ASC("h")
      HIDDEN.NC = 1 - HIDDEN.NC
      NCdrawMenu
      NCchangeDir(0,PATH.NC(0))
      NCchangeDir(1,PATH.NC(1))
      NCcursor(ACTIVE.NC,1)


    CASE 134  'HOME
      NChome
      
    CASE 135  'END
      NCend

  END SELECT
END SUB

FUNCTION NCnewName(p AS STRING, n AS STRING) AS STRING
  'smart new name for MOVE into same directory

  LOCAL STRING na = NCgetNoExtension(n), ex = NCgetExtension(n)
  LOCAL INTEGER num = 1
  IF ex = "" THEN
    DO WHILE NCexist(p + na + STR$(num))
      num = num + 1
    LOOP
    NCnewName = na + STR$(num)
  ELSE
    DO WHILE NCexist(p + na + STR$(num) + "." + ex)
      num = num + 1
    LOOP
    NCnewName = na + STR$(num) + "." + ex
  ENDIF
END FUNCTION

FUNCTION NCexist(fullPath as STRING) AS INTEGER
  'exists this file?

  NCexist = DIR$(fullPath, ALL) <> ""
END FUNCTION

FUNCTION NCparrent(p AS STRING) AS STRING
  'get parrent folder

  NCparrent = p
  IF RIGHT$(NCparrent,1)="/" THEN NCparrent = LEFT$(NCparrent,LEN(NCparrent)-1)
  DO WHILE RIGHT$(NCparrent,1)<>"/"
    NCparrent = LEFT$(NCparrent,LEN(NCparrent)-1)
  LOOP
END FUNCTION

SUB NCdelete
  'delete item

  IF NCquestion("DELETE", "Delete '" + MID$(SELECTED.NC,2) + "', really proceed?") THEN
    IF LEFT$(SELECTED.NC,1)="D" THEN
      ON ERROR SKIP
      RMDIR CUR_PATH.NC+MID$(SELECTED.NC,2)
      IF MM.ERRNO THEN 
        NCdeleteDir(CUR_PATH.NC+MID$(SELECTED.NC,2))
        IF INSTR(PATH.NC(0),CUR_PATH.NC+MID$(SELECTED.NC,2))>0 THEN
          PATH.NC(0) = NCparrent(CUR_PATH.NC+MID$(SELECTED.NC,2))
        ENDIF
        IF INSTR(PATH.NC(1),CUR_PATH.NC+MID$(SELECTED.NC,2))>0 THEN
          PATH.NC(1) = NCparrent(CUR_PATH.NC+MID$(SELECTED.NC,2))
        ENDIF

      ENDIF
    ELSE
      ON ERROR SKIP
      KILL CUR_PATH.NC+MID$(SELECTED.NC,2)
      IF MM.ERRNO THEN NCerror("DELETE '" + MID$(SELECTED.NC,2) + "' ERROR")
    ENDIF
    NCchangeDir(0,PATH.NC(0))
    NCchangeDir(1,PATH.NC(1))
    NCcursor(ACTIVE.NC,1)
  ENDIF
END SUB

SUB NChelp
  'show help

  LOCAL STRING txt = "About NC,Shortcuts,Manual"
  LOCAL INTEGER h = NCselect("CHOOSE SECTION", txt)
  SELECT CASE h
    CASE <0 'ESC
      'NCwarning("HELP","You was no able to choose :-(")

    CASE 0
      LOCAL STRING about(3) LENGTH 100
      about(0) = "My name is 'Napoleon Commander' (v" + VERSION+")"
      about(1) = ""
      about(2) = " I was developed by JirSoft, Nov/2020"
      about(1) = ""
      NCinfo("ABOUT ME",about())
      
    CASE 1
      LOCAL STRING shrt(20) LENGTH 100
      shrt( 0) = "Napoleon Commander v" + VERSION
      shrt( 1) = ""
      shrt( 2) = "Up/Down  Move row on active pane"
      shrt( 3) = "Home/End Jump to first/last row"
      shrt( 4) = "TAB      Switch active pane"
      shrt( 5) = "ENTER    Change active directory or invoke action"
      shrt( 6) = "H        Show or hide hidden files"
      shrt( 7) = ""
      shrt( 8) = "F1       Show this help"
      shrt( 9) = "F2       Calculate item size"
      shrt(10) = "F3       Quick (& dirty) file viewer"
      shrt(11) = "F4       Quick editor (not done yet)"
      shrt(12) = "F5       Copy file or directory"
      shrt(13) = "F6       Move or rename (if both panes are same)"
      shrt(14) = "F7       Create new directory"
      shrt(15) = "F8       Delete file or directory"
      shrt(16) = "F9       RESERVED (for TAR?)"
      shrt(17) = "F10      Quit"
      shrt(18) = "F11      RESERVED"
      shrt(19) = "F12      Duplicate view to inactive pane"
      shrt(20) = ""
  
      NCinfo("SHORTCUTs",shrt())
      
    CASE 2
      NCviewTXT(MANUAL.NC)

    CASE ELSE
      NCwarning("HELP","Choosen '" + FIELD$(txt,h+1,",") + "', but section still missing...")

  END SELECT
END SUB

SUB NCend
  'END pressed

  IF CURSOR.NC(ACTIVE.NC) < MIN(MAX_ROWS.NC, COUNT.NC(ACTIVE.NC)) THEN
    NCcursor(ACTIVE.NC,0)
    CURSOR.NC(ACTIVE.NC) = MIN(MAX_ROWS.NC, COUNT.NC(ACTIVE.NC))
    NCcursor(ACTIVE.NC,1)
  ENDIF
END SUB

SUB NChome
  'HOME pressed

  IF CURSOR.NC(ACTIVE.NC) > 0 THEN
    NCcursor(ACTIVE.NC,0)
    CURSOR.NC(ACTIVE.NC) = 0
    NCcursor(ACTIVE.NC,1)
  ENDIF
END SUB

SUB NCdown
  'DOWN pressed

  IF CURSOR.NC(ACTIVE.NC) < MAX_ROWS.NC THEN
    IF CURSOR.NC(ACTIVE.NC) < COUNT.NC(ACTIVE.NC) THEN
      NCcursor(ACTIVE.NC,0)
      CURSOR.NC(ACTIVE.NC) = CURSOR.NC(ACTIVE.NC) + 1
      NCcursor(ACTIVE.NC,1)
    ENDIF
  ELSE
    IF CURSOR.NC(ACTIVE.NC) + POS.NC(ACTIVE.NC) < COUNT.NC(ACTIVE.NC) THEN
      NCcursor(ACTIVE.NC,0)
      POS.NC(ACTIVE.NC) = POS.NC(ACTIVE.NC) + 1
      BLIT 400*ACTIVE.NC+8,32,400*ACTIVE.NC+8,16,384,16*MAX_ROWS.NC
      NCcursor(ACTIVE.NC,1)
    ENDIF
  ENDIF
END SUB

SUB NCup
  'UP pressed

  IF CURSOR.NC(ACTIVE.NC) > 0 THEN
    NCcursor(ACTIVE.NC,0)
    CURSOR.NC(ACTIVE.NC) = CURSOR.NC(ACTIVE.NC) - 1
    NCcursor(ACTIVE.NC,1)
  ELSE
    IF POS.NC(ACTIVE.NC) > 0 THEN
      NCcursor(ACTIVE.NC,0)
      POS.NC(ACTIVE.NC) = POS.NC(ACTIVE.NC) - 1
      BLIT 400*ACTIVE.NC+8,16,400*ACTIVE.NC+8,32,384,16*MAX_ROWS.NC
      NCcursor(ACTIVE.NC,1)
    ENDIF
  ENDIF
END SUB

SUB NCrenameItem
  'rename item

  STR.NC = NCinput("RENAME ITEM", "New name:",NCnewName(CUR_PATH.NC,MID$(SELECTED.NC,2)), FILECHARS.NC)
  ON ERROR SKIP
  RENAME CUR_PATH.NC+MID$(SELECTED.NC,2) AS CUR_PATH.NC+STR.NC
  IF MM.ERRNO THEN 
    NCerror("RENAME '" + MID$(SELECTED.NC,2) + "' ERROR") 
  ELSE
    NCchangeDir(0,PATH.NC(0))
    NCchangeDir(1,PATH.NC(1))
    NCcursor(ACTIVE.NC,1)
  ENDIF
END SUB

SUB NCcopyFile(source AS STRING, dest AS STRING, noWarning AS INTEGER)
  'copy file

  IF NOT noWarning THEN
    IF NOT NCquestion("COPY FILE","Copy '" + NCgetName(source) + "' to '" + NCgetPath(dest) + "'?") THEN         
      EXIT SUB
    ENDIF
  ENDIF
  ON ERROR SKIP
  COPY source TO dest
  IF MM.ERRNO THEN 
    NCerror("COPY '" + NCgetName(source) + "' ERROR")
  ELSE
    NCchangeDir(0,PATH.NC(0))
    NCchangeDir(1,PATH.NC(1))
    NCcursor(ACTIVE.NC,1)
  ENDIF 
END SUB

SUB NCmoveFile(source AS STRING, dest AS STRING)
  'move file

  IF NCquestion("MOVE FILE","Move '"+source+"' to '"+dest+"'?") THEN         
    ON ERROR SKIP
    COPY source TO dest
    IF MM.ERRNO THEN 
      NCerror("MOVE '" + NCgetName(source) + "' ERROR")
    ELSE
      ON ERROR SKIP
      KILL source
      IF MM.ERRNO THEN 
        NCerror("MOVE '" + NCgetName(source) + "' ERROR")
      ELSE
        NCchangeDir(0,PATH.NC(0))
        NCchangeDir(1,PATH.NC(1))
        NCcursor(ACTIVE.NC,1)
      ENDIF
    ENDIF 
  ENDIF
END SUB

SUB NCaction(p AS STRING, s AS STRING)
  'ENTER pressed on file (skeleton)

  SELECT CASE UCASE$(RIGHT$(s,4))
    CASE ".BAS"
  END SELECT
END SUB
   
FUNCTION NCchangePath(p AS STRING, d AS STRING) AS STRING
  'change path

  IF d = ".." THEN
    NCchangePath = p
    DO
      NCchangePath = LEFT$(NCchangePath, LEN(NCchangePath) - 1)
    LOOP WHILE RIGHT$(NCchangePath,1) <> "/" 
  ELSE
    NCchangePath = p + d + "/"
  ENDIF
END FUNCTION

SUB NCchangeDir(side AS INTEGER, p AS STRING)
  'change dir in pane

  LOCAL STRING f

  PATH.NC(side) = p
  CHDIR p

  IF UCASE$(PATH.NC(side))<>"A:/" THEN
    ITEM.NC(side,0) = "D..|>UP--DIR<"
    COUNT.NC(side) = 0
  ELSE
    COUNT.NC(side)=-1
  ENDIF
  f = DIR$("", ALL)
  DO WHILE f <> ""
    IF LEFT$(f,1)<> "." OR HIDDEN.NC THEN
      COUNT.NC(side) = COUNT.NC(side) + 1
      IF NCdateTime(f) = "" THEN
        ITEM.NC(side,COUNT.NC(side)) = "D" + f + "|" + NCsize(f) 
      ELSE
        ITEM.NC(side,COUNT.NC(side)) = "F" + f + "|" + NCsize(f) +"|" + NCdateTime(f)
      ENDIF
    ENDIF
    f = DIR$()
  LOOP
  POS.NC(side) = 0
  CURSOR.NC(side) = 0
  NCsort(side)
  NCredrawPane(side)

  CHDIR CUR_PATH.NC
END SUB

SUB NCredrawPane(side AS INTEGER)
  'redraw pane

  LOCAL STRING short = PATH.NC(side)
  LOCAL INTEGER i

  IF LEN(short)>46 THEN short = LEFT$(short,45)+"~"

  BOX 400*side,0,400,568,0,,RGB(BLACK)
  BOX 400*side,0,400,566,0,,RGB(BLUE)
  BOX 400*side+1,0+6,400-3,568-15,2,RGB(WHITE),RGB(BLUE)
  TEXT 400*side+200,0," "+short+" ","CT",,,RGB(WHITE),RGB(BLUE)
  TEXT 400*side+200,600-52,NCcounter(side),"CT",,,RGB(WHITE),RGB(BLUE)
  
  FOR i = POS.NC(side) TO MIN(COUNT.NC(side), MAX_ROWS.NC+POS.NC(side))
    IF MID$(ITEM.NC(side,i),2,1) = "." THEN
      TEXT 400*side+8, 16*(i-POS.NC(side)+1),NCout(ITEM.NC(side,i)),,,,RGB(RED),RGB(BLUE)
    ELSE
      TEXT 400*side+8, 16*(i-POS.NC(side)+1),NCout(ITEM.NC(side,i)),,,,RGB(WHITE),RGB(BLUE)
    ENDIF
  NEXT i
END SUB

FUNCTION NCout(s AS STRING) AS STRING
  'prepare string

  IF LEFT$(s,1) = "D" THEN
    NCout = NCname(MID$(FIELD$(s,1,"|"),2)) + " " + RIGHT$(SPACE$(9)+FIELD$(s,2,"|"),9) + SPACE$(15)
  ELSE
    NCout = NCname(MID$(FIELD$(s,1,"|"),2)) + " " + RIGHT$(SPACE$(9)+FIELD$(s,2,"|"),9) + " " + FIELD$(s,3,"|")
  ENDIF  
END FUNCTION

FUNCTION NCname(f AS STRING) AS STRING
  'prepare name, make it shorter when needed

  LOCAL INTEGER l = LEN(f)
  IF l > 23 THEN
    IF MID$(f, l-3,1)="." THEN
      NCname = LEFT$(f, 18) + "~" + RIGHT$(f,4)
    ELSE
      NCname = LEFT$(f, 22) + "~"
    ENDIF
  ELSE
    NCname = LEFT$(f + SPACE$(23), 23)
  ENDIF
END FUNCTION

FUNCTION NCdateTime(f AS STRING) AS STRING
  'prepare date and time of file

  LOCAL STRING dt = MM.INFO$(MODIFIED f)
  IF dt<>"" THEN dt = MID$(dt, 3, 14)
  NCdateTime = dt
END FUNCTION

FUNCTION NCsize(f AS STRING) AS STRING
  'prepare file size

  LOCAL INTEGER s = MM.INFO(FILESIZE f)
  IF s<0 THEN
    NCsize = ">SUB-DIR<"
  ELSE
    NCsize = STR$(s,9,0)
  ENDIF
END FUNCTION

FUNCTION NCgetPath(p AS STRING) AS STRING
  'get just PATH part
  IF INSTR(p,"/") > 0 THEN
    NCgetPath = p
    DO WHILE RIGHT$(NCgetPath,1) <> "/"
      NCgetPath = LEFT$(NCgetPath, LEN(NCgetPath) - 1)
    LOOP
  ELSE
    NCgetPath = ""
  ENDIF
END FUNCTION

FUNCTION NCgetNoExtension(p AS STRING) AS STRING
  'get NAME without extension

  IF INSTR(p,".") > 0 THEN
    NCgetNoExtension = p
    DO WHILE RIGHT$(NCgetNoExtension,1) <> "."
      NCgetNoExtension = LEFT$(NCgetNoExtension, LEN(NCgetNoExtension) - 1)
    LOOP
    NCgetNoExtension = LEFT$(NCgetNoExtension, LEN(NCgetNoExtension) - 1)
  ELSE
    NCgetNoExtension = p
  ENDIF
END FUNCTION

FUNCTION NCgetExtension(p AS STRING) AS STRING
  'get extension of file

  IF INSTR(p,".") > 0 THEN
    LOCAL STRING pp = p
    NCgetExtension = ""

    DO WHILE RIGHT$(pp,1) <> "."
      NCgetExtension = RIGHT$(pp,1) + NCgetExtension
      pp = LEFT$(pp, LEN(pp) - 1)
    LOOP
  ELSE
    NCgetExtension = ""
  ENDIF
END FUNCTION

FUNCTION NCgetName(p AS STRING) AS STRING
  'get just NAME part

  IF INSTR(p,"/") > 0 THEN
    LOCAL STRING pp = p
    NCgetName = ""

    DO WHILE RIGHT$(pp,1) <> "/"
      NCgetName = RIGHT$(pp,1) + NCgetName
      pp = LEFT$(pp, LEN(pp) - 1)
    LOOP
  ELSE
    NCgetName = p
  ENDIF
END FUNCTION

SUB NCdrawCL(p AS STRING)
  'outputs command line

  BOX 0,568,800,16,0,,RGB(BLACK)
  TEXT 0, 568,p,,,,RGB(WHITE),RGB(BLACK)
END SUB

SUB NCcursor(side AS INTEGER, show AS INTEGER)
  'show or hide cursor

  LOCAL STRING short = PATH.NC(side)
  LOCAL INTEGER hid = MID$(ITEM.NC(side,CURSOR.NC(side)+POS.NC(side)),2,1)="." 
  CUR_PATH.NC = PATH.NC(side)

  IF LEN(short)>46 THEN short = LEFT$(short,45)+"~"
  
  IF show THEN
    TEXT 400*side+200,0," "+short+" ","CT",,,RGB(BLUE),RGB(WHITE)
    IF hid THEN
      TEXT 400*side+8, 16*(CURSOR.NC(side)+1),NCout(ITEM.NC(side,CURSOR.NC(side)+POS.NC(side))),,,,RGB(BLUE),RGB(RED)
    ELSE
      TEXT 400*side+8, 16*(CURSOR.NC(side)+1),NCout(ITEM.NC(side,CURSOR.NC(side)+POS.NC(side))),,,,RGB(BLUE),RGB(WHITE)
    ENDIF
    SELECTED.NC = FIELD$(ITEM.NC(side,CURSOR.NC(side)+POS.NC(side)),1,"|")
    NCdrawCL(CUR_PATH.NC + MID$(SELECTED.NC,2))        
    TEXT 400*side+200,600-52,NCcounter(side),"CT",,,RGB(WHITE),RGB(BLUE)
  ELSE
    TEXT 400*side+200,0," "+short+" ","CT",,,RGB(WHITE),RGB(BLUE)
    IF hid THEN
      TEXT 400*side+8, 16*(CURSOR.NC(side)+1),NCout(ITEM.NC(side,CURSOR.NC(side)+POS.NC(side))),,,,RGB(RED),RGB(BLUE)
    ELSE
      TEXT 400*side+8, 16*(CURSOR.NC(side)+1),NCout(ITEM.NC(side,CURSOR.NC(side)+POS.NC(side))),,,,RGB(WHITE),RGB(BLUE)
    ENDIF
  ENDIF
END SUB

FUNCTION NCcounter(side AS INTEGER) AS STRING
  'display counter at bottom of pane

  NCcounter = " " + STR$(1+POS.NC(side)+CURSOR.NC(side))+"/"+STR$(1+COUNT.NC(side))+" "
END FUNCTION

SUB NCsetMenu(n AS INTEGER, t AS STRING, e AS INTEGER)
  'set name of F-key menu

  IF n>=0 THEN
    IF n<12 THEN
      MENU.NC(n) = LEFT$(t + SPACE$(6), 6)
      EN_MENU.NC(n) = e
    END IF
  END IF
END SUB

SUB NCsort(side AS INTEGER)
  'sort dir (need speed up, SORT()???)

  LOCAL INTEGER mi, i, j
  LOCAL STRING ms
  
  FOR i = 1 TO COUNT.NC(side)
    mi = i - 1
    ms = ITEM.NC(side,mi)
    FOR j = i TO COUNT.NC(side)
      IF ITEM.NC(side,j) < ms THEN
        mi = j
        ms = ITEM.NC(side,mi)
      ENDIF
    NEXT j
    ITEM.NC(side,mi) = ITEM.NC(side,i-1)
    ITEM.NC(side,i-1) = ms 
  NEXT i
END SUB

FUNCTION NCquestion(title AS STRING, txt AS STRING) AS INTEGER
  'UI QUESTION, returns 1 when OK (ENTER) was pressed, 0 else
  'TITLE, PROMPT

  LOCAL INTEGER w = 16 + 8*MAX(4+LEN(title),LEN(txt),8) 'minimum 8 chars
  LOCAL INTEGER h = 80
  LOCAL STRING k = ""
  LOCAL INTEGER b = RGB(YELLOW), f = RGB(GRAY)

  PAGE WRITE 1
  BOX 0,0,w,h,0,b,b
  BOX 3,8,w-6,h-11,2,f,b
  TEXT w\2,1," " + title + " ","CT",8,,f,b
  TEXT w\2,24,txt,"CT",8,,f,b
  TEXT 8,h-24,"Cancel","LT",8,,b,f
  TEXT w-8,h-24,"  OK  ","RT",8,,b,f
  PAGE WRITE 0
  SPRITE READ #1,0,0,w,h,1
  SPRITE SHOW #1,(MM.HRES-w)\2,(MM.VRES-h)\2,1
  DO
    k = INKEY$
  LOOP WHILE k<>CHR$(27) AND k<>CHR$(10) 
  SPRITE HIDE #1
  SPRITE CLOSE #1
  NCquestion = (k=CHR$(10))
END FUNCTION

FUNCTION NCinput(title AS STRING, txt AS STRING, def AS STRING, en AS STRING) AS STRING
  'UI INPUT, returns text
  'TITLE, PROMPT, DEFAULT TEXT, STRING WITH POSSIBLE CHARS
 
  LOCAL INTEGER w = 16 + 8*MAX(4+LEN(title),LEN(txt),LEN(def),8) 'minimum 8 chars
  LOCAL INTEGER h = 88, change = 0
  LOCAL STRING k = ""
  LOCAL INTEGER b = RGB(YELLOW), f = RGB(GRAY)

  NCinput = def
  PAGE WRITE 1
  BOX 0,0,w,h,0,b,b
  BOX 3,8,w-6,h-11,2,f,b
  BOX 8,40,w-16,16,0,RGB(CYAN),RGB(CYAN)
  TEXT w\2,1," " + title + " ","CT",8,,f,b
  TEXT 8,22,txt,"LT",8,,f,b
  TEXT 8,40,def,"LT",8,,f,RGB(CYAN)
  TEXT 8,h-24,"Cancel","LT",8,,b,f
  TEXT w-8,h-24,"  OK  ","RT",8,,b,f
  PAGE WRITE 0
  SPRITE READ #1,0,0,w,h,1
  SPRITE SHOW #1,(MM.HRES-w)\2,(MM.VRES-h)\2,1

  CURSOR_X.NC = (MM.HRES-w)\2+LEN(def)*8:CURSOR_Y.NC = (MM.VRES-h)\2+56
  IF LEN(def) < ((w-16)\8) THEN CURSOR_X.NC=CURSOR_X.NC+8

  CURSOR_ON.NC = 0: CURSOR_INT.NC = TIMER  
  DO
    IF TIMER-CURSOR_INT.NC > CURSOR_TIME THEN
      CURSOR_ON.NC = 1 - CURSOR_ON.NC
      IF CURSOR_ON.NC THEN
        LINE CURSOR_X.NC, CURSOR_Y.NC, CURSOR_X.NC+7, CURSOR_Y.NC, 2, f
      ELSE
        LINE CURSOR_X.NC, CURSOR_Y.NC, CURSOR_X.NC+7, CURSOR_Y.NC, 2, b
      ENDIF
      CURSOR_INT.NC = TIMER
    ENDIF
    k = INKEY$
    
    SELECT CASE k
      CASE CHR$(127)  'DEL, delete all
        NCinput = ""
        change = 1
        LINE CURSOR_X.NC, CURSOR_Y.NC, CURSOR_X.NC+7, CURSOR_Y.NC, 2, b
        CURSOR_X.NC = (MM.HRES-w)\2+8
         
      CASE CHR$(8)    'BACKSPACE, delete last character
        IF NCinput<>"" THEN
          IF LEN(NCinput) < ((w-16)\8) THEN
            LINE CURSOR_X.NC, CURSOR_Y.NC, CURSOR_X.NC+7, CURSOR_Y.NC, 2, b
            CURSOR_X.NC = CURSOR_X.NC - 8
          ENDIF
          NCinput = LEFT$(NCinput, LEN(NCinput) - 1)
          change = 1
        ENDIF

      CASE ELSE
        IF INSTR(en,k)>0 THEN
          IF LEN(NCinput) < ((w-16)\8) THEN
            NCinput = NCinput + k
            change = 1
            LINE CURSOR_X.NC, CURSOR_Y.NC, CURSOR_X.NC+7, CURSOR_Y.NC, 2, b
            IF LEN(NCinput) < ((w-16)\8) THEN
              CURSOR_X.NC = CURSOR_X.NC + 8
            ENDIF
          ELSE
            NCinput = LEFT$(NCinput, LEN(NCinput)-1) + k
            change = 1
          ENDIF
        ENDIF
    END SELECT

    IF change THEN
      BOX (MM.HRES-w)\2+8,(MM.VRES-h)\2+40,w-16,16,0,RGB(CYAN),RGB(CYAN)
      TEXT (MM.HRES-w)\2+8,(MM.VRES-h)\2+40,NCinput,"LT",8,,f,RGB(CYAN)
      change = 0
    ENDIF
  LOOP WHILE k<>CHR$(27) AND k<>CHR$(10) 
  SPRITE HIDE #1
  SPRITE CLOSE #1
  IF k=CHR$(27) THEN NCinput = ""
END FUNCTION

SUB NCinfo(title AS STRING, txt() AS STRING)
  'UI INFO, shows more lines
  'TITLE, TEXT array

  LOCAL INTEGER w = 16, h = 16, i
  LOCAL INTEGER b = RGB(YELLOW), f = RGB(GRAY)
  LOCAL INTEGER m = MIN(MAX_ROWS.NC, BOUND(txt()))
 
  FOR i = 0 TO m
    IF LEN(txt(i)) > 98 THEN txt(i) = LEFT$(txt(i),98)
    w = MAX(16+8*LEN(txt(i)), w)
  NEXT i
  h = m*16+64
  PAGE WRITE 1
  BOX 0,0,w,h,0,b,b
  BOX 3,8,w-6,h-11,2,f,b
  TEXT w\2,1," " + title + " ","CT",8,,f,b
  FOR i = 0 TO m
    TEXT 8,24+i*16,txt(i),"LT",8,,f,b
  NEXT i
  TEXT w\2,h-24,"  OK  ","CT",8,,b,f
  PAGE WRITE 0
  SPRITE READ #1,0,0,w,h,1
  SPRITE SHOW #1,(MM.HRES-w)\2,(MM.VRES-h)\2,1
  DO:LOOP WHILE INKEY$="" 
  DO:LOOP WHILE INKEY$<>"" 
  SPRITE HIDE #1
  SPRITE CLOSE #1
END SUB

SUB NCwaitingON(title AS STRING)
  'UI WAIT, start progress
  'TITLE

  CONST txt = "Please wait..."
  LOCAL INTEGER w = 32 + MAX(8*LEN(title), 8*LEN(txt)) 'minimum width
  LOCAL INTEGER h = 48
  LOCAL INTEGER b = RGB(YELLOW), f = RGB(GRAY)
  
  PAGE WRITE 1
  BOX 0,0,w,h,0,b,b
  BOX 3,8,w-6,h-11,2,f,b
  TEXT w\2,1," " + title + " ","CT",8,,f,b
  TEXT w\2,24,txt,"CT",8,,f,b
  PAGE WRITE 0
  SPRITE READ #1,0,0,w,h,1
  SPRITE SHOW #1,(MM.HRES-w)\2,(MM.VRES-h)\2,1
END SUB

SUB NCwaitingOFF
  'UI WAIT, finish progress

  SPRITE HIDE #1
  SPRITE CLOSE #1
END SUB

FUNCTION NCselect(title AS STRING, txt AS STRING) AS INTEGER
  'UI SELECT, can select up to 10 choices with keys 0-9
  'TITLE, TEXT (lines separated by ",")
  
  LOCAL INTEGER w = 16 + 8*MAX(4+LEN(title),13) 'minimum 13 chars
  LOCAL INTEGER i,cnt = 0, h = 80
  LOCAL INTEGER b = RGB(YELLOW), f = RGB(GRAY)
  LOCAL STRING k
  
  DO WHILE FIELD$(txt, cnt+1, ",") <> ""
    cnt = cnt + 1
  LOOP
  cnt = MIN(cnt, 10)
  h = 16*cnt + 64
  FOR i = 1 TO cnt
    w = MAX(w, 8*(LEN(FIELD$(txt, i, ","))+6))
  NEXT i
  PAGE WRITE 1
  BOX 0,0,w,h,0,b,b
  BOX 3,8,w-6,h-11,2,f,b
  TEXT w\2,1," " + title + " ","CT",8,,f,b
  FOR i = 1 TO cnt
    TEXT 8,8+i*16," " + STR$(i-1) + " " + FIELD$(txt, i, ","),"LT",8,,f,b
  NEXT i
  TEXT w\2,h-24," Press 0-" + STR$(cnt-1) + " ","CT",8,,b,f
  PAGE WRITE 0
  SPRITE READ #1,0,0,w,h,1
  SPRITE SHOW #1,(MM.HRES-w)\2,(MM.VRES-h)\2,1
  DO
    k = INKEY$
  LOOP WHILE INSTR("0123456789"+CHR$(27),k)=0 
  DO:LOOP WHILE INKEY$<>"" 
  NCselect = ASC(k)-48
  SPRITE HIDE #1
  SPRITE CLOSE #1
END FUNCTION

SUB NCwarning(title AS STRING, txt AS STRING)
  'UI WARNING, wait for any key
  'TITLE, INFO

  LOCAL INTEGER w = 16 + 8*MAX(4+LEN(title),LEN(txt),8) 'minimum 8 chars
  LOCAL INTEGER h = 80
  LOCAL INTEGER b = RGB(YELLOW), f = RGB(GRAY)
  
  IF w>800 THEN
    w = 800
    title = LEFT$(title, MIN(LEN(title),98))
    txt = LEFT$(txt, MIN(LEN(txt),98))
  ENDIF
  PAGE WRITE 1
  BOX 0,0,w,h,0,b,b
  BOX 3,8,w-6,h-11,2,f,b
  TEXT w\2,1," " + title + " ","CT",8,,f,b
  TEXT w\2,24,txt,"CT",8,,f,b
  TEXT w\2,h-24,"  OK  ","CT",8,,b,f
  PAGE WRITE 0
  SPRITE READ #1,0,0,w,h,1
  SPRITE SHOW #1,(MM.HRES-w)\2,(MM.VRES-h)\2,1
  DO:LOOP WHILE INKEY$="" 
  DO:LOOP WHILE INKEY$<>"" 
  SPRITE HIDE #1
  SPRITE CLOSE #1
END SUB

SUB NCerror(title AS STRING)
  'shows BASIC error

  NCwarning(title, FIELD$(MM.ERRMSG$,2,":"))
END SUB

SUB NCdeleteDir(start AS STRING)
  'delete complete dir, no recursion

  LOCAL INTEGER ind = 0, td=0, size
  LOCAL STRING item, path
  LOCAL STRING pth(MAX_ITEMS.NC)
  LOCAL STRING toDo(MAX_ITEMS.NC)
 
  NCwaitingON("DELETE DIR") 
  pth(ind) = start
  toDo(td) = "R" + start
  DO WHILE ind >= 0
    CHDIR pth(ind)
    path = pth(ind)
    ind = ind - 1
    item = DIR$("", ALL)
    DO WHILE item <> ""
      size = MM.INFO(FILESIZE item)
      IF size<0 THEN
        'directory
        ind = ind + 1
        pth(ind) = path + "/" + item                
        td = td + 1
        toDo(td) = "R" + path + "/" + item
 
      ELSE
        'file
        td = td + 1
        toDo(td) = "K" + path + "/" + item
      ENDIF
      item = DIR$()
    LOOP
  LOOP
  FOR ind = td TO 0 STEP -1
    IF LEFT$(toDo(ind),1)="K" THEN
      KILL MID$(toDo(ind),2)
    ELSE
      CHDIR MID$(toDo(ind),2)+"/.."
      RMDIR NCfilePart(MID$(toDo(ind),2))
    ENDIF
  NEXT ind
  NCwaitingOFF
END SUB

FUNCTION NCfilePart(p AS STRING) AS STRING
  'split path

  LOCAL STRING pp = p
  DO WHILE RIGHT$(pp,1)<>"/"
    NCfilePart = RIGHT$(pp,1) + NCfilePart
    pp = LEFT$(pp,LEN(pp)-1)
  LOOP 
END FUNCTION

FUNCTION NCsource2dest(s AS STRING, d AS STRING, i AS STRING) AS STRING
  'replace source with destination (for dir copy)

  NCsource2dest = d + RIGHT$(i,LEN(i)-LEN(s))  
END FUNCTION

SUB NCcopyDir(source AS STRING, dest AS STRING, noWarning AS INTEGER)
  'copy dir structure

  LOCAL INTEGER ind = 0, size
  LOCAL STRING item, path,dst
  LOCAL STRING pth(MAX_ITEMS.NC)
  
  pth(ind) = source

  NCwaitingON("COPY DIR")
  ON ERROR SKIP
  MKDIR dest
  IF MM.ERRNO > 0 THEN 
    NCerror("COPY DIR")
  ELSE
    DO WHILE ind >= 0
      CHDIR pth(ind)
      path = pth(ind)
      ind = ind - 1
      item = DIR$("", ALL)
      DO WHILE item <> ""
        size = MM.INFO(FILESIZE item)
        IF size<0 THEN
          'directory
          'NCwarning("COPY DIR", "Create dir '" + NCsource2dest(source,dest,path + item) + "'")
          MKDIR NCsource2dest(source,dest,path + item)

          ind = ind + 1
          pth(ind) = path + item + "/"                
        ELSE
          'file
          'NCwarning("COPY DIR", "Copy file '" + path + item + "' to '" + NCsource2dest(source,dest,path + item) + "'")
          COPY path+item TO NCsource2dest(source,dest,path + item)
        ENDIF
        item = DIR$()
      LOOP
    LOOP
  
    NCwaitingOFF
    NCchangeDir(0,PATH.NC(0))
    NCchangeDir(1,PATH.NC(1))
    NCcursor(ACTIVE.NC,1)
  ENDIF
END SUB

FUNCTION NCmeasure(start AS STRING) AS INTEGER
  'measure folder

  LOCAL INTEGER ind = 0, total = 0, items = 1, size
  LOCAL STRING item, path
  LOCAL STRING pth(MAX_ITEMS.NC)

  pth(ind) = start

  DO WHILE ind >= 0
    CHDIR pth(ind)
    path = pth(ind)
    ind = ind - 1
    item = DIR$("", ALL)
    DO WHILE item <> ""
      size = MM.INFO(FILESIZE item)
      IF size<0 THEN
        'directory
        ind = ind + 1
        pth(ind) = path + "/" + item                
        items = items + 1
      ELSE
        total = total + size
        items = items + 1 
      ENDIF
      item = DIR$()
    LOOP
  LOOP
  NCmeasure = items OR (total << 16)
END FUNCTION

SUB NCinit
  'INIT

  MODE 1,8
  CHDIR CUR_PATH.NC

  CURSOR.NC(0) = 0
  CURSOR.NC(1) = 0       'left and right cursor
  POS.NC(0) = 0
  POS.NC(1) = 0       'left and right position
  COUNT.NC(0) = -1
  COUNT.NC(1) = -1 'left and right items count
  PATH.NC(0) = CUR_PATH.NC                   'left path
  PATH.NC(1) = CUR_PATH.NC                  'right path

  LOAD FONT "AtariST.FNT"
  FONT #8,1
  CLS
  NCsetMenu(0, "Help", 1)
  NCsetMenu(1, "GetSiz", 1)
  NCsetMenu(2, "Viewer" , 1)
  NCsetMenu(3, "Editor" , 0)
  NCsetMenu(4, "Copy"   , 1)
  NCsetMenu(5, "RenMov", 1)
  NCsetMenu(6, "MakDir", 1)
  NCsetMenu(7, "Delete", 1)
  NCsetMenu(8, "RESERV", 0) 'Un/TAR
  NCsetMenu(9, "QuitNC", 1)
  NCsetMenu(10,"RESERV", 0)
  NCsetMenu(11,"L=R", 1)
 
  NCdrawMenu
END SUB

SUB NCdrawMenu
  'draws menu at bottom
  LOCAL INTEGER i, back, xx = 2

  BOX 0,600-16,800,16,0,,RGB(BLACK)
  FOR i = 0 TO 11
    IF EN_MENU.NC(i) THEN
      back = RGB(CYAN)
    ELSE
      back = RGB(GRAY)
    ENDIF
    IF MENU.NC(i) <> "" THEN
      TEXT xx, 584,STR$(i+1,0,0),,,,RGB(WHITE),RGB(BLACK)
      xx = xx + 8
      IF i > 8 THEN xx = xx + 8
      TEXT xx,584, MENU.NC(i),,,,RGB(BLACK),back
      xx = xx + 6*8 + 9
    END IF
  NEXT i    
END SUB

SUB NCviewHEX(filePath AS STRING)
  'simple hex viewer

  LOCAL INTEGER si = MM.INFO(FILESIZE filePath)
  LOCAL INTEGER firstRow = 16+4, row = 0, cnt = 0, change = 0, b, po = 0, i
  LOCAL STRING li,k

  CLS
  BOX 0,16,800,600-32,0,,RGB(CYAN)
  LINE 0,7,800,7,2,RGB(WHITE)
  LINE 0,600-8,800,600-8,2,RGB(WHITE)
  TEXT 400,0," " + filePath + " ","CT",8,,RGB(WHITE),RGB(BLACK)
  TEXT 0,600-16,"PgUP/PgDOWN/ESC ","LT",8,,RGB(WHITE),RGB(BLACK)

  OPEN filePath FOR RANDOM AS #3

  DO 
    SEEK #3, po + 1
    change = 0
    cnt = 0 
    row = 0
  
    BOX 0,16,800,600-32,0,,RGB(CYAN)
    TEXT 400,600-16," Position " + HEX$(po,8) + " of " + HEX$(si,8) + " ","CT",8,,RGB(WHITE),RGB(BLACK)

    DO WHILE cnt<16*35 AND NOT EOF(#3)
      li = INPUT$(16, #3)
    
      TEXT 0,firstRow + row, HEX$(po+cnt,8),"LT",8,,RGB(BLACK), RGB(CYAN)
      FOR i = 0 TO MIN(LEN(li)-1,15)
        b = ASC(MID$(li,i+1,1))
        TEXT 80+i*32,firstRow + row, HEX$(b,2),"LT",8,,RGB(BLACK), RGB(CYAN)
        IF b>=32 THEN
          TEXT 600+i*8,firstRow + row, CHR$(b),"LT",8,,RGB(BLACK), RGB(CYAN)
        ELSE
          TEXT 600+i*8,firstRow + row, ".","LT",8,,RGB(BLACK), RGB(CYAN)
        ENDIF
      NEXT i          
      row = row + 16
      cnt = cnt + 16
    LOOP
    
    DO WHILE change = 0 AND k<>CHR$(27)
      DO: k = INKEY$: LOOP WHILE k=""
      IF k=CHR$(136) THEN
        'Page UP
        IF po > 0 THEN 
          po = MAX(po - 16*35,0)
          change = 1
        ENDIF

      ELSEIF k=CHR$(137) THEN
        'Page DOWN
        IF (po+16*35) <= si  THEN 
          po = po + 16*35
          change = 1
        ENDIF

      ENDIF
    LOOP
  LOOP WHILE k<>CHR$(27)
  CLOSE #3
  NCredrawPane(0)
  NCredrawPane(1)  
  NCcursor(ACTIVE.NC,1)
  NCdrawMenu
END SUB

SUB NCviewTXT(filePath AS STRING)
  'simple text viewer

  CLS
  BOX 0,16,800,600-32,0,,RGB(CYAN)
  LINE 0,7,800,7,2,RGB(WHITE)
  LINE 0,600-8,800,600-8,2,RGB(WHITE)
  TEXT 400,0," " + filePath + " ","CT",8,,RGB(WHITE),RGB(BLACK)
  TEXT 0,600-16,"PgUP/PgDOWN/ESC ","LT",8,,RGB(WHITE),RGB(BLACK)

  LOCAL INTEGER firstRow = 16+4, row = 0, cnt = 0, pg = 0, maxpage = 0, viewpage = 0, change = 0
  LOCAL STRING li, k

  OPEN filePath FOR INPUT AS #3
  DO WHILE NOT EOF(#3)
    LINE INPUT #3, li
    cnt = cnt + 1
    IF (cnt MOD 35) = 0 THEN 
      pg = pg + 1
    ENDIF
  LOOP
  CLOSE #3  

  maxpage = pg
  
  DO 
    change = 0
    pg = 0
    cnt = 0 
  
    OPEN filePath FOR INPUT AS #3
    DO WHILE pg<viewpage AND NOT EOF(#3)
      LINE INPUT #3, li
      cnt = cnt + 1
      IF (cnt MOD 35) = 0 THEN 
        pg = pg + 1
      ENDIF
    LOOP
    
    BOX 0,16,800,600-32,0,,RGB(CYAN)
    TEXT 400,600-16," Page " + STR$(pg+1) + "/" + STR$(maxpage+1) + " ","CT",8,,RGB(WHITE),RGB(BLACK)

    row = 0
    DO WHILE (row < 35*16) AND NOT EOF(#3)
      LINE INPUT #3, li
      IF LEN(li)>100 THEN li = LEFT$(li,100)
      TEXT 0,firstRow + row, li,"LT",8,,RGB(BLACK), RGB(CYAN)
      row = row + 16 
    LOOP
    CLOSE #3

    DO WHILE change = 0 AND k<>CHR$(27)
      DO: k = INKEY$: LOOP WHILE k=""
      IF k=CHR$(136) THEN
        'Page UP
        IF viewpage > 0 THEN 
          viewpage = viewpage - 1
          change = 1
        ENDIF
      ELSEIF k=CHR$(137) THEN
        'Page DOWN
        IF viewpage<maxpage THEN 
          viewpage = viewpage + 1
          change = 1
        ENDIF
      ENDIF
    LOOP
  LOOP WHILE k<>CHR$(27)
  NCredrawPane(0)
  NCredrawPane(1)  
  NCcursor(ACTIVE.NC,1)
  NCdrawMenu
END SUB

SUB NCview
  'parrent for viewer

  LOCAL STRING k
  CONST en = CHR$(27)

  SELECT CASE UCASE$(NCgetExtension(MID$(SELECTED.NC,2)))
    CASE "TXT", "BAS", "BAK", "INC", "FNT"
      'text view
      NCviewTXT(CUR_PATH.NC + MID$(SELECTED.NC,2))
      
    CASE "BMP", "PNG", "BMP", "JPG"
      'image view
      NCwarning("IMAGE VIEW", "Still no viewer...")

    CASE ELSE
      'HEX view
      NCviewHEX(CUR_PATH.NC + MID$(SELECTED.NC,2))

  END SELECT
END SUB

