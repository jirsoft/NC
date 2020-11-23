from datetime import datetime
from pathlib import Path
import serial

#modify to your port
ser = serial.Serial(
	port='/dev/tty.usbmodem14101',
	baudrate = 230400,
	parity=serial.PARITY_NONE,
	stopbits=serial.STOPBITS_ONE,
	bytesize=serial.EIGHTBITS,
	timeout=1
	)
	
#modify to your path to server root
BASEDIR = "/Users/jirsoft/Documents/Maximite/NCserver/"

def convert_date(timestamp):
    d = datetime.utcfromtimestamp(timestamp)
    formated_date = d.strftime('%y-%m-%d %H:%M')
    return formated_date

def out(s):
	print(s)
	
LF = '\n'
CURDIR = ""

ser.reset_input_buffer()
ch = ''
while ser.inWaiting() > 0:
	ch = ser.read(1)
	
print ("Napoleon server connected to: " + ser.portstr)
while True:
	ch = ser.read_until().decode('ASCII')[:-1]
	
	if len(ch) > 0:
	
		#is server alive
		if ch[0] == '?':
			out('LIFE TEST')
			ser.write('OK\n'.encode('ASCII'))
    		
		#missing
		elif ch[0] == 'W':
			out('WRITE FILE')
    		
		#missing
		elif ch[0] == 'R':
			out('READ FILE')
    		
		#missing
		elif ch[0] == 'C':
			out('COPY FILE')
    		
		#traverse directory
		elif ch[0] == 'D':
			out('DIRECTORY ' + ch[1:])
			CURDIR = ch[4:]
			
			dir = Path(BASEDIR + CURDIR)
			cnt = 0
			for item in dir.iterdir():
				cnt += 1
			if len(CURDIR) > 0:
				cnt += 1
			
			ret = 'D' + str(cnt) + '|' + 'S:/' + CURDIR
			if ret[-1] != '/':
				ret += '/'
			out(ret)
			ret += '\n'
			ser.write(ret.encode('ASCII'))
			
			if len(CURDIR) > 0:
				ret = 'D..|[ GO UP ]|'
				out(ret)
				ret += '\n'
				ser.write(ret.encode('ASCII'))
				
			for item in dir.iterdir():
				info = item.stat()
				mtime = convert_date(info.st_mtime)
				if item.is_file():
					fsize = str(info.st_size)
					ret = 'F'+item.name + '|' + fsize + "|" + mtime

				else:
					ret = 'D'+item.name + '|DIRECTORY|' + mtime
				out(ret)
				ret += '\n'
				ser.write(ret.encode('ASCII'))
    	
		#missing
		elif ch[0] == 'M':
			out('MAKE DIRECTORY')
    		
		#missing
		elif ch[0] == 'K':
			out('KILL')
    		
		else:
			out(ch)
		
		ch = ''
		
ser.close()

