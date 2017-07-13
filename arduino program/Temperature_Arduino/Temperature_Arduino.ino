#include <Wire.h>
#include <Adafruit_ADS1015.h>
#include <PID_v1.h>
#define RelayPin 6
#define fanPin 5
//ADC SCL pin on pin A5
//ADC SDA pin on pin A4
//ADC ADDR pin on GND 
//ADC ALRT pin on nothing 

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// PID

//Define PID Variables we'll be connecting to
double Setpoint=0;
double Input=0;
double Output=0;

double equilibrium = 1438;

// the probe number on whioch the PID is based
int leadingIndex = 2;
// confocal system 3

// if set tu true, the PID won't be use, the computer has to change the window % 
boolean computerControl = false;
boolean pause = false;
//define PID parameters
double Kp = 0;
double Ki = 10;
double Kd = 0;

int dt=100;

//Specify the links and initial tuning parameters
PID myPID(&Input, &Output, &Setpoint, Kp, Ki, Kd, DIRECT, dt);

int WindowSize = 2000; //duration of one heating cycle, this duration will be divided in a part "on" and the rest "off", [ms]
unsigned long windowStartTime; //variable to store the starting time of the window


unsigned long previousMillis = 0;        // will store last time that the temperature was sent to computer
long interval = 1000;           // interval at which to send serial temperature, [ms]

unsigned long currentLoopMillis;
unsigned long previousLoopMillis;
unsigned long LoopInterval = 333; //interval for the loop

int state = LOW; //heater state
int FANstate = HIGH; //fan state (HIGH => off)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//temperature acquisition 

Adafruit_ADS1115 ads;

int nbOfProbes = 4;
float T[4];//table to store the temperature returned by the 4 inputs
float R[4];//table to store the Resistance returned by the 4 inputs
int repeats = 5;
float R0 = 100000.0F;//nominal resistance of thermistor [Ohm] (connected to Vin)
float T0 = 25.0F + 273.15F;//nominal temperature of thermistor [K] 
float B = 4036.0F;//thermisotr B constant
float Vin = 5.0F;//V
float Rc[4] = {
  110100.0F,109400.0F,109800.0F,109800.0F}
;  //Resistance in serie of the thermistor [Ohm] (connected to ground)
//behavioral system 110100.0F,109400.0F,109800.0F,109800.0F
//confocal system 110000.0F
//FUS system 1433000.0F
float multiplier = 0.1875F;//factor to transform bits signal into Vo





//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//setup 

