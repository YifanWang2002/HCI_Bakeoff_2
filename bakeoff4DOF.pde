import java.util.ArrayList;
import java.util.Collections;



//these are variables you should probably leave alone
int index = 0; //starts at zero-ith trial
float border = 0; //some padding from the sides of window, set later
int trialCount = 12; //this will be set higher for the bakeoff
int trialIndex = 0; //what trial are we on
int errorCount = 0;  //used to keep track of errors
float errorPenalty = 0.5f; //for every error, add this value to mean time
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false; //is the user done

final float screenPPI = 133; //what is the DPI of the screen you are using
//you can test this by drawing a 72x72 pixel rectangle in code, and then confirming with a ruler it is 1x1 inch. 

//These variables are for my example design. Your input code should modify/replace these!
float logoX = 500;
float logoY = 500;
float logoZ = 50f;
float logoRotation = 0;

// added things
int DOUBLECLICK_THRESHOLD = 300;
int prevClickTime = 0;
int clickCount = 0;
enum State { INIT, PREDRAW, DRAW, POSTDRAW, SUBMIT }
State state = State.INIT;
boolean maybeDoubleclick = false;

int correctTrials = 0;
int totalTrialsAttempted = 0;
int lastUpdateTime = 0; // Tracks the last update time for display
int updateFrequency = 2000; // Update frequency in milliseconds (2 seconds)

float maybex1 = 0;
float maybey1 = 0;
float x1 = 0;
float y1 = 0;
float x2 = 0;
float y2 = 0;

private class Destination
{
  float x = 0;
  float y = 0;
  float rotation = 0;
  float z = 0;
}

ArrayList<Destination> destinations = new ArrayList<Destination>();

void setup() {
  //fullScreen();
  size(1000, 800);  
  rectMode(CENTER);
  textFont(createFont("Arial", inchToPix(.3f))); //sets the font to Arial that is 0.3" tall
  textAlign(CENTER);
  rectMode(CENTER); //draw rectangles not from upper left, but from the center outwards
  
  //don't change this! 
  border = inchToPix(2f); //padding of 2.0 inches

  for (int i=0; i<trialCount; i++) //don't change this! 
  {
    Destination d = new Destination();
    d.x = random(border, width-border); //set a random x with some padding
    d.y = random(border, height-border); //set a random y with some padding
    d.rotation = random(0, 360); //random rotation between 0 and 360
    d.z = inchToPix((float)random(1,12)/4.0f); //increasing size from 0.25" up to 3.0" 
    destinations.add(d);
    println("created target with " + d.x + "," + d.y + "," + d.rotation + "," + d.z);
  }

  Collections.shuffle(destinations); // randomize the order of the button; don't change this.
}

void draw() {
  background(40); //background is dark grey
  noStroke();
  rectMode(CENTER);
  //fill(255,0,0);
  //rect(width/2,height/2, inchToPix(1f), inchToPix(1f));
  
  fill(200);
  //shouldn't really modify this printout code unless there is a really good reason to
  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, inchToPix(.4f));
    text("User had " + errorCount + " error(s)", width/2, inchToPix(.4f)*2);
    text("User took " + (finishTime-startTime)/1000f/trialCount + " sec per destination", width/2, inchToPix(.4f)*3);
    text("User took " + ((finishTime-startTime)/1000f/trialCount+(errorCount*errorPenalty)) + " sec per destination inc. penalty", width/2, inchToPix(.4f)*4);
    return;
  }

  //===========DRAW DESTINATION SQUARES=================
  for (int i=trialIndex; i<trialCount; i++) // reduces over time
  {
    pushMatrix();
    Destination d = destinations.get(i); //get destination trial
    translate(d.x, d.y); //center the drawing coordinates to the center of the destination trial
    rotate(radians(d.rotation)); //rotate around the origin of the destination trial
    noFill();
    strokeWeight(3f);
    if (trialIndex==i)
      stroke(255, 0, 0, 192); //set color to semi translucent
    else
      stroke(128, 128, 128, 128); //set color to semi translucent
    rect(0, 0, d.z, d.z);
    popMatrix();
  }

  //===========DRAW LOGO SQUARE=================
  maybeDoubleclick = maybeDoubleclick && (millis() - prevClickTime < DOUBLECLICK_THRESHOLD);
  if (!maybeDoubleclick) {
    if (state == State.PREDRAW) {
      state = State.DRAW;
      x1 = maybex1;
      y1 = maybey1;
    } else if (state == State.POSTDRAW) {
      state = State.SUBMIT;
    }
    clickCount = 0;
  }
  
  pushMatrix();
  noStroke();
  if (checkForSuccessWithoutPrints()) {
    fill(0,255,0,192);
  } else {
    fill(60,60,192,192);
  }
  rectMode(CORNER);
  if (state == State.INIT) {
    x1 = 0;
    y1 = 0;
    x2 = 1;
    y2 = 1;
  } else if (state == State.DRAW) {
    x2 = mouseX;
    y2 = mouseY;
  }
  translate(x1, y1);
  logoX = (x1 + x2) / 2;
  logoY = (y1 + y2) / 2;
  logoZ = dist(x1, y1, x2, y2) / sqrt(2);
  float rot = atan2(y2 - y1, x2 - x1) - PI/4;
  logoRotation = degrees(rot);
  rotate(rot);
  square(0, 0, logoZ);
  popMatrix();

  //===========DRAW EXAMPLE CONTROLS=================
  fill(255);
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, inchToPix(.8f));
  
  if (totalTrialsAttempted > 0 && startTime != 0) {
    // Use current time (millis()) instead of finishTime if the user hasn't finished all trials
    float currentTime = userDone ? finishTime : millis();
    float averageTimePerTrial = (currentTime - startTime) / 1000f / totalTrialsAttempted;
    //text("Correctness: " + correctTrials + "/" + totalTrialsAttempted, width / 2, height - inchToPix(.4f) * 2);
    //text("Average Time per Trial: " + averageTimePerTrial + " sec", width / 2, height - inchToPix(.4f));
    //text(String.format("Average Time per Trial: %.4f sec", averageTimePerTrial), width / 2, height - inchToPix(.4f));
}
}

  

