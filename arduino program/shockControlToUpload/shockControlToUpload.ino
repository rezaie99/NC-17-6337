const byte index[117] = {
139,129,119,109,99,89,79,69,59,49,39,29,19,138,128,118,108,98,88,78,68,58,48,38,28,18,137,127,117,107,97,87,77,67,57,47,37,27,17,136,126,116,106,96,86,76,66,56,46,36,26,16,135,125,115,105,95,85,75,65,55,45,35,25,15,134,124,114,104,94,84,74,64,54,44,34,24,14,133,123,113,103,93,83,73,63,53,43,33,23,13,132,122,112,102,92,82,72,62,52,42,32,22,12,131,121,111,101,91,81,71,61,51,41,31,21,11};
 
const int differentIntervals[2] = {
1,202};
 
const int nbOfIntervals = 234;
 
const byte whichInterval[234] = {
2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
 
const unsigned long interval = 10;
 

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// begining of code that Matlab doesn't touch, doesn't compile without previous lines (can be found in the shockControlToUpload for debug but need to be removed before actual use)

const int nbRows = 9;
const int nbCols = 13;

const int rowPins[nbRows] = {
  A0, A1, A2, A3, A4, A5, A6, A7, A8};
const int colPins[nbCols] = {
  46, 47, 48, 49, 50, 51, 52, 53, 38, 44, 39, 42, 41};

const int voltmeterPin = A11;

unsigned long previousActivationTime;
unsigned long nextActivationTime;
//unsigned long nextSendTime;
//boolean sentAlready;
unsigned long currentTime;
//boolean sendContinuousCurrent = true;
boolean crossShocks = true;//when set to true cloumns are + and rows are -, if false columns are either + or - and rows are off

//unsigned int R = 10000;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//setup

void setup() {

  Serial.begin(115200);

  closeAllRelays();

}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//loop

void loop()
{
  int state = 0;
  int indexNum = 0;

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // triggering signal

    int val=-1;
   while (val==-1)
    {
      val=Serial.read();//wait for any signal, the trigger
    }

  previousActivationTime = millis();
  int k;
  for (int t=0;t<nbOfIntervals;t++)
  {
    k=(int)whichInterval[t] - 1;
    nextActivationTime = previousActivationTime + differentIntervals[k]*interval;

    waitForNextSwitch();

    if (crossShocks)
    {
      int indexCol = (int)floor(index[indexNum]/10);// example : 73 => column 7, row 3
      int indexRow = index[indexNum]-10*indexCol;// other example : 127 => column 12, row 7
      indexCol--;
      indexRow--;
      state = 1-state;//we turn it on/off alternally
      digitalWrite(rowPins[indexRow], state);
      digitalWrite(colPins[indexCol], 1-state);//in the setup the columns were branched wrongly...
    }
    else // parallel shocks
    {

    }
    if (state == 0)
    {
      indexNum++;
    }



  }
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //close all relays, then restart the loop and wait for new trigger
  closeAllRelays();
}

void waitForNextSwitch()
{
  while(true)
  {
    currentTime = millis();
    if (currentTime>=nextActivationTime)
    {
      previousActivationTime=currentTime;
      return; 
    }

//    int aaa=analogRead(voltmeterPin);
//    Serial.println(aaa);
//        delayMicroseconds(500);
//        delayMicroseconds(500);
  }

}



void closeAllRelays()
{
   Serial.println(-42);
  for(int i =0;i<nbRows;i++){
    pinMode(rowPins[i], OUTPUT);
    digitalWrite(rowPins[i], LOW);
  }

  for(int i =0;i<nbCols;i++){
    pinMode(colPins[i], OUTPUT);
    digitalWrite(colPins[i], HIGH);
  } 
}








