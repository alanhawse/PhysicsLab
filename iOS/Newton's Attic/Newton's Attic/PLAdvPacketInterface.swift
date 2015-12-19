//
//  PLAdvPacketInterface.swift
//  Newton's Attic
//
//  Created by Alan Hawse on 6/21/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import Foundation

class PLAdvPacketInterface {
    
    // this enum is not currently used ... maybe should be gone
    private enum fieldTypes {
        case Other
        case UI8Bit
        case UI24Bit
        case SI16Bit
        case UI16Bit
        case F32Bit
    }
    
    private struct PLAdvHeaderFormat {
        static let packetSize = 26 // I wish that there was a way to not hardcode this number
        static let bleMfgCode   = (offset:0,numBytes: 2, type:fieldTypes.UI16Bit, value: UInt16(0x0131))
        static let packetType   = (offset:2,numBytes: 1, type:fieldTypes.Other)
 
    }
    
    private struct PLAdvPacket0Format {
        static let time         = (offset:3,numBytes: 3, type:fieldTypes.UI24Bit)
        static let position     = (offset:6,numBytes: 2, type:fieldTypes.UI16Bit)
        static let accelX       = (offset:8,numBytes: 2, type:fieldTypes.SI16Bit)
        static let accelY       = (offset:10,numBytes: 2, type:fieldTypes.SI16Bit)
        static let accelZ       = (offset:12,numBytes: 2, type:fieldTypes.SI16Bit)
        static let gyroX        = (offset:14,numBytes: 2, type:fieldTypes.SI16Bit)
        static let gyroY        = (offset:16,numBytes: 2, type:fieldTypes.SI16Bit)
        static let gyroZ        = (offset:18,numBytes: 2, type:fieldTypes.SI16Bit)
        static let magX         = (offset:20,numBytes: 2, type:fieldTypes.SI16Bit)
        static let magY         = (offset:22,numBytes: 2, type:fieldTypes.SI16Bit)
        static let magZ         = (offset:24,numBytes: 2, type:fieldTypes.SI16Bit)
    }
    
    private struct PLAdvPacket1Format {
        static let time         = (offset:3,numBytes: 3, type:fieldTypes.UI24Bit)
        static let humidity     = (offset:6, numBytes: 4, type: fieldTypes.F32Bit)
        static let airPressure  = (offset:10, numBytes: 4, type: fieldTypes.F32Bit)
        static let temperature  = (offset:14, numBytes: 4, type: fieldTypes.F32Bit)
        static let altitude     = (offset:18, numBytes: 4, type: fieldTypes.F32Bit)
    }
    
    private struct PLAdvPacket2Format {
        static let name         = (offset:3, numBytes: 14, type: fieldTypes.Other)
        static let wheelCircumfrence = (offset:17, numBytes: 4, type: fieldTypes.F32Bit)
        static let zeroPos      = (offset:21, numBytes: 2, type: fieldTypes.UI16Bit)
        static let ticksPerRotation = (offset:23, numBytes:2, type: fieldTypes.UI16Bit)
    }
    

    var pl: PhysicsLab?
    
    // figure out if it is a valid Physics Lab Packet by looking at the length and the header
    func isValid(ar: [UInt8]) -> Bool
    {
        if (ar.count == PLAdvHeaderFormat.packetSize && decodeBytesAtOffset(0, ar: ar, numBytes: PLAdvHeaderFormat.bleMfgCode.numBytes ) == PLAdvHeaderFormat.bleMfgCode.value)
        {
            return true
        }

        return false
    }
   
    private var packet0Count = 0
    private var packet1Count = 0
    private var packet2Count = 0
    private var packet0CountLast = 0
    private var packet1CountLast = 0
    private var packet2CountLast = 0
    private var packet0LastTime = 0.0
    
    var packetsPerSecond = 0.0
    

