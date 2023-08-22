
#include <cmath>
#include <iostream>
#include <vector>
#define _USE_MATH_DEFINES
#include <float.h>
using namespace std;



#define CENTERED 24,24,24,24
#define ONRADIUS 1,200,200,200
//#define BACKGRND ,5,5,5,5,5,5,5,5
#define BACKGRND ,1,1,1,1,1,1,1,1
#define HALF_RAD ,30,35,42,35,30,15,5,


float myErfInv2(float x){
   float tt1, tt2, lnx, sgn;
   sgn = (x < 0) ? -1.0f : 1.0f;

   x = (1 - x)*(1 + x);        // x = 1 - x*x;
   lnx = logf(x);

   tt1 = 2/(M_PI*0.147) + 0.5f * lnx;
   tt2 = 1/(0.147) * lnx;

   return(sgn*sqrtf(-tt1 + sqrtf(tt1*tt1 - tt2)));
}


int main ()
{
  //int nk_lst1[] = {CENTERED CENTERED CENTERED CENTERED CENTERED CENTERED CENTERED CENTERED };
  int nk_lst1[] = {ONRADIUS BACKGRND BACKGRND BACKGRND BACKGRND BACKGRND BACKGRND BACKGRND }; 
  //int nk_lst1[] = {HALF_RAD  BACKGRND BACKGRND BACKGRND BACKGRND BACKGRND BACKGRND }; 

  int a0 = 0;
  float a1 = 0.0;
  float b1 = 0.0;
  
  float w = 200;
  int N = 60;
  float w2 = 40000;		//nm^2
  float r = 0.6 * 200;	//nm
  float dt = 1;			//ms

  for (int i = 0; i < N; i++)
    {
      int val = nk_lst1[i];	//ms^-1
      a0 = a0 + val;
      a1 = a1 + val * cos (2 * M_PI * i * (1.0 / N));
      b1 = b1 + val * sin (2 * M_PI * i * (1.0 / N));
    }
    
  //cout << "a0: " << a0 << endl;
  //cout << "a1: " << a1 << endl;
  //cout << "b1: " << b1 << endl;
  
  
  //a0 = a0 * dt * exp(-1.2*(r/w));
  
  
  
  float phi_rad = atan2 (b1, a1);
  float rho_relative = sqrt (pow (a1, 2) + pow (b1, 2)) * (1.0 / a0); 
  //int index = floor((phi_rad * N) / (2*M_PI));
  
  cout << "rho (relat): " << rho_relative << endl;

  //rho_relative = 1;
  
  float phi_deg =  phi_rad * 180 * (1.0 / M_PI);
  
  
 float rho_nm = (rho_relative * w2) / (2.0 * r);   
 //float rho_nm = (w2/(4.0*r))*tan((M_PI/2.0)*rho_relative);
 //float rho_nm = (w2/(2.4*r)) * myErfInv2((4/3)*rho_relative);
 
 
 
  
  cout << "rho (nm): " << rho_nm << endl;
  cout << "phi (degree): " << phi_deg << endl;
  //cout << "index: " << index << endl;
 
  float x = rho_nm * cos (phi_rad);
  float y = rho_nm * sin (phi_rad);

  cout << "x (nm): " << x << endl;
  cout << "y (nm): " << y << endl;


    
  //Part to simulate points avalaible 

  int min = -150; //take points around the center
  int max = 150;
  int incr = 50;
  int index = 0; // depends on DAC Resolution
  
  int array_len = pow((abs(min) + abs(max) + 2),2);
  
  int x_coord_lst[array_len];
  int y_coord_lst[array_len];
  

  for (int i = min; i <= max; i += incr) {
      for (int j = min; j <= max; j += incr) {
          x_coord_lst[index] = i;
          y_coord_lst[index] = j;
          index++;
      }
  }
  

    //for (int i = 0; i < index; ++i) {std::cout << "x = " << x_coord_lst[i] << ",y = " << y_coord_lst[i] << std::endl;}

    std::cout << "index = " <<  index <<std::endl;


  int closest_point_x;
  int closest_point_y;
  float min_d = FLT_MAX;
  
  //Find closest point. Can be avoided by casting to int in AnalogWrite ??
  
  for (int i = 0; i < index; i += 1) {
    for (int j = 0; j < index; j += 1) {
    float d = sqrt( pow(x_coord_lst[i]-x,2)+ pow(y_coord_lst[j]-y,2) );
    if (d < min_d)
      {
      min_d = d;
      closest_point_x = x_coord_lst[i];
      closest_point_y = y_coord_lst[j];
      }
   }
  }
  
  
  cout << "closest x (nm): " << closest_point_x << endl;
  cout << "closest y (nm): " << closest_point_y << endl;  
  cout << "min_d     (nm): " << min_d << endl;

} 
