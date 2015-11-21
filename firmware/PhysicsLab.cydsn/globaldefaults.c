#include <project.h>
#include "globaldefaults.h"
#include "lsm9ds0.h"

static const DefaultVariables globalFlashDefaults = { 
    A_SCALE_4G,
    G_SCALE_245DPS,
    M_SCALE_2GS,
    0x1000,
    15.14,
    "physicslab001",
    200
};


DefaultVariables globalDefaults;

void GlobalReadDefaults()
{
   
    memcpy(&globalDefaults,&globalFlashDefaults,sizeof(DefaultVariables));
}
 
void GlobalWriteDefaults()
{
    
    uint8 dirty = 0;
    uint8 rowData[CY_FLASH_SIZEOF_ROW];
    uint32 bytesToCopy = sizeof(DefaultVariables);
    int i;
    uint32 bytesCopied = 0;
    uint32 row = (uint32)&globalFlashDefaults / CY_FLASH_SIZEOF_ROW;                    // which row is the data in
    void *startofRow = (void *)(row * CY_FLASH_SIZEOF_ROW);           // pointer to the start of the row
    uint32 offset = (uint32)&globalFlashDefaults - (uint32)startofRow;           // offset of data in row
    int numRows = ( offset + sizeof(globalFlashDefaults))/CY_FLASH_SIZEOF_ROW + 1;   // how many rows need to be written
    void *addressInBuffer = (void *)&rowData + offset;                // where to copy into the memory buffer on the first row
    
    uint8* flashSource;
    uint8* ramSource;
    flashSource = (uint8 *)&globalFlashDefaults;
    ramSource = (uint8 *)&globalDefaults;
    

    
    for(i=0;i<(int)sizeof(DefaultVariables);i++)
    {
        if (flashSource[i] != ramSource[i])
            dirty = 1;
    }
    if(!dirty)
        return;
 
    //LED2_Write(~LED2_Read());
    
    for(i=0;i<numRows;i++)
    {
        int bcopy;
        if (offset + bytesToCopy > CY_FLASH_SIZEOF_ROW)
        {
            bcopy = CY_FLASH_SIZEOF_ROW - offset;
            offset = 0; // the rest of the lines will start at the begining
        }
        else
            bcopy = bytesToCopy;
     
        memcpy(rowData,startofRow+(i*CY_FLASH_SIZEOF_ROW),CY_FLASH_SIZEOF_ROW); // copy the flash line into the ram
        memcpy(addressInBuffer, &globalDefaults + bytesCopied, bcopy); // copy as much of the global struct as possible
        bytesCopied += bcopy;
        bytesToCopy -= bcopy;
        addressInBuffer = (void *)rowData; // reset to the start of the ram buffer
        (void)CySysFlashWriteRow(row, rowData); // write the line of flash + ignore the error code
        row = row + 1; // setup for the next row
    }
}