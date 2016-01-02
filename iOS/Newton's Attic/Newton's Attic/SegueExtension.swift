//
//  SegueExtension.swift
//  Newton's Attic
//
//  Created by Alan Hawse on 1/2/16.
//  Copyright © 2016 Elkhorn Creek Engineering. All rights reserved.
//

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
