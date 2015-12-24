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

    init(time: Double, position: Double, acceleration:(x:Double,y:Double,z:Double),gyro:(x:Double,y:Double,z:Double),mag:(x:Double,y:Double,z:Double), velocity: Double)
    {
        self.acceleration = acceleration
        self.time = time
        self.gyro = gyro
        self.mag = mag
        self.position = position
        self.velocity = velocity
    }
    
    var acceleration : (x:Double,y:Double,z:Double) = (0,0,0)
    var mag : (x:Double,y:Double,z:Double) = (0,0,0)
    var gyro : (x:Double,y:Double,z:Double) = (0,0,0)
    var position : Double = 0
    var time : Double = 0
    var velocity : Double = 0.0
    
}


class CartHistory {

    var recording = false {
        didSet {
            // send the message that the recording is over
            if oldValue != recording {
                NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.PLUpdatedHistoryState, object: nil)
            }
        }
    }
    var armed = false {
        didSet {
            if oldValue != armed {
                // send the message that the recording is over
                NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.PLUpdatedHistoryState, object: nil)
            }
        }
    }
    
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
    // the buckets are defined by the GlobalHistoryConfig.roundingTime
    // the time starts from "0" ... which is when you arm the recording
    // e.g "7" is 7*GlobalHistoryConfig.roundingTime 
    // if the rounding time is 30 ... then 7 is the datapacket that occured at 7*30ms
    // so 7 would be anytime between 210ms and 239ms
    private var timeDps : [ Int: DataPoint]?
    
    // posDps = positionDataPoints stored by buckets of 1cm
    // So, the key is a position on the track in CMs... 
    // the value is an array of datapoints that occured each time it got to the track
    // at that position
    // I use "cartPass" to keep track of the number of times that the cart has been at a place on the track
    private var posDps : [Int:[Int:DataPoint]]?
    
    private var startTime : Int = 0 // start in Miliseconds
    private var lastTime : Int = 0 // in Miliseconds
    private var startTimeSeconds = Double(0.0)
    
    private var lastPosition : Double = Global.trackLength + Double(1.0)
    
    
    var packets : Int? {
        get {
            return history?.count
        }
    }
    
    var packetsPerSecond : Double? {
        get {
            if history?.count>2 {
                return Double(Int((Double(history!.count) / (history![history!.count-1].time - history![0].time))*10))/10
            }
            else
            {
                return nil
            }
        }
    }

    init()
    {
        history = [DataPoint]()
        timeDps = [Int: DataPoint]()
    }
    
    func arm(position: Double)
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
        
    var lastTimeSeconds : Double {return Double(lastTime-(startTime*GlobalHistoryConfig.roundingTime))/1000.0 }
    
    func triggerRecording ()
    {
        if recording == false && armed == true {
            recording = true
        }
    }
    
    func stopRecording()
    {
        recording = false
        armed = false
        
        let x = NSDate()
        let nsdfm = NSDateFormatter()
        nsdfm.timeStyle = .MediumStyle
        let fname = nsdfm.stringFromDate(x)
        let filename = "pl\(fname).csv"
        writeToFile(filename)

    }
    
    func addPoint(time: Double, position: Double,acceleration: (x:Double,y:Double,z:Double),gyro:(x:Double,y:Double,z:Double),mag:(x:Double,y:Double,z:Double), velocity : Double)
    {
   
        if !armed {
            return
        }
       
        
        if history?.count >= GlobalHistoryConfig.maxPoints || lastTimeSeconds > GlobalHistoryConfig.maxRecordingTime {
            stopRecording()
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
        
        let dp: DataPoint = DataPoint(time: time-startTimeSeconds, position: position ,acceleration: acceleration,gyro: gyro, mag: mag, velocity: velocity)
        
        
        history?.append(dp)
        
        // recording of data versus time
        
     //   let num = roundedTime - startTime
        
        if timeDps!.count < roundedTime-startTime {
            for i in timeDps!.count...(roundedTime-startTime) {
                timeDps![i] = dp
            }
        }
        
        /// recording of data versus position
        let pos = Int(position * 100)
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
            let dps = posDps![i]
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
        
        var heading = "time,position,velocity,accel x,accel y,accel z,mag x, mag y,mag z,gyro x,gyro y,gyro z\n"
        
        //print("points = \(history!.count)")
        
        for i in 0..<history!.count {
            if let dp = history?[i] {
                let outpoint = "\(dp.time),\(dp.position),\(dp.velocity),\(dp.acceleration.x),\(dp.acceleration.y),\(dp.acceleration.z),\(dp.mag.x),\(dp.mag.y),\(dp.mag.z),\(dp.gyro.x),\(dp.gyro.y),\(dp.gyro.z)\n"
                heading += outpoint
            }
        }
        
        if let dir : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
            let path = dir.stringByAppendingPathComponent(file)
            try! heading.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding)
            
        }
    }

}