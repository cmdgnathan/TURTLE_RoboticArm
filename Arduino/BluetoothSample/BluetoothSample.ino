#include <string.h>
#include <AFMotor.h>
#include <Servo.h>

AF_DCMotor motor(2);
Servo myservo1, myservo2, myservo3, myservo4, mysevro5;

boolean servo = true;

// Serial Buffer
char buf[64]; 
int bufpos;

// Control Variables
double finger[5];
int finger_i;

int bluetooth_timeout = 0;

void setup() {
  // initialize both serial ports:
  Serial.begin(9600);
  Serial1.begin(9600);

  bufpos = 0; // Initialize Buffer Position

  if(servo){
    myservo1.attach(5); //servo attached to 9 pin on Arduino 
    myservo2.attach(4);
    myservo3.attach(3);
    myservo4.attach(2);
    
     
  }
  else{    
    motor.setSpeed(200); // turn on motor
    motor.run(RELEASE);
  }
  
  
}

void loop(){
  // Bluetooth Read (Tx1,Rx1)
  bluetoothRead();
  if (bluetooth_timeout >= 20) {
    myservo1.write(90);
    myservo2.write(90);
    myservo3.write(90);
    myservo4.write(90);
  }
  else if(servo){
    myservo1.write((int)(finger[4]*90));
    myservo2.write((int)(finger[3]*90)); 
    myservo3.write((int)(90+finger[2]*90));
    myservo4.write((int)(finger[1]*90));
  }
  else{
    motor.run(FORWARD);
    motor.setSpeed((int)(255*finger[2]));
  }

    


  for(int i = 0; i < 5; i++){
    Serial.print(i);
    Serial.print(":");
    Serial.print(finger[i]);
    Serial.print("\t");
  }
  Serial.println();
       
    


}



// Bluetooth Read
void bluetoothRead(){

  if (bluetooth_timeout <= 21) {
    bluetooth_timeout++;
  }
  
  while(Serial1.available()) {
    bluetooth_timeout = 0;
    char inchar = Serial1.read(); 

    // DEBUG
    //Serial.print(inchar);

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


