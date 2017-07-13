const int nbRows = 9;
const int nbCols = 13;

const int rowPins[nbRows] = {
  A0, A1, A2, A3, A4, A5, A6, A7, A8};
const int colPins[nbCols] = {
  46, 47, 48, 49, 50, 51, 52, 53, 45, 44, 43, 42, 41};

const int voltmeterPin = A10;

int analoginput;

unsigned long nextActivationTime;
unsigned long previousActivationTime;
unsigned long currentTime;

void setup() {

  Serial.begin(115200);

  for(int i =0;i<nbRows;i++){
    pinMode(rowPins[i], OUTPUT);
    digitalWrite(rowPins[i], LOW);
  }

  for(int i =0;i<nbCols;i++){
    pinMode(colPins[i], OUTPUT);
    digitalWrite(colPins[i], HIGH);
  } 

}

void loop()
{

  int val=-1;
  while (val==-1)
  {
    val=Serial.read();//wait for any signal, the trigger
  }

  for (int t=0;t<nbOfTimePoints;t++)
  {

    if (t==0)
    {
      previousActivationTime = millis();//Returns the number of milliseconds since the Arduino board began running the current program
    }
    else
    {
      nextActivationTime = previousActivationTime+interval;

      while(true)
      {
        currentTime = millis();
        if (currentTime>=nextActivationTime)
        {
          previousActivationTime=nextActivationTime;
          break; 
        }
      }
    }

    for(int i =0;i<nbRows;i++){
      digitalWrite(rowPins[i], allRowStates[i][t]);
    }
    for(int i =0;i<nbCols;i++){
      digitalWrite(colPins[i], 1-allColStates[i][t]);
    }
    delay(1);
    analoginput = analogRead(voltmeterPin);
    Serial.println(analoginput);
  }

  Serial.println(-42);

  while (true)
  {
    //this code is made to be ran only once
  }


}







