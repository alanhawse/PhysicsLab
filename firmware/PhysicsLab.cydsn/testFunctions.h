

#if !defined(TESTFUNCTIONS_H)
#define TESTFUNCTIONS_H
#include <cytypes.h>
    

extern uint32 testStatus;
inline uint32 getTestStatus();

#define TESTSPIFLAG (1<<0)
#define TESTXMFLAG (1<<1)
#define TESTGFLAG (1<<2)
#define TESTFLASHFLAG (1<<3)
#define TESTI2CFLAG (1<<4)
#define TESTHTUFLAG (1<<5)
#define TESTBMPFLAG (1<<6)
void runTest(void);
    
#endif



/* [] END OF FILE */
