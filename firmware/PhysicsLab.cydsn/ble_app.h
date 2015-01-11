

#if !defined(BLE_APP_H)
#define BLE_APP_H

#include <project.h>
#include "lsm9ds0.h"
    
typedef enum KinematicHandle {
    KinematicAccel=CYBLE_KINEMATIC_ACCELERATION_CHAR_HANDLE,
    KinematicGyro=CYBLE_KINEMATIC_GYRO_CHAR_HANDLE,
    KinematicMag=CYBLE_KINEMATIC_MAG_CHAR_HANDLE
    
} KinematicHandle;

void BLEupdateKinematicAttribute(KinematicHandle kh,LSM9DS0DATA *);
void BLEupdateButtonAttribute(uint8 button);
void BLEupdatePositionAttribute(uint16 );
void BLEenable();
void BLEnotify();


    
#endif
