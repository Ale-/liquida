abstract class ProgressIcon {

    PGraphics icon;
  
    ProgressIcon(int w, int h){
        icon = createGraphics(w, h);
    }  
  
    abstract PImage show();  
}

class AsteroidProgressIcon extends ProgressIcon
{
    float r, a = 0f;    
    int fill, s_2;
  
    AsteroidProgressIcon(int s, float r, int fill)
    {
        super(s, s);
        s_2 = s/2; 
        this.r = r;
        this.fill = fill; 
    }
  
    PImage show()
    {
        icon.beginDraw();
        icon.noStroke();
        icon.fill(-1, 25);
        icon.rect(0, 0, icon.width, icon.height);
        icon.fill(fill);
        icon.ellipse(s_2 + cos(a) * (s_2 - r), s_2 + sin(a) * (s_2 - r), r, r);    
        icon.endDraw();
        a = (a + .1) % TWO_PI;
        return (PImage)icon;
    }    
}
