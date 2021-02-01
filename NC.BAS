#DEFINE "DBG ", "'"
'#DEFINE "DBG ", ""
'#MMDEBUG ON

OPTION BREAK 0
DBG OPTION BREAK 3


'Napoleon Commander
CONST VERSION.NC = "1.14"


CONST MIN_VERSION.NC = 5.06

OPTION EXPLICIT
OPTION DEFAULT NONE
OPTION BASE 0
OPTION CRLF CR


DIM INTEGER INIT.NC = 0
DIM STRING NC_PATH.NC = MM.INFO$(PATH)     'path to NC executable

NCinitDebug
NCchdir NC_PATH.NC

#INCLUDE "../LIB/TUI.INC"
#INCLUDE "../LIB/GRF.INC"
'#INCLUDE "TUI.INC"
'#INCLUDE "GRF.INC"
#INCLUDE "VIEWER.INC"
#INCLUDE "ACTION.INC"

CONST ICONS.NC = RGB(RED)
CONST RIGHT.NC = " " + CHR$(227) + " " 'right arrow
CONST FILECHARS.NC = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789()_-."
DIM STRING WIFICHARS.NC = ""
CONST MAX_ITEMS.NC = 1500 'max number of items in pane
CONST MAX_ROWS.NC = 32   'max row in list display
CONST EDIT_ROWS.NC = 35
CONST ESC.NC = CHR$(27)
CONST ENTER.NC = CHR$(10)
CONST CR.NC = CHR$(13)
CONST LF.NC = CHR$(10)
CONST FONT.NC = "NC.FNT"
CONST INFO.NC = "FILEINFO.TXT"
CONST FOUND.NC = "FOUND.TXT"
CONST SERIAL_TIMEOUT.NC = 3000

CONST BUFFER_LEN.NC = 100000 
DIM STRING SERIAL_INIT.NC = "COM3:230400,1024"
DIM STRING SERIAL_PATH.NC = ""
DIM INTEGER SERIAL_ON.NC = 0

DIM STRING ESP_SSID.NC
DIM STRING ESP_PASS.NC
DIM INTEGER ESP.NC = 1
DIM STRING ESP_INIT.NC = "COM1:691200,1024"
DIM STRING ESP_CONNECTION.NC = "", ESP_VERSION.NC = ""
DIM INTEGER ESP_ON.NC = 0
DIM INTEGER WIFI.NC = 0
CONST ESP_PREFIX.NC = "@NC_"

DIM STRING STR.NC         'temporary string var
DIM STRING NULL_S.NC 
DIM INTEGER INT.NC        'temporary integer var
DIM INTEGER NULL_I.NC 

DIM INTEGER CLOCK.NC = 0
DIM STRING DIALOG.NC
DIM INTEGER CAPS.NC
DIM INTEGER KEYTEST.NC
DIM STRING KEY.NC
DIM INTEGER KEYMOD.NC = 0
DIM INTEGER ALT_OLD.NC = -1
DIM INTEGER ALT.NC = 0
DIM INTEGER CTRL.NC = 0
DIM STRING STORE.NC
DIM STRING COMPLETE.NC   'current selected item
DIM STRING SELECTED.NC   'current selected item name
DIM STRING MANUAL.NC = NC_PATH.NC + "MANUAL.TXT"

DIM STRING ACT_PATH.NC, NON_PATH.NC 'active and non-active path (selected and not selected)
DIM STRING SEL_TYPE.NC, SEL_NAME.NC 'D or F, name without prefix

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

DIM INTEGER HIDDEN.NC = 0 'not show hidden items
DIM INTEGER UNSORT.NC = 0 'not sort items

DIM STRING SS.NC = "" 'screenshot was made

DIM INTEGER CONFIG.NC = 0
DIM INTEGER CFG_ExtView.NC = 0
DIM INTEGER CFG_ExtAct.NC = 0
DIM INTEGER CFG_ESCup.NC = 0
DIM INTEGER CFG_DirFil.NC = 0
DIM INTEGER CFG_TXTfb.NC = 0
DIM INTEGER CFG_HighColor.NC = 0
DIM INTEGER CFG_FastSerial.NC = 0
DIM INTEGER CFG_ESP.NC = 0

NCinit

NCchangeDir(0, "A:/")
NCchangeDir(1, "A:/")
NCdrawCL(ACT_PATH.NC)

NCcursor(0, 1)


ON KEY 157, NCprintScreen
DO
  IF SS.NC <> "" THEN 'screenshot was prepared
    PAGE WRITE 1
    CLS RGB(NOTBLACK)
    BLIT WRITE #64,VAL(FIELD$(SS.NC,1,",")),VAL(FIELD$(SS.NC,2,","))
    PAGE WRITE 0
    STR.NC = NCnewName(ACT_PATH.NC, "ScreenShot.BMP")
    GRF.saveBMP(ACT_PATH.NC+STR.NC,VAL(FIELD$(SS.NC,1,",")),VAL(FIELD$(SS.NC,2,",")),VAL(FIELD$(SS.NC,3,",")),VAL(FIELD$(SS.NC,4,",")), 1)
    BLIT CLOSE #64
    SS.NC = ""
    NCchangeDir(ACTIVE.NC, ACT_PATH.NC)
    IF PATH.NC(0) = PATH.NC(1) THEN NCchangeDir(1 - ACTIVE.NC, NON_PATH.NC)
    NCcursor(ACTIVE.NC, 1)
  ENDIF

  IF (TIMER - KEYTEST.NC) > 100 THEN 
    KEYMOD.NC = KEYDOWN(7)
    CAPS.NC = KEYDOWN(8) AND 1
    ALT.NC = (KEYMOD.NC AND 1)>0 OR (KEYMOD.NC AND 16)>0
    CTRL.NC = (KEYMOD.NC AND 2)>0 OR (KEYMOD.NC AND 32)>0
    IF ALT.NC <> ALT_OLD.NC THEN
      ALT_OLD.NC = ALT.NC
      IF ALT.NC THEN
        NCsetMenu(0, "SourLP", 1)
        NCdrawMenuPart(1)
        NCsetMenu(1, "SourRP", 1)
        NCdrawMenuPart(2)
        NCsetMenu(2, "VieHEX", 1)
        NCdrawMenuPart(3)
        NCsetMenu(3, "HlpBAS", 1)
        NCdrawMenuPart(4)
        NCsetMenu(4, "Move", 1)
        NCdrawMenuPart(5)
        NCsetMenu(8, "Comprs", 1)
        NCdrawMenuPart(9)
        NCsetMenu(9, "QuitNC", 1)
        NCdrawMenuPart(10)
        NCsetMenu(11,"WiFi", ESP.NC)
        NCdrawMenuPart(12)
      ELSE
        NCsetMenu(0, "Help", 1)
        NCdrawMenuPart(1)
        NCsetMenu(1, "GetInf", 1)
        NCdrawMenuPart(2)
        NCsetMenu(2, "Viewer", 1)
        NCdrawMenuPart(3)
        NCsetMenu(3, "EdiHEX", 1)
        NCdrawMenuPart(4)
        NCsetMenu(4, "Copy", 1)
        NCdrawMenuPart(5)
        NCsetMenu(8, "MakMAR", 1)
        NCdrawMenuPart(9)
        NCsetMenu(9, "About", 1)
        NCdrawMenuPart(10)
        NCsetMenu(11,"LP=RP", 1)
        NCdrawMenuPart(12)
      ENDIF
    ENDIF
    KEYTEST.NC = TIMER
  ENDIF

  KEY.NC = INKEY$
  IF KEY.NC <> "" THEN
    NCkey(ASC(KEY.NC))
    KEY.NC = ""
  ENDIF
LOOP
END

SUB NCespTest
  'test for ESP8266

  LOCAL STRING dialog = TUIwaitingON("ESP TEST")

  ON ERROR SKIP
  OPEN ESP_INIT.NC AS #1
    ?#1, "@ver" + LF.NC;
    ESP_VERSION.NC = ""
    ESP_VERSION.NC = NCreadUntilLF()
    IF ESP_VERSION.NC <> "" THEN
      IF LEFT$(ESP_VERSION.NC, 5) = "ESP v" THEN
        ESP.NC = 1
      ELSE
        ESP.NC = 0
        ESP_VERSION.NC = ""
      ENDIF
    ELSE
      ESP.NC = 0
      ESP_VERSION.NC = ""
    ENDIF
  CLOSE #1
  TUIwaitingOFF(dialog)
END SUB

SUB NCespWifiTest
  LOCAL STRING conn = "@netinfo"
  LOCAL INTEGER timeout = TIMER

  LOCAL STRING dialog = TUIwaitingON("WIFI TEST")
  ON ERROR SKIP
  OPEN ESP_INIT.NC AS #1
    ?#1, conn + LF.NC;
    ESP_CONNECTION.NC = ""
    DO WHILE ESP_CONNECTION.NC = "" AND ((TIMER-timeout) < 2000)
      ESP_CONNECTION.NC = NCreadUntilLF()
    LOOP
    WIFI.NC = (ESP_CONNECTION.NC <> "")
  CLOSE #1
  TUIwaitingOFF(dialog)
END SUB

SUB NCespConnect(SSID AS STRING, PASS AS STRING)
  'connect ESP8266 to local network

  LOCAL STRING conn = "@connect(" + SSID + "," + PASS + ")"
  LOCAL INTEGER timeout = TIMER

  ON ERROR SKIP
  OPEN ESP_INIT.NC AS #1
    ?#1, conn + LF.NC;
    ESP_CONNECTION.NC = ""
    DO WHILE ESP_CONNECTION.NC = "" AND ((TIMER-timeout) < 10000)
      ESP_CONNECTION.NC = NCreadUntilLF()
    LOOP
    WIFI.NC = (LEFT$(ESP_CONNECTION.NC, 9) = "Connected")
  CLOSE #1
END SUB

SUB NCespReboot
  'reboots ESP8266

  OPEN "COM1:691200,1024" AS #1
    ?#1, "@reboot" + CHR$(10);
  CLOSE #1
END SUB

FUNCTION NCespDisconnect() AS INTEGER
  'disconnect ESP8266 from network

  IF NCisSerial(0) OR NCisSerial(1) THEN
    TUIwarning("WIFI DISCONNECT", "WIFI in use now, disconnect not possible")
  ELSE
    LOCAL INTEGER timeout = TIMER
    LOCAL STRING dis = ""

    ON ERROR SKIP
    OPEN ESP_INIT.NC AS #1
    ?#1, "@disconnect";
    DO WHILE dis = "" AND ((TIMER-timeout) < 5000)
      dis = NCreadUntilLF()
    LOOP
    CLOSE #1
    NCespDisconnect = (dis = "Disconnected")
  ENDIF
END FUNCTION

SUB NCprintScreen
  'store screenshot into memory

  IF NOT NCisSerial(ACTIVE.NC) THEN
    IF SS.NC = "" THEN
      IF (KEYDOWN(7) AND 1) AND ON.TUI THEN 'LEFT ALT, DIALOG screemshot
        SS.NC = STR$(X.TUI) + "," + STR$(Y.TUI) + "," + STR$(W.TUI) + "," + STR$(H.TUI)
        BLIT READ #64, X.TUI, Y.TUI, W.TUI, H.TUI
        PAGE COPY 0 TO 1
        BOX X.TUI, Y.TUI, W.TUI, H.TUI, 0,, RGB(WHITE)
        PAUSE 100
        PAGE COPY 1 TO 0
      ELSE
        SS.NC = "0,0," + STR$(MM.HRES) + "," + STR$(MM.VRES)
        BLIT READ #64, 0, 0, MM.HRES, MM.VRES
        PAGE COPY 0 TO 1
        BOX 0, 0, MM.HRES, MM.VRES, 0,, RGB(WHITE)
        PAUSE 100
        PAGE COPY 1 TO 0
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

  IF ESP.NC THEN
    IF NOT ESP_ON.NC THEN
      IF SERIAL_ON.NC THEN CLOSE #1
      OPEN ESP_INIT.NC AS #1
      ESP_ON.NC = 1
    ENDIF
    NCserialOut("?", 1)     
    DO WHILE lineSerial = ""
      lineSerial = NCreadUntilLF()
    LOOP
    IF lineSerial = "OK" THEN
      NCserialOK = 1
    ENDIF
  ELSE
    IF NOT SERIAL_ON.NC THEN
      IF ESP_ON.NC THEN CLOSE #1
      OPEN SERIAL_INIT.NC AS #1
      SERIAL_ON.NC = 1
    ENDIF
    NCserialOut("?")     
    lineSerial = NCreadUntilLF()
    IF lineSerial = "OK" THEN
      NCserialOK = 1
    ENDIF
  ENDIF
END FUNCTION

FUNCTION NCtrim(s AS STRING) AS STRING
  'remove white chars from both end

  NCtrim = NClTrim(NCrTrim(s))
END FUNCTION


FUNCTION NClTrim(s AS STRING) AS STRING
  'left trim function (remove white chars from left)

  NClTrim = s
  DO WHILE NClTrim <> "" AND ASC(LEFT$(NClTrim,1)) < 33
    NClTrim = MID$(NClTrim, 2)
  LOOP
END FUNCTION

FUNCTION NCrTrim(s AS STRING) AS STRING
  'right trim function (removes white chars from right)

  NCrTrim = s
  DO WHILE NCrTrim <> "" AND ASC(RIGHT$(NCrTrim,1)) < 33
    NCrTrim = LEFT$(NCrTrim, LEN(NCrTrim) - 1)
  LOOP
END FUNCTION

