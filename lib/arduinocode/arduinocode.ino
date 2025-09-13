// RGB LED Strip Controller (Arduino Mega + HC-05)
// Bidirectional: App <-> Arduino <-> Serial Monitor

#define RED_PIN    5   // PWM pin for Red
#define GREEN_PIN  6   // PWM pin for Green
#define BLUE_PIN   7   // PWM pin for Blue

int r = 0, g = 0, b = 0;

void setup() {
  Serial.begin(9600);    // USB Serial Monitor
  Serial1.begin(9600);   // HC-05 (TX1=18, RX1=19)

  pinMode(RED_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);

  setColor(0, 0, 0);     // Start with LEDs off
  Serial.println("System ready. Type commands here or use the app.");
}

void loop() {
  // 1. Handle data from Bluetooth (app -> Arduino)
  if (Serial1.available()) {
    String cmd = Serial1.readStringUntil('\n');
    cmd.trim();

    if (cmd.length() > 0) {
      Serial.print("From App: ");
      Serial.println(cmd);  // show on Serial Monitor
      parseCommand(cmd);
    }
  }

  // 2. Handle data from Serial Monitor (PC -> Arduino -> App)
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();

    if (cmd.length() > 0) {
      Serial1.println(cmd);   // forward to HC-05
      Serial.print("From PC: ");
      Serial.println(cmd);    // confirm locally
      parseCommand(cmd);
    }
  }
}

// Parse incoming command like: S,R,128,G,64,B,255
void parseCommand(String cmd) {
  int rIndex = cmd.indexOf("R,");
  int gIndex = cmd.indexOf("G,");
  int bIndex = cmd.indexOf("B,");

  if (rIndex > -1 && gIndex > -1 && bIndex > -1) {
    r = cmd.substring(rIndex + 2, cmd.indexOf(",", rIndex + 2)).toInt();
    g = cmd.substring(gIndex + 2, cmd.indexOf(",", gIndex + 2)).toInt();
    b = cmd.substring(bIndex + 2).toInt();

    setColor(r, g, b);

    String ack = "OK R=" + String(r) + " G=" + String(g) + " B=" + String(b);
    Serial1.println(ack);   // feedback to app
    Serial.println(ack);    // feedback to Serial Monitor
  }
}

// Set RGB LED color using PWM
void setColor(int red, int green, int blue) {
  analogWrite(RED_PIN, red);
  analogWrite(GREEN_PIN, green);
  analogWrite(BLUE_PIN, blue);
}
