#ifndef HTU21_H
#define HTU21_H

#include <project.h>
    
    void HTU21Enable();
    uint32 HTU21test();
    int HTU21process();
    inline float HTU21GetHumidity(); // relative humdity in percent
    inline float HTU21GetTemperature(); // temperature in degrees c
    void HTU21ReadSensor(void);
    inline int HTU21isBroken();
    
#endif

