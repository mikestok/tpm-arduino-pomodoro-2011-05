/* 
 * Timer code from 
 * http://www.electronicsblog.net/examples-of-using-arduinoatmega-16-bit-hardware-timer-for-digital-clock/
 */

#define HEARTBEAT_LED 13 // on the arduino board

#define WORK_STATE     0
#define REST_STATE     1
#define FREE_STATE     2
#define N_STATES       3
#define INITIAL_STATE  WORK_STATE

int ledFor[]          = {  9, 10, 11 };
int secsFor[]         = { 25,  5,  0 };
int nextStateTimer[]  = { REST_STATE, FREE_STATE, FREE_STATE };

boolean heartbeatOn = false;
int     state;
int     secsLeft;

ISR(TIMER1_OVF_vect) {
  TCNT1=0x0BDC; // set initial value to remove time error (16bit counter register)
  heartbeatOn = !heartbeatOn;  
  if (secsLeft > 0) {
    secsLeft--;
  }
}

void setup() {
  int i;
  
  pinMode(HEARTBEAT_LED, OUTPUT);
  for (i = 0; i < N_STATES; i++) {
    pinMode(ledFor[i], OUTPUT);
  }
  
  enterState(INITIAL_STATE);

  TIMSK1=0x01; // enabled global and timer overflow interrupt;
  TCCR1A = 0x00; // normal operation page 148 (mode0);
  TCNT1=0x0BDC; // set initial value to remove time error (16bit counter register)
  TCCR1B = 0x04; // start timer/ set clock
}

void enterState (int newState) {
  state = newState;
  secsLeft = secsFor[newState];
}

void loop () {
  int i;
  
  digitalWrite(HEARTBEAT_LED, heartbeatOn ? HIGH : LOW);
  
  if (secsLeft == 0 && state != FREE_STATE) {
    enterState(nextStateTimer[state]);
  }
  
  for (i = 0; i < N_STATES; i++) {
    digitalWrite(ledFor[i], state == i ? HIGH : LOW);
  }
}
