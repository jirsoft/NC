'Here can be put external viewers for any extensions. Name of SUB for the viewer must be:
'EXTviewXXX, where the XXX is extension for that viewer is working
'
'Viewer can use just local variables, cannot change MODE and need to set EXT_ERR.NC to:
'0 = no error, or >0 in case of error (<0 is signaling to the NC, that viewer is not available)
'
'From NC can be used UI SUBs and FUNCTIONs, mainly:
'NCwaitingON(description) for longer action, on end then NCwaitingOFF
'NCwarning(title, text) for information to the user

'EXAMPLE
SUB EXTviewBIN(filePath AS STRING)
  TUIwarning("BIN VIEW", "Example of viewer for BIN files'")
  EXT_ERR.NC = -1 'fallback to internal viewer, normally will be here EXT_ERR.NC = 0
END SUB

SUB EXTviewMAR(filePath AS STRING)
  CONST maxChunkSize = 128
  LOCAL INTEGER firstRow = 16+4, row = 0, fiLen, curLen = 0, chunkLen
  LOCAL STRING li, cmd, par, k
  LOCAL INTEGER indent = 0, pg = 1
  LOCAL STRING dialog
  
  EXT_ERR.NC = 0

  CLS
  BOX 0,16,800,600-32,0,,RGB(CYAN)
  LINE 0,7,800,7,2,RGB(WHITE)
  LINE 0,600-8,800,600-8,2,RGB(WHITE)
  TEXT 400,0," " + filePath + " ","CT",8,,RGB(WHITE),RGB(BLACK)
  BOX 0,16,800,600-32,0,,RGB(CYAN)
  TEXT 400,600-16," Page " + STR$(pg) + " ","CT",8,,RGB(WHITE),RGB(BLACK)
  TEXT 0,600-16,"PgDOWN/ESC ","LT",8,,RGB(WHITE),RGB(BLACK)


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
        TEXT 0,firstRow + row, SPACE$(2*indent) + "DIR "+par,"LT",8,,RGB(BLACK), RGB(CYAN)
        indent = indent + 2
        row = row + 16 
    
      CASE "FILE"
        dialog = TUIwaitingON("READ FILE")
        curLen = 0
        LINE INPUT #3, li
        fiLen = VAL(li)
        TEXT 0,firstRow + row, SPACE$(2*indent) + "FILE " + par + " (" + STR$(fiLen) + " bytes)","LT",8,,RGB(BLACK), RGB(CYAN)
        row = row + 16 
        DO WHILE curLen < fiLen        
          chunkLen = MIN(fiLen - curLen,maxChunkSize)
          curLen = curLen + chunkLen
          li = INPUT$(chunkLen, #3)
        LOOP
        TUIwaitingOFF(dialog)

      CASE "ENDDIR"
        indent = indent - 2
        TEXT 0,firstRow + row, SPACE$(2*indent) + "END DIR","LT",8,,RGB(BLACK), RGB(CYAN)
        row = row + 16 
        
      CASE "ENDARCHIVE"
        TEXT 0,firstRow + row, SPACE$(2*indent) + "END ARCHIVE","LT",8,,RGB(BLACK), RGB(CYAN)
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
        TEXT 400,600-16," Page " + STR$(pg) + " ","CT",8,,RGB(WHITE),RGB(BLACK)
      ENDIF
    ENDIF
  LOOP
  TEXT 400,600-16," Page " + STR$(pg) + " ","CT",8,,RGB(WHITE),RGB(BLACK)

  CLOSE #3
  DO WHILE k<>CHR$(27)
    k = INKEY$
  LOOP
END SUB

