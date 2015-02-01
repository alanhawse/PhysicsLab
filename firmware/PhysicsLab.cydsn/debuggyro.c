/* ========================================
 *
 * Copyright YOUR COMPANY, THE YEAR
 * All Rights Reserved
 * UNPUBLISHED, LICENSED SOFTWARE.
 *
 * CONFIDENTIAL AND PROPRIETARY INFORMATION
 * WHICH IS THE PROPERTY OF your company.
 *
 * ========================================
*/


#include <project.h>
#include "LSM9DS0.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#ifndef debug__DISABLED

void setup();
void printGyro();
void printAccel();
void printMag();
void printHeading(float hx, float hy);
void printOrientation(float x, float y, float z);
char *convertFloat(float f, char * buff);

//extern int16 LSM9DS0Gyro.x, LSM9DS0Gyro.y, LSM9DS0Gyro.z; // x, y, and z axis readings of the gyroscope
//extern	int16 LSM9DS0Accel.x, LSM9DS0Accel.y, LSM9DS0Accel.z; // x, y, and z axis readings of the accelerometer
//extern	int16 LSM9DS0Mag.x, LSM9DS0Mag.y, LSM9DS0Mag.z; // x, y, and z axis readings of the magnetometer

extern LSM9DS0DATA LSM9DS0Accel;
extern LSM9DS0DATA LSM9DS0Gyro;
extern LSM9DS0DATA LSM9DS0Mag;

extern uint32 systime;


int mainLoop()
{
    int nextprint=0;
    
   
    int displayFlag=0;

    setup();
    char c;
    
    UART_Start();
    
    for(;;)
    {
        c=UART_GetChar();
        
        switch(c)
        {
            case 'a':
            
            /* Place your application code here. */
              printGyro();  // Print "G: gx, gy, gz"
              printAccel(); // Print "A: ax, ay, az"
              printMag();   // Print "M: mx, my, mz"
      
             // Print the heading and orientation for fun!
                printHeading((float) LSM9DS0Mag.x, (float) LSM9DS0Mag.y);
                UART_PutString("\n");
                
         printOrientation(LSM9DS0_calcAccel(LSM9DS0Accel.x), LSM9DS0_calcAccel(LSM9DS0Accel.y), LSM9DS0_calcAccel(LSM9DS0Accel.z));
        UART_PutString("\n");
            break;
            case 'q':
                displayFlag ^= 0x01;
                break;

            case 'w':
                displayFlag ^= 0x02;
                break;

            case 'e':
                displayFlag ^= 0x04;
                break;
        
            case 'z':
                LSM9DS0GyroZero();
                break;
                
                case 'p':
                    printGyro();
                break;
        
        }
        
        if(systime>nextprint)
        {
            if(displayFlag & 0x01)
                printAccel();
            if(displayFlag & 02)
                printGyro();
            if(displayFlag & 0x04)
            {
                printMag();
                printHeading((float) LSM9DS0Mag.x, (float) LSM9DS0Mag.y);
            }   
            nextprint = systime + 250;
        }
        
        
  
    }
}



// Do you want to print calculated values or raw ADC ticks read
// from the sensor? Comment out ONE of the two #defines below
// to pick:
#define PRINT_CALCULATED
//#define PRINT_RAW

#define PRINT_SPEED 500 // 500 ms between prints

char buff[100];
char floatbuff0[10];
char floatbuff1[10];
char floatbuff2[10];
char floatbuff3[10];

void setup()
{

    
  uint16 status = LSM9DS0_begin(G_SCALE_245DPS,A_SCALE_2G,M_SCALE_2GS,G_ODR_95_BW_125,A_ODR_1600,M_ODR_100);
    
  //uint16 status = LSM9DS0_begin(LSM9DS0Gyro.yro_scale.G_SCALE_245DPS, LSM9DS0_accel_scale.A_SCALE_2G, LSM9DS0_mag_scale.M_SCALE_2GS, LSM9DS0Gyro.yro_odr.G_ODR_95_BW_125, LSM9DS0_accel_odr.A_ODR_1600, LSM9DS0_mag_odr.M_ODR_100);
  // Or call it with declarations for sensor scales and data rates:  
  //uint16 status = LSM9DS0_begin(LSM9DS0_G_SCALE_2000DPS, 
  //                            LSM9DS0_A_SCALE_6G, LSM9DS0_M_SCALE_2GS);
  
  // begin() returns a 16-bit value which includes both the gyro 
  // and accelerometers WHO_AM_I response. You can check this to
  // make sure communication was successful.
  UART_PutString("LSM9DS0 WHO_AM_I's returned: ");

    sprintf(buff,"%x should be 0x49d4\n",status);
    UART_PutString(buff);

 }



