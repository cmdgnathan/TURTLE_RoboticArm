#include <string.h>
#include <AFMotor.h>

AF_DCMotor motor(2);

// Serial Buffer
char buf[64]; 
int bufpos;

// Control Variables
double finger[5];
int finger_i;

void setup() {
  // initialize both serial ports:
  Serial.begin(9600);
  Serial1.begin(9600);

  bufpos = 0; // Initialize Buffer Position

  // turn on motor
  motor.setSpeed(200); 
  motor.run(RELEASE);

}

void loop(){
  // Bluetooth Read (Tx1,Rx1)
  bluetoothRead();

  motor.run(FORWARD);
  motor.setSpeed((int)(255*finger[0]));

  for(int i = 0; i < 5; i++){
    Serial.print(i);
    Serial.print(":");
    Serial.println(finger[i]);
  }
        
    


}



// Bluetooth Read
void bluetoothRead(){
  while(Serial1.available()) {
    char inchar = Serial1.read();

    if(inchar != '\n'){ // Packet Terminator
      buf[bufpos] = inchar;
      bufpos++;
    }
    else{     
      buf[bufpos] = 0;
      bufpos = 0;  

      char* token = strtok(buf,":");
      finger_i = atoi(token);
      
      token = (strtok(NULL,":"));
      finger[finger_i] = atoi(token) / 99.0;

      //////////////////////////////////////
      // VERIFY
      //Serial.print(finger_i);
      //Serial.print(":");
      //Serial.println(finger[finger_i]);
      //////////////////////////////////////
    }
    
    
  }  
}


