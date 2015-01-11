
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

extern CYBLE_GAPP_DISC_MODE_INFO_T  cyBle_discoveryModeInfo;

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
        
        uint16 cnt = 0x0b0c;
        cnt = cnt + 1;
        
        CyBle_ProcessEvents ();
        
        SPIprocess();
        GUIprocess();
        QDprocess(); 
        
        
        
        if((CyBle_GetBleSsState() != CYBLE_BLESS_STATE_EVENT_CLOSE) && (CyBle_GetState() == CYBLE_STATE_ADVERTISING ))
        {
            cyBle_discoveryModeInfo.advData->advData[19]=(uint8)cnt>>8;
            cyBle_discoveryModeInfo.advData->advData[20]=(uint8)cnt;
            
           // cyBle_discoveryModeInfo.advData->advData[19]=(uint8)0xab;
            //cyBle_discoveryModeInfo.advData->advData[20]=(uint8)0xcd;
            
            CyBle_GapUpdateAdvData(cyBle_discoveryModeInfo.advData, cyBle_discoveryModeInfo.scanRspData);
        }


    }
}



void GUIprocess()
{
    static uint8 p0=1,p1=1,p2=1;
    
    int buttonFlag=0;

    if(!CapSense_IsBusy())
        {
            if(CapSense_CheckIsWidgetActive(CapSense_BUTTON0__BTN) )
            {
                if(p0)
                {                    
                    LED0_Write(!LED0_Read());
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
                 LED1_Write(!LED1_Read());
                enable5v_Write(LED1_Read());
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
                    
                    buttonFlag = 0x8;
                    LED2_Write(!LED2_Read());
                    
                    p2=0;
                }
            }
            else
                p2=1;
            
            if(buttonFlag)
                BLEupdateButtonAttribute(LED2_Read() << 2 | LED1_Read() << 1 | LED0_Read());

            CapSense_UpdateEnabledBaselines();
            CapSense_ScanEnabledWidgets();
        }
}


