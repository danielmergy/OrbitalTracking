#include <arduino.h>
#include <SPI.h>
#include <cmath>
#include <iostream>
#include <vector>
#define _USE_MATH_DEFINES
#include <float.h>

#define SPI_WRITE_COMMAND                 (1<<7)
#define ADDR_PERIPH_PWM                   (1<<3)
#define ADDR_SPI_THRESHOLD                   0
#define ADDR_SPI_WIDTH                       1

#define FPGA_CLOCK 
#define FPGA_MB_INT                       (31u)
#define FPGA_INT                          (33u) //B2 N2
#define FPGA_TDI                            (26u)
#define FPGA_TDO                            (29u)
#define FPGA_TCK                            (27u)
#define FPGA_TMS                            (28u)

#define MAX_INT                         2147483647

const int slaveSelectPin = FPGA_MB_INT;
const int burst_flag_pin = FPGA_MB_INT; //TODO


const int N=64;
const int M =512;
//float w2 = 0.04;

//int Burst_threshold = 0;
//const int iteration_threshold = (int)(N*exp((-2/w2)*(p0-r))^2)


//Used to move the center of the orbit to the closest point to the particle
void findClosestPoint(float x, float y, int* closest_point_x, int* closest_point_y){
    int x_coord_lst[1000];
    int y_coord_lst[1000];
    int min = -10;
    int max = 10;
    int incr = 2;
    int index = 0;

	//grid simulation part
    for (int i = min; i <= max; i += incr) {
        for (int j = min; j <= max; j += incr) {
            x_coord_lst[index] = i;
            y_coord_lst[index] = j;
            index++;
        }
    }


    float min_d = FLT_MAX;

    

    //Serial.print(index);
    //Serial.print(",");
    //Serial.println("1,2,3,4,5");

  
    for (int i = 0; i < index; i += 1) {
        for (int j = 0; j < index; j += 1) {
            float d = sqrt( pow(x_coord_lst[i]-x,2)+ pow(y_coord_lst[j]-y,2) );
            if (d < min_d)
            {
                min_d = d;
                *closest_point_x = x_coord_lst[i]; 
                *closest_point_y = y_coord_lst[j];
            }
        }
    }

   //consider using d for improving next estimation
}
//Based on photons recived in the last loop compute the particle position
int calculateValues(int nk_lst1[], int N, float* x, float* y) {
    int a0 = 0;
    float a1 = 0.0;
    float b1 = 0.0;

    for (int i = 0; i < N; i++)
    {
      int val = nk_lst1[i];
      a0 = a0 + val;
      a1 = a1 + val * cos (2 * M_PI * i * (1.0 / N));
      b1 = b1 + val * sin (2 * M_PI * i * (1.0 / N));
    }

    float phi_rad = atan2 (b1, a1);
    float rho_relative = sqrt (pow (a1, 2) + pow (b1, 2)) * (1.0 / a0);
    float w2 = 40000;
    float r = 0.6 * 200;
    float rho_nm = (rho_relative * w2) / (2.0 * r);
    
    *x = rho_nm * cos (phi_rad);
    *y = rho_nm * sin (phi_rad);
	
	return a0;
}

//Called by start_orbital_tracking(), generate a circular array for the laser
void generateCircleCoordinates(int xa, int ya, int r, int N, float X[], float Y[]) {
    float theta = 0;
    float dtheta = 2 * M_PI / N;
    
    for (int i = 0; i < N; i++) {
        X[i] = xa + r * cos(theta);
        Y[i] = ya + r * sin(theta);
        theta += dtheta;
    }
}

