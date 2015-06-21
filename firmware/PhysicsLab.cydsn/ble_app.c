#include <project.h>
#include "ble_app.h"
#include "testFunctions.h"
#include "main.h"
#include "lsm9ds0.h"
#include "bmp180.h"
#include "htu21.h"
#include "globaldefaults.h"

// private variables
CYBLE_CONN_HANDLE_T  connectionHandle;
int bleConnected=0;

int BLEButtonNotify = 0;
int BLEButtonIndicate = 0;

int BLEMagNotify = 0;
int BLEMagIndicate = 0;

int BLEAccelerationNotify = 0;
int BLEAccelerationIndicate = 0;

int BLEGyroNotify=0;
int BLEGyroIndicate=0;

int BLEPositionNotify=0;
int BLEPositionIndicate=0;

int BLEEventFlag=0;

// PrivateFunctions

void BleCallBack(uint32 event, void* eventParam);


void BLEenable()
{
    CyBle_Start( BleCallBack );
    while(CyBle_GetState() == CYBLE_STATE_INITIALIZING)
    {
        CyBle_ProcessEvents();
    }

}

void BLEupdateEnvironment()
{
    
    if(!bleConnected)
        return;
    
	CYBLE_GATTS_HANDLE_VALUE_NTF_T 	tempHandle;
    long tLong;
    float tFloat;
    
    // temperature
    
    typedef struct tempValues
    {
        uint8 flag; 
        float temperature;
    } tempValues;
    
    tempValues tv;
    
    tempHandle.attrHandle = CYBLE_ENVIRONMENT_TEMPERATURE_MEASUREMENT_CHAR_HANDLE;
    tempHandle.value.len = 5;    
    tempHandle.value.val = (uint8 *)&tv;
    CyBle_GattsReadAttributeValue(&tempHandle,&connectionHandle,CYBLE_GATT_DB_LOCALLY_INITIATED);
    
    tv.temperature = BMP180GetTemperature();
  	CyBle_GattsWriteAttributeValue(&tempHandle,0,&connectionHandle,0);  
    
    // humidity
    tFloat = HTU21GetHumidity();
	tempHandle.attrHandle = CYBLE_ENVIRONMENT_RELATIVE_HUMIDITY_CHAR_HANDLE;
	tempHandle.value.val = (uint8 *)&tFloat;
    tempHandle.value.len = 4;
  	CyBle_GattsWriteAttributeValue(&tempHandle,0,&connectionHandle,0);  
    
    // Pressure
    tLong = BMP180GetPressure();
	tempHandle.attrHandle = CYBLE_ENVIRONMENT_AIRPRESSURE_CHAR_HANDLE;
	tempHandle.value.val = (uint8 *)&tLong;
    tempHandle.value.len = 4;
  	CyBle_GattsWriteAttributeValue(&tempHandle,0,&connectionHandle,0);  
    
    // Altitude
    tFloat = BMP180GetAltitude();
	tempHandle.attrHandle = CYBLE_ENVIRONMENT_ALTITUDE_CHAR_HANDLE;
	tempHandle.value.val = (uint8 *)&tFloat;
    tempHandle.value.len = 4;
  	CyBle_GattsWriteAttributeValue(&tempHandle,0,&connectionHandle,0);  
    
}

void BLEupdateTestAttribute(uint32 testStatus)
{
    
    if(!bleConnected)
        return;
    
	CYBLE_GATTS_HANDLE_VALUE_NTF_T 	testHandle;
    
    
	testHandle.attrHandle = CYBLE_TESTSERVICE_TESTCHARACTERISTIC_CHAR_HANDLE;
	testHandle.value.val = (uint8 *)&testStatus;
    testHandle.value.len = 4;
	
  	CyBle_GattsWriteAttributeValue(&testHandle,0,&connectionHandle,0);  
}

