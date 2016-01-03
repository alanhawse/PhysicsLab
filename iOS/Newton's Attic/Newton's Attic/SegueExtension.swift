//
//  SegueExtension.swift
//  Newton's Attic
//
//  Created by Alan Hawse on 1/2/16.
//  Copyright © 2016 Elkhorn Creek Engineering. All rights reserved.
//
// This protocol extension came from the WWDC2015 
// https://developer.apple.com/videos/play/wwdc2015-411/ 27:01

import Foundation
import UIKit

protocol SegueHandlerType {
    typealias SegueIdentifier : RawRepresentable
}

extension SegueHandlerType where
    Self: UIViewController,
    SegueIdentifier.RawValue == String {
    func performSegueWithIdentifier(segueIdentifier : SegueIdentifier, sender : AnyObject?) {
        performSegueWithIdentifier(segueIdentifier.rawValue, sender: sender)
    }
    
}
