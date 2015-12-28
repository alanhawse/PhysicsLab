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


    private var armFlag0 = false
    
    private var nextData2 = 0

    private var currentTime0 = 0.0
    var nextUpdate0 : Double? = 1.0 // wait for 1 second at the start
    private var nextData0 = 0
    private var time0 = [Double]()
    private var pos0 = [Double]()
    private var aX = [Double]()
    private var aY = [Double]()
    private var aZ = [Double]()
    private var gyroX = [Double]()
    private var gyroY = [Double]()
    private var gyroZ = [Double]()
    private var magX = [Double]()
    private var magY = [Double]()
    private var magZ = [Double]()

    var nextUpdate1 : Double? = 5.0
    private var nextData1 = 0
    private var time1 = [Double]()
    private var humidity1 = [Double]()
    private var airPressure1 = [Double]()
    private var temperature1 = [Double]()
    private var altitude1 = [Double]()
    
    private var packet1 = [Int:[UInt8]]()
    
    
    var nextUpdate2 : Double? = 5.0
    private var packet2 = [Int:[UInt8]]()
    private var time2 = [Double]()

    
    var accelMode : UInt8 = 0
    
    var magMode : UInt8 = 0
    
    var gyroMode : UInt8 = 0
    
    private struct DemoConstants {
        static let accelRangeMax = 8.0
        static let gyroRangeMax = 2000.0
        static let magRangeMax = 12.0
        
    }
    
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
    

    func arm0()
    {
        armFlag0 = true
        
    }
    
    func getNextData0() -> [UInt8]?
    {
        
        //print("Running get next data nextData0 = \(nextData0)")
        
        //print("Accel = \(accel)")
        
        if armFlag0 {
            //currentTime0 = time0[0]
            
            accel = (aX[0], aY[0], aZ[0])
            mag = (magX[0], magY[0], magZ[0])
            gyro = (gyroX[0], gyroY[0], gyroZ[0])
            nextUpdate0 = 5.0 // time0[1] - time0[0]
            nextData0 = 1
            armFlag0 = false
            return nil
        }
        
        
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
        
        if time0.count == 1 {
            nextUpdate0 = nil
        }
        else
        {
            currentTime0 += nextUpdate0!
        }
        
        return rval
    }
    
    func getNextData1() -> [UInt8]?
    {
        
        let rval = packet1[nextData1]
        
        nextData1 = nextData1 + 1
        
        
        if nextData1 == packet1.count
        {
            nextData1 = 0
            nextUpdate1 = 10.0
        }
        else
        {
            nextUpdate1 = time1[nextData1] - time1[nextData1 - 1]
        }
        
        if packet1.count == 1 {
            nextUpdate1 = nil
        }
        
        return rval
        
    }
    
    func getNextData2() -> [UInt8]?
    {
        //print("Nextdata2 = \(nextData2)")
        
        let rval = packet2[nextData2]
        
        nextData2 = nextData2 + 1
        
        
        if nextData2 == packet2.count
        {
            nextData2 = 0
            nextUpdate1 = 10.0
        }
        else
        {
            nextUpdate2 = time2[nextData2] - time2[nextData2 - 1]
        }
        
        if packet2.count == 1 {
            nextUpdate2 = nil
        }
        
        return rval
        
    }
    
    
    private func hi8(inval : UInt16) -> UInt8
    {
        return UInt8( (inval & 0xFF00)>>8)
    }
    
    private func lo8(inval : UInt16) -> UInt8
    {
        return UInt8(inval & 0xFF)
    }
    
    enum FileTypeReadErrors : ErrorType {
        case DataError(String)
    }
    
    struct File0Format {
        static let Time = "time"
        static let Position = "position"
        static let Ax = "accel x"
        static let Ay = "accel y"
        static let Az = "accel z"
        static let GyroX = "gyro x"
        static let GyroY = "gyro y"
        static let GyroZ = "gyro z"
        static let MagX = "mag x"
        static let MagY = "mag y"
        static let MagZ = "mag z"
    }
    
    struct File1Format {
        static let Time = "time"
        static let Humidity = "humidity"
        static let AirPressure = "air pressure"
        static let Temperature = "temperature"
        static let Altitude = "altitude"
        
    }
    
    struct File2Format {
        static let Time = "time"
        static let Name = "name"
        static let WheelCircumfrence = "wheel cir"
        static let ZeroPos = "zero pos"
        static let TicksPerRotation = "ticks"
    }

    
    func loadDataFiles(fileName0 : String?, fileName1 : String?, fileName2: String?) throws
    {
        if fileName0 != nil { try readDataFile0(fileName0!)}
        if fileName1 != nil { try readDataFile1(fileName1!)}
        if fileName2 != nil { try readDataFile2(fileName2!)}
    }

    
    private func readDataFile0(fileName : String) throws
    {
        let fileLocation = NSBundle.mainBundle().pathForResource(fileName, ofType: "csv")!
        
        let error: NSErrorPointer = nil
        
        if let csv = CSV(contentsOfFile: fileLocation, error: error) {
            // Rows
            let rows = csv.rows

            if csv.rows.count == 0 {throw FileTypeReadErrors.DataError("No data rows")}
            
            
            
            for var i=0 ; i<rows.count; i++ {
                
                
                guard let timeString = csv.rows[i][File0Format.Time] else {throw FileTypeReadErrors.DataError("Missing column \"\(File0Format.Time)\"")}
                guard let time = Double(timeString) else {throw FileTypeReadErrors.DataError("Time format  \"\(timeString)\" in row \(i)")}
                
                if time < 0 {
                    throw FileTypeReadErrors.DataError("Time must be >0 in row\(i)")
                }
                
                if i>0 {
                    
                    if time < time0[i-1] {
                        throw FileTypeReadErrors.DataError("Time must go forward in row \(i)")
                    }
                }
                
                time0.append(time)
            
                guard let positionString = csv.rows[i][File0Format.Position] else {throw FileTypeReadErrors.DataError("Missing column \"\(File0Format.Position)\"")}
                guard let position = Double(positionString) else {throw FileTypeReadErrors.DataError("Position format  \"\(positionString)\" in row \(i)")}
                pos0.append(position)
                
                guard let AxString = csv.rows[i][File0Format.Ax] else {throw FileTypeReadErrors.DataError("Missing column \"\(File0Format.Ax)\"")}
                guard let tempAx = Double(AxString) else {throw FileTypeReadErrors.DataError("Acceleration X format  \"\(AxString)\" in row \(i)")}
                aX.append(tempAx)
                
        
                guard let AyString = csv.rows[i][File0Format.Ay] else {throw FileTypeReadErrors.DataError("Missing column \"\(File0Format.Ay)\"")}
                guard let tempAy = Double(AyString) else {throw FileTypeReadErrors.DataError("Acceleration Y format  \"\(AyString)\" in row \(i)")}
                aY.append(tempAy)
                
                
                guard let AzString = csv.rows[i][File0Format.Az] else {throw FileTypeReadErrors.DataError("Missing column \"\(File0Format.Az)\"")}
                guard let tempAz = Double(AzString) else {throw FileTypeReadErrors.DataError("Acceleration Z format  \"\(AzString)\" in row \(i)")}
                aZ.append(tempAz)

                
                guard let gyroxString = csv.rows[i][File0Format.GyroX] else {throw FileTypeReadErrors.DataError("Missing column \"\(File0Format.GyroX)\"")}
                guard let tempgyrox = Double(gyroxString) else {throw FileTypeReadErrors.DataError("Gyro X format  \"\(gyroxString)\" in row \(i)")}
                gyroX.append(tempgyrox)
                
                guard let gyroyString = csv.rows[i][File0Format.GyroY] else {throw FileTypeReadErrors.DataError("Missing column \"\(File0Format.GyroY)\"")}
                guard let tempgyroy = Double(gyroyString) else {throw FileTypeReadErrors.DataError("Gyro Y format  \"\(gyroyString)\" in row \(i)")}
                gyroY.append(tempgyroy)
                
                guard let gyrozString = csv.rows[i][File0Format.GyroZ] else {throw FileTypeReadErrors.DataError("Missing column \"\(File0Format.GyroZ)\"")}
                guard let tempgyroz = Double(gyrozString) else {throw FileTypeReadErrors.DataError("Gyro Z format  \"\(gyrozString)\" in row \(i)")}
                gyroZ.append(tempgyroz)
                
                guard let magxString = csv.rows[i][File0Format.MagX] else {throw FileTypeReadErrors.DataError("Missing column \"\(File0Format.MagX)\"")}
                guard let tempmagx = Double(magxString) else {throw FileTypeReadErrors.DataError("mag X format  \"\(magxString)\" in row \(i)")}
                magX.append(tempmagx)
                
                guard let magyString = csv.rows[i][File0Format.MagY] else {throw FileTypeReadErrors.DataError("Missing column \"\(File0Format.MagY)\"")}
                guard let tempmagy = Double(magyString) else {throw FileTypeReadErrors.DataError("mag Y format  \"\(magyString)\" in row \(i)")}
                magY.append(tempmagy)
                
                guard let magzString = csv.rows[i][File0Format.MagZ] else {throw FileTypeReadErrors.DataError("Missing column \"\(File0Format.MagZ)\"")}
                guard let tempmagz = Double(magzString) else {throw FileTypeReadErrors.DataError("mag Z format  \"\(magzString)\" in row \(i)")}
                magZ.append(tempmagz)
                
                
                if aX[aX.count-1] > DemoConstants.accelRangeMax
                {
                    throw FileTypeReadErrors.DataError("X Acceleration \(aX[aX.count-1]) > Max \(DemoConstants.accelRangeMax) on line \(i)")
                }
                
                while abs(aX[aX.count-1]) > accelRange {
                    accelMode += 1
                }
                
                if aY[aY.count-1] > DemoConstants.accelRangeMax
                {
                    throw FileTypeReadErrors.DataError("Y Acceleration \(aY[aY.count-1]) > Max \(DemoConstants.accelRangeMax) on line \(i)")
                }
               
                while abs(aY[aY.count-1]) > accelRange {
                    accelMode += 1
                }
                
                if aZ[aZ.count-1] > DemoConstants.accelRangeMax
                {
                    throw FileTypeReadErrors.DataError("Z Acceleration \(aZ[aZ.count-1]) > Max \(DemoConstants.accelRangeMax) on line \(i)")
                }
                
                while abs(aZ[aZ.count-1]) > accelRange {
                    accelMode += 1
                }
                
                if magX[magX.count-1] > DemoConstants.magRangeMax
                {
                    throw FileTypeReadErrors.DataError("X Mag \(magX[magX.count-1]) > Max \(DemoConstants.magRangeMax) on line \(i)")
                }
                
                while abs(magX[magX.count-1]) > magRange {
                    magMode += 1
                }
               
                if magY[magY.count-1] > DemoConstants.magRangeMax
                {
                    throw FileTypeReadErrors.DataError("Y Mag \(magX[magX.count-1]) > Max \(DemoConstants.magRangeMax) on line \(i)")
                }
                
                while abs(magY[magY.count-1]) > magRange {
                    magMode += 1
                }
                
                if magZ[magZ.count-1] > DemoConstants.magRangeMax
                {
                    throw FileTypeReadErrors.DataError("Z Mag \(magZ[magZ.count-1]) > Max \(DemoConstants.magRangeMax) on line \(i)")
                }
                
                while abs(magZ[magZ.count-1]) > magRange {
                    magMode += 1
                }
                
                
             
                if gyroX[gyroX.count-1] > DemoConstants.gyroRangeMax
                {
                    throw FileTypeReadErrors.DataError("X Gyro \(gyroX[gyroX.count-1]) > Max \(DemoConstants.gyroRangeMax) on line \(i)")
                }
                
                while abs(gyroX[gyroX.count-1]) > gyroRange {
                    gyroMode += 1
                }
                
                if gyroY[gyroY.count-1] > DemoConstants.gyroRangeMax
                {
                    throw FileTypeReadErrors.DataError("Y Gyro \(gyroY[gyroY.count-1]) > Max \(DemoConstants.gyroRangeMax) on line \(i)")
                }
                
                while abs(gyroY[gyroY.count-1]) > gyroRange {
                    gyroMode += 1
                }
                
                if gyroZ[gyroZ.count-1] > DemoConstants.gyroRangeMax
                {
                    throw FileTypeReadErrors.DataError("Z Gyro \(gyroZ[gyroZ.count-1]) > Max \(DemoConstants.gyroRangeMax) on line \(i)")
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
        }
    }
    
    private func readDataFile1(fileName : String) throws
    {
        let fileLocation = NSBundle.mainBundle().pathForResource(fileName, ofType: "csv")!
        
        let error: NSErrorPointer = nil
        
        if let csv = CSV(contentsOfFile: fileLocation, error: error) {
            // Rows
            let rows = csv.rows
            
            if csv.rows.count == 0 {throw FileTypeReadErrors.DataError("No data rows")}
            
            for var i=0 ; i<rows.count; i++ {
                
                guard let timeString = csv.rows[i][File1Format.Time] else {throw FileTypeReadErrors.DataError("Missing column \"\(File1Format.Time)\"")}
                guard let time = Double(timeString) else {throw FileTypeReadErrors.DataError("Time format  \"\(timeString)\" in row \(i)")}
                
                if time < 0 {
                    throw FileTypeReadErrors.DataError("Time must be >0 in row\(i)")
                }
                
                if i>0 {
                    
                    if time < time1[i-1] {
                        throw FileTypeReadErrors.DataError("Time must go forward in row \(i)")
                    }
                }
                
                time1.append(time)
                
                guard let humidityString = csv.rows[i][File1Format.Humidity] else {throw FileTypeReadErrors.DataError("Missing column \"\(File1Format.Humidity)\"")}
                guard let humidity = Double(humidityString) else {throw FileTypeReadErrors.DataError("Humidity format  \"\(humidityString)\" in row \(i)")}
                if humidity < 0.0 || humidity > 100.0  {throw FileTypeReadErrors.DataError("0.0 < Humidity < 100.0 \"\(humidityString)\" in row \(i)")}
                
                guard let airPressureString = csv.rows[i][File1Format.AirPressure] else {throw FileTypeReadErrors.DataError("Missing column \"\(File1Format.AirPressure)\"")}
                guard let airPressure = Double(airPressureString) else {throw FileTypeReadErrors.DataError("airPressure format  \"\(airPressureString)\" in row \(i)")}
                if airPressure < 50000.0 || airPressure > 200000.0  {throw FileTypeReadErrors.DataError("5000.0 < Humidity < 200000.0 \"\(airPressureString)\" in row \(i)")}
                
                
                guard let temperatureString = csv.rows[i][File1Format.Temperature] else {throw FileTypeReadErrors.DataError("Missing column \"\(File1Format.Temperature)\"")}
                guard let temperature = Double(temperatureString) else {throw FileTypeReadErrors.DataError("temperature format  \"\(temperatureString)\" in row \(i)")}
                if temperature < -10.0 || temperature > 50.0  {throw FileTypeReadErrors.DataError("-10.0 < Temperature < 50.0 \"\(temperatureString)\" in row \(i)")}
                
                
                guard let altitudeString = csv.rows[i][File1Format.Altitude] else {throw FileTypeReadErrors.DataError("Missing column \"\(File1Format.Altitude)\"")}
                guard let altitude = Double(altitudeString) else {throw FileTypeReadErrors.DataError("altitude format  \"\(altitudeString)\" in row \(i)")}
                if altitude < 0 || altitude > 5000.0  {throw FileTypeReadErrors.DataError("0.0 < Altitude < 5000.0 \"\(altitudeString)\" in row \(i)")}

                var rval  = [UInt8](count: 26, repeatedValue: 0)
                rval[0] = 0x31
                rval[1] = 0x01
                rval[2] = accelMode << 6 | gyroMode << 4 | magMode << 2 | 0x01
                rval[3] = UInt8((UInt(time*1000) & 0xFF)) // timestamp 0
                rval[4] = UInt8((UInt(time*1000) & 0xFF00)>>8) // timestamp 1
                rval[5] = UInt8((UInt(time*1000) & 0xFF0000)>>16) // timestamp 2
                
                var ns: NSData
                var tempFloat : Float
                var array = [UInt8]()
                
                tempFloat = Float(humidity)
                ns = NSData(bytes: &tempFloat, length: sizeof(Float))
                array = [UInt8](count: sizeof(Float), repeatedValue: 0)
                ns.getBytes(&array, length: sizeof(Float))
                rval[6] = array[0]
                rval[7] = array[1]
                rval[8] = array[2]
                rval[9] = array[3]
                
              
                var tempInt : Int
                tempInt = Int(airPressure)
                ns = NSData(bytes: &tempInt, length: sizeof(Int))
                array = [UInt8](count: sizeof(Int), repeatedValue: 0)
                ns.getBytes(&array, length: sizeof(Int))
                rval[10] = array[0]
                rval[11] = array[1]
                rval[12] = array[2]
                rval[13] = array[3]
                
                tempFloat = Float(temperature)
                ns = NSData(bytes: &tempFloat, length: sizeof(Float))
                array = [UInt8](count: sizeof(Float), repeatedValue: 0)
                ns.getBytes(&array, length: sizeof(Float))
                rval[14] = array[0]
                rval[15] = array[1]
                rval[16] = array[2]
                rval[17] = array[3]
                
                tempFloat = Float(altitude)
                ns = NSData(bytes: &tempFloat, length: sizeof(Float))
                array = [UInt8](count: sizeof(Float), repeatedValue: 0)
                ns.getBytes(&array, length: sizeof(Float))
                rval[18] = array[0]
                rval[19] = array[1]
                rval[20] = array[2]
                rval[21] = array[3]
                
                packet1[i] = rval

            }
        }
        //print("Read rows 1=\(packet1.count)")
    }
    
    private func readDataFile2(fileName : String) throws
    {
        
        
        let fileLocation = NSBundle.mainBundle().pathForResource(fileName, ofType: "csv")!
        
        let error: NSErrorPointer = nil
        
        if let csv = CSV(contentsOfFile: fileLocation, error: error) {
            // Rows
            let rows = csv.rows
            
            if csv.rows.count == 0 {throw FileTypeReadErrors.DataError("No data rows")}
            
            for var i=0 ; i<rows.count; i++ {
                
                guard let timeString = csv.rows[i][File2Format.Time] else {throw FileTypeReadErrors.DataError("Missing column \"\(File2Format.Time)\"")}
                guard let time = Double(timeString) else {throw FileTypeReadErrors.DataError("Time format  \"\(timeString)\" in row \(i)")}
                
                if time < 0 {
                    throw FileTypeReadErrors.DataError("Time must be >0 in row\(i)")
                }
                
                if i>0 {
                    
                    if time < time1[i-1] {
                        throw FileTypeReadErrors.DataError("Time must go forward in row \(i)")
                    }
                }
                
                time2.append(time)
                
                guard let nameString  = csv.rows[i][File2Format.Name] else {throw FileTypeReadErrors.DataError("Missing column \"\(File2Format.Name)\"")}
                if nameString.utf8.count > 13 || nameString.utf8.count < 1 {throw FileTypeReadErrors.DataError("Name must be 0 < length < 13 \"\(nameString)\" in row \(i)")}
                
                
                guard let wheelString = csv.rows[i][File2Format.WheelCircumfrence] else {throw FileTypeReadErrors.DataError("Missing column \"\(File2Format.WheelCircumfrence)\"")}
                guard let wheelDouble = Double(wheelString) else {throw FileTypeReadErrors.DataError("Wheel Circumference format  \"\(wheelString)\" in row \(i)")}
                if wheelDouble < 5.0 || wheelDouble > 100.0  {throw FileTypeReadErrors.DataError("5.0 < Wheel Circumference < 100.0 \"\(wheelString)\" in row \(i)")}

                guard let zeroString = csv.rows[i][File2Format.ZeroPos] else {throw FileTypeReadErrors.DataError("Missing column \"\(File2Format.ZeroPos)\"")}
                guard let zeroDouble = Double(zeroString) else {throw FileTypeReadErrors.DataError("Zero Position Format  \"\(zeroString)\" in row \(i)")}
                let zeroInt = UInt16(zeroDouble * pl!.pos.cartPositionConvertRatio)

                guard let ticksString = csv.rows[i][File2Format.TicksPerRotation] else {throw FileTypeReadErrors.DataError("Missing column \"\(File2Format.TicksPerRotation)\"")}
                guard let ticksInt = UInt16(ticksString) else {throw FileTypeReadErrors.DataError("Ticks per rotation format  \"\(zeroString)\" in row \(i)")}
                

                
                var rval  = [UInt8](count: 26, repeatedValue: 0)
                rval[0] = 0x31
                rval[1] = 0x01
                rval[2] = accelMode << 6 | gyroMode << 4 | magMode << 2 | 0x02 // the 0x02 is packet type 2
                rval[3] = UInt8((UInt(time*1000) & 0xFF)) // timestamp 0
                rval[4] = UInt8((UInt(time*1000) & 0xFF00)>>8) // timestamp 1
                rval[5] = UInt8((UInt(time*1000) & 0xFF0000)>>16) // timestamp 2
                
                
                var ti = 0
                for char in nameString.utf8
                {
                    rval[3+ti] = char
                    ti = ti + 1
                }
                
                
                var ns: NSData
                var tempFloat : Float
                var array = [UInt8]()
                
                tempFloat = Float(wheelDouble)
                ns = NSData(bytes: &tempFloat, length: sizeof(Float))
                array = [UInt8](count: sizeof(Float), repeatedValue: 0)
                ns.getBytes(&array, length: sizeof(Float))
                rval[17] = array[0]
                rval[18] = array[1]
                rval[19] = array[2]
                rval[20] = array[3]

                rval[21] = lo8(zeroInt)
                rval[22] = hi8(zeroInt)
                rval[23] = lo8(ticksInt)
                rval[24] = hi8(ticksInt)
                packet2[i] = rval
                
            }
        }
        //print("Read rows 2=\(packet2.count)")
    }
    
}