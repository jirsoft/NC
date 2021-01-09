#include <ESP8266WiFi.h>
#include <ESP8266mDNS.h>
#include <WiFiUdp.h>
#include <ArduinoOTA.h>
#include <NTPClient.h>
#include <WiFiUdp.h>
#include <Time.h>
#include <TimeLib.h>

const String ESPversion = "0.33";

char serByte;
char serMode = 0; // 0 = command mode, 1 = file mode
String serCommand = "";

const long utcOffsetInSeconds = 3600;
time_t CURRENT_TIME = now();
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", utcOffsetInSeconds, 60000);

unsigned int udpPort = 34701;
unsigned int dbgPort = 1313;
IPAddress udpIP;
boolean NCwifiServerFound = false;

WiFiUDP udp;
char udpRecBuffer[UDP_TX_PACKET_MAX_SIZE + 1];
char udpSendBuffer[UDP_TX_PACKET_MAX_SIZE + 1];
int udpSize;

void setup() {
  Serial.begin(691200); //921600
  serOut("\nBooting");
  serOut("ESP ready");
  
  // Port defaults to 8266
  // ArduinoOTA.setPort(8266);

  // Hostname defaults to esp8266-[ChipID]
  ArduinoOTA.setHostname("CMM2ESP");
  
  // No authentication by default
  // ArduinoOTA.setPassword("ESP");

  // Password can be set with it's md5 value as well
  // MD5(admin) = 21232f297a57a5a743894a0e4a801fc3
  // ArduinoOTA.setPasswordHash("21232f297a57a5a743894a0e4a801fc3");

  ArduinoOTA.onStart([]() {
    String type;
    if (ArduinoOTA.getCommand() == U_FLASH) {
      type = "sketch";
    } else { // U_FS
      type = "filesystem";
    }

    // NOTE: if updating FS this would be the place to unmount FS using FS.end()
    serOut("OTA started (" + type + ")");
  });
  ArduinoOTA.onEnd([]() {
    serOut("\nOTA finished");
  });
  ArduinoOTA.onProgress([](unsigned int progress, unsigned int total) {
    //Serial.printf("Progress: %u%%\r", (progress / (total / 100)));
  });
  ArduinoOTA.onError([](ota_error_t error) {
    Serial.printf("Error[%u]: ", error);
    if (error == OTA_AUTH_ERROR) {
      Serial.println("Auth Failed");
    } else if (error == OTA_BEGIN_ERROR) {
      Serial.println("Begin Failed");
    } else if (error == OTA_CONNECT_ERROR) {
      Serial.println("Connect Failed");
    } else if (error == OTA_RECEIVE_ERROR) {
      Serial.println("Receive Failed");
    } else if (error == OTA_END_ERROR) {
      Serial.println("End Failed");
    }
  });
  Serial.setTimeout(3000);
  WiFi.disconnect();
}

String getTime()
{
  String h = String(hour(CURRENT_TIME));
  if (h.length() < 2)
    h = "0" + h;
  String m = String(minute(CURRENT_TIME));
  if (m.length() < 2)
    m = "0" + m;
  String s = String(second(CURRENT_TIME));
  if (s.length() < 2)
    s = "0" + s;

  return(h + ":" + m + ":" + s);
}

String getDate()
{
  String m = String(month(CURRENT_TIME));
  if (m.length() < 2)
    m = "0" + m;
  String d = String(day(CURRENT_TIME));
  if (d.length() < 2)
    d = "0" + d;
  String y = String(year(CURRENT_TIME));
  
  return(y + "-" + m + "-" + d);
}

void serOut(String s)
{
  Serial.print(s + '\n');
}   

