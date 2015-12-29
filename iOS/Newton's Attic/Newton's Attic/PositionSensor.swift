//
//  PositionSensor.swift
//  Newton's Attic
//
//  Created by Alan Hawse on 7/16/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import Foundation

class PositionSensor {
    
    init(clock: Clock)
    {
        self.clock = clock
    }

    var clock : Clock
    
    var countsPerRotation = 200.0 // probably wants to be in the advertising packet
    var wheelCircumfrence = 15.14
    
    var velocity = 0.0
    var maxVelocity = 0.0
    var minVelocity = 0.0
    
    var positionRange : (min:Double, max:Double) = (0.0,35.0)
    var velocityRange : (min:Double, max:Double) = (-10.0,10.0)
    var lastCartPosition : (time:Double,position:Double)?
    var maxCartPosition = 0.0
    
    var cartZero : Double = 0.0     
    var cartZeroCounts : UInt16 {
        get { return UInt16(cartZero / cartPositionConvertRatio) }
        set { cartZero  =  Double(newValue) * cartPositionConvertRatio }
    }
    
    var cartPositionCounts : UInt16 {
        get { return UInt16( cartPosition / cartPositionConvertRatio)}
        set {cartPosition = Double(newValue) * cartPositionConvertRatio}
    }
    
    var cartPosition : Double = 0.0 {
        didSet {
            if cartPosition > maxCartPosition {
                maxCartPosition = cartPosition
            }
            
            if lastCartPosition != nil {
                // calculate current velocity
                if (clock.currentTime > lastCartPosition!.time + 0.2) // only calculate the velocity every 200ms
                {
                    velocity = (cartPosition - lastCartPosition!.position) / (clock.currentTime - lastCartPosition!.time)
                    if velocity > Double(velocityRange.max) {
                        
                        print("Velocity error \(velocity) = \(clock.currentTime) \(lastCartPosition!.time)")
                        print("Cart = \(cartPosition) \(lastCartPosition!.position)")
                        maxVelocity = velocity
                    }
                    if velocity < Double(velocityRange.min) {
                        minVelocity = velocity
                    }
                    lastCartPosition = (clock.currentTime,cartPosition)
                    
                }
            }
            else
            {
                lastCartPosition = (clock.currentTime,cartPosition)
            }
        }
    }

    var cmsPerRotation = 10.0 * 2.54 {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.PLUpdatedCmsPerRotation, object: self)
        }
    }

    // meters/click = 1 rotation/200 counts * cmsPerRotation *  1m/100cm
    var cartPositionConvertRatio: Double {
            return cmsPerRotation * (1.0/100.0) * (1.0/countsPerRotation)
    }
    
    func resetMaxMin() {
        maxVelocity = velocity
        minVelocity = velocity
        maxCartPosition = cartPosition
    }
}
  