void BLEupdateSettings()
{
    
    if(!bleConnected)
        return;
    
    uint8 setting;
    
	CYBLE_GATTS_HANDLE_VALUE_NTF_T 	settingsHandle;
    
    
    // Update the accelerometer setting
    setting = (LSM9DS0GetSetting() & 0b00110000)>>4;
	settingsHandle.attrHandle = CYBLE_SETTINGS_LSM9DS0ACCELMODE_CHAR_HANDLE;
	settingsHandle.value.val = (uint8 *)&setting;
    settingsHandle.value.len = 1;
  	CyBle_GattsWriteAttributeValue(&settingsHandle,0,&connectionHandle,0);  
    
    // Update the mag setting
    setting = (LSM9DS0GetSetting() & 0b00001100)>>2;
	settingsHandle.attrHandle = CYBLE_SETTINGS_LSM9DS0MAGMODE_CHAR_HANDLE;
	settingsHandle.value.val = (uint8 *)&setting;
    settingsHandle.value.len = 1;
  	CyBle_GattsWriteAttributeValue(&settingsHandle,0,&connectionHandle,0); 
    
    // Update the gyro setting
    setting = (LSM9DS0GetSetting() & 0b00000011);
	settingsHandle.attrHandle = CYBLE_SETTINGS_LSM9DS0GYROMODE_CHAR_HANDLE;
	settingsHandle.value.val = (uint8 *)&setting;
    settingsHandle.value.len = 1;
  	CyBle_GattsWriteAttributeValue(&settingsHandle,0,&connectionHandle,0); 
    
    // update the cmsPerRotation zero
    
   
    settingsHandle.attrHandle = CYBLE_SETTINGS_WHEELCIRCUMFRENCE_CHAR_HANDLE; 
   	settingsHandle.value.val = (uint8 *)&globalDefaults.cmsPerRotation;

    settingsHandle.value.len = 4;
  	CyBle_GattsWriteAttributeValue(&settingsHandle,0,&connectionHandle,0); 

    
    // update the  quadrature zero
    
    settingsHandle.attrHandle = CYBLE_SETTINGS_ZEROPOSITION_CHAR_HANDLE;
  	settingsHandle.value.val = (uint8 *)&globalDefaults.zeroPos;

    settingsHandle.value.len = 2;
  	CyBle_GattsWriteAttributeValue(&settingsHandle,0,&connectionHandle,0); 
    
}

void BLEupdateButtonAttribute(uint8 button)
{
  
    if(!bleConnected)
        return;
    
    
	CYBLE_GATTS_HANDLE_VALUE_NTF_T 	buttonHandle;
    
    uint8 buttons[3];
	
    buttons[0] = 3;
    buttons[1] = 0;
    buttons[2] = button;
	buttonHandle.attrHandle = CYBLE_BUTTONS_BUTTONS_CHAR_HANDLE;				
	buttonHandle.value.val = buttons;
    buttonHandle.value.len = 3;
	
  	CyBle_GattsWriteAttributeValue(&buttonHandle,0,&connectionHandle,0);  
    
    if(BLEButtonNotify)
        CyBle_GattsNotification(connectionHandle,&buttonHandle);
        
    if(BLEButtonIndicate)
        CyBle_GattsIndication(connectionHandle,&buttonHandle);
            

}

void BLEupdatePositionAttribute(uint16 val)
{
  
    if(!bleConnected)
        return;
    
    static uint32 lastUpdate=0;

    
    
	CYBLE_GATTS_HANDLE_VALUE_NTF_T 	PositionHandle;
    
	PositionHandle.attrHandle = CYBLE_KINEMATIC_POSITION_CHAR_HANDLE;				
	PositionHandle.value.val = (uint8 *)&val;
    PositionHandle.value.len = 2;
	
  	CyBle_GattsWriteAttributeValue(&PositionHandle,0,&connectionHandle,0);  

    if(systime < lastUpdate + BLEUPDATEINTERVAL)
        return; 
    
    lastUpdate = systime;
    
    if(BLEPositionNotify)
        CyBle_GattsNotification(connectionHandle,&PositionHandle);
        
    if(BLEPositionIndicate)
        CyBle_GattsIndication(connectionHandle,&PositionHandle);
}

