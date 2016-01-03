//
//  FileViewController.swift
//  Physics Lab
//
//  Created by Alan Hawse on 5/31/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import UIKit
import MessageUI

class FileViewController: UIViewController {
    
    private var fileNames = [String]()
    private var docsDir : String {
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        return dirPaths[0] 
    }
    // checkstate keeps track of the user checkmarks even if they
    // are off the screen.
    private var checkState = [UITableViewCellAccessoryType]()

    @IBOutlet weak var fileListTable: UITableView!
    @IBOutlet weak var fileTable: UITableView!
    

    // MARK: - Viewcontroller Lifecycle
    
    override func viewWillAppear(animated: Bool) {
        readFiles()
        fileTable.dataSource = self
        fileTable.delegate = self
    }
 
    // MARK: - UI Actions
    
    // if the user clicks the trash button then erase the currently
    // selected files... then for easy programming read in the file
    // list from the filesystem again
    @IBAction func trashAction(sender: UIButton) {
        trashFiles(getList())
        readFiles()
        fileListTable.reloadData()
    }
    
    // When the user clicks the mark all action button the
    // program will see how many files are checked.  If more than half are checked
    // then it will check the rest... otherwise it will uncheck all of them
    @IBAction func markAll(sender: UIButton) {
        var ip = NSIndexPath()
        var count = 0
        
        // iterate over all of the cells
        for i in 0..<fileNames.count {
            if checkState[i] != .None
            {
              count = count + 1
            }
        }
        
        var setCheck = false
        if count <= fileNames.count / 2 {
                setCheck = true
        }
        
        for i in 0..<fileNames.count {
            ip = NSIndexPath(forRow: i, inSection: 0)
            if let cell = fileTable.cellForRowAtIndexPath(ip)
            {
                if setCheck {
                    cell.accessoryType = .Checkmark
                    checkState[i] = .Checkmark
                }
                else
                {
                    cell.accessoryType = .None
                    checkState[i] = .None
                }
            }
        }
    }
    
    // if the user clicks the email button then make a list of all of
    // the files to mail.  the attach them.  then launch an email window
    // so the user can send the email
    @IBAction func emailAction(sender: UIButton) {
        let emvc = EmailViewController()
        if MFMailComposeViewController.canSendMail()
        {
            var files = [String]()
            for i in 0..<fileNames.count {
                if checkState[i] != .None {
                    files.append(fileNames[i])
                }
            }
            emvc.setupAttachments(docsDir: docsDir, fileNames: files)
            presentViewController(emvc, animated: true, completion: nil)
        }
        
    }
    

    
       // MARK: - Helper functions
    
    // if the cell is checked then you need to flip the state
    // in the list as well.
    private func flipCellState(cell : UITableViewCell)
    {
        for i in 0..<fileNames.count
        {
            if cell.textLabel?.text == fileNames[i] {
                if checkState[i] == .None {
                    checkState[i] = .Checkmark
                }
                else
                {
                    checkState[i] = .None
                }
                cell.accessoryType = checkState[i]
                return
            }
        }
    }
    
    // makes a filter list of all of the files that have a checkmark
    // used by trash and email
    private func getList() -> [String] {
        var rval = [String]()
        
        //var ip = NSIndexPath()
        for i in 0..<fileNames.count {
            if checkState[i] != .None {
                rval.append(fileNames[i])
            }
        }
        return rval
    }
    
    // erase all of the files in a list
    private func trashFiles(fileList: [String]) {
        let fileManager = NSFileManager.defaultManager()
        var docsDir: String?
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        docsDir = dirPaths[0] as String
        for i in fileList {
            let fname = docsDir! + "/" + i
            do {
                try fileManager.removeItemAtPath(fname)
            } catch _ {
            }
        }
    }
    
    
    // this function reads all of the files in the documents directory and adds them to the list of files that the program knows about
    private func readFiles() {
        fileNames.removeAll(keepCapacity: true)
        checkState.removeAll(keepCapacity: true)
        
        let fileManager = NSFileManager.defaultManager()
        let enumerator = fileManager.enumeratorAtPath(docsDir)
        
        while let element = enumerator?.nextObject() as? String {
            if element.hasSuffix(".csv") { // checks the extension
                fileNames.append(element)
                checkState.append(.None)
            }
        }
        
    }
}

extension FileViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileNames.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("fileName", forIndexPath: indexPath)
        
        let ip = indexPath.row
        cell.textLabel?.text = fileNames[ip]
        cell.accessoryType = checkState[ip]
        
        return cell
    }
    
}

extension FileViewController:  UITableViewDelegate {
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        flipCellState(cell!)
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        flipCellState(cell!)
    }
    

}
