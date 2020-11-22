#MMDEBUG ON

OPTION EXPLICIT
OPTION DEFAULT NONE
OPTION BASE 0

CONST VERSION = "0.60"

DIM INTEGER INIT.NC = 0
DIM STRING NC_PATH.NC = NCgetPath(MM.INFO$(CURRENT))     'path to NC executable

initDebug
NCchdir NC_PATH.NC

#INCLUDE "TUI.INC"
#INCLUDE "VIEWER.INC"
#INCLUDE "ACTION.INC"

CONST FILECHARS.NC = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789()_-."
CONST MAX_ITEMS.NC = 500 'max number of items in pane
CONST MAX_ROWS.NC = 32   'max row in list display
CONST ESC.NC = CHR$(27)
CONST ENTER.NC = CHR$(10)
CONST CR.NC = CHR$(13)
CONST LF.NC = CHR$(10)
CONST INFO.NC = "FILEINFO.TXT"
CONST SERIAL_TIMEOUT.NC = 300
CONST SERIAL_INIT.NC = "COM3:230400,1024"
CONST SERIAL_NUM.NC = 1
DIM STRING SERIAL_IN.NC = ""
DIM STRING SERIAL_PATH.NC = ""
DIM INTEGER SERIAL_ON.NC = 0

DIM STRING NULL.NC 
DIM STRING STORE.NC
DIM STRING COMPLETE.NC   'current selected item
DIM STRING SELECTED.NC   'current selected item name
DIM STRING MANUAL.NC = NC_PATH.NC + "MANUAL.TXT"
DIM STRING CUR_PATH.NC          'current path
DIM STRING MENU.NC(11) LENGTH 7 'menu
DIM INTEGER EN_MENU.NC(11)      'menu enabled
DIM INTEGER CURSOR.NC(1)        'cursor position in pane
DIM INTEGER POS.NC(1)           'items list position in pane
DIM INTEGER COUNT.NC(1)         'number of items in pane
DIM STRING PATH.NC(1)           'current path in pane
DIM STRING ITEM.NC(1, MAX_ITEMS.NC) 'items storage

DIM INTEGER EXT_ERR.NC = -1 'external error (VIEWER, ACTION...)
                            '-1=no EXT, 0=OK, >0 error from EXT
DIM INTEGER LOGO.NC = 0

DIM INTEGER ACTIVE.NC = 0 '0 cursor on left

DIM INTEGER HLP.NC        'temporary integer var
DIM INTEGER HIDDEN.NC = 0 'not show hidden items
DIM INTEGER UNSORT.NC = 0 'not sort items
DIM STRING STR.NC         'temporary string var

DIM STRING SS.NC = "" 'screenshot was made

DIM INTEGER CFG_ExtView.NC = 0
DIM INTEGER CFG_ExtAct.NC = 0
DIM INTEGER CFG_ESCup.NC = 0
DIM INTEGER CFG_DirFil.NC = 0
DIM INTEGER CFG_TXTfb.NC = 0
DIM INTEGER CFG_HighColor.NC = 0
DIM INTEGER CFG.NC

NCinit

NCchangeDir(0,"A:/")
NCchangeDir(1,"A:/")
NCdrawCL(PATH.NC(ACTIVE.NC))

NCcursor(0,1)

ON KEY 157, NCprintScreen
DIM STRING kk
DO
  IF SS.NC <> "" THEN 'screenshot was prepared
    PAGE COPY 0 TO 1
    CLS
    BLIT WRITE #64,VAL(FIELD$(SS.NC,1,",")),VAL(FIELD$(SS.NC,2,","))
    SAVE IMAGE PATH.NC(ACTIVE.NC)+"ScreenShot.BMP",VAL(FIELD$(SS.NC,1,",")),VAL(FIELD$(SS.NC,2,",")),VAL(FIELD$(SS.NC,3,",")),VAL(FIELD$(SS.NC,4,","))
    BLIT CLOSE #64
    PAGE COPY 1 TO 0
    SS.NC = ""
    NCchangeDir(ACTIVE.NC,PATH.NC(ACTIVE.NC))
    NCcursor(ACTIVE.NC,1)
  ENDIF

  kk = INKEY$
  IF kk <> "" THEN NCkey(ASC(kk))
LOOP
END

SUB NCprintScreen
  'store screenshot into memory

  IF NCisSerial(ACTIVE.NC) THEN
  ELSE
    IF SS.NC = "" THEN
      IF (KEYDOWN(7) AND 1) AND ON.TUI THEN 'LEFT ALT, DIALOG screemshot
        SS.NC = STR$(X.TUI) + "," + STR$(Y.TUI) + "," + STR$(W.TUI) + "," + STR$(H.TUI)
        BLIT READ #64, X.TUI, Y.TUI, W.TUI, H.TUI
      ELSE
        SS.NC = "0,0," + STR$(MM.HRES) + "," + STR$(MM.VRES)
        BLIT READ #64, 0, 0, MM.HRES, MM.VRES
      ENDIF
    ENDIF
  ENDIF
END SUB     

SUB NCheader(side AS INTEGER, s AS STRING)
  'draw header path

  LOCAL STRING ss = s
  IF LEN(ss)>46 THEN ss = LEFT$(ss,45)+"~"
  IF side = ACTIVE.NC THEN
    TEXT 400*side+200,0," " + ss + " ", "CT",8,,RGB(BLUE),RGB(WHITE)
  ELSE
    TEXT 400*side+200,0," " + ss + " ", "CT",8,,RGB(WHITE),RGB(BLUE)
  ENDIF
END SUB

FUNCTION NCserialOK() AS INTEGER
  'test serial port (server returns OK)

  LOCAL FLOAT timeout = TIMER
  LOCAL STRING lineSerial = ""

  NCserialOK = 0

  IF NOT SERIAL_ON.NC THEN
    OPEN SERIAL_INIT.NC AS #1
    SERIAL_ON.NC = 1
  ENDIF
  NCserialOut("?")     
  lineSerial = NCreadUntilLF()
  IF lineSerial = "OK" THEN
    NCserialOK = 1
  ENDIF
END FUNCTION