void BleCallBack(uint32 event, void* eventParam)
{
    CYBLE_GATTS_WRITE_REQ_PARAM_T *wrReqParam;

    
    switch(event)
    {
        
        case CYBLE_EVT_GAP_DEVICE_DISCONNECTED:
            GlobalWriteDefaults();
        case CYBLE_EVT_STACK_ON:
            bleConnected = 0;
            CyBle_GappStartAdvertisement(CYBLE_ADVERTISING_FAST);

        break;
         
         
        case CYBLE_EVT_GATT_CONNECT_IND:
			
            connectionHandle = *(CYBLE_CONN_HANDLE_T  *)eventParam;
            bleConnected=1;
            BLEupdateTestAttribute(getTestStatus());
            BLEupdateButtonAttribute(LED2_Read() << 2 | LED1_Read() << 1 | LED0_Read());
            BLEupdateEnvironment();
            BLEupdateSettings();
            
            
		break;
            
        case CYBLE_DEBUG_EVT_BLESS_INT: // signals the start of a ble event
            if (CyBle_GetBleSsState() == CYBLE_BLESS_STATE_EVENT_CLOSE)
                BLEEventFlag = 1;
        break;
                
        

         case CYBLE_EVT_GATTS_WRITE_REQ:
            wrReqParam = (CYBLE_GATTS_WRITE_REQ_PARAM_T *) eventParam;
			
            if(wrReqParam->handleValPair.attrHandle == CYBLE_BUTTONS_BUTTONS_BUTTONCCCD_DESC_HANDLE)
            {
                
                if(!(wrReqParam->handleValPair.value.val[0] > 1 || wrReqParam->handleValPair.value.val[1] > 1)) {
	                CyBle_GattsWriteAttributeValue(&wrReqParam->handleValPair, 0, &connectionHandle, CYBLE_GATT_DB_LOCALLY_INITIATED);
                    BLEButtonNotify = wrReqParam->handleValPair.value.val[0];
                    BLEButtonIndicate = wrReqParam->handleValPair.value.val[1];
                }
            }
            
            if(wrReqParam->handleValPair.attrHandle == CYBLE_KINEMATIC_ACCELERATION_ACCELCCCD_DESC_HANDLE) // CCCD for acceleration
            {
                
                if(!(wrReqParam->handleValPair.value.val[0] > 1 || wrReqParam->handleValPair.value.val[1] > 1)) {
	                CyBle_GattsWriteAttributeValue(&wrReqParam->handleValPair, 0, &connectionHandle, CYBLE_GATT_DB_LOCALLY_INITIATED);
                    BLEAccelerationNotify = wrReqParam->handleValPair.value.val[0];
                    BLEAccelerationIndicate = wrReqParam->handleValPair.value.val[1];
                }
            }
            
            if(wrReqParam->handleValPair.attrHandle == CYBLE_KINEMATIC_MAG_MAGCCCD_DESC_HANDLE) // CCCD for Mag
            {
                
                if(!(wrReqParam->handleValPair.value.val[0] > 1 || wrReqParam->handleValPair.value.val[1] > 1)) {
	                CyBle_GattsWriteAttributeValue(&wrReqParam->handleValPair, 0, &connectionHandle, CYBLE_GATT_DB_LOCALLY_INITIATED);
                    BLEMagNotify = wrReqParam->handleValPair.value.val[0];
                    BLEMagIndicate = wrReqParam->handleValPair.value.val[1];
                }
            }
            
            if(wrReqParam->handleValPair.attrHandle == CYBLE_KINEMATIC_GYRO_GYROCCCD_DESC_HANDLE) // CCCD for Gyro
            {
                
                if(!(wrReqParam->handleValPair.value.val[0] > 1 || wrReqParam->handleValPair.value.val[1] > 1)) {
	                CyBle_GattsWriteAttributeValue(&wrReqParam->handleValPair, 0, &connectionHandle, CYBLE_GATT_DB_LOCALLY_INITIATED);
                    BLEGyroNotify = wrReqParam->handleValPair.value.val[0];
                    BLEGyroIndicate = wrReqParam->handleValPair.value.val[1];
                }
            }
            
            // cart Position
            if(wrReqParam->handleValPair.attrHandle == CYBLE_KINEMATIC_POSITION_CHAR_HANDLE) 
            {
                    QD_WriteCounter (wrReqParam->handleValPair.value.val[0] |  (wrReqParam->handleValPair.value.val[1]<<8)); 
	                CyBle_GattsWriteAttributeValue(&wrReqParam->handleValPair, 0, &connectionHandle, CYBLE_GATT_DB_LOCALLY_INITIATED);
            }
            
            if(wrReqParam->handleValPair.attrHandle == CYBLE_KINEMATIC_POSITION_POSITIONCCCD_DESC_HANDLE) // CCCD for Position
            {
                
                if(!(wrReqParam->handleValPair.value.val[0] > 1 || wrReqParam->handleValPair.value.val[1] > 1)) {
	                CyBle_GattsWriteAttributeValue(&wrReqParam->handleValPair, 0, &connectionHandle, CYBLE_GATT_DB_LOCALLY_INITIATED);
                    BLEPositionNotify = wrReqParam->handleValPair.value.val[0];
                    BLEPositionIndicate = wrReqParam->handleValPair.value.val[1];
                }
            }
            
            
          
            if(wrReqParam->handleValPair.attrHandle == CYBLE_SETTINGS_LSM9DS0ACCELMODE_CHAR_HANDLE) // acceleromter
            {
                // if it is a legal LSM9DS0 mode 4 magic number of the enum of legal modes
                if((wrReqParam->handleValPair.value.val[0] < 4)) {
	                CyBle_GattsWriteAttributeValue(&wrReqParam->handleValPair, 0, &connectionHandle, CYBLE_GATT_DB_LOCALLY_INITIATED);
                    // change the LSM9DS0 Setting
                    globalDefaults.LSM9AccelMode = wrReqParam->handleValPair.value.val[0];

                    LSM9DS0_setAccelScale(wrReqParam->handleValPair.value.val[0]);
                }
            }
            
            if(wrReqParam->handleValPair.attrHandle == CYBLE_SETTINGS_LSM9DS0MAGMODE_CHAR_HANDLE)
            {
                // if it is a legal LSM9DS0 mode 4 magic number of the enum of legal modes
                if((wrReqParam->handleValPair.value.val[0] < 4)) {
	                CyBle_GattsWriteAttributeValue(&wrReqParam->handleValPair, 0, &connectionHandle, CYBLE_GATT_DB_LOCALLY_INITIATED);
                    // change the LSM9DS0 Setting
                    globalDefaults.LSM9MagMode = wrReqParam->handleValPair.value.val[0];

                    LSM9DS0_setMagScale(wrReqParam->handleValPair.value.val[0]);
                }
            }
            
            if(wrReqParam->handleValPair.attrHandle == CYBLE_SETTINGS_LSM9DS0GYROMODE_CHAR_HANDLE)
            {
                // if it is a legal LSM9DS0 mode 4 magic number of the enum of legal modes
                if((wrReqParam->handleValPair.value.val[0] < 4)) {
	                CyBle_GattsWriteAttributeValue(&wrReqParam->handleValPair, 0, &connectionHandle, CYBLE_GATT_DB_LOCALLY_INITIATED);
                    // change the LSM9DS0 Setting
                    globalDefaults.LSM9GyroMode = wrReqParam->handleValPair.value.val[0];
                    LSM9DS0_setGyroScale(wrReqParam->handleValPair.value.val[0]);
                }
            }
           
            
            // Name
            if(wrReqParam->handleValPair.attrHandle == CYBLE_SETTINGS_NAME_CHAR_HANDLE) 
            {
                if (wrReqParam->handleValPair.value.len <= sizeof(globalDefaults.name) )
                {
                    memcpy(globalDefaults.name, wrReqParam->handleValPair.value.val,wrReqParam->handleValPair.value.len );
                    CyBle_GattsWriteAttributeValue(&wrReqParam->handleValPair, 0, &connectionHandle, CYBLE_GATT_DB_LOCALLY_INITIATED);
                }
            }
            
            // Wheel Circumfrence
            if(wrReqParam->handleValPair.attrHandle == CYBLE_SETTINGS_WHEELCIRCUMFRENCE_CHAR_HANDLE) 
            {
                float temp;
                memcpy(&temp, wrReqParam->handleValPair.value.val, 4); // arh hardcode
                globalDefaults.cmsPerRotation = temp;
                CyBle_GattsWriteAttributeValue(&wrReqParam->handleValPair, 0, &connectionHandle, CYBLE_GATT_DB_LOCALLY_INITIATED);
            }
            
            // Zero
            if(wrReqParam->handleValPair.attrHandle == CYBLE_SETTINGS_ZEROPOSITION_CHAR_HANDLE) 
            {
                    globalDefaults.zeroPos = (wrReqParam->handleValPair.value.val[0] |  (wrReqParam->handleValPair.value.val[1]<<8)); 
	                CyBle_GattsWriteAttributeValue(&wrReqParam->handleValPair, 0, &connectionHandle, CYBLE_GATT_DB_LOCALLY_INITIATED);
            }
            
    
            
            CyBle_GattsWriteRsp(connectionHandle);
           			
			break;    
        default:
        break;
  }
} 


