
//////////////////// BMP180 ////////////
#include "bmp180.h"
#include <math.h>
#include <stdlib.h>

#define BMP180I2CDEVICE 0x77

uint8 BMP180Read(uint8);
short BMP180ReadInt(uint8);
long BMP180CalculatePressure(unsigned long up);
float BMP180CalculateTemperature(unsigned short ut);

int BMP180BrokenFlag;


short ac1;
short ac2;
short ac3;
unsigned short ac4;
unsigned short ac5;
unsigned short ac6;
short b1;
short b2;
short mb;
short mc;
short md;
long PressureCompensate;
const unsigned char OSS = 0;

float BMP180Temperature; // temperature degrees c
long BMP180Pressure; // pressure in Pa
float BMP180Altitude; // 

inline int BMP180isBroken()
{
    return BMP180BrokenFlag;
}

inline float BMP180GetAltitude()
{
    return BMP180Altitude;
}

uint32 BMP180test()
{
    uint8 buff[2];
    uint32 rval;
    uint32 teststatus=0;
    
    buff[0] = 0xD0;  //device id register
    buff[1] = 0;

    BMP180BrokenFlag = 1;
    
    rval = I2C_I2CMasterWriteBuf(BMP180I2CDEVICE,buff,1,I2C_I2C_MODE_COMPLETE_XFER);
    if(rval != I2C_I2C_MSTR_NO_ERROR)
    {
        teststatus |= 1;
       
        return teststatus;
    }
    
    CyDelay(1);
    
    rval = I2C_I2CMasterStatus();
    if(rval & I2C_I2C_MSTAT_ERR_XFER) // any error condition
    {
        teststatus |= 2;

        return teststatus;
    }
    
    rval = I2C_I2CMasterReadBuf(BMP180I2CDEVICE,buff,1,I2C_I2C_MODE_COMPLETE_XFER);
    if(rval != I2C_I2C_MSTR_NO_ERROR)
    {

        teststatus |= 4;
        return teststatus;
    }
    
    CyDelay(1);
    
    rval = I2C_I2CMasterStatus();
    if(rval & I2C_I2C_MSTAT_ERR_XFER) // any error condition
    {

        teststatus |= 8;
        return teststatus;
    }
    
    if(buff[0] != 0x55) // device ID from datasheet
    {


        teststatus |= 16;
        return teststatus;
    }
    
    BMP180BrokenFlag = 0;
    return 0;
    
}



void BMP180init(void)
{
    if(BMP180isBroken())
        return;
    
    ac1 = BMP180ReadInt(0xAA);
    ac2 = BMP180ReadInt(0xAC);
    ac3 = BMP180ReadInt(0xAE);
    ac4 = BMP180ReadInt(0xB0);
    ac5 = BMP180ReadInt(0xB2);
    ac6 = BMP180ReadInt(0xB4);
    b1 = BMP180ReadInt(0xB6);
    b2 = BMP180ReadInt(0xB8);
    mb = BMP180ReadInt(0xBA);
    mc = BMP180ReadInt(0xBC);
    md = BMP180ReadInt(0xBE);
    
}

// Read 1 byte from the BMP180 at 'address'
// Return: the read byte;
uint8 BMP180Read(uint8 reg)
{
    uint8 buff[2];
    buff[0]=reg;
    
    I2C_I2CMasterWriteBuf(BMP180I2CDEVICE,buff,1,I2C_I2C_MODE_COMPLETE_XFER);
    while( !(I2C_I2CMasterStatus() & I2C_I2C_MSTAT_WR_CMPLT));
    I2C_I2CMasterReadBuf(BMP180I2CDEVICE,buff,1,I2C_I2C_MODE_COMPLETE_XFER);
    while(!(I2C_I2CMasterStatus() & I2C_I2C_MSTAT_RD_CMPLT));
    return buff[0];
    
}

