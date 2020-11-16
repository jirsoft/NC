'Here can be put external actionss for any extensions. Name of SUB for the viewer must be:
'EXTactionXXX, where the XXX is extension for that viewer is working
'
'Action can use just local variables, cannot change MODE and need to set EXT_ERR.NC to:
'0 = no error, or >0 in case of error (<0 is signaling to the NC, that viewer is not available)
'
'From NC can be used UI SUBs and FUNCTIONs, mainly:
'NCwaitingON(description) for longer action, on end then NCwaitingOFF
'NCwarning(title, text) for information to the user

'EXAMPLE
SUB EXTactionBIN(filePath AS STRING)
  NCwarning("BIN action", "Example of actionr for BIN files'")
  EXT_ERR.NC = -1 'fallback to internal action, normally will be here EXT_ERR.NC = 0
END SUB

SUB EXTactionMAR(filePath AS STRING)
  CONST maxChunkSize = 128
  LOCAL INTEGER fiLen, curLen = 0, chunkLen
  LOCAL STRING li, cmd, par, k, p = PATH.NC(1-ACTIVE.NC)
  EXT_ERR.NC = 0

  IF NCquestion("EXTRACT MAR", "Extract '" +filePath + "' to '" + p + "'?") THEN
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
          p = p + par + "/"
          ON ERROR SKIP
          MKDIR p
          IF MM.ERRNO > 0 THEN 
            CLOSE #3
            EXT_ERR.NC=1
            NCerror("DIR '" + p + "' ERROR")
            EXIT SUB
          ENDIF
          'NCwarning("MAKE DIR", p)
    
        CASE "FILE"
          NCwaitingON("CREATE FILE "+par)
          curLen = 0
          LINE INPUT #3, li
          fiLen = VAL(li)
          'NCwarning("CREATE FILE", p + par)
          OPEN p+par FOR OUTPUT AS #4
          DO WHILE curLen < fiLen        
            chunkLen = MIN(fiLen - curLen,maxChunkSize)
            curLen = curLen + chunkLen
            li = INPUT$(chunkLen, #3)
            PRINT #4,li;
          LOOP
          CLOSE #4
          NCwaitingOFF

        CASE "ENDDIR"
          p = NCparrent(p)
          'NCwarning("END DIR", p)

                
        CASE "ENDARCHIVE"
          'NCwarning("END ARCHIVE","")
              
      END SELECT

    LOOP

    CLOSE #3
  ENDIF
  NCchangeDir(1-ACTIVE.NC,PATH.NC(1-ACTIVE.NC))
  NCcursor(ACTIVE.NC,1)
END SUB

