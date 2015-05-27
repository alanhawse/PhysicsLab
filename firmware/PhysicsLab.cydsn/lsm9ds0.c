/******************************************************************************
SFE_LSM9DS0.cpp
SFE_LSM9DS0 Library Source File
Jim Lindblom @ SparkFun Electronics
Original Creation Date: February 14, 2014 (Happy Valentines Day!)
https://github.com/sparkfun/LSM9DS0_Breakout
This file implements all functions of the LSM9DS0 class. Functions here range
from higher level stuff, like reading/writing LSM9DS0 registers to low-level,
hardware reads and writes. Both SPI and I2C handler functions can be found
towards the bottom of this file.
Development environment specifics:
	IDE: Arduino 1.0.5
	Hardware Platform: Arduino Pro 3.3V/8MHz
	LSM9DS0 Breakout Version: 1.0
This code is beerware; if you see me (or any other SparkFun employee) at the
local, and you've found our code helpful, please buy us a round!
Distributed as-is; no warranty is given.
******************************************************************************/

#include "LSM9DS0.h"
#include "globaldefaults.h"

// name of the component
//#define LSM9DS0_I2C_INTERFACE I2C
#define LSM9DS0_SPI_INTERFACE SPI
#define LSM9DS0_MAG_SPI_SLAVE SPI_SPI_SLAVE_SELECT0
#define LSM9DS0GYRO_SPI_SLAVE SPI_SPI_SLAVE_SELECT1
#define LSM9DS0_ACCEL_SPI_SLAVE SPI_SPI_SLAVE_SELECT0



	// We'll store the gyro, accel, and magnetometer readings in a series of
	// public class variables. Each sensor gets three variables -- one for each
	// axis. Call readGyro(), readAccel(), and readMag() first, before using
	// these variables!
	// These values are the RAW signed 16-bit readings from the sensors.
//	int16 LSM9DS0Gyro.x, LSM9DS0Gyro.y, LSM9DS0Gyro.z; // x, y, and z axis readings of the gyroscope
//	int16 LSM9DS0Accel.x, LSM9DS0Accel.y, LSM9DS0Accel.z; // x, y, and z axis readings of the accelerometer
//    int16 LSM9DS0Mag.x, LSM9DS0Mag.y, LSM9DS0Mag.z; // x, y, and z axis readings of the magnetometer
    
    int16 LSM9DS0_biasgx,LSM9DS0_biasgy,LSM9DS0_biasgz=0; 
    
    int16 LSM9DS0_temperature;
	float LSM9DS0_abias[3];
    float LSM9DS0_gbias[3];
        
        // xmAddress and gAddress store the I2C address or SPI chip select pin
	// for each sensor.
	uint8 LSM9DS0_xmAddress, LSM9DS0_gAddress;
	// interfaceMode keeps track of whether we're using SPI or I2C to talk
//	LSM9DS0_interface_mode LSM9DS0_interfaceMode;
	
	// gScale, aScale, and mScale store the current scale range for each 
	// sensor. Should be updated whenever that value changes.
	LSM9DS0Gyro_scale LSM9DS0_gScale;
	LSM9DS0_accel_scale LSM9DS0_aScale;
	LSM9DS0_mag_scale LSM9DS0_mScale;
	
	// gRes, aRes, and mRes store the current resolution for each sensor. 
	// Units of these values would be DPS (or g's or Gs's) per ADC tick.
	// This value is calculated as (sensor scale) / (2^15).
	float LSM9DS0_gRes, LSM9DS0_aRes, LSM9DS0_mRes;
        
int LSM9DS0BrokenFlag=1;

LSM9DS0DATA LSM9DS0Accel;
LSM9DS0DATA LSM9DS0Gyro;
LSM9DS0DATA LSM9DS0Mag;

uint8 LSM9DS0Setting;
    
    
int LSM9DS0Process()
{
      LSM9DS0_readAccel();
      LSM9DS0_readGyro();
      LSM9DS0_readMag();

    return 1;
}

inline uint8 LSM9DS0GetSetting()
{
    //return LSM9DS0Setting;
    return (LSM9DS0_aScale << 4) | (LSM9DS0_mScale << 2) | (LSM9DS0_gScale) ;
}

inline LSM9DS0DATA* LSM9DS0GetAccel()
{
    return &LSM9DS0Accel;
}
inline LSM9DS0DATA* LSM9DS0GetGyro()
{
    return &LSM9DS0Gyro;
}

inline LSM9DS0DATA* LSM9DS0GetMag()
{
    return &LSM9DS0Mag;
}

