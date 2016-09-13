//
//  GameViewController.swift
//  Lottery
//
//  Created by Peter Brooks on 9/5/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import UIKit
import Firebase

class GameViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: Properties
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableHeaderView: UIView!
    
    var ref: FIRDatabaseReference!

    var refHandleCountries: FIRDatabaseHandle!
    var refHandleGames: FIRDatabaseHandle!
    var refHandleGameDetail: FIRDatabaseHandle!
    
    var storageRef: FIRStorageReference!
    var remoteConfig: FIRRemoteConfig!
    
    var Countries: [FIRDataSnapshot]! = []
    var Games: [FIRDataSnapshot]! = []
    var GamesDetail: [FIRDataSnapshot]! = []
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        FIRDatabase.database().persistenceEnabled = true
        configureDatabase()
        
        //self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "GameCell")

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let header = tableHeaderView {
            header.frame.size.height = 44.0
        }
    }
    
    
    deinit {
        self.ref.child("Countries").removeObserverWithHandle(refHandleCountries)
        self.ref.child("Games").removeObserverWithHandle(refHandleCountries)
        self.ref.child("GameDetail").removeObserverWithHandle(refHandleCountries)
 
    }
    
    func configureDatabase() {
        
        ref = FIRDatabase.database().reference()
        
        // Listen for new country in the Firebase database
        refHandleCountries = self.ref.child("Countries").observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
            
            self.Countries.append(snapshot)
            print("countries snapshot = \(snapshot)")
            
        })
        
         // Listen for new Game in the Firebase database
        refHandleGames = self.ref.child("Games").observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
            
            self.Games.append(snapshot)
            print("games snapshot = \(snapshot)")
            //self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.FirebaseDB.count-1, inSection: 0)], withRowAnimation: .Automatic)
        
        })
        
         // Listen for new Game Detail in the Firebase database
        refHandleGameDetail = self.ref.child("Games Detail").observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
            
            self.GamesDetail.append(snapshot)
            print("games detail snapshot = \(snapshot)")
            //self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.FirebaseDB.count-1, inSection: 0)], withRowAnimation: .Automatic)
            
        })

    }
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellIdentifier = "GameCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! GameTableViewCell
        cell.gameName.text = "hi"
        cell.GameValue.text = "ho"
        
        return cell
    }

}
