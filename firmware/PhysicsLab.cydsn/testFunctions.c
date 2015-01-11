

#include <project.h>
#include <testFunctions.h>
#include "bmp180.h"
#include "htu21.h"
#include "lsm9ds0.h"

uint32 testStatus;

void testSpi();
void testI2C();

void runTest()
{
    testStatus = 0;
    testSpi();
    testI2C();
    
    
}

inline uint32 getTestStatus()
{
    return testStatus;
}


void testSpi()
{
    
    
    uint8 buff[10];
    int rval;
    
    testStatus |= LSM9DS0test(); // this is dangerous because I assume the position of the LSM9DS0 Flags
    
    // test the third device on the SPI Bus ... aka the SPI Flash
    SPI_SpiSetActiveSlaveSelect(SPI_SPI_SLAVE_SELECT2);
    SPI_SpiUartClearRxBuffer();
    SPI_SpiUartClearTxBuffer();
    
    buff[0]=0x9f;  // RDID Command (from the datasheet)
    buff[1]=0;
    buff[2]=0;
    buff[3]=0;
    
    SPI_SpiUartPutArray(buff,4);
    CyDelay(1);
    
    if(SPI_SpiUartGetRxBufferSize() != 4) // 
        testStatus |= TESTSPIFLAG;
    
    rval = SPI_SpiUartReadRxData(); // ignore the first byte
    
    rval = SPI_SpiUartReadRxData();
    if(rval != 0x1)  // tabe 12.3 manufacturer ID and Device ID
        testStatus |= TESTFLASHFLAG;
    
    rval = SPI_SpiUartReadRxData();
    if(rval != 0x20)  // tabe 12.3 manufacturer ID and Device ID
        testStatus |= TESTFLASHFLAG;
    
    rval = SPI_SpiUartReadRxData();
    if(rval != 0x18)  // tabe 12.3 manufacturer ID and Device ID
        testStatus |= TESTFLASHFLAG;
    
}

void testI2C()
{
    
    // if the scl is shorted to ground
    if(!I2C_scl_Read())
        testStatus |= TESTI2CFLAG;
   
    // if the sda is shorted to ground
    if(!I2C_sda_Read())
        testStatus |= TESTI2CFLAG;
    
    
   if(BMP180test())
        testStatus |= TESTBMPFLAG;
    
 //   testStatus |= TESTBMPFLAG;

    I2C_I2CMasterClearStatus();

    if(HTU21test())
        testStatus |= TESTHTUFLAG;
   
    
}


/* [] END OF FILE */