int LSM9DS0test()
{
    
    
    
    uint8 buff[10];
    int rval=0;
    
    uint32 temp;
    
    LSM9DS0BrokenFlag =0;
    
    // test the first device on the SPI Bus ... aka LSM9DSO XM

    SPI_SpiSetActiveSlaveSelect(LSM9DS0_ACCEL_SPI_SLAVE);
    SPI_SpiUartClearRxBuffer();
    SPI_SpiUartClearTxBuffer();
    
    buff[0]=0x8f;  // who am I register from the datasheet
    buff[1]=0;
    
    SPI_SpiUartPutArray(buff,2);
    CyDelay(1);
    
    if(SPI_SpiUartGetRxBufferSize() != 2) // 
        rval |= LSM9DS0TESTSPIFLAG;
    
    (void)SPI_SpiUartReadRxData(); // ignore the first byte
    
    temp = SPI_SpiUartReadRxData();
    if(temp != 0x49)  // the XM response
        rval |= LSM9DS0TESTXMFLAG;
    
    // test the second device on the SPI Bus ... aka LSM9DSO G

    SPI_SpiSetActiveSlaveSelect(LSM9DS0GYRO_SPI_SLAVE);

    SPI_SpiUartClearRxBuffer();
    SPI_SpiUartClearTxBuffer();
    
    buff[0]=0x8f;  // who am I register from the datasheet
    buff[1]=0;
    
    SPI_SpiUartPutArray(buff,2);
    CyDelay(1);
    
    if(SPI_SpiUartGetRxBufferSize() != 2) // 
        rval |= LSM9DS0TESTSPIFLAG;
    
    (void)SPI_SpiUartReadRxData(); // ignore the first byte
    
    temp = SPI_SpiUartReadRxData();
    if(temp != 0xd4)  // the G response from the datasheet
        rval |= LSM9DS0TESTGFLAG;
    
    LSM9DS0BrokenFlag = rval;
    return rval;

}



inline int LSM9DS0isBroken()
{
    return LSM9DS0BrokenFlag;
}

void LSM9DS0GyroZero()
{
    int i;
    int gx,gy,gz;
    
    LSM9DS0_biasgz = 0;
    LSM9DS0_biasgy = 0;
    LSM9DS0_biasgx = 0;
    
    for(i=0;i<64;i++)
    {
        LSM9DS0_readGyro();
        gx += LSM9DS0Gyro.x;
        gy += LSM9DS0Gyro.y;
        gz += LSM9DS0Gyro.z;
    }
    LSM9DS0_biasgx = gx>>6;
    LSM9DS0_biasgy = gy>>6;
    LSM9DS0_biasgz = gz>>6;
}
        

uint16 LSM9DS0_begin(LSM9DS0Gyro_scale gScl, LSM9DS0_accel_scale aScl, LSM9DS0_mag_scale mScl, 
						LSM9DS0Gyro_odr gODR, LSM9DS0_accel_odr aODR, LSM9DS0_mag_odr mODR)
{
	// Store the given scales in class variables. These scale variables
	// are used throughout to calculate the actual g's, DPS,and Gs's.
	LSM9DS0_gScale = gScl;
	LSM9DS0_aScale = aScl;
	LSM9DS0_mScale = mScl;
	
	// Once we have the scale values, we can calculate the resolution
	// of each sensor. That's what these functions are for. One for each sensor
	LSM9DS0_calcgRes(); // Calculate DPS / ADC tick, stored in gRes variable
	LSM9DS0_calcmRes(); // Calculate Gs / ADC tick, stored in mRes variable
	LSM9DS0_calcaRes(); // Calculate g / ADC tick, stored in aRes variable
	
    
    CyDelay(50);
    LSM9DS0_gWriteByte(LSM9DS0_CTRL_REG5_G,0x80);
    CyDelay(50);
    LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG0_XM,0x80);
    CyDelay(50);
	
	// To verify communication, we can read from the WHO_AM_I register of
	// each device. Store those in a variable so we can return them.
	uint8 gTest = LSM9DS0_gReadByte(LSM9DS0_WHO_AM_I_G);		// Read the gyro WHO_AM_I
	uint8 xmTest = LSM9DS0_xmReadByte(LSM9DS0_WHO_AM_I_XM);	// Read the accel/mag WHO_AM_I
	
	// Gyro initialization stuff:
	LSM9DS0_initGyro();	// This will "turn on" the gyro. Setting up interrupts, etc.
	LSM9DS0_setGyroODR(gODR); // Set the gyro output data rate and bandwidth.
	LSM9DS0_setGyroScale(LSM9DS0_gScale); // Set the gyro range
	
	// Accelerometer initialization stuff:
	LSM9DS0_initAccel(); // "Turn on" all axes of the accel. Set up interrupts, etc.
	LSM9DS0_setAccelODR(aODR); // Set the accel data rate.
	LSM9DS0_setAccelScale(LSM9DS0_aScale); // Set the accel range.
	
	// Magnetometer initialization stuff:
	LSM9DS0_initMag(); // "Turn on" all axes of the mag. Set up interrupts, etc.
	LSM9DS0_setMagODR(mODR); // Set the magnetometer output data rate.
	LSM9DS0_setMagScale(LSM9DS0_mScale); // Set the magnetometer's range.
	
	// Once everything is initialized, return the WHO_AM_I registers we read:
	return (xmTest << 8) | gTest;
    
    LSM9DS0GyroZero();
    
}

