/* Processing Water Simulation
* adapted by: Rodrigo Amaya
*
* Based on "Java Water Simulation", by: Neil Wallis
* For more information visit the original article here:
* http://neilwallis.com/projects/java/water/index.php
*
* How does it work? "2D Water"
* http://freespace.virgin.net/hugo.elias/graphics/x_water.htm
*
*/
 
//import processing.opengl.*;
 
PImage img;
 
int 
  w = 1300, 
  h = 867, 
  wh = w*h,
  size = w * (h+2) * 2, 
  w_2 = w / 2, 
  h_2 = h / 2,
  oldind = w, 
  newind = w*(h+3), 
  mapind, 
  radius = 5, //test with 3
  i, a, b;

short data;
 
int[] ripplemap, ripple, texture;

PVector[] cursors;
float cx1 = w_2, cy1 = h_2; 
 
void setup()
{
  size(w, h);
  img = loadImage("bg.jpg");   
  ripplemap = new int[size];
  ripple    = new int[wh];
  texture   = new int[wh];  
  noCursor();
  background(img);
}
 
void draw() 
{
  frame.setTitle(nfc(frameRate, 2));
  image(img, 0, 0);
  loadPixels();
  texture = pixels;
   
  //Toggle maps each frame
  i      = oldind;
  oldind = mapind = newind;
  newind = i;
  
  for (int y = 0, i = 0; y < h; y++) 
    for (int x = 0; x < w; x++) {
      data = (short)((ripplemap[mapind - w] + ripplemap[mapind + w] + ripplemap[mapind - 1] + ripplemap[mapind + 1]) >> 1);
      data -= ripplemap[newind+i];
      data -= data >> 5;
      ripplemap[newind+i] = data;
 
      //where data=0 then still, where data>0 then wave
      data = (short)(1024-data);
 
      //offsets
      a = ((x - w_2) * data/1024) + w_2;
      b = ((y - h_2) * data/1024) + h_2;
 
      //bounds check
      if (a >= w) a = w-1; else if (a < 0) a = 0;
      if (b >= h) b = h-1; else if (b < 0) b = 0;
 
      ripple[i] = texture[a+(b * w)];
      mapind++;
      i++;
  }
  arrayCopy(ripple, 0, pixels, 0, wh);  
  updatePixels();
}
 
void disturb(int dx, int dy) 
{  
  for (int y = dy - radius; y < dy + radius; y++) 
    for (int x= dx - radius; x < dx + radius; x++) 
      if (y >= 0 && y < height && x >=0 && x < width) 
        ripplemap[oldind + (y*width) + x] += 128;   //test with 512
  cx1 += random(-10, 10);
  cy1 += random(-10, 10);
  dx = int(cx1);
  dy = int(cy1);  
  for (int y = dy - radius; y < dy + radius; y++) 
    for (int x= dx - radius; x < dx + radius; x++) 
      if (y >= 0 && y < height && x >=0 && x < width) 
        ripplemap[oldind + (y*width) + x] += 128;   //test with 512
}
 
void mouseMoved(){
  disturb(mouseX, mouseY);
}
 