    func addPacket(ar: [UInt8])
    {
        if !isValid(ar)
        {
            return
        }
        // ARH Figure out how to do a bit field
        let packetType = ar[PLAdvHeaderFormat.packetType.offset] & 0b00000011
        switch packetType {
        case 0:
            packetType0(ar)
            NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.PLUpdatedKinematicData, object: pl!)
            
        case 1:
            packetType1(ar)
            NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.PLUpdatedEnviroment, object: pl!)

        case 2:
            packetType2(ar)
            NSNotificationCenter.defaultCenter().postNotificationName(PLNotifications.PLUpdatedAdmin, object: pl!)
            
        default: break
        }

     }
    
    private func packetType0 (ar : [UInt8])
    {
        let Time : Int = decodeBytesAtOffset(PLAdvPacket0Format.time.offset, ar: ar, numBytes: PLAdvPacket0Format.time.numBytes)
        let packetTime = Double(Time) / 1000 // convert ms to seconds ARH this is the wrong place for this magic number

        if packetTime == pl!.clock.currentTime
        {
            return
        }
        
        packet0Count = packet0Count + 1
        if packetTime-packet0LastTime > 1.0 {
            packetsPerSecond = Double(packet0Count - packet0CountLast) / (packetTime-packet0LastTime)
            
            if packetsPerSecond < Global.minPacketRate {
                bleLand?.discoverDevices()
            }
            packet0CountLast = packet0Count
            packet0LastTime = packetTime
        }
        
        pl!.clock.currentTime = packetTime
        
        // ARH need to do something about this
        pl!.accelerometer.mode = Int((ar[2]  & 0b11000000) >> 6)
        pl!.mag.mode = Int((ar[2]  & 0b00110000) >> 4)
        pl!.gyro.mode = Int((ar[2]  & 0b00001100) >> 2)
        
        //pl!.pos.currentTime = packetTime
        pl!.pos.cartPositionCounts = decodeBytesAtOffset(PLAdvPacket0Format.position.offset, ar: ar, numBytes: PLAdvPacket0Format.position.numBytes)
       
        
        var dataX: Int16 = 0
        var dataY: Int16 = 0
        var dataZ: Int16 = 0

        dataX = decodeBytesAtOffset(PLAdvPacket0Format.accelX.offset, ar: ar, numBytes: PLAdvPacket0Format.accelX.numBytes)
        dataY = decodeBytesAtOffset(PLAdvPacket0Format.accelY.offset, ar: ar, numBytes: PLAdvPacket0Format.accelY.numBytes)
        dataZ = decodeBytesAtOffset(PLAdvPacket0Format.accelZ.offset, ar: ar, numBytes: PLAdvPacket0Format.accelZ.numBytes)
        pl!.accelerometer.counts = (x:Int(dataX),y:Int(dataY),z:Int(dataZ))

        
        dataX = decodeBytesAtOffset(PLAdvPacket0Format.gyroX.offset, ar: ar, numBytes: PLAdvPacket0Format.gyroX.numBytes)
        dataY = decodeBytesAtOffset(PLAdvPacket0Format.gyroY.offset, ar: ar, numBytes: PLAdvPacket0Format.gyroY.numBytes)
        dataZ = decodeBytesAtOffset(PLAdvPacket0Format.gyroZ.offset, ar: ar, numBytes: PLAdvPacket0Format.gyroZ.numBytes)
        pl!.gyro.counts =  (x: Int(dataX), y:Int(dataY), z: Int(dataZ))
        
        dataX = decodeBytesAtOffset(PLAdvPacket0Format.magX.offset, ar: ar, numBytes: PLAdvPacket0Format.magX.numBytes)
        dataY = decodeBytesAtOffset(PLAdvPacket0Format.magY.offset, ar: ar, numBytes: PLAdvPacket0Format.magY.numBytes)
        dataZ = decodeBytesAtOffset(PLAdvPacket0Format.magZ.offset, ar: ar, numBytes: PLAdvPacket0Format.magZ.numBytes)
        pl!.mag.counts = (x: Int(dataX), y:Int(dataY), z: Int(dataZ))

        pl!.saveHistory()
    }
    
    private func packetType1 (ar : [UInt8])
    {
        packet1Count = packet1Count + 1
        pl!.relativeHumdity = decodeBytesAtOffset(PLAdvPacket1Format.humidity.offset, ar: ar, numBytes: PLAdvPacket1Format.humidity.numBytes)
        pl!.pressure = decodeBytesAtOffset(PLAdvPacket1Format.airPressure.offset, ar: ar, numBytes: PLAdvPacket1Format.airPressure.numBytes)
        pl!.temperature = decodeBytesAtOffset(PLAdvPacket1Format.temperature.offset, ar: ar, numBytes: PLAdvPacket1Format.temperature.numBytes)
        pl!.altitude = decodeBytesAtOffset(PLAdvPacket1Format.altitude.offset, ar: ar, numBytes: PLAdvPacket1Format.altitude.numBytes)
    }
    
    private func packetType2( ar: [UInt8])
    {
        packet2Count = packet2Count + 1
        pl!.pos.cmsPerRotation = decodeBytesAtOffset(PLAdvPacket2Format.wheelCircumfrence.offset, ar: ar, numBytes: PLAdvPacket2Format.wheelCircumfrence.numBytes)
        
        pl!.pos.cartZeroCounts = decodeBytesAtOffset(PLAdvPacket2Format.zeroPos.offset, ar: ar, numBytes: PLAdvPacket2Format.zeroPos.numBytes)
        
        let tempU16 : UInt16 = decodeBytesAtOffset(PLAdvPacket2Format.ticksPerRotation.offset, ar: ar, numBytes: PLAdvPacket2Format.ticksPerRotation.numBytes)
        pl!.pos.countsPerRotation = Double(tempU16)
        
        // Decode name from the packet
        var tempAr = [UInt8]()
        for i in 0...PLAdvPacket2Format.name.numBytes {
            if ar[i+PLAdvPacket2Format.name.offset] == 0 {
                break
            }
            tempAr.append(ar[i+PLAdvPacket2Format.name.offset])
        }
        
        if let  nm = NSString(bytes: tempAr, length: tempAr.count, encoding: NSUTF8StringEncoding)
        {
            pl!.name = nm as String
        }
    }
    
    // MARK: - Decoder helpers
    
    private func decodeBytesAtOffset(offset: Int, ar : [UInt8], numBytes: Int ) -> Double {
        var bytes : Array<UInt8> = [0,0,0,0]
        var rval : Float = 0.0
        bytes[0] = ar[offset]
        bytes[1] = ar[offset+1]
        bytes[2] = ar[offset+2]
        bytes[3] = ar[offset+3]
        memcpy(&rval,bytes,4)
        return Double(rval)
    }
    
    private func decodeBytesAtOffset(offset: Int, ar : [UInt8] , numBytes: Int) -> UInt16
    {
        return UInt16(ar[offset]) + UInt16(ar[offset+1])<<8
    }
    
    private func decodeBytesAtOffset(offset: Int, ar: [UInt8], numBytes: Int) -> Int16
    {
        var bytes : Array<UInt8> = [0,0,0,0]
        var rval : Int16 = 0
        bytes[0] = ar[offset]
        bytes[1] = ar[offset+1]
        memcpy(&rval,bytes,2)
        return rval
    }
    
    // can decode a signed 4 bytes or an unsigned 3 byte
    private func decodeBytesAtOffset(offset: Int, ar: [UInt8], numBytes: Int) -> Int
    {
        var bytes : Array<UInt8> = [0,0,0,0]
        var rval : Int = 0
        bytes[0] = ar[offset]
        bytes[1] = ar[offset+1]
        bytes[2] = ar[offset+2]
        bytes[3] = 0
        if(numBytes == 4)
        {
            bytes[3] = ar[offset+3]
        }
        memcpy(&rval,bytes,4)
        return rval
    }
}