void LSM9DS0_initGyro()
{
	/* CTRL_REG1_G sets output data rate, bandwidth, power-down and enables
	Bits[7:0]: DR1 DR0 BW1 BW0 PD Zen Xen Yen
	DR[1:0] - Output data rate selection
		00=95Hz, 01=190Hz, 10=380Hz, 11=760Hz
	BW[1:0] - Bandwidth selection (sets cutoff frequency)
		 Value depends on ODR. See datasheet table 21.
	PD - Power down enable (0=power down mode, 1=normal or sleep mode)
	Zen, Xen, Yen - Axis enable (o=disabled, 1=enabled)	*/
	LSM9DS0_gWriteByte(LSM9DS0_CTRL_REG1_G, 0x0F); // Normal mode, enable all axes
	
	/* CTRL_REG2_G sets up the HPF
	Bits[7:0]: 0 0 HPM1 HPM0 HPCF3 HPCF2 HPCF1 HPCF0
	HPM[1:0] - High pass filter mode selection
		00=normal (reset reading HP_RESET_FILTER, 01=ref signal for filtering,
		10=normal, 11=autoreset on interrupt
	HPCF[3:0] - High pass filter cutoff frequency
		Value depends on data rate. See datasheet table 26.
	*/
	LSM9DS0_gWriteByte(LSM9DS0_CTRL_REG2_G, 0x00); // Normal mode, high cutoff frequency
	
	/* CTRL_REG3_G sets up interrupt and DRDY_G pins
	Bits[7:0]: I1_IINT1 I1_BOOT H_LACTIVE PP_OD I2_DRDY I2_WTM I2_ORUN I2_EMPTY
	I1_INT1 - Interrupt enable on INT_G pin (0=disable, 1=enable)
	I1_BOOT - Boot status available on INT_G (0=disable, 1=enable)
	H_LACTIVE - Interrupt active configuration on INT_G (0:high, 1:low)
	PP_OD - Push-pull/open-drain (0=push-pull, 1=open-drain)
	I2_DRDY - Data ready on DRDY_G (0=disable, 1=enable)
	I2_WTM - FIFO watermark interrupt on DRDY_G (0=disable 1=enable)
	I2_ORUN - FIFO overrun interrupt on DRDY_G (0=disable 1=enable)
	I2_EMPTY - FIFO empty interrupt on DRDY_G (0=disable 1=enable) */
	// Int1 enabled (pp, active low), data read on DRDY_G:
	LSM9DS0_gWriteByte(LSM9DS0_CTRL_REG3_G, 0x88); 
	
	/* CTRL_REG4_G sets the scale, update mode
	Bits[7:0] - BDU BLE FS1 FS0 - ST1 ST0 SIM
	BDU - Block data update (0=continuous, 1=output not updated until read
	BLE - Big/little endian (0=data LSB @ lower address, 1=LSB @ higher add)
	FS[1:0] - Full-scale selection
		00=245dps, 01=500dps, 10=2000dps, 11=2000dps
	ST[1:0] - Self-test enable
		00=disabled, 01=st 0 (x+, y-, z-), 10=undefined, 11=st 1 (x-, y+, z+)
	SIM - SPI serial interface mode select
		0=4 wire, 1=3 wire */
	LSM9DS0_gWriteByte(LSM9DS0_CTRL_REG4_G, 0x00); // Set scale to 245 dps
	
	/* CTRL_REG5_G sets up the FIFO, HPF, and INT1
	Bits[7:0] - BOOT FIFO_EN - HPen INT1_Sel1 INT1_Sel0 Out_Sel1 Out_Sel0
	BOOT - Reboot memory content (0=normal, 1=reboot)
	FIFO_EN - FIFO enable (0=disable, 1=enable)
	HPen - HPF enable (0=disable, 1=enable)
	INT1_Sel[1:0] - Int 1 selection configuration
	Out_Sel[1:0] - Out selection configuration */
	LSM9DS0_gWriteByte(LSM9DS0_CTRL_REG5_G, 0x00);
	
	// Temporary !!! For testing !!! Remove !!! Or make useful !!!
	LSM9DS0_configGyroInt(0x2A, 0, 0, 0, 0); // Trigger interrupt when above 0 DPS...
}

void LSM9DS0_initAccel()
{
	/* CTRL_REG0_XM (0x1F) (Default value: 0x00)
	Bits (7-0): BOOT FIFO_EN WTM_EN 0 0 HP_CLICK HPIS1 HPIS2
	BOOT - Reboot memory content (0: normal, 1: reboot)
	FIFO_EN - Fifo enable (0: disable, 1: enable)
	WTM_EN - FIFO watermark enable (0: disable, 1: enable)
	HP_CLICK - HPF enabled for click (0: filter bypassed, 1: enabled)
	HPIS1 - HPF enabled for interrupt generator 1 (0: bypassed, 1: enabled)
	HPIS2 - HPF enabled for interrupt generator 2 (0: bypassed, 1 enabled)   */
	LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG0_XM, 0x00);
	
	/* CTRL_REG1_XM (0x20) (Default value: 0x07)
	Bits (7-0): AODR3 AODR2 AODR1 AODR0 BDU AZEN AYEN AXEN
	AODR[3:0] - select the acceleration data rate:
		0000=power down, 0001=3.125Hz, 0010=6.25Hz, 0011=12.5Hz, 
		0100=25Hz, 0101=50Hz, 0110=100Hz, 0111=200Hz, 1000=400Hz,
		1001=800Hz, 1010=1600Hz, (remaining combinations undefined).
	BDU - block data update for accel AND mag
		0: Continuous update
		1: Output registers aren't updated until MSB and LSB have been read.
	AZEN, AYEN, and AXEN - Acceleration x/y/z-axis enabled.
		0: Axis disabled, 1: Axis enabled									 */	
	LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG1_XM, 0x17); 
	
	//Serial.println(xmReadByte(CTRL_REG1_XM));
	/* CTRL_REG2_XM (0x21) (Default value: 0x00)
	Bits (7-0): ABW1 ABW0 AFS2 AFS1 AFS0 AST1 AST0 SIM
	ABW[1:0] - Accelerometer anti-alias filter bandwidth
		00=773Hz, 01=194Hz, 10=362Hz, 11=50Hz
	AFS[2:0] - Accel full-scale selection
		000=+/-2g, 001=+/-4g, 010=+/-6g, 011=+/-8g, 100=+/-16g
	AST[1:0] - Accel self-test enable
		00=normal (no self-test), 01=positive st, 10=negative st, 11=not allowed
	SIM - SPI mode selection
		0=4-wire, 1=3-wire													 */
	LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG2_XM, 0xC0); // Set scale to 2g
	
	/* CTRL_REG3_XM is used to set interrupt generators on INT1_XM
	Bits (7-0): P1_BOOT P1AP P1_INT1 P1_INT2 P1_INTM P1_DRDYA P1_DRDYM P1_EMPTY
	*/
	// Accelerometer data ready on INT1_XM (0x04)
