//
//  globals.swift
//  Newton's Attic
//
//  Created by Alan Hawse on 7/5/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

struct PLNotifications {
    static let pLUpdatedKinematicData = "org.elkhorn-creek.physicslab.updatedKinematicData"
    static let pLUpdatedEnviroment = "org.elkhorn-creek.physicslab.updatedEnvironment"
    static let pLUpdatedAdmin = "org.elkhorn-creek.physicslab.updatedName"
    static let bLEConnected = "org.elkhorn-creek.physicslab.BLEConnected"
    static let bLEDisconnected = "org.elkhorn-creek.physicslab.BLEDisconnected"
    static let bLEUpdatedDevices = "org.elkhorn-creek.physicslab.updatedDevices"
    static let pLUpdatedHistory = "org.elkhorn-creek.org.physicslab.updateHistory"
    
    static let pLUpdatedAccelMode = "org.elkhorn-creek.org.physicslab.updateAccelMode"
    static let pLUpdatedGyroMode = "org.elkhorn-creek.org.physicslab.updateMagMode"
    static let pLUpdatedMagMode = "org.elkhorn-creek.org.physicslab.updateMagMode"
    static let pLUpdatedName = "org.elkhorn-creek.org.physicslab.updateName"
    static let pLUpdatedCmsPerRotation = "org.elkhorn-creek.org.physicslab.updateCmsPerRotation"
    
    static let pLUpdatedCartZero = "org.elkhorn-creek.org.physicslab.updateCartZero"
    
    static let pLUpdatedHistoryState = "org.elkhorn-creek.org.physicslab.updatedHistoryState"
}

struct GlobalHistoryConfig {
    static var maxRecordingTime = 30.0 { didSet {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setDouble(maxRecordingTime, forKey: UserDefaultsKeys.recordingTime)
        }
    }
    static let maxRecordingTimeMin = 1.0
    static let maxRecordingTimeMax = 100.0
    
    static var maxPasses = 5
    
    // The 30 is the maximum number of packets/second... so 35 should be safe
    static var maxPoints : Int { get { return Int(maxRecordingTime) * 35 } }
    
    static let roundingTime = 30 // in miliseconds.. size of buckets for the recording
    static let triggerG  = 0.1 // change in Gs to start up the recording process
    static let directionThreshold = 0.05 // cms you have to go the other way to increment the passes
}


struct Global {
    // sets the x-axis on the graph screen... the units are meters
    static var trackLength = 45.0 { didSet {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setDouble(trackLength, forKey: UserDefaultsKeys.trackLength)
        }
    }
    
    static let minPacketRate = 25.0
    static let trackLengthMax = 100.0
    static let trackLengthMin = 5.0
    
    static let password = "1225" // newtons birthday
}




struct UserDefaultsKeys {
    static let trackLength = "TrackLength"
    static let recordingTime = "RecordingTime"
}

var loggedIn : Bool = false
var bleLand = BlueToothNeighborhood?()

// An array of the names of all of the demo devices and the datafile
var demoDevices : [String:(String?,String?,String?)]  = ["Demo1":("packet0Template","packet1Template","packet2Template")]


extension  UIImage {
    enum AssetIdentifier : String {
        case BlueToothConnected = "bluetoothconnected"
        case Login = "login"
        case Record = "recordbutton"
        
    }
    
    convenience init!(assetIdentifier: AssetIdentifier)
    {
        self.init(named: assetIdentifier.rawValue)
    }
}
