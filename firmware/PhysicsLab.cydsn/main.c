
#include <project.h>
#include "testFunctions.h"
#include <stdlib.h>
#include "lsm9ds0.h"
#include "ble_app.h"
#include "main.h"
#include "htu21.h"
#include "bmp180.h"
#include "advertising.h"
#include "cydisabledsheets.h"
#include "globaldefaults.h"


void GUIprocess();
void SPIprocess();
void QDprocess();


uint32 systime=1; // 1 ms

/*
CY_ISR(systimeISR)
{
    systime++;
    SYSPWM_ClearInterrupt(SYSPWM_INTR_MASK_TC);
    systimeisr_ClearPending();
    UA11_Write(~UA11_Read());
    
}
*/

CY_ISR(stime)
{
    systime++;
    UA11_Write(~UA11_Read());

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

void QDprocess()
{

    uint16 val= QD_ReadCounter();
    BLEupdatePositionAttribute(val);
}
void QDenable()
{
    QD_Start();
    
    QD_TriggerCommand(QD_MASK, QD_CMD_RELOAD); // this line is complete bullshit
    CyDelay(1); // and this is even more complete bullshit
    QD_WriteCounter(globalDefaults.zeroPos);

}



void mainLoop();

int main()
{


    CyGlobalIntEnable; 
    
    GlobalReadDefaults();

    CySysTickStart();
    CySysTickSetClockSource(CY_SYS_SYST_CSR_CLK_SRC_LFCLK);
    CySysTickSetReload(32);
    CySysTickSetCallback(0,stime); // The LF clock has a WC 32768 ...divided by 32 = 1/ms
    
    SPI_Start();
    
#ifndef debug__DISABLED
        UART_Start();
        mainLoop();
        
#endif
   
    
    CapSense_Start();
    CapSense_InitializeEnabledBaselines();
    CapSense_ScanEnabledWidgets();
    
    I2C_Start();
    
    runTest();
    
    (void)LSM9DS0_begin(globalDefaults.LSM9GyroMode,globalDefaults.LSM9AccelMode,globalDefaults.LSM9MagMode,G_ODR_95_BW_125,A_ODR_1600,M_ODR_100);

    
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
        
        CyBle_ProcessEvents();
        CyBle_EnterLPM(CYBLE_BLESS_DEEPSLEEP);

  
        if( BLEEventFlag && CyBle_GetState() == CYBLE_STATE_ADVERTISING)
        {
            BLEEventFlag = 0;
            UA10_Write(~UA10_Read());
            handleAdvertisingPacketChange();  
        }
        
        SPIprocess();
        GUIprocess();
        QDprocess();
        
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
                    QD_WriteCounter(globalDefaults.zeroPos);
                    
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
                LED0_Write((buttonState & 0x01));  // the board has a broken connection
                LED1_Write((buttonState & 0x02)>>1);
                LED2_Write((buttonState & 0x04)>>2);

            }

            CapSense_UpdateEnabledBaselines();
            CapSense_ScanEnabledWidgets();
        }
}