//	LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG3_XM, 0x04); 
	LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG3_XM, 0x00); 
}

void LSM9DS0_initMag()
{	
	/* CTRL_REG5_XM enables temp sensor, sets mag resolution and data rate
	Bits (7-0): TEMP_EN M_RES1 M_RES0 M_ODR2 M_ODR1 M_ODR0 LIR2 LIR1
	TEMP_EN - Enable temperature sensor (0=disabled, 1=enabled)
	M_RES[1:0] - Magnetometer resolution select (0=low, 3=high)
	M_ODR[2:0] - Magnetometer data rate select
		000=3.125Hz, 001=6.25Hz, 010=12.5Hz, 011=25Hz, 100=50Hz, 101=100Hz
	LIR2 - Latch interrupt request on INT2_SRC (cleared by reading INT2_SRC)
		0=interrupt request not latched, 1=interrupt request latched
	LIR1 - Latch interrupt request on INT1_SRC (cleared by readging INT1_SRC)
		0=irq not latched, 1=irq latched 									 */
	LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG5_XM, 0x94); // Mag data rate - 100 Hz, enable temperature sensor
	
	/* CTRL_REG6_XM sets the magnetometer full-scale
	Bits (7-0): 0 MFS1 MFS0 0 0 0 0 0
	MFS[1:0] - Magnetic full-scale selection
	00:+/-2Gauss, 01:+/-4Gs, 10:+/-8Gs, 11:+/-12Gs							 */
	LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG6_XM, 0x00); // Mag scale to +/- 2GS
	
	/* CTRL_REG7_XM sets magnetic sensor mode, low power mode, and filters
	AHPM1 AHPM0 AFDS 0 0 MLP MD1 MD0
	AHPM[1:0] - HPF mode selection
		00=normal (resets reference registers), 01=reference signal for filtering, 
		10=normal, 11=autoreset on interrupt event
	AFDS - Filtered acceleration data selection
		0=internal filter bypassed, 1=data from internal filter sent to FIFO
	MLP - Magnetic data low-power mode
		0=data rate is set by M_ODR bits in CTRL_REG5
		1=data rate is set to 3.125Hz
	MD[1:0] - Magnetic sensor mode selection (default 10)
		00=continuous-conversion, 01=single-conversion, 10 and 11=power-down */
	LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG7_XM, 0x00); // Continuous conversion mode
	
	/* CTRL_REG4_XM is used to set interrupt generators on INT2_XM
	Bits (7-0): P2AP P2_INT1 P2_INT2 P2_INTM P2_DRDYA P2_DRDYM P2_Overrun P2_WTM
	*/
	LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG4_XM, 0x04); // Magnetometer data ready on INT2_XM (0x08)
	
	/* INT_CTRL_REG_M to set push-pull/open drain, and active-low/high
	Bits[7:0] - XMIEN YMIEN ZMIEN PP_OD IEA IEL 4D MIEN
	XMIEN, YMIEN, ZMIEN - Enable interrupt recognition on axis for mag data
	PP_OD - Push-pull/open-drain interrupt configuration (0=push-pull, 1=od)
	IEA - Interrupt polarity for accel and magneto
		0=active-low, 1=active-high
	IEL - Latch interrupt request for accel and magneto
		0=irq not latched, 1=irq latched
	4D - 4D enable. 4D detection is enabled when 6D bit in INT_GEN1_REG is set
	MIEN - Enable interrupt generation for magnetic data
		0=disable, 1=enable) */
	LSM9DS0_xmWriteByte(LSM9DS0_INT_CTRL_REG_M, 0x09); // Enable interrupts for mag, active-low, push-pull
}

