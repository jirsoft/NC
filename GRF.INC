'Graphic library
CONST VERSION.GRF = "0.06"

'FUNCTION GRF.info(pg AS INTEGER) AS STRING
  'return MODE, BPP, y-lines, pg address, write address

'SUB GRF.saveBMP(filePath AS STRING, xx AS INTEGER, yy AS INTEGER, ww AS INTEGER, hh AS INTEGER, pp AS INTEGER)
  'save BMP file from screen memory on xx,yy with size of ww,hh from page pp
  'it takes bpp from current MODE (so either 8 or 16) = makes BMP smaller than MMBASICs 24bpp

'FUNCTION GRF.getImgInfo(filePath AS STRING) AS STRING
  'return info about graphic file
  'WIDTH, HEIGHT, BPP, VERSION

'FUNCTION GRF.loadImg(filePath AS STRING, xx AS INTEGER, yy AS INTEGER, pg AS INTEGER) AS INTEGER
  'load image to x, y, page
  'returns 0 when NOK

'FUNCTION GRF.getC64info(filePath AS STRING) AS STRING
  'get info for some C64 formats

'FUNCTION GRF.loadC64(filePath AS STRING, x AS INTEGER, y AS INTEGER, pg AS INTEGER) AS INTEGER
  'load some C64 formats to x, y, page
  'returns 0 when NOK

'FUNCTION GRF.getZXinfo(filePath AS STRING) AS STRING
  'get info for some ZX formats

'FUNCTION GRF.getCMMcolor(n AS INTEGER) AS INTEGER
  'get color from standard CMM (for sprites)

'FUNCTION GRF.loadZX(filePath AS STRING, x AS INTEGER, y AS INTEGER, pg AS INTEGER) AS INTEGER
  'load some ZX Spectrum formats to x, y, page
  'returns 0 when NOK


FUNCTION GRF.info(pg AS INTEGER) AS STRING
  'return MODE, BPP, y-lines, pg address, write address

  LOCAL FLOAT m = MM.INFO(MODE)
  LOCAL INTEGER pgAdr = -1, dup = 1

  IF pg <= MM.INFO(MAX PAGES) THEN
    pgAdr = MM.INFO(PAGE ADDRESS pg)
  ENDIF

  GRF.info = LEFT$(STR$(m), 1) + "," + MID$(STR$(m), 3) 

  SELECT CASE m
    CASE 1.12,3.8,3.12,3.16,5 TO 7.99, 12 TO 13.99
      if pg = 0 THEN dup = 2

  END SELECT
    
  CAT GRF.info, "," + STR$(dup)
  CAT GRF.info, "," + STR$(pgAdr)
  CAT GRF.info, "," + STR$(MM.INFO(WRITE PAGE))
END FUNCTION

