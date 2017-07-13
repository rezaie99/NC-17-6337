
const unsigned long interval = 1000;
 
const int nbRows = 9;
const int nbCols = 13;


const int rowPins[nbRows] = {
  A0, A1, A2, A3, A4, A5, A6, A7, A8};
const int colPins[nbCols] = {
  46, 47, 48, 49, 50, 51, 52, 53, 45, 44, 43, 42, 41};

const int voltmeterPin = A10;


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
  unsigned long previousActivationTime;
  unsigned long nextActivationTime;
  unsigned long currentTime;
  int analoginput;
  int state = 0;
  int indexNum = 0;

  int val=-1;
  while (val==-1)
  {
    val=Serial.read();//wait for any signal, the trigger
  }


digitalWrite(rowPins[0], HIGH);
digitalWrite(colPins[0], 1-HIGH);//in the setup the columns were branched wrongly...
    
    
    
    
  previousActivationTime = millis();

while((millis()-previousActivationTime)<interval)
{
  
}



digitalWrite(rowPins[0], LOW);
digitalWrite(colPins[0], 1-LOW);//in the setup the columns were branched wrongly...
    
//
//  Serial.println(-42);
//  for(int i =0;i<nbRows;i++){
//    pinMode(rowPins[i], OUTPUT);
//    digitalWrite(rowPins[i], LOW);
//  }
//
//  for(int i =0;i<nbCols;i++){
//    pinMode(colPins[i], OUTPUT);
//    digitalWrite(colPins[i], HIGH);
//  } 
}




