#!/usr/bin/python3
#Napoleon Server
#Simple server for CMM2  Napoleon Commander over network
#JirSoft, 2020
VER = 'v0.13'

import socket
from datetime import datetime
from pathlib import Path
import sys, getopt
import os
import shutil
import time

espIP = "10.0.13.180"
ncPort = 34701

hostname = socket.gethostname()
ncIP = socket.gethostbyname(hostname)

#used as server root, this server has no other access, can be given as command lineargument
BASEDIR = "/Users/jirsoft/Documents/Maximite/NCserver/"
VERB_LEVEL = 2

LF = '\n'
CURDIR = ""
MODE = 0

def out(s, level):
	if VERB_LEVEL > level:
		print(s)

def convert_date(timestamp):
    d = datetime.utcfromtimestamp(timestamp)
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
	global MODE, copyTime, remain, buffer, fileLen, fileName
	
	fileName = BASEDIR + CURDIR + d.split('|')[0][1:]
	fileLen = int(d.split('|')[1])
	out('LOCAL to SERVER ' + fileName + ', [' + str(fileLen) + ' bytes]', 0)
	remain = fileLen
	buffer = bytes()
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
		out('SERVER to LOCAL ' + fileName + ', [' + str(fileLen) + ' bytes = ' + str(partNum) + '*' + str(partLen) + '+' + str(partRem) + ']', 0)
		newFile = open(fileName, "rb")
		buffer = newFile.read()
		newFile.close
		bufPos = 0
		ret = 'READY|' + str(fileLen)
		out(ret, 1)
		udpOut(ret)

		if getUdpString() == 'START':
			out('START ... ', 1)					
			copyTime = time.perf_counter()
			
			if partNum > 0:
				for i in range(1, partNum + 1):
					srd = getUdpString()
					if srd == 'NEXT':
						sock.sendto(buffer[bufPos:bufPos + partLen], (espIP, ncPort))
						bufPos += partLen
					else:
						out("SERVER to LOCAL Error '" + srd + "'", -1)
			
			if partRem > 0:
				srd = getUdpString()
				if srd == 'NEXT':
					sock.sendto(buffer[bufPos:], (espIP, ncPort))
				else:
					out("SERVER to LOCAL (REM) Error '" + srd + "'", -1)
											
			copyTime = time.perf_counter() - copyTime

			if getUdpString() == 'DONE':
				out('DONE in ' + str(round(copyTime, 1)) + ' sec (' + str(round(fileLen/copyTime/1024,1)) + ' kB/s)', 0)

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
	CURDIR = d[4:]
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
	out(ret, 1)
	udpOut(ret)

	if len(CURDIR) > 0:
		ret = 'D..|[ GO UP ]|'
		out(ret, 1)
		if getUdpString() == 'NEXT':
			udpOut(ret)

	for item in dir.iterdir():
		info = item.stat()
		mtime = convert_date(info.st_mtime)
		if item.is_file():
			fsize = str(info.st_size)
			ret = 'F' + item.name + '|' + fsize + "|" + mtime

		else:						
			ret = 'D' + item.name + '|DIRECTORY|' + mtime
		out(ret, 1)
		if getUdpString() == 'NEXT':
			udpOut(ret)

def traverseDir(d):
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
		sock.sendto((s + "\n").encode('ASCII'), (espIP, ncPort))
	except:
		out("udpOut Error", -1)		

def getUdpString():
	try:
		data, address = sock.recvfrom(2048)
		if data:
			return(data.decode('ASCII')[:-1])
			
	except socket.timeout:
		return("")
		
def main(argv):
	global BASEDIR, espIP, VERB_LEVEL
	
	try:
		opts, args = getopt.getopt(argv, "hs:i:v:", ["ip=","ip=", "verbose="])
		
	except getopt.GetoptError:
		print(sys.argv[0] + ' -s <serverdir> -i <CMM2 IP> -v <verbose level>')
		sys.exit()

	for opt, arg in opts:
		if opt == '-h':
			print("Napoleon UDP server " + VER)
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

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
sock.settimeout(5)
sock.bind((ncIP, ncPort))

udpOut("NCudpServer")
out ("Napoleon UDP Server started as:", -1)
out (sys.argv[0]  + " -s '" + BASEDIR + "' -i '" + espIP + "' -v " + str(VERB_LEVEL), -1)
out('and is listening on ' + ncIP + ':' + str(ncPort), -1)

while (True):
	try:
		data, address = sock.recvfrom(10000)
		if data:
			if MODE == 0:
				sData = data.decode('ASCII')[:-1]
				if sData != "":
					out("<- '" + sData + "'", 0)
	
					#ESP on CMM2 found NCudpServer
					if sData == 'NConCMM2':
						out('Napoleon Commander found NCudpServer', -1)
						sock.settimeout(None)
				
					#debug data
					elif sData[0] == '#':
						out("DEBUG: '" + sData[1:] + "'", -1)

					#life test
					elif sData[0] == '?':
						lifeTest()
		
					#local -> server
					elif sData[0] == 'W':
						writeFile(sData)

					#server -> local
					elif sData[0] == 'R':
						readFile(sData)

					#server -> server
					elif sData[0] == 'C':
						copyItem(sData)

					#list directory
					elif sData[0] == 'D':
						listDir(sData)

					#traverse directory
					elif sData[0] == 'T':
						traverseDir(sData)

					#server MKDIR
					elif sData[0] == 'M':
						makeDir(sData)

					#server RENAME
					elif sData[0] == 'N':
						renameItem(sData)

					#server KILL or RMDIR (include subdirs)
					elif sData[0] == 'K':
						killItem(sData)
		
				else:
					udpOut("NCudpServer")
			
			else:
				toRead = min(len(data), remain)
				buffer += data
				remain -= toRead
				if remain <= 0:
					udpOut('DONE')
					copyTime = time.perf_counter() - copyTime
					newFile = open(fileName, "wb")
					newFile.write(buffer)
					newFile.close
					MODE = 0	
					out('DONE in ' + str(round(copyTime, 1)) + ' sec (' + str(round(fileLen/copyTime/1024,1)) + ' kB/s)', 0)

	except socket.timeout:
		udpOut("NCudpServer")
