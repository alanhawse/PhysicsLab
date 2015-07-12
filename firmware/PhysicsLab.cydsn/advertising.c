////////////////////////////////////////////////////////////////////// Advertising
#include <project.h>
#include "main.h"
#include "lsm9ds0.h"
#include "htu21.h"
#include "bmp180.h"
#include "globaldefaults.h"


#define ADVINDEX (7)
#define ADVPACKET0 0b00
#define ADVPACKET1 0b01
#define ADVPACKET2 0b10
#define ADVPACKET3 0b11


typedef struct __packed advPacket0 {
    uint8 setup;
    uint8 tb0;
    uint8 tb1;
    uint8 tb2;
    uint16 position;
    
    LSM9DS0DATA accel;
    LSM9DS0DATA gyro;
    LSM9DS0DATA mag;
    
} advPacket0;


void setupType0Adv()
{
    advPacket0 *ap;
    
    ap = (advPacket0 *)&cyBle_discoveryModeInfo.advData->advData[ADVINDEX];
    
    // packet type + LSM9Setting
  
    
    ap->setup = ADVPACKET0 | (LSM9DS0GetSetting()<<2);
    
    // fix this
    ap->tb0 =LO8(systime);
    ap->tb1 =HI8(LO16(systime));
    ap->tb2 =LO8(HI16(systime));
    
    
    // position // if it is a uint16 it causes some unhandled exception
    uint16 val= QD_ReadCounter();
    
    /* ARH Bomb
    if (val != 0x1000)
    {
        while(1);
    }
    */
    
    ap->position = val;
   
    
    // acceleration x,y,z
    memcpy(&ap->accel , LSM9DS0GetAccel(), 6); // sizeof(LSM9DS0DATA));
    
    // gyro x,y,z
    memcpy(&ap->gyro , LSM9DS0GetGyro(),6 ); // sizeof(LSM9DS0DATA));
    
    // mag x,y,z
    memcpy(&ap->mag , LSM9DS0GetMag(),6); //sizeof(LSM9DS0DATA));
             
    CyBle_GapUpdateAdvData(cyBle_discoveryModeInfo.advData, cyBle_discoveryModeInfo.scanRspData);
}


typedef struct __packed advPacket1 {
    uint8 setup;
    uint8 tb0;
    uint8 tb1;
    uint8 tb2;
    float relativeHumdity;
    long airPressure;
    float temperature;
    float altitude;
    
} advPacket1;

typedef union Types {
    float f;
    uint8 bytes[4];
    long longVal;
} Types;

void setupType1Adv()
{
    advPacket1 *ap;

    Types tempData;
    
    ap = (advPacket1 *)&cyBle_discoveryModeInfo.advData->advData[ADVINDEX];
    
    // packet type + LSM9Setting
    ap->setup = ADVPACKET1;
    
    tempData.longVal = systime;
    
    ap->tb0 = tempData.bytes[0];
    ap->tb1 = tempData.bytes[1];
    ap->tb2 = tempData.bytes[2];

    tempData.f = BMP180GetTemperature(); 
    memcpy(&ap->temperature,&tempData,4);
    
    
    tempData.f = HTU21GetHumidity();
    memcpy(&ap->relativeHumdity,&tempData,4);

    tempData.longVal = BMP180GetPressure();
    memcpy(&ap->airPressure,&tempData,4);
    
    
    tempData.f = BMP180GetAltitude(); 
    memcpy(&ap->altitude,&tempData,4);

    CyBle_GapUpdateAdvData(cyBle_discoveryModeInfo.advData, cyBle_discoveryModeInfo.scanRspData);
    
}

/*
typedef struct __packed advPacket2 {
    uint8 setup;
    uint8 tb0;
    uint8 tb1;
    uint8 tb2;
    float altitude;
    float airDensity;
    float dewPoint;
    
} advPacket2;
*/

/*
void setupType2Adv()
{
    // packet type

    advPacket2 *ap;
    Types tempData;

    ap = (advPacket2 *)&cyBle_discoveryModeInfo.advData->advData[ADVINDEX];
    
    // packet type + LSM9Setting
    ap->setup = ADVPACKET2;
    
    tempData.longVal = systime;
    
    ap->tb0 = tempData.bytes[0];
    ap->tb1 = tempData.bytes[1];
    ap->tb2 = tempData.bytes[2];
    
    tempData.f = BMP180GetAltitude(); 
    memcpy(&ap->altitude,&tempData,4);

    tempData.f = getAirDensity(); 
    memcpy(&ap->airDensity,&tempData,4);

    ap->airDensity = 0; // todo
    
    tempData.f = HTU21GetDewPoint(); 
    memcpy(&ap->dewPoint,&tempData,4);
    
    CyBle_GapUpdateAdvData(cyBle_discoveryModeInfo.advData, cyBle_discoveryModeInfo.scanRspData);
    

}
*/


typedef struct __packed advPacket2 {
    uint8 setup;
    uint8 name[14];
    float wheelCircumfrence;
    uint16 zeroPos;
    
} advPacket3;


void setupType2Adv()
{
    // packet type

    advPacket3 *ap;
    //Types tempData;

    ap = (advPacket3 *)&cyBle_discoveryModeInfo.advData->advData[ADVINDEX];
    
    // packet type + LSM9Setting
    ap->setup = ADVPACKET2;
    
    ap->wheelCircumfrence = globalDefaults.cmsPerRotation;
    ap->zeroPos = globalDefaults.zeroPos;
    memcpy(&ap->name,globalDefaults.name,sizeof(globalDefaults.name)); 
    
    CyBle_GapUpdateAdvData(cyBle_discoveryModeInfo.advData, cyBle_discoveryModeInfo.scanRspData);
    

}

extern CYBLE_GAPP_DISC_MODE_INFO_T  cyBle_discoveryModeInfo;


void handleAdvertisingPacketChange()
{
    typedef enum advStates {
      ADVSTATEPACKET0,
       ADVSTATEINSERTPACKET,
   
    } advStates;

    typedef enum insertPacketStates {
        ADVSTATEEPACKET1,
        ADVSTATEEPACKET2
    } insertPacketStates;

    static advStates advState = ADVSTATEPACKET0;
    static insertPacketStates insertState = ADVPACKET1;
    static uint32 advTimer=0;
    
        
            switch(advState)
            {
                case ADVSTATEPACKET0:
                    setupType0Adv();
                    if(systime > advTimer + 500)
                        advState = ADVSTATEINSERTPACKET;
                    
                break;
                    
                case ADVSTATEINSERTPACKET:
                    LED0_Write(~LED0_Read());
                    if(insertState == ADVSTATEEPACKET1)
                    {
                        setupType1Adv();
                        insertState = ADVSTATEEPACKET2;
                    }
                    else
                    {
                        setupType2Adv();
                        insertState = ADVSTATEEPACKET1;
                    }
                    
                    advState = ADVSTATEPACKET0;
                    advTimer = systime;
                break;
            
                
                default:
                    setupType0Adv();
                break;
                    
    }  
}
