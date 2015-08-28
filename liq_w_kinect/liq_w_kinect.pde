
/**
 *  Liq_w
 *  Based on 'Processing Water Simulation' by Rodrigo Amaya, ported from the "Java Water Simulation" by Neil Wallis
 *  @see http://www.openprocessing.org/sketch/43543
 *  Ale González, 2015
 *  For more information visit: 
 *  http://neilwallis.com/projects/java/water/index.php 
 *  http://freespace.virgin.net/hugo.elias/graphics/x_water.htm
 *
 *  Image by Ale.
 */
 

//SimpleOpenNI -- Kinect driver
import SimpleOpenNI.*;
SimpleOpenNI  kinect; 


//HD resolution
//int w = 1400, h = 1050;
int w = 1920, h = 1080;
//Other geometry settings
int wh, size, w_2, h_2, dx, dy, oldind, newind, mapind, radius = 10, i, a, b, px, py;
float fx, fy;
int
  title_color = 0xff0000ff,
  text_color  = 0xff0000ff,
  title_size  = 24,
  text_size   = 18,
  padding     = 50;
int kw = 640, kh = 480;

short data;
PImage texture;
int[] ripplemap, ripple;
PVector lefthand_3d, righthand_3d, lefthand_2d, righthand_2d; 
float confidence = 0f;
ProgressIcon ico;
boolean callibrating = true, users = false; 
PFont reg, bold;
String 
    title = "Liquid-a",
    exp = "A digital tiling project by Javi Aldarias and wwb.cc",
    callibrating_text = "Hello! Wait a sec, we're callibrating your body";
     
int[] pal = {#1d2536, #3b539b, #d7d6f8, #bccbf6, #2a2867, #496cca};
int[] userList; 
Truchet t;
String rule;
int[][][] rules;
int current_rule;
int current_zoom = 2;
int zoom_f = 4;
//int buckets = 80 / zoom_f;
//int bucket  = 10 * zoom_f;
int bucket = w/20, buckets_x= w/bucket, buckets_y = h/bucket; 

boolean debugging = true, callibrated = false;
     
void setup()
{
    size(w, h);
    noCursor();
    fill(-1, 125);
    noStroke();
    reg = loadFont("Asap-Regular-48.vlw");
    bold = loadFont("Asap-Bold-48.vlw");
    
    ico = new AsteroidProgressIcon(20, 5, 0x90000000);
    
    //Geometry settings
    wh = w*h;
    size = w * (h+2) * 2; 
    w_2 = w / 2;
    h_2 = h / 2;
    //Kinect resolution
    dx = w_2 - kw/2;
    dy = h_2 - kh/2;
    //fy = h / float(kh);
    //fx = w / float(kw);
   
    oldind = w; 
    newind = w * (h+3); 
    
    //Buffer settings
    //texture = loadImage("test_720.jpg");   
    
    ripplemap = new int[size];
    ripple    = new int[wh];
    
    //Kinect initialization   
    kinect = new SimpleOpenNI(this);
    if(!kinect.isInit())
    {
        println("Can't init SimpleOpenNI, maybe the camera is not connected!");
        //QUE PASA SI LA KINECT NO FUNCIONA??
        //PANIC MODE: no hay kinect 
    } else {
        kinect.enableDepth();  
        kinect.enableUser();
    }

    lefthand_3d = new PVector();
    righthand_3d = new PVector();
    lefthand_2d = new PVector();
    righthand_2d = new PVector();
    
    t = new Truchet();
    rules = t.createRules(0, 1, 2, 3);
    current_rule = int(random(rules.length));
    texture = truchet();
    texture.loadPixels();
}
 
void draw(){   
    kinect.update();
    splash();
    userList = kinect.getUsers();
    
    if(users && !callibrated) { 
        callibrating();
        for(int i = 0; i < userList.length; i++) 
        {
            //If callibration is completed, proceed
            if(kinect.isTrackingSkeleton(userList[i])) callibrated = true;
            break;  
        }
    }
    if (users && callibrated) 
    {
        background(texture);
        loadPixels();
          i      = oldind;
          oldind = mapind = newind;
          newind = i;
          
          for (int y = 0, i = 0; y < h; y++) 
            for (int x = 0; x < w; x++) {
              data = (short)((ripplemap[mapind - w] + ripplemap[mapind + w] + ripplemap[mapind - 1] + ripplemap[mapind + 1]) >> 1);
              data -= ripplemap[newind+i];
              data -= data >> 5;
              ripplemap[newind+i] = data; 
              data = (short)(1024-data); 
              a = ((x - w_2) * data>>10) + w_2;
              b = ((y - h_2) * data>>10) + h_2;
              if (a >= w) a = w-1; else if (a < 0) a = 0;
              if (b >= h) b = h-1; else if (b < 0) b = 0; 
              ripple[i] = texture.pixels[a+(b * w)];
              mapind++;
              i++;
          }
          arrayCopy(ripple, 0, pixels, 0, wh);  
          updatePixels();    
        
        for(int i = 0; i < userList.length; i++) 
        {
            //If callibration is completed, proceed
            if(kinect.isTrackingSkeleton(userList[i]))
            {          
                //lefthand 
                kinect.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_LEFT_HAND, lefthand_3d);
                kinect.convertRealWorldToProjective(lefthand_3d, lefthand_2d);
                //px = dx - int(lefthand_2d.x);
                px = int(lefthand_2d.x) + dx;
                py = int(lefthand_2d.y) + dy;
                for (int y = py - radius; y < py + radius; y++) 
                  for (int x = px - radius; x < px + radius; x++) 
                      if (y >= 0 && y < h && x >=0 && x < w) 
                          ripplemap[oldind + (y*w) + x] += 128;            
                //righthand      
                kinect.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_RIGHT_HAND, righthand_3d);
                kinect.convertRealWorldToProjective(righthand_3d, righthand_2d);         
                //px = dx - int(righthand_2d.x);
                px = int(righthand_2d.x) + dx;
                py = int(righthand_2d.y) + dy;
                for (int y = py - radius; y < py + radius; y++) 
                  for (int x = px - radius; x < px + radius; x++) 
                      if (y >= 0 && y < h && x >=0 && x < w) 
                          ripplemap[oldind + (y*w) + x] += 128;               
                if(debugging){
                    stroke(#ff0000);
                    strokeWeight(5);
                    drawSkeleton(userList[i]);
                }          
            }
        }    
    }
}


