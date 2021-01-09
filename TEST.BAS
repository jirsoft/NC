#MMDEBUG ON

OPTION BASE 0
OPTION EXPLICIT
OPTION DEFAULT NONE

OPTION CRLF LF

CHDIR MM.INFO$(PATH)

CONST CR.ESP = CHR$(13)
CONST LF.ESP = CHR$(10)
CONST CRLF.ESP = CR.ESP + LF.ESP
CONST SERIAL_TIMEOUT.ESP = 300
DIM INTEGER PORT.ESP = -1, CONNECTED.ESP = 0

DIM INTEGER waiting, i
DIM STRING s, k, ret

CONST MAXLEN.ESP = 1000000
DIM INTEGER BUF.ESP(MAXLEN.ESP \ 8)

ESPinit(9)
ESPsend("@connect(****,****)")
DO
  ret = ESPreadUntilLF()
  IF ret <> "" THEN
    ? ">"ret
  ENDIF
  k = INKEY$
  DO WHILE k <> "" OR s <> ""
    IF k = LF.ESP THEN
      IF s <> "" THEN
        SELECT CASE LCASE$(s)
          CASE "@connect"
            ?
            ESPsend(s + "(JirNET,jirickovOSit)", LF.ESP)

          CASE "@speedtest"
            ?
            ESPsend(s, LF.ESP)
            ret = ESPreadUntilLF()
            ESPspeedTest(ret)

          CASE ELSE
            ?
            ESPsend(s, LF.ESP)
        END SELECT
        s = ""
      ENDIF
      k = ""
    ELSE
      IF LEN(s) < 255 THEN 
        CAT s, k
        ?k;
      ENDIF
    ENDIF
    k = INKEY$
  LOOP
LOOP

CLOSE PORT.ESP
END

SUB ESPspeedTest(s AS STRING)
  LOCAL INTEGER dataLen = VAL(FIELD$(s, 1, ","))
  LOCAL INTEGER partLen = VAL(FIELD$(s, 2, ","))
  LOCAL INTEGER partNum = dataLen \ partLen
  LOCAL INTEGER partRem = dataLen MOD partLen, i, tim = TIMER, l = 0, j, crc = 0, ll
  LOCAL STRING null

  CONST testFile = "OUT.TMP"

  LONGSTRING CLEAR BUF.ESP()
  ? "ESP -> CMM2 speed test ... ";
  FOR i = 1 TO partNum
    DO WHILE LOC(PORT.ESP) < partLen: LOOP
    null = INPUT$(partLen, #PORT.ESP)
    'FOR j = 1 TO LEN(null)
    '  crc = (crc + ASC(MID$(null, j, 1))) AND &hFF
    'NEXT j
    LONGSTRING APPEND BUF.ESP(), null
    INC l, partLen
    ESPsend("OK", LF.ESP)
  NEXT i
  
  IF partRem > 0 THEN
    DO WHILE LOC(PORT.ESP) < partRem: LOOP
    null = INPUT$(partRem, #PORT.ESP)
    'FOR i = 1 TO LEN(null)
    '  crc = (crc + ASC(MID$(null, i, 1))) AND &hFF
    'NEXT i
    LONGSTRING APPEND BUF.ESP(), null
    INC l, partRem
    ESPsend("OK", LF.ESP)
  ENDIF
  tim = TIMER - tim

  OPEN testFile FOR OUTPUT AS #1
  LONGSTRING PRINT #1, BUF.ESP();
  CLOSE #1
  ? STR$(l)" bytes read, speed = "STR$(1000 * dataLen / 1024 / tim, 0, 2)"kB/s"
  ', CRC = " + STR$(crc)

  LONGSTRING CLEAR BUF.ESP()
  l = MM.INFO(FILESIZE testFile)
  ll = l
  OPEN testFile FOR INPUT AS #1
    DO WHILE l > 0
      LONGSTRING APPEND BUF.ESP(), INPUT$(MIN(l, 255), #1)
      INC l, -MIN(l, 255)
    LOOP
  CLOSE #1  
  ? "CMM2 -> ESP speed test ... ";
  tim = TIMER  
  ESPsend(STR$(ll), LF.ESP)
  LONGSTRING PRINT #PORT.ESP, BUF.ESP();
  tim = TIMER - tim
  ? STR$(ll)" bytes written, speed = "STR$(1000 * ll / 1024 / tim, 0, 2)"kB/s"
  ', CRC = " + STR$(crc)  
END SUB

FUNCTION ESPreadUntilLF() AS STRING
  LOCAL STRING one = "", serIn = ""
  LOCAL INTEGER timeout = TIMER
  
  ESPreadUntilLF = ""
  
  DO WHILE (one <> LF.ESP) AND ((TIMER - timeout) < SERIAL_TIMEOUT.ESP)
    IF LOC(#PORT.ESP) > 0 THEN
      one = INPUT$(1, #PORT.ESP)
      IF one = LF.ESP THEN
        ESPreadUntilLF = serIn
        serIn = ""
      ELSE
        IF LEN(serIn) < 250 THEN
          CAT serIn, one
        ELSE
          serIn = one
        ENDIF
      ENDIF
      timeout = TIMER
    ENDIF
  LOOP
END FUNCTION

SUB ESPerror(e AS STRING)
  ?"ERROR: " + e
END SUB

SUB ESPinit(p AS INTEGER)
  PORT.ESP = p
  'OPEN "COM1:115200,256" AS PORT.ESP
  OPEN "COM1:921600,256" AS PORT.ESP
  CONNECTED.ESP = 1
END SUB

SUB ESPsend(c AS STRING, ad AS STRING)
  IF CONNECTED.ESP THEN
    DO WHILE LOF(#PORT.ESP) < (LEN(c) + LEN(ad)): LOOP
    ?#PORT.ESP, c + ad;

  ELSE
    ESPerror("ESP port not open")
  ENDIF
END SUB
