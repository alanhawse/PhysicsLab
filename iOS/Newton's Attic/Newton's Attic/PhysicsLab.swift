//
//  PhysicsLab.swift
//
//  Created by Alan Hawse on 1/18/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import Foundation

class PhysicsLab {
 
    
    var bleAdvInterface : PLAdvPacketInterface?
    var bleConnectionInterface : PLBleInterface?
    var history = CartHistory()
    var currentTime : Float = 0
    
    init()
    {
        history.pl = self
    }
    
    var name:String? {
        didSet {
          //  bleConnectionInterface?.writeName(name!)
            NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.PLUpdatedName, object: self)
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
    
    func saveHistory()
    {
        history.addPoint(currentTime, position: cartPosition, acceleration: acceleration, gyro: gyro, mag: mag, velocity: velocity)
    }
    
    
    // MARK: - Cart Position + Velocity
    var velocity : Float = 0.0
    var maxMinVelocity : (min:Float, max:Float) = (0.0,0.0)
    var velocityRange : (min:Double, max:Double) = (-8.0,8.0)
    var lastCartPosition : (time:Float,position:Float)?
    var maxCartPosition : Float = 0.0
    
    var cartZero : Float = 0.0 {
        didSet {
            
            //var val:UInt16 = UInt16( cartZero / cartPositionConvertRatio)
 //           bleConnectionInterface?.writeCartZeroInt(val)
            NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.PLUpdatedCartZero, object: self)
        }
    }
    
    var cartZeroInt : UInt16 {
        get { return UInt16(cartZero / cartPositionConvertRatio) }
        set { cartZero  = Float(newValue) * cartPositionConvertRatio }
    }
    
    var cartPositionInt : UInt16 {
        get { return UInt16( cartPosition / cartPositionConvertRatio)}
        set {cartPosition = Float(newValue) * cartPositionConvertRatio}
    }
  
    var cartPosition : Float = 0.0 {
        didSet {
            
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

    // meters per click
    // 10 inches * 2.54 CM/inch
    
    var cmsPerRotation: Float = 10.0 * 2.54 {
        didSet {
            //bleConnectionInterface?.writeCmsPerRotation(cmsPerRotation)
                NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.PLUpdatedCmsPerRotation, object: self)
        }
    }
    
    
    // meters/click = 1 rotation/200 clicks * cmsPerRotation *  1m/100cm
    private var cartPositionConvertRatio: Float {
        get {
            return cmsPerRotation * (1.0/100.0) * (1.0/200)
        }
    }
    


    
    // MARK: - Acceleration
    var maxAcceleration : (x: Float, y:Float, z: Float) = (0.0,0.0,0.0)
    var minAcceleration : (x: Float, y:Float, z: Float) = (0.0,0.0,0.0)
    
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
    
    var LSM9DSOAccelMode = 0 {
        didSet {
            //bleConnectionInterface?.writeAccelMode(LSM9DSOAccelMode)
            NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.PLUpdatedAccelMode, object: self)
            
        }
    }
    
    enum AccelState {
        case A2G
        case A4G
        case A6G
        case A8G
    }
    
    let accelInfo : [AccelState:(Int,Float)] =
    [   .A2G:(0,2.0),
        .A4G:(1,4.0),
        .A6G:(2,6.0),
        .A8G:(3,8.0)
    ]
    
    
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
    
    
    
    func setAccelerationInt(#x:Int, y:Int, z:Int)
    {
        var xval : Float = Float(x) / LSM9DSOAccelCountpG
        var yval : Float = Float(y) / LSM9DSOAccelCountpG
        var zval : Float = Float(z) / LSM9DSOAccelCountpG
        
        acceleration = (x:xval,y:yval,z:zval)
    }
    
   
    
    // MARK: - Gyro
    var maxGyro : (x:Float, y:Float, z:Float) = (0.0,0.0,0.0)
    var minGyro : (x:Float, y:Float, z:Float) = (0.0,0.0,0.0)
    
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
    
    var LSM9DSOGyroMode = 0 {
        didSet {
            //bleConnectionInterface?.writeGyroMode(LSM9DSOGyroMode)
           NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.PLUpdatedGyroMode, object: self)
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
    
    func setGyroInt(#x:Int, y:Int, z:Int)
    {
        var xval : Float = Float(x) / LSM9DSOGyroCountpDPS
        var yval : Float = Float(y) / LSM9DSOGyroCountpDPS
        var zval : Float = Float(z) / LSM9DSOGyroCountpDPS
        gyro = (x:xval,y:yval,z:zval)
    }
    
    
  
    
    // MARK: - Magnemoter
    
    var maxMag : ( x:Float, y:Float, z:Float) = (0.0,0.0,0.0)
    var minMag : ( x:Float, y:Float, z:Float) = (0.0,0.0,0.0)
    
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
    
    var LSM9DS0MagMode = 0 {
        didSet {
            //bleConnectionInterface?.writeMagMode(LSM9DS0MagMode)
            NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.PLUpdatedMagMode, object: self)
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
    
    func setMagInt(#x:Int, y:Int, z:Int)
    {
        var xval : Float = Float(x) / LSM9DSOMagCountpG
        var yval : Float = Float(y) / LSM9DSOMagCountpG
        var zval : Float = Float(z) / LSM9DSOMagCountpG
        mag = (x:xval,y:yval,z:zval)
    }
    
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


    // MARK: - Environmental
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

}