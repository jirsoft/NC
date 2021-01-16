#!/usr/bin/python3
#Napoleon Server
#Simple server for CMM2  Napoleon Commander
#JirSoft, 2020
#v0.04

from datetime import datetime
from pathlib import Path
import sys, getopt
import serial
import os
import shutil
import time

#default name of the serial port (when not given as command line argument)
#portName = '/dev/tty.usbserial-AD0JHH4Z' 	#MacOS, CMM2 deluxe
portName = '/dev/tty.usbmodem14101'					#MacOS, CMM2 standard
#portName='COM4'														#WINDOWS

#default baudrate (when not given as command line argument)
#tested on my computer, needs to be the same speed as on CMM2 in SERIAL_INIT.NC
portBaudrate = 691200

#used as server root, this server has no other access, can be given as command lineargument
BASEDIR = "/Users/jirsoft/Documents/Maximite/NCserver/"

LF = '\n'
CURDIR = ""
MODE = 0


def convert_date(timestamp):
    d = datetime.fromtimestamp(timestamp)
    formated_date = d.strftime('%y-%m-%d %H:%M')
    return formated_date

def uni2ascii(s):
	return(s.encode("ascii", "ignore").decode())
	
def out(s):
	print(s)
	
def unicodeTest(d):
	dir = Path(d)
	dirLen = len(d)
	trav = []
	for dirpath, dirs, files in os.walk(dir):
		if dirpath[dirLen:] != uni2ascii(dirpath[dirLen:]):
			trav.append(dirpath[dirLen:])
		for f in files:
			if f != uni2ascii(f):
				trav.append (dirpath[dirLen:] + '/' + f)

	if len(trav) > 0:
		print('Found ' + str(len(trav)) + ' non-ASCII named file(s) or dir(s), please rename it:')
		for r in trav:
			print(BASEDIR + r)
		sys.exit()

def main(argv):
	global BASEDIR, portName, portBaudrate
	try:
		opts, args = getopt.getopt(argv, "hs:p:b:", ["serverdir=","port=", "baudrate="])
		
	except getopt.GetoptError:
		print(sys.argv[0] + ' -s <serverdir> -p <portname> -b <baudrate>')
		sys.exit()

	for opt, arg in opts:
		if opt == '-h':
			print()
			print(sys.argv[0] + ' -s <serverdir> -p <portname> -b <baudrate>')
			print('  <serverdir>')
			print('    base directory for NCserver, Napoleon Commander on CMM2 see just inside of this')
			print()
			print('  <portname>')
			print('    serial port used for communication with Napoleon Commander on CMM2')
			print()
			print('  <baudrate>')
			print('    speed of serial port, need to be the same as set in Napoleon Commander')
			print('    (F11, option 6 checked=691200, unchecked=230400)')
			print()
			
			sys.exit()
		 
		elif opt in ("-s", "--serverdir"):
			if arg == '/' or arg == '':
				print('Serverdir too dangerous (root dir of disk), using default')
			else:
				BASEDIR = arg
		 
		elif opt in ("-p", "--port"):
			portName = arg

		elif opt in ("-b", "--baudrate"):
			if (arg != '230400') and (arg != '691200'):
				print("Nonstandard baudrate (standard for NC is 230400 and 691200)")
				if int(arg) > 1024:
					if int(arg) < 1000000:
						portBaudrate = arg
					else:
						print('Baudrate to high, using default')
				else:
					print('Baudrate too low, using default')
					
			else:
				portBaudrate = arg
			


if __name__ == "__main__":
	main(sys.argv[1:])

try:
	ser = serial.Serial(
		port = portName, #MacOS, CMM2 deluxe
		baudrate = portBaudrate,
		parity=serial.PARITY_NONE,
		stopbits=serial.STOPBITS_ONE,
		bytesize=serial.EIGHTBITS,
		timeout=10
		)
		
except:
	print("Wrong serial port, can't be open")
	sys.exit()

unicodeTest(BASEDIR)

ser.reset_input_buffer()
ch = ''
while ser.inWaiting() > 0:
	ch = ser.read(1)

print ("Napoleon Server started as:")
print (sys.argv[0] + " -s '" + BASEDIR + "' -p '" + portName + "' -b " + str(portBaudrate))

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
				out('WRITE FILE ' + BASEDIR + ch.split('|')[0][1:] + ', [' + str(fileLen) + ' bytes]')
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
					ret = 'READY|' + str(fileLen) + '\n'
					ser.write(ret.encode('ASCII'))

					while ser.in_waiting < 6:
						time.sleep(0.1)
					if ser.read_until().decode('ASCII')[:-1] == 'START':
						print('START ... ', end = '')					
						copyTime = time.perf_counter()
						
						for i in range(1, partNum + 1):
							srd = ser.read_until().decode('ASCII')[:-1]
							if srd == 'NEXT':
								ser.write(buffer[bufPos:bufPos + partLen])
								bufPos += partLen
							else:
								print("ERROR '" + srd + "'")
						
						if partRem > 0:
							srd = ser.read_until().decode('ASCII')[:-1]
							if srd == 'NEXT':
								ser.write(buffer[bufPos:])
							else:
								print("ERROR '" + srd + "'")
														
						copyTime = time.perf_counter() - copyTime

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
		
			#list directory
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
					if ser.read_until().decode('ASCII')[:-1] == 'NEXT':
						ser.write(ret.encode('ASCII'))
			
				for item in dir.iterdir():
					info = item.stat()
					mtime = convert_date(info.st_mtime)
					if item.is_file():
						fsize = str(info.st_size)
						ret = 'F' + item.name + '|' + fsize + "|" + mtime

					else:						
						ret = 'D' + item.name + '|DIRECTORY|' + mtime
					out(ret)
					ret += '\n'
					if ser.read_until().decode('ASCII')[:-1] == 'NEXT':
						ser.write(ret.encode('ASCII'))
	
			#traverse directory
			elif ch[0] == 'T':
				out('TRAVERSE ' + ch[1:])
				CURDIR = ch[4:]
				if CURDIR != '':
					if CURDIR[-1] != '/':
						CURDIR += '/'
				dir = Path(BASEDIR + CURDIR)
				dirLen = len(BASEDIR)
				trav = []
				for dirpath, dirs, files in os.walk(dir):
					trav.append('D' + dirpath[dirLen:])
					for f in files:
						trav.append ('F' + dirpath[dirLen:] + '/' + f + '|' + str(os.stat(dirpath + '/' + f).st_size))
			
				ret = 'T' + str(len(trav)) + '|' + 'S:/' + CURDIR
				out(ret)
				ret += '\n'
				ser.write(ret.encode('ASCII'))
				for r in trav:
					ret = r
					out(ret)
					ret += '\n'
					if ser.read_until().decode('ASCII')[:-1] == 'NEXT':
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
		
			#server RENAME
			elif ch[0] == 'N':
				srcName = BASEDIR + ch.split('|')[0][4:]
				destName = BASEDIR + ch.split('|')[1][3:]
				out('RENAME item ' + srcName + ' to ' + destName)
				os.rename(srcName, destName)
			
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

	
