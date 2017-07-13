
const int IRpin =  11;      
const int whitePin =  12;      

int IRstate = LOW;             
int whiteState = LOW;             

void setup() {
  Serial.begin(115200);
  pinMode(IRpin, OUTPUT);      
  pinMode(whitePin, OUTPUT); 
  digitalWrite(IRpin, IRstate);
  digitalWrite(whitePin, whiteState);
}


void loop() {
  int val=-1;
  val=Serial.read();
  if (val!=-1)
  {
    switch (val){
    case 10:
      IRstate = LOW;
      break;
    case 11:
      IRstate = HIGH;
      break;
    case 20:
      whiteState = LOW;
      break;
    case 21:
      whiteState = HIGH;
      break;
    }
    digitalWrite(IRpin, IRstate);
    digitalWrite(whitePin, whiteState);
  }
}

