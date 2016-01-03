//
//  BleDevice.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/5/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//
import CoreBluetooth


class BleDevice {
    var peripheral : CBPeripheral?
    var lastSeen : NSDate?
    var pl : PhysicsLab?
    var deviceNumber = 0
    
    var demoDevice : DemoDevice?
    
    var connectedState : Bool  {
            get
            {
            if peripheral != nil {
                switch peripheral!.state
                {
                case .Connected:
                    return true
                case .Disconnected:
                    return false
                default: return false
                }
            }
            else
            {
                return false
            }
        }
    }
    
    var UUIDString : String
  
    init(peripheral: CBPeripheral, lastSeen: NSDate)
    {
        self.peripheral = peripheral
        self.lastSeen = lastSeen
        self.UUIDString = peripheral.identifier.UUIDString
    }
    
    init(name: String, lastSeen: NSDate )
    {
        self.peripheral = nil
        self.UUIDString = name
        self.lastSeen = lastSeen
        self.demoDevice = DemoDevice()
        
    }
}