//
//  CartHistory.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/22/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

protocol CartHistoryDisplayDelegate {
    func display(sender : CartHistory)
}

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
    
    var delegate : CartHistoryDisplayDelegate?
    
    var recording = false
    var armed = false

    func arm(position: Float)
    {
        lastPosition = position
        armed = true
    }
    
    init()
    {
        history = [DataPoint]()
        timeDps = [Int: DataPoint]()
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
    
    private let maxPoints = 2500
    let maxTime : Float = 20.0
    private let roundingTime = 30 // in miliseconds
    var cartPass : Int = 0
    private var forwardDirection = true
    
    private var history : [DataPoint]?
    private var timeDps : [ Int: DataPoint]?
    private var posDps : [Int:[Int:DataPoint]]?

    private var startTime : Int = 0
    private var lastTime : Int = 0
    private var startTimeSeconds = Float(0.0)
    
    private var lastPosition : Float = 50.0
    
    
    var lastTimeSeconds : Float {
        get {
            return Float(lastTime-(startTime*roundingTime))/1000.0
        }
    }
    
    
    func addPoint(time: Float, position: Float,acceleration: (x:Float,y:Float,z:Float),gyro:(x:Float,y:Float,z:Float),mag:(x:Float,y:Float,z:Float), velocity : Float)
    {
   
        if !armed {
            return
        }
       
        
        if history?.count >= maxPoints {
            recording = false
            armed = false
            return
        }
        
        if lastTimeSeconds > maxTime {
            recording = false
            armed = false
            return
        }
        
        
        if !recording {
            
            // ARH harded 0.1g
            if position > lastPosition || abs(acceleration.x) > 0.1 {
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
        
        // ARH hardcoded the 0.05 which is 5cms 
        // (dont change direction unless you have moved 5cm in other direction)
        if forwardDirection {
            if position < lastPosition-0.05
            {
                forwardDirection = false
                cartPass = cartPass + 1
            }
        }
        else {
            if position > lastPosition+0.05 {
                forwardDirection = true
                cartPass = cartPass + 1
            }
            
        }
        
        // arh hardcoded the maximum number of passes
        if cartPass>5 {
            cartPass = 5
        }
        
        lastPosition = position

        
        lastTime = Int(time*1000.0)
        
        let roundedTime = lastTime / roundingTime
        
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

        
        delegate?.display(self)
        
    }
    
    
    func getValYforXTime(x: Double) -> DataPoint? {
        if timeDps == nil {
            return nil
        }
        
        let index = Int(x*1000)/roundingTime
        
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
    
    
}