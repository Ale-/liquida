
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
 
 
PImage img;
 
int w, h, wh, size, w_2, h_2, oldind, newind, mapind, visitors_number = 1, radius = 5, i, a, b;

short data;
 
int[] ripplemap, ripple, texture;
int[][] visitors;

float cx1 = w_2, cy1 = h_2; 
 
void setup()
{
  img = loadImage("bg.jpg");   
  size(img.width, img.height);
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
  texture   = new int[wh];  
  visitors  = new int[visitors_number][2];
  noCursor();
  background(img);
}
 
void draw() 
{
  frame.setTitle(nfc(frameRate, 2));
  background(img);
  loadPixels();
  arrayCopy(pixels, 0, texture, 0, wh);  
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
      a = ((x - w_2) * data/1024) + w_2;
      b = ((y - h_2) * data/1024) + h_2;
      if (a >= w) a = w-1; else if (a < 0) a = 0;
      if (b >= h) b = h-1; else if (b < 0) b = 0; 
      ripple[i] = texture[a+(b * w)];
      mapind++;
      i++;
  }
  arrayCopy(ripple, 0, pixels, 0, wh);  
  updatePixels();
  visitors[0][0] = mouseX;
  visitors[0][1] = mouseY;
  for(int v = 0; v < visitors.length; v++)
      for (int y = visitors[v][1] - radius; y < visitors[v][1] + radius; y++) 
        for (int x= visitors[v][0] - radius; x < visitors[v][0] + radius; x++) 
          if (y >= 0 && y < h && x >=0 && x < w) 
            ripplemap[oldind + (y*w) + x] += 128; 
}



