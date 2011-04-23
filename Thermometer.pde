#include <LiquidCrystal.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// pin for communicating with temperature sensor
#define ONE_WIRE_BUS 9
// size of boxcar average window
#define nBoxcar 10
// temperature sensor objects
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
// LCD object
LiquidCrystal lcd(8, 7, 6, 5, 4, 3);

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
float boxcarCelsius[nBoxcar];
int i = 0;

void setup(void) {
    // serial stuff
    Serial.begin(115200);
    // create degree glyph for LCD
    lcd.createChar(0, degreeGlyph);
    // initialize LCD with dimensions
    lcd.begin(16,2);
    // initialize temp sensor
    sensors.begin();
}

void printTemperature() {
    sensors.requestTemperatures();
    float tempC = sensors.getTempCByIndex(0);
    // increment index on boxcar
    i++;
    if (i == nBoxcar) i = 0;
    boxcarCelsius[i] = tempC;
    // average over boxcar array
    tempC = 0;
    for (int j = 0; j < nBoxcar; j++) {
        tempC += boxcarCelsius[j] / nBoxcar;
    }
    // print to lcd
    lcd.setCursor(1, 0);
    lcdPrintTemp(tempC);
    // janky print to serial
    Serial.println(tempC);
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
    printTemperature();
    delay(1000);
}