// This is a function that uses the FIFO to accumulate sample of accelerometer and gyro data, average
// them, scales them to  gs and deg/s, respectively, and then passes the biases to the main sketch
// for subtraction from all subsequent data. There are no gyro and accelerometer bias registers to store
// the data as there are in the ADXL345, a precursor to the LSM9DS0, or the MPU-9150, so we have to
// subtract the biases ourselves. This results in a more accurate measurement in general and can
// remove errors due to imprecise or varying initial placement. Calibration of sensor data in this manner
// is good practice.
void LSM9DS0_calLSM9DS0(float * gbias, float * abias)
{  
  uint8 data[6] = {0, 0, 0, 0, 0, 0};
  int16 gyro_bias[3] = {0, 0, 0}, accel_bias[3] = {0, 0, 0};
  int samples, ii;
  
  // First get gyro bias
  uint8 c = LSM9DS0_gReadByte(LSM9DS0_CTRL_REG5_G);
  LSM9DS0_gWriteByte(LSM9DS0_CTRL_REG5_G, c | 0x40);         // Enable gyro FIFO  
  CyDelay(20);                                 // Wait for change to take effect
  LSM9DS0_gWriteByte(LSM9DS0_FIFO_CTRL_REG_G, 0x20 | 0x1F);  // Enable gyro FIFO stream mode and set watermark at 32 samples
  CyDelay(1000);  // delay 1000 milliseconds to collect FIFO samples
  
  samples = (LSM9DS0_gReadByte(LSM9DS0_FIFO_SRC_REG_G) & 0x1F); // Read number of stored samples

  for(ii = 0; ii < samples ; ii++) {            // Read the gyro data stored in the FIFO
    LSM9DS0_gReadBytes(LSM9DS0_OUT_X_L_G,  &data[0], 6);
    gyro_bias[0] += (((int16)data[1] << 8) | data[0]);
    gyro_bias[1] += (((int16)data[3] << 8) | data[2]);
    gyro_bias[2] += (((int16)data[5] << 8) | data[4]);
  }  

  gyro_bias[0] /= samples; // average the data
  gyro_bias[1] /= samples; 
  gyro_bias[2] /= samples; 
  
  gbias[0] = (float)gyro_bias[0]*LSM9DS0_gRes;  // Properly scale the data to get deg/s
  gbias[1] = (float)gyro_bias[1]*LSM9DS0_gRes;
  gbias[2] = (float)gyro_bias[2]*LSM9DS0_gRes;
  
  c = LSM9DS0_gReadByte(LSM9DS0_CTRL_REG5_G);
  LSM9DS0_gWriteByte(LSM9DS0_CTRL_REG5_G, c & ~0x40);  // Disable gyro FIFO  
  CyDelay(20);
  LSM9DS0_gWriteByte(LSM9DS0_FIFO_CTRL_REG_G, 0x00);   // Enable gyro bypass mode
  

  //  Now get the accelerometer biases
  c = LSM9DS0_xmReadByte(LSM9DS0_CTRL_REG0_XM);
  LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG0_XM, c | 0x40);      // Enable accelerometer FIFO  
  CyDelay(20);                                // Wait for change to take effect
  LSM9DS0_xmWriteByte(LSM9DS0_FIFO_CTRL_REG, 0x20 | 0x1F);  // Enable accelerometer FIFO stream mode and set watermark at 32 samples
  CyDelay(1000);  // delay 1000 milliseconds to collect FIFO samples

  samples = (LSM9DS0_xmReadByte(LSM9DS0_FIFO_SRC_REG) & 0x1F); // Read number of stored accelerometer samples

   for(ii = 0; ii < samples ; ii++) {          // Read the accelerometer data stored in the FIFO
    LSM9DS0_xmReadBytes(LSM9DS0_OUT_X_L_A, &data[0], 6);
    accel_bias[0] += (((int16)data[1] << 8) | data[0]);
    accel_bias[1] += (((int16)data[3] << 8) | data[2]);
    accel_bias[2] += (((int16)data[5] << 8) | data[4]) - (int16)(1./LSM9DS0_aRes); // Assumes sensor facing up!
  }  

  accel_bias[0] /= samples; // average the data
  accel_bias[1] /= samples; 
  accel_bias[2] /= samples; 
  
  abias[0] = (float)accel_bias[0]*LSM9DS0_aRes; // Properly scale data to get gs
  abias[1] = (float)accel_bias[1]*LSM9DS0_aRes;
  abias[2] = (float)accel_bias[2]*LSM9DS0_aRes;

  c = LSM9DS0_xmReadByte(LSM9DS0_CTRL_REG0_XM);
  LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG0_XM, c & ~0x40);    // Disable accelerometer FIFO  
  CyDelay(20);
  LSM9DS0_xmWriteByte(LSM9DS0_FIFO_CTRL_REG, 0x00);       // Enable accelerometer bypass mode
}

void LSM9DS0_readAccel()
{
	uint8 temp[6]; // We'll read six bytes from the accelerometer into temp	
	LSM9DS0_xmReadBytes(LSM9DS0_OUT_X_L_A, temp, 6); // Read 6 bytes, beginning at OUT_X_L_A
	LSM9DS0Accel.x = (temp[1] << 8) | temp[0]; // Store x-axis values into ax
	LSM9DS0Accel.y = (temp[3] << 8) | temp[2]; // Store y-axis values into ay
	LSM9DS0Accel.z = (temp[5] << 8) | temp[4]; // Store z-axis values into az
}

void LSM9DS0_readMag()
{
	uint8 temp[6]; // We'll read six bytes from the mag into temp	
	LSM9DS0_xmReadBytes(LSM9DS0_OUT_X_L_M, temp, 6); // Read 6 bytes, beginning at OUT_X_L_M
	LSM9DS0Mag.x = (temp[1] << 8) | temp[0]; // Store x-axis values into mx
	LSM9DS0Mag.y = (temp[3] << 8) | temp[2]; // Store y-axis values into my
	LSM9DS0Mag.z = (temp[5] << 8) | temp[4]; // Store z-axis values into mz
}

