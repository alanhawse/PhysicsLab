//
//  PhysicsLab.swift
//
//  Created by Alan Hawse on 1/18/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import Foundation

struct LSM9DS0Params {
    static let bits = 15
    static let modeAccelMap = [2.0,4.0,6.0,8.0]
    static let modeGyroMap = [245.0, 500.0, 2000.0]
    static let modeMagMap = [2.0,4.0,8.0,12.0]
}

class PhysicsLab {
    
    var bleAdvInterface : PLAdvPacketInterface?
    var bleConnectionInterface : PLBleInterface?
    var history = CartHistory()
    var clock = Clock()
    
    var accelerometer = Accelerometer(modeMap: LSM9DS0Params.modeAccelMap, bits:LSM9DS0Params.bits)
    var gyro = Gyro(modeMap: LSM9DS0Params.modeGyroMap, bits: LSM9DS0Params.bits)
    var mag = Magnetometer(modeMap: LSM9DS0Params.modeMagMap, bits: LSM9DS0Params.bits)
    
    var pos : PositionSensor!
    
    init()
    {
        history.pl = self
        pos = PositionSensor(clock: clock)
    }
    
    var name:String? {
        didSet {
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
    
    func resetMaxMin() {
        accelerometer.resetMaxMin()
        gyro.resetMaxMin()
        mag.resetMaxMin()
        pos.resetMaxMin()
    }
    
    func saveHistory()
    {
        history.addPoint(clock.currentTime, position: pos.cartPosition, acceleration: accelerometer.val, gyro: gyro.val, mag: mag.val, velocity: pos.velocity)
    }
    
   
    // MARK: - Environmental
    var relativeHumdity : Double = 0.0
    var pressure :  Int = 0
    var temperature :  Double = 0.0
    var altitude :  Double = 0.0
    
    // http://www.gribble.org/cycling/air_density.html
    var airDensity :  Double {
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
            
            //let es = eso / (p*p*p*p*p*p*p*p) //8.0
            let es = eso / pow(p,8.0)
            let pv = es * Double(relativeHumdity)

            // http://www.holsoft.nl/physics/ocmain.htm
            let rho = 1.2929 * 273.15 / (Double(temperature) + 273.0531) * (Double(pressure) - 0.3783 * pv) / 1.013e5
                        
            return Double(rho)
        }
    }
    
    var dewPoint :  Double {
        get {
            
            let part1 = log(relativeHumdity/100)
            let part2 = (17.625*temperature)
            let part3 = (243.04+temperature)
            let part4 = 17.625-log(relativeHumdity/100)
            let part5 = (17.625*temperature)
            let part6 = (243.04+temperature)
            let rval = 243.04 * (part1 + (part2/part3))  / (part4-(part5/part6))
            return rval
        }
    }

}