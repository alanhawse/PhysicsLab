//
//  ThreeAxisModeConvertor.swift
//  Newton's Attic
//
//  Created by Alan Hawse on 7/16/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import Foundation

class ThreeAxisModeConvertor
{
    
    var bits = 15 { didSet { setValPerCount() } }
    var range = 16.0 { didSet { setValPerCount() } }
    var mode : Int = 0  {
        // this will crash if mode > number of things in array
        didSet { range = Double(modeMap[mode]) }
    }
    
    // maps modes (integers) to Mode Ranges (doubles)
    var modeMap = [0.0]
    var max : (x: Double, y:Double, z: Double) = (0.0,0.0,0.0)
    var min : (x: Double, y:Double, z: Double) = (0.0,0.0,0.0)
    
    init (modeMap: [Double], bits: Int) {
        valPerCount = 0 // to make the error disapear
        self.bits = bits
        self.modeMap = modeMap
        self.setValPerCount()
        
    }
    
    private func setValPerCount()
    {
        valPerCount = range/pow(2.0,Double(bits))
    }
    
    private var valPerCount : Double
    
    var x : Double { return val.x }
    var y : Double { return val.y }
    var z : Double { return val.z }
    
    var val : (x:Double, y:Double, z:Double) = (0.0,0.0,0.0) {
        didSet {
            if val.x >= max.x { max.x = val.x }
            if val.y >= max.y { max.y = val.y }
            if val.z >= max.z { max.z = val.z }
            
            if val.x <= min.x { min.x = val.x }
            if val.y <= min.y { min.y = val.y }
            if val.z <= min.z { min.z = val.z }
        }
    }
    
    var counts : (x:Int, y:Int, z:Int) {
        set {
            val = (x:Double(newValue.x) * valPerCount, y: Double(newValue.y) * valPerCount, z: Double(newValue.z) * valPerCount)
        }
        get {
            return (x: Int(val.x/valPerCount), y: Int(val.y/valPerCount ),z: Int(val.z/valPerCount))
        }
    }
    
    func resetMaxMin()
    {
        max = val
        min = val
    }
}
