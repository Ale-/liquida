import ddf.minim.*;
import ddf.minim.analysis.*;


/**
 *  Liq_w_minim
 *  Based on 'Processing Water Simulation' by Rodrigo Amaya, ported from the "Java Water Simulation" by Neil Wallis
 *  @see http://www.openprocessing.org/sketch/43543
 *  Ale González, 2015
 *  For more information visit: 
 *  http://neilwallis.com/projects/java/water/index.php 
 *  http://freespace.virgin.net/hugo.elias/graphics/x_water.htm
 *
 *  Image by Ale.
 *  Panic version (if everything fails this'd do the job)
 */
 
 
PImage texture;
 
int w, h, wh, size, w_2, h_2, oldind, newind, mapind, visitors_number = 1, radius = 500, i, a, b;
float r = 250f;
short data;
 
int[] ripplemap, ripple;
int[][] visitors;

Minim m;
AudioInput microphone;
float[] wave; 
 
void setup()
{
    texture = loadImage("bg.jpg");   
    size(texture.width, texture.height);
    w = width;
    h = height; 
    wh = w*h;
    size = w * (h+2) * 2; 
    w_2 = w / 2;
    h_2 = h / 2;
    oldind = w; 
    newind = w*(h+3); 
    
    ripplemap = new int[size];
    ripple    = new int[wh];
    visitors  = new int[visitors_number][2];
    noCursor();
    texture.loadPixels();
    
    m = new Minim(this);
    microphone = m.getLineIn();
    wave = new float[1024];
}


/**
 *  draw
 *  main loop
 */ 
void draw() 
{
    frame.setTitle(nfc(frameRate, 2));
    background(texture);
    
    //Create ripples effect blending buffers
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
    radius = int( microphone.mix.get(0) * r);
    
    //Caculate visitors influence over the ripplemap
    visitors[0][0] = mouseX;
    visitors[0][1] = mouseY;
    for(int v = 0; v < visitors.length; v++)
        for (int y = visitors[v][1] - radius; y < visitors[v][1] + radius; y++) 
          for (int x= visitors[v][0] - radius; x < visitors[v][0] + radius; x++) 
            if (y >= 0 && y < h && x >=0 && x < w) 
              ripplemap[oldind + (y*w) + x] += 128; 
}

/**
 *  stop
 *  closes minim and sound properly
 */
void stop()
{
    microphone.close();
    m.stop();
    super.stop();
}