void LSM9DS0_readTemp()
{
	uint8 temp[2]; // We'll read two bytes from the temperature sensor into temp	
	LSM9DS0_xmReadBytes(LSM9DS0_OUTEMP_L_XM, temp, 2); // Read 2 bytes, beginning at OUTEMP_L_M
	LSM9DS0_temperature = (((int16) temp[1] << 12) | temp[0] << 4 ) >> 4; // Temperature is a 12-bit signed integer
}

void LSM9DS0_readGyro()
{
	uint8 temp[6]; // We'll read six bytes from the gyro into temp
	LSM9DS0_gReadBytes(LSM9DS0_OUT_X_L_G, temp, 6); // Read 6 bytes, beginning at OUT_X_L_G
	LSM9DS0Gyro.x = ((temp[1] << 8) | temp[0]) - LSM9DS0_biasgx; // Store x-axis values into gx
	LSM9DS0Gyro.y = ((temp[3] << 8) | temp[2]) - LSM9DS0_biasgy; // Store y-axis values into gy
	LSM9DS0Gyro.z = ((temp[5] << 8) | temp[4]) - LSM9DS0_biasgz; // Store z-axis values into gz
}

float LSM9DS0_calcGyro(int16 gyro)
{
	// Return the gyro raw reading times our pre-calculated DPS / (ADC tick):
	return LSM9DS0_gRes * gyro; 
}

float LSM9DS0_calcAccel(int16 accel)
{
	// Return the accel raw reading times our pre-calculated g's / (ADC tick):
	return LSM9DS0_aRes * accel;
}

float LSM9DS0_calcMag(int16 mag)
{
	// Return the mag raw reading times our pre-calculated Gs / (ADC tick):
	return LSM9DS0_mRes * mag;
}

void LSM9DS0_setGyroScale(LSM9DS0Gyro_scale gScl)
{
	// We need to preserve the other bytes in CTRL_REG4_G. So, first read it:
	uint8 temp = LSM9DS0_gReadByte(LSM9DS0_CTRL_REG4_G);
	// Then mask out the gyro scale bits:
	temp &= 0xFF^(0x3 << 4);
	// Then shift in our new scale bits:
	temp |= gScl << 4;
	// And write the new register value back into CTRL_REG4_G:
	LSM9DS0_gWriteByte(LSM9DS0_CTRL_REG4_G, temp);
	
	// We've updated the sensor, but we also need to update our class variables
	// First update gScale:
	LSM9DS0_gScale = gScl;
	// Then calculate a new gRes, which relies on gScale being set correctly:
	LSM9DS0_calcgRes();
}

void LSM9DS0_setAccelScale(LSM9DS0_accel_scale aScl)
{
	// We need to preserve the other bytes in CTRL_REG2_XM. So, first read it:
	uint8 temp = LSM9DS0_xmReadByte(LSM9DS0_CTRL_REG2_XM);
	// Then mask out the accel scale bits:
	temp &= 0xFF^(0x3 << 3);
	// Then shift in our new scale bits:
	temp |= aScl << 3;
	// And write the new register value back into CTRL_REG2_XM:
	LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG2_XM, temp);
	
	// We've updated the sensor, but we also need to update our class variables
	// First update aScale:
	LSM9DS0_aScale = aScl;
	// Then calculate a new aRes, which relies on aScale being set correctly:
	LSM9DS0_calcaRes();
}

void LSM9DS0_setMagScale(LSM9DS0_mag_scale mScl)
{
	// We need to preserve the other bytes in CTRL_REG6_XM. So, first read it:
	uint8 temp = LSM9DS0_xmReadByte(LSM9DS0_CTRL_REG6_XM);
	// Then mask out the mag scale bits:
	temp &= 0xFF^(0x3 << 5);
	// Then shift in our new scale bits:
	temp |= mScl << 5;
	// And write the new register value back into CTRL_REG6_XM:
	LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG6_XM, temp);
	
	// We've updated the sensor, but we also need to update our class variables
	// First update mScale:
	LSM9DS0_mScale = mScl;
	// Then calculate a new mRes, which relies on mScale being set correctly:
	LSM9DS0_calcmRes();
}

void LSM9DS0_setGyroODR(LSM9DS0Gyro_odr gRate)
{
	// We need to preserve the other bytes in CTRL_REG1_G. So, first read it:
	uint8 temp = LSM9DS0_gReadByte(LSM9DS0_CTRL_REG1_G);
	// Then mask out the gyro ODR bits:
	temp &= 0xFF^(0xF << 4);
	// Then shift in our new ODR bits:
	temp |= (gRate << 4);
	// And write the new register value back into CTRL_REG1_G:
	LSM9DS0_gWriteByte(LSM9DS0_CTRL_REG1_G, temp);
}
void LSM9DS0_setAccelODR(LSM9DS0_accel_odr aRate)
{
	// We need to preserve the other bytes in CTRL_REG1_XM. So, first read it:
	uint8 temp = LSM9DS0_xmReadByte(LSM9DS0_CTRL_REG1_XM);
	// Then mask out the accel ODR bits:
	temp &= 0xFF^(0xF << 4);
	// Then shift in our new ODR bits:
	temp |= (aRate << 4);
	// And write the new register value back into CTRL_REG1_XM:
	LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG1_XM, temp);
}
void LSM9DS0_setAccelABW(LSM9DS0_accel_abw abwRate)
{
	// We need to preserve the other bytes in CTRL_REG2_XM. So, first read it:
	uint8 temp = LSM9DS0_xmReadByte(LSM9DS0_CTRL_REG2_XM);
	// Then mask out the accel ABW bits:
	temp &= 0xFF^(0x3 << 7);
	// Then shift in our new ODR bits:
	temp |= (abwRate << 7);
	// And write the new register value back into CTRL_REG2_XM:
	LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG2_XM, temp);
}
void LSM9DS0_setMagODR(LSM9DS0_mag_odr mRate)
{
	// We need to preserve the other bytes in CTRL_REG5_XM. So, first read it:
	uint8 temp = LSM9DS0_xmReadByte(LSM9DS0_CTRL_REG5_XM);
	// Then mask out the mag ODR bits:
	temp &= 0xFF^(0x7 << 2);
	// Then shift in our new ODR bits:
	temp |= (mRate << 2);
	// And write the new register value back into CTRL_REG5_XM:
	LSM9DS0_xmWriteByte(LSM9DS0_CTRL_REG5_XM, temp);
}