// Read 2 bytes from the BMP180
// First byte will be from 'address'
// Second byte will be from 'address'+1
short BMP180ReadInt(uint8 reg)
{
    
    uint8 buff[2];
    buff[0]=reg;
    
    I2C_I2CMasterWriteBuf(BMP180I2CDEVICE,buff,1,I2C_I2C_MODE_COMPLETE_XFER);
    while( !(I2C_I2CMasterStatus() & I2C_I2C_MSTAT_WR_CMPLT));
    I2C_I2CMasterReadBuf(BMP180I2CDEVICE,buff,2,I2C_I2C_MODE_COMPLETE_XFER);
    while(!(I2C_I2CMasterStatus() & I2C_I2C_MSTAT_RD_CMPLT));
    return buff[0]<<8 | buff[1];
    
}

// Read the uncompensated temperature value
unsigned short BMP180ReadUT()
{
    unsigned short ut;
    
    if(BMP180isBroken())
        return 0;
    
    I2C_I2CMasterSendStart(BMP180I2CDEVICE,0); // write
    I2C_I2CMasterWriteByte(0xF4);
    I2C_I2CMasterWriteByte(0x2E);
    I2C_I2CMasterSendStop();
    CyDelay(5);
    ut = BMP180ReadInt(0xF6);
    
    BMP180Temperature = BMP180CalculateTemperature(ut);
    
    return ut;
}
// Read the uncompensated pressure value
unsigned long BMP180ReadUP()
{
    unsigned char msb, lsb, xlsb;
    unsigned long up = 0;
    
    if(BMP180isBroken())
        return 0;
   
    I2C_I2CMasterSendStart(BMP180I2CDEVICE,0); // write
    I2C_I2CMasterWriteByte(0xF4);
    I2C_I2CMasterWriteByte(0x34 + (OSS<<6));
    I2C_I2CMasterSendStop();
    
    CyDelay(2 + (3<<OSS));

    // Read register 0xF6 (MSB), 0xF7 (LSB), and 0xF8 (XLSB)
    msb = BMP180Read(0xF6);
    lsb = BMP180Read(0xF7);
    xlsb = BMP180Read(0xF8);
    up = (((unsigned long) msb << 16) | ((unsigned long) lsb << 8) | (unsigned long) xlsb) >> (8-OSS);
    
    BMP180Pressure = BMP180CalculatePressure(up);
    
    return up;
}


float BMP180CalculateAltitude(float pressure)
{
    float A = pressure/101325;
    float B = 1/5.25588;
    float C = pow(A,B);
    C = 1 - C;
    C = C /0.0000225577;
    return C;
}

inline float BMP180GetTemperature()
{
    return BMP180Temperature;
}

float BMP180CalculateTemperature(unsigned short ut)
{
    long x1, x2;

    x1 = (((long)ut - (long)ac6)*(long)ac5) >> 15;
    x2 = ((long)mc << 11)/(x1 + md);
    PressureCompensate = x1 + x2;

    float temp = ((PressureCompensate + 8)>>4);
    temp = temp /10;

    return temp;
}

inline long BMP180GetPressure()
{
    return BMP180Pressure;
}

long BMP180CalculatePressure(unsigned long up)
{
    long x1, x2, x3, b3, b6, p;
    unsigned long b4, b7;
    b6 = PressureCompensate - 4000;
    x1 = (b2 * (b6 * b6)>>12)>>11;
    x2 = (ac2 * b6)>>11;
    x3 = x1 + x2;
    b3 = (((((long)ac1)*4 + x3)<<OSS) + 2)>>2;

    // Calculate B4
    x1 = (ac3 * b6)>>13;
    x2 = (b1 * ((b6 * b6)>>12))>>16;
    x3 = ((x1 + x2) + 2)>>2;
    b4 = (ac4 * (unsigned long)(x3 + 32768))>>15;

    b7 = ((unsigned long)(up - b3) * (50000>>OSS));
    if (b7 < 0x80000000)
    p = (b7<<1)/b4;
    else
    p = (b7/b4)<<1;

    x1 = (p>>8) * (p>>8);
    x1 = (x1 * 3038)>>16;
    x2 = (-7357 * p)>>16;
    p += (x1 + x2 + 3791)>>4;

    long temp = p;
    return temp;
}

void BMP180ReadSensor(void)
{
    (void)BMP180ReadUT();
    (void)BMP180ReadUP();
    
     BMP180Altitude = BMP180CalculateAltitude(BMP180GetPressure());
}