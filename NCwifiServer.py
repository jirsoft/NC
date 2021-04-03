#!/usr/bin/python3
#Napoleon Server
#Simple server for CMM2  Napoleon Commander over network, UDP and TCP used
#JirSoft, 2020
VER = 'v0.26'

import socket
from datetime import datetime
from pathlib import Path
import sys, getopt
import os
import shutil
import time

espIP = "10.0.13.180"
udpPort = 34701
tcpPort = 34702

def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP
    
ncIP = get_ip()

#used as server root, this server has no other access, can be given as command lineargument
BASEDIR = "/Users/jirsoft/Documents/Maximite/NCserver/"
VERB_LEVEL = 1

LF = '\n'
CURDIR = ""
MODE = 0
ACT_COMMAND = ''
NC_FOUND = 0

def out(s, level):
	if VERB_LEVEL > level:
		print(s)

def convert_date(timestamp):
    d = datetime.fromtimestamp(timestamp)
    formated_date = d.strftime('%y-%m-%d %H:%M')
    return formated_date

def uni2ascii(s):
	return(s.encode("ascii", "ignore").decode())

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
		out('Found ' + str(len(trav)) + ' non-ASCII named file(s) or dir(s), please rename it:', -1)
		for r in trav:
			out(BASEDIR + r, -1)
		sys.exit()

def lifeTest():
	out('LIFE TEST', 0)
	out("-> 'OK'", 1)
	udpOut("OK")
	
def writeFile(d):
	global MODE, copyTime, remain, buffer, fileLen, fileName, packNum, packCount
	
	fileName = BASEDIR + d.split('|')[0][4:]
	fileLen = int(d.split('|')[1])
	packCount = int(fileLen / 8000)
	if (fileLen % 8000) > 0:
		packCount += 1
		
	out('LOCAL to SERVER ' + fileName + ', [' + str(fileLen) + ' bytes]', 0)
	remain = fileLen
	buffer = bytes()
	packNum = 0
	MODE = 1
	udpOut('READY')
	copyTime = time.perf_counter()

def readFile(d):
	fileName = BASEDIR + d.split('|')[0][4:]
	partLen = int(d.split('|')[1])
	if os.path.exists(fileName):
		fileLen = os.stat(fileName).st_size
		partNum = int(fileLen / partLen)
		partRem = fileLen % partLen
		packCount = partNum
		if partRem > 0:
			packCount += 1
		out('SERVER to LOCAL ' + fileName + ', [' + str(fileLen) + ' bytes = ' + str(partNum) + '*' + str(partLen) + '+' + str(partRem) + '/' + str(packCount) + ']', 0)
		newFile = open(fileName, "rb")
		buffer = newFile.read()
		newFile.close
		bufPos = 0
		ret = 'READY|' + str(fileLen)
		out(ret, 1)
		udpOut(ret)

		if getUdpString() == '#START':
			out('START ... ', 1)					
			copyTime = time.perf_counter()
			
			packNum = 0
					
			while packNum < packCount:
				srd = getUdpString()
				if srd == "#NEXT":
					if VERB_LEVEL > 1:
						print("{:.0%} ".format((packNum + 1)/packCount), end = '', flush=True)
					#out("NEXT " + str(packNum), 0)
					bufStart = packNum * partLen
					if packNum < partNum:
						bufEnd = bufStart + partLen
					else:
						bufEnd = bufStart + partRem				
					udp.sendto(packNum.to_bytes(2,'little') + buffer[bufStart:bufEnd], (espIP, udpPort))
					packNum += 1
					
				elif len(srd) > 7:
					if srd[:7] == "#REPEAT":
						packNum = int(srd[6:])
						out("\nPACKET (" + str(packNum)+ ") was lost, repeating", -1)
						bufStart = packNum * partLen
						if packNum < partNum:
							bufEnd = bufStart + partLen
						else:
							bufEnd = bufStart + partRem						
						udp.sendto(packNum.to_bytes(2,'little') + buffer[bufStart:bufEnd], (espIP, udpPort))
						packNum += 1
					
				else:
					out("\nSERVER to LOCAL Error '" + srd + "'", -1)
					return
														

			if getUdpString() == '#DONE':
				copyTime = time.perf_counter() - copyTime
				out('\nDONE in ' + str(round(copyTime, 1)) + ' sec (' + str(round(fileLen/copyTime/1024,1)) + ' kB/s)', 1)

