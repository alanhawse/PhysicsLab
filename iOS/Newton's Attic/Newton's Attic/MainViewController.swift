//
//  ViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/3/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit

var loggedIn : Bool = false
var bleLand = BlueToothNeighborhood?()

class MainViewController: UITableViewController, BlueToothNeighborhoodUpdate {
    // a table id to bleDevice mapping table
    var tagToId = [Int: BleDevice]()
    
    @IBOutlet var devicesTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if bleLand == nil
        {
            bleLand = BlueToothNeighborhood()
            bleLand?.startUpCentralManager()
        }
        bleLand?.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        bleLand?.delegate = self
        // make it so that the tableviews dont go beneath the navigation bar
        navigationController?.navigationBar.translucent = false
        navigationController?.toolbar.translucent = false
    }
    
    // delegate method for the BlueToothNeighborhoodUpdate protocol
    func addedDevice() {
        devicesTable.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return bleLand?.blePeripheralsPhysicsLab.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("bledevice", forIndexPath: indexPath) as! UITableViewCell
        
        let ip = indexPath.row
        
        if bleLand?.blePeripheralsPhysicsLab.count > 0 {
            if let bleD = bleLand?.blePeripheralsPhysicsLab[ip]
            {
                // if the name is known then use it.. otherwise put the
                // identifier in the tableviewcell.  When the broadcast packet
                // with the name is received it will send a reload data which will
                // then change the identifier to the name in the table
                if let nm = bleD.pl?.name
                {
                    cell.textLabel!.text = nm
                }
                else
                {
                    cell.textLabel!.text = bleD.peripheral?.identifier.UUIDString
                }
                
                // tagtoid is a table of cell tags that map to which bleD so that
                // when the user clicks the device it can setup the next stages
                // with the correct bleDevice
                cell.tag = tagToId.count
                tagToId[tagToId.count+1] = bleD
            }
        }
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var destination = segue.destinationViewController as? UIViewController
        
        if let navCon = destination as? UINavigationController
        {
            destination = navCon.visibleViewController
        }
        
        if let tbc = destination as? PhysicsLabBarViewController
        {
            if let tvc = sender as? UITableViewCell {
                tbc.bleD = tagToId[tvc.tag]
            }
        }
        bleLand?.delegate = nil
    }

}