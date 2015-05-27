//
//  GraphViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/22/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, PhysicsLabDisplayDelegate, GraphViewDataSource {
      var bleD : BleDevice?
    
    override func viewDidAppear(animated: Bool) {
        bleD?.pl?.delegate = self
        graphView.dataSource = self
        setRangeY()
        setRangeX()
        
    }
    
    // input x in CMs for range cms
    func getValYforXPosition(x: Int, range: Int) -> [Int : Float]? {
        
        var rval = [Int:Float]()
        var vals = bleD?.pl?.history.getValYforXPosition(x,range: range)
        

        for i in 0...bleD!.pl!.history.cartPass {
            if let dp = vals?[i]
            {
                switch ySelection.selectedSegmentIndex {
                case 0:
                    rval[i] = dp.acceleration.x
                case 1:
                    rval[i] = dp.acceleration.y
                case 2:
                    rval[i] = dp.acceleration.z
                case 3:
                    rval[i] = dp.velocity
                default:
                    break
                }
            }
        }
        return rval
    }
    
    func getValYforX(x: Double) -> Float? {
        
        if xSelection.selectedSegmentIndex == 0 {

            let y =  bleD?.pl?.history.getValYforXTime(x)
        
            switch ySelection.selectedSegmentIndex {
            case 0:
                return y?.acceleration.x
            case 1:
                return y?.acceleration.y
            case 2:
                return y?.acceleration.z
            case 3:
                return y?.velocity
            default:
                return nil
            }

        }
        
        return nil
        
    }
    
    func setRangeY()
    {
        switch ySelection.selectedSegmentIndex {
        case 0:
            graphView.rangeY = (min:CGFloat(-1*bleD!.pl!.LSM9DSOAccelRange),max:CGFloat(bleD!.pl!.LSM9DSOAccelRange))
        case 1:
            graphView.rangeY = (min:CGFloat(-1*bleD!.pl!.LSM9DSOAccelRange),max:CGFloat(bleD!.pl!.LSM9DSOAccelRange))

        case 2:
            graphView.rangeY = (min:CGFloat(-1*bleD!.pl!.LSM9DSOAccelRange),max:CGFloat(bleD!.pl!.LSM9DSOAccelRange))

        case 3:
            graphView.rangeY = (min:CGFloat(bleD!.pl!.velocityRange.min), max:CGFloat(bleD!.pl!.velocityRange.max))
          
        default:
            graphView.rangeY = (min:CGFloat(-1*bleD!.pl!.LSM9DSOAccelRange),max:CGFloat(bleD!.pl!.LSM9DSOAccelRange))
    
        }
    }
    
    func setRangeX() {
        switch xSelection.selectedSegmentIndex {
            
        case 0: // time
            graphView.rangeX = (min:CGFloat(0.0),max:CGFloat(bleD!.pl!.history.maxTime))
        case 1: // position
            graphView.rangeX = (min:CGFloat(0.0), max: CGFloat(45.0)) // arh hard coded meters
        default: // time
            graphView.rangeX = (min:CGFloat(0.0),max:CGFloat(bleD!.pl!.history.maxTime))
            
        }
    }
    
    func physicsLabDisplay(sender: PhysicsLab) {
        
        graphView.setNeedsDisplay()
        
    }

    
    @IBOutlet weak var graphView: GraphView!
    @IBOutlet weak var xSelection: UISegmentedControl!
    
    @IBAction func xSelect(sender: UISegmentedControl) {
        setRangeX()
        if sender.selectedSegmentIndex == 0 {
            graphView.scatterMode = false
        }
        else
        {
            graphView.scatterMode = true
        }
    }
    
    @IBOutlet weak var ySelection: UISegmentedControl!
    @IBAction func ySelect(sender: UISegmentedControl) {
        setRangeY()
    }
    

    
}
