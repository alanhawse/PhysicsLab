//
//  ViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/3/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit


class MainViewController: UITableViewController {

    // MARK: - Member Variables
    
    // a table id to bleDevice mapping table
    private var tagToId = [Int: BleDevice]()
    @IBOutlet var devicesTable: UITableView!
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if bleLand == nil
        {
            bleLand = BlueToothNeighborhood()
            bleLand?.startUpCentralManager()
        }
        
        readDefaults()
    }
    
    override func viewDidAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserverForName(PLNotifications.BLEUpdatedDevices, object: nil, queue: NSOperationQueue.mainQueue()) { _ in self.devicesTable.reloadData() }
        
        // make it so that the tableviews dont go beneath the navigation bar
        navigationController?.navigationBar.translucent = false
        navigationController?.toolbar.translucent = false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destination = segue.destinationViewController as UIViewController

        // tell the new viewcontroller which bleD model he is talking to
        if let tbc = destination as? PhysicsLabBarViewController
        {
            if let tvc = sender as? UITableViewCell {
                tbc.bleD = tagToId[tvc.tag]
            }
        }
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: - Table delegate functions
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return bleLand?.blePeripheralsPhysicsLab.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("bledevice", forIndexPath: indexPath) 
        
        let ip = indexPath.row
        
        if bleLand?.blePeripheralsPhysicsLab.count > 0 {
            if let bleD = bleLand?.blePeripheralsPhysicsLab[ip]
            {
                // if the name is known then use it.. otherwise put the
                // identifier in the tableviewcell.  When the broadcast packet
                // with the name is received it will send a reload data which will
                // then change the identifier to the name in the table
                if let name = bleD.pl?.name
                {
                    cell.textLabel!.text = name
                }
                else
                {
                    //cell.textLabel!.text = bleD.peripheral?.identifier.UUIDString
                    cell.textLabel!.text = bleD.UUIDString
                    
                }
                
                // tagtoid is a table of cell tags that map to which bleD so that
                // when the user clicks the device it can setup the next stages
                // with the correct bleDevice
                cell.tag = tagToId.count
                print("Cell tag = \(cell.tag)")
                tagToId[tagToId.count+1] = bleD
            }
        }
        return cell
    }
    
    // MARK: - Other functions
    
    func readDefaults()
    {
       
        var rval = 0.0
        let defaults = NSUserDefaults.standardUserDefaults()
        
        rval = defaults.doubleForKey(UserDefaultsKeys.recordingTime)
        if rval != 0.0
        {
            GlobalHistoryConfig.maxRecordingTime = rval
        }
    
        rval = defaults.doubleForKey(UserDefaultsKeys.trackLength)
        if rval != 0.0
        {
            Global.trackLength = rval
        }
    }

}