void speedTest()
{
  long dataLen = random(50000, 150000);
  long daLe = dataLen;
  long crb, crc = 0;
  long partLen = 250;
  int partNum = dataLen / partLen, partRem = dataLen % partLen;
  byte buf[partLen];
  for (int i = 0; i < partLen; i++)
  {
    buf[i] = random(0, 256);
    crc = (crc + buf[i]) & 0xFF;
  }
  crb = crc;
  crc = 0;
  
  unsigned long tim = millis(); 
  serOut(String(dataLen) + "," + String(partLen) + "," + String(partNum) + "," + String(partRem));
  int part = 0;
  while (dataLen >= partLen)
  {
    Serial.write(buf, partLen);
    dataLen -= partLen;
    crc = (crc + crb) & 0xFF;
    if(!Serial.readStringUntil('\n').equalsIgnoreCase("OK"))
      return;
  }
  if (dataLen > 0)
  {
    Serial.write(buf, dataLen);
    for (int i = 0; i < dataLen; i++)
      crc = (crc + buf[i]) & 0xFF;
    if(!Serial.readStringUntil('\n').equalsIgnoreCase("OK"))
      return;
  }
  tim = millis() - tim;
  double spd = 1000 * daLe / 1024 / tim;
  serOut("Write test OK, " + String(daLe) + " bytes written, speed = " + String(spd, 2) + "kB/s, CRC8 = " + String(crc));
  tim = millis();
  daLe = Serial.readStringUntil('\n').toInt();
  dataLen = daLe;
  partLen = 1250;
  byte buf2[partLen];
  while (dataLen > 0)
  {
    dataLen -= Serial.readBytes(buf2, min(partLen, dataLen));
  }
  tim = millis() - tim;
  spd = 1000 * daLe / 1024 / tim;
  serOut("Read test OK, " + String(daLe) + " bytes read, speed = " + String(spd, 2) + "kB/s");  
}        

void udpOut(String s)
{
  if (NCwifiServerFound)
  {
    s.toCharArray(udpSendBuffer, s.length());
    udpSendBuffer[s.length() + 1] = 0;
    udp.beginPacket(udpIP, udpPort);
    udp.write(udpSendBuffer, s.length());
    udp.endPacket();
  }
}

void udpDebug(String s)
{
  if (NCwifiServerFound)
  {
    s.toCharArray(udpSendBuffer, s.length());
    udpSendBuffer[s.length() + 1] = 0;
    udp.beginPacket(udpIP, dbgPort);
    udp.write(udpSendBuffer, s.length());
    udp.endPacket();
  }
}

String getUdpString()
{
  udpSize = 0;
  unsigned long timeOut = millis();
  String received = "";
  
  while (!udpSize and (millis() - timeOut) < 3000)
    udpSize = udp.parsePacket();
  if (udpSize)
  {
    int n = udp.read(udpRecBuffer, UDP_TX_PACKET_MAX_SIZE);
    
    received = String(udpRecBuffer);
    received.remove(n);
  }
  return(received);  
}

void testUdpPacket()
{
  udpSize = udp.parsePacket();
  if (udpSize)
  {
    //serOut("Received packet of size " + String(udpSize) + " from " + udp.remoteIP().toString() + ":" + String(udp.remotePort()));

    int n = udp.read(udpRecBuffer, UDP_TX_PACKET_MAX_SIZE);
    String received = (char *)udpRecBuffer;
    received.remove(n);
    if (received.equalsIgnoreCase("NCudpServer\n"))
    {
      if (!NCwifiServerFound or udpIP != udp.remoteIP())
      {
        NCwifiServerFound = true;
        udpIP = udp.remoteIP();
        udpOut("NConCMM2\n");
        serOut("NCudpServer found on " + udpIP.toString() + ":" + String(udpPort));
      }
    }
    else
      serOut(received);

    //sendUdpCommand("OK\n");
  }  
}

void ncD()
{
  String dir = getUdpString();
  if (dir != "")
  {
    int count = dir.substring(1, dir.indexOf('|')).toInt();
    
    serOut(dir);

    for (int i = 0; i < count; i++)
    {
      if (Serial.readStringUntil('\n') == "NEXT")
        udpOut("NEXT\n");
      serOut(getUdpString());
    }
  }
  else
    serOut("ncD timeout");
}

void ncW(String ww)
{
  int fileLen = ww.substring(ww.indexOf('|') + 1).toInt();
  //udpOut("Max size is " + String(UDP_TX_PACKET_MAX_SIZE) + "\n");
  unsigned int maxPak = UDP_TX_PACKET_MAX_SIZE;
  int pakCount = fileLen / UDP_TX_PACKET_MAX_SIZE;
  int pakRem = fileLen % UDP_TX_PACKET_MAX_SIZE;
  int pakSize;

  udpOut("#" + String(fileLen) + "," + String(pakCount) + "," + String(pakRem) + "\n");
  udpOut("W" + ww + "\n");
  serOut(getUdpString());
  
  for (int i = 0; i < pakCount; i++)
  {
    pakSize = 0;
    while (pakSize < UDP_TX_PACKET_MAX_SIZE)
      if (Serial.available() > 0)
        pakSize += Serial.readBytes(udpSendBuffer + pakSize, min(Serial.available(), UDP_TX_PACKET_MAX_SIZE - pakSize));
    udpSendBuffer[pakSize + 1] = 0;
    udp.beginPacket(udpIP, udpPort);
    udp.write(udpSendBuffer, pakSize);
    udp.endPacket();    
  }

  if (pakRem > 0)
  {
    pakSize = 0;
    while (pakSize < pakRem)
      if (Serial.available() > 0)
        pakSize += Serial.readBytes(udpSendBuffer + pakSize, min(Serial.available(), pakRem - pakSize));
    udpSendBuffer[pakSize + 1] = 0;
    udp.beginPacket(udpIP, udpPort);
    udp.write(udpSendBuffer, pakSize);
    udp.endPacket();        
  }
  serOut(getUdpString());
}

