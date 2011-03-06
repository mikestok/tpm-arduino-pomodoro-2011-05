/* 
 * Timer code from:
 * http://www.electronicsblog.net/examples-of-using-arduinoatmega-16-bit-hardware-timer-for-digital-clock/
 *
 * Button interrupt code from:
 * http://www.codeproject.com/KB/system/Arduino_interrupts.aspx
 */

/* TEST_INTERVALS is used to have shorter intervals for the
 * WORK_STATE and REST_STATE so that the test cycles are faster
 */
// #define TEST_INTERVALS

#define HEARTBEAT_LED 13 // built in led on the arduino board

#define PUSHBUTTON_INT 0  // interrupt 0 = digital pin 2

#define WORK_STATE     0
#define REST_STATE     1
#define FREE_STATE     2
#define N_STATES       3
#define INITIAL_STATE  FREE_STATE

int ledFor[]          = {          9,         10,         11 };
#ifndef TEST_INTERVALS
int secsFor[]         = {    25 * 60,     5 * 60,     0 * 60 };
#else
int secsFor[]         = {         15,         10,          0 };
#endif
int nextStateTimer[]  = { REST_STATE, FREE_STATE, FREE_STATE };
int nextStateButton[] = { FREE_STATE, FREE_STATE, WORK_STATE };

volatile boolean heartbeatOn = false;

volatile int     state;
volatile int     secsLeft;

/*
 * Interrupt service routines
 */

/*
 * One second timer
 */
ISR(TIMER1_OVF_vect) {
  noInterrupts();

  TCNT1=0x0BDC; // set initial value to remove time error (16bit counter register)

  heartbeatOn = !heartbeatOn;  
  digitalWrite(HEARTBEAT_LED, heartbeatOn ? HIGH : LOW);

  // The "FREE" led beats with the heartbeat when one of the
  // other states is active, so we have to update the leds when
  // the clock ticks.
  updateLeds();

  if (secsLeft > 0) {
    if (--secsLeft == 0) {
      enterState(nextStateTimer[state]);
    }
  }

  interrupts();
}

/*
 * Rising edge from push button
 */
void buttonReleased() {
  noInterrupts();
  enterState(nextStateButton[state]);
  interrupts();
}

/*
 * Utility routines
 */

void updateLeds() {
  int i;

  for (i = 0; i < N_STATES; i++) {
    digitalWrite(ledFor[i], state == i ? HIGH : LOW);
  }

  // Display heartbeat on the "free" led if we aren't in
  // the free state, so you can see the timer's working.
  if (state != FREE_STATE) {
    digitalWrite(ledFor[FREE_STATE], heartbeatOn ? HIGH : LOW);
  }
}

void enterState (int newState) {
  state = newState;
  secsLeft = secsFor[newState];
  updateLeds();
}

/*
 * Arduino routines
 */

void setup() {
  int i;

  // set up IO pins
  pinMode(HEARTBEAT_LED, OUTPUT);
  for (i = 0; i < N_STATES; i++) {
    pinMode(ledFor[i], OUTPUT);
  }

  // set up state
  enterState(INITIAL_STATE);

  // set up sources of interrupts
  attachInterrupt(PUSHBUTTON_INT, buttonReleased, RISING);

  TIMSK1=0x01; // enabled global and timer overflow interrupt;
  TCCR1A = 0x00; // normal operation page 148 (mode0);
  TCNT1=0x0BDC; // set initial value to remove time error (16bit counter register)
  TCCR1B = 0x04; // start timer/ set clock
}

void loop () {
  delay(50);
}
