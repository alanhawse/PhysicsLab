//
//  PhysicsLab.swift
//  BLETest1
//
//  Created by Alan Hawse on 1/18/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol PhysicsLabDisplayDelegate {
    func physicsLabDisplay(sender: PhysicsLab)
}

class PhysicsLab : NSObject, CBPeripheralDelegate {
    
    init?(advertisementData: [UInt8])
    {
        super.init()

        if advertisementData.count == 26 && advertisementData[0] == 0x31 && advertisementData[1] == 1
        {
            addPacket(advertisementData)
        }
        else
        {
            //println("not a physics lab")
            return nil
        }
        
    }
    
    var delegate : PhysicsLabDisplayDelegate? {
        didSet {
           // println("Delegate = \(delegate)")
        }
    }
    
    var history = CartHistory()
    
    
    var name:String? {
        didSet {
            if connectionComplete {
                
                let temp  = (name! as NSString).dataUsingEncoding(NSUTF8StringEncoding)
                let data = NSMutableData(data: temp!)
                let x : [UInt8] = [0]
                
                data.appendBytes(x, length: 1)
                
                peripheral?.writeValue(data, forCharacteristic: charName, type: CBCharacteristicWriteType.WithResponse)
                
            }
        }
    }
    func isNameLegal(name : String) -> Bool
    {
        let length = name.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        if length>0 && length<14
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    
    var velocity : Float = 0.0
    var maxMinVelocity : (min:Float, max:Float) = (0.0,0.0)
    
    
    var velocityRange : (min:Double, max:Double) = (-8.0,8.0)
    
    func resetMax() {
        maxCartPosition = cartPosition
        maxAcceleration = acceleration
        minAcceleration = acceleration
        
        maxGyro = gyro
        minGyro = gyro
        
        maxMag = mag
        minMag = mag
        
        maxMinVelocity = (velocity,velocity)
    }
    
    
    var cartZero : Float = 0.0 {
        
        didSet {
            if connectionComplete {
                
                var val:UInt16 = UInt16( cartZero / ConvertRatio)
                let ns = NSData(bytes: &val, length: sizeof(Float))
                
                peripheral?.writeValue(ns, forCharacteristic: charCartZero, type: CBCharacteristicWriteType.WithResponse)
            }
        }
    }
    
        
    
    var cartPositionHex : Int = 0
    var currentTime : Float = 0
    var cartPosition : Float = 0.0 {
        didSet {
            
            
            if connectionComplete {
                
                var val:UInt16 = UInt16( cartPosition / ConvertRatio)
                let ns = NSData(bytes: &val, length: sizeof(Float))
                peripheral?.writeValue(ns, forCharacteristic: charCartPosition, type: CBCharacteristicWriteType.WithResponse)
            }
            else
            {
                
                if cartPosition > maxCartPosition {
                    maxCartPosition = cartPosition
                }
                
                
                if lastCartPosition != nil {
                    // calculate current velocity
                    if (currentTime > lastCartPosition!.time + 0.2) // only calculate the velocity every 200ms
                    {
                        velocity = (cartPosition - lastCartPosition!.position) / (currentTime - lastCartPosition!.time)
                        if velocity > Float(velocityRange.max) {
                    
                            println("Velocity error \(currentTime) \(lastCartPosition!.time)")
                            println("Cart = \(cartPosition) \(lastCartPosition!.position)")
                            maxMinVelocity.max = velocity
                        }
                        if velocity < Float(velocityRange.min) {
                            maxMinVelocity.min = velocity
                        }
                        lastCartPosition = (currentTime,cartPosition)
                        
                    }
                }
                else
                {
                    lastCartPosition = (currentTime,cartPosition)
                }
            }
            
            
        }
    }
    
    var lastCartPosition : (time:Float,position:Float)?
    
    var acceleration : (x:Float, y:Float, z:Float) = (0.0,0.0,0.0) {
        didSet {
            if acceleration.x >= maxAcceleration.x { maxAcceleration.x = acceleration.x }
            if acceleration.y >= maxAcceleration.y { maxAcceleration.y = acceleration.y }
            if acceleration.z >= maxAcceleration.z { maxAcceleration.z = acceleration.z }
            
            if acceleration.x <= minAcceleration.x { minAcceleration.x = acceleration.x }
            if acceleration.y <= minAcceleration.y { minAcceleration.y = acceleration.y }
            if acceleration.z <= minAcceleration.z { minAcceleration.z = acceleration.z }
            
            
            
        }
    }
    
    var gyro : (x:Float, y:Float, z:Float) = (0.0,0.0,0.0) {
        didSet {
            if gyro.x >= maxGyro.x { maxGyro.x = gyro.x }
            if gyro.y >= maxGyro.y { maxGyro.y = gyro.y }
            if gyro.z >= maxGyro.z { maxGyro.z = gyro.z }
            
            if gyro.x <= minGyro.x { minGyro.x = gyro.x }
            if gyro.y <= minGyro.y { minGyro.y = gyro.y }
            if gyro.z <= minGyro.z { minGyro.z = gyro.z }
        }
    }
    
    var mag : ( x:Float, y:Float, z:Float) = (0.0,0.0,0.0)  {
        didSet {
            if mag.x > maxMag.x { maxMag.x = mag.x }
            if mag.y > maxMag.y { maxMag.y = mag.y }
            if mag.z > maxMag.z { maxMag.z = mag.z }
            
            if mag.x > minMag.x { minMag.x = mag.x }
            if mag.y > minMag.y { minMag.y = mag.y }
            if mag.z > minMag.z { minMag.z = mag.z }
            
        }
    }
    
    var maxCartPosition : Float = 0.0
    
    var maxAcceleration : (x: Float, y:Float, z: Float) = (0.0,0.0,0.0)
    var minAcceleration : (x: Float, y:Float, z: Float) = (0.0,0.0,0.0)
    
    
    var maxGyro : (x:Float, y:Float, z:Float) = (0.0,0.0,0.0)
    var maxMag : ( x:Float, y:Float, z:Float) = (0.0,0.0,0.0)
    var minGyro : (x:Float, y:Float, z:Float) = (0.0,0.0,0.0)
    var minMag : ( x:Float, y:Float, z:Float) = (0.0,0.0,0.0)
    
    

    var heading : Float {
        get {
            //var heading : Float = 0.0
            if (mag.y > 0.0)
            {
                return 90.0 - (atan(mag.x / mag.y) * (180.0 / 3.1415926));
            }
            else if (mag.y < 0.0)
            {
                return 	-1.0 *  (atan(mag.x / mag.y) * (180 / 3.1415926));
            }
            else // hy = 0
            {
                if (mag.x < 0.0) { return 180.0; }
                else { return 0.0; }
            }
        }
    }

    var relativeHumdity : Float = 0.0
    var pressure :  Int = 0
    var temperature :  Float = 0.0
    var altitude :  Float = 0.0
    
    // http://www.gribble.org/cycling/air_density.html
    var airDensity :  Float {
        get {
         
            let eso = 6.1078
            let c0 = 0.99999683
            let c1 = -0.9082695e-2
            let c2 = 0.78736169e-4
            let c3 = -0.61117958e-6
            let c4 = 0.43884187e-8
            let c5 = -0.29883885e-10
            let c6 = 0.21874425e-12
            let c7 = -0.17892321e-14
            let c8 = 0.11112018e-16
            let c9 = -0.30994571e-19
            let T = Double(dewPoint)
            
            let part8 = (c6 + T * (c7 + T * (c8 + T * c9)))
            let p = c0 + T * (c1 + T * (c2 + T * (c3 + T * (c4 + T * (c5 + T * part8)))))
            
            let es = eso / (p*p*p*p*p*p*p*p) //8.0
            let pv = es * Double(relativeHumdity)

            // http://www.holsoft.nl/physics/ocmain.htm
            let rho = 1.2929 * 273.15 / (Double(temperature) + 273.0531) * (Double(pressure) - 0.3783 * pv) / 1.013e5
                        
            return Float(rho)
        }
    }
    
    var dewPoint :  Float {
        get {
            
            let part1 = log(relativeHumdity/100)
            let part2 = (17.625*temperature)
            let part3 = (243.04+temperature)
            let part4 = 17.625-log(relativeHumdity/100)
            let part5 = (17.625*temperature)
            let part6 = (243.04+temperature)
            let rval = 243.04 * (part1 + (part2/part3))  / (part4-(part5/part6))
            return Float(rval)
        }
    }
    

    var LSM9DSOAccelMode = 0 {
        didSet {
            if connectionComplete {
                
                var val = LSM9DSOAccelMode
                let ns = NSData(bytes: &val, length: sizeof(UInt8))
                
                peripheral?.writeValue(ns, forCharacteristic: charAccel, type: CBCharacteristicWriteType.WithResponse)
            }
        }
    }

    var LSM9DSOAccelRange : Float {
        get {
            switch LSM9DSOAccelMode {
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
    
    private var LSM9DSOAccelCountpG : Float    // 2g in 15 bits - 2,4,6,8,16 (are legal ranges)
    {
        get {
            switch(LSM9DSOAccelMode)
            {
            case 0:
                return 32768.0/2.0
                
            case 1:
                return 32768.0/4.0
                
                
            case 2:
                return 32768.0/6.0
                
            case 3:
                return 32768.0/8.0
                
            default:
               return 32768.0/2.0
                
            }
            
        }
        
    }
    
    
    // meters per click
    // 10 inches * 2.54 CM/inch
    
    var cmsPerRotation: Float = 10.0 * 2.54 {
        didSet {
            if connectionComplete {
                
                var val = cmsPerRotation
                let ns = NSData(bytes: &val, length: sizeof(Float))
                
                peripheral?.writeValue(ns, forCharacteristic: charWheelCircumfrence, type: CBCharacteristicWriteType.WithResponse)
            }
        }
    }
    
    
    // meters/click = 1 rotation/200 clicks * cmsPerRotation *  1m/100cm
    private var ConvertRatio: Float {
        get {
            return cmsPerRotation * (1.0/100.0) * (1.0/200)
        }
    }
    
    
    
    //let MAXSIZE = 50 * 60 * 1 // 50hz 60 seconds/minute 1 minutes
    let MAXSIZE = 10
    

    var LSM9DSOGyroMode = 0 {
        didSet {
            if connectionComplete {
                
                var val = LSM9DSOGyroMode
                let ns = NSData(bytes: &val, length: sizeof(UInt8))
                
                peripheral?.writeValue(ns, forCharacteristic: charGyro, type: CBCharacteristicWriteType.WithResponse)
              //  println("Writing value to \(peripheral)")
            }
        }
    }
    
    
    var LSM9DSOGyroRange : Float {
        get {
            switch LSM9DSOGyroMode {
            case 0:
                return 245
            case 1:
                return 500
            case 2:
                return 2000
            
            default:
                return 245
            }
            
        }
    }
    
    
    
    private var LSM9DSOGyroCountpDPS : Float { // - 245, 500, 2000 are legal ranges
        
    
        get {
        
        switch(LSM9DSOGyroMode)
        {
        case 0:
            return 32768.0/245.0
            
        case 1:
            return 32768.0/500.0
            
            
        case 2:
            return 32768.0/2000.0
            
        default:
            return 32768.0/245.0
            
            }
        }
    }
    var LSM9DS0MagMode = 0 {
        didSet {
            if connectionComplete {
                
                var val = LSM9DS0MagMode
                let ns = NSData(bytes: &val, length: sizeof(UInt8))
                peripheral?.writeValue(ns, forCharacteristic: charMag, type: CBCharacteristicWriteType.WithResponse)
            }
        }
    }
    
    var LSM9DSOMagRange : Float {
        get {
            switch LSM9DS0MagMode {
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

    private var LSM9DSOMagCountpG : Float {   // 2, 4, 8, 12 are the legal ranges
        get {
        switch(LSM9DS0MagMode)
        {
        case 0:
            return 32768.0/2.0
            
        case 1:
            return 32768.0/4.0
            
            
        case 2:
            return 32768.0/8.0
        
        case 3:
            return 32768.0/12.0
            
        default:
            return 32768.0/2.0
            
            
        }
        }
    }
    
    private func addCartPosition(curtime: Float, newPosition:Float)
    {
        cartPosition = newPosition
       
    }

    private func addCartPosition(curtime: Float, newPosition:Int)
    {
        let converted : Float = Float(newPosition) * ConvertRatio
        addCartPosition(curtime,newPosition:converted)
        
        
    }
    
    
    
    private func addAccel(time : Float, x:Float,y:Float,z:Float)
    {
        acceleration = (x:x,y:y,z:z)
        
    }
    
    private func addAccel(curtime : Float, x:Int, y:Int, z:Int)
    {
        var xval : Float = Float(x) / LSM9DSOAccelCountpG
        var yval : Float = Float(y) / LSM9DSOAccelCountpG
        var zval : Float = Float(z) / LSM9DSOAccelCountpG
        
        addAccel(curtime, x:xval, y: yval, z: zval)
        
    }
    
    
    private func addGyro(time : Float, x:Float,y:Float,z:Float)
    {
        
        gyro = (x:x,y:y,z:z)
        
    }
    
    private func addGyro(curtime : Float, x:Int, y:Int, z:Int)
    {
        
        var xval : Float = Float(x) / LSM9DSOGyroCountpDPS
        var yval : Float = Float(y) / LSM9DSOGyroCountpDPS
        var zval : Float = Float(z) / LSM9DSOGyroCountpDPS
        
        addGyro(curtime, x:xval, y: yval, z: zval)
        
    }
    
    private func addMag(time : Float, x:Float,y:Float,z:Float)
    {
        mag = (x:x,y:y,z:z)
        
    }
    
    private func addMag(curtime : Float, x:Int, y:Int, z:Int)
    {
        var xval : Float = Float(x) / LSM9DSOMagCountpG
        var yval : Float = Float(y) / LSM9DSOMagCountpG
        var zval : Float = Float(z) / LSM9DSOMagCountpG
        
        addMag(curtime, x:xval, y: yval, z: zval)
        
    }
    
    func addPacket(ar: [UInt8])
    {
        
        let packetType = ar[2] & 0b00000011
        switch packetType {
        case 0:
            packetType0(ar)
        case 1:
            packetType1(ar)
        case 2:
            packetType2(ar)
        case 3:
            packetType3(ar)
            
        default:
            break
            
        }
        
        delegate?.physicsLabDisplay(self)
        
    }
 
    var packet0Count = 0
    private func packetType0 (ar : [UInt8])
    {
        
        //println("Packet type 0")

        let packetTime = Float(Int(ar[3]) + Int(ar[4])<<8 + Int(ar[5])<<16) / 1000
        if packetTime == currentTime
        {
            return
        }
        packet0Count = packet0Count + 1
        //println("Packet 0 \(packet0Count)")
        currentTime = packetTime
        
        LSM9DSOAccelMode = Int((ar[2]  & 0b11000000) >> 6)
        LSM9DS0MagMode = Int((ar[2]  & 0b00110000) >> 4)
        LSM9DSOGyroMode = Int((ar[2]  & 0b00001100) >> 2)
        
        
        let b0 = UInt32(ar[3])
        let b1 = UInt32(ar[4])
        let b2 = UInt32(ar[5])
        
        let tempint = b0 + b1<<8 + b2<<16
        
        
        var tempInt:Int16 = 0
        var bytes : Array<UInt8> = [0,0,0,0]
        
        var uTempInt:UInt16 = 0
        
        // Position
        
        bytes[0] = ar[6]
        bytes[1] = ar[7]
        memcpy(&uTempInt, bytes,2)
        var tempPos : Int = Int(uTempInt)
        addCartPosition(currentTime, newPosition: tempPos)
        cartPositionHex = tempPos
        
        // acceleration
        
        bytes[0] = ar[8]
        bytes[1] = ar[9]
        memcpy(&tempInt,bytes,2)
        var DataX : Int = Int(tempInt)
        
        bytes[0] = ar[10]
        bytes[1] = ar[11]
        memcpy(&tempInt,bytes,2)
        var DataY : Int = Int(tempInt)
        
        bytes[0] = ar[12]
        bytes[1] = ar[13]
        memcpy(&tempInt,bytes,2)
        var DataZ : Int = Int(tempInt)
        addAccel(currentTime, x: DataX, y:DataY, z: DataZ)
        
        /// Gyro
        bytes[0] = ar[14]
        bytes[1] = ar[15]
        memcpy(&tempInt,bytes,2)
        DataX  = Int(tempInt)
        
        bytes[0] = ar[16]
        bytes[1] = ar[17]
        memcpy(&tempInt,bytes,2)
        DataY  = Int(tempInt)
        
        bytes[0] = ar[18]
        bytes[1] = ar[19]
        memcpy(&tempInt,bytes,2)
        DataZ  = Int(tempInt)
        
        addGyro(currentTime, x: DataX, y:DataY, z: DataZ)
        
        
        /// Mag
        bytes[0] = ar[20]
        bytes[1] = ar[21]
        memcpy(&tempInt,bytes,2)
        DataX  = Int(tempInt)
        
        bytes[0] = ar[22]
        bytes[1] = ar[23]
        memcpy(&tempInt,bytes,2)
        DataY  = Int(tempInt)
        
        bytes[0] = ar[24]
        bytes[1] = ar[25]
        memcpy(&tempInt,bytes,2)
        DataZ  = Int(tempInt)
        
        addMag(currentTime, x: DataX, y:DataY, z: DataZ)
        
        history.addPoint(currentTime, position: cartPosition, acceleration: acceleration, gyro: gyro, mag: mag, velocity: velocity)
        
    }
    
    
    private var packet1Count = 0
    private var packet2Count = 0
    private func packetType1 (ar : [UInt8])
    {
  
        packet1Count = packet1Count + 1
        //println("Packet Type 1 = \(packet1Count)")
        var Time : Int = Int(ar[3]) + Int(ar[4])<<8 + Int(ar[5])<<16
        var tempInt:Int16 = 0
        var tempFloat:Float = 0.0
        var bytes : Array<UInt8> = [0,0,0,0]
        
        bytes[0] = ar[6]
        bytes[1] = ar[7]
        bytes[2] = ar[8]
        bytes[3] = ar[9]
        
        memcpy(&relativeHumdity,bytes,4)

        bytes[0] = ar[10]
        bytes[1] = ar[11]
        bytes[2] = ar[12]
        bytes[3] = ar[13]
        
        memcpy(&pressure,bytes,4)
        
        bytes[0] = ar[14]
        bytes[1] = ar[15]
        bytes[2] = ar[16]
        bytes[3] = ar[17]
        
        memcpy(&temperature,bytes,4)
        
     //   packet1Count = packet1Count + 1
     //   println("packet1Count = \(packet1Count)")
        
    }

    
    private func packetType2 (ar : [UInt8])
    {
        
      //  println("Packet Type 2")
        var Time : Int = Int(ar[3]) + Int(ar[4])<<8 + Int(ar[5])<<16
        var tempInt:Int16 = 0
        var tempFloat:Float = 0.0
        var bytes : Array<UInt8> = [0,0,0,0]
        
        bytes[0] = ar[6]
        bytes[1] = ar[7]
        bytes[2] = ar[8]
        bytes[3] = ar[9]
        
        memcpy(&altitude,bytes,4)
        
        bytes[0] = ar[10]
        bytes[1] = ar[11]
        bytes[2] = ar[12]
        bytes[3] = ar[13]
        
  //      memcpy(&airDensity,bytes,4)
        
        bytes[0] = ar[14]
        bytes[1] = ar[15]
        bytes[2] = ar[16]
        bytes[3] = ar[17]
        
 //       memcpy(&dewPoint,bytes,4)
        
    //    packet2Count = packet2Count + 1
     //   println("packet2Count = \(packet2Count)")
        
        
    }
    
    var packet3Count = 0
    
    private func packetType3( ar: [UInt8])
    {
        
      //  println("Packet Type 3")
        var tempUInt : UInt16 = 0
        var tempInt:Int16 = 0
        var tempFloat:Float = 0.0
        var bytes : Array<UInt8> = [0,0,0,0]
        bytes[0] = ar[17]
        bytes[1] = ar[18]
        bytes[2] = ar[19]
        bytes[3] = ar[20]
        memcpy(&cmsPerRotation,bytes,4)
        
        bytes[0] = ar[21]
        bytes[1] = ar[22]
        memcpy(&tempUInt,bytes,2)
        
        cartZero  = Float(tempUInt) * ConvertRatio
        
        var tempAr = [UInt8]()
        
        let offset = 3
        for i in 0...14 {
            if ar[i+offset] == 0 {
                break
            }
            tempAr.append(ar[i+offset])
        }
        
        if let  nm = NSString(bytes: tempAr, length: tempAr.count, encoding: NSUTF8StringEncoding)
        {
            name = nm as String
        }
        
        
     //   packet3Count = packet3Count + 1
     //   println("packet 3 \(tempFloat) packet3Count = \(packet3Count)")
        
    }
    
    ////////////////////// connected device ////////////////////////
    
    var connectionComplete = false
    var peripheral : CBPeripheral? // ARH this is really bad
    
    
    let SettingsService = CBUUID(string:"00000000-0000-1000-8000-00805F9B3300")
    let CharacteristicAccelMode = CBUUID(string:"00000000-0000-1000-8000-00805F9B3310")
    let CharacteristicGyroMode = CBUUID(string:"00000000-0000-1000-8000-00805F9B3320")
    let CharacteristicMagMode = CBUUID(string:"00000000-0000-1000-8000-00805F9B3330")
    let CharacteristicName = CBUUID(string:"00000000-0000-1000-8000-00805F9B3340")
    let CharacteristicWheelCircumfrence = CBUUID(string:"00000000-0000-1000-8000-00805F9B3350")
    let CharacteristicCartZero = CBUUID(string:"00000000-0000-1000-8000-00805F9B3360")
    let CharacteristicCartPosition = CBUUID(string:"00000000-0000-1000-8000-00805F9B3370")
    
    let KinematicService = CBUUID(string: "00000000-0000-1000-8000-00805F9B3100")
    let CharacteristicAcceleration = CBUUID(string: "00000000-0000-1000-8000-00805F9B3110")
    let CharacteristicMag = CBUUID(string: "00000000-0000-1000-8000-00805F9B3120")
    let CharacteristicGyro = CBUUID(string: "00000000-0000-1000-8000-00805F9B3130")
    let CharacteristicPosition = CBUUID(string: "00000000-0000-1000-8000-00805F9B3140")

    
    var charAccel = CBCharacteristic()
    var charMag = CBCharacteristic()
    var charGyro = CBCharacteristic()
    var charName = CBCharacteristic()
    var charWheelCircumfrence = CBCharacteristic()
    var charCartZero = CBCharacteristic()
    var charCartPosition = CBCharacteristic()

    
    
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        
       self.peripheral = peripheral // ARH this is really bad way to do this
        characteristicCount = 0
        
        for service in peripheral.services {
            if let thisService = service as? CBService
            {
                if thisService.UUID == SettingsService {
                    
                    peripheral.discoverCharacteristics(nil, forService: thisService) // ARH probably should replace nil with the specific ones
                }
                if thisService.UUID == KinematicService {
                    peripheral.discoverCharacteristics(nil, forService: thisService) // ARH probably should replace nil with the specific ones
                }
                
            }
        }
        
    }
    
    var characteristicCount = 0
    
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        delegate?.physicsLabDisplay(self)
        
        
        
        for i in service.characteristics {
            let thisCharacteristic = i as! CBCharacteristic
            switch thisCharacteristic.UUID
            {
            case CharacteristicAccelMode:
                charAccel = thisCharacteristic
                characteristicCount += 1
            case CharacteristicGyroMode:
                charGyro = thisCharacteristic
                characteristicCount += 1
            case CharacteristicMagMode:
                charMag = thisCharacteristic
                characteristicCount += 1
            case CharacteristicName:
                charName = thisCharacteristic
                characteristicCount += 1
            case CharacteristicWheelCircumfrence:
                charWheelCircumfrence = thisCharacteristic
                characteristicCount += 1
            case CharacteristicCartZero:
                charCartZero = thisCharacteristic
                characteristicCount += 1
            case CharacteristicPosition:
                charCartPosition = thisCharacteristic
                characteristicCount += 1
                
    
            default: break
            }
        }
        
        if characteristicCount == 7 {
            connectionComplete = true
            peripheral.setNotifyValue(true, forCharacteristic: charCartPosition)
            delegate?.physicsLabDisplay(self)
        }
        
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if characteristic == charCartPosition {
         
            
            var ar = [UInt8]()
            
            if characteristic.value != nil {
                
                ar  = [UInt8](count:characteristic.value.length, repeatedValue: 0)
                // copy bytes into array
                characteristic.value.getBytes(&ar, length:characteristic.value.length)
                
                let cp :UInt16 = UInt16(ar[0]) | UInt16(ar[1])<<8 
                cartPosition = Float(cp) * ConvertRatio
                delegate?.physicsLabDisplay(self)
                
                
            }
           
            
            
        }
    }
    

    
}