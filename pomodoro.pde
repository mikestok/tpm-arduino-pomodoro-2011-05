/* 
 * Timer code from:
 * http://www.electronicsblog.net/examples-of-using-arduinoatmega-16-bit-hardware-timer-for-digital-clock/
 *
 * Button interrupt code from:
 * http://www.codeproject.com/KB/system/Arduino_interrupts.aspx
 */

/*
 * TEST_INTERVALS is used to have shorter intervals for the
 * WORK_STATE and REST_STATE so that the test cycles are faster
 */
// #define TEST_INTERVALS

#define HEARTBEAT_LED 13 // built in led on the arduino board

/*
 * INITIAL_TCNT1
 *
 * When we use a /256 prescaler the effective frequency of a 16MHz
 * clock is 16,000,000 / 256 = 62,500Hz.  As the clock generates
 * an interrupt when it overflows it will normally take 65,336
 * cycles or a little more than 1s.
 *
 * By setting an initial count of 65,336 - 65,200 we can make the
 * interrupt more accurate.
 */

#define INITIAL_TCNT1  (65536 - 16000000 / 256)

#define PUSHBUTTON_INT 0  // interrupt 0 = digital pin 2

#define WORK_STATE     0
#define REST_STATE     1
#define FREE_STATE     2
#define N_STATES       3
#define INITIAL_STATE  FREE_STATE

/*
 * Pin assignments are chosen because:
 *  * We use timer 1 to generate the one second clock ticks,
 *    so that makes PWM to pins 9 and 10 impossible.
 *  * Timer 2 is not used by the system, so is more likely to
 *    be accurate for low duty cycle PWM pins 3 and 11. Thus
 *    we use pins 3 and 11 for the work / rest states.
 *  * Timer 0 is used by the system, so pin 5 gets used by
 *    the free state light which doesn't really have much
 *    interesting activity.
 */
int ledFor[]          = {          3,         11,          5 };
#ifndef TEST_INTERVALS
int secsFor[]         = {    25 * 60,     5 * 60,     0 * 60 };
#else
int secsFor[]         = {         15,         10,          0 };
#endif
int nextStateTimer[]  = { REST_STATE, FREE_STATE, FREE_STATE };
int nextStateButton[] = { FREE_STATE, FREE_STATE, WORK_STATE };

volatile boolean heartbeatOn = false;

volatile int     brightnessFor[N_STATES];
volatile int     state;
volatile int     secsDuration;
volatile int     secsLeft;

/*
 * Interrupt service routines
 */

/*
 * One second timer
 */

ISR(TIMER1_OVF_vect) {
  noInterrupts();

  TCNT1 = INITIAL_TCNT1; // set initial value to remove time error (16bit counter register)

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

  // Clear all the "other" state leds
  for (i = 0; i < N_STATES; i++) {
    if (i != state) {
      brightnessFor[i] = 0;
    }
  }

  if (state == FREE_STATE) {
    brightnessFor[FREE_STATE] = 255;
  }
  else {
    // For other states set the brightness to full on until we get close to the end of the
    // period.  When we are close to the end of the period we use the heartbeat to swich between
    // full on and something gradually dimming.
    int rampDownPeriod = 180;
    if (secsLeft > rampDownPeriod || heartbeatOn) {
      brightnessFor[state] = 255;
    }
    else {
       brightnessFor[state] = map(secsLeft, 0, rampDownPeriod, 64, 255);
    }
  }
}

void enterState (int newState) {
  state = newState;
  secsDuration = secsLeft = secsFor[newState];
  updateLeds();
}

/*
 * Arduino routines
 */

void setup() {
  int i;

  // set up IO pins
  pinMode(HEARTBEAT_LED, OUTPUT);

  // set up state
  enterState(INITIAL_STATE);

  // set up sources of interrupts
  attachInterrupt(PUSHBUTTON_INT, buttonReleased, RISING);

  TIMSK1 = 0x01;          // enabled global and timer overflow interrupt;
  TCCR1A = 0x00;          // normal operation page 148 (mode0);
  TCNT1  = INITIAL_TCNT1; // set initial value to remove time error (16bit counter register)
  TCCR1B = 0x04;          // start timer/ set clock
}

void loop () {
  int i;

  for (i = 0; i < N_STATES; i++) {
    analogWrite(ledFor[i], brightnessFor[i]);
  }

  delay(50);
}
