
#if defined(__AVR_ATmega1280__) || defined(__AVR_ATmega2560__)
#define INTERNAL INTERNAL1V1
#endif

#include "Adafruit_MAX31855.h"

int thermoDO = 3;
int thermoCS = 4;
int thermoCLK = 5;
int tempC=0;

//int freq = 40;

//long previousMillis = 0;        // will store last time LED was updated
//long interval = int(1000/(freq*1.1));           // interval at which to blink (milliseconds)int delaym = int(1000/freq);

Adafruit_MAX31855 thermocouple(thermoCLK, thermoCS, thermoDO);


const int firstRelayPin =  11;      
const int secondRelayPin =  12;      

int firstRelayState = LOW;             
int secondRelayState = LOW;             



void setup() {
  pinMode(firstRelayPin, OUTPUT);      
  pinMode(secondRelayPin, OUTPUT); 
  digitalWrite(firstRelayPin, firstRelayState);
  digitalWrite(secondRelayPin, secondRelayState);
  /* initialize serial                                       */
  Serial.begin(115200);
  // wait for MAX chip to stabilize
  delay(500);
}


void loop() {


  int val=0;
  val=Serial.read();
  if (val!=-1)
  {
    switch (val){
    case 10:
      firstRelayState = LOW;
      break;
    case 11:
      firstRelayState = HIGH;
      break;
    case 20:
      secondRelayState = LOW;
      break;
    case 21:
      secondRelayState = HIGH;
      break;
    }
    digitalWrite(firstRelayPin, firstRelayState);
    digitalWrite(secondRelayPin, secondRelayState);
  }

//  unsigned long currentMillis = millis();
//      Serial.println(currentMillis - previousMillis);
//  if(currentMillis - previousMillis > interval) {
    // save the last time you blinked the LED
    //thermocouple.readInternal()
    tempC = int(100*thermocouple.readCelsius());
    if (isnan(tempC)) {
      Serial.println("Something wrong with thermocouple!");
    } 
    else {
      Serial.println(tempC);
    }
//        previousMillis = currentMillis;  
  //}
}





