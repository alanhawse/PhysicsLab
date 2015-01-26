
#include <project.h>
#include "testFunctions.h"
#include <stdlib.h>
#include "lsm9ds0.h"
#include "ble_app.h"
#include "main.h"
#include "htu21.h"
#include "bmp180.h"

void GUIprocess();
void SPIprocess();
void QDprocess();

uint32 systime=0; // 1 ms

CY_ISR(systimeISR)
{
    systime++;
    SYSPWM_ClearInterrupt(SYSPWM_INTR_MASK_TC);
    systimeisr_ClearPending();
}


void SPIprocess()
{
    if(SPI_SpiIsBusBusy())
        return;
    if(LSM9DS0Process()) // return 1 if there is new data
    {
        BLEupdateKinematicAttribute(KinematicAccel,LSM9DS0GetAccel());  
        BLEupdateKinematicAttribute(KinematicMag,LSM9DS0GetMag());         
        BLEupdateKinematicAttribute(KinematicGyro,LSM9DS0GetGyro());    
    }
}

#define QDZero 1000
void QDprocess()
{

    uint16 val= QD_ReadCounter();
    BLEupdatePositionAttribute(val);
}
void QDenable()
{
    QD_Start();
    enable5v_Write(1); // turn on the 5v supply
    QD_TriggerCommand(QD_MASK, QD_CMD_RELOAD); // this line is complete bullshit
    CyDelay(1); // and this is even more complete bullshit
    QD_WriteCounter(QDZero);

}
////////////////////////////////////////////////////////////////////// Advertising

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
    ap->setup = ADVPACKET0 | (LSM9DS0GetSetting()<<6);
    
    // fix this
    ap->tb0 =LO8(systime);
    ap->tb1 =HI8(LO16(systime));
    ap->tb2 =LO8(HI16(systime));
    
    
    // position // if it is a uint16 it causes some unhandled exception
    uint16 val= QD_ReadCounter();
    
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

    CyBle_GapUpdateAdvData(cyBle_discoveryModeInfo.advData, cyBle_discoveryModeInfo.scanRspData);
    
}


typedef struct __packed advPacket2 {
    uint8 setup;
    uint8 tb0;
    uint8 tb1;
    uint8 tb2;
    float altitude;
    float airDensity;
    float dewPoint;
    
} advPacket2;

float getAirDensity()
{
    return 0.0;
}

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

extern CYBLE_GAPP_DISC_MODE_INFO_T  cyBle_discoveryModeInfo;


void handleAdvertisingPacketChange()
{
    typedef enum advStates {
    ADVSTATEPACKET0,
    ADVSTATEPACKET1,
    ADVSTATEPACKET0NEXT,
    ADVSTATEPACKET2,
    ADVSTATEPACKET3
    } advStates;

    static advStates advState = ADVSTATEPACKET0;
    static int advTrigger = 0;
    static uint32 advTimer=0;
    
    
    CYBLE_BLESS_STATE_T BLESSstate = CyBle_GetBleSsState();
            
    if(BLESSstate == CYBLE_BLESS_STATE_ACTIVE)
    {
        advTrigger = 1;
    }
    
    else
    {
        if(advTrigger)
        {
            advTrigger = 0;
        
            switch(advState)
            {
                case ADVSTATEPACKET0:
                    setupType0Adv();
                    if(systime > advTimer + 1000)
                        advState = ADVSTATEPACKET1;
                    
                break;
                    
                case ADVSTATEPACKET1:
                    setupType1Adv();
                    advState = ADVSTATEPACKET0NEXT;
                    advTimer = systime;
                break;
            
                case ADVSTATEPACKET0NEXT:
                    setupType0Adv();
                    if(systime > advTimer + 1000)
                        advState = ADVSTATEPACKET2;
                    
                break;
                    
                case ADVSTATEPACKET2:
                    setupType2Adv();
                    advState = ADVSTATEPACKET0;
                    advTimer = systime;
                    
                break;
                case ADVSTATEPACKET3:
                    advState = ADVPACKET0;
                break;
                    
                default:
                    setupType0Adv();
                break;
                    
            }
        }
    }  
}


int main()
{


    
    CyGlobalIntEnable; 
    
    SYSPWM_Start();
    systimeisr_StartEx(systimeISR);
    
    CapSense_Start();
    CapSense_InitializeEnabledBaselines();
    CapSense_ScanEnabledWidgets();

    
    SPI_Start();
    I2C_Start();
    
    runTest();
    
    
    LSM9DS0enableReadings();
    
    if(!HTU21isBroken())
    {
        HTU21ReadSensor();
    }
    
    if(!BMP180isBroken())
    {
        BMP180init();
        BMP180ReadSensor();
    }
    
    QDenable();
    
    BLEenable();
    
    
    
    for(;;)
    {
                
        CyBle_ProcessEvents ();
        
        SPIprocess();
        GUIprocess();
        QDprocess(); 
        
        
        if(CyBle_GetState() == CYBLE_STATE_ADVERTISING)
        {
            handleAdvertisingPacketChange();
        }
        
        CyBle_EnterLPM(CYBLE_BLESS_DEEPSLEEP);
       
    }
}




void GUIprocess()
{
    static uint8 p0=1,p1=1,p2=1;
    static uint8 buttonState=0;
    int buttonFlag=0;

    if(!CapSense_IsBusy())
        {
            if(CapSense_CheckIsWidgetActive(CapSense_BUTTON0__BTN) )
            {
                if(p0)
                {                 
                    buttonState ^= 0x01;
                    buttonFlag = 0x8;
                    p0=0;
                }
            }
            else 
                p0 = 1;
            
             if(CapSense_CheckIsWidgetActive(CapSense_BUTTON1__BTN))
            {
                if(p1)
                {
                 buttonState ^= 0x2;
                buttonFlag = 0x8;
                 p1=0;
                }
            }
            else
                p1=1;
            
             if(CapSense_CheckIsWidgetActive(CapSense_BUTTON2__BTN))
            {
                if(p2)
                {
                    
                    buttonState ^= 0x04;
                    
                    buttonFlag = 0x8;
                    
                    p2=0;
                }
            }
            else
                p2=1;
            
            if(buttonFlag)
            {
                BLEupdateButtonAttribute(buttonState);
             //   LED0_Write((buttonState & 0x01));  // the board has a broken connection
                LED1_Write((buttonState & 0x02)>>1);
                LED2_Write((buttonState & 0x04)>>2);

            }

            CapSense_UpdateEnabledBaselines();
            CapSense_ScanEnabledWidgets();
        }
}


