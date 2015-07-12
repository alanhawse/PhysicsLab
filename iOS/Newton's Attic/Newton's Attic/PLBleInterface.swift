//
//  PLBleInterface.swift
//  Newton's Attic
//
//  Created by Alan Hawse on 6/21/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import Foundation
import CoreBluetooth

class PLBleInterface: NSObject, CBPeripheralDelegate {
    
    
    // MARK: - Public Interface
    var connectionComplete = false
    var peripheral : CBPeripheral?
    var pl : PhysicsLab?
    
    // MARK: - Private
    private struct PLBleInterfaceGlobals {
        
        static let SettingsService = CBUUID(string:"00000000-0000-1000-8000-00805F9B3300")
        static let CharacteristicAccelMode = CBUUID(string:"00000000-0000-1000-8000-00805F9B3310")
        static let CharacteristicGyroMode = CBUUID(string:"00000000-0000-1000-8000-00805F9B3320")
        static let CharacteristicMagMode = CBUUID(string:"00000000-0000-1000-8000-00805F9B3330")
        static let CharacteristicName = CBUUID(string:"00000000-0000-1000-8000-00805F9B3340")
        static let CharacteristicWheelCircumfrence = CBUUID(string:"00000000-0000-1000-8000-00805F9B3350")
        static let CharacteristicCartZero = CBUUID(string:"00000000-0000-1000-8000-00805F9B3360")
        static let CharacteristicCartPosition = CBUUID(string:"00000000-0000-1000-8000-00805F9B3370")
        
        // this is the number that must be discovered to make things work
        // be VERY careful changing this number as it is in this file several places
        static let numCharacteristics = 7
        
        static let KinematicService = CBUUID(string: "00000000-0000-1000-8000-00805F9B3100")
        static let CharacteristicAcceleration = CBUUID(string: "00000000-0000-1000-8000-00805F9B3110")
        static let CharacteristicMag = CBUUID(string: "00000000-0000-1000-8000-00805F9B3120")
        static let CharacteristicGyro = CBUUID(string: "00000000-0000-1000-8000-00805F9B3130")
        static let CharacteristicPosition = CBUUID(string: "00000000-0000-1000-8000-00805F9B3140")
        
    }
    
    struct PLBleCharacteristics {
        private var charAccel = CBCharacteristic()
        private var charMag = CBCharacteristic()
        private var charGyro = CBCharacteristic()
        private var charName = CBCharacteristic()
        private var charWheelCircumfrence = CBCharacteristic()
        private var charCartZero = CBCharacteristic()
        private var charCartPosition = CBCharacteristic()
    }
    
    private var PLBleChar = PLBleCharacteristics()
    
