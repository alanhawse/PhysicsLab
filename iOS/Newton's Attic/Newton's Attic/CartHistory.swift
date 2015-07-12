//
//  CartHistory.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/22/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import Foundation

// This class is used to store one datapoint of all of the kinematic parameters of the car for one instance in time
class DataPoint {

    init(time: Float, position: Float, acceleration:(x:Float,y:Float,z:Float),gyro:(x:Float,y:Float,z:Float),mag:(x:Float,y:Float,z:Float), velocity: Float)
    {
        self.acceleration = acceleration
        self.time = time
        self.gyro = gyro
        self.mag = mag
        self.position = position
        self.velocity = velocity
    }
    
    var acceleration : (x:Float,y:Float,z:Float) = (0,0,0)
    var mag : (x:Float,y:Float,z:Float) = (0,0,0)
    var gyro : (x:Float,y:Float,z:Float) = (0,0,0)
    var position : Float = 0
    var time : Float = 0
    var velocity : Float = 0.0
    
}


class CartHistory {

    var recording = false
    var armed = false
    var pl : PhysicsLab?

    // number of times the car has gone back and forth
    // ARH - there might be a bug right here as maybe it
    // should start with 1 ... also is it public?
    var cartPass : Int = 0
    
    private var forwardDirection = true
    
    // store the history three different ways
    
    // history contains every datapoint
    private var history : [DataPoint]?
    
    // timeDps stores one datapoint for each Time "bucket"
    // the buckets are defined by the globalroundingtime
    private var timeDps : [ Int: DataPoint]?
    
    // posDps = positionDataPoints stored by buckets of the roundingtime
    private var posDps : [Int:[Int:DataPoint]]?
    
    private var startTime : Int = 0 // start in Miliseconds
    private var lastTime : Int = 0 // in Miliseconds
    private var startTimeSeconds = Float(0.0)
    
    private var lastPosition : Float = Global.trackLength + Float(1.0)


    init()
    {
        history = [DataPoint]()
        timeDps = [Int: DataPoint]()
    }
    
    func arm(position: Float)
    {
        lastPosition = position
        armed = true
    }
    
    
    func clearRecord()
    {
        history = nil
        timeDps = nil
        history = [DataPoint]()
        timeDps = [Int: DataPoint]()
        posDps = [Int:[Int:DataPoint]]()
        lastTime = 0
        recording = false
        armed = false
    }
        
    var lastTimeSeconds : Float {return Float(lastTime-(startTime*GlobalHistoryConfig.roundingTime))/1000.0 }
    
    func addPoint(time: Float, position: Float,acceleration: (x:Float,y:Float,z:Float),gyro:(x:Float,y:Float,z:Float),mag:(x:Float,y:Float,z:Float), velocity : Float)
    {
   
        if !armed {
            return
        }
       
        
        if history?.count >= GlobalHistoryConfig.maxPoints || lastTimeSeconds > GlobalHistoryConfig.maxRecordingTime {
            recording = false
            armed = false
        
            let x = NSDate()
            let nsdfm = NSDateFormatter()
            nsdfm.timeStyle = .MediumStyle
            let fname = nsdfm.stringFromDate(x)
            let filename = "pl\(fname).csv"
            writeToFile(filename)
            return
        }
        
        
        if !recording {
            
            if position > lastPosition || abs(acceleration.x) > GlobalHistoryConfig.triggerG {
                recording = true
                lastPosition = position
                forwardDirection = true
            }
            else
            {
                lastPosition = position
                return
            }
        }
        
        // decide if you should switch directions
        if forwardDirection {
            if position < lastPosition-GlobalHistoryConfig.directionThreshold
            {
                forwardDirection = false
                cartPass = cartPass + 1
            }
        }
        else {
            if position > lastPosition+GlobalHistoryConfig.directionThreshold {
                forwardDirection = true
                cartPass = cartPass + 1
            }
        }
        
        if cartPass>GlobalHistoryConfig.maxPasses {
            cartPass = GlobalHistoryConfig.maxPasses
        }
        
        // Save the position and time for next datapoint
        lastPosition = position
        lastTime = Int(time*1000.0)
        
        let roundedTime = lastTime / GlobalHistoryConfig.roundingTime
        
        // if it is the first datapoint... setup the starts
        if history?.count == 0 {
            startTimeSeconds = time
            startTime = roundedTime
        }
        
        var dp: DataPoint = DataPoint(time: time-startTimeSeconds, position: position ,acceleration: acceleration,gyro: gyro, mag: mag, velocity: velocity)
        
        
        history?.append(dp)
        
        // recording of data versus time
        
        let num = roundedTime - startTime
        
        if timeDps!.count < roundedTime-startTime {
            for i in timeDps!.count...(roundedTime-startTime) {
                timeDps![i] = dp
            }
        }
        
        /// recording of data versus position
        var pos = Int(position * 100)
        if let dpa = posDps?[pos] {
            var t1 = dpa
            t1[cartPass] = dp
            posDps![pos] = t1
        }
        else
        {
            var t1 = [Int:DataPoint]()
            t1[cartPass] = dp
            posDps![pos] = t1
        }

        NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.PLUpdatedHistory, object: pl!)
    }
    
    // return a y-value ... based on an x time
    func getValYforXTime(x: Double) -> DataPoint? {
        if timeDps == nil {
            return nil
        }
        
        let index = Int(x*1000)/GlobalHistoryConfig.roundingTime
        
        return timeDps![index]
    }
    
    // input x in CMs - recording in Cms... but the screen shows 18cms (or so) for each point
    // so you need to find the actual data in the range
    func getValYforXPosition(x: Int, range: Int) -> [Int:DataPoint]? {
        if posDps == nil {
            return nil
        }
        var rval = [Int:DataPoint]()
        for i in x...x+range
        {
            var dps = posDps![i]
            if dps != nil {
                for x in dps! {
                    rval[x.0] = x.1
                }
            }
            
        }
        return rval
    }

    // Save the history to a csv
    private func writeToFile(file: String)
    {
        let fileManager = NSFileManager.defaultManager()
        var docsDir: String?

        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        
        docsDir = dirPaths[0] as? String
        let dataFile = docsDir?.stringByAppendingPathComponent(file)
    
        var heading = "time,position,velocity,accel x,accel y,accel z,mag x, mag y,mag z,gyro x,gyro y,gyro z\n"
        
        println("points = \(history!.count)")
        
        for i in 0..<history!.count {
            if let dp = history?[i] {
                let outpoint = "\(dp.time),\(dp.position),\(dp.velocity),\(dp.acceleration.x),\(dp.acceleration.y),\(dp.acceleration.z),\(dp.mag.x),\(dp.mag.y),\(dp.mag.z),\(dp.gyro.x),\(dp.gyro.y),\(dp.gyro.z)\n"
                heading += outpoint
            }
        }
        var databuffer = (heading as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        fileManager.createFileAtPath(dataFile!, contents: databuffer!,attributes: nil)
        
    }
}