void mousePressed()
{
  if (startTime == 0) //start time on the instant of the first user click
  {
    startTime = millis();
    println("time started!");
  }
}

void mouseReleased()
{
  clickCount++;
  if (clickCount == 1) { // single click, starting draw mode
    if (state == State.INIT || state == State.SUBMIT) {
      state = State.PREDRAW;
      maybex1 = mouseX;
      maybey1 = mouseY;
    } else if (state == State.DRAW) { // second click, ending draw mode
      state = State.POSTDRAW;
      x2 = mouseX;
      y2 = mouseY;
    }
    prevClickTime = millis();
    maybeDoubleclick = true;
  } else if (clickCount == 2 && millis() - prevClickTime < DOUBLECLICK_THRESHOLD && maybeDoubleclick) { // doubleclick
    clickCount = 0;
    maybeDoubleclick = false;
    state = State.INIT;
    if (userDone==false && !checkForSuccess()) {
      errorCount++;
    }

    trialIndex++; //and move on to next trial

    if (trialIndex==trialCount && userDone==false)
    {
      userDone = true;
      finishTime = millis();
    }
  } else {
    // should not be reachable
    state = State.INIT;
    clickCount = 0;
    maybeDoubleclick = false;
  }
}

public boolean checkForSuccessWithoutPrints()
{
  Destination d = destinations.get(trialIndex);  
  boolean closeDist = dist(d.x, d.y, logoX, logoY)<inchToPix(.05f); //has to be within +-0.05"
  boolean closeRotation = calculateDifferenceBetweenAngles(d.rotation, logoRotation)<=5;
  boolean closeZ = abs(d.z - logoZ)<inchToPix(.1f); //has to be within +-0.1"  

  return closeDist && closeRotation && closeZ;
}

//probably shouldn't modify this, but email me if you want to for some good reason.
public boolean checkForSuccess()
{
  Destination d = destinations.get(trialIndex);  
  boolean closeDist = dist(d.x, d.y, logoX, logoY)<inchToPix(.05f); //has to be within +-0.05"
  boolean closeRotation = calculateDifferenceBetweenAngles(d.rotation, logoRotation)<=5;
  boolean closeZ = abs(d.z - logoZ)<inchToPix(.1f); //has to be within +-0.1"  
  
  boolean success = closeDist && closeRotation && closeZ;

  // Increment totalTrialsAttempted and correctTrials if the trial is completed successfully
  totalTrialsAttempted++;
  if (success) {
    correctTrials++;
  }

  println("Close Enough Distance: " + closeDist + " (destination X/Y = " + d.x + "/" + d.y + ", logo X/Y = " + logoX + "/" + logoY +")");
  println("Close Enough Rotation: " + closeRotation + " (rot dist="+calculateDifferenceBetweenAngles(d.rotation, logoRotation)+")");
  println("Close Enough Z: " +  closeZ + " (logo Z = " + d.z + ", destination Z = " + logoZ +")");
  println("Close enough all: " + (closeDist && closeRotation && closeZ));

  return closeDist && closeRotation && closeZ;
}

//utility function I include to calc diference between two angles
double calculateDifferenceBetweenAngles(float a1, float a2)
{
  double diff=abs(a1-a2);
  diff%=90;
  if (diff>45)
    return 90-diff;
  else
    return diff;
}

//utility function to convert inches into pixels based on screen PPI
float inchToPix(float inch)
{
  return inch*screenPPI;
}
