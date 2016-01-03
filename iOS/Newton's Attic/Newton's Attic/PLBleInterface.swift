//
//  PLBleInterface.swift
//  Newton's Attic
//
//  Created by Alan Hawse on 6/21/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import Foundation
import CoreBluetooth

class PLBleInterface: NSObject {
    
    
    override init()
    {
        super.init()
    }
    
    // MARK: - Public Interface
    var connectionComplete = false
    var peripheral : CBPeripheral?
    var pl : PhysicsLab?
    
    private var characteristicCount = 0

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
    
    private struct PLBleCharacteristics {
        var charAccelMode : CBCharacteristic!
        var charMagMode : CBCharacteristic!
        var charGyroMode : CBCharacteristic!
        var charName : CBCharacteristic!
        var charWheelCircumfrence : CBCharacteristic!
        var charCartZero : CBCharacteristic!
        var charCartPosition : CBCharacteristic!
        
    }
    
    private var PLBleChar = PLBleCharacteristics()

    
    func closeConnection()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        connectionComplete = false
        peripheral = nil
    }
    
    
    // MARK: - Write Characteristcs to connection
    func writeName()
    {
        if connectionComplete {
            
            let temp  = (pl!.name! as NSString).dataUsingEncoding(NSUTF8StringEncoding)
            let data = NSMutableData(data: temp!)
            let x : [UInt8] = [0]
            data.appendBytes(x, length: 1)
            
            peripheral?.writeValue(data, forCharacteristic: PLBleChar.charName, type: CBCharacteristicWriteType.WithResponse)
            
        }
    }
    
    
    func writeCmsPerRotation()
    {
        bleWriteFloat(Float(pl!.pos.cmsPerRotation), char: PLBleChar.charWheelCircumfrence)
    }
    
    func writeResetPosition()
    {
        bleWriteUInt16(pl!.pos.cartZeroCounts, char: PLBleChar.charCartZero)
        
    }
    
    func writeAccelMode()
    {
        bleWriteUInt8(UInt8(pl!.accelerometer.mode), char: PLBleChar.charAccelMode)
    }
    
    func writeMagMode()
    {
        bleWriteUInt8(UInt8(pl!.mag.mode), char: PLBleChar.charMagMode)
    }
    
    func writeGyroMode()
    {
        bleWriteUInt8(UInt8(pl!.gyro.mode), char: PLBleChar.charGyroMode)
    }

    

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
            print("Writing val = \(val) to Char=\(char)")

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

extension PLBleInterface: CBPeripheralDelegate {
    // MARK: - BLE Discovery Delgate protocol interface
    
    // This function is called one time for each service in the device
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        
        //print("didDiscover Services \(peripheral)")
        
        self.peripheral = peripheral
        characteristicCount = 0
        
        for service in peripheral.services! {
            
            if service.UUID == PLBleInterfaceGlobals.SettingsService {
                
                //print("Discover characteristic for \(service.UUID)")
                
                peripheral.discoverCharacteristics(nil, forService: service) // ARH probably should replace nil with the specific ones
            }
            if service.UUID == PLBleInterfaceGlobals.KinematicService {
                //print("Discover characteristic for \(service.UUID)")
                
                peripheral.discoverCharacteristics(nil, forService: service) // ARH probably should replace nil with the specific ones
            }
            
            
        }
    }
    
    
    // this function is called once for each characterisitic in during discovery
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
        // print("Did Discover Characteristics")
        
        // print("Service = \(service)")
        
        for i in service.characteristics! {
            //let thisCharacteristic = i as! CBCharacteristic
            //  print("Service = \(i)")
            switch i.UUID
            {
            case PLBleInterfaceGlobals.CharacteristicAccelMode:
                PLBleChar.charAccelMode = i
                characteristicCount += 1
            case PLBleInterfaceGlobals.CharacteristicGyroMode:
                PLBleChar.charGyroMode = i
                characteristicCount += 1
            case PLBleInterfaceGlobals.CharacteristicMagMode:
                PLBleChar.charMagMode = i
                characteristicCount += 1
            case PLBleInterfaceGlobals.CharacteristicName:
                PLBleChar.charName = i
                characteristicCount += 1
            case PLBleInterfaceGlobals.CharacteristicWheelCircumfrence:
                PLBleChar.charWheelCircumfrence = i
                characteristicCount += 1
            case PLBleInterfaceGlobals.CharacteristicCartZero:
                PLBleChar.charCartZero = i
                characteristicCount += 1
            case PLBleInterfaceGlobals.CharacteristicPosition:
                PLBleChar.charCartPosition = i
                characteristicCount += 1
                
            default: break
            }
        }
        
        if characteristicCount == PLBleInterfaceGlobals.numCharacteristics {
            connectionComplete = true
            peripheral.setNotifyValue(true, forCharacteristic: PLBleChar.charCartPosition)
            
            NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.bLEConnected, object: pl!)
            
        }
        
    }
    
    // This function is called everytime a characteristic is updated and it is
    // set for ble notify
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if characteristic == PLBleChar.charCartPosition {
            var ar = [UInt8]()
            
            if let dat = characteristic.value  {
                
                ar  = [UInt8](count:dat.length, repeatedValue: 0)
                // copy bytes into array
                dat.getBytes(&ar, length:dat.length)
                
                let cp :UInt16 = UInt16(ar[0]) | UInt16(ar[1])<<8
                pl?.pos.cartPositionCounts = cp
                NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.pLUpdatedKinematicData, object: pl!)
            }
        }
    }

}

