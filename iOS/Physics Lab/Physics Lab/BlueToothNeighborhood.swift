//
//  BlueToothNeighborhood.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/3/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import Foundation

//
//  ViewController.swift
//  PhysicsLab
//
//  Created by Alan Hawse on 3/21/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import CoreBluetooth

protocol BlueToothNeighborhoodUpdate {
    func addedDevice()
}

class BlueToothNeighborhood: NSObject, CBCentralManagerDelegate  {
    
    var physicsLabFilter = true
    
    var centralManager : CBCentralManager?
    
    var delegate : BlueToothNeighborhoodUpdate?
    
    var count : Int = 0
    

    var blueToothReady = false
    
    var blePeripherals = [NSUUID:BleDevice]()
    var blePeripheralsPhysicsLab = [BleDevice]()
    
    func startUpCentralManager() {

        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }
    
    func discoverDevices() {

        centralManager?.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
        
    }
    
    func connectToDevice(peripheral: CBPeripheral?)
    {

        if peripheral != nil {
        centralManager?.connectPeripheral(peripheral, options: nil)
        }
        
    }
    
    func disconnectDevice(bleD : BleDevice?)
    {
        
        if bleD?.peripheral != nil {
            centralManager?.cancelPeripheralConnection(bleD?.peripheral)
            bleD?.pl?.connectionComplete = false
            bleD?.pl?.peripheral = nil
        }
    }
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        if let bleD = blePeripherals[peripheral.identifier]
        {
            bleD.pl?.delegate?.physicsLabDisplay(bleD.pl!)
            
        }
    }
    
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        
        if let bleD = blePeripherals[peripheral.identifier]
        {
            peripheral.delegate = bleD.pl
            
            peripheral.discoverServices(nil)

        }
        
     }
    
    

    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [NSObject : AnyObject], RSSI: NSNumber)
    {
        
        let packetData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData
        
        var ar = [UInt8]()
        
        if packetData != nil {
            
            ar  = [UInt8](count:packetData!.length, repeatedValue: 0)
            // copy bytes into array
            packetData!.getBytes(&ar, length:packetData!.length)
        }
   
        
        if let bleD = blePeripherals[peripheral.identifier]  {
            bleD.lastSeen = NSDate()
            if bleD.pl != nil {
                    bleD.pl?.addPacket(ar)
            }
            
        }
        else
        {
            
            
            //println(peripheral.description)
            let bleD = BleDevice(peripheral: peripheral, lastSeen: NSDate(),advertisementData: ar)
            blePeripherals[peripheral.identifier] = bleD
            
            if bleD.pl == nil {

            }
            else
            {
                blePeripheralsPhysicsLab.append(bleD)
                delegate?.addedDevice()

            }
        
        }
        
        
    }
    
    
    
    @objc func centralManagerDidUpdateState(central: CBCentralManager!) {
        println("checking state\n")
        switch (central.state) {
        case .PoweredOff: break
            
        case .PoweredOn:
            blueToothReady = true;
            
        case .Resetting: break
            
        case .Unauthorized: break
            
        case .Unknown:break
            
        case .Unsupported:break
            
        }
        if blueToothReady {
            discoverDevices()
        }
    }
    
    
}

