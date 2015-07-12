//
//  EnviroViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/9/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

class EnviroViewController: UIViewController {

    var bleD : BleDevice?

    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var relativeHumidity: UILabel!
    @IBOutlet weak var pressure: UILabel!
    @IBOutlet weak var dewPoint: UILabel!
    @IBOutlet weak var altitude: UILabel!
    @IBOutlet weak var density: UILabel!
    
    
    // MARK: - Viewcontroller life cycle
    override func viewDidAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUI", name: PLNotifications.PLUpdatedEnviroment, object: bleD!.pl!)
        updateUI()
    }
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    

    // MARK: - Display functions

    /* ARH need a consistent name for these */
    func updateUI()
    {
        let x = NSNumberFormatter()
        x.numberStyle = .DecimalStyle
        x.minimumFractionDigits = 2
        x.maximumFractionDigits = 2
        
        if bleD?.pl?.temperature != nil {
            temperature.text = x.stringFromNumber(bleD!.pl!.temperature)
        }
        if bleD?.pl?.relativeHumdity != nil {
            relativeHumidity.text = x.stringFromNumber(bleD!.pl!.relativeHumdity)
        }
        if bleD?.pl?.pressure != nil {
            pressure.text = x.stringFromNumber(bleD!.pl!.pressure)
        }
        if bleD?.pl?.dewPoint != nil {
                dewPoint.text = x.stringFromNumber(bleD!.pl!.dewPoint)
        }
        if bleD?.pl?.altitude != nil {
            altitude.text = x.stringFromNumber(bleD!.pl!.altitude)
        }
        if bleD?.pl?.airDensity != nil {
            density.text = x.stringFromNumber(bleD!.pl!.airDensity)
        }
    }
}
