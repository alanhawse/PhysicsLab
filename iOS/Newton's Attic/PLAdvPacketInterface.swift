//
//  PLAdvPacketInterface.swift
//  Newton's Attic
//
//  Created by Alan Hawse on 6/21/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import Foundation

class PLAdvPacketInterface {
    
    var pl: PhysicsLab?
    
    func isValid(ar: [UInt8]) -> Bool
    {
        if (ar.count == 26 && ar[0] == 0x31 && ar[1] == 1)
        {
            return true
        }
        else
        {
            return false
        }
        
    }
    
    func addPacket(ar: [UInt8])
    {
        if !isValid(ar)
        {
            return
        }
        let packetType = ar[2] & 0b00000011
        switch packetType {
        case 0:
            packetType0(ar)
        case 1:
            packetType1(ar)
        case 2:
            packetType2(ar)
        case 3:
            packetType3(ar)
            
        default:
            break
            
        }
        // ARH this might be a bad idea
        pl?.delegate?.physicsLabDisplay(pl!)
    }
    
    private var packet0Count = 0
    private func packetType0 (ar : [UInt8])
    {
        
        //println("Packet type 0")
        
        let packetTime = Float(Int(ar[3]) + Int(ar[4])<<8 + Int(ar[5])<<16) / 1000
        if packetTime == pl!.currentTime
        {
            return
        }
        packet0Count = packet0Count + 1
        //println("Packet 0 \(packet0Count)")
        pl!.currentTime = packetTime
        
        pl!.LSM9DSOAccelMode = Int((ar[2]  & 0b11000000) >> 6)
        pl!.LSM9DS0MagMode = Int((ar[2]  & 0b00110000) >> 4)
        pl!.LSM9DSOGyroMode = Int((ar[2]  & 0b00001100) >> 2)
        
        
        let b0 = UInt32(ar[3])
        let b1 = UInt32(ar[4])
        let b2 = UInt32(ar[5])
        
        let tempint = b0 + b1<<8 + b2<<16
        
        
        var tempInt:Int16 = 0
        var bytes : Array<UInt8> = [0,0,0,0]
        
        var uTempInt:UInt16 = 0
        
        // Position
        
        bytes[0] = ar[6]
        bytes[1] = ar[7]
        memcpy(&uTempInt, bytes,2)
        var tempPos : Int = Int(uTempInt)
        pl!.setCartPositionInt(tempPos)
       
        // acceleration
        
        bytes[0] = ar[8]
        bytes[1] = ar[9]
        memcpy(&tempInt,bytes,2)
        var dataX : Int = Int(tempInt)
        
        bytes[0] = ar[10]
        bytes[1] = ar[11]
        memcpy(&tempInt,bytes,2)
        var dataY : Int = Int(tempInt)
        
        bytes[0] = ar[12]
        bytes[1] = ar[13]
        memcpy(&tempInt,bytes,2)
        var dataZ : Int = Int(tempInt)
        
        pl!.setAccelerationInt(x:dataX,y:dataY,z:dataZ)
        
        /// Gyro
        bytes[0] = ar[14]
        bytes[1] = ar[15]
        memcpy(&tempInt,bytes,2)
        dataX  = Int(tempInt)
        
        bytes[0] = ar[16]
        bytes[1] = ar[17]
        memcpy(&tempInt,bytes,2)
        dataY  = Int(tempInt)
        
        bytes[0] = ar[18]
        bytes[1] = ar[19]
        memcpy(&tempInt,bytes,2)
        dataZ  = Int(tempInt)
        
       
        pl!.setGyroInt(x: dataX, y:dataY, z: dataZ)
        
        /// Mag
        bytes[0] = ar[20]
        bytes[1] = ar[21]
        memcpy(&tempInt,bytes,2)
        dataX  = Int(tempInt)
        
        bytes[0] = ar[22]
        bytes[1] = ar[23]
        memcpy(&tempInt,bytes,2)
        dataY  = Int(tempInt)
        
        bytes[0] = ar[24]
        bytes[1] = ar[25]
        memcpy(&tempInt,bytes,2)
        dataZ  = Int(tempInt)
       
        pl!.setMagInt(x: dataX, y:dataY, z: dataZ)
        
        pl!.saveHistory()
        
    }
    
