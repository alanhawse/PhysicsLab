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

    var nextUpdate0 = 1.0 // wait for 10 seconds at the start
    var nextUpdate1 = 5.0
    var nextUpdate2 = 5.0

    
    var nextData0 = 0
    
    var time0 = [Double]()

    var pos0 = [Double]()
    
    var aX = [Double]()
    var aY = [Double]()
    var aZ = [Double]()
   
    var gyroX = [Double]()
    var gyroY = [Double]()
    var gyroZ = [Double]()
    
    var magX = [Double]()
    var magY = [Double]()
    var magZ = [Double]()
    
    
    
    var currentTime0 = 0.0
    
    var accelMode : UInt8 = 0
    
    var magMode : UInt8 = 0
    
    var gyroMode : UInt8 = 0
    
    private var accelRange : Double {
        get {
            switch accelMode {
            case 0:
                return 2.0
            case 1:
                return 4.0
            case 2:
                return 6.0
            case 3:
                return 8.0
            default:
                return 2.0
            }
            
        }
    }
    private var magRange : Double {
        get {
            switch magMode {
            case 0:
                return 2.0
            case 1:
                return 4.0
            case 2:
                return 8.0
            case 3:
                return 12.0
            default:
                return 2.0
                
            }

        }
    }
    private var gyroRange : Double {
        switch gyroMode {
        case 0:
            return 245.0
        case 1:
            return 500.0
        case 2:
            return 2000.0
            
        default:
            return 245.0
            
        }

    }
    
    private var pos = 0.0
    private var accel = (-1.0,-1.5,-2.0)
    private var gyro = (100.0,120.0,-20.0)
    private var mag = (0.5,-1.1,1.24)
    
    var clicksPerMeter : Double //  = 100.0/15.14 * 200.0
        {
            get {
            return 100.0/pl!.pos.wheelCircumfrence *  pl!.pos.countsPerRotation
            
        }
    }
    private var accelClicksPerG : Double { get { return 32767.0 / accelRange } }

    private var gyroClicksPerDps : Double { get { return 32767.0 / gyroRange } }

    private var magClicksPerGauss : Double { get { return 32767.0 / magRange } }
    

    
    
    func getNextData0() -> [UInt8]
    {
        
        //print("Running get next data nextData0 = \(nextData0)")
        
        //print("Accel = \(accel)")
        
        var rval  = [UInt8](count: 26, repeatedValue: 0)
        rval[0] = 0x31
        rval[1] = 0x01
        rval[2] = accelMode << 6 | gyroMode << 4 | magMode << 2 | 0x00
        rval[3] = UInt8((UInt(currentTime0*1000) & 0xFF)) // timestamp 0
        rval[4] = UInt8((UInt(currentTime0*1000) & 0xFF00)>>8) // timestamp 1
        rval[5] = UInt8((UInt(currentTime0*1000) & 0xFF0000)>>16) // timestamp 2
        
        let cartClicks : UInt16 = UInt16(pos / pl!.pos.cartPositionConvertRatio)
        
        
        rval[6] = lo8(cartClicks) // position 0
        rval[7] = hi8(cartClicks) // position 1
        
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
        
        tempInt16 = Int16(gyro.0 * gyroClicksPerDps)
        ns = NSData(bytes: &tempInt16, length: sizeof(Double))
        count = ns.length / sizeof(Int16)
        array = [UInt8](count: count, repeatedValue: 0)
        ns.getBytes(&array, length:count * sizeof(Int16))

        rval[14] = UInt8(array[0]) // gyro x
        rval[15] = UInt8(array[1]) // gyro x
        
        tempInt16 = Int16(gyro.1 * gyroClicksPerDps)
        ns = NSData(bytes: &tempInt16, length: sizeof(Double))
        count = ns.length / sizeof(Int16)
        array = [UInt8](count: count, repeatedValue: 0)
        ns.getBytes(&array, length:count * sizeof(Int16))
        
        rval[16] = UInt8(array[0]) // gyro y
        rval[17] = UInt8(array[1]) // gyro y
        
        tempInt16 = Int16(gyro.2 * gyroClicksPerDps)
        ns = NSData(bytes: &tempInt16, length: sizeof(Double))
        count = ns.length / sizeof(Int16)
        array = [UInt8](count: count, repeatedValue: 0)
        ns.getBytes(&array, length:count * sizeof(Int16))
        
        
        rval[18] = UInt8(array[0]) // gyro z
        rval[19] = UInt8(array[1]) // gyro z
       
        tempInt16 = Int16(mag.0 * magClicksPerGauss)
        ns = NSData(bytes: &tempInt16, length: sizeof(Double))
        count = ns.length / sizeof(Int16)
        array = [UInt8](count: count, repeatedValue: 0)
        ns.getBytes(&array, length:count * sizeof(Int16))
        
        
        rval[20] = UInt8(array[0]) // mag x
        rval[21] = UInt8(array[1]) // mag x
        
        tempInt16 = Int16(mag.1 * magClicksPerGauss)
        ns = NSData(bytes: &tempInt16, length: sizeof(Double))
        count = ns.length / sizeof(Int16)
        array = [UInt8](count: count, repeatedValue: 0)
        ns.getBytes(&array, length:count * sizeof(Int16))
        
        rval[22] = UInt8(array[0]) // mag y
        rval[23] = UInt8(array[1]) // mag y
       
        tempInt16 = Int16(mag.2 * magClicksPerGauss)
        ns = NSData(bytes: &tempInt16, length: sizeof(Double))
        count = ns.length / sizeof(Int16)
        array = [UInt8](count: count, repeatedValue: 0)
        ns.getBytes(&array, length:count * sizeof(Int16))
        
        rval[24] = UInt8(array[0]) // mag z
        rval[25] = UInt8(array[1]) // mag z
        
        //print("Current Time = \(currentTime0)")
        
        accel = (aX[nextData0], aY[nextData0], aZ[nextData0])
        mag = (magX[nextData0], magY[nextData0], magZ[nextData0])
        gyro = (gyroX[nextData0], gyroY[nextData0], gyroZ[nextData0])
        pos = pos0[nextData0]
        
        
        //print("Next data = \(nextData0) accel=\(accel) rows = \(time0.count)")
        
        nextData0 = nextData0 + 1
        
        if nextData0 == time0.count {
            nextData0 = 0
            nextUpdate0 = 10.0 // 10 second delay... ARH this is hardcoded
            //print("Delay Gap 10.0 systemTime = \(currentTime0) lastPacket = \(time0[time0.count-1]) pos=\(pos)")
        }
        else
        {
            nextUpdate0 = time0[nextData0] - time0[nextData0-1]
        }
        
        currentTime0 += nextUpdate0
        
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
    
    func readDataFile(fileName : String)
    {
        let fileLocation = NSBundle.mainBundle().pathForResource(fileName, ofType: "csv")!
        
        let error: NSErrorPointer = nil
        
        if let csv = CSV(contentsOfFile: fileLocation, error: error) {
            // Rows
            let rows = csv.rows
            
            //print("Number of rows = \(rows.count)")
            
            //let headers = csv.headers  //=> ["id", "name", "age"]
            
            //print(headers)
            
            //print(csv.rows[0])
            
            //print(csv.rows[0]["accelz"])
            
            
            // ARH you need to use the new error trapping code right here
            // bad things that can happen
            // non-monotonically increasing time
            // numbers outside of range
            //
            
            for var i=0 ; i<rows.count; i++ {
                
                
                
                time0.append(Double(csv.rows[i]["time"]!)!)
                
                pos0.append(Double(csv.rows[i]["position"]!)!)

                
                aX.append(Double(csv.rows[i]["accel x"]!)!)
                aY.append(Double(csv.rows[i]["accel y"]!)!)
                aZ.append(Double(csv.rows[i]["accel z"]!)!)
                
                
                // ARH This blocks will lock if you have a value > than the max range... this is a bug
                while abs(aX[aX.count-1]) > accelRange {
                    accelMode += 1
                }
               
                while abs(aY[aY.count-1]) > accelRange {
                    accelMode += 1
                }
                
                while abs(aZ[aZ.count-1]) > accelRange {
                    accelMode += 1
                }
                
                magX.append(Double(csv.rows[i]["accel x"]!)!)
                magY.append(Double(csv.rows[i]["accel y"]!)!)
                magZ.append(Double(csv.rows[i]["accel z"]!)!)
          
                while abs(magX[magX.count-1]) > magRange {
                    magMode += 1
                }
                
                while abs(magY[magY.count-1]) > magRange {
                    magMode += 1
                }
                
                while abs(magZ[magZ.count-1]) > magRange {
                    magMode += 1
                }
                
                gyroX.append(Double(csv.rows[i]["gyro x"]!)!)
                gyroY.append(Double(csv.rows[i]["gyro y"]!)!)
                gyroZ.append(Double(csv.rows[i]["gyro z"]!)!)

             
                while abs(gyroX[gyroX.count-1]) > gyroRange {
                    gyroMode += 1
                }
                
                while abs(gyroY[gyroY.count-1]) > gyroRange {
                    gyroMode += 1
                }
                
                while abs(gyroZ[gyroZ.count-1]) > gyroRange {
                    gyroMode += 1
                }
            }
            
            currentTime0 = time0[0]
            
            accel = (aX[0], aY[0], aZ[0])
            mag = (magX[0], magY[0], magZ[0])
            gyro = (gyroX[0], gyroY[0], gyroZ[0])
            nextUpdate0 = time0[1] - time0[0]
            nextData0 = 1
            
            //print("Read \(rows.count)")
            //print("accelMode = \(accelMode) magMode = \(magMode) gyroMode=\(gyroMode) ")
            //print("accelRange = \(accelRange) magRange = \(magRange) gyroRange=\(gyroRange) ")

        
        }
        
        // ARH right here you should send the message to the system about what modes things are in
    }
    
}