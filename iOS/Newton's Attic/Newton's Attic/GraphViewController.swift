//
//  GraphViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/22/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource {
      var bleD : BleDevice?
    
    // MARK: - Viewcontroller Lifecycle
    override func viewDidAppear(animated: Bool) {
        graphView.dataSource = self
        setRangeY()
        setRangeX()
        updateRate()
        
        NSNotificationCenter.defaultCenter().addObserverForName(PLNotifications.PLUpdatedKinematicData, object: bleD!.pl!, queue: NSOperationQueue.mainQueue())
            { _ in self.graphView.setNeedsDisplay()
                self.updateRate()
        }
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Display Functions
    
    @IBOutlet weak var graphView: GraphView!
    @IBOutlet weak var xSelection: UISegmentedControl!
    
    @IBOutlet weak var packets: UILabel!
    @IBOutlet weak var packetsPerSecond: UILabel!
    
    
    private func updateRate()
    {
        
        if let temp = bleD?.pl?.history.packets
        {
            packets.text = "\(temp)"
        }
        else
        {
            packets.text = "0"
        }
        
        if let temp = bleD?.pl?.history.packetsPerSecond
        {
            packetsPerSecond.text = "\(temp)"
        }
        else
        {
            packetsPerSecond.text = "0"

        }
        
        
    }
    
    
    
    @IBAction func xSelect(sender: UISegmentedControl) {
        setRangeX()
        if sender.selectedSegmentIndex == 0 {
            graphView.graphType = .Line
        }
        else
        {
            graphView.graphType = .Scatter

        }
    }
    
    private func setRangeX() {
        switch xSelection.selectedSegmentIndex {
        case 0: // time
           graphView.rangeX = (min:CGFloat(0.0),max:CGFloat(GlobalHistoryConfig.maxRecordingTime))
        case 1: // position
            graphView.rangeX = (min:CGFloat(0.0), max: CGFloat(Global.trackLength))
        default: // time
            graphView.rangeX = (min:CGFloat(0.0),max:CGFloat(GlobalHistoryConfig.maxRecordingTime))
            
        }
    }
    
    @IBOutlet weak var ySelection: UISegmentedControl!
    @IBAction func ySelect(sender: UISegmentedControl) {
        setRangeY()
    }
    
    private func setRangeY()
    {
        switch ySelection.selectedSegmentIndex {
        case 0:
            graphView.rangeY = (min:CGFloat(-1*bleD!.pl!.accelerometer.range),max:CGFloat(bleD!.pl!.accelerometer.range))
        case 1:
            graphView.rangeY = (min:CGFloat(-1*bleD!.pl!.accelerometer.range),max:CGFloat(bleD!.pl!.accelerometer.range))
        case 2:
            graphView.rangeY = (min:CGFloat(-1*bleD!.pl!.accelerometer.range),max:CGFloat(bleD!.pl!.accelerometer.range))
        case 3:
            graphView.rangeY = (min:CGFloat(bleD!.pl!.pos.velocityRange.min), max:CGFloat(bleD!.pl!.pos.velocityRange.max))
        default:
            graphView.rangeY = (min:CGFloat(-1*bleD!.pl!.accelerometer.range),max:CGFloat(bleD!.pl!.accelerometer.range))
        }
    }
    
    // MARK: - Graph datasource delegate
    
    // input x in CMs for range cms
    func getValYforXPosition(x: Int, range: Int) -> [Int : Double]? {
        
        var rval = [Int:Double]()
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
                default: break
                }
            }
        }
        return rval
    }
    
    // This function is used when the graphview is in line graph mode
    // it return the y-value based on teh current x-value
    func getValYforX(x: Double) -> Double? {
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
}