void setup(void) 
{
  Serial.begin(115200);

  pinMode(RelayPin, OUTPUT);      
  pinMode(fanPin, OUTPUT);      
  digitalWrite(fanPin,FANstate);
  digitalWrite(RelayPin,LOW);

  ads.begin();

  //tell the PID to range between 0 and the full window size
  myPID.SetOutputLimits(0, WindowSize);

  //turn the PID on
  myPID.SetMode(AUTOMATIC);

  windowStartTime = millis();
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//loop 

void loop(void) 
{

  currentLoopMillis = millis();
  if(currentLoopMillis - previousLoopMillis > LoopInterval) {
    previousLoopMillis = currentLoopMillis;   

    // check if computer sent new parameters

      getComputerCommands();

    //temperature acquisition

    getTemperature();

    // PID control

    Input = T[leadingIndex];

    if (!computerControl && !pause)
    {
      if (Input>Setpoint && Output==WindowSize)
      {
        myPID.SetITerm(equilibrium);
        Output=equilibrium;
      }
      else
      {
        myPID.Compute();
      } 
    }

    if (Input<0) // due to a misconnected thermometer
    {
      Output = 0; // so the heater is off
    }


    /************************************************
     * turn the output pin on/off based on pid output
     ************************************************/
    if(millis() - windowStartTime>WindowSize)
    { //time to shift the Relay Window
      windowStartTime += WindowSize;
    }
    if (!computerControl)
    {
      if((WindowSize - Output) < millis() - windowStartTime && Input<=Setpoint+0.05) // turn relay on, for a given part of the window, defined by the PID
      {
        state=HIGH;
      }
      else if (Input>=Setpoint-3 || Output<0.1*WindowSize)// turn relay off for the rest of the widow if we are getting close to the target temp
      {
        state=LOW;
      }
    }
    else
    {
      if((WindowSize - Output) < millis() - windowStartTime)  // turn relay on, for a given part of the window, defined by the PID
      {
        state=HIGH;
      }
      else// turn relay off for the rest of the widow if we are getting close to the target temp
      {
        state=LOW;
      }
    }
    digitalWrite(RelayPin,state);

    sendData2Computer();
  }
  //end of loop
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//temperature computation

void getTemperature()
{
  float a;
  for (int i=0;i<nbOfProbes;i++){
    a=0;
    for (int j=0;j<repeats;j++){
      a+=ads.readADC_SingleEnded(i);
    }
    R[i]=bits2R(a/repeats,i);
    T[i]=R2temperature(R[i]);
  }
}

float R2temperature(float r)
{
  float t;
  t = (1 / ( (log(r / R0) / B) + (1.0F / T0) ) ) - 273.15F; 
  return (t);
}

float bits2R(int16_t readV, int index)
{
  float Vo = readV*multiplier/1000.0F;//V
  float r;
  r = Rc[index] * ((Vin/Vo) - 1.0F);
  return (r);
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Communication


void getComputerCommands()
{
  int lowbyte=-1;
  lowbyte=Serial.read();
  if (lowbyte>=0)
  {
    int highbyte = -1;
    while(highbyte==-1)
    {
      highbyte=Serial.read();
    }

    int receivedValue = highLowBytes2int(lowbyte, highbyte);
    int category = (int) floor(receivedValue/100);

    switch (category)
    {
    case 0:              //if (val<100) //if computer sends a value less than 100, it's the new target temperature
      if (Setpoint==0 || receivedValue==0)// if the temperature target is set to 0, the PID is reinitialized
      {
        Output=0;
        myPID.SetITerm(0);
        myPID.SetMode(MANUAL);
        myPID.SetMode(AUTOMATIC);
      }
      Setpoint = receivedValue;
      break;
    case 1:               // else if (val>=100 && val<200) // if the computer sends a value higher than 100, it's discarded and the 3 next values are the new PID parameters
      Kp = getNextSerialValue();
      Ki = getNextSerialValue();
      Kd = getNextSerialValue();
      myPID.SetTunings((double)Kp, (double)Ki, (double)Kd);
      break;
    case 2:       // else if (val>=200 && val<300) // if the computer sends a value higher than 200
      computerControl = true;
      Output = getNextSerialValue();
      break;
    case 3:
      pause = 1 - pause;
      break;
    case 4:
      FANstate = 1 - FANstate;
      digitalWrite(fanPin,FANstate);
      break;
    }
  }
}


void sendThisAs2bytes(int val)
{
  word w = word(val);
  Serial.write(lowByte(w)); 
  Serial.write(highByte(w));
}





int highLowBytes2int(int lowbyte, int highbyte)
{
  word w = word(highbyte,lowbyte);
  return (int) w;
}





unsigned int getNextSerialValue()
{
  int lowbyte = -1;
  while (lowbyte==-1)
  {
    lowbyte = Serial.read();
  }
  int highbyte = -1;
  while (highbyte==-1)
  {
    highbyte = Serial.read();
  }
  unsigned int value;
  value = highLowBytes2int(lowbyte,highbyte);
  return value;
}






void sendData2Computer()
{
  // Send data to computer at given frequency
  if (true)
  {
    unsigned long currentMillis = millis();

    if(currentMillis - previousMillis > interval) {
      // save the last time the temperature was sent
      previousMillis = currentMillis;   
      sendThisAs2bytes((int)(4242));
      for (int i=0;i<nbOfProbes;i++){
        sendThisAs2bytes((int)(100*T[i]));
      }
      if (true)
      {
        sendThisAs2bytes((int) Setpoint);
        sendThisAs2bytes((int) Kp);
        sendThisAs2bytes((int) Ki);
        sendThisAs2bytes((int) Kd);
        sendThisAs2bytes((int) Output);
        sendThisAs2bytes((int) computerControl);
        sendThisAs2bytes((int) (myPID.GetITerm()));
        sendThisAs2bytes((int) (pause));
      }
    } 
  }
}