def copyItem(d):
	out("COPY ITEM '" + d + "'", 0)
	src = BASEDIR + d.split('|')[0][4:]
	dest = BASEDIR + d.split('|')[1][3:]
	if os.path.isdir(src):
		out('COPY DIR ' + src + ' to ' + dest, 1)
		shutil.copytree(src, dest)
	else:
		out('COPY FILE ' + src + ' to ' + dest, 1)
		shutil.copy(src, dest)
	udpOut('DONE')

def listDir(d):
	global CURDIR
	
	out("LIST DIR '" + d + "'", 0)
	CURDIR = d.split('|')[0][4:]
	partLen = int(d.split('|')[1])
	if CURDIR != '':
		if CURDIR[-1] != '/':
			CURDIR += '/'

	dir = Path(BASEDIR + CURDIR)
	
	buffer = bytes()
	if len(CURDIR) > 0:
		ret = 'D..|[ GO UP ]|\n'
		buffer += ret.encode('ASCII')
	for item in dir.iterdir():
		info = item.stat()
		mtime = convert_date(info.st_mtime)
		if item.is_file():
			fsize = str(info.st_size)
			ret = 'F' + item.name + '|' + fsize + '|' + mtime + '\n'
			buffer += ret.encode('ASCII')
		else:						
			ret = 'D' + item.name + '|DIRECTORY|' + mtime + '\n'
			buffer += ret.encode('ASCII')
			
	ret = 'READY|' + str(len(buffer))
	out('-> ' + ret, 1)
	#print(buffer)
	partNum = int(len(buffer) / partLen)
	partRem = len(buffer) % partLen
	packCount = partNum
	if partRem > 0:
		packCount += 1
	udpOut(ret)

	if getUdpString() == '#START':
		out('<- #START', 1)
		copyTime = time.perf_counter()
		packNum = 0
				
		while packNum < packCount:
			srd = getUdpString()
			out('<- ' + srd, 1)
			if srd == "#NEXT":
				bufStart = packNum * partLen
				if packNum < partNum:
					bufEnd = bufStart + partLen
				else:
					bufEnd = bufStart + partRem				
				udp.sendto(packNum.to_bytes(2,'little') + buffer[bufStart:bufEnd], (espIP, udpPort))
				packNum += 1
				
			elif len(srd) > 7:
				if srd[:7] == "#REPEAT":
					packNum = int(srd[6:])
					out("\nPACKET (" + str(packNum)+ ") was lost, repeating", -1)
					bufStart = packNum * partLen
					if packNum < partNum:
						bufEnd = bufStart + partLen
					else:
						bufEnd = bufStart + partRem						
					udp.sendto(packNum.to_bytes(2,'little') + buffer[bufStart:bufEnd], (espIP, udpPort))
					packNum += 1
				
			else:
				out("\nLIST DIR Error '" + srd + "'", -1)
				return
				
		if getUdpString() == '#DONE':
			out('<- #DONE', 1)
			copyTime = time.perf_counter() - copyTime
			out('\nDONE in ' + str(round(copyTime, 1)) + ' sec (' + str(round(len(buffer)/copyTime/1024,1)) + ' kB/s)', 1)

def traverseDir(d):
	global CURDIR
	
	out("TRAVERSE DIR '" + d + "'", 0)
	CURDIR = d.split('|')[0][4:]
	partLen = int(d.split('|')[1])
	if CURDIR != '':
		if CURDIR[-1] != '/':
			CURDIR += '/'

	dir = Path(BASEDIR + CURDIR)
	buffer = bytes()
	
	dirLen = len(BASEDIR)
	for dirpath, dirs, files in os.walk(dir):
		ret = 'D' + dirpath[dirLen:] + '\n'
		buffer += ret.encode('ASCII')
		for f in files:
			ret = 'F' + dirpath[dirLen:] + '/' + f + '|' + str(os.stat(dirpath + '/' + f).st_size) + '\n'
			buffer += ret.encode('ASCII')
			
	ret = 'READY|' + str(len(buffer))
	out('-> ' + ret, 1)
	#print(buffer)
	partNum = int(len(buffer) / partLen)
	partRem = len(buffer) % partLen
	packCount = partNum
	if partRem > 0:
		packCount += 1
	udpOut(ret)

	if getUdpString() == '#START':
		out('<- #START', 1)
		copyTime = time.perf_counter()
		packNum = 0
				
		while packNum < packCount:
			srd = getUdpString()
			out('<- ' + srd, 1)
			if srd == "#NEXT":
				bufStart = packNum * partLen
				if packNum < partNum:
					bufEnd = bufStart + partLen
				else:
					bufEnd = bufStart + partRem				
				udp.sendto(packNum.to_bytes(2,'little') + buffer[bufStart:bufEnd], (espIP, udpPort))
				packNum += 1
				
			elif len(srd) > 7:
				if srd[:7] == "#REPEAT":
					packNum = int(srd[6:])
					out("\nPACKET (" + str(packNum)+ ") was lost, repeating", -1)
					bufStart = packNum * partLen
					if packNum < partNum:
						bufEnd = bufStart + partLen
					else:
						bufEnd = bufStart + partRem						
					udp.sendto(packNum.to_bytes(2,'little') + buffer[bufStart:bufEnd], (espIP, udpPort))
					packNum += 1
				
			else:
				out("\nTRAVERSE Error '" + srd + "'", -1)
				return
				
		if getUdpString() == '#DONE':
			out('<- #DONE', 1)
			copyTime = time.perf_counter() - copyTime
			out('\nDONE in ' + str(round(copyTime, 1)) + ' sec (' + str(round(len(buffer)/copyTime/1024,1)) + ' kB/s)', 1)