void LSM9DS0_configGyroInt(uint8 int1Cfg, uint16 int1ThsX, uint16 int1ThsY, uint16 int1ThsZ, uint8 duration)
{
	LSM9DS0_gWriteByte(LSM9DS0_INT1_CFG_G, int1Cfg);
	LSM9DS0_gWriteByte(LSM9DS0_INT1HS_XH_G, (int1ThsX & 0xFF00) >> 8);
	LSM9DS0_gWriteByte(LSM9DS0_INT1HS_XL_G, (int1ThsX & 0xFF));
	LSM9DS0_gWriteByte(LSM9DS0_INT1HS_YH_G, (int1ThsY & 0xFF00) >> 8);
	LSM9DS0_gWriteByte(LSM9DS0_INT1HS_YL_G, (int1ThsY & 0xFF));
	LSM9DS0_gWriteByte(LSM9DS0_INT1HS_ZH_G, (int1ThsZ & 0xFF00) >> 8);
	LSM9DS0_gWriteByte(LSM9DS0_INT1HS_ZL_G, (int1ThsZ & 0xFF));
	if (duration)
		LSM9DS0_gWriteByte(LSM9DS0_INT1_DURATION_G, 0x80 | duration);
	else
		LSM9DS0_gWriteByte(LSM9DS0_INT1_DURATION_G, 0x00);
}

void LSM9DS0_calcgRes()
{
	// Possible gyro scales (and their register bit settings) are:
	// 245 DPS (00), 500 DPS (01), 2000 DPS (10). Here's a bit of an algorithm
	// to calculate DPS/(ADC tick) based on that 2-bit value:
	switch (LSM9DS0_gScale)
	{
	case G_SCALE_245DPS:
		LSM9DS0_gRes = 245.0 / 32768.0;
		break;
	case G_SCALE_500DPS:
		LSM9DS0_gRes = 500.0 / 32768.0;
		break;
	case G_SCALE_2000DPS:
		LSM9DS0_gRes = 2000.0 / 32768.0;
		break;
	}
}

void LSM9DS0_calcaRes()
{
	// Possible accelerometer scales (and their register bit settings) are:
	// 2 g (000), 4g (001), 6g (010) 8g (011), 16g (100). Here's a bit of an 
	// algorithm to calculate g/(ADC tick) based on that 3-bit value:
	LSM9DS0_aRes = LSM9DS0_aScale == A_SCALE_16G ? 16.0 / 32768.0 : 
		   (((float) LSM9DS0_aScale + 1.0) * 2.0) / 32768.0;
}

void LSM9DS0_calcmRes()
{
	// Possible magnetometer scales (and their register bit settings) are:
	// 2 Gs (00), 4 Gs (01), 8 Gs (10) 12 Gs (11). Here's a bit of an algorithm
	// to calculate Gs/(ADC tick) based on that 2-bit value:
	LSM9DS0_mRes = LSM9DS0_mScale == M_SCALE_2GS ? 2.0 / 32768.0 : 
	       (float) (LSM9DS0_mScale << 2) / 32768.0;
}
	
void LSM9DS0_gWriteByte(uint8 subAddress, uint8 data)
{
	// Whether we're using I2C or SPI, write a byte using the
	// gyro-specific I2C address or SPI CS pin.
    
    #ifdef LSM9DS0_SPI_INTERFACE
    LSM9DS0_SPIwriteByte(LSM9DS0GYRO_SPI_SLAVE, subAddress, data);
    #else
    I2CwriteByte(gAddress, subAddress, data);
    #endif
}

void LSM9DS0_xmWriteByte(uint8 subAddress, uint8 data)
{
	// Whether we're using I2C or SPI, write a byte using the
	// gyro-specific I2C address or SPI CS pin.
    
    #ifdef LSM9DS0_SPI_INTERFACE
    LSM9DS0_SPIwriteByte(LSM9DS0_ACCEL_SPI_SLAVE, subAddress, data);
    #else
    I2CwriteByte(gAddress, subAddress, data);
    #endif
}

uint8 LSM9DS0_gReadByte(uint8 subAddress)
{
	// Whether we're using I2C or SPI, write a byte using the
	// gyro-specific I2C address or SPI CS pin.
    
    #ifdef LSM9DS0_SPI_INTERFACE
    return LSM9DS0_SPIreadByte(LSM9DS0GYRO_SPI_SLAVE, subAddress);
    #else
    I2CwriteByte(gAddress, subAddress, data);
    #endif
}

