//
//  BlueToothNeighborhood.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/3/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//


import CoreBluetooth


class BlueToothNeighborhood : NSObject {
    private var centralManager : CBCentralManager?
    var blePeripheralsPhysicsLab = [BleDevice]() // just the physics labs
    
    private var blueToothReady = false
    private var blePeripherals = [NSUUID:BleDevice]() // all the known ble peripherals
    
    // MARK: - Function to control the central manager
    
    func startUpCentralManager() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        createDemoDevices()
        
 
    }
    
    func discoverDevices() {
        centralManager?.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
    }
    
    func connectToDevice(peripheral: CBPeripheral?)
    {
        if peripheral != nil {
        centralManager?.connectPeripheral(peripheral!, options: nil)
        }
        
    }
    
    func disconnectDevice(bleD : BleDevice?)
    {
        if let per = bleD?.peripheral  {
            centralManager?.cancelPeripheralConnection(per)
            bleD?.pl?.bleConnectionInterface?.closeConnection()
        }
    }

    private func createDemoDevices()
    {
        
        for deviceName in demoDevices {
        
            let ns = NSUUID(UUIDString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")
            
            // make a new ble device
            let bleD = BleDevice(name: deviceName.0, lastSeen: NSDate())
            // add it to the table of device
            blePeripherals[ns!] = bleD
            
            let plInterface = PLAdvPacketInterface()
            
            bleD.pl = PhysicsLab()
            bleD.pl!.name = deviceName.0
            bleD.pl!.bleAdvInterface = plInterface
            plInterface.pl = bleD.pl
            
            bleD.pl!.bleConnectionInterface = PLBleInterface()
            bleD.pl!.bleConnectionInterface!.pl = bleD.pl!
            
            bleD.demoDevice!.pl = bleD.pl
            
            
            do {
                try bleD.demoDevice?.loadDataFiles((deviceName.1.0), fileName1: (deviceName.1.1), fileName2: (deviceName.1.2))

                // add it to the list of physics labs
                
                blePeripheralsPhysicsLab.append(bleD)
                bleD.deviceNumber = blePeripheralsPhysicsLab.count
                
                
                if deviceName.1.0 != nil && bleD.demoDevice!.nextUpdate0 != nil {
                    NSTimer.scheduledTimerWithTimeInterval(bleD.demoDevice!.nextUpdate0!, target: self, selector: "addDataDemoDevice0:", userInfo: bleD, repeats: false)
                }
                
                if deviceName.1.1 != nil && bleD.demoDevice!.nextUpdate1 != nil {
                    NSTimer.scheduledTimerWithTimeInterval(bleD.demoDevice!.nextUpdate1!, target: self, selector: "addDataDemoDevice1:", userInfo: bleD, repeats: false)
                }
 
                
                if deviceName.1.2 != nil && bleD.demoDevice!.nextUpdate2 != nil {
                    NSTimer.scheduledTimerWithTimeInterval(bleD.demoDevice!.nextUpdate0!, target: self, selector: "addDataDemoDevice2:", userInfo: bleD, repeats: false)
                }
                
            }
            catch DemoDevice.FileTypeReadErrors.DataError(let errorMessage) {
               print(errorMessage)
                //assertionFailure()

            }
            catch {
                print("Unhandeled")
                //assertionFailure()
            }
            
        }
        
        // cause the display to reload as we found a new physics lab
        NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.bLEUpdatedDevices, object: nil)
      
    }
    
    
    
    func addDataDemoDevice0(timer:NSTimer)
    {
        let userInfo = timer.userInfo as! BleDevice
        
        if let out = userInfo.demoDevice!.getNextData0()
        {
            userInfo.demoDevice?.pl?.bleAdvInterface?.addPacket(out)
        }
       
        if userInfo.demoDevice!.nextUpdate0 != nil
        {
            NSTimer.scheduledTimerWithTimeInterval((userInfo.demoDevice!.nextUpdate0!), target: self, selector: "addDataDemoDevice0:", userInfo: userInfo, repeats: false)
        }
        
    }
    
    func addDataDemoDevice1(timer:NSTimer)
    {
        let userInfo = timer.userInfo as! BleDevice
        
        if let out = userInfo.demoDevice!.getNextData1()
        {
            userInfo.demoDevice?.pl?.bleAdvInterface?.addPacket(out)
        }
        if userInfo.demoDevice!.nextUpdate1 != nil
        {
            NSTimer.scheduledTimerWithTimeInterval(userInfo.demoDevice!.nextUpdate1!, target: self, selector: "addDataDemoDevice1:", userInfo: userInfo, repeats: false)
        }
        
    }

    func addDataDemoDevice2(timer:NSTimer)
    {
        let userInfo = timer.userInfo as! BleDevice
        
        if let out = userInfo.demoDevice!.getNextData2()
        {
            //print("PacketType = \(out[2])")
            userInfo.demoDevice?.pl?.bleAdvInterface?.addPacket(out)
        }
        
        if userInfo.demoDevice!.nextUpdate2 != nil
        {
            NSTimer.scheduledTimerWithTimeInterval(userInfo.demoDevice!.nextUpdate2!, target: self, selector: "addDataDemoDevice2:", userInfo: userInfo, repeats: false)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.bLEUpdatedDevices, object: nil)

        
    }

    
}

extension BlueToothNeighborhood:  CBCentralManagerDelegate  {
    // MARK: - CBCentralManager Delegate Functions
    
    
    
    @objc func centralManagerDidUpdateState(central: CBCentralManager) {
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

    
    // disconnected a device
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        if let bleD = blePeripherals[peripheral.identifier]
        {
            NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.bLEDisconnected, object: bleD.pl!)
        }
    }
    
    // a device connection is complete
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        
        if let bleD = blePeripherals[peripheral.identifier]
        {
            // ARH this should probably be setup in the bleConnectionInterface Object
            peripheral.delegate = bleD.pl?.bleConnectionInterface
            //    println("starting service discovery")
            peripheral.discoverServices(nil)
            
        }
        
    }
    
    // called when you see an advertising packet
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber)
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
                NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.bLEUpdatedDevices, object: nil)
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
                bleD.deviceNumber = blePeripheralsPhysicsLab.count
                
                // cause the display to reload as we found a new physics lab
                NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.bLEUpdatedDevices, object: nil)
            }
        }
    }
    

}

