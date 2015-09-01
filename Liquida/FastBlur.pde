/**
 * FastBlur
 * Based on Mario Klingemann's Super Fast Blur
 * @see SuperFastBlur by Mario Klingemann <http://incubator.quasimondo.com>
 *
 */
 
class FastBlur {
      
    int w, h, wm, hm, wh, rsum, gsum, bsum, x, y, i, p, p1, p2, yp, yi, yw, radius;
    int[] r, g, b, vmin, vmax, pix, dv;
  
    FastBlur(int w, int h, int radius)
    {
        if (radius < 1) {
            println("Radius must be bigger than one");
            return;  
        }
        this.w = w;
        this.h = h;
        this.radius = radius;
        
        wm   = w-1;
        hm   = h-1;
        wh   = w*h;
        yw   = 0;
        yi   = 0;
        r    = new int[wh];
        g    = new int[wh];
        b    = new int[wh];
        vmin = new int[max(w, h)];
        vmax = new int[max(w, h)];
        int div  = 2 * radius + 1;
        int dv_sz = 256 * div;
        dv   = new int[dv_sz];    
        for (i = 0; i < dv_sz; i++) 
          dv[i] = i/div;        
    }  
    
    void blur(PImage frame)
    {
        frame.loadPixels();
        
        yw = yi = 0;
        
        for (y = 0; y < h; y++)
        {
            rsum = gsum = bsum = 0;
            
            for(i = -radius; i <= radius; i++){
                p     =  frame.pixels[ yi + min(wm, max(i, 0)) ];
                rsum += (p >> 16) & 0xFF;
                gsum += (p >>  8) & 0xFF;
                bsum +=  p        & 0xFF;
            }
            for (x = 0; x < w; x++){
                r[yi] = dv[rsum];
                g[yi] = dv[gsum];
                b[yi] = dv[bsum];
          
                if(y == 0) {
                  vmin[x] = min(x+radius+1, wm);
                  vmax[x] = max(x-radius, 0);
                }
                
                p1 = frame.pixels[yw + vmin[x]];
                p2 = frame.pixels[yw + vmax[x]];
          
                rsum += (p1 & 0xFF0000) - (p2 & 0xFF0000) >> 16;
                gsum += (p1 & 0x00FF00) - (p2 & 0x00FF00) >> 8;
                bsum += (p1 & 0x0000FF) - (p2 & 0x0000FF);
                yi++;
            }
            yw += w;
        }
      
        for (x = 0; x < w; x++)
        {
            rsum = gsum = bsum = 0;
            yp   =- radius*w;
            for(i = -radius; i <= radius; i++){
                yi = max(0, yp) + x;
                rsum += r[yi];
                gsum += g[yi];
                bsum += b[yi];
                yp += w;
            }
            yi = x;
            for (y = 0; y < h; y++){
                frame.pixels[yi] = 0xFF000000 | (dv[rsum] << 16) | (dv[gsum] << 8) | dv[bsum];
                if(x == 0){
                  vmin[y] = w * min(y+radius+1, hm);
                  vmax[y] = w * max(y-radius, 0);
                }
                p1 = x + vmin[y];
                p2 = x + vmax[y];
          
                rsum += r[p1] - r[p2];
                gsum += g[p1] - g[p2];
                bsum += b[p1] - b[p2];
          
                yi += w;
            }
        }
        frame.updatePixels();        
    }
}
         