    func closeConnection()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        connectionComplete = false
        peripheral = nil
    }
    
    // MARK: - BLE Discovery Delgate protocol interface

    // This function is called one time for each service in the device
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        
        self.peripheral = peripheral
        characteristicCount = 0
        
        for service in peripheral.services {
            if let thisService = service as? CBService
            {
                if thisService.UUID == PLBleInterfaceGlobals.SettingsService {
                    
                    peripheral.discoverCharacteristics(nil, forService: thisService) // ARH probably should replace nil with the specific ones
                }
                if thisService.UUID == PLBleInterfaceGlobals.KinematicService {
                    peripheral.discoverCharacteristics(nil, forService: thisService) // ARH probably should replace nil with the specific ones
                }
                
            }
        }
    }
    
    private var characteristicCount = 0
    
    // this function is called once for each characterisitic in during discovery
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        
        
        for i in service.characteristics {
            let thisCharacteristic = i as! CBCharacteristic
            switch thisCharacteristic.UUID
            {
            case PLBleInterfaceGlobals.CharacteristicAccelMode:
                PLBleChar.charAccel = thisCharacteristic
                characteristicCount += 1
            case PLBleInterfaceGlobals.CharacteristicGyroMode:
                PLBleChar.charGyro = thisCharacteristic
                characteristicCount += 1
            case PLBleInterfaceGlobals.CharacteristicMagMode:
                PLBleChar.charMag = thisCharacteristic
                characteristicCount += 1
            case PLBleInterfaceGlobals.CharacteristicName:
                PLBleChar.charName = thisCharacteristic
                characteristicCount += 1
            case PLBleInterfaceGlobals.CharacteristicWheelCircumfrence:
                PLBleChar.charWheelCircumfrence = thisCharacteristic
                characteristicCount += 1
            case PLBleInterfaceGlobals.CharacteristicCartZero:
                PLBleChar.charCartZero = thisCharacteristic
                characteristicCount += 1
            case PLBleInterfaceGlobals.CharacteristicPosition:
                PLBleChar.charCartPosition = thisCharacteristic
                characteristicCount += 1
                
            default: break
            }
        }
        
        if characteristicCount == PLBleInterfaceGlobals.numCharacteristics {
            connectionComplete = true
            peripheral.setNotifyValue(true, forCharacteristic: PLBleChar.charCartPosition)
            
            NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.BLEConnected, object: nil)
            
            // setup the cart property observers
            /*
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "writeName", name: PLNotifications.PLUpdatedName, object: pl!)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "writeCartZeroInt", name: PLNotifications.PLUpdatedCartZero, object: pl!)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "writeCmsPerRotation", name: PLNotifications.PLUpdatedCmsPerRotation, object: pl!)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "writeAccelMode", name: PLNotifications.PLUpdatedAccelMode, object: pl!)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "writeGyroMode", name: PLNotifications.PLUpdatedGyroMode, object: pl!)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "writeMagMode", name: PLNotifications.PLUpdatedMagMode, object: pl!)
            
            */
            NSNotificationCenter.defaultCenter().addObserverForName(PLNotifications.PLUpdatedName, object: pl!, queue: NSOperationQueue.mainQueue() ) { _ in self.writeName() }
            NSNotificationCenter.defaultCenter().addObserverForName(PLNotifications.PLUpdatedCartZero, object: pl!, queue: NSOperationQueue.mainQueue() ) {_ in self.bleWriteUInt16(self.pl!.cartZeroInt, char: self.PLBleChar.charCartZero) }
            NSNotificationCenter.defaultCenter().addObserverForName(PLNotifications.PLUpdatedCmsPerRotation, object: pl!, queue: NSOperationQueue.mainQueue() ) { _ in self.bleWriteFloat(self.pl!.cmsPerRotation, char: self.PLBleChar.charWheelCircumfrence)}
            
            NSNotificationCenter.defaultCenter().addObserverForName(PLNotifications.PLUpdatedAccelMode, object: pl!, queue: NSOperationQueue.mainQueue() ) { _ in self.bleWriteUInt8(UInt8(self.pl!.LSM9DSOAccelMode), char: self.PLBleChar.charAccel) }
            NSNotificationCenter.defaultCenter().addObserverForName(PLNotifications.PLUpdatedGyroMode, object: pl!, queue: NSOperationQueue.mainQueue() ) { _ in self.bleWriteUInt8(UInt8(self.pl!.LSM9DSOGyroMode), char: self.PLBleChar.charGyro) }
            NSNotificationCenter.defaultCenter().addObserverForName(PLNotifications.PLUpdatedMagMode, object: pl!, queue: NSOperationQueue.mainQueue() ) { _ in self.bleWriteUInt8(UInt8(self.pl!.LSM9DS0MagMode), char: self.PLBleChar.charMag) }
        }
        
    }
    
    // This function is called everytime a characteristic is updated and it is
    // set for ble notify
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if characteristic == PLBleChar.charCartPosition {
            var ar = [UInt8]()
            
            if characteristic.value != nil {
                
                ar  = [UInt8](count:characteristic.value.length, repeatedValue: 0)
                // copy bytes into array
                characteristic.value.getBytes(&ar, length:characteristic.value.length)
                
                let cp :UInt16 = UInt16(ar[0]) | UInt16(ar[1])<<8
                pl?.cartPositionInt = cp
                NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.PLUpdatedKinematicData, object: pl!)
            }
        }
    }
    
    // MARK: - Write Characteristcs to connection
    private func writeName()
    {
        if connectionComplete {
            
            let temp  = (pl!.name! as NSString).dataUsingEncoding(NSUTF8StringEncoding)
            let data = NSMutableData(data: temp!)
            let x : [UInt8] = [0]
            data.appendBytes(x, length: 1)
            
            peripheral?.writeValue(data, forCharacteristic: PLBleChar.charName, type: CBCharacteristicWriteType.WithResponse)
            
        }
    }
    /*
    private func writeCartZeroInt() {
        bleWriteUInt16(pl!.cartZeroInt, char: PLBleChar.charCartZero)
    }
    
    private func writeCartPositionInt()
    {
        bleWriteUInt16(pl!.cartPositionInt, char: PLBleChar.charCartPosition)
    }
    
    
    private func writeCmsPerRotation()
    {
        bleWriteFloat(pl!.cmsPerRotation, char: PLBleChar.charWheelCircumfrence)
    }
    
    private func writeAccelMode()
    {
        self.bleWriteUInt8(UInt8(self.pl!.LSM9DSOAccelMode), char: self.PLBleChar.charAccel)
    }
    
    private func writeGyroMode()
    {
        self.bleWriteUInt8(UInt8(self.pl!.LSM9DSOGyroMode), char: self.PLBleChar.charGyro)
    }
    
    private func writeMagMode()
    {
        self.bleWriteUInt8(UInt8(self.pl!.LSM9DS0MagMode), char: self.PLBleChar.charMag)
    }
    
    */

    // MARK: - BLE Write Functions
    // ARH These should reall be done as extensions to Characertisitc?
    
    private func bleWriteUInt8(var val: UInt8, char: CBCharacteristic)
    {
        if connectionComplete {
            let ns = NSData(bytes: &val, length: sizeof(UInt8))
            peripheral?.writeValue(ns, forCharacteristic: char, type: CBCharacteristicWriteType.WithResponse)
        }
 
    }
    private func bleWriteFloat(var val: Float, char : CBCharacteristic)
    {
        if connectionComplete {
            //var outVal = pl!.cmsPerRotation
            let ns = NSData(bytes: &val, length: sizeof(Float))
            peripheral?.writeValue(ns, forCharacteristic: char, type: CBCharacteristicWriteType.WithResponse)
        }
    }
    private func bleWriteInt16(var val: Int16, char : CBCharacteristic)
    {
        if connectionComplete {
            //var outVal = pl!.cmsPerRotation
            let ns = NSData(bytes: &val, length: sizeof(Int16))
            peripheral?.writeValue(ns, forCharacteristic: char, type: CBCharacteristicWriteType.WithResponse)
        }
    }
 
    private func bleWriteUInt16(var val: UInt16, char : CBCharacteristic)
    {
        if connectionComplete {
            //var outVal = pl!.cmsPerRotation
            let ns = NSData(bytes: &val, length: sizeof(UInt16))
            peripheral?.writeValue(ns, forCharacteristic: char, type: CBCharacteristicWriteType.WithResponse)
        }
    }
}