SUB NCgetInfo(filePath AS STRING)
  'get info and save it into 
  LOCAL STRING lin, ex = UCASE$(NCgetExtension(filePath))

  SELECT CASE ex
    CASE "ARC"
      'archive view
      LOCAL STRING inf(4)
      LOCAL STRING header
      LOCAL INTEGER skp

      OPEN ACT_PATH.NC + SEL_NAME.NC FOR INPUT AS #3
      LINE INPUT #3,header
      IF LEFT$(header, 3) = "HUF" THEN
        LOCAL INTEGER tLen = ASC(INPUT$(1, #3))
        LOCAL INTEGER tMin = ASC(MID$(INPUT$(2, #3), 2, 1))
        IF tLen > 2 THEN 
          skp = 2 * (tLen - 2)
          DO WHILE skp > 255
            skp = skp - 255
            lin = INPUT$(255, #3)
          LOOP
          lin = INPUT$(skp, #3)      
        ENDIF
        LOCAL INTEGER tMax = ASC(MID$(INPUT$(2, #3), 2, 1))

      ENDIF
      CLOSE #3
      inf(0) = "Source file  : " + NCgetNoExtension(SEL_NAME.NC) + "." + FIELD$(header, 2, ",")
      inf(1) = "Compressor   : " + LEFT$(header, 3)
      inf(2) = "Source lenght: " + FIELD$(header, 3, ",")     
      inf(3) = "Compression  : " + STR$(100 * MM.INFO(FILESIZE ACT_PATH.NC + SEL_NAME.NC)/VAL(FIELD$(header, 3, ",")), 0, 1) + "%"
      IF LEFT$(header, 3) = "HUF" THEN
        inf(4)="Table (tree) : " + STR$(tLen) + " (" + STR$(tMin) + "-" + STR$(tMax) + " b)"
      ENDIF
      TUIinfo("ARC INFO", inf())        

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
          lin = NCtrim(lin)      
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
    
    CASE "GIF", "BMP", "PNG", "JPG"
      LOCAL STRING info = GRF.getImgInfo(ACT_PATH.NC + SEL_NAME.NC)
      IF info <> "" THEN
        LOCAL STRING inf(3)
        inf(0) = "Width     : " + FIELD$(info, 1, ",")
        inf(1) = "Height    : " + FIELD$(info, 2, ",")
        inf(2) = "Bits/pixel: " + FIELD$(info, 3, ",")
        inf(3) = "Version   : " + FIELD$(info, 4, ",")
        TUIinfo(ex + " IMAGE INFO", inf())
      ELSE
        TUIwarning("GET INFO",filePath)
      ENDIF

    CASE "SCR", "BSC"
      LOCAL STRING info = GRF.getZXinfo(ACT_PATH.NC + SEL_NAME.NC)
      IF info <> "" THEN
        LOCAL STRING inf(3)
        inf(0) = "Width     : " + FIELD$(info, 1, ",")
        inf(1) = "Height    : " + FIELD$(info, 2, ",")
        inf(2) = "Bits/pixel: " + FIELD$(info, 3, ",")
        inf(3) = "Version   : " + FIELD$(info, 4, ",")
        TUIinfo("ZX Spectrum IMAGE INFO", inf())
      ELSE
        TUIwarning("GET INFO",filePath)
      ENDIF

    CASE "HBM", "HED", "KOA", "DD", "JJ", "GG"
      LOCAL STRING info = GRF.getC64info(ACT_PATH.NC + SEL_NAME.NC)
      IF info <> "" THEN
        LOCAL STRING inf(3)
        inf(0) = "Width     : " + FIELD$(info, 1, ",")
        inf(1) = "Height    : " + FIELD$(info, 2, ",")
        inf(2) = "Bits/pixel: " + FIELD$(info, 3, ",")
        inf(3) = "Version   : " + FIELD$(info, 4, ",")
        TUIinfo("C64 IMAGE INFO", inf())
      ELSE
        TUIwarning("GET INFO",filePath)
      ENDIF
    
    CASE "PI1", "PI2", "PI3", "PC1", "PC2", "PC3"
      LOCAL STRING info = GRF.getSTinfo(ACT_PATH.NC + SEL_NAME.NC)
      IF info <> "" THEN
        LOCAL STRING inf(3)
        inf(0) = "Width     : " + FIELD$(info, 1, ",")
        inf(1) = "Height    : " + FIELD$(info, 2, ",")
        inf(2) = "Bits/pixel: " + FIELD$(info, 3, ",")
        inf(3) = "Version   : " + FIELD$(info, 4, ",")
        TUIinfo("Atari ST IMAGE INFO", inf())
      ELSE
        TUIwarning("GET INFO",filePath)
      ENDIF
    
    CASE "SPR"
      LOCAL STRING info = GRF.getSPRinfo(ACT_PATH.NC + SEL_NAME.NC)
      IF info <> "" THEN
        LOCAL STRING inf(1)
        inf(0) = "Width     : " + FIELD$(info, 1, ",")
        inf(1) = "Height    : " + FIELD$(info, 2, ",")
        TUIinfo("SPRITE INFO", inf())
      ELSE
        TUIwarning("GET INFO",filePath)
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
        txt = txt + ",TEXT VIEWER fallback (HEX else)"
        txt = txt + ",HIGH COLOR mode"
        txt = txt + ",FAST SERIAL SERVER (691200bd)"
        txt = txt + ",ESP8266 installed"
     
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
    LOGO.NC = NCprepareLogo("NAPOLEON.SPR")
  ENDIF

  IF oldSel AND 64 THEN 
    IF CFG_FastSerial.NC THEN
      SERIAL_INIT.NC = "COM3:691200,3072"
    ELSE
      SERIAL_INIT.NC = "COM3:230400,1024"
    ENDIF
    IF SERIAL_ON.NC THEN CLOSE #1
    SERIAL_ON.NC = 0
    NULL_I.NC = NCserialOK()
  ENDIF
  
  IF oldSel AND 128 THEN
    IF CFG_ESP.NC THEN
      NCespTest
      IF ESP.NC THEN
        NCespWifiTest
      ENDIF
    ELSE
      WIFI.NC = 0
      ESP.NC = 0
      ESP_VERSION.NC = ""
    ENDIF
  ENDIF
  IF (oldSel AND 8) OR (oldSel AND 32) THEN 'changed MODE or items sorting
    NCchangeDir(0,PATH.NC(0))
    NCchangeDir(1,PATH.NC(1))
    NCdrawMenu
    NCdrawCL(ACT_PATH.NC)
    NCcursor(ACTIVE.NC,1)
  ENDIF
  IF oldSel <> 0 THEN 
    CONFIG.NC = sel
    NCconfigSave(sel)
  ENDIF
END SUB

FUNCTION NCconfigPack() AS INTEGER
  'pack config into integer

  NCconfigPack = CFG_ExtView.NC + 2*CFG_ExtAct.NC + 4*CFG_ESCup.NC
  NCconfigPack = NCconfigPack + 8*CFG_DirFil.NC + 16*CFG_TXTfb.NC + 32*CFG_HighColor.NC
  NCconfigPack = NCconfigPack + 64*CFG_FastSerial.NC + 128*CFG_ESP.NC
END FUNCTION

SUB NCconfigSave(sel AS INTEGER)
  'save config
  OPEN NC_PATH.NC + "NC.CFG" FOR OUTPUT AS #3
  ?#3,BIN$(sel)
  IF ESP_SSID.NC <> "" THEN
    ?#3, ESP_SSID.NC
  ENDIF
  IF ESP_PASS.NC <> "" THEN
    ?#3, ESP_PASS.NC
  ENDIF
  CLOSE #3
END SUB

SUB NCconfigLoad
  'load config

  LOCAL STRING sCfg
  ON ERROR SKIP
  OPEN NC_PATH.NC + "NC.CFG" FOR INPUT AS #3
  IF MM.ERRNO = 0 THEN
    LINE INPUT #3, sCfg
    CONFIG.NC = VAL("&b" + sCfg)

    NCconfigUnpack(CONFIG.NC)
    IF NOT EOF(#3) THEN
      LINE INPUT #3, ESP_SSID.NC
    ENDIF
    IF NOT EOF(#3) THEN
      LINE INPUT #3, ESP_PASS.NC
    ENDIF

    CLS RGB(NOTBLACK)
    CLOSE #3
  ENDIF
  IF CFG_FastSerial.NC THEN
    SERIAL_INIT.NC = "COM3:691200,1024"
  ELSE
    SERIAL_INIT.NC = "COM3:230400,1024"
  ENDIF
  IF CFG_ESP.NC THEN
    FONT.TUI = 1
    NCespTest
    IF ESP.NC THEN
      NCespWifiTest
    ELSE
      CFG_ESP.NC = 0
    ENDIF
    FONT.TUI = 8
  ELSE
    ESP.NC = 0
    ESP_VERSION.NC = ""
  ENDIF
END SUB

SUB NCwifi
  IF ESP.NC THEN
    LOCAL STRING wifi = "Connect to ...", ssid, pass
    LOCAL STRING dialog

    IF ESP_SSID.NC <> "" THEN CAT wifi, ",Connect to " + ESP_SSID.NC
    IF WIFI.NC THEN CAT wifi, ",Disconnect from " + ESP_SSID.NC
    LOCAL INTEGER wifiChoice = TUIchoice("WIFI", wifi)
    SELECT CASE wifiChoice
      CASE 0
        'connect to
        ssid = TUIinput("NETWORK CREDENTIALS", "Network name (SSID):", ESP_SSID.NC, WIFICHARS.NC)
        pass = TUIinput("NETWORK CREDENTIALS", "Password for " + ssid + ":", ESP_PASS.NC, WIFICHARS.NC)
        IF ssid <> "" THEN
          dialog = TUIwaitingON("WIFI CONNECTING TO " + ssid)
          NCespConnect(ssid, pass)
          IF WIFI.NC THEN
            ESP_SSID.NC = ssid
            ESP_PASS.NC = pass
            NCconfigSave(CONFIG.NC)
          ENDIF
          TUIwaitingOFF(dialog)
        ENDIF        

      CASE 1
        IF ESP_SSID.NC <> "" THEN
          'connect to SSID
          dialog = TUIwaitingON("WIFI CONNECTING TO " + ESP_SSID.NC)
          NCespConnect(ESP_SSID.NC, ESP_PASS.NC)
          TUIwaitingOFF(dialog)

        ELSE
          'disconnect
          IF WIFI.NC THEN
            dialog = TUIwaitingON("WIFI DICONNECTING FROM " + ESP_SSID.NC)          
            IF NCespDisconnect() THEN
              WIFI.NC = 0
            ENDIF
            TUIwaitingOFF(dialog)
          ENDIF
        ENDIF
        
      CASE 2
        'disconnect
        IF WIFI.NC THEN
          dialog = TUIwaitingON("WIFI DICONNECTING FROM " + ESP_SSID.NC)          
          IF NCespDisconnect() THEN
            WIFI.NC = 0
          ENDIF
          TUIwaitingOFF(dialog)
        ENDIF

    END SELECT 
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
  CFG_FastSerial.NC = (sel AND 64) > 0 
  CFG_ESP.NC = (sel AND 128) > 0 
END SUB

SUB NCfindFirstChar(ch AS STRING)
  'find item which begins with ch

  LOCAL INTEGER i
  
  IF LCASE$(MID$(SELECTED.NC, 2, 1)) = ch AND SEL_TYPE.NC = "D" THEN
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

  IF NCisSerial(ACTIVE.NC) THEN
    LOCAL INTEGER i
    LOCAL STRING nn = NCgetName(fullPath)

    FOR i = 0 TO COUNT.NC(ACTIVE.NC)
      IF nn = MID$(FIELD$(ITEM.NC(ACTIVE.NC, i), 1, "|"), 2) THEN
        NCexist = 1
        EXIT FUNCTION    
      ENDIF          
    NEXT i
  ELSE
    NCexist = DIR$(fullPath, ALL) <> ""
  ENDIF
END FUNCTION

FUNCTION NCparent(p AS STRING) AS STRING
  'get parent folder

  NCparent = p
  IF RIGHT$(NCparent,1)="/" THEN NCparent = LEFT$(NCparent,LEN(NCparent)-1)
  IF INSTR(NCparent, "/") > 0 THEN
    DO WHILE RIGHT$(NCparent,1)<>"/"
      NCparent = LEFT$(NCparent,LEN(NCparent)-1)
    LOOP
  ELSE
    CAT NCparent, "/"
  ENDIF
END FUNCTION

SUB NCdelete(s AS STRING, noWarning AS INTEGER)
  'delete item

  IF NOT noWarning THEN
    IF NOT TUIquestion("DELETE", "Delete '" + MID$(s, 2) + "', really proceed?") THEN
      EXIT SUB
    ENDIF
  ENDIF
  IF NCisDir(s) THEN
    IF NCrmdir(ACT_PATH.NC + MID$(s, 2)) THEN 
      NCdeleteDir(ACT_PATH.NC + MID$(s, 2))
      IF INSTR(PATH.NC(0), ACT_PATH.NC + MID$(s, 2)) > 0 THEN
        PATH.NC(0) = NCparent(ACT_PATH + MID$(s, 2))
      ENDIF
      IF INSTR(PATH.NC(1), ACT_PATH.NC + MID$(s, 2)) > 0 THEN
        PATH.NC(1) = NCparent(ACT_PATH.NC + MID$(s, 2))
      ENDIF
    ENDIF
  ELSE
    NULL_I.NC = NCkill(ACT_PATH.NC + MID$(s, 2))
  ENDIF

  NCchangeDir(ACTIVE.NC, PATH.NC(ACTIVE.NC))
  IF NCnonActiveChange() THEN NCchangeDir(1 - ACTIVE.NC, PATH.NC(1 - ACTIVE.NC))
  NCcursor(ACTIVE.NC, 1)
END SUB

FUNCTION NCnonActiveChange() AS INTEGER
  NCnonActiveChange = 0
  IF (PATH.NC(1 - ACTIVE.NC) <> NON_PATH.NC) OR (LEFT$(ACT_PATH.NC, 1) = LEFT$(NON_PATH.NC, 1)) THEN
    NCnonActiveChange = 1
  ENDIF
END FUNCTION

SUB NChelp
  'show help

  LOCAL STRING txt = "Shortcuts,BASIC helpers,Manual"
  
  LOCAL INTEGER h = TUIchoice("CHOOSE SECTION", txt)
  SELECT CASE h
    CASE <0 'ESC
      'TUIwarning("HELP","You was no able to choose :-(")

    CASE 0
      LOCAL STRING shrt(26) LENGTH 100
      shrt( 0) = "ALT+F1/F2   Selects source for left or right pane (SD card or SERVER)"
      shrt( 1) = ""
      shrt( 2) = CHR$(225) + " " + CHR$(226) + "         Up/Down  Moves row on active pane"
      shrt( 3) = "Home/End    Jumps to first/last row on the screen (with ALT total begin/end)"
      shrt( 4) = "PgUP/PgDOWN Paging in list"
      shrt( 5) = "TAB         Switches active pane"
      shrt( 6) = "Keys a-z    Jumps to first item with this char on begin in DIRs or FILEs,"
      shrt( 7) = "            second press jumps between DIR and FILE"
      shrt( 8) = "ENTER       Changes active directory or invokes action"
      shrt( 9) = "ESC         Jumps to parent directory if present"
      shrt(10) = "CTRL+h      Switches hidden items ON/OFF (" + CHR$(230) + " shown when hidden ON)"
      shrt(11) = "CTRL+u      Unsorted/sorted directory layout (" + CHR$(229) + " shown when sorted)"
      shrt(12) = "CTRL+f      Finds item (wildcards enabled), shows all found, then jumps to first"
      shrt(13) = "PrintScr    Saves screen to 'ScreenShot.BMP', with ALT just current dialog (not to S:)"
      shrt(14) = ""
      shrt(15) = "        F1  Displays HELP screen(s)"
      shrt(16) = "        F2  Gets size for DIR, info for FILE"
      shrt(17) = "        F3  Quick (& dirty) TEXT file viewer, ALT+F3 forces HEX viewer"
      shrt(18) = "        F4  Simple HEX editor, ALT+F4 starts BASIC helpers"
      shrt(19) = "        F5  Copies FILE or DIR, ALT+F5 moves"
      shrt(20) = "        F6  Renames FILE or DIR"
      shrt(21) = "        F7  Creates new DIRECTORY"
      shrt(22) = "        F8  Deletes FILE or DIR"
      shrt(23) = "        F9  Archive DIR tree, ALT+F9 compress FILE"
      shrt(24) = "       F10  Shows INFO box, ALT+F10 QUITs this app"
      shrt(25) = "       F11  NC Configuration"
      shrt(26) = "       F12  Duplicates view from active to inactive pane, ALT+F12 WiFi functions"
  
      TUIinfo("KEYBOARD SHORTCUTs",shrt())
      
    CASE 1
      LOCAL STRING bhlp(12) LENGTH 100
      bhlp(0) = "Tools for developers of BASIC apps. Curently they are:"
      bhlp(1) = ""
      bhlp(2) = "PRETTY FORMAT"
      bhlp(3) = "  Formats BASIC app 'pretty', by proper indenting, removing more than 1 empty line,"
      bhlp(4) = "  change BASIC keywords into upper case, inserts 1 empty line before SUB/FUNCTION etc."
      bhlp(5) = ""
      bhlp(6) = "DEBUG ON"
      bhlp(7) = "  Changes every BASIC line which begins with ''', removing ''' and put them on end of line."
      bhlp(8) = "  So is this line 'uncommented' and can be used for DEBUG
      bhlp(9) = ""
      bhlp(10) = "DEBUG OFF"
      bhlp(11) = "  Changes every BASIC line which ends with ''', removing ''' and put them on begin of line."
      bhlp(12) = "  So is this line 'commented' and it remove 'debug lines' (and not slows down the app)."

      TUIinfo("BASIC HELPERs",bhlp())


    CASE 2
      NCviewTXT(MANUAL.NC)

  END SELECT
END SUB

SUB NCrenameItem
  'rename item

  STR.NC = TUIinput("RENAME ITEM", "New name:",NCnewName(ACT_PATH.NC, SEL_NAME.NC), FILECHARS.NC)
  IF STR.NC <> "" THEN
    IF NCisSerial(ACTIVE.NC) THEN
      NCserialOut("N" + ACT_PATH.NC + SEL_NAME.NC + "|" + ACT_PATH.NC + STR.NC, 1)
      IF NCinsideTest(ACT_PATH.NC, NON_PATH.NC) THEN
        PATH.NC(1-ACTIVE.NC) = NCparent(NON_PATH.NC)
      ENDIF
    ELSE
      IF NCrename(ACT_PATH.NC + SEL_NAME.NC, ACT_PATH.NC + STR.NC) THEN 
        NCerror("RENAME '" + SEL_NAME.NC + "' ERROR") 
      ELSE
        IF NCinsideTest(ACT_PATH.NC, NON_PATH.NC) THEN
          PATH.NC(1-ACTIVE.NC) = NCparent(NON_PATH.NC)
        ENDIF
      ENDIF
    ENDIF
    NCchangeDir(ACTIVE.NC, ACT_PATH.NC)
    IF NCnonActiveChange() THEN NCchangeDir(1 - ACTIVE.NC, PATH.NC(1 - ACTIVE.NC))
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

  IF NOT NCcopy(source, dest) THEN 
    NCchangeDir(0,PATH.NC(0))
    NCchangeDir(1,PATH.NC(1))
    NCcursor(ACTIVE.NC,1)
  ELSE
    NCerror("COPY '" + NCgetName(source) + "' ERROR")
  ENDIF 
END SUB

SUB NCmoveFile(source AS STRING, dest AS STRING)
  'move file

  IF TUIquestion("MOVE FILE","Move '"+source+"' to '"+dest+"'?") THEN         
    IF NCcopy(source, dest) THEN 
      NCerror("COPY '" + NCgetName(source) + "' ERROR")
    ELSE
      IF NOT NCkill(source) THEN
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
  
  TUIwaitForNoKey
  SELECT CASE ex
    CASE "BAS"
      extAction = "RUN " + CHR$(34) + p + s + CHR$(34)
      OPTION BREAK 3
      EXECUTE extAction

    CASE "SPR"
      NCviewTXT(p + s)

    CASE "BMP"
      CLOCK.NC = 0
      CLS RGB(NOTBLACK)
      LOAD BMP p+s
      TUIwaitForNoKey
      TUIwaitForKey
      TUIwaitForNoKey
      NCredrawPane(0)
      NCredrawPane(1)  
      NCcursor(ACTIVE.NC,1)
      NCdrawMenu
      
    CASE "JPG"
      CLOCK.NC = 0
      CLS RGB(NOTBLACK)
      LOAD JPG p+s
      TUIwaitForNoKey
      TUIwaitForKey
      TUIwaitForNoKey
      NCredrawPane(0)
      NCredrawPane(1)  
      NCcursor(ACTIVE.NC,1)
      NCdrawMenu

    CASE "PNG"
      CLOCK.NC = 0
      CLS RGB(NOTBLACK)
      ON ERROR SKIP
      LOAD PNG p+s
      IF MM.ERRNO = 0 THEN
        TUIwaitForNoKey
        TUIwaitForKey
        TUIwaitForNoKey
      ELSE
        TUIwarning("PNG VIEW ERROR", MM.ERRMSG$)
      ENDIF
      NCredrawPane(0)
      NCredrawPane(1)  
      NCcursor(ACTIVE.NC,1)
      NCdrawMenu

    CASE "GIF"
      CLOCK.NC = 0
      CLS RGB(NOTBLACK)
      ON ERROR SKIP
      LOAD GIF p+s
      TUIwaitForNoKey
      TUIwaitForKey
      TUIwaitForNoKey
      NCredrawPane(0)
      NCredrawPane(1)  
      NCcursor(ACTIVE.NC,1)
      NCdrawMenu

    CASE "MAR"
      NCunMAR(p + s)

    CASE "ARC"
      NCunARC(p + s)

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
  BOX 400*side,0,400,568,0,,RGB(NOTBLACK)
  BOX 400*side,0,400,566,0,,RGB(BLUE)
  BOX 400*side+1,0+6,400-3,568-15,2,RGB(WHITE),RGB(BLUE)
  IF side = ACTIVE.NC THEN
    ACT_PATH.NC = PATH.NC(side)
    TEXT 400*side+200,0," "+short+" ","CT",8,,RGB(BLUE),RGB(WHITE)
  ELSE
    NON_PATH.NC = PATH.NC(side)
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
  LOCAL STRING ex = NCgetExtension(f)

  IF l > 23 THEN
    IF ex <> "" THEN
      NCname = LEFT$(f, 18) + "~."
      IF LEN(ex) > 3 THEN
        NCname = NCname + "~" + RIGHT$(ex, 2)
      ELSE
        NCname = NCname + RIGHT$("   " + ex, 3)
      ENDIF
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
  IF dt <> "" THEN dt = MID$(dt, 3, 14)
  NCdateTime = dt
END FUNCTION

FUNCTION NCsize(f AS STRING) AS STRING
  'prepare file size

  LOCAL INTEGER s = MM.INFO(FILESIZE f)
  IF s < 0 THEN
    NCsize = "DIRECTORY"
  ELSE
    NCsize = STR$(s, 9, 0)
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
      IF c = ":" THEN c = CHR$(250)
      NCdigital = NCdigital + c
    ENDIF
  NEXT i
END FUNCTION

SUB NCclock
  SELECT CASE CLOCK.NC
    CASE 1
      TEXT 800 - 5*8, 568, NCdigital(LEFT$(TIME$, 5)), "LT", 8,, RGB(CYAN), RGB(NOTBLACK)
      IF WIFI.NC THEN
        TEXT 0, 568, CHR$(231), "LT", 8,, ICONS.NC, RGB(NOTBLACK)
      ELSE
        TEXT 0, 568, " ", "LT", 8,, RGB(CYAN), RGB(NOTBLACK)
      ENDIF

    CASE 2
      TEXT 800 - 6*8, 600-16, " " + NCdigital(LEFT$(TIME$, 5)),"LT", 8,, RGB(WHITE), RGB(NOTBLACK)
  END SELECT
END SUB

SUB NCdrawCL(p AS STRING)
  'outputs command line

  LOCAL STRING pp = LEFT$(p, 100-9)
  BOX 8, 568, 800 - 6*8, 16, 0,, RGB(NOTBLACK)
  TEXT 4*8, 568,p,"LT",8,,RGB(WHITE),RGB(NOTBLACK)
  IF HIDDEN.NC THEN
    TEXT 8, 568, CHR$(230), "LT", 8,, ICONS.NC, RGB(NOTBLACK)
  ENDIF
  IF NOT UNSORT.NC THEN
    TEXT 16, 568, CHR$(229), "LT", 8,, ICONS.NC, RGB(NOTBLACK)
  ENDIF
  CLOCK.NC = 1
END SUB

SUB NCcursor(side AS INTEGER, show AS INTEGER)
  'show or hide cursor

  LOCAL STRING short = PATH.NC(side)
  LOCAL INTEGER hid = MID$(ITEM.NC(side,CURSOR.NC(side)+POS.NC(side)),2,1)="." 
  LOCAL INTEGER fcol

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
    SEL_NAME.NC = MID$(SELECTED.NC, 2)
    SEL_TYPE.NC = LEFT$(SELECTED.NC, 1)
    NCdrawCL(ACT_PATH.NC + SEL_NAME.NC)        
    TEXT 400*side+200,600-52,NCcounter(side),"CT",,,RGB(WHITE),RGB(BLUE)
    ACT_PATH.NC = PATH.NC(side)
    NON_PATH.NC = PATH.NC(1 - side)

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
  ENDIF
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

  NCchdir("A:/")
  FOR ind = td TO 0 STEP -1
    IF LEFT$(toDo(ind),1)="K" THEN
      INT.NC = NCkill(MID$(toDo(ind),2))
    ELSE
      NULL_I.NC = NCrmdir(MID$(toDo(ind),2))
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

FUNCTION NCsource2dest(src AS STRING, dst AS STRING, pth AS STRING) AS STRING
  'replace source with destination (for dir copy)

  NCsource2dest = dst + RIGHT$(pth, LEN(pth)- LEN(src))  
END FUNCTION

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

SUB NCviewHEX(filePath AS STRING)
  'simple hex viewer

  CLOCK.NC = 2
  LOCAL INTEGER firstRow = 16+4, row = 0, cnt = 0, change = 0, b, po = 0, i, ln, cx, cy
  LOCAL STRING li,k

  NCviewBackground(filePath)
  OPEN filePath FOR RANDOM AS #3
  LOCAL INTEGER si = LOF(#3)
  DO 
    SEEK #3, po + 1
    change = 0
    cnt = 0 
    row = 0
  
    TEXT 400,600-16," Position " + HEX$(po,8) + " of " + HEX$(si,8) + " ","CT",8,,RGB(WHITE),RGB(NOTBLACK)

    PAGE WRITE 1
    BOX 0,16,800,600-32,0,,RGB(CYAN)
    DO WHILE cnt<16*35 AND NOT EOF(#3)
      li = INPUT$(16, #3)
    
      TEXT 8,firstRow + row, LEFT$(HEX$(po+cnt,8),4), "LT",8,,RGB(BLUE), RGB(CYAN)
      TEXT 44,firstRow + row, RIGHT$(HEX$(po+cnt,8),4), "LT",8,,RGB(BLUE), RGB(CYAN)
      ln = MIN(LEN(li) - 1, 15)
      FOR i = 0 TO ln
        b = ASC(MID$(li, i + 1, 1))
        TEXT 112 + i*32, firstRow + row, HEX$(b,2),"LT",8,,RGB(NOTBLACK), RGB(CYAN)
        IF b >= 32 AND b <= 127 THEN
          TEXT 640 + i*8, firstRow + row, CHR$(b),"LT",8,,RGB(NOTBLACK), RGB(CYAN)
        ELSE
          TEXT 640 + i*8, firstRow + row, ".","LT",8,,RGB(NOTBLACK), RGB(CYAN)
        ENDIF
      NEXT i          
      row = row + 16
      cnt = cnt + 16
    LOOP
    
    PAGE WRITE 0
    BLIT 0,16,0,16,800,600-32,1
    
    DO WHILE change = 0 AND k<>ESC.NC
      DO: k = INKEY$: LOOP WHILE k=""
      IF k=CHR$(136) THEN
        'Page UP
        IF po > 0 THEN 
          po = MAX(po - 16*35, 0)
          change = 1
        ENDIF

      ELSEIF k=CHR$(137) THEN
        'Page DOWN
        IF (po + 16*35) <= si  THEN 
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

SUB NCviewBackground(filePath AS STRING)
  CLS RGB(NOTBLACK)
  BOX 0,16,800,600-32,0,,RGB(CYAN)
  LINE 0,7,800,7,2,RGB(WHITE)
  LINE 0,600-8,800,600-8,2,RGB(WHITE)
  TEXT 400,0," " + filePath + " ","CT",8,,RGB(WHITE),RGB(NOTBLACK)
  TEXT 0,600-16,"PgUP/PgDOWN/ESC ","LT",8,,RGB(WHITE),RGB(NOTBLACK)
END SUB

SUB NCviewTXT(filePath AS STRING)
  'simple text viewer

  CLOCK.NC = 2
  NCviewBackground(filePath)
  CONST lineLength = 99
  CONST white = CHR$(8) + CHR$(10) + CHR$(13) + CHR$(32)
  LOCAL INTEGER firstRow = 16+4, filePos = 0, fileSize = MM.INFO(FILESIZE filePath)
  LOCAL INTEGER maxRow = 0, maxPages, indent = (MM.HRES - 8*lineLength) \ 2
  LOCAL STRING oneLine = "", ch, k = ""
  LOCAL INTEGER pages(1000), cntPage = 1, cntChar = 1, change = 0

  'count lines
  pages(cntPage) = cntChar  
  OPEN filePath FOR INPUT AS #3
    maxRow = 0
    DO WHILE NOT EOF(#3)
      ch = INPUT$(1, #3)
      IF ch = LF.NC THEN
        oneLine = ""
        INC maxRow
        IF maxRow = 35 THEN
          INC cntPage
          pages(cntPage) = cntChar + 1
          maxRow = 0
        ENDIF

      ELSEIF ch <> CR.NC THEN
        IF LEN(oneLine) < lineLength THEN
          CAT oneLine, ch
        ELSE
          oneLine = ""
          INC maxRow
          IF maxRow = 35 THEN
            INC cntPage
            pages(cntPage) = cntChar
            maxRow = 0
          ENDIF
        ENDIF
      ENDIF         

      INC cntChar
    LOOP
  CLOSE #3
  maxPages = cntPage
  cntPage = 1
  DO
    change = 0
    maxRow = 0
    BOX 0, 16, 800, 600-32, 0,, RGB(CYAN)
    TEXT 400, 600-16, " Page " + STR$(cntPage) + "/" + STR$(maxPages) + " ","CT", 8,, RGB(WHITE), RGB(NOTBLACK)

    oneLine = ""
    OPEN filePath FOR RANDOM AS #3
      filePos = pages(cntPage)
      SEEK #3, filePos
      DO WHILE maxRow < 35 AND filePos <= fileSize
        ch = INPUT$(1, #3)
        INC filePos
        IF ch = LF.NC THEN
          TEXT indent, firstRow + 16 * maxRow, oneLine, "LT", 8,, RGB(NOTBLACK), RGB(CYAN)
          oneLine = ""
          INC maxRow

        ELSEIF ch <> CR.NC THEN
          IF LEN(oneLine) < lineLength THEN
            CAT oneLine, ch
          ELSE
            TEXT indent, firstRow + 16 * maxRow, oneLine, "LT", 8,, RGB(NOTBLACK), RGB(CYAN)
            oneLine = ch
            INC maxRow
          ENDIF
        ENDIF
      LOOP               
    CLOSE #3
    IF oneLine <> "" THEN
      TEXT indent, firstRow + 16 * maxRow, oneLine, "LT", 8,, RGB(NOTBLACK), RGB(CYAN)
    ENDIF
    DO WHILE change = 0 AND k<>ESC.NC
      DO: k = INKEY$: LOOP WHILE k = ""
      IF k = CHR$(136) THEN
        'Page UP
        IF cntPage > 1 THEN 
          INC cntPage, -1
          change = 1
        ENDIF

      ELSEIF k = CHR$(137) THEN
        'Page DOWN
        IF cntPage < maxPages THEN 
          INC cntPage, 1
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

  LOCAL STRING k, ex = UCASE$(NCgetExtension(SEL_NAME.NC)), exViewer

  IF ALT.NC THEN 'ALT F3 force HEX
    NCviewHEX(ACT_PATH.NC + SEL_NAME.NC)
  ELSE

    SELECT CASE ex

    CASE "SPR"
      'sprite view
      NCviewSPR(ACT_PATH.NC + SEL_NAME.NC)

    CASE "TXT", "BAS", "BAK", "INC", "FNT", "PLY", "ASC", "CFG", "PY", "MD", "CSV"
      'text view
      NCviewTXT(ACT_PATH.NC + SEL_NAME.NC)

    CASE "BMP", "PNG", "GIF", "JPG"
      NCviewImg(ACT_PATH.NC + SEL_NAME.NC)

    CASE "MAR"
      NCviewMAR(ACT_PATH.NC + SEL_NAME.NC)

    CASE "DD", "HED", "HBM", "GG", "JJ", "KOA"
      'C64 graphics format
      NCviewC64(ACT_PATH.NC + SEL_NAME.NC)

    CASE "SCR", "BSC"
      'ZX Spectrum graphics format
      NCviewZX(ACT_PATH.NC + SEL_NAME.NC)

    CASE "PI1", "PI2", "PI3", "PC1", "PC2", "PC3"
      'Atari ST graphics format
      NCviewST(ACT_PATH.NC + SEL_NAME.NC)

    CASE ELSE
      EXT_ERR.NC = -1
      IF CFG_ExtView.NC THEN
        exViewer = "EXTview" + ex
        ON ERROR SKIP
        CALL exViewer, ACT_PATH.NC + SEL_NAME.NC
      ENDIF
      IF EXT_ERR.NC < 0 THEN
        'fallback to HEX view
        IF CFG_TXTfb.NC THEN
          NCviewTXT(ACT_PATH.NC + SEL_NAME.NC)
        ELSE
          NCviewHEX(ACT_PATH.NC + SEL_NAME.NC)
        ENDIF
      ELSE
        'external viewer was available
        NCredrawPane(0)
        NCredrawPane(1)  
        NCcursor(ACTIVE.NC,1)
        NCdrawMenu
      ENDIF
    END SELECT
  ENDIF
END SUB

SUB NCviewImg(filePath AS STRING)
  'simple image viewer

  LOCAL STRING inf = GRF.getImgInfo(filePath)
  IF inf <> "" THEN
    LOCAL INTEGER w = VAL(FIELD$(inf, 1, ","))
    LOCAL INTEGER h = VAL(FIELD$(inf, 2, ","))
    LOCAL INTEGER bpp = VAL(FIELD$(inf, 3, ","))
    
    IF w < = MM.HRES AND h <= MM.VRES THEN
      LOCAL INTEGER nw = w, nh = h, ww = w, hh = h
      LOCAL INTEGER mw = MM.HRES - 32, mh = MM.VRES - 64
  
      IF nw > mw THEN
        nw = mw
        nh = nh*mw/w
      ENDIF
      IF nh > mh THEN
        nw = w*mh/nh
        nh = mh
      ENDIF
      hh = nh
      ww = nw  

      IF GRF.loadImg(filePath, 0, 0, 1, 1) THEN
        LOCAL STRING dialog = TUIemptyON(filePath + ", " + STR$(w) + "x" + STR$(h)+ ", " + STR$(bpp)+"bpp", ww, hh)
        LOCAL INTEGER yy = VAL(FIELD$(dialog, 4, ",")) + 4
        IMAGE RESIZE_FAST 0, 0, w, h, (MM.HRES - nw) \ 2, yy, nw, nh, 1
        TUIwaitForNoKey
        TUIwaitForKey
        TUIwaitForNoKey
        TUIemptyOFF(dialog)
      ENDIF
    ELSE
      TUIwarning("IMAGE VIEWER", "Image is too big (" + STR$(w) + "x" + STR$(h) + ")")
    ENDIF
  ELSE
    TUIwarning("IMAGE VIEWER", "Image can't be decoded")
  ENDIF
END SUB

FUNCTION NCprepareLogo(f AS STRING) AS INTEGER
  'read SPR file

  LOCAL INTEGER i, w = 0, h = 0
  LOCAL STRING s

  ON ERROR SKIP
  OPEN NC_PATH.NC + f FOR INPUT AS #5
  IF MM.ERRNO = 0 THEN
    LINE INPUT #5, s
    w = VAL(FIELD$(s, 1, ","))
    'h = VAL(FIELD$(s, 3, ","))
    NCprepareLogo = 63
    PAGE WRITE 1
    CLS RGB(BLACK)
    DO WHILE NOT EOF(#5)
      LINE INPUT #5,s
      FOR i = 1 TO LEN(s)
        IF MID$(s, i, 1)<>" " THEN
          PIXEL i-1, h, RGB(NOTBLACK)
        ENDIF
      NEXT i
      INC h
    LOOP
    INC h
    CLOSE #5
    IF LOGO.NC = 63 THEN BLIT CLOSE #63
    BLIT READ #63, 0, 0, w, h
    PAGE WRITE 0

  ELSE
    NCprepareLogo = 0
  ENDIF
END FUNCTION

FUNCTION NCrmdir(filePath AS STRING) AS INTEGER
  'rmdir

  ON ERROR SKIP
  RMDIR filePath
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

SUB NCinitDebug
  'erase debug file

  OPEN NC_PATH.NC + "DEBUG.TXT" FOR OUTPUT AS #6
  CLOSE #6
END SUB

SUB NCoutDebug(s AS STRING)
  'append to debug file

  DBG OPEN NC_PATH.NC + "DEBUG.TXT" FOR APPEND AS #6
  DBG ?#6,s
  DBG CLOSE #6
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
    NCserialOut("D" + p, 1)
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

    NCchdir ACT_PATH.NC
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
      IF one <> LF.NC THEN
        IF LEN(NCreadUntilLF) < 250 THEN
          CAT NCreadUntilLF, one
        ENDIF
      ENDIF
      timeout = TIMER
    ENDIF
  LOOP
END FUNCTION

SUB NCserialDir(side AS INTEGER)
  'get dir from serial

  LOCAL INTEGER i, cnt
  LOCAL STRING lineSerial = ""

  DO WHILE lineSerial = ""
    lineSerial = NCreadUntilLF()
  LOOP
  IF LEFT$(lineSerial, 1) = "D" THEN
    cnt = VAL(MID$(lineSerial,2)) - 1
    PATH.NC(side) = FIELD$(lineSerial, 2, "|")
    COUNT.NC(side) = -1

    FOR i = 0 TO cnt
      lineSerial = ""
      NCserialOut("NEXT")         
      DO WHILE lineSerial = ""
        lineSerial = NCreadUntilLF()
      LOOP
      IF lineSerial <> "" THEN
        IF MID$(lineSerial, 2, 1) = "." THEN
          IF HIDDEN.NC OR LEFT$(lineSerial, 3) = "D.." THEN
            COUNT.NC(side) = COUNT.NC(side) + 1 
            ITEM.NC(side, COUNT.NC(side)) = lineSerial
          ENDIF
        ELSE
          COUNT.NC(side) = COUNT.NC(side) + 1 
          ITEM.NC(side, COUNT.NC(side)) = lineSerial
        ENDIF
      ELSE
        COUNT.NC(side) = COUNT.NC(side) + 1 
        ITEM.NC(side, COUNT.NC(side)) = "???"
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

  LOCAL STRING partData
  LOCAL INTEGER partNum, partRem

  IF NCisSerial(1-ACTIVE.NC) THEN
    IF NCisSerial(ACTIVE.NC) THEN
      'server to server
      IF TUIquestion("SERVER" + RIGHT.NC + "SERVER COPY","Copy '" + NCgetName(source) + "' to '" + NCgetPath(dest) + "'?") THEN
        NCserialOut("C" + source + "|" + dest, 1)

        partData = ""
        DO WHILE partData = ""
          partData = NCreadUntilLF()
        LOOP
        IF partData = "DONE" THEN
          NCserialOut("D" + NON_PATH.NC, 1)
          NCserialDir(1-ACTIVE.NC)
          POS.NC(1-ACTIVE.NC) = 0
          CURSOR.NC(1-ACTIVE.NC) = 0
          NCredrawPane(1-ACTIVE.NC)
        ENDIF
      ENDIF
    ELSE
      'local to server
      IF TUIquestion("LOCAL" + RIGHT.NC + "SERVER COPY","Copy '" + NCgetName(source) + "' to '" + NCgetPath(dest) + "'?") THEN
        NCfileToServer(source, dest)
      ENDIF
    ENDIF
  ELSE
    'server to local
    IF TUIquestion("SERVER" + RIGHT.NC + "LOCAL COPY","Copy '" + NCgetName(source) + "' to '" + NCgetPath(dest) + "'?") THEN
      NCfileFromServer(source, dest)
      NCchangeDir(1-ACTIVE.NC, NON_PATH.NC)
    ENDIF
  ENDIF
END SUB

SUB NCfileToServer(source AS STRING, dest AS STRING, dir AS INTEGER)
  'copy file from local to server

  CONST partLen = 250
  LOCAL STRING partData, dialog
  LOCAL INTEGER partNum, partRem, fileLen = MM.INFO(FILESIZE source), i, bufLen

  'NCoutDebug("NCfileToServer " + source + "," + dest + "," + STR$(dir))
  'NCserialOut("W" + NCgetName(source) + "|" + STR$(fileLen), 1)
  NCserialOut("W" + dest + "|" + STR$(fileLen), 1)

  partData = ""
  DO WHILE partData = ""
    partData = NCreadUntilLF()
  LOOP
  IF partData = "READY" THEN
    partNum = fileLen \ partLen
    partRem = fileLen MOD partLen

    IF fileLen > 5000 THEN
      dialog = TUIwaitingON("COPY '" + NCgetName(source) + "' (LOC" + RIGHT.NC + "SRV, " + STR$(fileLen) + " bytes)")
    ENDIF

    OPEN source FOR INPUT AS #2
    FOR i = 1 TO partNum
      IF fileLen > 5000 THEN
        TUIwaitingProgress(dialog, 100 * i / partNum)
      ENDIF
      DO WHILE LOF(#1) < partLen
      LOOP
      ?#1, INPUT$(partLen, #2);       
    NEXT i 

    IF partRem > 0 THEN
      DO WHILE LOF(#1) < partRem
      LOOP
      ?#1, INPUT$(partRem, #2);
    ENDIF

    CLOSE #2

    IF fileLen > 5000 THEN
      TUIwaitingOFF(dialog)
    ENDIF

    partData = ""
    DO WHILE partData = ""
      partData = NCreadUntilLF()
    LOOP
    IF partData = "DONE" AND NOT dir THEN
      NCserialOut("D" + NON_PATH.NC, 1)
      NCserialDir(1-ACTIVE.NC)
      POS.NC(1-ACTIVE.NC) = 0
      CURSOR.NC(1-ACTIVE.NC) = 0
      NCredrawPane(1-ACTIVE.NC)
    ENDIF
  ENDIF
END SUB

SUB NCserialOut(s AS STRING, useEspPrefix AS INTEGER)
  'print to serial with LF

  
  IF SERIAL_ON.NC THEN
    'ON ERROR SKIP
    'OPEN SERIAL_INIT.NC AS #1  
    ?#1,s + LF.NC;

  ELSEIF ESP_ON.NC THEN
    'ON ERROR SKIP
    'OPEN ESP_INIT.NC AS #1  
    IF useEspPrefix THEN
      ?#1, ESP_PREFIX.NC + s + LF.NC;
    ELSE
      ?#1, s + LF.NC;
    ENDIF
  ENDIF
END SUB

FUNCTION NCisDir(s AS STRING) AS INTEGER
  'return TRUE when DIR is selected
 
  NCisDir = LEFT$(s, 1) = "D"
END FUNCTION

SUB NCmakeMAR
  'create MAR achive

  CONST maxLen = 128
  LOCAL INTEGER ind = 0, td=0, size, filePos
  LOCAL STRING item, path, partData
  LOCAL STRING pth(MAX_ITEMS.NC)
  LOCAL STRING toDo(MAX_ITEMS.NC)
  LOCAL STRING dest = NON_PATH.NC + SEL_NAME.NC + ".MAR"
  
  LOCAL STRING ccc = TUIwaitingON("MAKE MAR ARCHIVE") 
  TUIwaitingProgress(ccc, 0)

  pth(ind) = ACT_PATH.NC + SEL_NAME.NC
  toDo(td) = pth(ind)
  DO WHILE ind >= 0
    NCchdir pth(ind)
    path = pth(ind)
    ind = ind - 1
    item = DIR$("", ALL)
    DO WHILE item <> ""
      IF LEFT$(item, 1) <> "." OR HIDDEN.NC THEN
        size = MM.INFO(FILESIZE item)
        IF size<0 THEN
          'directory
          ind = ind + 1
          pth(ind) = path + "/" + item                
          td = td + 1
          toDo(td) = path + "/" + item + "/"
 
        ELSE
          'file
          td = td + 1
          toDo(td) = path + "/" + item
        ENDIF
      ENDIF
      item = DIR$()
    LOOP
  LOOP

  TUIwaitingProgress(ccc, 10)

  SORT toDo(),,2,0,td+1 
  toDo(0) = toDo(0) + "/"
  path = toDo(0)
  OPEN dest FOR OUTPUT AS #2
  FOR ind = 0 TO td
    TUIwaitingProgress(ccc, 10 + ind/td*90)
    item = toDo(ind)
    IF RIGHT$(item, 1) = "/" THEN
      DO WHILE INSTR(item, path) = 0
        ?#2,"ENDDIR: " + NCgetName(LEFT$(path, LEN(path)-1))
        path = NCparent(path)  
      LOOP
      ?#2,"DIR: " + NCgetName(LEFT$(item, LEN(item)-1)) '" ("item")"
      path = item
    ELSE
      DO WHILE INSTR(item, path) = 0
        ?#2,"ENDDIR: " + NCgetName(LEFT$(path, LEN(path)-1))
        path = NCparent(path)  
      LOOP
      ?#2,"FILE: " + NCgetName(item) '" ("item")"
      filePos = 0
      OPEN item FOR INPUT AS #3
      ?#2,LOF(#3)
      DO WHILE NOT EOF(#3)
        size = MIN(LOF(#3) - filePos, maxLen)
        filePos = filePos + size
        partData = INPUT$(size, #3)
        ?#2, partData;
      LOOP
      CLOSE #3
    ENDIF
  NEXT ind
  ?#2,"ENDDIR: " + NCgetName(LEFT$(toDo(0), LEN(toDo(0))-1))
  ?#2,"ENDARCHIVE:" 
  CLOSE #2
  TUIwaitingOFF(ccc)
END SUB

SUB NCinit
  'INIT

  IF MM.INFO(VERSION) < MIN_VERSION.NC THEN
    FONT.TUI = 1
    TUIwarning("VERSION CHECK", "FW version >= " + STR$(MIN_VERSION.NC,1,2) + " needed, you have " + STR$(MM.INFO(VERSION), 1, 2))
    OPTION BREAK 3
    END
  ENDIF

  LOCAL INTEGER i
  FOR i = 32 TO 127
    CAT WIFICHARS.NC, CHR$(i)
  NEXT i

  INIT.NC = 1

  NCconfigLoad
  IF CFG_HighColor.NC THEN
    MODE 1,16
  ELSE
    MODE 1,8
  ENDIF

  LOGO.NC = NCprepareLogo("NAPOLEON.SPR")

  CURSOR.NC(0) = 0
  CURSOR.NC(1) = 0       'left and right cursor
  POS.NC(0) = 0
  POS.NC(1) = 0       'left and right position
  COUNT.NC(0) = -1
  COUNT.NC(1) = -1 'left and right items count
  PATH.NC(0) = ACT_PATH.NC                   'left path
  PATH.NC(1) = ACT_PATH.NC                  'right path

  ON ERROR SKIP
  LOAD FONT NC_PATH.NC + FONT.NC
  IF MM.ERRNO > 0 THEN
    FONT.TUI = 1
    TUIwarning("FONT LOAD ERROR", "Font file '" + NC_PATH.NC + FONT.NC + "' not found!")
    OPTION BREAK 3
    CLS
    END
  ELSE
    FONT #8,1
  ENDIF
  CLS RGB(NOTBLACK)
  NCsetMenu(0, "Help", 1)
  NCsetMenu(1, "GetInf", 1)
  NCsetMenu(2, "Viewer" , 1)
  NCsetMenu(3, "Editor" , 0)
  NCsetMenu(4, "Copy"   , 1)
  NCsetMenu(5, "Rename", 1)
  NCsetMenu(6, "NewDir", 1)
  NCsetMenu(7, "Delete", 1)
  NCsetMenu(8, "MakMAR", 1)
  NCsetMenu(9, "QuitNC", 1)
  NCsetMenu(10,"Config", 1)
  NCsetMenu(11,"LP=RP", 1)
 
  NCdrawMenu

  SETTICK 1000, NCclock
END SUB

SUB NCsetMenu(n AS INTEGER, t AS STRING, e AS INTEGER)
  'set name of F-key menu

  IF n>=0 THEN
    IF n<12 THEN
      MENU.NC(n) = LEFT$(t + SPACE$(6), 6)
      EN_MENU.NC(n) = e
    END IF
  END IF
END SUB

SUB NCdrawMenuPart(fn AS INTEGER)
  'draws menu at bottom
  LOCAL INTEGER back, xx = 2

  IF EN_MENU.NC(fn-1) THEN
    back = RGB(CYAN)
  ELSE
    back = RGB(GRAY)
  ENDIF

  IF MENU.NC(fn-1) <> "" THEN
    xx = 4 + (fn - 1) * 56
    IF fn > 1 THEN xx = xx +  (fn-1)*9
    IF fn > 10 THEN xx = xx + (fn-10) *8 
    TEXT xx, 584, STR$(fn,0,0),,,, RGB(WHITE), RGB(NOTBLACK)
    xx = xx + 8
    IF fn > 9 THEN xx = xx + 8  
    TEXT xx,584, MENU.NC(fn-1),,,,RGB(NOTBLACK),back
  END IF
END SUB

SUB NCdrawMenu
  'draws menu at bottom
  LOCAL INTEGER i, back, xx = 2

  BOX 0,600-16,800,16,0,,RGB(NOTBLACK)
  FOR i = 1 TO 12
    NCdrawMenuPart(i)
  NEXT i    
END SUB

SUB NCesc
  IF CFG_ESCup.NC THEN
    IF NCisSerial(ACTIVE.NC) THEN
      'serial port
      IF LEFT$(ITEM.NC(ACTIVE.NC, 0), 3) = "D.." THEN
        IF SEL_NAME.NC = ".." THEN
          STR.NC = NCparent(ACT_PATH.NC)
        ELSE
          STR.NC = ACT_PATH.NC + SEL_NAME.NC
        ENDIF
        NCserialOut("D" + STR.NC, 1)
        NCserialDir(ACTIVE.NC)
        ACT_PATH.NC = NCchangePath(ACT_PATH.NC, SEL_NAME.NC)
        NCdrawCL(ACT_PATH.NC)
        NCredrawPane(ACTIVE.NC)
        NCcursor(ACTIVE.NC, 1)
      ENDIF
    ELSE
      IF LEFT$(ITEM.NC(ACTIVE.NC, 0), 3) = "D.." THEN
        ACT_PATH.NC = NCchangePath(ACT_PATH.NC, "..")
        NCchangeDir(ACTIVE.NC,ACT_PATH.NC)
        NCdrawCL(ACT_PATH.NC)
        NCcursor(ACTIVE.NC,1)
      ENDIF
    ENDIF
  ENDIF
END SUB

SUB NCenter
  'ENTER pressed

  TUIwaitForNoKey
  IF NCisDir(SELECTED.NC) THEN
    IF NCisSerial(ACTIVE.NC) THEN
      'serial port
      IF SEL_NAME.NC = ".." THEN
        STR.NC = NCparent(ACT_PATH.NC)
      ELSE
        STR.NC = ACT_PATH.NC + SEL_NAME.NC
      ENDIF
      NCserialOut("D" + STR.NC, 1)
      NCserialDir(ACTIVE.NC)
      CURSOR.NC(ACTIVE.NC) = 0
      POS.NC(ACTIVE.NC) = 0
      NCcursor(ACTIVE.NC,0)
      NCdrawCL(ACT_PATH.NC)
      NCredrawPane(ACTIVE.NC)
      NCcursor(ACTIVE.NC,1)
    ELSE
      ACT_PATH.NC = NCchangePath(ACT_PATH.NC, SEL_NAME.NC)      
      NCchangeDir(ACTIVE.NC, ACT_PATH.NC)
      NCdrawCL(ACT_PATH.NC)
      NCcursor(ACTIVE.NC, 1)
    ENDIF
  ELSE
    IF NOT NCisSerial(ACTIVE.NC) THEN
      NCaction(ACT_PATH.NC, SEL_NAME.NC)
    ENDIF
  ENDIF
END SUB

SUB NCbasPretty(p AS STRING)
  LOCAL STRING ln, tst
  LOCAL STRING nm = NCgetPath(p) + NCgetNoExtension(NCgetName(p))
  LOCAL INTEGER indent = 0,plus

  'phase 1
  OPEN p FOR INPUT AS #2
    OPEN  nm + ".TEMP" FOR OUTPUT AS #3
      DO WHILE NOT EOF(#2)
        plus = 0
        LINE INPUT #2, ln
        ln = NCtrim(ln)
        tst = UCASE$(ln)
        IF LEFT$(tst, 4) = "SUB " THEN
          plus = 2

        ELSEIF LEFT$(tst, 7) = "END SUB" THEN
          INC indent, -2

        ELSEIF LEFT$(tst, 9) = "FUNCTION " THEN 
          plus = 2

        ELSEIF LEFT$(tst, 12) = "END FUNCTION" THEN 
          INC indent, -2

        ELSEIF LEFT$(tst, 2) = "DO" OR INSTR(tst, ":DO") > 0 THEN 
          plus = 2
    
        ELSEIF LEFT$(tst, 4) = "LOOP" OR INSTR(tst, ":LOOP") > 0 THEN 
          INC indent, -2
   
        ELSEIF LEFT$(tst, 3) = "IF " OR INSTR(tst, ":IF") > 0 THEN 
          plus = 2
    
        ELSEIF LEFT$(tst, 4) = "ELSE" THEN 
          plus = 2
          INC indent, -2

        ELSEIF LEFT$(tst, 5) = "ENDIF" OR INSTR(tst, ":ENDIF") > 0 THEN 
          INC indent, -2
    
        ELSEIF LEFT$(tst, 4) = "FOR " OR INSTR(tst, ":FOR ") > 0 THEN 
          plus = 2
    
        ELSEIF LEFT$(tst, 4) = "NEXT" OR INSTR(tst, ":NEXT") > 0 THEN 
          INC indent, -2

        ENDIF    
        IF indent > 0 THEN
          ?#3, SPACE$(indent) + ln
        ELSE
          ?#3, ln
        ENDIF
        INC indent, plus
      LOOP
    CLOSE #3
  CLOSE #2

  'phase 2
'  IF NOT NCkill(p) THEN
'    IF NOT NCrename(nm + ".TEMP", nm + ".BAS") THEN
'      'rename error
'      NCchangeDIr(ACTIVE.NC, ACT_PATH.NC)
'      NCcursor(ACTIVE.NC, 1)
'    ENDIF
'  ELSE
'    'delete error
'  ENDIF
END SUB

SUB NCbasHelp(filePath AS STRING)
  'BASIC Helpers
  
  IF NOT NCisSerial(ACTIVE.NC) THEN
    LOCAL INTEGER helper = TUIchoice("BASIC HELPERs", "Pretty format,DEBUG ON,DEBUG OFF")
    SELECT CASE helper
      CASE 0' nicer
        IF TUIquestion("BASIC HELPERS", "Format '" + NCgetName(filePath) + "' pretty ?") THEN
          'NCbasPretty(filePath)
          TUIwarning("PRETTY FORMAT", "Not enabled yet")
        ENDIF

      CASE 1' debug ON
        IF TUIquestion("BASIC HELPERS", "Switch in '" + NCgetName(filePath) + "' debuging ON ?") THEN
          NCbasDebug(filePath, 1)
        ENDIF

      CASE 2' debug OFF
        IF TUIquestion("BASIC HELPERS", "Switch in '" + NCgetName(filePath) + "' debuging OFF ?") THEN
          NCbasDebug(filePath, 0)
        ENDIF

    END SELECT
  ENDIF
END SUB

SUB NCunMAR(filePath AS STRING)
  CONST maxChunkSize = 128
  LOCAL INTEGER fiLen, curLen = 0, chunkLen, fiPos = 0, totLen = 0
  LOCAL STRING li, cmd, par, k, p = NON_PATH.NC
  LOCAL STRING dialog

  EXT_ERR.NC = 0
  IF TUIquestion("EXTRACT MAR", "Extract '" + filePath + "' to '" + p + "' ?") THEN
    dialog = TUIwaitingON("EXTRACT MAR '" + NCgetName(filePath) + "'")
    totLen = MM.INFO(FILESIZE filePath)
    OPEN filePath FOR INPUT AS #3
    DO WHILE NOT EOF(#3)
      LINE INPUT #3, li
      fiPos = fiPos + LEN(li) + 2
      cmd = FIELD$(li,1,":")
      par = FIELD$(li,2,":")
      SELECT CASE cmd
        CASE "DIR"
          DO WHILE LEFT$(par,1)="." OR LEFT$(par,1)="/"
            par = MID$(par,2)      
          LOOP
          p = p + par + "/"
          ON ERROR SKIP
          MKDIR p
          IF MM.ERRNO > 0 THEN 
            CLOSE #3
            EXT_ERR.NC=1
            NCerror("DIR '" + p + "' ERROR")
            EXIT SUB
          ENDIF
    
        CASE "FILE"
          curLen = 0
          LINE INPUT #3, li
          fiPos = fiPos + LEN(li) + 2
          fiLen = VAL(li)
          OPEN p+par FOR OUTPUT AS #4
          DO WHILE curLen < fiLen        
            chunkLen = MIN(fiLen - curLen,maxChunkSize)
            curLen = curLen + chunkLen
            li = INPUT$(chunkLen, #3)
            PRINT #4,li;
          LOOP
          CLOSE #4
          fiPos = fiPos + fiLen
        CASE "ENDDIR"
          p = NCparent(p)

                
        CASE "ENDARCHIVE"
              
      END SELECT

      TUIwaitingProgress(dialog, 100 * fiPos \ totLen)
    LOOP

    CLOSE #3
    TUIwaitingOFF(dialog)

  ENDIF
  NCchangeDir(1 - ACTIVE.NC, NON_PATH.NC)
  NCcursor(ACTIVE.NC,1)
END SUB

SUB NCviewMAR(filePath AS STRING)
  CONST maxChunkSize = 128
  LOCAL INTEGER firstRow = 16+4, row = 0, fiLen, curLen = 0, chunkLen
  LOCAL STRING li, cmd, par, k
  LOCAL INTEGER indent = 0, pg = 1
  LOCAL STRING dialog
  
  EXT_ERR.NC = 0

  CLS RGB(NOTBLACK)
  BOX 0,16,800,600-32,0,,RGB(CYAN)
  LINE 0,7,800,7,2,RGB(WHITE)
  LINE 0,600-8,800,600-8,2,RGB(WHITE)
  TEXT 400,0," " + filePath + " ","CT",8,,RGB(WHITE),RGB(NOTBLACK)
  BOX 0,16,800,600-32,0,,RGB(CYAN)
  TEXT 400,600-16," Page " + STR$(pg) + " ","CT",8,,RGB(WHITE),RGB(NOTBLACK)
  TEXT 0,600-16,"PgDOWN/ESC ","LT",8,,RGB(WHITE),RGB(NOTBLACK)

  OPEN filePath FOR INPUT AS #3
  DO WHILE NOT EOF(#3)
    LINE INPUT #3, li
    cmd = FIELD$(li,1,":")
    par = FIELD$(li,2,":")
    SELECT CASE cmd
      CASE "DIR"
        DO WHILE LEFT$(par,1)="." OR LEFT$(par,1)="/"
          par = MID$(par,2)      
        LOOP
        TEXT 0,firstRow + row, SPACE$(2*indent) + "DIR "+par,"LT",8,,RGB(NOTBLACK), RGB(CYAN)
        indent = indent + 2
        row = row + 16 
    
      CASE "FILE"
        dialog = TUIwaitingON("READ FILE")
        curLen = 0
        LINE INPUT #3, li
        fiLen = VAL(li)
        TEXT 0,firstRow + row, SPACE$(2*indent) + "FILE " + par + " (" + STR$(fiLen) + " bytes)","LT",8,,RGB(NOTBLACK), RGB(CYAN)
        row = row + 16 
        DO WHILE curLen < fiLen        
          chunkLen = MIN(fiLen - curLen,maxChunkSize)
          curLen = curLen + chunkLen
          li = INPUT$(chunkLen, #3)
        LOOP
        TUIwaitingOFF(dialog)

      CASE "ENDDIR"
        indent = indent - 2
        TEXT 0,firstRow + row, SPACE$(2*indent) + "END DIR","LT",8,,RGB(NOTBLACK), RGB(CYAN)
        row = row + 16 
        
      CASE "ENDARCHIVE"
        TEXT 0,firstRow + row, SPACE$(2*indent) + "END ARCHIVE","LT",8,,RGB(NOTBLACK), RGB(CYAN)
        row = row + 16 
              
    END SELECT

    IF row> 34*16 THEN 
      pg = pg + 1
      row = 0
      DO: k = INKEY$: LOOP WHILE k<>CHR$(137) AND k<>CHR$(27)
      IF k=CHR$(27) THEN
        EXIT DO
      ELSE
        BOX 0,16,800,600-32,0,,RGB(CYAN)   
        TEXT 400,600-16," Page " + STR$(pg) + " ","CT",8,,RGB(WHITE),RGB(NOTBLACK)
      ENDIF
    ENDIF
  LOOP
  TEXT 400,600-16," Page " + STR$(pg) + " ","CT",8,,RGB(WHITE),RGB(NOTBLACK)

  CLOSE #3
  DO WHILE k<>CHR$(27)
    k = INKEY$
  LOOP
  NCredrawPane(0)
  NCredrawPane(1)  
  NCcursor(ACTIVE.NC,1)
  NCdrawMenu
END SUB

SUB NCfKeys(fkey AS INTEGER)
  IF NOT EN_MENU.NC(fkey-145) THEN EXIT SUB

  SELECT CASE fkey
    CASE 145  'F1
      IF ALT.NC THEN
        INT.NC = TUIchoice("LEFT PANE","A:/,S:/")
        SELECT CASE INT.NC
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

    CASE 146  'F2
      IF ALT.NC THEN
        INT.NC = TUIchoice("RIGHT PANE","A:/,S:/")
        SELECT CASE INT.NC
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
        IF NCisSerial(ACTIVE.NC) THEN
          IF NCisDir(SELECTED.NC) THEN
            DIALOG.NC = TUIwaitingON("GET INFO")
            INT.NC = NCserverDirInfo(ACT_PATH.NC+SEL_NAME.NC)
            TUIwaitingOFF(DIALOG.NC)     
            TUIwarning("GET INFO","'"+SEL_NAME.NC+"' has "+STR$(INT.NC>>16,0,0)+" bytes in " + STR$(INT.NC AND &hFFFF,0,0)+" items")
          ENDIF
        ELSE
          IF SELECTED.NC <> "D.." THEN
            IF NCisDir(SELECTED.NC) THEN
              DIALOG.NC = TUIwaitingON("GET INFO")
              INT.NC = NCmeasure(ACT_PATH.NC+SEL_NAME.NC)
              TUIwaitingOFF(DIALOG.NC)     
              TUIwarning("GET INFO","'"+SEL_NAME.NC+"' has "+STR$(INT.NC>>16,0,0)+" bytes in " + STR$(INT.NC AND &hFFFF,0,0)+" items")
            ELSE
              NCgetInfo(ACT_PATH.NC+SEL_NAME.NC)
            ENDIF
          ENDIF
        ENDIF
      ENDIF

    CASE 147  'F3
      IF NOT NCisSerial(ACTIVE.NC) THEN
        IF NOT NCisDir(SELECTED.NC) THEN
          NCview
        ENDIF
      ENDIF
  
    CASE 148  'F4
      IF ALT.NC THEN
        IF NOT NCisDir(SELECTED.NC) THEN
          LOCAL STRING  ex = UCASE$(NCgetExtension(SELECTED.NC))
          IF ex = "BAS" or ex = "INC" THEN
            NCbasHelp(ACT_PATH.NC + SEL_NAME.NC)
          ENDIF
        ENDIF
      ELSE
        IF NOT NCisDir(SELECTED.NC) AND NOT NCisSerial(ACTIVE.NC) THEN
          NCeditHEX(ACT_PATH.NC + SEL_NAME.NC)
        ENDIF
      ENDIF

    CASE 149  'F5
      IF ALT.NC THEN
        IF NCisSerial(0) OR NCisSerial(1) THEN
          TUIwarning("MOVE SERVER ITEM", "Move to/from server not supported yet")
        ELSE
          IF LEFT$(SELECTED.NC,3)<>"D.." THEN
            IF PATH.NC(0) = PATH.NC(1) THEN 'RENAME
              NCrenameItem     
            ELSE 'MOVE
              IF NCisDir(SELECTED.NC) THEN
                'MOVE DIR        
                IF NCinsideTest(ACT_PATH.NC + SEL_NAME.NC + "/", NON_PATH.NC + SEL_NAME.NC + "/") THEN
                  TUIwarning("MOVE DIR ","Move something into itself is VERY bad idea!")
                  EXIT SUB
                ENDIF  
                IF TUIquestion("MOVE DIR", "Move '" + SEL_NAME.NC+"' to '" + NON_PATH.NC + "'?") THEN
                  STORE.NC = SELECTED.NC
                  NCcopyDir(ACT_PATH.NC + SEL_NAME.NC + "/", NON_PATH.NC + SEL_NAME.NC + "/")
                  NCdelete(STORE.NC, 1)
                ENDIF         
              ELSE
                'MOVE FILE
                NCmoveFile(ACT_PATH.NC+SEL_NAME.NC,NON_PATH.NC+SEL_NAME.NC)
              ENDIF
            ENDIF
          ENDIF
        ENDIF      
      ELSE
        IF NCisSerial(0) OR NCisSerial(1) THEN
          'copy to/from/on server
          IF NCisDir(SELECTED.NC) THEN
            IF NCinsideTest(ACT_PATH.NC+SEL_NAME.NC+"/",NON_PATH.NC+SEL_NAME.NC+"/") THEN
              TUIwarning("COPY DIR ","Copy something into itself is VERY bad idea!")
            ELSE
              IF NOT NCisSerial(ACTIVE.NC) THEN
                IF TUIquestion("SERVER DIR COPY", "Copy '" + ACT_PATH.NC + SEL_NAME.NC + "' to '" +  NON_PATH.NC + "' ?") THEN
                  NCdirToServer(ACT_PATH.NC + SEL_NAME.NC, NON_PATH.NC)
                ENDIF
              ELSE      
                IF NCisSerial(0) AND NCisSerial(1) THEN
                  NCserverCopy(ACT_PATH.NC + SEL_NAME.NC, NON_PATH.NC + SEL_NAME.NC)
                ELSE
                  'TUIwarning("COPY DIR", "Copy dir from/on server not supported yet")
                  IF TUIquestion("SERVER DIR COPY", "Copy '" + ACT_PATH.NC + SEL_NAME.NC + "' to '" +  NON_PATH.NC + "' ?") THEN
                    NCdirFromServer(ACT_PATH.NC + SEL_NAME.NC, NON_PATH.NC)
                  ENDIF
                ENDIF
              ENDIF
            ENDIF    
          ELSE
            NCserverCopy(ACT_PATH.NC+SEL_NAME.NC,NON_PATH.NC+SEL_NAME.NC)
          ENDIF

        ELSE
          'copy SD
          IF LEFT$(SELECTED.NC,3)<>"D.." THEN
            IF PATH.NC(0) = PATH.NC(1) THEN
              'COPY as new name
              STR.NC = TUIinput("COPY AS","New name for '"+SEL_NAME.NC+"'",NCnewName(NON_PATH.NC,SEL_NAME.NC),FILECHARS.NC)
              IF STR.NC <> SEL_NAME.NC AND STR.NC <> "" THEN
                IF SEL_TYPE.NC = "F" THEN
                  NCcopyFile(ACT_PATH.NC+SEL_NAME.NC,NON_PATH.NC+STR.NC,0)    
                ELSE
                  NCcopyDir(ACT_PATH.NC+SEL_NAME.NC+"/",NON_PATH.NC+STR.NC+"/",1)     
                ENDIF
              ENDIF                  
            ELSE
              IF NCisDir(SELECTED.NC) THEN
                'COPY DIR
                IF TUIquestion("COPY DIR", "Copy '"+SEL_NAME.NC+"' to '"+NON_PATH.NC+"'?") THEN
                  NCcopyDir(ACT_PATH.NC+SEL_NAME.NC+"/",NON_PATH.NC+SEL_NAME.NC+"/")     
                ENDIF
              ELSE
                'COPY FILE
                IF TUIquestion("COPY FILE", "Copy '"+SEL_NAME.NC+"' to '"+NON_PATH.NC+"'?") THEN
                  NCcopyFile(ACT_PATH.NC+SEL_NAME.NC,NON_PATH.NC+SEL_NAME.NC)
                ENDIF
              ENDIF
            ENDIF 
          ENDIF       
        ENDIF
      ENDIF

    CASE 150  'F6
      IF LEFT$(SELECTED.NC,3)<>"D.." THEN
        NCrenameItem     
      ENDIF

    CASE 151  'F7
      STR.NC = TUIinput("MAKE NEW DIRECTORY","Directory name:","NewDir", FILECHARS.NC)
      IF STR.NC<>"" THEN
        IF NCmkdir(ACT_PATH.NC+STR.NC) THEN 
          TUIwarning("MAKE DIR", "MakeDir '" + STR.NC + "' ERROR")
        ELSE
          NCchangeDir(ACTIVE.NC, PATH.NC(ACTIVE.NC))
          IF NCnonActiveChange() THEN NCchangeDir(1 - ACTIVE.NC, PATH.NC(1 - ACTIVE.NC))
          NCcursor(ACTIVE.NC,1)
        ENDIF
      ENDIF

    CASE 152  'F8, DEL 127 is sometimes stuck...
      IF LEFT$(SELECTED.NC,3)<>"D.." THEN
        IF NCisSerial(ACTIVE.NC) THEN
          IF TUIquestion("DELETE ON SERVER", "Delete '" + SEL_NAME.NC + "', really proceed?") THEN
            NCserialOut("K" + ACT_PATH.NC + SEL_NAME.NC, 1)
            NCchangeDir(ACTIVE.NC,ACT_PATH.NC)
            IF NCinsideTest(ACT_PATH.NC+SEL_NAME.NC+"/",NON_PATH.NC+SEL_NAME.NC+"/") THEN
              NCchangeDir(1-ACTIVE.NC,ACT_PATH.NC)
            ENDIF
            NCcursor(ACTIVE.NC,1)
          ENDIF
        ELSE
          NCdelete(SELECTED.NC)
        ENDIF
      ENDIF

    CASE 153  'F9
      IF (NOT NCisSerial(0)) AND (NOT NCisSerial(1)) THEN
        IF LEFT$(SELECTED.NC,3)<>"D.." THEN
          IF ALT.NC THEN
            IF NOT NCisDir(SELECTED.NC) THEN
              NCmakeARC(ACT_PATH.NC + SEL_NAME.NC)
            ENDIF
          ELSE
            IF NCisDir(SELECTED.NC) THEN
              IF TUIquestion("MAKE MAR ARCHIVE","Archive '" + ACT_PATH.NC + SEL_NAME.NC + "' to '" + SEL_NAME.NC + ".MAR' ?") THEN
                IF NCexist(ACT_PATH.NC + SEL_NAME.NC + ".MAR") THEN
                  IF TUIquestion("MAKE MAR ARCHIVE", "Archive '" + SEL_NAME.NC + ".MAR' already exists, replace?") THEN
                    NCmakeMAR
                    NCchangeDir(0,PATH.NC(0))
                    NCchangeDir(1,PATH.NC(1))
                    NCcursor(ACTIVE.NC,1)
                  ENDIF
                ELSE
                  NCmakeMAR
                  NCchangeDir(0,PATH.NC(0))
                  NCchangeDir(1,PATH.NC(1))
                  NCcursor(ACTIVE.NC,1)
                ENDIF
              ENDIF
            ENDIF
          ENDIF
        ENDIF
      ENDIF
      
    CASE 154  'F10
      IF ALT.NC THEN
        IF TUIquestion("QUIT", "Are you ready to leave me alone?") THEN
          NCchdir ACT_PATH.NC
          NCconfigSave(NCconfigPack())
          OPTION BREAK 3
          CLS
          END
        ENDIF
      ELSE
        LOCAL STRING about(10) LENGTH 100
        LOCAL STRING myVer = STR$(MM.INFO(VERSION), 1, 2) + "." + RIGHT$(STR$(MM.INFO(VERSION) * 10000, 5, 0),2)
        LOCAL STRING myCMM2 = MM.DEVICE$ + " (" + LEFT$(STR$(MM.INFO(CPUSPEED)), 3) + "MHz), v" + myVer
        about(0) = "              My name is Napoleon Commander (" + NCdigital(VERSION.NC) + ")"
        about(1) = ""
        about(2) = "              Born on: 7. November 2020"
        about(3) = "              Where  : Czech Republic"
        about(4) = "              Father : " + CHR$(157) + "JirSoft"
        about(5) = "              Mother : Unknown"
        about(6) = "              Sisters: TUI.INC v" + VERSION.TUI + ", GRF.INC v" + VERSION.GRF
        about(7) = ""
        about(8) = "I'm living inside of " + myCMM2
        IF ESP_VERSION.NC <> "" THEN
          about(9)="and have also implanted an special organ, " + ESP_VERSION.NC
        ENDIF
        IF WIFI.NC THEN
          about(10)= "(connected to " + FIELD$(ESP_CONNECTION.NC, 1, ",") + ", BSSID " + FIELD$(ESP_CONNECTION.NC, 2, ",") + ")"
        ENDIF
        TUIinfo("ABOUT ME",about(), LOGO.NC)
      ENDIF

    CASE 155  'F11
      NCconfig

    CASE 156  'F12
      IF ALT.NC THEN
        NCwifi
      ELSE
        NCchangeDir(1-ACTIVE.NC,ACT_PATH.NC)        
        NCredrawPane(1-ACTIVE.NC)
      ENDIF

  END SELECT
END SUB

SUB NCunARC(source AS STRING)
  'decompress CMM2 archive file (ARC)

  LOCAL INTEGER arcLen = MM.INFO(FILESIZE source), srcLen = 0, rle, fiPos = 0, i
  LOCAL STRING header, prev
  LOCAL STRING dest = NON_PATH.NC + NCgetNoExtension(NCgetName(source))

  IF TUIquestion("UNCOMPRESS ARC","Uncompress '" + NCgetName(source) + "' to '" + NON_PATH.NC + "' ?") THEN

    OPEN source FOR INPUT AS #3
    LINE INPUT #3, header
    srcLen = VAL(FIELD$(header, 3, ","))
    INC fiPos, 2 + LEN(header)
    CAT dest, "." + FIELD$(header, 2, ",")    
    SELECT CASE LEFT$(header, 3)
      CASE "RLE"
        'RLE, first archiver
        LOCAL STRING dialog = TUIwaitingON("UNCOMPRESS ARC")
        TUIwaitingProgress(dialog, 0)
        OPEN dest FOR OUTPUT AS #4
        DO WHILE NOT EOF(#3)
          rle = ASC(INPUT$(1, #3))
          INC fiPos
          IF rle < 128 THEN
            'raw data
            INC fiPos, rle + 1
            INC srcLen, rle + 1
            
            FOR i = 1 TO rle + 1
              ?#4,INPUT$(1, #3);
            NEXT i

          ELSE
            'compressed data
            prev = INPUT$(1, #3)
            INC srcLen, rle - 127
            INC fiPos
            FOR i = 1 TO rle - 127
              ?#4,prev;
            NEXT i
          ENDIF

          TUIwaitingProgress(dialog, 100 * fiPos / arcLen)
        LOOP
        CLOSE #4 
        TUIwaitingOFF(dialog)
    
      CASE "HUF"
        'HUFFMAN, slow :-(
        LOCAL STRING dialog = TUIwaitingON("UNCOMPRESS ARC")
        LOCAL INTEGER tLen = ASC(INPUT$(1, #3))
        LOCAL STRING bit(tLen - 1), bb = ""
        LOCAL INTEGER ind(tLen - 1), bits

        TUIwaitingProgress(dialog, 0)

        ind(0) = ASC(INPUT$(1, #3))
        bits = ASC(INPUT$(1, #3))
        bit(0) = STRING$(bits, "0")
        '?ind(0), bit(0)
        FOR rle = 1 TO tLen - 1
          ind(rle) = ASC(INPUT$(1, #3))
          bits = ASC(INPUT$(1, #3))
          bit(rle) = BIN$((VAL("&b" + bit(rle - 1)) + 1) << (bits - LEN(bit(rle - 1))), bits)
          '?ind(rle), bit(rle)
        NEXT rle
        INC fiPos, 1 + 2 * tLen

        TUIwaitingProgress(dialog, 100 * fiPos / arcLen)

        OPEN dest FOR OUTPUT AS #4
        DO WHILE NOT EOF(#3)
          FOR rle = 0 TO tLen - 1
            IF LEN(bb) < LEN(bit(rle)) THEN
              CAT bb, BIN$(ASC(INPUT$(1, #3)), 8)
              INC fiPos
            ENDIF
            IF LEFT$(bb, LEN(bit(rle))) = bit(rle) THEN
              ?#4, CHR$(ind(rle));
              INC srcLen, -1
              bb = MID$(bb, LEN(bit(rle)) + 1)
              EXIT FOR
            ENDIF
          NEXT rle
          TUIwaitingProgress(dialog, 100 * fiPos / arcLen)
        LOOP
        DO WHILE srcLen > 0
          FOR rle = 0 TO tLen - 1
            IF LEFT$(bb, LEN(bit(rle))) = bit(rle) THEN
              ?#4, CHR$(ind(rle));
              bb = MID$(bb, LEN(bit(rle)) + 1)
              INC srcLen, -1
              EXIT FOR
            ENDIF
          NEXT rle
        LOOP
        CLOSE #4        
        TUIwaitingOFF(dialog)

      CASE ELSE
        TUIwarning("UNCOMPRESS ARC", "Decompression of '" + LEFT$(header,3) + "' not implemented yet")
        CLOSE #3
        EXIT SUB

    END SELECT
    CLOSE #3  
    NCchangeDir(0,PATH.NC(0))
    NCchangeDir(1,PATH.NC(1))
    NCcursor(ACTIVE.NC,1)
  ENDIF
END SUB

SUB NCmakeARC(source AS STRING)
  'make CMM2 archive file (ARC)

  LOCAL INTEGER srcLen = MM.INFO(FILESIZE source), arcLen = 0, rle, fiPos = 0, arcTypeInt = 1
  LOCAL STRING header, prev, byt, buf
  LOCAL STRING dest = NON_PATH.NC + NCgetNoExtension(NCgetName(source)) + ".ARC"

  IF TUIquestion("COMPRESS TO ARC","Compress '" + NCgetName(source) + "' to '" + NCgetName(dest) + "' ?") THEN
    'arcTypeInt = TUIchoice("ARC COMPRESS ALGORITHM","RLE - faster but not so universal,HUFMAN - slow but good")

    SELECT CASE arcTypeInt
      
      CASE  0 '
        'RLE, first archiver

        LOCAL STRING dialog = TUIwaitingON("COMPRESS TO ARC")
        TUIwaitingProgress(dialog, 0)
        OPEN source FOR INPUT AS #3
        OPEN dest FOR OUTPUT AS #4
        header =  "RLE," + NCgetExtension(source) + "," + STR$(srcLen) '3 char archiver name, source extension, source size
        INC arcLen, LEN(header) + 2
        ?#4, header
        buf = ""     
        IF NOT EOF(#3) THEN      
          byt = INPUT$(1, #3)
          INC fiPos
          prev = byt
          rle = 0
        ELSE
          prev = ""
        ENDIF
        DO WHILE prev <> ""
          TUIwaitingProgress(dialog, 100 * fiPos / srcLen)
          IF byt = prev AND rle < 128 THEN
            INC rle
          ELSEIF rle > 1 OR rle = 128 THEN
            IF buf <> "" THEN
              ?#4, CHR$(LEN(buf) - 1) + buf;
              INC arcLen, LEN(buf) + 1
              buf = ""
            ENDIF
            ?#4, CHR$(128 + rle - 1) + prev;
            INC arcLen, 2
            rle = 1
          ELSEIF rle = 1 THEN
            IF LEN(buf) < 128 THEN
              CAT buf, prev
            ELSE
              ?#4, CHR$(LEN(buf) - 1) + buf;
              INC arcLen, LEN(buf) + 1
              buf = prev
            ENDIF
            rle = 1
          ENDIF
          prev = byt
          IF NOT EOF(#3) THEN
            byt = INPUT$(1, #3) 
            INC fiPos
          ELSE
            byt = ""
          ENDIF
        LOOP
        IF buf <> "" THEN
          ?#4, CHR$(LEN(buf) - 1) + buf;
          INC arcLen, LEN(buf) + 1    
          buf = ""
        ENDIF    
        CLOSE #4 
        CLOSE #3  
        TUIwaitingOFF(dialog)
      
      CASE 1
        'HUFFMAN, slow but good
        LOCAL INTEGER i, ind, cnt = -1, fr, dif, change
        LOCAL INTEGER q(255), qq(255), nc, nn = 255, tind = -1
        LOCAL STRING bit(255), tree(255), bb
        LOCAL STRING dialog = TUIwaitingON("COMPRESS TO ARC")

        TUIwaitingProgress(dialog, 0)
        dif = 0
        OPEN source FOR INPUT AS #3
        DO WHILE NOT EOF(#3)
        ind = ASC(INPUT$(1, #3))
        fr = q(ind) >> 16
        INC fr
        INC dif
        q(ind) = (fr << 16) + ind
        TUIwaitingProgress(dialog, 40 * dif / srcLen)
        LOOP
        CLOSE #3 
        FOR i = 0 TO 255
        IF q(i) > 0 THEN
          INC cnt
          qq(cnt) = q(i)
        ENDIF
        NEXT i
        SORT qq(), , 1, , cnt+1
        dif = cnt

        nc = cnt
        DO WHILE nc > 0
        fr = (qq(nc) >> 16) + (qq(nc-1) >> 16)

        INC tind
        ind = qq(nc) AND &hFFFF
        IF ind < 256 THEN
          tree(tind) = CHR$(ind)
          bit(ind) = "0" + bit(ind)
        ELSE
          FOR i = 1 TO LEN(tree(ind - 256))
          bit(ASC(MID$(tree(ind - 256),i,1))) = "0" + bit(ASC(MID$(tree(ind - 256),i,1)))
          NEXT i
          tree(tind) = tree(ind - 256)
        ENDIF
        ind = qq(nc-1) AND &hFFFF
        IF ind < 256 THEN
          tree(tind) = tree(tind) + CHR$(ind)
          bit(ind) = "1" + bit(ind)
        ELSE
          FOR i = 1 TO LEN(tree(ind - 256))
          bit(ASC(MID$(tree(ind - 256),i,1))) = "1" + bit(ASC(MID$(tree(ind - 256),i,1)))
          NEXT i
          tree(tind) = tree(tind) + tree(ind - 256)
        ENDIF

        INC nc, -1
        INC nn
        qq(nc) = (fr << 16) + nn    
        SORT qq(), , 1, , nc+1
        LOOP
        TUIwaitingProgress(dialog, 45)


        LOCAL STRING tbl(cnt) LENGTH 32
        LOCAL INTEGER tblInd(cnt)
        ind = cnt
        FOR i=0 TO 255
        IF q(i) > 0 THEN
          tblInd(ind) = q(i) AND &hFFFF
          tbl(ind) = bit(tblInd(ind))
          INC ind, -1
        ENDIF
        NEXT i

        change = 1
        DO WHILE change
        change = 0
        FOR i = 1 TO cnt
          IF LEN(tbl(i)) < LEN(tbl(i - 1)) THEN
          NULL_S.NC = tbl(i)
          tbl(i) = tbl(i - 1)
          tbl(i - 1) = NULL_S.NC
          NULL_I.NC = tblInd(i)
          tblInd(i) = tblInd(i - 1)
          tblInd(i - 1) = NULL_I.NC
          change = 1
          ELSEIF LEN(tbl(i)) = LEN(tbl(i - 1)) THEN
          IF tbl(i) < tbl(i - 1) THEN
            NULL_S.NC = tbl(i)
            tbl(i) = tbl(i - 1)
            tbl(i - 1) = NULL_S.NC
            NULL_I.NC = tblInd(i)
            tblInd(i) = tblInd(i - 1)
            tblInd(i - 1) = NULL_I.NC
            change = 1
          ENDIF
          ENDIF
        NEXT i
        LOOP
        TUIwaitingProgress(dialog, 48)

        OPEN dest FOR OUTPUT AS #4
        header =  "HUF," + NCgetExtension(source) + "," + STR$(srcLen) '3 char archiver name, source extension, source size
        INC arcLen, LEN(header) + 2
        ?#4, header

        'write huffman table n, n*(ASC, number of bits)
        tbl(0) = STRING$(LEN(tbl(0)), "0")
        bit(tblInd(0)) = tbl(0)
        ?#4, CHR$(cnt+1)CHR$(tblInd(0))CHR$(LEN(tbl(0)));
        FOR i = 1 TO cnt
        ind = VAL("&b" + tbl(i - 1)) + 1
        bb = BIN$(ind, LEN(tbl(i - 1)))    
        tbl(i) = bb + STRING$(LEN(tbl(i)) - LEN(tbl(i - 1)), "0")
        bit(tblInd(i)) = tbl(i)
        ?#4, CHR$(tblInd(i))CHR$(LEN(tbl(i)));
        NEXT i

        TUIwaitingProgress(dialog, 50)  
        bb = ""
        cnt = 0
        OPEN source FOR INPUT AS #3
        DO WHILE NOT EOF(#3)
        ind = ASC(INPUT$(1, #3))
        INC cnt
        bb = bb + bit(ind)
        DO WHILE LEN(bb) > 7
          ?#4,CHR$(VAL("&b" + LEFT$(bb, 8)));
          bb = MID$(bb, 9)
        LOOP
        TUIwaitingProgress(dialog, 50 + 50 * cnt / srcLen)  
        LOOP
        IF bb <> "" THEN
        IF LEN(bb) < 8 THEN
          bb = bb + STRING$(8 - LEN(bb), "0")
        ENDIF
        DO WHILE LEN(bb) > 7
          ?#4,CHR$(VAL("&b" + bb));
          bb = MID$(bb, 9)
        LOOP
        ENDIF
        CLOSE #3 

        CLOSE #4
        TUIwaitingOFF(dialog)        huf(source, dest)

    END SELECT
    NCchangeDir(0,PATH.NC(0))
    NCchangeDir(1,PATH.NC(1))
    NCcursor(ACTIVE.NC,1)
  ENDIF
END SUB

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
          INT.NC = NCmkdir(NCsource2dest(source,dest,path + item))

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

FUNCTION NCmkdir(filePath AS STRING) AS INTEGER
  'mkedir 
  IF LEFT$(filePath, 3) = "S:/" THEN
    NCserialOut("M" + filePath, 1)
    STR.NC = ""
    DO WHILE STR.NC = ""
      STR.NC = NCreadUntilLF()
    LOOP
    IF STR.NC = "DONE" THEN
      NCmkdir = 0
    ELSEIF LEFT$(STR.NC,5) = "ERROR" THEN
      NCmkdir = 1
    ENDIF

  ELSE
    ON ERROR SKIP
    MKDIR filePath
    NCmkdir = MM.ERRNO
  ENDIF
END FUNCTION

SUB NCdirToServer(source AS STRING, dest AS STRING)
  'copy directory to server

  LOCAL INTEGER ind = 0, td=0, size
  LOCAL STRING item, path, hlp
  LOCAL STRING pth(MAX_ITEMS.NC)
  LOCAL STRING toDo(MAX_ITEMS.NC)
  CONST partLen = 250
  LOCAL STRING partData, dialog
  LOCAL INTEGER timeOut, partNum, partRem, fileLen, i
  
  dialog = TUIwaitingON("COPY DIR TO SERVER") 

  pth(ind) = source
  toDo(td) = pth(ind)
  DO WHILE ind >= 0
    NCchdir pth(ind)
    path = pth(ind)
    ind = ind - 1
    item = DIR$("", ALL)
    DO WHILE item <> ""
      IF LEFT$(item, 1) <> "." OR HIDDEN.NC THEN
        size = MM.INFO(FILESIZE item)
        IF size<0 THEN
          'directory
          ind = ind + 1
          pth(ind) = path + "/" + item                
          td = td + 1
          toDo(td) = path + "/" + item + "/"
 
        ELSE
          'file
          td = td + 1
          toDo(td) = path + "/" + item
        ENDIF
      ENDIF
      item = DIR$()
    LOOP
  LOOP

  SORT toDo(),,2,0,td+1 
  toDo(0) = toDo(0) + "/"
  path = NCparent(source)
  
  TUIwaitingOFF(dialog)
  FOR ind = 0 TO td
    'TUIwaitingProgress(dialog, 100 * ind / td)
    item = toDo(ind)
    IF RIGHT$(item, 1) = "/" THEN
      NULL_I.NC = NCmkdir(NCsource2dest(path, dest, item))
    ELSE
      hlp = NCsource2dest(path, dest, item)
      'NCoutDebug("NCdirToServer " + item + "," + hlp + ",1")
      NCfileToServer(item, hlp, 1)
      
'      fileLen = MM.INFO(FILESIZE item)
'      NCserialOut("W" + NCsource2dest(path, "", item) + "|" + STR$(fileLen), 1)
'      partData = ""
'      DO WHILE partData = ""
'        partData = NCreadUntilLF()
'      LOOP
'      IF partData = "READY" THEN
'        partNum = fileLen \ partLen
'        partRem = fileLen MOD partLen
'        OPEN item FOR INPUT AS #2

'        FOR i = 1 TO partNum
'          ?#1, INPUT$(partLen, #2);         
'        NEXT i 

'        IF partRem > 0 THEN
'          ?#1, INPUT$(partRem, #2);         
'        ENDIF

'        CLOSE #2

'        partData = ""
'        DO WHILE partData = ""
'          partData = NCreadUntilLF()
'        LOOP
        'IF partData = "DONE" THEN
        'ENDIF
      ENDIF
    ENDIF
  NEXT ind
  'TUIwaitingOFF(dialog)
  NCchangeDir(1,PATH.NC(1))
END SUB

SUB NCkey(kk AS INTEGER)
  'main SUB for key control
  LOCAL STRING ccc
  LOCAL INTEGER realPos
  
  SELECT CASE kk
    CASE 128  'up
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
    
    CASE 129  'down
      IF CURSOR.NC(ACTIVE.NC) < MAX_ROWS.NC THEN
        IF CURSOR.NC(ACTIVE.NC) + POS.NC(ACTIVE.NC) < COUNT.NC(ACTIVE.NC) THEN
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

    CASE ASC("a") TO ASC("z")
      NCfindFirstChar(CHR$(kk))

    CASE 27  'ESC
      NCesc

    CASE 9    'TAB
      NCcursor(ACTIVE.NC, 0)
      ACTIVE.NC = 1 - ACTIVE.NC
      NCheader(1 - ACTIVE.NC, ACT_PATH.NC)
      NCheader(ACTIVE.NC, NON_PATH.NC)
      NCcursor(ACTIVE.NC, 1)

    CASE 13   'ENTER
      NCenter

    CASE 145 TO 156 'F1-F12
      NCfKeys(kk)

    CASE 134  'HOME
      IF ALT.NC THEN
        NCsetCurPos(ACTIVE.NC, 0)
        NCredrawPane(ACTIVE.NC)
        NCcursor(ACTIVE.NC,1)
      ELSE
        IF CURSOR.NC(ACTIVE.NC) > 0 THEN
          NCcursor(ACTIVE.NC, 0)
          CURSOR.NC(ACTIVE.NC) = 0
          NCcursor(ACTIVE.NC, 1)
        ENDIF
      ENDIF
    
    CASE 135  'END
      IF ALT.NC THEN
        NCsetCurPos(ACTIVE.NC, COUNT.NC(ACTIVE.NC))
        NCredrawPane(ACTIVE.NC)
        NCcursor(ACTIVE.NC,1)
      ELSE
        IF CURSOR.NC(ACTIVE.NC) < MIN(MAX_ROWS.NC, COUNT.NC(ACTIVE.NC) - POS.NC(ACTIVE.NC)) THEN
          NCcursor(ACTIVE.NC, 0)
          CURSOR.NC(ACTIVE.NC) = MIN(MAX_ROWS.NC, COUNT.NC(ACTIVE.NC) - POS.NC(ACTIVE.NC))
          NCcursor(ACTIVE.NC, 1)
        ENDIF
      ENDIF

    CASE 136  'Page UP
      realPos = POS.NC(ACTIVE.NC) + CURSOR.NC(ACTIVE.NC)
      IF realPos - MAX_ROWS.NC > 0 THEN
        INC POS.NC(ACTIVE.NC), - MAX_ROWS.NC - 1
        DO WHILE POS.NC(ACTIVE.NC) < 0
          INC POS.NC(ACTIVE.NC), 1
          INC CURSOR.NC(ACTIVE.NC), -1
        LOOP
        NCredrawPane(ACTIVE.NC)
        NCcursor(ACTIVE.NC,1)
      ENDIF     
    
    CASE 137  'Page DOWN
      IF POS.NC(ACTIVE.NC) + MAX_ROWS.NC + CURSOR.NC(ACTIVE.NC) < COUNT.NC(ACTIVE.NC) THEN
        INC POS.NC(ACTIVE.NC), MAX_ROWS.NC + 1
        NCredrawPane(ACTIVE.NC)
        NCcursor(ACTIVE.NC,1)
      ENDIF
    
    CASE 6 'CTRL f
      NCsearch

    CASE 8 'CTRL h
      HIDDEN.NC = 1 - HIDDEN.NC
      NCdrawCL(ACT_PATH.NC)
      NCchangeDir(0, PATH.NC(0))
      NCchangeDir(1, PATH.NC(1))
      NCcursor(ACTIVE.NC, 1)

    CASE 21 'CTRL u
      UNSORT.NC = 1 - UNSORT.NC
      NCdrawCL(ACT_PATH.NC)
      NCchangeDir(0, PATH.NC(0))
      NCchangeDir(1, PATH.NC(1))
      NCcursor(ACTIVE.NC, 1)

  END SELECT
END SUB

SUB NCdirFromServer(source AS STRING, dest AS STRING)
  LOCAL INTEGER i, cnt
  LOCAL INTEGER strip = LEN(source) - LEN(NCgetName(source)) - 1
  LOCAL STRING dst, lineSerial

  NCserialOut("T" + source, 1)

  lineSerial = ""
  DO WHILE lineSerial = ""
    lineSerial = NCreadUntilLF()
  LOOP

  IF LEFT$(lineSerial, 1) = "T" THEN
    cnt = VAL(MID$(lineSerial,2))
    LOCAL STRING tree(cnt)
    FOR i = 1 TO cnt
      NCserialOut("NEXT")         
      lineSerial = ""
      DO WHILE lineSerial = ""
        lineSerial = NCreadUntilLF()
      LOOP
      tree(i) = lineSerial
    NEXT i
  ENDIF
  FOR i = 1 TO cnt
    lineSerial = FIELD$(tree(i), 1, "|")
    dst = dest + MID$(lineSerial, strip)
    IF LEFT$(tree(i), 1) = "D" THEN
      IF NCmkdir(dst) THEN
        TUIwarning("DIR COPY ERROR", "Can't create '" + dst + "'")
        EXIT FOR
      ENDIF
    ELSE
      NCfileFromServer("S:/" + MID$(lineSerial, 2), dst)
    ENDIF
  NEXT i
  NCchangeDir(1 - ACTIVE.NC, NON_PATH.NC)
END SUB

SUB NCfileFromServer(src AS STRING, dst AS STRING)
  'copy file from server to local

  CONST partLen = 250
  LOCAL STRING lineSerial, partData, dialog
  LOCAL INTEGER i, fileLen, partNum, partRem, bufLen
  LOCAL INTEGER BUFFER.NC(BUFFER_LEN.NC \ 8)

  NCserialOut("R" + src + "|" + STR$(partLen), 1)

  partData = ""
  DO WHILE partData = ""
    partData = NCreadUntilLF()
  LOOP
  IF FIELD$(partData, 1, "|") = "READY" THEN
    fileLen = VAL(FIELD$(partData, 2, "|"))
    partNum = fileLen \ partLen
    partRem = fileLen MOD partLen
    dialog = TUIwaitingON("COPY '" + NCgetName(src) + "' (SRV" + RIGHT.NC + "LOC, " + STR$(fileLen) + " bytes)")

    LONGSTRING CLEAR BUFFER.NC()
    bufLen = 0

    NCserialOut("START")         

    OPEN dst FOR OUTPUT AS #2

    FOR i = 1 TO partNum
      IF bufLen + partLen > BUFFER_LEN.NC THEN
        LONGSTRING PRINT #2, BUFFER.NC();
        LONGSTRING CLEAR BUFFER.NC()
        bufLen = 0
      ENDIF
      IF LOC(#1) > 0 THEN lineSerial = INPUT$(LOC(#1), #1)
      NCserialOut("NEXT")         
      TUIwaitingProgress(dialog, 100 * i / partNum)
      DO WHILE LOC(#1) < partLen: LOOP
      LONGSTRING APPEND BUFFER.NC(), INPUT$(partLen, #1)
      INC bufLen, partLen
    NEXT i
    IF bufLen > 0 THEN
      LONGSTRING PRINT #2, BUFFER.NC();
      LONGSTRING CLEAR BUFFER.NC()
      bufLen = 0
    ENDIF
    IF partRem > 0 THEN
      IF LOC(#1) > 0 THEN lineSerial = INPUT$(LOC(#1), #1)
      NCserialOut("NEXT")         
      DO WHILE LOC(#1) < partRem: LOOP
      ?#2, INPUT$(partRem, #1);
    ENDIF

    CLOSE #2
    NCserialOut("DONE")         
    TUIwaitingOFF(dialog)
  ENDIF
END SUB

FUNCTION NCserverDirInfo(filePath AS STRING) AS INTEGER
  LOCAL INTEGER bytes = 0, items = 0, i
  LOCAL STRING dst, lineSerial

  NCserialOut("T" + filePath, 1)

  lineSerial = ""
  DO WHILE lineSerial = ""
    lineSerial = NCreadUntilLF()
  LOOP
  IF LEFT$(lineSerial, 1) = "T" THEN
    items = VAL(MID$(lineSerial,2))
    FOR i = 0 TO items - 1
      NCserialOut("NEXT")         
      lineSerial = ""
      DO WHILE lineSerial = ""
        lineSerial = NCreadUntilLF()
      LOOP
      IF LEFT$(lineSerial, 1) = "F" THEN
        INC bytes, VAL(FIELD$(lineSerial, 2, "|"))
      ENDIF
    NEXT i
  ENDIF
  NCserverDirInfo = (bytes << 16) + items  
END FUNCTION

SUB NCviewC64(filePath AS STRING)
  'simple C64 image format viewer
  'HBM, HED, DD, KOA, missing DD, GG
  
  LOCAL STRING info = GRF.getC64info(ACT_PATH.NC + SEL_NAME.NC), k = ""
  IF info <> "" THEN
    LOCAL INTEGER w = VAL(FIELD$(info, 1, ","))
    LOCAL INTEGER h = VAL(FIELD$(info, 2, ","))
    LOCAL INTEGER bpp = VAL(FIELD$(info, 3, ","))
    
    IF GRF.loadC64(filePath, 0, 0, 1, 1) THEN
      LOCAL STRING dialog = TUIemptyON(filePath + ", " + STR$(w) + "x" + STR$(h)+ ", " + STR$(bpp)+"bpp", w, h, " S = Save to BMP ")
      LOCAL INTEGER yy = VAL(FIELD$(dialog, 4, ",")) + 4    
      BLIT 0, 0, (MM.HRES - w) \ 2, yy, w, h, 1
      TUIwaitForNoKey
      DO WHILE k = ""
        k = INKEY$
      LOOP        
      TUIwaitForNoKey
      TUIemptyOFF(dialog)
      IF UCASE$(k) = "S" THEN
        GRF.saveBMP(NCgetNoExtension(filePath) + ".BMP", 0, 0, w, h, 1)
        NCchangeDir(ACTIVE.NC, ACT_PATH.NC)
        NCcursor(ACTIVE.NC, 1)
      ENDIF
    ELSE
      TUIwarning("C64 IMAGE VIEWER", "Loading error")
    ENDIF
  ELSE
    TUIwarning("C64 IMAGE VIEWER", "Image can't be decoded")
  ENDIF
END SUB

SUB NCviewSPR(filePath AS STRING)
  'simple sprite viewer
  
  LOCAL STRING info = GRF.getSPRinfo(ACT_PATH.NC + SEL_NAME.NC)
  IF info <> "" THEN
    LOCAL INTEGER w = VAL(FIELD$(info, 1, ","))
    LOCAL INTEGER h = VAL(FIELD$(info, 2, ","))
    

    PAGE WRITE 1
    CLS BC.TUI
    PAGE WRITE 0
    IF GRF.loadSPR(filePath, 0, 0, 1, 1) THEN   
      LOCAL STRING dialog = TUIemptyON(filePath + ", " + STR$(w) + "x" + STR$(h), w, h)
      LOCAL INTEGER yy = VAL(FIELD$(dialog, 4, ",")) + 4    
      BLIT 0, 0, (MM.HRES - w) \ 2, yy, w, h, 1
      TUIwaitForNoKey
      TUIwaitForKey
      TUIwaitForNoKey
      TUIemptyOFF(dialog)
    ENDIF
  ENDIF
END SUB

SUB NCsearch
  'search for FILE or DIR

  LOCAL STRING find = TUIinput("SEARCH FOR FILE/DIR", "Search what", "", FILECHARS.NC + "*?")
  LOCAL INTEGER firstFlag = 1
  LOCAL STRING firstItem = "", firstPath = ""

  IF find <> "" THEN
    LOCAL STRING dialog = TUIwaitingON("SEARCHING FOR '" + find + "'")
    ON ERROR SKIP
    OPEN NC_PATH.NC + FOUND.NC FOR OUTPUT AS #3
    IF MM.ERRNO = 0 THEN
      ?#3,"SEARCH for '" + find + "'"
      ?#3
      ?#3,"Found:"

      IF NCisSerial(ACTIVE.NC) THEN
      ELSE
        LOCAL INTEGER ind = 0, size, i
        LOCAL STRING item, path
        LOCAL STRING pth(MAX_ITEMS.NC)

        pth(ind) = LEFT$(ACT_PATH.NC, LEN(ACT_PATH.NC) - 1)
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
              IF NCequal(find, item) THEN
                ? #3, pth(ind) + "/"
                IF firstFlag THEN
                  firstFlag = 0
                  firstItem = item + "/"
                  firstPath = path
                ENDIF
              ENDIF
            ELSE
              IF NCequal(find, item) THEN
                ? #3, path + "/" + item
                IF firstFlag THEN
                  firstFlag = 0
                  firstItem = item
                  firstPath = path
                ENDIF
              ENDIF
            ENDIF
            item = DIR$()
          LOOP
        LOOP
      ENDIF
      CLOSE #3
      TUIwaitingOFF(dialog)
      NCviewTXT(NC_PATH.NC + FOUND.NC)
      IF NOT firstFlag THEN
        NCchangeDir(ACTIVE.NC, firstPath + "/")
        IF RIGHT$(firstItem, 1) = "/" THEN firstItem = LEFT$(firstItem, LEN(firstItem) - 1)
        FOR i = 0 TO COUNT.NC(ACTIVE.NC)
          IF LCASE$(MID$(FIELD$(ITEM.NC(ACTIVE.NC, i), 1, "|"), 2)) = LCASE$(firstItem) THEN
            NCsetCurPos(ACTIVE.NC, i)
            EXIT FOR
          ENDIF
        NEXT i
        NCcursor(ACTIVE.NC, 1)
      ENDIF
    ENDIF
  ENDIF
END SUB

FUNCTION NCequal(wild AS STRING, name AS STRING) AS INTEGER
  LOCAL STRING pat = UCASE$(wild), stri = UCASE$(name)
  LOCAL STRING locp = "", locs = ""
  LOCAL INTEGER two = INSTR(pat, "**")
  
  DO WHILE two > 0
    pat = LEFT$(pat, two) + MID$(pat, two + 2)
    two = INSTR(pat, "**")
  LOOP
  DO WHILE pat <> ""
    IF pat = stri THEN
      NCequal = 1
      EXIT FUNCTION
    ENDIF
    IF LEFT$(pat, 1) <> LEFT$(stri, 1) AND LEFT$(pat, 1) <> "?" AND LEFT$(pat, 1) <> "*" THEN
      NCequal = 0
      EXIT FUNCTION
    ENDIF
    IF LEFT$(pat, 1) = "*" THEN
      pat = MID$(pat, 2)
      IF pat = "" THEN
        NCequal = 1
        EXIT FUNCTION
      ENDIF
      two = INSTR(stri, LEFT$(pat, 1))
      IF two = 0 THEN
        NCequal = 0
        EXIT FUNCTION
      ENDIF
      stri = MID$(stri, two + 1)
      IF INSTR(stri, LEFT$(pat, 1)) = 0 THEN
        pat = MID$(pat, 2)
      ELSE
        pat = "*" + pat
      ENDIF
    ELSE
      IF LEFT$(pat, 1) = LEFT$(stri, 1) OR LEFT$(pat, 1) = "?" THEN
        pat = MID$(pat, 2)
        stri = MID$(stri, 2)
      ELSE
        NCequal = 0
        EXIT FUNCTION
      ENDIF
    ENDIF
  LOOP
  NCequal = (pat = stri)
END FUNCTION

SUB NCviewST(filePath AS STRING)
  'simple Atari ST image format viewer
  'PI1, PI2, PI3, PC1, PC2, PC3
  
  LOCAL STRING info = GRF.getSTinfo(ACT_PATH.NC + SEL_NAME.NC), k = ""
  IF info <> "" THEN
    LOCAL INTEGER w = VAL(FIELD$(info, 1, ","))
    LOCAL INTEGER h = VAL(FIELD$(info, 2, ","))
    LOCAL INTEGER bpp = VAL(FIELD$(info, 3, ","))
    
    IF GRF.loadST(filePath, 0, 0, 1, 1) THEN
      LOCAL STRING dialog = TUIemptyON(filePath + ", " + STR$(w) + "x" + STR$(h)+ ", " + STR$(bpp)+"bpp", w, h, " S = Save to BMP ")
      LOCAL INTEGER yy = VAL(FIELD$(dialog, 4, ",")) + 4    
      BLIT 0, 0, (MM.HRES - w) \ 2, yy, w, h, 1
      TUIwaitForNoKey
      DO WHILE k = ""
        k = INKEY$
      LOOP        
      TUIwaitForNoKey
      TUIemptyOFF(dialog)
      IF UCASE$(k) = "S" THEN
        GRF.saveBMP(NCgetNoExtension(filePath) + ".BMP", 0, 0, w, h, 1)
        NCchangeDir(ACTIVE.NC, ACT_PATH.NC)
        NCcursor(ACTIVE.NC, 1)
      ENDIF
    ELSE
      TUIwarning("Atari ST IMAGE VIEWER", "Loading error")
    ENDIF
  ELSE
    TUIwarning("Atari ST IMAGE VIEWER", "Image can't be decoded")
  ENDIF
END SUB

SUB NCviewZX(filePath AS STRING)
  'simple ZX Spectrum image format viewer
  'SCR, BSC
  
  LOCAL STRING info = GRF.getZXinfo(ACT_PATH.NC + SEL_NAME.NC), k = ""
  IF info <> "" THEN
    LOCAL INTEGER w = VAL(FIELD$(info, 1, ","))
    LOCAL INTEGER h = VAL(FIELD$(info, 2, ","))
    LOCAL INTEGER bpp = VAL(FIELD$(info, 3, ","))
    

    IF GRF.loadZX(filePath, 0, 0, 1, 1) THEN
      LOCAL STRING dialog = TUIemptyON(filePath + ", " + STR$(w) + "x" + STR$(h)+ ", " + STR$(bpp)+"bpp", w, h, " S = Save to BMP ")
      LOCAL INTEGER yy = VAL(FIELD$(dialog, 4, ",")) + 4    
      BLIT 0, 0, (MM.HRES - w) \ 2, yy, w, h, 1
      TUIwaitForNoKey
      DO WHILE k = ""
         k = INKEY$
      LOOP        
      TUIwaitForNoKey
      TUIemptyOFF(dialog)
      IF UCASE$(k) = "S" THEN
        GRF.saveBMP(NCgetNoExtension(filePath) + ".BMP", 0, 0, w, h, 1)
        NCchangeDir(ACTIVE.NC, ACT_PATH.NC)
        NCcursor(ACTIVE.NC, 1)
      ENDIF
    ELSE
      TUIwarning("ZX Spectrum IMAGE VIEWER", "Loading error")
    ENDIF
  ELSE
    TUIwarning("ZX Spectrum IMAGE VIEWER", "Image can't be decoded")
  ENDIF
END SUB

SUB NCeditHEX(filePath AS STRING)
  'simple hex editor

  CLOCK.NC = 2
  LOCAL INTEGER firstRow = 16+4, row = 0, cnt = 0, change = 0, b, po = 0, i, ln, cx, cy, edNum
  LOCAL INTEGER cursX = 0, cursY = 0, cursLN(EDIT_ROWS.NC), maxRow, curPos, digit = 0, digPos = 0
  LOCAL INTEGER fCol = RGB(NOTBLACK), bCol = RGB(CYAN), wCol = RGB(WHITE), nCol = RGB(BLUE), rCol = RGB(RED)
  LOCAL STRING li,k

  NCviewBackground(filePath)
  TEXT 0,600-16,"PG/CRSR/0-F/ALT+char/ENTER/ESC ","LT",8,,RGB(WHITE),RGB(NOTBLACK)
  OPEN filePath FOR RANDOM AS #3
  LOCAL INTEGER si = LOF(#3)
  DO 
    SEEK #3, po + 1
    change = 0
    cnt = 0 
    row = 0
  
    curPos = po + cursX + 16*cursY
    TEXT 400, 600-16, " Position " + HEX$(curPos, 8) + " of " + HEX$(si-1,8) + " ", "CT", 8,, wCol, fCol

    PAGE WRITE 1
    BOX 0, 16, 800, 600-32,0 ,, bCol
    DO WHILE cnt < 16*EDIT_ROWS.NC AND NOT EOF(#3)
      li = INPUT$(16, #3)
    
      IF (row >> 4) = cursY THEN
        TEXT 8, firstRow + row, LEFT$(HEX$(po + cnt, 8), 4), "LT", 8,, bCol, fCol
        TEXT 44, firstRow + row, RIGHT$(HEX$(po + cnt, 8), 4), "LT", 8,, bCol, fCol

      ELSE
        TEXT 8, firstRow + row, LEFT$(HEX$(po + cnt, 8), 4), "LT", 8,, nCol, bCol
        TEXT 44, firstRow + row, RIGHT$(HEX$(po + cnt, 8), 4), "LT", 8,, nCol, bCol
      ENDIF


      ln = MIN(LEN(li) - 1, 15)
      cursLN(row >> 4) = ln
      FOR i = 0 TO ln
        b = ASC(MID$(li, i + 1, 1))
        IF (row >> 4) = cursY AND i = cursX THEN
          TEXT 112 + i*32, firstRow + row, HEX$(b,2), "LT", 8,, bCol, nCol
          IF b >= 32 AND b <= 127 THEN
            TEXT 640 + i*8, firstRow + row, CHR$(b),"LT", 8,, bCol, nCol
          ELSE
            TEXT 640 + i*8, firstRow + row, ".","LT", 8,, bCol, nCol
          ENDIF

        ELSE
          TEXT 112 + i*32, firstRow + row, HEX$(b,2), "LT", 8,, fCol, bCol
          IF b >= 32 AND b <= 127 THEN
            TEXT 640 + i*8, firstRow + row, CHR$(b),"LT", 8,, fCol, bCol
          ELSE
            TEXT 640 + i*8, firstRow + row, ".","LT", 8,, fCol, bCol
          ENDIF
        ENDIF
      NEXT i          
      maxRow = row >> 4
      row = row + 16
      cnt = cnt + 16
    LOOP
    
    PAGE WRITE 0
    BLIT 0,16,0,16,800,600-32,1
    
    IF cursY > maxRow THEN
      cursY = maxRow
      cursX = MIN(cursLN(cursY), cursX)
      change = 1
    ENDIF
    IF cursX > cursLN(cursY) THEN
      cursX = MIN(cursLN(cursY), cursX)
      change = 1
    ENDIF

    IF NOT change THEN
      SEEK #3, curPos + 1
      edNum = VAL(INPUT$(1, #3))
    ENDIF
    DO WHILE change = 0 AND k<>ESC.NC
      DO: k = INKEY$: LOOP WHILE k=""
      KEYMOD.NC = KEYDOWN(7)
      ALT.NC = (KEYMOD.NC AND 1) > 0 OR (KEYMOD.NC AND 16) > 0
      SELECT CASE ASC(k)
        CASE 136
          'Page UP
          IF po > 0 THEN 
            po = MAX(po - 16*EDIT_ROWS.NC, 0)
            change = 1
          ENDIF

        CASE 137
          'Page DOWN
          IF (po + 16*EDIT_ROWS.NC) <= si  THEN 
            po = po + 16*EDIT_ROWS.NC
            digPos = 0
            change = 1
          ENDIF

        CASE 130
          'LEFT
          IF cursX > 0  THEN 
            INC cursX, -1
            digPos = 0
            change = 1
          ENDIF

        CASE 131
          'RIGHT
          IF cursX < cursLN(cursY)  THEN 
            INC cursX, 1
            digPos = 0
            change = 1
          ENDIF

        CASE 128
          'UP
          IF cursY > 0  THEN
            INC cursY, -1
            digPos = 0
            change = 1
          ELSE
            IF po > 0 THEN 
              po = MAX(po - 16*EDIT_ROWS.NC, 0)
              cursY = EDIT_ROWS.NC
              digPos = 0
              change = 1
            ENDIF
          ENDIF

        CASE 129
          'DOWN
          IF cursY < maxRow  THEN 
            INC cursY, 1
            cursX = MIN(cursLN(cursY), cursX)
            digPos = 0
            change = 1
          ELSE
            IF (po + 16*EDIT_ROWS.NC) <= si  THEN 
              po = po + 16*EDIT_ROWS.NC
              digPos = 0
              cursY = 0        
              change = 1
            ENDIF
          ENDIF

        CASE 32 TO 126      
          'change value
          IF ALT.NC THEN
            edNum = ASC(k)
            TEXT 112 + cursX*32, firstRow + (cursY << 4), HEX$(edNum,2), "LT", 8,, rCol, nCol
            IF edNum >= 32 AND edNum <= 127 THEN
              TEXT 640 + cursX*8, firstRow + (cursY << 4), CHR$(edNum),"LT", 8,, rCol, nCol
            ELSE
              TEXT 640 + cursX*8, firstRow + (cursY << 4), ".","LT", 8,, rCol, nCol
            ENDIF
            digPos = 0
          ELSE
            digit = ASC(UCASE$(k)) - 48
            IF digit > 9 THEN INC digit, -7
            IF digit >= 0 AND digit <= 15 THEN
              IF digPos THEN
                edNum = (edNum AND &hF0) OR digit
              ELSE
                edNum = (edNum AND &hF) OR (digit << 4)
              ENDIF
              digPos = 1 - digPos
              TEXT 112 + cursX*32, firstRow + (cursY << 4), HEX$(edNum,2), "LT", 8,, rCol, nCol
              IF edNum >= 32 AND edNum <= 127 THEN
                TEXT 640 + cursX*8, firstRow + (cursY << 4), CHR$(edNum),"LT", 8,, rCol, nCol
              ELSE
                TEXT 640 + cursX*8, firstRow + (cursY << 4), ".","LT", 8,, rCol, nCol
              ENDIF
            ENDIF
          ENDIF

        CASE 13
          'ENTER
          SEEK #3, curPos + 1
          ?#3, CHR$(edNum);
          digPos = 0
          change = 1

      END SELECT
    LOOP
  LOOP WHILE k<>ESC.NC
  CLOSE #3
  NCredrawPane(0)
  NCredrawPane(1)  
  NCcursor(ACTIVE.NC,1)
  NCdrawMenu
END SUB

