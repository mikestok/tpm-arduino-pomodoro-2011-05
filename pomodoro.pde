/* 
 * Timer code from 
 * http://www.electronicsblog.net/examples-of-using-arduinoatmega-16-bit-hardware-timer-for-digital-clock/
 */

/* 
 * LEDs are assigned to avoid the analog output pins, just in case 
 * we want to use them...
 */
 
#define WORK_LED       2 // red - do not disturb
#define REST_LED       4 // amber - resting
#define FREE_LED       7 // green
#define HEARTBEAT_LED 13 // on the arduino board

#define WORK_SECS     25 // should be 25 * 60
#define REST_SECS      5 // should be  5 * 60

#define WORK_STATE     1
#define REST_STATE     2
#define FREE_STATE     3

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

  enterState(WORK_STATE, WORK_SECS);
  
  pinMode(HEARTBEAT_LED, OUTPUT);
  pinMode(WORK_LED, OUTPUT);
  pinMode(REST_LED, OUTPUT);
  pinMode(FREE_LED, OUTPUT);

  TIMSK1=0x01; // enabled global and timer overflow interrupt;
  TCCR1A = 0x00; // normal operation page 148 (mode0);
  TCNT1=0x0BDC; // set initial value to remove time error (16bit counter register)
  TCCR1B = 0x04; // start timer/ set clock
}

void enterState (int newState, int secs) {
  state = newState;
  secsLeft = secs;
}

void loop () {
  digitalWrite(HEARTBEAT_LED, heartbeatOn ? HIGH : LOW);
  
  if (secsLeft == 0) {
    switch (state) {
      case WORK_STATE:
      enterState(REST_STATE, REST_SECS);
      break;
      default:
      enterState(FREE_STATE, 0);
      break;
    }
  }
  
  digitalWrite(WORK_LED, state == WORK_STATE ? HIGH : LOW);
  digitalWrite(REST_LED, state == REST_STATE ? HIGH : LOW);
  digitalWrite(FREE_LED, state == FREE_STATE ? HIGH : LOW);
}
