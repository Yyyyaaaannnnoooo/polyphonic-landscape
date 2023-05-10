/*
SparkFun Inventor's Kit 
Example sketch 06

PHOTORESISTOR

  Use a photoresistor (light sensor) to control the brightness
  of a LED.

Hardware connections:

  Photo resistor:

    Connect one side of the photoresistor to 5 Volts (5V).
    Connect the other side of the photoresistor to ANALOG pin 0.
    Connect a 10K resistor between ANALOG pin 0 and GND.

    This creates a voltage divider, with the photoresistor one
    of the two resistors. The output of the voltage divider
    (connected to A0) will vary with the light level.


This sketch was written by SparkFun Electronics,
with lots of help from the Arduino community.
This code is completely free for any use.
Visit http://learn.sparkfun.com/products/2 for SIK information.
Visit http://www.arduino.cc to learn about the Arduino.

Version 2.0 6/2012 MDG
*/


// As usual, we'll create constants to name the pins we're using.
// This will make it easier to follow the code below.

const int sensorPin = A0;

// We'll also set up some global variables for the light level:

int lightLevel, high = 0, low = 1023;


void setup()
{
Serial.begin(9600); 
}


void loop()
{
  lightLevel = analogRead(sensorPin);
  Serial.print(lightLevel);
  Serial.print('a');
  delay(1);
}
