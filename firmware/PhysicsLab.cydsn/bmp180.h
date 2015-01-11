
#ifndef BMP180_H
#define BMP180_H

#include <project.h>


    
#define BMP085_ADDRESS 0x77

void BMP180init(void);

float BMP180GetTemperature();
long BMP180GetPressure();
float BMP180GetAltitude();
unsigned short BMP180ReadUT(void);
unsigned long BMP180ReadUP(void);
void BMP180ReadSensor(void);
uint32 BMP180test();
inline int BMP180isBroken();



#endif
