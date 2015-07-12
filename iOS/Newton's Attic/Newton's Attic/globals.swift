//
//  globals.swift
//  Newton's Attic
//
//  Created by Alan Hawse on 7/5/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

struct PLNotifications {
    static let PLUpdatedKinematicData = "org.elkhorn-creek.physicslab.updatedKinematicData"
    static let PLUpdatedEnviroment = "org.elkhorn-creek.physicslab.updatedEnvironment"
    static let PLUpdatedAdmin = "org.elkhorn-creek.physicslab.updatedName"
    static let BLEConnected = "org.elkhorn-creek.physicslab.BLEConnected"
    static let BLEDisconnected = "org.elkhorn-creek.physicslab.BLEDisconnected"
    static let BLEUpdatedDevices = "org.elkhorn-creek.physicslab.updatedDevices"
    static let PLUpdatedHistory = "org.elkhorn-creek.org.physicslab.updateHistory"
    
    static let PLUpdatedAccelMode = "org.elkhorn-creek.org.physicslab.updateAccelMode"
    static let PLUpdatedGyroMode = "org.elkhorn-creek.org.physicslab.updateMagMode"
    static let PLUpdatedMagMode = "org.elkhorn-creek.org.physicslab.updateMagMode"
    static let PLUpdatedName = "org.elkhorn-creek.org.physicslab.updateName"
    static let PLUpdatedCmsPerRotation = "org.elkhorn-creek.org.physicslab.updateCmsPerRotation"
    
    static let PLUpdatedCartZero = "org.elkhorn-creek.org.physicslab.updateCartZero"
}

struct GlobalHistoryConfig {
    static var maxRecordingTime : Float = 10.0
    static var maxPasses = 5
    static let maxPoints = 2500
    static let roundingTime = 30 // in miliseconds.. size of buckets for the recording
    static let triggerG : Float = 0.1
    static let directionThreshold : Float = 0.05 // cms you have to go the other way to increment the passes
}

struct Global {
    // sets the x-axis on the graph screen... the units are meters
    static var trackLength :Float = 45.0
    static let password = "1225" // newtons birthday
}

var loggedIn : Bool = false
var bleLand = BlueToothNeighborhood?()
