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

void writeToSPI(int instruction, int value){
  digitalWrite(CS, LOW);
  SPI.transfer(instruction);
  SPI.transfer(value);
  digitalWrite(CS, HIGH);
}

void setTime(String response){
  // year
  val = 0;
  int i = 0;
  digit = response.charAt(i++) - 0x30;
  val |= digit << 4;
  digit = response.charAt(i++) - 0x30;
  val |= digit;
  writeToSPI(0x86, val);

  // month
  val = 0;
  digit = response.charAt(i++) - 0x30;
  val |= digit << 4;
  digit = response.charAt(i++) - 0x30;
  val |= digit;
  writeToSPI(0x85, val);

  // day
  val = 0;
  digit = response.charAt(i++) - 0x30;
  val |= digit << 4;
  digit = response.charAt(i++) - 0x30;
  val |= digit;
  writeToSPI(0x84, val);

  // hour
  val = 0;
  digit = response.charAt(i++) - 0x30;
  val |= digit << 4;
  digit = response.charAt(i++) - 0x30;
  val |= digit;
  writeToSPI(0x82, val);

  // minute
  val = 0;
  digit = response.charAt(i++) - 0x30;
  val |= digit << 4;
  digit = response.charAt(i++) - 0x30;
  val |= digit;
  writeToSPI(0x81, val);

  // seconds
  val = 0;
  digit = response.charAt(i++) - 0x30;
  val |= digit << 4;
  digit = response.charAt(i++) - 0x30;
  val |= digit;
  writeToSPI(0x80, val);
}

String readTimeToString(){
  String time = "";

  // year
  /*
  digitalWrite(10, LOW);
  SPI.transfer(0x06);
  val = SPI.transfer(0x00);
  digitalWrite(10, HIGH);
  digit = (val & 0xF0) >> 4;
  time.concat(digit);
  digit = (val & 0x0F);
  time.concat(digit);
  time.concat('/');
  */

  // month
  digitalWrite(10, LOW);
  SPI.transfer(0x05);
  val = SPI.transfer(0x00);
  digitalWrite(10, HIGH);
  digit = (val & 0xF0) >> 4;
  time.concat(digit);
  digit = (val & 0x0F);
  time.concat(digit);
  time.concat('/');

  // day
  digitalWrite(10, LOW);
  SPI.transfer(0x04);
  val = SPI.transfer(0x00);
  digitalWrite(10, HIGH);
  digit = (val & 0xF0) >> 4;
  time.concat(digit);
  digit = (val & 0x0F);
  time.concat(digit);
  time.concat("  ");

  // hour
  digitalWrite(10, LOW);
  SPI.transfer(0x02);
  val = SPI.transfer(0x00);
  digitalWrite(10, HIGH);
  digit = (val & 0x30) >> 4;
  time.concat(digit);
  digit = (val & 0x0F);
  time.concat(digit);
  time.concat(":");

  // minute
  digitalWrite(10, LOW);
  SPI.transfer(0x01);
  val = SPI.transfer(0x00);
  digitalWrite(10, HIGH);
  digit = (val & 0xF0) >> 4;
  time.concat(digit);
  digit = (val & 0x0F);
  time.concat(digit);

  return(time);
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
    String time = readTimeToString();
    Serial.print(time);
    printTemperature();
    lcd.setCursor(2,1);
    lcd.print(time);
    delay(1000);
}
