#Napoleon Server
#Simple server for CMM2  Napoleon Commander
#JirSoft, 2020

from datetime import datetime
from pathlib import Path
import serial
import os
import shutil
import time

#modify to your port
ser = serial.Serial(
	port='/dev/tty.usbmodem14101',
	#tested on my computer, needs to be the same speed as on CMM2 in SERIAL_INIT.NC
	baudrate = 691200,
	parity=serial.PARITY_NONE,
	stopbits=serial.STOPBITS_ONE,
	bytesize=serial.EIGHTBITS,
	timeout=1
	)
	
#modify to your path to server root, this server has no other access
BASEDIR = "/Users/jirsoft/Documents/Maximite/NCserver/"

def convert_date(timestamp):
    d = datetime.utcfromtimestamp(timestamp)
    formated_date = d.strftime('%y-%m-%d %H:%M')
    return formated_date

def out(s):
	print(s)
	
LF = '\n'
CURDIR = ""
MODE = 0

ser.reset_input_buffer()
ch = ''
while ser.inWaiting() > 0:
	ch = ser.read(1)
	
print ("Napoleon Server connected to: " + ser.portstr)
while True:
	if MODE == 0:
		ch = ser.read_until().decode('ASCII')[:-1]
	
		if len(ch) > 0:
			print('<-' + ch)
		
			#is server alive
			if ch[0] == '?':
				out('LIFE TEST')
				ser.write('OK\n'.encode('ASCII'))
			
			#local -> server
			elif ch[0] == 'W':
				fileName = BASEDIR + CURDIR + ch.split('|')[0][1:]
				fileLen = int(ch.split('|')[1])
				remain = fileLen
				buffer = bytes()
				MODE = 1
				ser.write('READY\n'.encode('ASCII'))
				out('WRITE FILE ' + ch.split('|')[0][1:] + ' [' + str(fileLen) + ' bytes]')
				copyTime = time.perf_counter()
			
			#server -> local
			elif ch[0] == 'R':
				fileName = BASEDIR + ch.split('|')[0][4:]
				partLen = int(ch.split('|')[1])
				if os.path.exists(fileName):
					fileLen = os.stat(fileName).st_size
					partNum = int(fileLen / partLen)
					partRem = fileLen % partLen
					out('READ FILE ' + fileName + ', [' + str(fileLen) + ' bytes = ' + str(partNum) + '*' + str(partLen) + '+' + str(partRem) + ']')
					newFile = open(fileName, "rb")
					buffer = newFile.read()
					newFile.close
					bufPos = 0
					ser.write('READY\n'.encode('ASCII'))

					while ser.in_waiting < 6:
						time.sleep(0.1)
					if ser.read_until().decode('ASCII')[:-1] == 'START':
						print('START ', end = '')					
						copyTime = time.perf_counter()
						for i in range(1, partNum + 1):
							if ser.read_until().decode('ASCII')[:-1] == 'NEXT':
								ser.write(buffer[bufPos:bufPos + partLen])
								bufPos += partLen
							else:
								print('ERROR ')
							
						if partRem > 0:
							if ser.read_until().decode('ASCII')[:-1] == 'NEXT':
								ser.write(buffer[bufPos:])
							else:
								print('ERROR ')
						copyTime = time.perf_counter() - copyTime
						#ser.write('DONE\n'.encode('ASCII'))
						
						if ser.read_until().decode('ASCII')[:-1] == 'DONE':
							print('DONE in ' + str(round(copyTime, 1)) + ' sec (' + str(round(fileLen/copyTime/1024,1)) + ' kB/s)')
						
					
			
			#server -> server
			elif ch[0] == 'C':
				src = BASEDIR + ch.split('|')[0][4:]
				dest = BASEDIR + ch.split('|')[1][3:]
				if os.path.isdir(src):
					out('COPY DIR ' + src + ' to ' + dest)
					shutil.copytree(src, dest)
				else:
					out('COPY FILE ' + src + ' to ' + dest)
					shutil.copy(src, dest)
				ser.write('DONE\n'.encode('ASCII'))
			
			#traverse directory
			elif ch[0] == 'D':
				out('DIRECTORY ' + ch[1:])
				CURDIR = ch[4:]
				if CURDIR != '':
					if CURDIR[-1] != '/':
						CURDIR += '/'
			
				dir = Path(BASEDIR + CURDIR)
				cnt = 0
				for item in dir.iterdir():
					cnt += 1
				if len(CURDIR) > 0:
					cnt += 1
			
				ret = 'D' + str(cnt) + '|' + 'S:/' + CURDIR
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
		
			#server MKDIR
			elif ch[0] == 'M':
				dirName = BASEDIR + ch[4:]
				out('MAKE DIRECTORY ' + dirName)
				if not os.path.exists(dirName):
					os.mkdir(dirName)
					ser.write('DONE\n'.encode('ASCII'))
				else:
					ser.write('ERRORDirecory exists\n'.encode('ASCII'))
					print('Error: ' + dirName + ' exists')
			
			#server KILL or RMDIR (include subdirs)
			elif ch[0] == 'K':
				itemName = BASEDIR + ch[4:]
				out('KILL ' + itemName)			
				if os.path.exists(itemName):
					if os.path.isdir(itemName):
						try:
							shutil.rmtree(itemName)
						except OSError as e:
							print("Error: %s : %s" % (itemName, e.strerror))					
					else:
						try:
							os.remove(itemName)
						except OSError as e:
							print("Error: %s : %s" % (itemName, e.strerror))					
			
			else:
				out(ch)
		
			ch = ''
			
	else:
		if ser.in_waiting > 0:
			toRead = min(ser.in_waiting, remain)
			buffer += ser.read(toRead)
			remain -= toRead
			if remain <= 0:
				ser.write('DONE\n'.encode('ASCII'))
				copyTime = time.perf_counter() - copyTime
				print('DONE in ' + str(round(copyTime, 1)) + ' sec (' + str(round(fileLen/copyTime/1024,1)) + ' kB/s)')
				newFile = open(fileName, "wb")
				newFile.write(buffer)
				newFile.close
				MODE = 0
			
					
		
ser.close()

