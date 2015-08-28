/**
 *  Liquid-a
 *  Software for the installation Liquid-a, in the Aura festival, Sintra, 2015
 *  A project by Javi Aldarias and wwb
 *  Ale, 2015
 */
 
//SimpleOpenNI 
import SimpleOpenNI.*;
SimpleOpenNI  kinect; 

//BlobDetection
import blobDetection.*; 
BlobDetection bd;
Blob blob;

//Global variables
int
  //Projection resolution, hd
  w = 1280, h = 720,
  //Kinect resolution, fixed 
  kw = 640, kh = 480,
  //Other settings 
  wh, size, w_2, h_2, 
  oldind, newind, mapind, 
  radius = 5, 
  a, b,
  blob_resolution = 8,
  current_time;
    
short 
  data;
PImage 
  cam, texture, blobs;
int[] 
  ripplemap, ripple;
ArrayList<PVector> 
  visitors;     
float tt = .85;
//Splash screen settings
Boolean
  splash = false,
  debugging = false,
  users = false, 
  text = false;
int    
  users_n,
  splash_timer,
  splash_bg = #ff0000,
  splash_timeout = 20;  
PImage 
  splash_init,
  splash_es;
float  
  splash_alpha = 0f,
  splash_alpha_two = 0f,
  bg_alpha = 255f;

  
void setup()
{
    size(w, h);
    noCursor();
    
    //Geometry settings
    wh = w*h;
    size = w * (h+2) * 2; 
    w_2 = w / 2;
    h_2 = h / 2;
    oldind = w; 
    newind = w * (h+3); 
 
    //Buffer settings    
    ripplemap = new int[size];
    ripple    = new int[wh];
    
    //Kinect initialization   
    kinect = new SimpleOpenNI(this);
    if(!kinect.isInit())
        println("Can't init SimpleOpenNI, maybe the camera is not connected!");
    else {
        kinect.enableDepth();
        kinect.enableUser(); 
    }
    
    //Truchet settings
    t = new Truchet();
    rules = t.createRules(0, 1, 2, 3);
    current_rule = int(random(rules.length));
    texture = truchet();
    texture.loadPixels();
        
        
    //Blob detection
    blobs = createImage(kw/4, kh/4, RGB);
    bd = new BlobDetection(blobs.width, blobs.height);
    bd.setPosDiscrimination(true); //Detect bright blobs
    bd.setThreshold(tt);          //Brightness threshold
    
    //A timer to change the tilings
    current_time = millis();
}
 
void draw()
{   
    kinect.update();
    
    if(debugging) 
        frame.setTitle( nfc(frameRate, 2) );  
    tint(255, bg_alpha < 255f ? bg_alpha++ : bg_alpha);
    image(texture, 0, 0);
    //Update texture
    if(millis() > current_time + 60000){
        current_rule = (current_rule + 1) % rules.length;
        current_time = millis();  
        texture = truchet(); 
        bg_alpha = 0f;       
    }
    
    //Create visitors
    cam = kinect.depthImage();
    blobs.copy(cam, 0, 0, cam.width, cam.height, 0, 0, blobs.width, blobs.height);
    fastblur(blobs, 2);    
    bd.computeBlobs(blobs.pixels);

    //Blob detection
    //Detects main blobs and create particles in its contour
    EdgeVertex p;
    visitors = new ArrayList<PVector>();
    for(int i = 0; i < bd.getBlobNb(); i++) {
        blob = bd.getBlob(i);
        int edges = blob.getEdgeNb();         
        if(edges < 250) continue;
        for (int edge = 0; edge < edges; edge += blob_resolution){
            p = blob.getEdgeVertexA(edge);
            if (p != null) 
                visitors.add(new PVector(p.x * width, p.y * height + 100));
        }
    }

    //Water effect    
    loadPixels();
    int tmp = oldind;
    oldind = mapind = newind;
    newind = tmp;
    loadPixels();
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
        ripple[i] = g.pixels[a+(b * w)];
        mapind++;
        i++;
    }
    arrayCopy(ripple, 0, pixels, 0, wh);  
    updatePixels();    
      
    //Caculate visitors influence over the ripplemap
    int vx, vy;
    for(PVector v : visitors) {
        vx = int(v.x);
        vy = int(v.y);
        for (int y = vy - radius; y < vy + radius; y++) 
          for (int x= vx - radius; x < vx + radius; x++) 
            if (y >= 0 && y < h && x >=0 && x < w) 
              ripplemap[oldind + (y*w) + x] += 128;
    }
}

void keyPressed(){
    if(keyCode == UP && tt < 1f){
            bd.setThreshold(tt+=.05); 
            println(tt); 
    } else if (keyCode == DOWN && tt > 0f){
            bd.setThreshold(tt-=.05); 
            println(tt); 
    }  
}
