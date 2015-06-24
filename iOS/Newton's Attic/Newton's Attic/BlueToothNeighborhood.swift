//
//  BlueToothNeighborhood.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/3/15.
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
    //    println("Connect to device \(peripheral!.identifier)")
        if peripheral != nil {
        centralManager?.connectPeripheral(peripheral, options: nil)
        }
        
    }
    
    func disconnectDevice(bleD : BleDevice?)
    {
        
        if bleD?.peripheral != nil {
            centralManager?.cancelPeripheralConnection(bleD?.peripheral)
            bleD?.pl?.bleConnectionInterface?.connectionComplete = false
            bleD?.pl?.bleConnectionInterface?.peripheral = nil
        }
    }
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        if let bleD = blePeripherals[peripheral.identifier]
        {
         //   println("Ble DisConnected")
            bleD.pl?.delegate?.physicsLabDisplay(bleD.pl!)
            
        }
    }
    
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        
        if let bleD = blePeripherals[peripheral.identifier]
        {
        //    println("Ble Connected")

            peripheral.delegate = bleD.pl?.bleConnectionInterface
            
            peripheral.discoverServices(nil)

        }
        
     }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [NSObject : AnyObject], RSSI: NSNumber)
    {
        
        let packetData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData
        
        if packetData == nil {
            return
        }
        var ar = [UInt8]()
        
        ar  = [UInt8](count:packetData!.length, repeatedValue: 0)
        // copy bytes into array
        packetData!.getBytes(&ar, length:packetData!.length)
        
        
        if let bleD = blePeripherals[peripheral.identifier]
        {
            bleD.lastSeen = NSDate()
            
            // if we have seen this device before and it is a physics lab then
            // you need to add the new advertising packet information
            if bleD.pl != nil
            {
                bleD.pl?.bleAdvInterface?.addPacket(ar)
                delegate?.addedDevice() // /ARH might be a bad idea if it causes to many updates of the list
            }
        }
        else // you have never seen the device
        {
            // make a new ble device
            let bleD = BleDevice(peripheral: peripheral, lastSeen: NSDate())
            // add it to the table of device
            blePeripherals[peripheral.identifier] = bleD
            
            let plInterface = PLAdvPacketInterface()
            if plInterface.isValid(ar)
            {
                bleD.pl = PhysicsLab()
                bleD.pl!.name = peripheral.identifier.UUIDString
                bleD.pl!.bleAdvInterface = plInterface
                plInterface.pl = bleD.pl
                
                bleD.pl!.bleConnectionInterface = PLBleInterface()
                bleD.pl!.bleConnectionInterface!.pl = bleD.pl!
                
                
                // add it to the list of physics labs
                blePeripheralsPhysicsLab.append(bleD)
                // cause the display to reload as we found a new physics lab
                delegate?.addedDevice()
            }
        }
    }
    
    
    
    @objc func centralManagerDidUpdateState(central: CBCentralManager!) {
        switch (central.state) {
        case .PoweredOff: break
        case .PoweredOn: blueToothReady = true
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