void ncR(String ww)
{
  String fileName = ww.substring(0, ww.indexOf('|'));
  int partLen = ww.substring(ww.indexOf('|') + 1).toInt();
  int udpSize;
  unsigned int maxPak = 32 * partLen;
  int pakSize;
  unsigned long timeOut;
  String received;
  
  //udpOut("#" + fileName + "|" + String(partLen) + "\n");
  //udpDebug("#" + fileName + "|" + String(partLen) + "\n");
  udpOut("R" + fileName + "|" + String(maxPak) + "\n");
  //udpDebug("R" + fileName + "|" + String(maxPak) + "\n");

  String rdy = getUdpString();
  int fileLen = rdy.substring(rdy.indexOf('|') + 1).toInt();
  int pakCount = fileLen / maxPak;
  int pakRem = fileLen % maxPak;
  int partCount = fileLen / partLen;
  int partRem = fileLen % partLen;
  
  serOut(rdy);
  //udpDebug("fileLen=" + String(fileLen) + ", pakCount=" + String(pakCount) + ", pakRem=" + String(pakRem) + '\n');
  //udpDebug("partLen=" + String(partLen) + ", partCount=" + String(partCount) + ", partRem=" + String(partRem) + '\n');
  if (Serial.readStringUntil('\n') == "START")
  {
    udpOut("START\n");
    for (int i = 0; i < pakCount; i++)
    {
      udpOut("NEXT\n");
      udpSize = 0;
      timeOut = millis();
      while (!udpSize and (millis() - timeOut) < 3000)
        udpSize = udp.parsePacket();
      if (udpSize)
      {
        pakSize = udp.read(udpRecBuffer, maxPak);
      
        for (int j = 0; j < 32; j++)
          if (Serial.readStringUntil('\n') == "NEXT")
            Serial.write(udpRecBuffer + (j * partLen), partLen);
      }
    }

    if (pakRem > 0)
    {
      udpOut("NEXT\n");
      udpSize = 0;
      timeOut = millis();
      while (!udpSize and (millis() - timeOut) < 3000)
        udpSize = udp.parsePacket();
      if (udpSize)
      {
        pakSize = udp.read(udpRecBuffer, pakRem);
        //udpDebug("pakSize = " + String(pakSize) + '\n');
               
        for (int j = 0; j < (partCount - (32 * pakCount)); j++)
          if (Serial.readStringUntil('\n') == "NEXT")
            Serial.write(udpRecBuffer + (j * partLen), partLen);
        if (partRem > 0)
          if (Serial.readStringUntil('\n') == "NEXT")
            Serial.write(udpRecBuffer + (pakSize - partRem), partRem);
      }
    }

    udpOut(Serial.readStringUntil('\n') + "\n");
    
  }
}

