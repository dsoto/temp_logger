#include <LiquidCrystal.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <SPI.h>

// pin for communicating with temperature sensor
#define ONE_WIRE_BUS 9
// temperature sensor objects
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

// LCD object
LiquidCrystal lcd(8, 7, 6, 5, 4, 3);

const int CS = 10; // chip select pin
unsigned int val;
unsigned int digit;

const int sampleIntervalMinutes = 15;

// definition of degree glyph.  ones are selected pixels
byte degreeGlyph[8] = {
    B01100,
    B10010,
    B10010,
    B01100,
    B00000,
    B00000,
    B00000,
    B00000
};

void setup(void) {
    // serial stuff
    Serial.begin(9600);
    Serial.println("templogger begin");
    // create degree glyph for LCD
    lcd.createChar(0, degreeGlyph);
    // initialize LCD with dimensions
    lcd.begin(16,2);
    // initialize temp sensor
    sensors.begin();


   SPI.begin();
   SPI.setBitOrder(MSBFIRST);
   SPI.setDataMode(SPI_MODE3);
   pinMode(10, OUTPUT);



}

// this function encapsulates a write to the real time clock
void writeToSPI(int instruction, int value){
  digitalWrite(CS, LOW);
  SPI.transfer(instruction);
  SPI.transfer(value);
  digitalWrite(CS, HIGH);
}

// converts a binary coded decimal to a decimal
int convertBCDtoDEC(int valBCD){
  int valDEC;
  valDEC = ((valBCD & 0xF0) >> 4) * 10;
  valDEC += valBCD & 0x0F;
  return(valDEC);
}

// reads the BCD at address on the RTC and returns a converted int value
// representing that piece of the date
int readTimeValue(int address){
  digitalWrite(CS, LOW);
  SPI.transfer(address);
  int valBCD = SPI.transfer(0x00);
  digitalWrite(CS, HIGH);
  int valDEC = convertBCDtoDEC(valBCD);
  return(valDEC);
}

// reads the entire yymmddhhmmss values from the RTC
void readTime(int * year,
              int * month,
              int * day,
              int * hour,
              int * minute,
              int * second){
  *year    = readTimeValue(0x06);
  *month   = readTimeValue(0x05);
  *day     = readTimeValue(0x04);
  *hour    = readTimeValue(0x02);
  *minute  = readTimeValue(0x01);
  *second  = readTimeValue(0x00);
}

// value is written to datetime string in two digits and the string address index is incremented
void placeDigitsInArray(char * datetime, int * index, int value){
  datetime[(*index)++] = (value / 10) + 0x30;
  datetime[(*index)++] = (value % 10) + 0x30;
}

// using the values passed in, an 18 digit zero terminated string is constructed and passed back
char * constructDateString(int year,
                           int month,
                           int day,
                           int hour,
                           int minute,
                           int second){
  char datetime[18] = {0};
  int i = 0;
  placeDigitsInArray(datetime, &i, year);
  datetime[i++] = '/';
  placeDigitsInArray(datetime, &i, month);
  datetime[i++] = '/';
  placeDigitsInArray(datetime, &i, day);
  datetime[i++] = ' ';
  placeDigitsInArray(datetime, &i, hour);
  datetime[i++] = ':';
  placeDigitsInArray(datetime, &i, minute);
  datetime[i++] = ':';
  placeDigitsInArray(datetime, &i, second);
  datetime[i++] = 0;
  return(datetime);
}

void writeRTC(char * dateString, int * index, int address){
  int val = 0;
  val |= (dateString[(*index)++] - 0x30) << 4;
  val |= (dateString[(*index)++] - 0x30);
  writeToSPI(address, val);
}

void setTime(char * dateString){
  int i = 0;
  writeRTC(dateString, &i, 0x86);
  writeRTC(dateString, &i, 0x85);
  writeRTC(dateString, &i, 0x84);
  writeRTC(dateString, &i, 0x82);
  writeRTC(dateString, &i, 0x81);
  writeRTC(dateString, &i, 0x80);
}

float readTemperature(){
    sensors.requestTemperatures();
    float tempC = sensors.getTempCByIndex(0);
    return tempC;
}


void printTemperature() {
    sensors.requestTemperatures();
    float tempC = sensors.getTempCByIndex(0);
    // print to lcd
    lcd.setCursor(1, 0);
    lcdPrintTemp(tempC);
    // janky print to serial
    //Serial.print(millis());
    Serial.print("  ");
    Serial.print(tempC);
    Serial.print("  ");
    lcd.write(0);
    lcd.print("C  ");
    lcdPrintTemp(DallasTemperature::toFahrenheit(tempC));
    // janky print to serial redux
    Serial.println(DallasTemperature::toFahrenheit(tempC));
    lcd.write(0);
    lcd.print("F");
}

// prints double with 1 decimal place
void lcdPrintTemp(double val) {
    // print integer part
    lcd.print(int(val));
    lcd.print(".");
    // subtract off integer
    val = val - int(val);
    // multiply by ten, truncate, and print
    val = val * 10;
    lcd.print(int(val));
}

// prints integer with leading zero if necessary
void lcdPrintPadded(int val) {
    if (val <= 9) lcd.print("0");
    lcd.print(val,DEC);
}

void loop(void) {

    int year;
    int month;
    int day;
    int hour;
    int minute;
    int second;
    //char datetime[20] = {0};

    // read time from RTC and store in variables
    readTime(&year, &month, &day, &hour, &minute, &second);
    //lcd.setCursor(0,0);
    //lcd.print(second);

    // test if time is a multiple of sampleIntervalMinutes.
    // if yes, write to serial.
    if ((minute % sampleIntervalMinutes == 0) and (second == 0)){
        // get date and write to serial
        // fixme: i need to allocate datestring (ticket 2)
        char * datetime = constructDateString(year, month, day, hour, minute, second);
        Serial.write(datetime);

        // read temp and write to serial
        float tempC = readTemperature();
        Serial.print(",");
        Serial.print(tempC);
        Serial.println();

        // write date and temp to lcd
        lcd.setCursor(2,0);
        lcdPrintPadded(month);
        lcd.print("/");
        lcdPrintPadded(day);
        lcd.setCursor(9,0);
        lcdPrintPadded(hour);
        lcd.print(":");
        lcdPrintPadded(minute);

        lcd.setCursor(1,1);
        lcd.print(tempC,1);
        lcd.write(0);
        lcd.print("C  ");
        float tempF = (tempC * 9/5) + 32;
        lcd.print(tempF,1);
        lcd.write(0);
        lcd.print("F");

  }
  delay(1000);

  // look for string of length 12 YYMMDDHHMMSS on serial and then use to set time
  char dateString[13];
  if (Serial.available() >= 12){
    for (int i=0; i<12; i++){
      dateString[i] = Serial.read();
    }
    dateString[12] = 0;
    Serial.print("received string ");
    Serial.write(dateString);
    Serial.println();
    setTime(dateString);
  }
  else {
  // if serial port has less than 12, clear it out
  while (Serial.available() > 0){
    Serial.read();
    }
}

}
