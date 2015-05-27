#include <project.h>

#ifndef __GLOBALDEFAULTS_H__
#define __GLOBALDEFAULTS_H__



typedef struct __packed DefaultVariables {
    uint8 LSM9AccelMode;
    uint8 LSM9GyroMode;
    uint8 LSM9MagMode;
    uint16 zeroPos;
    float cmsPerRotation;
    uint8 name[14];
    
} DefaultVariables;



extern DefaultVariables globalDefaults;

void GlobalReadDefaults();
void GlobalWriteDefaults();

#endif
    