SUB NCkey(kk AS INTEGER)
  'main SUB for key control

  LOCAL STRING ccc
  
  SELECT CASE kk
    CASE 128  'up
      NCup
  
    CASE 129  'down
      NCdown

    CASE ASC("a") TO ASC("z")
      NCfindFirstChar(CHR$(kk))

    CASE 27  'ESC
      IF CFG_ESCup.NC THEN
        IF LEFT$(PATH.NC(ACTIVE.NC),1) = "S" THEN
          IF LEFT$(ITEM.NC(ACTIVE.NC,0),3) = "D.." THEN
            'serial port
            NCserialOut("C..")
            NCserialDir(ACTIVE.NC)
            NCcursor(ACTIVE.NC,0)
            PATH.NC(ACTIVE.NC) = NCchangePath(PATH.NC(ACTIVE.NC), MID$(SELECTED.NC,2))
            NCdrawCL(PATH.NC(ACTIVE.NC))
            NCredrawPane(ACTIVE.NC)
            NCcursor(ACTIVE.NC,1)
          ENDIF
        ELSE
          IF LEFT$(ITEM.NC(ACTIVE.NC,0),3) = "D.." THEN
            NCcursor(ACTIVE.NC,0)
            PATH.NC(ACTIVE.NC) = NCchangePath(PATH.NC(ACTIVE.NC), "..")
            NCchangeDir(ACTIVE.NC,PATH.NC(ACTIVE.NC))
            NCdrawCL(PATH.NC(ACTIVE.NC))
            NCcursor(ACTIVE.NC,1)
          ENDIF
        ENDIF
      ENDIF

    CASE 9    'TAB
      NCcursor(ACTIVE.NC,0)
      ACTIVE.NC = 1 - ACTIVE.NC
      NCheader(1-ACTIVE.NC, PATH.NC(1-ACTIVE.NC))
      NCheader(ACTIVE.NC, PATH.NC(ACTIVE.NC))
      NCcursor(ACTIVE.NC,1)

    CASE 10   'ENTER
      SELECTED.NC = FIELD$(ITEM.NC(ACTIVE.NC,CURSOR.NC(ACTIVE.NC)+POS.NC(ACTIVE.NC)),1,"|") 
      IF LEFT$(SELECTED.NC,1) = "D" THEN
        IF NCisSerial(ACTIVE.NC) THEN
          'serial port
          IF RIGHT$(SELECTED.NC,2) = ".." THEN
            STR.NC = NCparent(PATH.NC(ACTIVE.NC))
          ELSE
            STR.NC = PATH.NC(ACTIVE.NC) + MID$(SELECTED.NC, 2)
          ENDIF
          NCserialOut("D" + STR.NC)
          NCserialDir(ACTIVE.NC)
          CURSOR.NC(ACTIVE.NC) = 0
          POS.NC(ACTIVE.NC) = 0
          NCcursor(ACTIVE.NC,0)
          NCdrawCL(PATH.NC(ACTIVE.NC))
          NCredrawPane(ACTIVE.NC)
          NCcursor(ACTIVE.NC,1)
        ELSE
          NCcursor(ACTIVE.NC,0)
          PATH.NC(ACTIVE.NC) = NCchangePath(PATH.NC(ACTIVE.NC), MID$(SELECTED.NC,2))
          NCchangeDir(ACTIVE.NC,PATH.NC(ACTIVE.NC))
          NCdrawCL(PATH.NC(ACTIVE.NC))
          NCcursor(ACTIVE.NC,1)
        ENDIF
      ELSE
        IF NOT NCisSerial(ACTIVE.NC) THEN
          NCaction(PATH.NC(ACTIVE.NC), MID$(SELECTED.NC,2))
        ENDIF
      ENDIF

    CASE 145  'F1
      IF EN_MENU.NC(0) THEN
        IF (KEYDOWN(7) AND 1) THEN
          HLP.NC = TUIchoice("LEFT PANE","A:/,S:/")
          SELECT CASE HLP.NC
            CASE 0            
              PATH.NC(0) = "A:/"               
              NCheader(0, PATH.NC(0))
              NCchangeDir(0, PATH.NC(0))
              IF ACTIVE.NC = 0 THEN
                NCcursor(ACTIVE.NC, 1)
              ENDIF

            CASE 1 
              IF NCserialOK() THEN
                NCchangeDir(0, "S:/")
                IF ACTIVE.NC = 0 THEN
                  NCcursor(ACTIVE.NC, 1)
                ENDIF
              ENDIF              

          END SELECT
        ELSE
          NChelp
        ENDIF
      ENDIF

    CASE 146  'F2
      IF EN_MENU.NC(1) THEN
        IF (KEYDOWN(7) AND 1) THEN
          HLP.NC = TUIchoice("RIGHT PANE","A:/,S:/")
          SELECT CASE HLP.NC
            CASE 0
              PATH.NC(1) = "A:/"               
              NCheader(1, PATH.NC(1))
              NCchangeDir(1, PATH.NC(1))
              IF ACTIVE.NC = 1 THEN
                NCcursor(ACTIVE.NC, 1)
              ENDIF


            CASE 1 
              IF NCserialOK() THEN
                NCchangeDir(1, "S:/")
                IF ACTIVE.NC = 1 THEN
                  NCcursor(ACTIVE.NC, 1)
                ENDIF
              ENDIF              
    
          END SELECT

        ELSE
          IF NOT NCisSerial(ACTIVE.NC) THEN          
            IF SELECTED.NC <> "D.." THEN
              IF LEFT$(SELECTED.NC,1)="D" THEN
                ccc = TUIwaitingON("GET SIZE")
                HLP.NC = NCmeasure(CUR_PATH.NC+MID$(SELECTED.NC,2))
                TUIwaitingOFF(ccc)     
                TUIwarning("GET INFO","'"+MID$(SELECTED.NC,2)+"' has "+STR$(HLP.NC>>16,0,0)+" bytes in " + STR$(HLP.NC AND &hFFFF,0,0)+" items")
              ELSE
                NCgetInfo(CUR_PATH.NC+MID$(SELECTED.NC,2))
              ENDIF
            ENDIF
          ENDIF
        ENDIF
      ENDIF

    CASE 147  'F3
      IF EN_MENU.NC(2) THEN
        IF NOT NCisSerial(ACTIVE.NC) THEN
          IF LEFT$(SELECTED.NC,1)="F" THEN
            NCview
          ENDIF
        ENDIF
      ENDIF

    CASE 148  'F4
      IF EN_MENU.NC(3) THEN
        TUIwarning("WARNING","Pressed F4")
      ENDIF

    CASE 149  'F5
      IF EN_MENU.NC(4) THEN
        IF NCisSerial(0) OR NCisSerial(1) THEN
          IF LEFT$(SELECTED.NC,1)="F" THEN
            NCserverCopy(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2),PATH.NC(1-ACTIVE.NC)+MID$(SELECTED.NC,2))
          ELSE
            UIwarning("COPY DIR", "Copy DIR to/from server not supported yet")
          ENDIF
        ELSE
          IF LEFT$(SELECTED.NC,3)<>"D.." THEN
            IF PATH.NC(0)=PATH.NC(1) THEN
              'COPY as new name
              STR.NC = TUIinput("COPY AS","New name for '"+MID$(SELECTED.NC,2)+"'",NCnewName(PATH.NC(1-ACTIVE.NC),MID$(SELECTED.NC,2)),FILECHARS.NC)
              IF STR.NC <> MID$(SELECTED.NC,2) AND STR.NC <> "" THEN
                IF LEFT$(SELECTED.NC,1)="F" THEN
                  NCcopyFile(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2),PATH.NC(1-ACTIVE.NC)+STR.NC,0)    
                ELSE
                  NCcopyDir(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2)+"/",PATH.NC(1-ACTIVE.NC)+STR.NC+"/",1)     
                ENDIF
              ENDIF                  

            ELSE
              IF LEFT$(SELECTED.NC,1)="D" THEN
                'COPY DIR
                IF TUIquestion("COPY DIR", "Copy '"+MID$(SELECTED.NC,2)+"' to '"+PATH.NC(1-ACTIVE.NC)+"'?") THEN
                  NCcopyDir(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2)+"/",PATH.NC(1-ACTIVE.NC)+MID$(SELECTED.NC,2)+"/")     
                ENDIF
              ELSE
                'COPY FILE
                IF TUIquestion("COPY FILE", "Copy '"+MID$(SELECTED.NC,2)+"' to '"+PATH.NC(1-ACTIVE.NC)+"'?") THEN
                  NCcopyFile(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2),PATH.NC(1-ACTIVE.NC)+MID$(SELECTED.NC,2))
                ENDIF
              ENDIF
            ENDIF 
          ENDIF       
        ENDIF
      ENDIF

    CASE 150  'F6
      IF EN_MENU.NC(5) THEN
        IF NCisSerial(0) OR NCisSerial(1) THEN
          TUIwarning("MOVE FILE", "Move to/from server not supported yet")
        ELSE
          IF LEFT$(SELECTED.NC,3)<>"D.." THEN
            IF PATH.NC(0)=PATH.NC(1) THEN 'RENAME
             NCrenameItem
        
            ELSE 'MOVE
              IF LEFT$(SELECTED.NC,1)="D" THEN
                'MOVE DIR
            
                IF NCinsideTest(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2)+"/",PATH.NC(1-ACTIVE.NC)+MID$(SELECTED.NC,2)+"/") THEN
                  TUIwarning("COPY DIR ","Copy something into itself is VERY bad idea!")
                  EXIT SUB
                ENDIF  

                IF TUIquestion("MOVE DIR", "Move '"+MID$(SELECTED.NC,2)+"' to '"+PATH.NC(1-ACTIVE.NC)+"'?") THEN
                  STORE.NC = SELECTED.NC
                  NCcopyDir(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2)+"/",PATH.NC(1-ACTIVE.NC)+MID$(SELECTED.NC,2)+"/")
                  SELECTED.NC = STORE.NC
                  NCdelete(1)                           
                ENDIF
            
              ELSE
                'MOVE FILE
                NCmoveFile(PATH.NC(ACTIVE.NC)+MID$(SELECTED.NC,2),PATH.NC(1-ACTIVE.NC)+MID$(SELECTED.NC,2))
              ENDIF
            ENDIF
          ENDIF
        ENDIF        
      ENDIF

    CASE 151  'F7
      IF EN_MENU.NC(6) THEN
        IF NCisSerial(ACTIVE.NC) THEN
          STR.NC = TUIinput("MAKE NEW DIRECTORY","Directory name:","NewDir", FILECHARS.NC)
          IF STR.NC<>"" THEN
            NCserialOut("M" + STR.NC)                       
            NCchangeDir(0,PATH.NC(0))
            NCchangeDir(1,PATH.NC(1))
            NCcursor(ACTIVE.NC,1)
          ENDIF
        ELSE
          STR.NC = TUIinput("MAKE NEW DIRECTORY","Directory name:","NewDir", FILECHARS.NC)
          IF STR.NC<>"" THEN
            IF NCmkdir(CUR_PATH.NC+STR.NC) THEN 
              NCerror("MakeDir '" + STR.NC + "' ERROR")
            ELSE
              NCchangeDir(0,PATH.NC(0))
              NCchangeDir(1,PATH.NC(1))
              NCcursor(ACTIVE.NC,1)
            ENDIF
          ENDIF
        ENDIF
      ENDIF

    CASE 152  'F8, DEL 127 is sometimes stuck...
      IF EN_MENU.NC(7) THEN
        IF NCisSerial(ACTIVE.NC) THEN
          IF TUIquestion("DELETE", "Delete '" + MID$(SELECTED.NC,2) + "', really proceed?") THEN
            NCserialOut("K" + MID$(SELECTED.NC,2))
            NCchangeDir(0,PATH.NC(0))
            NCchangeDir(1,PATH.NC(1))
            NCcursor(ACTIVE.NC,1)
          ENDIF
        ELSE
          IF LEFT$(SELECTED.NC,3)<>"D.." THEN
            NCdelete
          ENDIF
        ENDIF
      ENDIF

    CASE 153  'F9
      IF EN_MENU.NC(8) THEN
        NCsearch
      ENDIF

    CASE 154  'F10
      IF EN_MENU.NC(9) THEN
        IF TUIquestion("QUIT", "Are you redy to leave me alone?") THEN
          NCchdir PATH.NC(ACTIVE.NC)
          CLS
          END
        ENDIF
      ENDIF

    CASE 155  'F11
      IF EN_MENU.NC(10) THEN
        NCconfig
      ENDIF

    CASE 156  'F12
      IF EN_MENU.NC(11) THEN
        'TUIwarning("F12", PATH.NC(ACTIVE.NC))
        NCchangeDir(1-ACTIVE.NC,PATH.NC(ACTIVE.NC))        
        NCredrawPane(1-ACTIVE.NC)
      ENDIF

    CASE ASC("H")
      HIDDEN.NC = 1 - HIDDEN.NC
      NCdrawCL(PATH.NC(ACTIVE.NC))
      NCdrawMenu
      NCchangeDir(0,PATH.NC(0))
      NCchangeDir(1,PATH.NC(1))
      NCcursor(ACTIVE.NC,1)

    CASE ASC("U")
      UNSORT.NC = 1 - UNSORT.NC
      NCdrawCL(PATH.NC(ACTIVE.NC))
      NCdrawMenu
      NCchangeDir(0,PATH.NC(0))
      NCchangeDir(1,PATH.NC(1))
      NCcursor(ACTIVE.NC,1)

    CASE 134  'HOME
      NChome
      
    CASE 135  'END
      NCend

  END SELECT
  'ON KEY NCkey