SUB GRF.saveBMP(filePath AS STRING, xx AS INTEGER, yy AS INTEGER, ww AS INTEGER, hh AS INTEGER, pp AS INTEGER)
  'save BMP file from screen memory on xx,yy with size of ww,hh from page pp
  'it takes bpp from current MODE (so either 8 or 16) = makes BMP smaller than MMBASICs 24bpp

  LOCAL INTEGER x, y, c, bpp = 0, offset = 54
  LOCAL STRING dialog = TUIwaitingON("SAVING '" + filePath + "'")
  LOCAL INTEGER tim = TIMER, compr = 0
  LOCAL STRING inf = GRF.info(pp)
  
  LOCAL INTEGER addr = VAL(FIELD$(inf, 4, ","))
  IF addr < 0 THEN EXIT SUB

  LOCAL INTEGER dup = VAL(FIELD$(inf, 3, ","))
  
  bpp = VAL(FIELD$(inf, 2, ","))
  IF ww = 0 THEN ww = MM.HRES
  IF hh = 0 THEN hh = MM.VRES

  IF bpp = 8 THEN
    INC offset, 256 * 4

  ELSEIF bpp = 16 THEN
    compr = 3 'add setting to RGB565
    INC offset, 12

  ENDIF

  LOCAL INTEGER scanLineSize = ww * bpp / 8, padding = 0
  IF scanLineSize MOD 4 > 0 THEN 
    padding = 4 - (scanLineSize MOD 4)
    INC scanLineSize, padding
  ENDIF

  LOCAL INTEGER bmpSize = 54 + hh * scanLineSize + 4 * compr
  IF bpp = 8 THEN INC bmpSize, 4 * 256 'add palette

  OPEN filePath FOR OUTPUT AS #5
  'HEADER
  ?#5, "BM";                       'signature
  ?#5, BIN2STR$(UINT32, bmpSize);  'file size in bytes
  ?#5, BIN2STR$(UINT32, 0);        'unused
  ?#5, BIN2STR$(UINT32, offset);   'file offset to raster data

  ?#5, BIN2STR$(UINT32, 40);       'size of info header
  ?#5, BIN2STR$(INT32, ww);        'width
  ?#5, BIN2STR$(INT32, hh);        'height
  ?#5, BIN2STR$(UINT16, 1);        'number of planes
  ?#5, BIN2STR$(UINT16, bpp);      'bpp=1/4/8/16/24/32 (numColors=2/16/256/65K/16M/16M+A)
  ?#5, BIN2STR$(INT32, compr);     'compression (0=RGB, 1=RLE8, 2=RLE4, 3=BITFIELDS)
  ?#5, BIN2STR$(INT32, 0);         'compressed size of image
  ?#5, BIN2STR$(INT32, 0);         'hor. resolution pix/m
  ?#5, BIN2STR$(INT32, 0);         'ver resolution pix/m
  ?#5, BIN2STR$(INT32, 0);         'number of actually used colors
  ?#5, BIN2STR$(INT32, 0);         'number of important colors (0=ALL)

  IF bpp = 16 THEN
    'RGB565 mode
    ?#5, BIN2STR$(UINT32, &hF800);  'RED
    ?#5, BIN2STR$(UINT32, &h07E0);  'GREEN
    ?#5, BIN2STR$(UINT32, &h001F);  'BLUE

  ELSEIF bpp = 8 THEN
    'COLOR TABLE
    'length = 4 * numColors bytes
    'RED, GREEN, BLUE, RESERVE
    FOR x = 0 TO 255
      ?#5, BIN2STR$(UINT32, MAP(x));
    NEXT x

  ENDIF

  'RASTER IMAGE
  FOR y = hh - 1 TO 0 STEP -1
    TUIwaitingProgress(dialog, 100 * (hh - y) / hh)
    FOR x = 0 TO ww - 1
      SELECT CASE bpp
        CASE 24 '24bpp, not used
          c = PIXEL(xx + x, yy + y, pp)
          ?#5, LEFT$(BIN2STR$(UINT32, c), 3);
        
        CASE 8 '8bpp, COLOR INDEXED
          ?#5, CHR$(PEEK(BYTE addr + (yy + y)*MM.HRES*dup + xx + x));
          
        CASE 16 '16bpp, RGB565
          ?#5, BIN2STR$(UINT16, PEEK(SHORT addr + 2*(yy + y)*MM.HRES*dup + 2*(xx + x)));       
          'c = PIXEL(xx + x, yy + y, pp)
          'RGB888 to RGB565
          'c = ((c AND &hFF) >> 3) + (((c AND &hFF00) >> 10) << 5) + (((c AND &hFF0000) >> 19) << 11)
          '?#5, BIN2STR$(UINT16, c);
          
      END SELECT
    NEXT x
    IF padding > 0 THEN ?#5, STRING$(padding, 0);
  NEXT y
  CLOSE #5
  TUIwaitingOFF(dialog)
END SUB

