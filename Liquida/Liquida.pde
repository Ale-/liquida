/**
 *  Liquid-a
 *  Software for the installation Liquid-a, in the Aura festival, Sintra, 2015
 *  A project by Javi Aldarias [javialdarias.org] and wwb [wwb.cc]
 *
 *  Copyright (c) 2015 Ale González
 *    
 *  This software is free; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License version 2.1 as published by the Free Software Foundation.
 *    
 *  This software is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  Lesser General Public License for more details.
 *    
 *  You should have received a copy of the GNU Lesser General
 *  Public License along with this library; if not, write to the
 *  Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 *  Boston, MA 02111-1307 USA
 */
 
 
//SimpleOpenNI 
import SimpleOpenNI.*;
SimpleOpenNI  kinect; 

//BlobDetection
import blobDetection.*; 
BlobDetection bd;
Blob blob;

//Blur effect
FastBlur fast;

//Truchet pattern generator
 PaletteTruchetDisplayer t;

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
  blob_resolution = 8,   //inverse proportion
  current_time;

float 
  tt = .85,         //Brightness threshold for the blob detection  
  bg_alpha = 255f;  //Alpha for the background transitions

//Particles in the blob boundary that interact with the texture  
ArrayList<PVector> visitors;     
    
short data;
  
PImage 
  cam, 
  texture, 
  blobs;
int[] 
  ripplemap, 
  ripple;


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
    PaletteTruchetDisplayer t = new PaletteTruchetDisplayer(w, h, w/40, #1d2536, #3b539b, #d7d6f8, #bccbf6, #2a2867, #496cca);
    t.setRules(0, 1, 2, 3);
    t.setRandomRule();
    texture = t.truchet();
    texture.loadPixels();
                
    //Blob detection
    blobs = createImage(kw/4, kh/4, RGB);
    fast = new FastBlur(blobs.width, blobs.height, 1);
    bd   = new BlobDetection(blobs.width, blobs.height);
    bd.setPosDiscrimination(true); //Detect bright blobs
    bd.setThreshold(tt);          //Brightness threshold
    
    //A timer to change the tilings
    current_time = millis();
}
 
void draw()
{   
    kinect.update();
    backgroundTransitions();    
    blobDetection();
    createParticles();
    waterSimulation();    
}


/**
 *  Background transitions
 *  Set a truchet tiling as background and shifts it over time
 */
void backgroundTransitions()
{
    tint(255, bg_alpha < 255f ? bg_alpha++ : bg_alpha);
    image(texture, 0, 0);
    if(millis() > current_time + 60000){
        t.setCurrentRule((t.current_rule + 1) % t.rules.length);
        current_time = millis();  
        texture = t.truchet(); 
        bg_alpha = 0f;       
    }  
}

/**
 *  Blob detection
 *  Calculates main blobs in image using BlobDetection library
 */
void blobDetection()
{
    cam = kinect.depthImage();
    blobs.copy(cam, 0, 0, cam.width, cam.height, 0, 0, blobs.width, blobs.height);
    fast.blur(blobs);    
    bd.computeBlobs(blobs.pixels);  
}

/**
 *  createParticles
 *  instantiate PVectors in blobs contours in order to distort the water
 */
void createParticles()
{
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
}


/**
 *  waterSimulation
 *  A classic water rippling effect
 *  Based on 'Processing Water Simulation' by Rodrigo Amaya, ported from the "Java Water Simulation" by Neil Wallis
 *  @see http://www.openprocessing.org/sketch/43543
 */
void waterSimulation()
{
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