    private var packet1Count = 0
    private var packet2Count = 0
    private func packetType1 (ar : [UInt8])
    {
        
        packet1Count = packet1Count + 1
        //println("Packet Type 1 = \(packet1Count)")
        var Time : Int = Int(ar[3]) + Int(ar[4])<<8 + Int(ar[5])<<16
        var tempInt:Int16 = 0
        var tempFloat:Float = 0.0
        var bytes : Array<UInt8> = [0,0,0,0]
        
        bytes[0] = ar[6]
        bytes[1] = ar[7]
        bytes[2] = ar[8]
        bytes[3] = ar[9]
        
        memcpy(&pl!.relativeHumdity,bytes,4)
        
        bytes[0] = ar[10]
        bytes[1] = ar[11]
        bytes[2] = ar[12]
        bytes[3] = ar[13]
        
        memcpy(&pl!.pressure,bytes,4)
        
        bytes[0] = ar[14]
        bytes[1] = ar[15]
        bytes[2] = ar[16]
        bytes[3] = ar[17]
        
        memcpy(&pl!.temperature,bytes,4)
        
        //   packet1Count = packet1Count + 1
        //   println("packet1Count = \(packet1Count)")
        
    }
    
    
    private func packetType2 (ar : [UInt8])
    {
        
        //  println("Packet Type 2")
        var Time : Int = Int(ar[3]) + Int(ar[4])<<8 + Int(ar[5])<<16
        var tempInt:Int16 = 0
        var tempFloat:Float = 0.0
        var bytes : Array<UInt8> = [0,0,0,0]
        
        bytes[0] = ar[6]
        bytes[1] = ar[7]
        bytes[2] = ar[8]
        bytes[3] = ar[9]
        
        memcpy(&pl!.altitude,bytes,4)
        
        /*
        bytes[0] = ar[10]
        bytes[1] = ar[11]
        bytes[2] = ar[12]
        bytes[3] = ar[13]
        
        memcpy(&airDensity,bytes,4)
        
        bytes[0] = ar[14]
        bytes[1] = ar[15]
        bytes[2] = ar[16]
        bytes[3] = ar[17]
        
        memcpy(&dewPoint,bytes,4) */
        
        //    packet2Count = packet2Count + 1
        //   println("packet2Count = \(packet2Count)")
    }
    
    var packet3Count = 0
    
    private func packetType3( ar: [UInt8])
    {
        
        //  println("Packet Type 3")
        var tempUInt : UInt16 = 0
        var tempInt:Int16 = 0
        var tempFloat:Float = 0.0
        var bytes : Array<UInt8> = [0,0,0,0]
        bytes[0] = ar[17]
        bytes[1] = ar[18]
        bytes[2] = ar[19]
        bytes[3] = ar[20]
        memcpy(&pl!.cmsPerRotation,bytes,4)
        
        bytes[0] = ar[21]
        bytes[1] = ar[22]
        memcpy(&tempUInt,bytes,2)
        
        pl!.setCartZeroInt(Int(tempUInt))
        
        
        var tempAr = [UInt8]()
        
        let offset = 3
        for i in 0...14 {
            if ar[i+offset] == 0 {
                break
            }
            tempAr.append(ar[i+offset])
        }
        
        if let  nm = NSString(bytes: tempAr, length: tempAr.count, encoding: NSUTF8StringEncoding)
        {
            pl!.name = nm as String
        }
        
        //   packet3Count = packet3Count + 1
        //   println("packet 3 \(tempFloat) packet3Count = \(packet3Count)")
        
    }
}