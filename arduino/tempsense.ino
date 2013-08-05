#include <OneWire.h>
#include <DallasTemperature.h>

#include <Wire.h>
#include <Adafruit_MCP23017.h>
#include <Adafruit_RGBLCDShield.h>

#include <TimedAction.h>

#include <EEPROM.h>

#include "RTClib.h"

RTC_DS1307 RTC;

#define TIME_TEMP "timestamp temp"
#define ENABLE_DISP "enable display"
#define DISABLE_DISP "disable display"
#define HELP "help"

#define ONE_WIRE_BUS 2
#define DEBUG 1

#define OFF 0x0
#define RED 0x1
#define YELLOW 0x3
#define GREEN 0x2
#define TEAL 0x6
#define BLUE 0x4
#define VIOLET 0x5
#define WHITE 0x7

#if DEBUG
#define TEMPERATURE_TIMEOUT 1000
#else
#define TEMPERATURE_TIMEOUT 1000*60*60
#endif

#define SHOW_CURRENT_TEMP 0
#define SHOW_PREVIOUS_TEMP 1
#define SHOW_NEXT_TEMP 2

#define NEXT_LOG_POINTER 0
#define CURRENT_LOG_POINTER 1
#define TOTAL_LOGS_POINTER 2
#define LOG_START_INDEX 31

OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
Adafruit_RGBLCDShield lcd = Adafruit_RGBLCDShield();
int nextLog, currentLog, totalLogs;
float lastTemp;
uint8_t lastReadButton = 0;
boolean displayOn = true;
TimedAction temperatures = TimedAction(TEMPERATURE_TIMEOUT, readDisplayAndLogTemperature);

void setup(void) {
  Serial.begin(9600);
  sensors.begin();
  lcd.begin(16, 2);
  lcd.setBacklight(GREEN);
  Wire.begin();
  RTC.begin();
  
  if(! RTC.isrunning()) {
    Serial.println("RTC is NOT running!!");
    //RTC.adjust(DateTime(__DATE__, __TIME__));
  } else {
    Serial.println("RTC is ready");
  }
  Serial.print("You can see available commands by sending \"");
  Serial.print(HELP);
  Serial.println("\" over the serial connection");
  while(Serial.available() > 0) {
    Serial.read();
  }
}

void loop() {
  readButtons();
  if(displayOn) {
    temperatures.check();
  }
  if(Serial.available() > 0) {
    delay(100);
    handleMessage(readline());
  }
}

void readDisplayAndLogTemperature() {
  float temp = readTemperature();

  float delta = temp - lastTemp;
  // Serial.print("Delta: "); Serial.println(delta);

  if (abs(delta) > 0.5) {
    lcd.clear();
    displayTemperature(temp);
    enableBacklight(temp);
    lastTemp = temp;
  }

  // Serial.print("Temperature for device is: ");
  // Serial.print(temp);
  // Serial.println("deg C");
}

void displayTemperature(float temp) {
  // Serial.print("Is the diplay on: ");
  // Serial.println(displayOn);
  lcd.setCursor(0, 0);
  lcd.print("Temp is ");
  lcd.print(temp);
  lcd.print((char)223);
  lcd.print("C");
  lcd.setCursor(0, 1);
}

void enableBacklight(float temp) {
  lcd.setCursor(0, 1);
  if( temp < 18) {
    lcd.setBacklight(BLUE);
    lcd.print("2 cold for yeast");
  } else if (temp > 22) {
    lcd.setBacklight(RED);
    lcd.print("2 warm for yeast");
  } else {
    lcd.setBacklight(GREEN);
  }
}

void disableBacklight() {
  displayOn = false;
  lastTemp = lastTemp - 100;
  lcd.clear();
  lcd.setBacklight(OFF);
}

float readTemperature() {
  // if(DEBUG) { return random(1, 100); }
  sensors.requestTemperatures();

  return sensors.getTempCByIndex(0);
}

void readButtons() {
  uint8_t buttons = lcd.readButtons();
  if (buttons == lastReadButton) {
    return;
  }

  lastReadButton = buttons;

  if(buttons & BUTTON_SELECT) {
    toggleDisplay();
  }
  if(buttons & BUTTON_UP) {
    spewLogs();
  }
  if(buttons & BUTTON_LEFT) {
    setState(SHOW_PREVIOUS_TEMP);
  }
  if(buttons & BUTTON_RIGHT) {
    setState(SHOW_NEXT_TEMP);
  }
  if(buttons & BUTTON_DOWN) {
    setState(SHOW_CURRENT_TEMP);
  }
}

void toggleDisplay() {
  if(displayOn) {
    displayOn = false;
    lcd.setBacklight(OFF);
  } else {
    displayOn = true;
  }
}

void spewLogs() {
  int start = LOG_START_INDEX;
  Serial.print("Start Index: ");
  Serial.print(start);
  Serial.print("\tEnd Index: ");
  Serial.println(nextLog);
  for(int i = LOG_START_INDEX; i < nextLog; i++) {
    int l = EEPROM.read(i);
    Serial.print("Value for log entry ");
    Serial.print(i);
    Serial.print(" was ");
    Serial.println(l);
  }
}

String getTime() {
    DateTime now = RTC.now();
    String time = "";
    time = time +  tostr16(now.year()) + "/" + tostr(now.month()) + "/" + tostr(now.day());
    time = time + " " + tostr(now.hour()) + ":" + tostr(now.minute()) + ":";
    if(now.second() < 10) {
      time = time + "0";
    }
    time = time + tostr(now.second());
    return time;
}

String readline() {
  String result = "";
  char nextChar;
  while(Serial.available() > 0) {
    nextChar = Serial.read();
    if(nextChar == '\n') { break; }
    result.concat(nextChar);
  }
  return result;
}
String tostr16(uint16_t val) {
  return String(val, DEC);
}

String tostr(uint8_t val) {
  return String(val, DEC);
}
  
void setState(int state) {
  if(state == SHOW_CURRENT_TEMP){
    Serial.println("DOWN was just hit");
  }
  if(state == SHOW_NEXT_TEMP) {
    Serial.println("RIGHT was just hit");
  }
  if(state == SHOW_PREVIOUS_TEMP){
    Serial.print("LEFT was just hit");
  }
}

void handleMessage(String message) {
  if(message == TIME_TEMP) {
    logTimeAndTemp();
  } else if (message == ENABLE_DISP) {
    displayOn = true;
  } else if (message == DISABLE_DISP) {
    disableBacklight();
  } else if (message == HELP){
    Serial.println("Available Commands Are");
    Serial.println("--------------------------------------------------------------------------");
    Serial.print(ENABLE_DISP); Serial.println("\t\tTurns display on shows current temperature");
    Serial.print(DISABLE_DISP); Serial.println("\t\tTurns display off");
    Serial.print(TIME_TEMP); Serial.println("\t\tFetches current temperature reading and logs it with a timestamp");
    Serial.println("--------------------------------------------------------------------------");
    Serial.println("Anything else will be echoed back with a timestamp");
  } else {
    echo(message);
  }
}

void logTimeAndTemp() {
  Serial.print(getTime());
  Serial.print("|");
  Serial.println(readTemperature());
}

void echo(String message) {
  Serial.print("[");
  Serial.print(getTime());
  Serial.print("]");
  Serial.print("Echo: ");
  Serial.println(message);
}