def _traverseDir(d):
	out("TRAVERSE DIR '" + d + "'", 0)
	CURDIR = d[4:]
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
	out(ret, 1)
	udpOut(ret)

	for r in trav:
		ret = r
		out(ret, 1)
		if getUdpString() == 'NEXT':
			udpOut(ret)

def makeDir(d):
	dirName = BASEDIR + d[4:]
	out('MAKE DIR ' + dirName, 0)
	if not os.path.exists(dirName):
		os.mkdir(dirName)
		udpOut('DONE')
	else:
		udpOut('ERRORDirecory exists')
		out('MAKE DIR Error: ' + dirName + ' exists', -1)

def renameItem(d):
	srcName = BASEDIR + d.split('|')[0][4:]
	destName = BASEDIR + d.split('|')[1][3:]
	out('RENAME item ' + srcName + ' to ' + destName, 0)
	os.rename(srcName, destName)

def killItem(d):
	itemName = BASEDIR + d[4:]
	out('KILL ' + itemName, 0)			
	if os.path.exists(itemName):
		if os.path.isdir(itemName):
			try:
				shutil.rmtree(itemName)
			except OSError as e:
				out("KILL DIR Error: " + itemName + " : " + e.strerror, -1)
							
		else:
			try:
				os.remove(itemName)
			except OSError as e:
				out("KILL FILE Error: " + itemName + " : " + e.strerror, -1)

def udpOut(s):
	try:
		udp.sendto((s + "\n").encode('ASCII'), (espIP, udpPort))
	except:
		out("udpOut Error", -1)		

def tcpOut(s):
	try:
		tcp.sendall((s + "\n").encode('ASCII'))
	except:
		out("tcpOut Error", -1)		

def getUdpString():
	try:
		data, address = udp.recvfrom(2048)
		if data:
			return(data.decode('ASCII')[:-1])
			
	except socket.timeout:
		return("")
		
def main(argv):
	global BASEDIR, espIP, VERB_LEVEL
	
	try:
		opts, args = getopt.getopt(argv, "hs:i:v:", ["ip=","ip=", "verbose="])
		
	except getopt.GetoptError:
		print(sys.argv[1])
		print(sys.argv[0] + ' -s <serverdir> -i <CMM2 IP> -v <verbose level>')
		sys.exit()

	for opt, arg in opts:
		if opt == '-h':
			print("Napoleon WiFi server " + VER)
			print()
			print(sys.argv[0] + ' -s <serverdir> -i <IP> -b <baudrate>')
			print('  <serverdir>')
			print('    base directory for NCserver, Napoleon Commander on CMM2 see just inside of this')
			print()
			print('  <IP>')
			print('    IP address of ESP on CMM2')
			print()
			print('  <verbose>')
			print('    verbose level (0=min, 3 = max)')
			print()
			
			sys.exit()
		 
		elif opt in ("-s", "--serverdir"):
			if arg == '/' or arg == '':
				print('Serverdir too dangerous (root dir of disk), using default')
			else:
				BASEDIR = arg
		 
		elif opt in ("-i", "--ip"):
			espIP = arg

		elif opt in ("-v", "--verbose"):
			if (int(arg) >= 0) and (int(arg) <= 3):
				VERB_LEVEL = int(arg)
if __name__ == "__main__":
	main(sys.argv[1:])

udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
udp.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
udp.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
udp.settimeout(1)
udp.bind((ncIP, udpPort))

tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
tcp.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

udpOut("NCudpServer")
out (sys.argv[0]  + " -s '" + BASEDIR + "' -i '" + espIP + "' -v " + str(VERB_LEVEL), -1)
out ('Napoleon WiFi Server ' + VER + ' is listening on ' + ncIP + ':' + str(udpPort), -1)
out("Looking for NC...", -1)
while (True):
	try:
		data, address = udp.recvfrom(10000)
		if data:
			if MODE == 0:
				sData = data.decode('ASCII')[:-1]
				if sData != "":
					out("<- '" + sData + "'", 1)
	
					#ESP on CMM2 found NCudpServer
					if sData == 'NConCMM2':
						NC_FOUND = 1
						out('Napoleon Commander found NCwifiServer', -1)
						udp.settimeout(None)
				
					#debug data
					elif sData[0] == '#':
						out("DEBUG: '" + sData[1:] + "'", 1)

					#life test
					elif sData[0] == '?':
						ACT_COMMAND = 'LIFE TEST'
						lifeTest()
						ACT_COMMAND = ''
		
					#local -> server
					elif sData[0] == 'W':
						ACT_COMMAND = 'WRITE DATA'
						writeFile(sData)
						ACT_COMMAND = ''

					#server -> local
					elif sData[0] == 'R':
						ACT_COMMAND = 'READ DATA'
						readFile(sData)
						ACT_COMMAND = ''

					#server -> server
					elif sData[0] == 'C':
						ACT_COMMAND = 'COPY ITEM'
						copyItem(sData)
						ACT_COMMAND = ''

					#list directory
					elif sData[0] == 'D':
						ACT_COMMAND = 'LIST DIR'
						listDir(sData)
						ACT_COMMAND = ''

					#traverse directory
					elif sData[0] == 'T':
						ACT_COMMAND = 'TRAVERSE DIR'
						traverseDir(sData)
						ACT_COMMAND = ''

					#server MKDIR
					elif sData[0] == 'M':
						ACT_COMMAND = 'MAKE DIR'
						makeDir(sData)
						ACT_COMMAND = ''

					#server RENAME
					elif sData[0] == 'N':
						ACT_COMMAND = 'RENAME ITEM'
						renameItem(sData)
						ACT_COMMAND = ''

					#server KILL or RMDIR (include subdirs)
					elif sData[0] == 'K':
						ACT_COMMAND = 'KILL ITEM'
						killItem(sData)
						ACT_COMMAND = ''
		
				else:
					udpOut("NCudpServer")
			
			else:
				if packNum < packCount:
					ctrlNum = int.from_bytes(data[0:2], byteorder='little')
					udpOut(str(packNum))
					if ctrlNum == packNum:
						buffer += data[2:]
						out("OK " + str(ctrlNum) + "=" + str(packNum), 2)
						packNum += 1

					else:
						out("LOST PACKET (expected " + str(packNum) + ", got " + str(ctrlNum) + ")", -1)
					
				else:
					ctrlNum = int.from_bytes(data[0:2], byteorder='little')
					udpOut(str(packNum))
					if ctrlNum == packNum:
						buffer += data[2:]
						out("OK " + str(ctrlNum) + "=" + str(packNum), 2)
						packNum += 1

					else:
						out("LOST PACKET (expected " + str(packNum) + ", got " + str(ctrlNum) + ")", -1)

				

				if VERB_LEVEL > 1:
						print("{:.0%} ".format(packNum/packCount), end = '', flush=True)
				
				#print(ctrlNum, packNum, packCount)		
				if packNum == packCount:
					udpOut('DONE')
					copyTime = time.perf_counter() - copyTime
					newFile = open(fileName, "wb")
					newFile.write(buffer)
					newFile.close
					MODE = 0
					ACT_COMMAND = ''	
					out('\nDONE in ' + str(round(copyTime, 1)) + ' sec (' + str(round(fileLen/copyTime/1024,1)) + ' kB/s)', 1)

	except socket.timeout:
		if ACT_COMMAND == '':
			if not NC_FOUND:
				#out("Looking for NC...", -1)
				udpOut("NCudpServer")
			
		else:
			out("NCudpServer timeout in '" + ACT_COMMAND + "'", -1)			
			if ACT_COMMAND == 'WRITE DATA':
				out("WRITE DATA canceled", -1)
				MODE = 0
				ACT_COMMAND = ''