uint8 LSM9DS0_xmReadByte(uint8 subAddress)
{
	// Whether we're using I2C or SPI, write a byte using the
	// gyro-specific I2C address or SPI CS pin.
    
    #ifdef LSM9DS0_SPI_INTERFACE
    return LSM9DS0_SPIreadByte(LSM9DS0_ACCEL_SPI_SLAVE, subAddress);
    #else
    I2CwriteByte(gAddress, subAddress, data);
    #endif
}
	
void LSM9DS0_gReadBytes(uint8 subAddress, uint8 * dest, uint8 count)
{
	// Whether we're using I2C or SPI, write a byte using the
	// gyro-specific I2C address or SPI CS pin.
    
    #ifdef LSM9DS0_SPI_INTERFACE
		LSM9DS0_SPIreadBytes(LSM9DS0GYRO_SPI_SLAVE, subAddress, dest, count);

    #else
        LSM9DS0_I2CreadBytes(LSM9DS0Gyro.yRO_I2C_SLAVE, subAddress, dest, count);

    #endif
}


void LSM9DS0_xmReadBytes(uint8 subAddress, uint8 * dest, uint8 count)
{
	// Whether we're using I2C or SPI, write a byte using the
	// gyro-specific I2C address or SPI CS pin.
    
    #ifdef LSM9DS0_SPI_INTERFACE
		LSM9DS0_SPIreadBytes(LSM9DS0_ACCEL_SPI_SLAVE, subAddress, dest, count);

    #else
    I2CwriteByte(gAddress, subAddress, data);
    #endif
}



void LSM9DS0_SPIwriteByte(uint32 slave, uint8 subAddress, uint8 data)
{
    while(SPI_SpiIsBusBusy());
    SPI_SpiSetActiveSlaveSelect(slave);
    SPI_SpiUartWriteTxData(subAddress);
    SPI_SpiUartWriteTxData(data);
    while(SPI_SpiIsBusBusy());
   	
}

uint8 LSM9DS0_SPIreadByte(uint32 slave, uint8 subAddress)
{
	
	// Use the multiple read function to read 1 byte. 
	// Value is returned to `temp`.
    
        while(SPI_SpiIsBusBusy());

    uint8 buff[2];
    
    buff[0] = subAddress | 0x80;
    buff[1] = 0;
    
    
	SPI_SpiUartClearRxBuffer();
    SPI_SpiSetActiveSlaveSelect(slave);
    
    SPI_SpiUartPutArray(buff,2);

    while(SPI_SpiUartGetRxBufferSize() != 2);
    
    uint8 rval = SPI_SpiUartReadRxData();
    rval = SPI_SpiUartReadRxData();
    return rval;
    
}

void LSM9DS0_SPIreadBytes(uint32 slave, uint8 subAddress,
							uint8 * dest, uint8 count)
{
    
    uint8 buff[]={0,0,0,0,0,0,0,0};
    buff[0] = subAddress | 0xC0;
    int i;
    uint8 rval;
    
    while(SPI_SpiIsBusBusy());

        
   	SPI_SpiSetActiveSlaveSelect(slave);
    SPI_SpiUartClearRxBuffer();
    SPI_SpiUartClearTxBuffer();
    
    SPI_SpiUartPutArray(buff,count+1);
    
    
    while(SPI_SpiUartGetRxBufferSize() != count+1);
    
    SPI_SpiUartReadRxData();
    for (i=0;i<count;i++)
    {
        rval = SPI_SpiUartReadRxData();
        dest[i] = rval;
    }
}



// Wire.h read and write protocols
void LSM9DS0_I2CwriteByte(uint32 slave, uint8 subAddress, uint8 data)
{
    /*
	Wire.beginTransmission(address);  // Initialize the Tx buffer
	Wire.write(subAddress);           // Put slave register address in Tx buffer
	Wire.write(data);                 // Put data in Tx buffer
	Wire.endTransmission();           // Send the Tx buffer
    */
}

uint8 LSM9DS0_I2CreadByte(uint8 address, uint8 subAddress)
{
    /*
	uint8 data; // `data` will store the register data	 
	Wire.beginTransmission(address);         // Initialize the Tx buffer
	Wire.write(subAddress);	                 // Put slave register address in Tx buffer
	Wire.endTransmission(false);             // Send the Tx buffer, but send a restart to keep connection alive
	Wire.requestFrom(address, (uint8) 1);  // Read one byte from slave register address 
	data = Wire.read();                      // Fill Rx buffer with result
	return data;                             // Return data read from slave register
    */
    return 0;
}

void LSM9DS0_I2CreadBytes(uint8 address, uint8 subAddress, uint8 * dest, uint8 count)
{  
    /*
	Wire.beginTransmission(address);   // Initialize the Tx buffer
	// Next send the register to be read. OR with 0x80 to indicate multi-read.
	Wire.write(subAddress | 0x80);     // Put slave register address in Tx buffer
	Wire.endTransmission(false);       // Send the Tx buffer, but send a restart to keep connection alive
	uint8 i = 0;
	Wire.requestFrom(address, count);  // Read bytes from slave register address 
	while (Wire.available()) 
	{
		dest[i++] = Wire.read(); // Put read results in the Rx buffer
	}
    */
}