void ncT()
{
  String dir = getUdpString();
  if (dir != "")
  {
    int count = dir.substring(1, dir.indexOf('|')).toInt();
    
    serOut(dir);

    for (int i = 0; i < count; i++)
    {
      if (Serial.readStringUntil('\n') == "NEXT")
        udpOut("NEXT\n");
      serOut(getUdpString());
    }
  }
  else
    serOut("ncT timeout");
}
void loop() {
  ArduinoOTA.handle();
  timeClient.update();
  CURRENT_TIME = now();

  if (Serial.available() > 0)
  {
    // read the incoming byte:
    if (serMode == 0)
    {
      serByte = Serial.read();
      if (serByte == '@')
      {
        serCommand = Serial.readStringUntil('\n');
        serByte = '\n';
      }
    }

    else  
    {     
      Serial.print("I received: ");
      Serial.println(serByte, HEX);
    }
  }

  if (serCommand.length() > 0)
  {
    if (serCommand.equalsIgnoreCase("datetime"))
      serOut(getDate() + " " + getTime());
      
    else if (serCommand.equalsIgnoreCase("speedtest"))
      speedTest();
          
    else if (serCommand.equalsIgnoreCase("ver"))
      serOut("ESP v" + ESPversion);

    else if (serCommand.equalsIgnoreCase("mac"))
      serOut(WiFi.macAddress());

    else if (serCommand.equalsIgnoreCase("netinfo"))
    {
      if (WiFi.status() == WL_CONNECTED)
      {
        String netInfo = WiFi.SSID() + "," + WiFi.BSSIDstr() + "," + String(WiFi.RSSI()) + "," + WiFi.gatewayIP().toString() + "," + WiFi.subnetMask().toString() + "," + WiFi.localIP().toString();
        serOut(netInfo);
      }
      else
        serOut("");
    }

    else if (serCommand.equalsIgnoreCase("scan"))
    {
      int countNet = WiFi.scanNetworks();
      serOut(String(countNet) + " networks found");
      if (countNet > 0)
        for (int i = 0; i < countNet; ++i)
          serOut(String(i) + "," + WiFi.SSID(i) + "," + WiFi.BSSIDstr(i) + "," + String(WiFi.RSSI(i)));
    }

    else if (serCommand.equalsIgnoreCase("disconnect"))
    {
      WiFi.disconnect();
      serOut("Disconnected");
    }

    else if (serCommand.equalsIgnoreCase("NC_?"))
    {
      if (WiFi.status() == WL_CONNECTED)
        udpOut("?\n");
    }
    
    else if (serCommand.startsWith("NC_W"))
    {
      if (WiFi.status() == WL_CONNECTED)
      {
        ncW(serCommand.substring(4));
      }
    }

    else if (serCommand.startsWith("NC_R"))
    {
      if (WiFi.status() == WL_CONNECTED)
      {
        ncR(serCommand.substring(4));
      }
    }

    else if (serCommand.startsWith("NC_C"))
    {
      if (WiFi.status() == WL_CONNECTED)
      {
        udpOut("C" + serCommand.substring(4) + "\n");
        serOut(getUdpString());
      }
    }

    else if (serCommand.startsWith("NC_D"))
    {
      if (WiFi.status() == WL_CONNECTED)
      {
        udpOut("D" + serCommand.substring(4) + "\n");
        ncD();
      }
    }

    else if (serCommand.startsWith("NC_T"))
    {
      if (WiFi.status() == WL_CONNECTED)
      {
        udpOut("T" + serCommand.substring(4) + "\n");
        ncT();
      }
    }

    else if (serCommand.startsWith("NC_M"))
    {
      if (WiFi.status() == WL_CONNECTED)
      {
        udpOut("M" + serCommand.substring(4) + "\n");
        serOut(getUdpString());
      }
    }

    else if (serCommand.startsWith("NC_N"))
    {
      if (WiFi.status() == WL_CONNECTED)
        udpOut("N" + serCommand.substring(4) + "\n");
    }

    else if (serCommand.startsWith("NC_K"))
    {
      if (WiFi.status() == WL_CONNECTED)
        udpOut("K" + serCommand.substring(4) + "\n");
    }

    else if (serCommand.substring(0, 8).equalsIgnoreCase("connect(") && serCommand.endsWith(")"))
    {
      String ssid = serCommand.substring(8, serCommand.length() - 1);
      int pos = ssid.lastIndexOf(",");
      if (pos >= 0)
      {
        String pass = ssid.substring(pos + 1);
        ssid.remove(pos);

        if (WiFi.status() == WL_CONNECTED)
          WiFi.disconnect();
        
        WiFi.begin(ssid, pass);
        if (WiFi.waitForConnectResult() == WL_CONNECTED)
        {
          ArduinoOTA.begin();
          timeClient.begin();
          timeClient.update();
          setTime(timeClient.getEpochTime());
          serOut("Connected to " + WiFi.SSID() + "," + WiFi.BSSIDstr() + "," + String(WiFi.RSSI()));
          udp.begin(udpPort);
        }
        else
          serOut("Not connected to '" + ssid + "'/'" + pass + "'");        
      }
    }
    
    else if (serCommand == "reboot")
    {
      serOut("Rebooting...");
      ESP.restart();
    }
    
    else
      serOut("Unknown command '" + serCommand + "'");

    serCommand = "";
  }

  testUdpPacket();

  yield();
}
