//
//  BleDevice.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/5/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//
import CoreBluetooth


class BleDevice:NSObject {
   
    var peripheral : CBPeripheral?
    var lastSeen : NSDate?
    var pl : PhysicsLab?
  
    init(peripheral: CBPeripheral, lastSeen: NSDate, advertisementData: [UInt8])
    {
        self.peripheral = peripheral
        self.lastSeen = lastSeen
        self.pl = PhysicsLab(advertisementData: advertisementData)
        self.pl?.name = peripheral.identifier.UUIDString

    }
    
    
  
    
}