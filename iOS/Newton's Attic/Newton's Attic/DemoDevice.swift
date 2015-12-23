//
//  DemoDevice.swift
//  Newton's Attic
//
//  Created by Alan Hawse on 12/22/15.
//  Copyright © 2015 Elkhorn Creek Engineering. All rights reserved.
//
import Foundation

class DemoDevice {
    
    var pl : PhysicsLab?

    var nextUpdate0 = 30.0
    var nextUpdate1 = 5000.0
    var nextUpdate2 = 5000.0
    
    var currentTime = 0.0
    
    var accelMode : UInt8 = 0 {
        didSet {
            switch accelMode {
            case 0:
                accelRange = 2.0
            case 1:
                accelRange = 4.0
            case 2:
                accelRange = 6.0
            case 3:
                accelRange = 8.0
            default:
                accelRange = 2.0
                
            }
        }
    }
    
    var magMode : UInt8 = 0 {
        didSet {
            switch magMode {
            case 0:
                magRange = 2.0
            case 1:
                magRange = 4.0
            case 2:
                magRange = 8.0
            case 3:
                magRange = 12.0
            default:
                magRange = 2.0
                
            }
        }
    }
    
    var gyroMode : UInt8 = 0 {
        didSet {
            switch gyroMode {
            case 0:
                gyroRange = 245.0
            case 1:
                gyroRange = 500.0
            case 2:
                gyroRange = 2000.0
           
            default:
                gyroRange = 245.0
                
            }
        }
    }
    
    private var accelRange = 2.0
    private var magRange = 2.0
    private var gyroRange = 245.0
    
    private var pos = 0.0
    private var accel = (-1.0,-1.5,-2.0)
    private var gyro = (100.0,120.0,-20.0)
    private var mag = (0.5,-1.1,1.24)
    
    private var clicksPerMeter = 100.0/15.14 * 200.0
    private var accelClicksPerG : Double { get { return 32767.0 / accelRange } }
    
    
    func getNextData0() -> [UInt8]
    {
        var rval  = [UInt8](count: 26, repeatedValue: 0)
        rval[0] = 0x31
        rval[1] = 0x01
        rval[2] = accelMode << 6 | gyroMode << 4 | magMode << 2 | 0x00
        rval[3] = UInt8((UInt(currentTime*1000) & 0xFF)) // timestamp 0
        rval[4] = UInt8((UInt(currentTime*1000) & 0xFF00)>>8) // timestamp 1
        rval[5] = UInt8((UInt(currentTime*1000) & 0xFF0000)>>16) // timestamp 2
        rval[6] = UInt8(UInt16(pos*clicksPerMeter) & 0xFF) // position 0
        rval[7] = UInt8((UInt16(pos*clicksPerMeter) & 0xFF00) >> 8) // position 1
        
        var tempInt16 = Int16(accel.0 * accelClicksPerG)
        var ns = NSData(bytes: &tempInt16, length: sizeof(Double))
        var count = ns.length / sizeof(Int16)
        var array = [UInt8](count: count, repeatedValue: 0)
        ns.getBytes(&array, length:count * sizeof(Int16))
        
        
        rval[8] = UInt8(array[0]) // accel x 0
        rval[9] = UInt8(array[1]) // accel x 1

        
        tempInt16 = Int16(accel.1 * accelClicksPerG)
        ns = NSData(bytes: &tempInt16, length: sizeof(Double))
        count = ns.length / sizeof(Int16)
        array = [UInt8](count: count, repeatedValue: 0)
        ns.getBytes(&array, length:count * sizeof(Int16))
        
        rval[10] = UInt8(array[0]) // accel y 0
        rval[11] = UInt8(array[1]) // accel y 1
        
        tempInt16 = Int16(accel.2 * accelClicksPerG)
        ns = NSData(bytes: &tempInt16, length: sizeof(Double))
        count = ns.length / sizeof(Int16)
        array = [UInt8](count: count, repeatedValue: 0)
        ns.getBytes(&array, length:count * sizeof(Int16))
        
        rval[12] = UInt8(array[0]) // accel z 0
        rval[13] = UInt8(array[1]) // accel z 1
        
        rval[14] = 0
        rval[15] = 0
        rval[16] = 0
        rval[17] = 0
        rval[18] = 0
        rval[19] = 0
       
        rval[20] = 0
        rval[21] = 0
        rval[22] = 0
        rval[23] = 0
        rval[24] = 0
        rval[25] = 0
        
     
        currentTime = currentTime + 0.03
        pos = pos + 0.01
        if pos > 30.0 {
            pos = 0.0
        }
        
        return rval
    }
    
    func getNextData1() -> [UInt8]
    {
        return [0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5]
    }
    
    func getNextData2() -> [UInt8]
    {
        return [0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5]
    }
    
    
    private func hi8(inval : UInt16) -> UInt8
    {
        return UInt8( (inval & 0xFF00)>>8)
    }
    
    private func lo8(inval : UInt16) -> UInt8
    {
        return UInt8(inval & 0xFF)
    }
    
}