//When Burst Flag have been spotted bein the orbital tracking
void start_orbital_tracking(int X, int Y) {
  Serial.println("(MCU) A Burst has been detected! , scanning the neighborhood...");
	//FPGA mode = counter
	int x = X;
	int y = Y;

  float x_hat = x;
  float y_hat = y;
	int a0 = MAX_INT;
  int j = 0;

	//while (a0 > 100) 

  while (j < 1) { 
		int nk_lst[N];
		float x_coord_lst[N]; //maybe is doing problems
		float y_coord_lst[N];

		generateCircleCoordinates(x, y, 120, N, x_coord_lst, y_coord_lst);
		for (int i=0; i<N; i++) {
			analogWrite(A1, x_coord_lst[i]);
			analogWrite(A2, y_coord_lst[i]);
			delay(1);  //1 ms  
			//nk_lst[i] = SPI.transfer(0);
      nk_lst[i] = 24;

      #if ((y_coord_lst[i] <= 320.0)  & (x_coord_lst[i] >= 410.0) & (x_coord_lst[i] <= 430.0 ))
        { nk_lst[i] = 1000; } 
      Serial.print(millis());
      Serial.print(",");
      Serial.print(x_coord_lst[i]);
      Serial.print(",");
      Serial.print( y_coord_lst[i]);
      Serial.print(",");
      Serial.print(nk_lst[i]);
      Serial.print(",");
      Serial.print(x_hat);
      Serial.print(",");
      Serial.println(y_hat);
		}
		a0 = calculateValues(nk_lst,64, &x_hat, &y_hat);
		int closest_point_x, closest_point_y;
		findClosestPoint(x_hat, y_hat, &closest_point_x, &closest_point_y); //TODO adapt to struct point ?

    Serial.print(millis());
    Serial.print(",");
    Serial.print(0);
    Serial.print(",");
    Serial.print(closest_point_x);
    Serial.print(",");
     Serial.print(0);
    Serial.print(",");
    Serial.print(closest_point_y);
    Serial.print(",");
    Serial.println(0);
    
    


		x = closest_point_x;
		y = closest_point_y;
    j = j + 1;
	}
  Serial.println("(MCU) EndOfTransmissions");
  return;
}

//Generate a sequence of locations in a Raster Fashion for start_finding()
void RasterScanGenerator(int X0, int Y0, int Side, int* ptr_x, int* ptr_y) {
  int X, Y, next_X, i;
  int flag = 1;
    X = X0;
  for (Y = Y0; Y > Y0 - Side; Y--)
  {
      i = 0;
    while(i < Side)
    {
        *ptr_x = X;
        *ptr_y = Y;
        ptr_x ++;
        ptr_y ++;
        next_X = flag ? X+1 : X-1;
      X = (i != Side - 1) ? next_X : X;
      i++;
    }
    flag = 1 - flag;
  }
  *ptr_x = X;
}

//Called from handleCommand() : look for particle with a raster algo
void start_finding() {

 //find_particle_in_fullgrid	
 //FULL GRID # LOCATIONS = M

 int* arrX = (int *) malloc(10*10*sizeof(int));
 int* arrY = (int *) malloc(10*10*sizeof(int));

 RasterScanGenerator (10, 10, 10, arrX, arrY);


 int i=0;
 while (i<N)
 {
  analogWrite(A1, arrX[i]); //MirrorX
  analogWrite(A2, arrY[i]); //MirrorY
  delay(1);  //1 ms  
  //int nk = SPI.transfer(0); //timestamps  
  //if (digitalRead(burst_flag_pin)) //  from FPGA
    //break
  i=i+1;  
 }
 //start_orbital_tracking(arrX[i],arrY[i]);
 start_orbital_tracking(420,420);

 free(arrY);
 free(arrY);
 Serial.println("Done");


  //Serial.println("(MCU) EndOfProcedure");


}

//Used for writing values to FPGA registers controling HW BurstSearch
void SPIFPGAWrite(int adresse, int valeur) {

  // Selectionne le SS du FPGA
  digitalWrite(slaveSelectPin, LOW);
  
  //  Envoi la commande et la donnee
  //  Avec la configuration actuelle du FPGA : 1 seule donnee
  SPI.transfer(adresse);
  SPI.transfer(valeur);

  // Deselectionne le SS du FPGA
  digitalWrite(slaveSelectPin, HIGH);
}

//Used in BurstStream()
void burst(int duration) {
  for(int i=0; i<duration; i++) 
  {
    Serial.print(1);
    Serial.print(',');
    Serial.println('1');
  }  

  Serial.print(1);
  Serial.print(',');
  Serial.println('0');
}