void BLEupdateKinematicAttribute(KinematicHandle kh,LSM9DS0DATA *val)
{

    
    static uint32 maglastupdate,gyrolastupdate,accellastupdate=0;
    uint32 *lastUpdate;
    
 
    if(!bleConnected)
        return;
    
	CYBLE_GATTS_HANDLE_VALUE_NTF_T Handle;
              
    int notify=0;
    int indicate=0;
    
    switch(kh)
    {
        case KinematicAccel:
            notify = BLEAccelerationNotify;
            indicate = BLEAccelerationIndicate;
            lastUpdate = &accellastupdate;
            
       
        break;
        
        case KinematicGyro:
            notify = BLEGyroNotify;
            indicate = BLEGyroIndicate;
            lastUpdate = & gyrolastupdate;
        break;
        
        case KinematicMag:
            notify=BLEMagNotify;
            indicate=BLEMagIndicate;
            lastUpdate = &maglastupdate;
        break;
        
    }
    
    Handle.attrHandle = kh;				
	Handle.value.val = (uint8 *)val;
    Handle.value.len = 6;   
    
    CyBle_GattsWriteAttributeValue(&Handle,0,&connectionHandle,0);  

    if (  systime < *lastUpdate + BLEUPDATEINTERVAL  )
        return;
    
    *lastUpdate = systime;
    
    if(notify)
        CyBle_GattsNotification(connectionHandle,&Handle);
        
    if(indicate)
        CyBle_GattsIndication(connectionHandle,&Handle);
}