END SUB

FUNCTION NClTrim(s AS STRING) AS STRING
  'left trim function (removes spaces from left)

  NClTrim = s
  DO WHILE LEFT$(NClTrim,1)=" "
    NClTrim = MID$(NClTrim, 2)
  LOOP
END FUNCTION

SUB NCgetInfo(filePath AS STRING)
  'get info and save it into 
  LOCAL STRING lin, ex = UCASE$(NCgetExtension(filePath))

  SELECT CASE ex
    CASE "BAS", "INC"
      ON ERROR SKIP
      OPEN NC_PATH.NC + INFO.NC FOR OUTPUT AS #3
      IF MM.ERRNO = 0 THEN
        ?#3,"FILE INFO for '" + filePath + "' (" + STR$(MM.INFO(FILESIZE filePath)) + " bytes):"
        ?#3,"BASIC PROGRAM or INCLUDE FILE"
        ?#3
        ?#3,"SUBs and FUNCTIONs:"
        OPEN filePath FOR INPUT AS #4
        lin = ""
        DO WHILE NOT EOF(#4)
          IF lin = "" THEN LINE INPUT #4, lin      
          lin = NClTrim(lin)      
          IF LEFT$(lin,4) = "SUB " OR LEFT$(lin,9) = "FUNCTION " THEN
            ?#3, lin
            
            IF NOT EOF(#4) THEN
              LINE INPUT #4, lin      
              lin = NClTrim(lin)
              IF LEFT$(lin, 1) = "'" THEN 
                ?#3, "  "lin 'first comment after SUB/FUNCTION is description
                lin = ""
              ENDIF
            ENDIF
          ELSE
            lin = ""
          ENDIF          
        LOOP
        CLOSE #4
        CLOSE #3
        NCviewTXT(NC_PATH.NC + INFO.NC)
      ENDIF

    CASE ELSE
      TUIwarning("GET INFO",filePath)
  END SELECT
END SUB

SUB NCconfig
  'configure NC

  LOCAL STRING txt = "External viewers enabled"
        txt = txt + ",External actions enabled"
        txt = txt + ",ESC to parent dir"
        txt = txt + ",DIRs before FILEs"
        txt = txt + ",TEXT VIEWER fallback (BIN else)"
        txt = txt + ",HIGH COLOR mode"
      
  LOCAL INTEGER sel = NCconfigPack()
  LOCAL INTEGER oldSel = sel
  sel = TUIselect("CONFIGURATION",txt,sel)
  NCconfigUnpack(sel)
  
  oldSel = sel XOR oldSel 'difference between OLD and NEW settings  
  IF oldSel AND 32 THEN
    IF CFG_HighColor.NC THEN
      MODE 1,16
    ELSE
      MODE 1,8
    ENDIF
    FONT 8
  ENDIF 
  IF (oldSel AND 8) OR (oldSel AND 32) THEN 'changed MODE or items sorting
    NCchangeDir(0,PATH.NC(0))
    NCchangeDir(1,PATH.NC(1))
    NCdrawMenu
    NCdrawCL(PATH.NC(ACTIVE.NC))
    NCcursor(ACTIVE.NC,1)
  ENDIF
  IF oldSel <> 0 THEN 
    NCconfigSave(sel)
  ENDIF
END SUB

FUNCTION NCconfigPack() AS INTEGER
  'pack config into integer

  NCconfigPack = CFG_ExtView.NC + 2*CFG_ExtAct.NC + 4*CFG_ESCup.NC
  NCconfigPack = NCconfigPack + 8*CFG_DirFil.NC + 16*CFG_TXTfb.NC + 32*CFG_HighColor.NC
END FUNCTION

SUB NCconfigSave(sel AS INTEGER)
  'save config
  OPEN NC_PATH.NC + "NC.CFG" FOR OUTPUT AS #3
  ?#3,BIN$(sel)
  CLOSE #3
END SUB

SUB NCconfigLoad
  'load config

  LOCAL STRING sCfg
  LOCAL INTEGER iCfg
  ON ERROR SKIP
  OPEN NC_PATH.NC + "NC.CFG" FOR INPUT AS #3
  IF MM.ERRNO = 0 THEN
    LINE INPUT #3, sCfg
    iCfg = VAL("&b"+sCfg)
    CLS
    NCconfigUnpack(iCfg)
    CLOSE #3
  ENDIF
END SUB

SUB NCconfigUnpack(sel AS INTEGER)
  'unpack config from integer

  CFG_ExtView.NC = (sel AND 1) > 0 
  CFG_ExtAct.NC = (sel AND 2) > 0
  CFG_ESCup.NC = (sel AND 4) > 0
  CFG_DirFil.NC = (sel AND 8) > 0
  CFG_TXTfb.NC = (sel AND 16) > 0
  CFG_HighColor.NC = (sel AND 32) > 0
END SUB

SUB NCfindFirstChar(ch AS STRING)
  'find item which begins with ch

  LOCAL INTEGER i
  
  IF LCASE$(MID$(SELECTED.NC, 2, 1)) = ch AND LEFT$(SELECTED.NC, 1) = "D" THEN
    FOR i = 0 TO COUNT.NC(ACTIVE.NC)
      IF LEFT$(ITEM.NC(ACTIVE.NC,i), 1) = "F" AND LCASE$(MID$(ITEM.NC(ACTIVE.NC,i),2,1)) = ch THEN
        NCsetCurPos(ACTIVE.NC, i)
        EXIT FOR
      ENDIF
    NEXT i
  ELSE 
    FOR i = 0 TO COUNT.NC(ACTIVE.NC)
      IF LCASE$(MID$(ITEM.NC(ACTIVE.NC,i),2,1)) = ch THEN
        NCsetCurPos(ACTIVE.NC, i)
        EXIT FOR
      ENDIF
    NEXT i
  ENDIF
END SUB

SUB NCsetCurPos(side AS INTEGER, ind AS INTEGER)
  'find optimal POS and CURSOR position for ind

  LOCAL INTEGER actCur, actPos
  LOCAL INTEGER maxPos = MAX(0, COUNT.NC(side) - MAX_ROWS.NC)
  IF ind <= COUNT.NC(side) THEN
    actcur = MAX_ROWS.NC\2
    actPos = ind - actCur
    DO WHILE actPos < 0
      INC actCur, -1
      INC actPos
    LOOP
    DO WHILE actPos > maxPos
      INC actCur
      INC actPos, -1
    LOOP
    CURSOR.NC(side) = actCur
    POS.NC(side) = actPos
    NCredrawPane(side)
    NCcursor(side,1)
  ENDIF
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

FUNCTION NCparent(p AS STRING) AS STRING
  'get parent folder

  NCparent = p
  IF RIGHT$(NCparent,1)="/" THEN NCparent = LEFT$(NCparent,LEN(NCparent)-1)
  DO WHILE RIGHT$(NCparent,1)<>"/"
    NCparent = LEFT$(NCparent,LEN(NCparent)-1)
  LOOP
END FUNCTION

SUB NCdelete(noWarning AS INTEGER)
  'delete item


  IF NOT noWarning THEN
    IF NOT TUIquestion("DELETE", "Delete '" + MID$(SELECTED.NC,2) + "', really proceed?") THEN
      EXIT SUB
    ENDIF
  ENDIF
  IF LEFT$(SELECTED.NC,1)="D" THEN
    IF NCrmdir(CUR_PATH.NC+MID$(SELECTED.NC,2)) THEN 
      NCdeleteDir(CUR_PATH.NC+MID$(SELECTED.NC,2))
      IF INSTR(PATH.NC(0),CUR_PATH.NC+MID$(SELECTED.NC,2))>0 THEN
        PATH.NC(0) = NCparent(CUR_PATH.NC+MID$(SELECTED.NC,2))
      ENDIF
      IF INSTR(PATH.NC(1),CUR_PATH.NC+MID$(SELECTED.NC,2))>0 THEN
        PATH.NC(1) = NCparent(CUR_PATH.NC+MID$(SELECTED.NC,2))
      ENDIF
    ENDIF
  ELSE
    HLP.NC = NCkill(CUR_PATH.NC+MID$(SELECTED.NC,2))
  ENDIF
  NCchangeDir(0,PATH.NC(0))
  NCchangeDir(1,PATH.NC(1))
  NCcursor(ACTIVE.NC,1)
END SUB

SUB NChelp
  'show help

  LOCAL STRING txt = "About NC,Shortcuts,Manual"
  
  LOCAL INTEGER h = TUIchoice("CHOOSE SECTION", txt)
  SELECT CASE h
    CASE <0 'ESC
      'TUIwarning("HELP","You was no able to choose :-(")

    CASE 0
      LOCAL STRING about(7) LENGTH 100
      about(0) = "              My name is Napoleon Commander (" + NCdigital(VERSION) + ")"
      about(1) = ""
      about(2) = "              Born on: 7. November 2020"
      about(3) = "              Where  : Czech Republic"
      about(4) = "              Father : " + CHR$(157) + "JirSoft"
      about(5) = "              Mother : Unknown"
      about(6) = ""
      about(7) = "              I'm living inside of Colour Maximite 2 "
      TUIinfo("ABOUT ME",about(), LOGO.NC)
      
    CASE 1
      LOCAL STRING shrt(27) LENGTH 100
      shrt( 0) = "          Napoleon Commander " + VERSION
      shrt( 1) = ""
      shrt( 2) = "ALT+F1/F2 Selects source for left or right pane (SD card or SERVER)"
      shrt( 3) = ""
      shrt( 4) = CHR$(225) + " " + CHR$(226) + "       Up/Down  Moves row on active pane"
      shrt( 5) = "Home/End  Jumps to first/last row"
      shrt( 6) = "TAB       Switches active pane"
      shrt( 7) = "Keys a-z  Jumps to first item with this char on begin in DIRs or FILEs,"
      shrt( 8) = "          second press jumps to the other group"
      shrt( 9) = "ENTER     Changes active directory or invoke action"
      shrt(10) = "ESC       Jumps to parent directory (if possible)"
      shrt(11) = "Shift+H   Shows or hide hidden items"
      shrt(12) = "Shift+U   Unsorted SD card layout"
      shrt(13) = "PrintScr  Saves screen to 'ScreenShot.BMP', with LALT just dialog"
      shrt(14) = ""
      shrt(15) = "F1        Shows this help"
      shrt(16) = "F2        Gets info, size for DIR, info for FILE"
      shrt(17) = "F3        Quick (& dirty) file viewer"
      shrt(18) = "F4        Quick editor (not done yet)"
      shrt(19) = "F5        Copies file or directory"
      shrt(20) = "F6        Moves or rename (if both panes are same)"
      shrt(21) = "F7        Creates new directory"
      shrt(22) = "F8        Deletes file or directory"
      shrt(23) = "F9        RESERVED"
      shrt(24) = "F10       Quits NC"
      shrt(25) = "F11       NC Configuration"
      shrt(26) = "F12       Duplicates view to inactive pane"
      shrt(27) = ""
  
      TUIinfo("KEYBOARD SHORTCUTs",shrt())
      
    CASE 2
      NCviewTXT(MANUAL.NC)

    CASE ELSE
      TUIwarning("HELP","Choosen '" + FIELD$(txt,h+1,",") + "', but section still missing...")

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

  STR.NC = TUIinput("RENAME ITEM", "New name:",NCnewName(CUR_PATH.NC,MID$(SELECTED.NC,2)), FILECHARS.NC)

  IF NCrename(CUR_PATH.NC+MID$(SELECTED.NC,2), CUR_PATH.NC+STR.NC) THEN 
    NCerror("RENAME '" + MID$(SELECTED.NC,2) + "' ERROR") 
  ELSE
    NCchangeDir(0,PATH.NC(0))
    NCchangeDir(1,PATH.NC(1))
    NCcursor(ACTIVE.NC,1)
  ENDIF
END SUB

SUB NCcopyFile(source AS STRING, dest AS STRING, noWarning AS INTEGER)
  'copy file

  IF noWarning THEN
    IF NOT TUIquestion("COPY FILE","Copy '" + NCgetName(source) + "' to '" + NCgetPath(dest) + "'?") THEN         
      EXIT SUB
    ENDIF
  ENDIF

  IF NCcopy(source, dest) THEN 
    NCerror("COPY '" + NCgetName(source) + "' ERROR")
  ELSE
    NCchangeDir(0,PATH.NC(0))
    NCchangeDir(1,PATH.NC(1))
    NCcursor(ACTIVE.NC,1)
  ENDIF 
END SUB

SUB NCmoveFile(source AS STRING, dest AS STRING)
  'move file

  IF TUIquestion("MOVE FILE","Move '"+source+"' to '"+dest+"'?") THEN         
    IF NCcopy(source, dest) THEN 
      NCerror("COPY '" + NCgetName(source) + "' ERROR")
    ELSE
      IF NCkill(source) THEN
        NCchangeDir(0,PATH.NC(0))
        NCchangeDir(1,PATH.NC(1))
        NCcursor(ACTIVE.NC,1)
      ELSE
        NCerror("DELETE '" + NCgetName(source) + "' ERROR")
      ENDIF
    ENDIF 
  ENDIF
END SUB

SUB NCaction(p AS STRING, s AS STRING)
  'ENTER pressed on file (skeleton)

  LOCAL STRING extAction, ex = UCASE$(NCgetExtension(s))

  SELECT CASE ex
    CASE "BMP"
      CLS
      LOAD BMP p+s
      DO:LOOP WHILE INKEY$=""
      DO:LOOP WHILE INKEY$<>""
      NCredrawPane(0)
      NCredrawPane(1)  
      NCcursor(ACTIVE.NC,1)
      NCdrawMenu
      
    CASE "JPG"
      CLS
      LOAD JPG p+s
      DO:LOOP WHILE INKEY$=""
      DO:LOOP WHILE INKEY$<>""
      NCredrawPane(0)
      NCredrawPane(1)  
      NCcursor(ACTIVE.NC,1)
      NCdrawMenu

    CASE "PNG"
      CLS
      LOAD PNG p+s
      DO:LOOP WHILE INKEY$=""
      DO:LOOP WHILE INKEY$<>""
      NCredrawPane(0)
      NCredrawPane(1)  
      NCcursor(ACTIVE.NC,1)
      NCdrawMenu

    CASE "GIF"
      CLS
      LOAD GIF p+s
      DO:LOOP WHILE INKEY$=""
      DO:LOOP WHILE INKEY$<>""
      NCredrawPane(0)
      NCredrawPane(1)  
      NCcursor(ACTIVE.NC,1)
      NCdrawMenu

    CASE ELSE
      EXT_ERR.NC = -1
      IF CFG_ExtAct.NC THEN
        extAction = "EXTaction" + ex
        ON ERROR SKIP
        CALL extAction, p+s
        IF EXT_ERR.NC < 0 THEN
          IF MM.ERRNO>0 THEN 
            TUIwarning("ACTION " + ex,"External action not available")
          ENDIF
        ENDIF
      ENDIF

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

SUB NCredrawPane(side AS INTEGER)
  'redraw pane

  LOCAL STRING short = PATH.NC(side)
  LOCAL INTEGER i, fcol = RGB(WHITE)

  IF LEN(short)>46 THEN short = LEFT$(short,45)+"~"

  PAGE WRITE 1
  BOX 400*side,0,400,568,0,,RGB(BLACK)
  BOX 400*side,0,400,566,0,,RGB(BLUE)
  BOX 400*side+1,0+6,400-3,568-15,2,RGB(WHITE),RGB(BLUE)
  IF side = ACTIVE.NC THEN
    TEXT 400*side+200,0," "+short+" ","CT",8,,RGB(BLUE),RGB(WHITE)
  ELSE
    TEXT 400*side+200,0," "+short+" ","CT",8,,RGB(WHITE),RGB(BLUE)
  ENDIF
  TEXT 400*side+200,600-52,NCcounter(side),"CT",,,RGB(WHITE),RGB(BLUE)
  
  FOR i = POS.NC(side) TO MIN(COUNT.NC(side), MAX_ROWS.NC+POS.NC(side))
    STR.NC = ITEM.NC(side,i)
    IF LEFT$(STR.NC,1)="D" THEN
      fcol = RGB(YELLOW) 'dir
    ELSE
      fcol = RGB(WHITE) 'file
    ENDIF     
    IF MID$(STR.NC,2,1)="." THEN
      fcol = RGB(RED) 'hidden file/dir
    ENDIF
    TEXT 400*side+8, 16*(i-POS.NC(side)+1),NCout(ITEM.NC(side,i)),,,,fcol,RGB(BLUE)
  NEXT i
  PAGE WRITE 0
  BLIT 400*side,0,400*side,0,400,568,1
END SUB

FUNCTION NCout(s AS STRING) AS STRING
  'prepare string

  NCout = NCname(MID$(FIELD$(s,1,"|"),2)) + " " + RIGHT$(SPACE$(9)+FIELD$(s,2,"|"),9) + " " + RIGHT$(SPACE$(14)+FIELD$(s,3,"|"),14)
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
    NCsize = "DIRECTORY"
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

FUNCTION NCdigital(s AS STRING) AS STRING
  LOCAL INTEGER i
  LOCAL STRING c

  FOR i = 1 TO LEN(s)
    c = MID$(s, i, 1)
    IF INSTR("0123456789", c) > 0 THEN
      NCdigital = NCdigital + CHR$(ASC(c) - 48 + 240)
    ELSE
      NCdigital = NCdigital + c
    ENDIF
  NEXT i
END FUNCTION

SUB NCdrawCL(p AS STRING)
  'outputs command line

  BOX 0,568,800,16,0,,RGB(BLACK)
  TEXT 3*8, 568,p,"LT",8,,RGB(WHITE),RGB(BLACK)
  TEXT 800,568,NCdigital(VERSION),"RT",8,,RGB(RED)
  IF HIDDEN.NC THEN
    TEXT 0,568,"H","LT",8,,RGB(RED),RGB(BLACK)
  ENDIF
  IF UNSORT.NC THEN
    TEXT 8,568,"U","LT",8,,RGB(RED),RGB(BLACK)
  ENDIF
END SUB

SUB NCcursor(side AS INTEGER, show AS INTEGER)
  'show or hide cursor

  LOCAL STRING short = PATH.NC(side)
  LOCAL INTEGER hid = MID$(ITEM.NC(side,CURSOR.NC(side)+POS.NC(side)),2,1)="." 
  LOCAL INTEGER fcol
  CUR_PATH.NC = PATH.NC(side)

  IF LEN(short)>46 THEN short = LEFT$(short,45)+"~"
  
  IF LEFT$(ITEM.NC(side,CURSOR.NC(side)+POS.NC(side)),1) = "D" THEN
    fcol = RGB(YELLOW) 'dir
  ELSE
    fcol = RGB(WHITE) 'file
  ENDIF
  IF show THEN
    'TEXT 400*side+200,0," "+short+" ","CT",,,RGB(BLUE),RGB(WHITE)
    IF hid THEN
      TEXT 400*side+8, 16*(CURSOR.NC(side)+1),NCout(ITEM.NC(side,CURSOR.NC(side)+POS.NC(side))),,,,RGB(BLUE),RGB(RED)
    ELSE
      TEXT 400*side+8, 16*(CURSOR.NC(side)+1),NCout(ITEM.NC(side,CURSOR.NC(side)+POS.NC(side))),,,,RGB(BLUE),fcol
    ENDIF
    COMPLETE.NC = ITEM.NC(side,CURSOR.NC(side)+POS.NC(side))
    SELECTED.NC = FIELD$(COMPLETE.NC, 1, "|")
    NCdrawCL(CUR_PATH.NC + MID$(SELECTED.NC,2))        
    TEXT 400*side+200,600-52,NCcounter(side),"CT",,,RGB(WHITE),RGB(BLUE)
  ELSE
    'TEXT 400*side+200,0," "+short+" ","CT",,,RGB(WHITE),RGB(BLUE)
    IF hid THEN
      TEXT 400*side+8, 16*(CURSOR.NC(side)+1),NCout(ITEM.NC(side,CURSOR.NC(side)+POS.NC(side))),,,,RGB(RED),RGB(BLUE)
    ELSE
      TEXT 400*side+8, 16*(CURSOR.NC(side)+1),NCout(ITEM.NC(side,CURSOR.NC(side)+POS.NC(side))),,,,fcol,RGB(BLUE)
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

  IF UNSORT.NC THEN EXIT SUB
  LOCAL INTEGER mi, i, j
  LOCAL STRING ms
  
  FOR i = 1 TO COUNT.NC(side)
    mi = i - 1
    ms = ITEM.NC(side,mi)
    FOR j = i TO COUNT.NC(side)
      IF CFG_DirFil.NC THEN
        IF UCASE$(ITEM.NC(side,j)) < UCASE$(ms) THEN
          mi = j
          ms = ITEM.NC(side,mi)
        ENDIF
      ELSE
        IF UCASE$(MID$(ITEM.NC(side,j),2)) < UCASE$(MID$(ms,2)) THEN
          mi = j
          ms = ITEM.NC(side,mi)
        ENDIF
      ENDIF
    NEXT j
    ITEM.NC(side,mi) = ITEM.NC(side,i-1)
    ITEM.NC(side,i-1) = ms 
  NEXT i
END SUB

SUB NCsetChar(s AS STRING, p AS INTEGER, c AS STRING)
  'MID$ set

  s = LEFT$(s,p-1) + c + MID$(s, p+1)
END SUB

SUB NCerror(title AS STRING)
  'shows BASIC error

  TUIwarning(title, FIELD$(MM.ERRMSG$,2,":"))
END SUB

SUB NCdeleteDir(start AS STRING)
  'delete complete dir, recursion was not used

  LOCAL INTEGER ind = 0, td=0, size
  LOCAL STRING item, path
  LOCAL STRING pth(MAX_ITEMS.NC)
  LOCAL STRING toDo(MAX_ITEMS.NC)
 
  LOCAL STRING ccc = TUIwaitingON("DELETE DIR") 
  pth(ind) = start
  toDo(td) = "R" + start
  DO WHILE ind >= 0
    NCchdir pth(ind)
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
      HLP.NC = NCkill(MID$(toDo(ind),2))
    ELSE
      NCchdir MID$(toDo(ind),2)+"/.."
      HLP.NC = NCrmdir(NCfilePart(MID$(toDo(ind),2)))
    ENDIF
  NEXT ind
  TUIwaitingOFF(ccc)
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

  IF LEFT$(dest, LEN(source)) = source THEN
    TUIwarning("COPY DIR ","Copy "+ source + " into " + dest + " is VERY bad idea!")
    EXIT SUB
  ENDIF  
  LOCAL INTEGER ind = 0, size
  LOCAL STRING item, path,dst
  LOCAL STRING pth(MAX_ITEMS.NC)
  LOCAL STRING dialog = TUIwaitingON("COPY DIRECTORY")
  
  pth(ind) = source

  IF NCmkdir(dest) THEN 
    NCerror("COPY DIR")
  ELSE
    DO WHILE ind >= 0
      NCchdir pth(ind)
      path = pth(ind)
      ind = ind - 1
      item = DIR$("", ALL)
      DO WHILE item <> ""
        size = MM.INFO(FILESIZE item)
        IF size<0 THEN
          'directory
          'TUIwarning("COPY DIR", "Create dir '" + NCsource2dest(source,dest,path + item) + "'")
          HLP.NC = NCmkdir(NCsource2dest(source,dest,path + item))

          ind = ind + 1
          pth(ind) = path + item + "/"                
        ELSE
          'file
          'TUIwarning("COPY DIR", "Copy file '" + path + item + "' to '" + NCsource2dest(source,dest,path + item) + "'")
          COPY path+item TO NCsource2dest(source,dest,path + item)
        ENDIF
        item = DIR$()
      LOOP
    LOOP
  
    TUIwaitingOFF(dialog)
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
    NCchdir pth(ind)
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
        IF b>=32 AND b<=127 THEN
          TEXT 600+i*8,firstRow + row, CHR$(b),"LT",8,,RGB(BLACK), RGB(CYAN)
        ELSE
          TEXT 600+i*8,firstRow + row, ".","LT",8,,RGB(BLACK), RGB(CYAN)
        ENDIF
      NEXT i          
      row = row + 16
      cnt = cnt + 16
    LOOP
    
    DO WHILE change = 0 AND k<>ESC.NC
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
  LOOP WHILE k<>ESC.NC
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

  LOCAL INTEGER firstRow = 16+4, row = 0, cnt = 0, pg = 0, crPos, lfPos
  LOCAL INTEGER maxpage = 0, viewpage = 0, change = 0
  LOCAL STRING li, k

  OPEN filePath FOR INPUT AS #3
  DO WHILE NOT EOF(#3)
    'li = INPUT$(100, #3)
    'crPos = INSTR(li, CR.NC)
    'IF crPos > 0 THEN li = LEFT$(li, crPos - 1)
    'lfPos = INSTR(li, LF.NC)
    'IF lfPos > 0 THEN li = LEFT$(li, lfPos - 1)  
    ON ERROR SKIP
    LINE INPUT #3, li
    IF MM.ERRNO>0 THEN
      TUIwarning("TXT VIEWER", "Too long lines")
      CLOSE #3
      EXIT SUB
    ENDIF
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
      'li = INPUT$(100, #3)
      'crPos = INSTR(li, CR.NC)
      'IF crPos > 0 THEN li = LEFT$(li, crPos - 1)
      'lfPos = INSTR(li, LF.NC)
      'IF lfPos > 0 THEN li = LEFT$(li, lfPos - 1)  
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
      'li = INPUT$(100, #3)
      'crPos = INSTR(li, CR.NC)
      'IF crPos > 0 THEN li = LEFT$(li, crPos - 1)
      'lfPos = INSTR(li, LF.NC)
      'IF lfPos > 0 THEN li = LEFT$(li, lfPos - 1)  
      LINE INPUT #3, li
      IF LEN(li)>100 THEN li = LEFT$(li,100)
      TEXT 0,firstRow + row, li,"LT",8,,RGB(BLACK), RGB(CYAN)
      row = row + 16 
    LOOP
    CLOSE #3

    DO WHILE change = 0 AND k<>ESC.NC
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
  LOOP WHILE k<>ESC.NC
  NCredrawPane(0)
  NCredrawPane(1)  
  NCcursor(ACTIVE.NC,1)
  NCdrawMenu
END SUB

SUB NCview
  'parent for viewer

  LOCAL STRING k, ex = UCASE$(NCgetExtension(MID$(SELECTED.NC,2))), exViewer

  SELECT CASE ex
    CASE "TXT", "BAS", "BAK", "INC", "FNT"
      'text view
      IF KEYDOWN(7) AND 1 THEN 'ALT F3 force HEX
        NCviewHEX(CUR_PATH.NC + MID$(SELECTED.NC,2))
      ELSE
        NCviewTXT(CUR_PATH.NC + MID$(SELECTED.NC,2))
      ENDIF

    CASE "BMP"
      NCviewBMP(CUR_PATH.NC + MID$(SELECTED.NC,2))

    CASE "PNG", "BMP", "JPG"
      'image view
      TUIwarning("IMAGE VIEW", "Viewer not available yet...")

    CASE ELSE
      EXT_ERR.NC = -1
      IF CFG_ExtView.NC THEN
        exViewer = "EXTview" + ex
        ON ERROR SKIP
        CALL exViewer, CUR_PATH.NC + MID$(SELECTED.NC,2)
      ENDIF
      IF EXT_ERR.NC < 0 THEN
        'fallback to HEX view
        IF CFG_TXTfb.NC THEN
          NCviewTXT(CUR_PATH.NC + MID$(SELECTED.NC,2))
        ELSE
          NCviewHEX(CUR_PATH.NC + MID$(SELECTED.NC,2))
        ENDIF
      ELSE
        'external viewer was available
        NCredrawPane(0)
        NCredrawPane(1)  
        NCcursor(ACTIVE.NC,1)
        NCdrawMenu
      ENDIF

  END SELECT
END SUB

SUB NCviewBMP(filePath AS STRING)
  'simple BMP viewer

  LOCAL STRING b
  LOCAL INTEGER tw, w, h, bpp, nw, nh

  LOCAL STRING ccc = TUIwaitingON("BMP VIEW")
  OPEN filePath FOR INPUT AS #3
  b = INPUT$(2, #3)
  SELECT CASE b
    CASE "BM"
      b = INPUT$(16, #3)
      b = INPUT$(4, #3)
      w = ABS(STR2BIN(INT32, b))
      b = INPUT$(4, #3)
      h = ABS(STR2BIN(INT32, b))
      b = INPUT$(2, #3)
      b = INPUT$(2, #3)
      bpp = STR2BIN(UINT16, b)
      CLOSE #3
      
      PAGE WRITE 2
      LOAD BMP filePath
      PAGE WRITE 1
      PAGE COPY 0 TO 1
      nw = w:nh = h
      IF nw > 600 THEN
        nw = 600
        nh = nh*600/w
      ENDIF
      IF nh > 500 THEN
        nw = nw*500/nh
        nh = 500
      ENDIF
      TUIwaitingOFF(ccc)
      BOX (800-nw)/2-4, (600-nh)/2-5,nw+8,nh+10,0,RGB(GREEN),RGB(GREEN)
      BOX (800-nw)/2-4, (600-nh)/2-5,nw+8,nh+10,2,RGB(BLACK)

      tw = 8*LEN(filePath+", "+STR$(w)+"x"+STR$(h)+", "+STR$(bpp)+"bpp")      
      BOX (800-tw)/2-4, (600-nh)/2+4+nh,tw+8,24,0,RGB(GREEN),RGB(GREEN)
      BOX (800-tw)/2-4, (600-nh)/2+4+nh,tw+8,24,2,RGB(BLACK)
      IMAGE RESIZE 0,0,w,h,(800-nw)/2, (600-nh)/2,nw,nh,2
      TEXT 400,(600-nh)/2+nh+8,filePath+", "+STR$(w)+"x"+STR$(h)+", "+STR$(bpp)+"bpp","CT",8,,RGB(BLACK), RGB(GREEN)
      PAGE WRITE 0
      PAGE COPY 1 TO 0


  END SELECT
  DO:LOOP WHILE INKEY$=""  
  NCredrawPane(0)
  NCredrawPane(1)  
  NCcursor(ACTIVE.NC,1)
  NCdrawMenu
END SUB

FUNCTION NCprepareLogo(f AS STRING) AS INTEGER
  'read ICN file

  LOCAL INTEGER i, w = 0, h = 0
  LOCAL STRING s

  ON ERROR SKIP
  OPEN NC_PATH.NC + f FOR INPUT AS #5
  IF MM.ERRNO = 0 THEN
    NCprepareLogo = 63
    PAGE WRITE 1
    CLS RGB(BLACK)
    DO WHILE NOT EOF(#5)
      LINE INPUT #5,s
      w = MAX(w, LEN(s))
      FOR i = 1 TO LEN(s)
        IF MID$(s,i,1)<>" " THEN
          PIXEL i-1,h,RGB(GRAY)
        ENDIF
      NEXT i
      INC h
    LOOP
    INC h
    CLOSE #5
    BLIT READ #63,0,0,w,h
    PAGE WRITE 0
  ELSE
    NCprepareLogo = 0
  ENDIF
END FUNCTION

SUB NCinit
  'INIT

  INIT.NC = 1
  LOGO.NC = NCprepareLogo("NAPOLEON.ICN")

  NCconfigLoad
  IF CFG_HighColor.NC THEN
    MODE 1,16
  ELSE
    MODE 1,8
  ENDIF


  CURSOR.NC(0) = 0
  CURSOR.NC(1) = 0       'left and right cursor
  POS.NC(0) = 0
  POS.NC(1) = 0       'left and right position
  COUNT.NC(0) = -1
  COUNT.NC(1) = -1 'left and right items count
  PATH.NC(0) = CUR_PATH.NC                   'left path
  PATH.NC(1) = CUR_PATH.NC                  'right path

  LOAD FONT NC_PATH.NC + "AtariST.FNT"
  FONT #8,1
  CLS
  NCsetMenu(0, "Help", 1)
  NCsetMenu(1, "GetInf", 1)
  NCsetMenu(2, "Viewer" , 1)
  NCsetMenu(3, "Editor" , 0)
  NCsetMenu(4, "Copy"   , 1)
  NCsetMenu(5, "RenMov", 1)
  NCsetMenu(6, "MakDir", 1)
  NCsetMenu(7, "Delete", 1)
  NCsetMenu(8, "RESERV", 0)
  NCsetMenu(9, "QuitNC", 1)
  NCsetMenu(10,"Config", 1)
  NCsetMenu(11,"LP=RP", 1)
 
  NCdrawMenu
END SUB

FUNCTION NCmkdir(filePath AS STRING) AS INTEGER
  'mkedir 

  ON ERROR SKIP
  MKDIR filePath
  NCmkdir = MM.ERRNO
END FUNCTION

FUNCTION NCrmdir(filePath AS STRING) AS INTEGER
  'rmdir

  ON ERROR SKIP
  RMDIR CUR_PATH.NC+MID$(SELECTED.NC,2)
  NCrmdir = MM.ERRNO
END FUNCTION

FUNCTION NCkill(filePath AS STRING) AS INTEGER
  'kill

  ON ERROR SKIP
  KILL filePath
  NCkill = MM.ERRNO
END FUNCTION

FUNCTION NCrename(source AS STRING, dest AS STRING) AS INTEGER
  'rename

  ON ERROR SKIP
  RENAME source AS dest
  NCrename = MM.ERRNO
END FUNCTION

SUB NCchdir(path AS STRING)
  'chdir

  ON ERROR SKIP
  CHDIR path
END SUB

SUB initDebug
  'erase debug file

  OPEN NC_PATH.NC + "DEBUG.TXT" FOR OUTPUT AS #6
  CLOSE #6
END SUB

SUB outDebug(s AS STRING)
  'append to debug file

  OPEN NC_PATH.NC + "DEBUG.TXT" FOR APPEND AS #6
  PRINT #6, "  CHDIR " + s
  CLOSE #6
END SUB

FUNCTION NCinsideTest(source AS STRING, dest AS STRING) AS INTEGER
  'stop recursion

  NCinsideTest = LEFT$(dest, LEN(source)) = source
END FUNCTION

FUNCTION NCcopy(source AS STRING, dest AS STRING) AS INTEGER
  'copy

  ON ERROR SKIP
  COPY source TO dest
  NCcopy = MM.ERRNO
END FUNCTION

SUB NCchangeDir(side AS INTEGER, p AS STRING)
  'change dir in pane

  LOCAL STRING f, size, kind

  IF LEFT$(p, 3) = "S:/" THEN
    'TUIwarning("CHANGE DIR", "'" + p + "'")
    NCserialOut("D" + p)
    NCserialDir(side)
    'PATH.NC(side) = SERIAL_PATH.NC
    POS.NC(side) = 0
    CURSOR.NC(side) = 0
    NCredrawPane(side)
  ELSE

    PATH.NC(side) = p
    NCchdir p

    IF UCASE$(PATH.NC(side))<>"A:/" THEN
      ITEM.NC(side,0) = "D..|[ GO UP ]"
      COUNT.NC(side) = 0
    ELSE
      COUNT.NC(side)=-1
    ENDIF
    f = DIR$("", ALL)
    DO WHILE f <> ""
      IF LEFT$(f,1)<> "." OR HIDDEN.NC THEN
        COUNT.NC(side) = COUNT.NC(side) + 1
        size = NCsize(f)
        IF size = "DIRECTORY" THEN
          kind = "D"
        ELSE
          kind = "F"
        ENDIF
        ITEM.NC(side,COUNT.NC(side)) = kind + f + "|" + NCsize(f) +"|" + NCdateTime(f)
      ENDIF
      f = DIR$()
    LOOP
    POS.NC(side) = 0
    CURSOR.NC(side) = 0
    NCsort(side)
    NCredrawPane(side)

    NCchdir CUR_PATH.NC
  ENDIF
END SUB

FUNCTION NCreadUntilLF() AS STRING
  'read line up to LF from serial

  LOCAL STRING one = ""
  LOCAL INTEGER timeout = TIMER

  NCreadUntilLF = ""

  DO WHILE (one <> LF.NC) AND ((TIMER - timeout) < SERIAL_TIMEOUT.NC)
    IF LOC(#1) > 0 THEN
      one = INPUT$(1, #1)
      IF one = LF.NC THEN
        NCreadUntilLF = SERIAL_IN.NC
        SERIAL_IN.NC = ""
      ELSE
        IF LEN(SERIAL_IN.NC) < 250 THEN
          SERIAL_IN.NC = SERIAL_IN.NC + one
        ELSE
          SERIAL_IN.NC = one
        ENDIF
      ENDIF
      timeout = TIMER
    ENDIF
  LOOP  
END FUNCTION

SUB NCserialDir(side AS INTEGER)
  'get dir from serial

  LOCAL INTEGER i, cnt
  LOCAL STRING lineSerial

  lineSerial = NCreadUntilLF()
  'TUIwarning("SERIAL DIR", "'" + lineSerial + "'")
  IF LEFT$(lineSerial,1) = "D" THEN
    cnt = VAL(MID$(lineSerial,2)) - 1
    PATH.NC(side) = FIELD$(lineSerial, 2, "|")
    COUNT.NC(side) = -1
    FOR i = 0 TO cnt
      lineSerial = NCreadUntilLF()    
      IF MID$(lineSerial, 2, 1) = "." THEN
        IF HIDDEN.NC OR LEFT$(lineSerial, 3) = "D.." THEN
          COUNT.NC(side) = COUNT.NC(side) + 1 
          ITEM.NC(side, COUNT.NC(side)) = lineSerial
        ENDIF
      ELSE
        COUNT.NC(side) = COUNT.NC(side) + 1 
        ITEM.NC(side, COUNT.NC(side)) = lineSerial
      ENDIF
    NEXT i
    IF NOT UNSORT.NC THEN NCsort(side)
  ENDIF
END SUB

FUNCTION NCisSerial(side AS INTEGER) AS INTEGER
  'is this side serial?

  NCisSerial = LEFT$(PATH.NC(side),1) = "S"
END FUNCTION

SUB NCserverCopy(source AS STRING, dest AS STRING)
  'copy to/from/on server

  CONST partLen = 250
  LOCAL STRING partData, dialog
  LOCAL INTEGER partNum, partRem, fileLen = MM.INFO(FILESIZE source), i

  IF NCisSerial(1-ACTIVE.NC) THEN
    IF NCisSerial(ACTIVE.NC) THEN
      'server to server
      IF TUIquestion("SERVER->SERVER COPY","Copy '" + NCgetName(source) + "' to '" + NCgetPath(dest) + "'?") THEN
        NCserialOut("C" + source + "|" + NCgetPath(dest))
        partData = NCreadUntilLF()
        IF partData = "DONE" THEN
          NCserialOut("D" + PATH.NC(1-ACTIVE.NC))
          NCserialDir(1-ACTIVE.NC)
          POS.NC(1-ACTIVE.NC) = 0
          CURSOR.NC(1-ACTIVE.NC) = 0
          NCredrawPane(1-ACTIVE.NC)
        ENDIF
      ENDIF
    ELSE
      'local to server
      IF TUIquestion("LOCAL->SERVER COPY","Copy '" + NCgetName(source) + "' to '" + NCgetPath(dest) + "'?") THEN
        NCserialOut("W" + NCgetName(source) + "|" + STR$(fileLen))
        partData = NCreadUntilLF()
        IF partData = "READY" THEN
          partNum = fileLen \ partLen
          partRem = fileLen MOD partLen

          dialog = TUIwaitingON("SERVER WRITE " + STR$(fileLen) + " bytes")

          OPEN source FOR INPUT AS #2

          FOR i = 1 TO partNum
            IF fileLen > 10000 THEN
              TUIwaitingProgress(dialog, 100 * i / partNum)
            ENDIF
            partData = INPUT$(partLen, #2)
            ?#1, partData;         
          NEXT i 

          IF partRem > 0 THEN
            partData = INPUT$(partRem, #2)
            ?#1, partData;         
          ENDIF

          CLOSE #2
          TUIwaitingOFF(dialog)
          'dialog = TUIwaitingON("WAITING FOR SERVER RESPONSE")

          partData = NCreadUntilLF()
          'TUIwaitingOFF(dialog)
          IF partData = "DONE" THEN
            NCserialOut("D" + PATH.NC(1-ACTIVE.NC))
            NCserialDir(1-ACTIVE.NC)
            POS.NC(1-ACTIVE.NC) = 0
            CURSOR.NC(1-ACTIVE.NC) = 0
            NCredrawPane(1-ACTIVE.NC)
          ENDIF
        ENDIF
      ENDIF
    ENDIF
  ELSE
    'server to local
    IF TUIquestion("SERVER->LOCAL COPY","Copy '" + NCgetName(source) + "' to '" + NCgetPath(dest) + "'?") THEN
      'TUIwarning("SERVER COPY", COMPLETE.NC)
      fileLen = VAL(FIELD$(COMPLETE.NC, 2, "|"))
      NCserialOut("R" + source + "|" + STR$(partLen))
      partData = NCreadUntilLF()
      IF partData = "READY" THEN
        partNum = fileLen \ partLen
        partRem = fileLen MOD partLen
        dialog = TUIwaitingON("SERVER READ " + STR$(fileLen) + " bytes")

        OPEN dest FOR OUTPUT AS #2

        FOR i = 1 TO partNum
          IF fileLen > 10000 THEN
            TUIwaitingProgress(dialog, 100 * i / partNum)
          ENDIF
          NCserialOut("NEXT")         
          DO WHILE LOC(#1) < partLen
          LOOP
          partData = INPUT$(partLen, #1)
          ?#2, partData;
        NEXT i 

        IF partRem > 0 THEN
          NCserialOut("NEXT")         
          DO WHILE LOC(#1) < partRem
          LOOP
          partData = INPUT$(partRem, #1)
          ?#2, partData;         
        ENDIF

        CLOSE #2

        TUIwaitingOFF(dialog)
        partData = NCreadUntilLF()
        IF partData = "DONE" THEN
          NCchangeDir(1-ACTIVE.NC, PATH.NC(1-ACTIVE.NC))
          NCredrawPane(1-ACTIVE.NC)
        ENDIF
      ENDIF
    ENDIF
  ENDIF
END SUB

SUB NCserialOut(s AS STRING)
  'print to serial with LF

  IF SERIAL_ON.NC THEN
    ?#1,s + LF.NC;
  ENDIF
END SUB