//Used in BurstStream()
void pause() {
  Serial.print(20);
  Serial.print(',');
  Serial.println('0');
}

//Emulation of Recieved photons
void BurstStream(unsigned long duration, int maxcount) {

  int count = 0;
  unsigned long start_time = millis();
  while ((millis()- start_time < duration) & (count < maxcount))
  {
  pause();
  burst(5);
  count = count + 5 + 2;
  }
  Serial.println("(MCU) EndOfTransmission");
}
  
//Main Function for getting commands from PC  
void handleCommand(String command) {
  
  //default values
  static int N = 8;
  static int F = 6;
  static int T = 10;

  String parts[3];
  int i = 0;
  String part = "";
  for (int j = 0; j < command.length(); j++) {
    if (command[j] != ' ') {
      part += command[j];
    } else {
      parts[i] = part;
      i++;
      part = "";
    }
  }
  parts[i] = part;
  

  if (parts[0] == "bsearch") {
    unsigned long max_long; 
    unsigned long value = 0;
    max_long = value-1;
    int data_from_pc = atoi(parts[1].c_str());
    //delay(1000);

    if (parts[2] == "msec") {
    Serial.println("(MCU) getting values for several mseconds");
    BurstStream(data_from_pc, MAX_INT);
    }

    else if (parts[2] == "sec") {
    Serial.println("(MCU) getting values for several seconds");
    BurstStream(data_from_pc*1000, MAX_INT);
    }
    else if (parts[2] == "min") { 
    Serial.println("(MCU) getting values for several minutes");
    BurstStream(data_from_pc*60000, MAX_INT);
    }
    else if (parts[2] == "photons") {
    Serial.println("(MCU) getting values until max photons is reached");
    BurstStream(max_long, data_from_pc);
    }
  }

  else if (parts[0] == "set") {
    if (parts[1] == "N") {
      N = atoi(parts[2].c_str());
      Serial.print("(MCU) N was set to: ");
      Serial.println(N);
      SPIFPGAWrite(SPI_WRITE_COMMAND | ADDR_PERIPH_PWM | ADDR_SPI_WIDTH, N); 
      }
    if (parts[1] == "T") {
      T = atoi(parts[2].c_str());  
      Serial.print("(MCU) T was set to: ");
      Serial.println(T);
      SPIFPGAWrite(SPI_WRITE_COMMAND | ADDR_PERIPH_PWM | ADDR_SPI_THRESHOLD, T*F); 
      }
    if (parts[1] == "F") {
      F = atoi(parts[2].c_str());  
      Serial.print("(MCU) F was set to: ");
      Serial.println(F);
      SPIFPGAWrite(SPI_WRITE_COMMAND | ADDR_PERIPH_PWM | ADDR_SPI_THRESHOLD, T*F); 
      }
  }
   
  else if (parts[0] == "start_finding") {
    Serial.println("(MCU) Finding Procedure has started: ");
    //FPGA_MODE = NK 
	  start_finding();
    //Serial.println("(MCU) Finding Procedure has ended: ");
  }
   
}

//Arduino STD Setup Function
void setup() {
  Serial.begin(9600);
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(FPGA_TDO, INPUT);
  pinMode(FPGA_TMS, INPUT); 
  pinMode(FPGA_TDI, INPUT);
  pinMode(FPGA_TCK, INPUT);
  pinMode(FPGA_INT, INPUT);
  pinMode (slaveSelectPin, OUTPUT);
  SPI.begin();
  digitalWrite(slaveSelectPin, HIGH);
  //Load Default Configuaration for FPGA : N=8 , F = 6 , T = 10 (in 5ns)
  SPIFPGAWrite(SPI_WRITE_COMMAND | ADDR_PERIPH_PWM | ADDR_SPI_WIDTH, 8);  
  SPIFPGAWrite(SPI_WRITE_COMMAND | ADDR_PERIPH_PWM | ADDR_SPI_THRESHOLD, 6*10);
}

//Constantly waiting for commands
void loop() {
  if (Serial.available() > 0) {
    String command = Serial.readString();
    handleCommand(command);
  }
}

