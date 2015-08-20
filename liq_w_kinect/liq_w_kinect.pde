
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
int w = 1280, h = 720;
//int w = 1920, h = 1080;
//Other geometry settings
int wh, size, w_2, h_2, dx, dy, oldind, newind, mapind, radius = 5, i, a, b, px, py;
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
    dx = w_2 + kw/2;
    dy = h_2 - kh/2;
    fy = h / float(kh);
    fx = w / float(kw);
   
    oldind = w; 
    newind = w * (h+3); 
    
    //Buffer settings
    texture = loadImage("test_720.jpg");   
    texture.loadPixels();
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
    
    //splash();
}
 
void draw(){
    //splash.callibrating();     
    kinect.update();
    splash();
    if(users) { 
        callibrating();
    }
    if (users && !callibrating) 
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
        
        
        int[] userList = kinect.getUsers();
        for(int i = 0; i < userList.length; i++) 
        {
            //If callibration is completed, proceed
            if(kinect.isTrackingSkeleton(userList[i]))
            {          
              //lefthand 
              confidence = kinect.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_LEFT_HAND, lefthand_3d);
              kinect.convertRealWorldToProjective(lefthand_3d, lefthand_2d);
              px = dx - int(lefthand_2d.x);
              py = int(lefthand_2d.y) + dy;
              //ellipse(px, py, 50, 50);
              for (int y = py - radius; y < py + radius; y++) 
                for (int x = px - radius; x < px + radius; x++) 
                    if (y >= 0 && y < h && x >=0 && x < w) 
                        ripplemap[oldind + (y*w) + x] += 128;            
              //righthand      
              confidence = kinect.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_RIGHT_HAND, righthand_3d);
              kinect.convertRealWorldToProjective(righthand_3d, righthand_2d);         
              px = dx - int(righthand_2d.x);
              py = int(righthand_2d.y) + dy;
              //ellipse(px, py, 50, 50);
              for (int y = py - radius; y < py + radius; y++) 
                for (int x = px - radius; x < px + radius; x++) 
                    if (y >= 0 && y < h && x >=0 && x < w) 
                        ripplemap[oldind + (y*w) + x] += 128;               
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

void onLostUser(SimpleOpenNI curContext, int userId)
{
  println("onLostUser - userId: " + userId);
}

/* user-tracking callbacks!
void onNewUser(int userId) {
    println("start pose detection");
    kinect.startPoseDetection("Psi", userId);
}*/

void onEndCalibration(int userId, boolean successful) {
    if (successful) {
        println(" User calibrated !!!");
        callibrating = false;
        kinect.startTrackingSkeleton(userId);
    } else {
        println(" Failed to calibrate user !!!");
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