FUNCTION GRF.getImgInfo(filePath AS STRING) AS STRING
  'return info about graphic file
  'WIDTH, HEIGHT, BPP, VERSION

  GRF.getImgInfo = ""
  
  ON ERROR SKIP
  OPEN filePath FOR INPUT AS #10
  IF MM.ERRNO = 0 THEN
    LOCAL STRING sData, vers
    LOCAL INTEGER w, h, bpp, hlp

    SELECT CASE UCASE$(RIGHT$(filePath, 4))
      CASE ".BMP"
        vers = INPUT$(2, #10)
        IF vers = "BM" THEN
          sData = INPUT$(16, #10)
          sData = INPUT$(4, #10)
          w = ABS(STR2BIN(INT32, sData))
          sData = INPUT$(4, #10)
          h = ABS(STR2BIN(INT32, sData))
          sData = INPUT$(2, #10)
          sData = INPUT$(2, #10)
          bpp = STR2BIN(UINT16, sData)
          GRF.getImgInfo = STR$(w) + "," + STR$(h) + "," + STR$(bpp) + "," + vers
        ENDIF      

      CASE ".GIF"
        vers = INPUT$(6, #10)
        IF vers = "GIF87a" OR vers = "GIF89a" THEN
          w = STR2BIN(UINT16, INPUT$(2, #10))
          h = STR2BIN(UINT16, INPUT$(2, #10))
          bpp = (ASC(INPUT$(1, #10)) AND 7) + 1
          GRF.getImgInfo = STR$(w) + "," + STR$(h) + "," + STR$(bpp) + "," + vers
        ENDIF

      CASE ".PNG"
        sData = INPUT$(8, #10)
        IF sData = CHR$(137)+CHR$(80)+CHR$(78)+CHR$(71)+CHR$(13)+CHR$(10)+CHR$(26)+CHR$(10) THEN
          sData = INPUT$(8, #10)
          w = STR2BIN(UINT32, INPUT$(4, #10), BIG)
          h = STR2BIN(UINT32, INPUT$(4, #10), BIG)
          bpp = ASC(INPUT$(4, #10))
          hlp = ASC(INPUT$(4, #10))
          SELECT CASE hlp
            CASE 0 'gray
              vers = "Grayscale"

            CASE 2 'RGB
              bpp = 3 * bpp
              vers = "RGB"

            CASE 3 'PALETTE
              vers = "Indexed"
        
            CASE 4 'GRAY + ALPHA
              bpp = 2 * bpp
              vers = "Gray/alpha"

            CASE 6 'RGB + ALPHA
              bpp = 4 * bpp
              vers = "RGBA"

          END SELECT
          GRF.getImgInfo = STR$(w) + "," + STR$(h) + "," + STR$(bpp) + "," + vers

      CASE ".JPG"
        LOCAL INTEGER block
        LOCAL STRING x
        bpp = 24
        vers = ""
        DO
          block = ASC(INPUT$(1, #10)) ' flag for start of block
          IF block = 255 THEN
            block = ASC(INPUT$(1, #10)) ' block type
            IF block = &hC0 THEN
              x = INPUT$(3, #10)
              h = STR2BIN(UINT16, INPUT$(2, #10), BIG)
              w = STR2BIN(UINT16, INPUT$(2, #10), BIG)
              EXIT DO

            ELSEIF block = &hC2 THEN
  
              vers = "Progressive"
              x = INPUT$(3, #10)
              h = STR2BIN(UINT16, INPUT$(2, #10), BIG)
              w = STR2BIN(UINT16, INPUT$(2, #10), BIG)
              EXIT DO
            ENDIF
          ENDIF
        LOOP
        GRF.getImgInfo = STR$(w) + "," + STR$(h) + "," + STR$(bpp) + "," + vers

     END SELECT
    CLOSE #10
  END IF
END FUNCTION

FUNCTION GRF.loadImg(filePath AS STRING, xx AS INTEGER, yy AS INTEGER, pg AS INTEGER) AS INTEGER
  'load image to x, y, page
  'returns 0 when NOK

  GRF.loadImg = 1
  SELECT CASE UCASE$(RIGHT$(filePath, 4))
    CASE ".BMP"
      PAGE WRITE pg
      ON ERROR SKIP
      LOAD BMP filePath, xx, yy
      IF MM.ERRNO > 0 THEN GRF.loadImg = 0
      PAGE WRITE 0
      IF NOT GRF.loadImg THEN
        TEXT MM.HRES \2 , MM.VRES \2, "Unsupported BMP format", "CM" ,8 ,,RGB(RED), BC.TUI
      ENDIF
    CASE ".GIF"
      IF FIELD$(GRF.getImgInfo(filePath), 4, ",") = "GIF89a" THEN
        PAGE WRITE pg
        LOAD GIF filePath, xx, yy
        PAGE WRITE 0
      ELSE
        TEXT MM.HRES \2 , MM.VRES \2, "GIF87a not supported", "CM" ,8 ,,RGB(RED), BC.TUI
        GRF.loadImg = 0
      ENDIF

    CASE ".PNG"
      PAGE WRITE pg
      ON ERROR SKIP
      LOAD PNG filePath, xx, yy
      IF MM.ERRNO > 0 THEN GRF.loadImg = 0
      PAGE WRITE 0
      IF NOT GRF.loadImg THEN
        TEXT MM.HRES \2 , MM.VRES \2, "Unsupported PNG format", "CM" ,8 ,,RGB(RED), BC.TUI
      ENDIF

    CASE ".JPG"
      PAGE WRITE pg
      ON ERROR SKIP
      LOAD JPG filePath, xx, yy
      PAGE WRITE 0
      IF MM.ERRNO > 0 THEN GRF.loadImg = 0
      PAGE WRITE 0
      IF NOT GRF.loadImg THEN
        TEXT MM.HRES \2 , MM.VRES \2, "Unsupported JPG format", "CM" ,8 ,,RGB(RED), BC.TUI
        GRF.loadImg = 0
      ENDIF

  END SELECT
END FUNCTION

FUNCTION GRF.getC64info(filePath AS STRING) AS STRING
  'get info for some C64 formats

  LOCAL STRING ext = UCASE$(RIGHT$(filePath, 4))
  DO WHILE INSTR(ext, ".")
    ext = MID$(ext, 2)
  LOOP
  SELECT CASE ext
    CASE "DD"
      GRF.getC64info = "320,200,1,Doodle"

    CASE "HED"
      GRF.getC64info = "320,200,1,HiEddie"

    CASE "KOA"
      GRF.getC64info = "320 (2x160),200,2,Koala"

    CASE "GG"
      GRF.getC64info = "320 (2x160),200,2,Koala (RLE)"

    CASE "HBM"
      GRF.getC64info = "320,200,1,C64 HIRES"

    CASE "JJ"
      GRF.getC64info = "320,200,1,Doodle (RLE)"

    CASE ELSE
      GRF.getC64info = ""      
  END SELECT
END FUNCTION

FUNCTION GRF.loadC64(filePath AS STRING, x AS INTEGER, y AS INTEGER, pg AS INTEGER) AS INTEGER
  'load some C64 formats to x, y, page
  'returns 0 when NOK

  LOCAL INTEGER cols(15) = (&h000000, &hFFFFFF, &h880000, &hAAFFEE, &hCC44CC, &h00CC55, &h0000AA, &hEEEE77, &hDD8855, &h664400, &hFF7777, &h333333, &h777777, &hAAFF66, &h0088FF, &hBBBBBB)
  LOCAL INTEGER bitmap(1024), scrRAM(128), colRAM(128), backCol
  LOCAL INTEGER bmp, scr, col, multi = 0
  LOCAL INTEGER xxx, yyy, xx, yy, bb, ss, cc, bbb
  LOCAL STRING inp
  GRF.loadC64 = 0      
  cols(0) = RGB(NOTBLACK)
  backCol = cols(0)

  PAGE WRITE pg
  LOCAL STRING ext = UCASE$(RIGHT$(filePath, 4))
  DO WHILE INSTR(ext, ".")
    ext = MID$(ext, 2)
  LOOP
  SELECT CASE ext
    CASE "DD"
      OPEN filePath FOR INPUT AS #5
      LONGSTRING CLEAR bitmap()
      LONGSTRING CLEAR scrRAM()
      inp = INPUT$(2, #5) 'skip memory start
      FOR xxx = 1 TO 4
        LONGSTRING APPEND scrRAM(), INPUT$(250, #5)    
      NEXT xxx
      inp = INPUT$(24, #5) 'skip 24 bytes of screen RAM
      FOR xxx = 1 TO 32
        LONGSTRING APPEND bitmap(), INPUT$(250, #5)    
      NEXT xxx
      CLOSE #5
      multi = 0
      GRF.loadC64 = 1

    CASE "HED"
      OPEN filePath FOR INPUT AS #5
      LONGSTRING CLEAR bitmap()
      LONGSTRING CLEAR scrRAM()
      inp = INPUT$(2, #5) 'skip memory start
      FOR xxx = 1 TO 32
        LONGSTRING APPEND bitmap(), INPUT$(250, #5)    
      NEXT xxx
      inp = INPUT$(192, #5) 'skip 192 bytes of bitmap
      FOR xxx = 1 TO 4
        LONGSTRING APPEND scrRAM(), INPUT$(250, #5)    
      NEXT xxx
      CLOSE #5
      multi = 0
      GRF.loadC64 = 1

    CASE "KOA"
      OPEN filePath FOR INPUT AS #5
      LONGSTRING CLEAR bitmap()
      LONGSTRING CLEAR scrRAM()
      LONGSTRING CLEAR colRAM()
      inp = INPUT$(2, #5) 'skip memory start
      FOR xxx = 1 TO 32
        LONGSTRING APPEND bitmap(), INPUT$(250, #5)    
      NEXT xxx
      FOR xxx = 1 TO 4
        LONGSTRING APPEND scrRAM(), INPUT$(250, #5)    
      NEXT xxx
      FOR xxx = 1 TO 4
        LONGSTRING APPEND colRAM(), INPUT$(250, #5)    
      NEXT xxx
      backCol = ASC(INPUT$(1, #5)) AND 15      
      CLOSE #5
      multi = 1
      GRF.loadC64 = 1

    CASE "HBM"
      OPEN filePath FOR INPUT AS #5
      LONGSTRING CLEAR bitmap()
      inp = INPUT$(2, #5) 'skip memory start
      FOR xxx = 1 TO 32
        LONGSTRING APPEND bitmap(), INPUT$(250, #5)    
      NEXT xxx
      CLOSE #5
      LONGSTRING CLEAR scrRAM()
      FOR xxx = 1 TO 4
        LONGSTRING APPEND scrRAM(), STRING$(255, &h10)
      NEXT xxx
      LONGSTRING APPEND scrRAM(), STRING$(4, &h10)
      multi = 0
      GRF.loadC64 = 1

    CASE "GG"
    CASE "JJ"

  END SELECT
  IF GRF.loadC64 THEN
    IF multi THEN
      bmp = 8
      scr = 8
      col = 8
      FOR yy = 0 TO 199 STEP 8
        FOR xx = 0 TO 319 STEP 8
          'ss = LGETBYTE(scrRAM(), scr)
          ss = PEEK(VAR scrRAM(), scr)
          INC scr
          'cc = LGETBYTE(colRAM(), col) AND 15
          cc = PEEK(VAR colRAM(), col) AND 15
          INC col
          FOR yyy = 0 TO 7
            'bb = LGETBYTE(bitmap(), bmp)
            bb = PEEK(VAR bitmap(), bmp)
            INC bmp
            FOR xxx = 0 TO 3
              bbb = bb AND 3
              SELECT CASE bbb
                CASE 0
                  PIXEL x + xx + 2*(3 - xxx), y + yy + yyy, cols(backCol)
                  PIXEL x + xx + 2*(3 - xxx) + 1, y + yy + yyy, cols(backCol)

                CASE 2
                  PIXEL x + xx + 2*(3 - xxx), y + yy + yyy, cols(ss AND 15)
                  PIXEL x + xx + 2*(3 - xxx) + 1, y + yy + yyy, cols(ss AND 15)

                CASE 1
                  PIXEL x + xx + 2*(3 - xxx), y + yy + yyy, cols(ss >> 4)
                  PIXEL x + xx + 2*(3 - xxx) + 1, y + yy + yyy, cols(ss >> 4)

                CASE 3
                  PIXEL x + xx + 2*(3 - xxx), y + yy + yyy, cols(cc)
                  PIXEL x + xx + 2*(3 - xxx) + 1, y + yy + yyy, cols(cc)
              END SELECT
              bb = bb >> 2
            NEXT xxx
          NEXT yyy
        NEXT xx
      NEXT yy
    ELSE
      bmp = 8
      scr = 8
      FOR yy = 0 TO 199 STEP 8
        FOR xx = 0 TO 319 STEP 8
          ss = PEEK(VAR scrRAM(), scr)
          INC scr
          FOR yyy = 0 TO 7
            bb = PEEK(VAR bitmap(), bmp)
            INC bmp
            FOR xxx = 0 TO 7
              IF bb AND (1<<(7 - xxx)) THEN
                PIXEL x + xx + xxx, y + yy + yyy, cols(ss >> 4)
              ELSE
                PIXEL x + xx + xxx, y + yy + yyy, cols(ss AND 15)
              ENDIF
            NEXT xxx
          NEXT yyy
        NEXT xx
      NEXT yy
    ENDIF
  ENDIF
  PAGE WRITE 0
END FUNCTION

FUNCTION GRF.getSPRinfo(filePath AS STRING) AS STRING
  GRF.getSPRinfo = ""

  ON ERROR SKIP
  OPEN filePath FOR INPUT AS #3
  IF MM.ERRNO = 0 THEN
    LOCAL STRING s = "'"
    DO WHILE LEFT$(s, 1) = "'"
      LINE INPUT #3, s
    LOOP
    CLOSE #3
    LOCAL INTEGER w = VAL(FIELD$(s, 1, ","))
    s = FIELD$(s, 3, ",")
    LOCAL INTEGER h = VAL(s)
    IF h = 0 THEN h = w
    GRF.getSPRinfo = STR$(w) + "," + STR$(h)    
  ENDIF
END FUNCTION

FUNCTION GRF.loadSPR(filePath AS STRING, xx AS INTEGER, yy AS INTEGER, pg AS INTEGER) AS INTEGER
  'simple sprite viewer

  GRF.loadSPR = 0
  ON ERROR SKIP
  OPEN filePath FOR INPUT AS #3
  IF MM.ERRNO = 0 THEN
    PAGE WRITE pg
    LOCAL STRING s = "'", c
    DO WHILE LEFT$(s, 1) = "'"
      LINE INPUT #3, s
    LOOP
    LOCAL INTEGER w = VAL(FIELD$(s, 1, ","))
    LOCAL INTEGER x, y, cc
    s = FIELD$(s, 3, ",")
    LOCAL INTEGER h = VAL(s)
    IF h = 0 THEN h = w

    FOR y = 0 TO h - 1
      s = "'"
      DO WHILE LEFT$(s, 1) = "'"
        LINE INPUT #3, s
      LOOP
      FOR x = 1 TO LEN(s)
        c = MID$(s, x, 1)
        IF c >= "0" AND c <= "7" THEN
          cc = GRF.getCMMcolor(ASC(c) - 48)
          PIXEL xx + x - 1, yy + y, cc
        ENDIF
      NEXT x 
    NEXT y
    CLOSE #3
    PAGE WRITE 0
    GRF.loadSPR = 1
  ENDIF
END FUNCTION

FUNCTION GRF.getCMMcolor(n AS INTEGER) AS INTEGER
  'get color from standard CMM (for sprites)

  GRF.getCMMcolor = RGB(NOTBLACK)
  SELECT CASE n
    CASE 0
      GRF.getCMMcolor = RGB(NOTBLACK)

    CASE 1
      GRF.getCMMcolor = RGB(BLUE)

    CASE 2
      GRF.getCMMcolor = RGB(GREEN)

    CASE 3
      GRF.getCMMcolor = RGB(CYAN)

    CASE 4
      GRF.getCMMcolor = RGB(RED)

    CASE 5
      GRF.getCMMcolor = RGB(PURPLE)

    CASE 6
      GRF.getCMMcolor = RGB(YELLOW)

    CASE 7
      GRF.getCMMcolor = RGB(WHITE)

  END SELECT 
END FUNCTION

FUNCTION GRF.getZXinfo(filePath AS STRING) AS STRING
  'get info for some ZX formats

  LOCAL STRING ext = UCASE$(RIGHT$(filePath, 4))
  DO WHILE INSTR(ext, ".")
    ext = MID$(ext, 2)
  LOOP
  SELECT CASE ext
    CASE "SCR"
      GRF.getZXinfo = "256,192,1,Screen Dump"

    CASE "BSC"
      GRF.getZXinfo = "256,192,1,Border Screen Image"

    CASE ELSE
      GRF.getZXinfo = ""      
  END SELECT
END FUNCTION

FUNCTION GRF.loadZX(filePath AS STRING, x AS INTEGER, y AS INTEGER, pg AS INTEGER) AS INTEGER
  'load some ZX Spectrum formats to x, y, page
  'returns 0 when NOK

  LOCAL INTEGER cols(15) = (&h000000, &h0000D7, &hD70000, &hD700D7, &h00D700, &h00D7D7, &hD7D700, &hD7D7D7, &h000000, &h0000FF, &hFF0000, &hFF00FF, &h00FF00, &h00FFFF, &hFFFF00, &hFFFFFF)
  LOCAL INTEGER bitmap(768), scrRAM(96)
  LOCAL INTEGER bmp, scr, third, fc, bc, rx, ry
  LOCAL INTEGER xxx, yyy, xx, yy, bb, ss
  LOCAL STRING inp
  GRF.loadZX = 0      
  cols(0) = RGB(NOTBLACK)
  cols(8) = cols(0)

  PAGE WRITE pg
  LOCAL STRING ext = UCASE$(RIGHT$(filePath, 4))
  DO WHILE INSTR(ext, ".")
    ext = MID$(ext, 2)
  LOOP
  SELECT CASE ext
    CASE "SCR"
      OPEN filePath FOR INPUT AS #5
      LONGSTRING CLEAR bitmap()
      LONGSTRING CLEAR scrRAM()
      FOR xxx = 1 TO 32
        LONGSTRING APPEND bitmap(), INPUT$(192, #5)    
      NEXT xxx
      FOR xxx = 1 TO 4
        LONGSTRING APPEND scrRAM(), INPUT$(192, #5)
      NEXT xxx
      CLOSE #5
      GRF.loadZX = 1

    CASE "BSC"
      OPEN filePath FOR INPUT AS #5
      LONGSTRING CLEAR bitmap()
      LONGSTRING CLEAR scrRAM()
      FOR xxx = 1 TO 32
        LONGSTRING APPEND bitmap(), INPUT$(192, #5)    
      NEXT xxx
      FOR xxx = 1 TO 4
        LONGSTRING APPEND scrRAM(), INPUT$(192, #5)
      NEXT xxx
      CLOSE #5
      GRF.loadZX = 1

  END SELECT
  IF GRF.loadZX THEN
    bmp = 8
    scr = 8
    FOR third = 0 TO 3
      FOR yy = 0 TO 7
        FOR yyy = 0 TO 56 STEP 8
          FOR xx = 0 TO 248 STEP 8
            bb = PEEK(VAR bitmap(), bmp)
            INC bmp
            FOR xxx = 0 TO 7
              rx = x + xx + xxx
              ry = y + third * 64 + yy + yyy
              ss = PEEK(VAR scrRAM(), 8 + 32 * (ry \ 8) + (rx \ 8))
              fc = ss AND &b111
              bc = (ss AND &b111000) >> 3
              IF ss AND &b1000000 THEN
                INC fc, 8
                INC bc, 8
              ENDIF
              IF bb AND (1<<(7 - xxx)) THEN
                PIXEL rx, ry, cols(fc)
              ELSE
                PIXEL rx, ry, cols(bc)
              ENDIF
            NEXT xxx
          NEXT xx
        NEXT yyy
      NEXT yy
    NEXT third
  ENDIF
  PAGE WRITE 0
END FUNCTION