void onNewUser(SimpleOpenNI curkinect, int userId)
{
    println("onNewUser - userId: " + userId);
    println("\tstart tracking skeleton");
    users = true;  
    callibrating = true;
    curkinect.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curkinect, int userId)
{
  println("onLostUser - userId: " + userId);
  if(userList.length <= 0) {
      users = false;
      callibrating = false;  
  }
}


void callibrating(){
   textFont(reg, text_size);
   text(callibrating_text, w_2, h_2);
   image(ico.show(), w_2, h_2 + 100);
}

void splash() {
    background(-1);
    fill(title_color);
    textFont(bold, title_size);
    text(title, w - padding - textWidth(title), h - 2 * padding - textAscent() - textDescent());         
    textFont(reg, text_size);
    fill(text_color);
    text(exp, w - padding - textWidth(exp), h - padding - textAscent() - textDescent());        
}


// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{
  drawLine(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);
  drawLine(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  drawLine(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  drawLine(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);
  drawLine(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  drawLine(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  drawLine(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);
  drawLine(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  drawLine(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  drawLine(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  drawLine(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  drawLine(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);
  drawLine(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  drawLine(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  drawLine(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);  
}
  


/* draw the skeleton with the selected joints
void drawSkeleton(int userId)
{
  // to get the 3d joint data
  PVector jointPos = new PVector();
  kinect.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_NECK,jointPos);
  println(jointPos);
  
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);  
}*/

void drawLine(int userId, int jointA, int jointB){
   PVector a3d = new PVector();
   PVector b3d = new PVector();
   PVector a2d = new PVector();
   PVector b2d = new PVector();  
   float confidence = kinect.getJointPositionSkeleton(userId, jointA, a3d);
   kinect.convertRealWorldToProjective(a3d, a2d);
   confidence = kinect.getJointPositionSkeleton(userId, jointB, b3d);
   kinect.convertRealWorldToProjective(b3d, b2d);
   line(b2d.x + dx, b2d.y + dy, a2d.x + dx, a2d.y + dy);
  
}