void printGyro()
{
  // To read from the gyroscope, you must first call the
  // readGyro() function. When this exits, it'll update the
  // gx, gy, and gz variables with the most current data.
  LSM9DS0_readGyro();
  
  // Now we can use the gx, gy, and gz variables as we please.
  // Either print them as raw ADC values, or calculated in DPS.
  UART_PutString("G: ");
// #ifdef PRINT_CALCULATED
  // If you want to print calculated values, you can use the
  // calcGyro helper function to convert a raw ADC value to
  // DPS. Give the function the value that you want to convert.
  convertFloat(LSM9DS0_calcGyro(LSM9DS0Gyro.x),floatbuff0);
  convertFloat(LSM9DS0_calcGyro(LSM9DS0Gyro.y),floatbuff1);
  convertFloat(LSM9DS0_calcGyro(LSM9DS0Gyro.z),floatbuff2);

    sprintf(buff, "%s , %s, %s  ",floatbuff0,floatbuff1,floatbuff2);
    UART_PutString(buff);
    
//#elif defined PRINT_RAW
    
  sprintf(buff,"%4x , %4x , %4x\n",LSM9DS0Gyro.x,LSM9DS0Gyro.y, LSM9DS0Gyro.z);
UART_PutString(buff);  
//#endif
}

void printAccel()
{
  // To read from the accelerometer, you must first call the
  // readAccel() function. When this exits, it'll update the
  // ax, ay, and az variables with the most current data.
  LSM9DS0_readAccel();
  
  // Now we can use the ax, ay, and az variables as we please.
  // Either print them as raw ADC values, or calculated in g's.
  UART_PutString("A: ");
#ifdef PRINT_CALCULATED
  // If you want to print calculated values, you can use the
  // calcAccel helper function to convert a raw ADC value to
  // g's. Give the function the value that you want to convert.
  

  convertFloat(LSM9DS0_calcAccel(LSM9DS0Accel.x),floatbuff0);
  convertFloat(LSM9DS0_calcAccel(LSM9DS0Accel.y),floatbuff1);
  convertFloat(LSM9DS0_calcAccel(LSM9DS0Accel.z),floatbuff2);

    sprintf(buff, "%s , %s, %s \n",floatbuff0,floatbuff1,floatbuff2);
    UART_PutString(buff);
#elif defined PRINT_RAW 
  
sprintf(buff,"%d , %d , %d\n ",LSM9DS0Accel.x,LSM9DS0Accel.y, LSM9DS0Accel.z);
UART_UartPutString(buff);
#endif

}

void printMag()
{
  // To read from the magnetometer, you must first call the
  // readMag() function. When this exits, it'll update the
  // mx, my, and mz variables with the most current data.
  LSM9DS0_readMag();
  
  // Now we can use the mx, my, and mz variables as we please.
  // Either print them as raw ADC values, or calculated in Gauss.
  UART_PutString("M: ");
#ifdef PRINT_CALCULATED
  // If you want to print calculated values, you can use the
  // calcMag helper function to convert a raw ADC value to
  // Gauss. Give the function the value that you want to convert.
#define MAGSCALE 10
convertFloat(LSM9DS0_calcMag(LSM9DS0Mag.x)*MAGSCALE,floatbuff0);
  convertFloat(LSM9DS0_calcMag(LSM9DS0Mag.y)*MAGSCALE,floatbuff1);
  convertFloat(LSM9DS0_calcMag(LSM9DS0Mag.z)*MAGSCALE,floatbuff2);

    sprintf(buff, "%s , %s, %s ",floatbuff0,floatbuff1,floatbuff2);
    UART_PutString(buff);

      
sprintf(buff,"%x , %x , %x  ",LSM9DS0Mag.x,LSM9DS0Mag.y, LSM9DS0Mag.z);
UART_PutString(buff);

#endif
}

// Here's a fun function to calculate your heading, using Earth's
// magnetic field.
// It only works if the sensor is flat (z-axis normal to Earth).
// Additionally, you may need to add or subtract a declination
// angle to get the heading normalized to your location.
// See: http://www.ngdc.noaa.gov/geomag/declination.shtml
void printHeading(float hx, float hy)
{
  
  float heading;
  
  if (hy > 0)
  {
    heading = 90 - (atan(hx / hy) * (180 / 3.1415926));
  }
  else if (hy < 0)
  {
    heading = - (atan(hx / hy) * (180 / 3.1415926));
  }
  else // hy = 0
  {
    if (hx < 0) heading = 180;
    else heading = 0;
  }
  
    sprintf(buff,"Heading = %s\n",convertFloat(heading,floatbuff0));
 
     UART_PutString(buff);
 
}

// Another fun function that does calculations based on the
// acclerometer data. This function will print your LSM9DS0's
// orientation -- it's roll and pitch angles.
void printOrientation(float x, float y, float z)
{
  float pitch, roll;
  
  pitch = atan2(x, sqrt(y * y) + (z * z));
  roll = atan2(y, sqrt(x * x) + (z * z));
  pitch *= 180.0 / 3.1415926;
  roll *= 180.0 / 3.1415926;
  
  sprintf(buff,"Pitch = %s \n",convertFloat(pitch,floatbuff0));
    UART_PutString(buff);
      sprintf(buff,"Roll = %s \n",convertFloat(roll,floatbuff0));
    UART_PutString(buff);
  
}

char *convertFloat(float f, char * buff)
{
    int i ;
    int pos1, pos2;
    char sign=' ';
    if (f<0)
    {
        sign='-';
        f=f*-1;
    }
    
    i = f;
    
    f=f-i;
    f = f * 10;
    pos1 = f;
    f = f - pos1;
    f = f * 10;
    pos2 = f;
    
    sprintf(buff,"%c%d.%c%c",sign,i,'0'+pos1,'0'+pos2);
    return buff;
}
#endif

