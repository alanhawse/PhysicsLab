#include "htu21.h"


//////////////////////// HTU21  ///////////////////////
#define HTU21I2CDEVICE 0x40
#define HTU21userRegister 0xE7
#define HTU21triggerTemp 0xF3
#define HTU21triggerHumidity 0xF5
#define HTU21softResetCmd 0xFE

typedef enum {
    HTU21Idle,
    HTU21ReadTemp,
    HTU21ReadHumidity
} HTU21State;

int HTU21BrokenFlag;

inline int HTU21isBroken()
{
    return HTU21BrokenFlag;
}

float HTU21Temperature;
float HTU21Humidity;

inline float HTU21GetTemperature()
{
    return HTU21Temperature;
}

inline float HTU21GetHumidity()
{
    return HTU21Humidity;
}

int HTU21process()
{
    static HTU21State state = HTU21Idle;
    uint32 rval;
    uint8 buff[10];
 
    
   // rval = I2C_I2CMasterStatus();
   // if(rval & I2C_I2C_MSTAT_XFER_INP) 
   //     return 1;
    
    switch(state)
    {
        case HTU21Idle:
            // trigger temperature reading
            I2C_I2CMasterClearStatus();
            rval = I2C_I2CMasterSendStart(HTU21I2CDEVICE,0); // write
            rval = I2C_I2CMasterWriteByte(HTU21triggerTemp);
            state = HTU21ReadTemp;
        break;
        case HTU21ReadTemp:
            // send the restart
            rval = I2C_I2CMasterSendRestart(HTU21I2CDEVICE,I2C_I2C_READ_XFER_MODE);
            if(rval & I2C_I2C_MSTR_ERR_LB_NAK)
                return 1;
             buff[0] = I2C_I2CMasterReadByte(I2C_I2C_ACK_DATA);
             buff[1] = I2C_I2CMasterReadByte(I2C_I2C_NAK_DATA);
            I2C_I2CMasterSendStop();       
 
            HTU21Temperature = -46.85 + 175.72 * (buff[0]<<8 | buff[1]) / 65536.0; // from the datasheet degrees C
            
            I2C_I2CMasterClearStatus();
            rval = I2C_I2CMasterSendStart(HTU21I2CDEVICE,0); // write
            rval = I2C_I2CMasterWriteByte(HTU21triggerHumidity);
            state = HTU21ReadHumidity;          
        break;

        case HTU21ReadHumidity:
            rval = I2C_I2CMasterSendRestart(HTU21I2CDEVICE,I2C_I2C_READ_XFER_MODE);
            if(rval & I2C_I2C_MSTR_ERR_LB_NAK)
                return 1;
            buff[0] = I2C_I2CMasterReadByte(I2C_I2C_ACK_DATA);
            buff[1] = I2C_I2CMasterReadByte(I2C_I2C_NAK_DATA);
            I2C_I2CMasterSendStop();
            HTU21Humidity = -6 + 125 * (buff[0]<<8 | buff[1]) / 65536.0; // from the datasheet
            
            state = HTU21Idle;
        break;
    }
    
    if(state == HTU21Idle)
        return 0;
    return 1;
}



void HTU21ReadSensor()
{
    while(HTU21process());
}




uint32 HTU21test()
{
    uint8 buff[2];
    uint32 rval;
    uint32 teststatus=0;
    
    HTU21BrokenFlag = 1;
    
    buff[0] = HTU21userRegister; 
    buff[1] = 0;
    
    rval = I2C_I2CMasterWriteBuf(HTU21I2CDEVICE,buff,1,I2C_I2C_MODE_COMPLETE_XFER);
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
    
    rval = I2C_I2CMasterReadBuf(HTU21I2CDEVICE,buff,1,I2C_I2C_MODE_COMPLETE_XFER);
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
    
    if(buff[0] != 0x02) // default value of user register from the datasheet
    {
        teststatus |= 16;
        return teststatus;
    }
    
    HTU21BrokenFlag = 0;
    return 0;
    
}

void HTU21Enable()
{
    uint8 buff[1]; 
    buff[0] = HTU21softResetCmd;
    I2C_I2CMasterWriteBuf(HTU21I2CDEVICE,buff,1,I2C_I2C_MODE_COMPLETE_XFER);
}
