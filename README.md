# NC
 Napoleon Commander

Simple file commander based on ancient Norton (Volkov...) commanders for DOS, now for Colour Maximite 2.

It has ability to connect to Mac/PC/Linux computer either through serial port or WiFi with help of included Python server **NCserver.py** (when serial port used,  **pyserial** have to be installed with with `pip install pyserial`).

**This server needs as minimum v0.66 of ESP8266 firmware (https://github.com/jirsoft/CMM2ESP)**

Starting server without arguments use defaults from begin of the Python script, arguments can any combination of:
```
NCserver.py -s <serverdir> -ip <IP> (for UDP server)
  <serverdir>
    base directory for NCserver, Napoleon Commander on CMM2 see just inside of this

  <ip>
    IP address of ESP on CMM2

  <verbose>
    verbose level (0=min, 3 = max)
``` 
`NCserver.py -h` for help.

or for serial server:
```
NCserver.py -s <serverdir> -p <portname> -b <baudrate>
  <serverdir>
    base directory for NCserver, Napoleon Commander on CMM2 see just inside of this

  <portname>
    serial port used for communication with Napoleon Commander on CMM2

  <baudrate>
    speed of serial port, need to be the same as set in Napoleon Commander
    (F11, option 6 checked=691200, unchecked=230400)
```

### VERSION HISTORY
#### v1.40
	proportional text viewer on ALT F4
	speedup for ASCII text viewer (F3), total amount of pages is not precalculated anymore
	bugfixes
	
#### v1.38
	better resolution configuration
	improved config system (old will be converted on-the-fly)
	speed-up
	bugfixes
	test for TUI.INC version (needed for new config)
	
#### v1.26
	combined serial and network communication (switch ON/OFF ESP8266 with F11, restart server and use other medium)
	improved serial/network speed
	
#### v1.13
	fixed bug in HEX editor (00 couldn't be entered)
	extended About dialog (versions of GRF.INC and TUI.INC)
	Atari ST graphic formats in GRF.INC
	
#### v1.12
	finally finished basic HEX editor on F4 key, it can just overwrite, not to make file longer or shorter
	modified MANUAL.TXT to comply with changes
	new icons for WiFi, HIDDEN items and SORT in left bottom corner, keys changed to CTRL+H and CTRL+H
	clock in right bottom corner
	WiFi functions on ALT+F12 (searh moved to more standard CTRL+F):
		enabled just when ESP8266 module switched ON in CONFIG (key 7) and present (tested)
		first time needed SSID and PASSWORD to network, later stored into NC.CFG file
	bugfixes

#### v1.04
	added SEARCH to ALT+F12 (inclusive wildcards '?' and '*'), lists all found FILEs and DIRs, then jumps to first one
	added GRF.INC library (link in description), now just with few functions:
		screenshot saves BMP either in 8bpp or 16bpp (smaller files)
		preview of GIF, BMP and PNG in window and size + bpp informations
		preview of some C64 picure files:  HiEddie (.hed), Doodle (.dd), Koala (.koa), HIRES (.hbm)
		preview of SPRITE file
	bugfixes in TUI.INC
	
#### v0.99
	changed ICN for to SPR (standard sprite file)
	added simple sprite viewer
	modifcation of BMP viewer
	version file check
	refactoring

#### v0.98
	added support for PgUp and PgDown
	ALT+Home, ALT+End jumps to total begin and end of DIR listing
	support for NC UDP server (included) on CMM2 Deluxe *or any other with connected through serial)
	added Arduino file for ESP8266

#### v0.95
	use LONGSTRING in serial transfer FROM SERVER, big speedup
	(400 MHz CMM2 without WS board, 66/31 kB/s to/from server, 480 Mhz CMM2 Deluxe 66/14 kB/s, why?) 
	command line arguments for NCserver.py (baudrate, port, serverdir)
	on NCserver.py start check for non-ASCII characters in file/dir names (inside of serverdir)

#### v0.93
	bug fix (problem with dimensioning array with just 1 member, LOCAL STRING a(0) is not allowed)
	first version of NCserver with less crashes on unicode characters

#### v0.92
	bug fixes
	can run basic program with ENTER
	removed TUI.INC, see description
	
#### v0.91
	bug fixes
	new TUI version
	CTRL-C blocked
	
#### v0.72
	bug fixes
	main menu shows ALT version
	MOVES now under ALT+F5
	BASIC Helpers under ALT+F4, pretty formater (not finished yet), DEBUG helper
	simple archiver under ALT+F9 (RLE and HUFFMAN codec)
	some other small changes

#### v0.61
	bug fixes
	new serial speed

#### v0.60
	a-z key jumps first to DIR, second to FILE
	waiting dialog has progress bar
	ALT+F1/F2 choose source for panes: either SERVER or SD card
	bugfixes
	
#### v0.41
	TUI separated
	better logo
	bugfixes

#### v0.40
	better screen output (less flicker)
	CONFIG (with save)
	A-Z keys jumps to item
	Screenshot function
	UNSORTED FILES
	
#### v0.31
	DATETIME for DIRs
	DIRs are in yellow
	case unsensitive sorting
	status for HIDDEN files

#### v0.3
	added external viewer ("VIEWER.INC") and action ("ACTION.INC") for MAR files plus example
	bugfixes


#### v0.2
	first public version
