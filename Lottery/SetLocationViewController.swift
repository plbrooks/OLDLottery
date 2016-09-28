//
//  SetLocationViewController.swift
//  Lottery
//
//  Created by Peter Brooks on 9/27/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import UIKit
import Firebase

class SetLocationViewController: UIViewController {

    // MARK: Properties
    
    var ref: FIRDatabaseReference!
    var refHandleLocations: FIRDatabaseHandle!
    
    var countryName = ""
    
    class divisionData {
        var abbreviation        = ""
        var division            = ""
    }

    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()

    }

    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        loadDataFromFirebase()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        ref.removeAllObservers()
        
    }

    
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
    }
    
        
    func loadDataFromFirebase() {
        
        // Get countries
        
        let refKey = "LOCATIONS"
        
        refHandleLocations = self.ref.child(refKey).observe(.childAdded, with: { (snapshot) -> Void in
            
            //refHandleGames = self.ref.child(country).observeEventType(.Value, withBlock: { (snapshot) -> Void in
            
            if snapshot.exists() {
                
                let countryName = snapshot.key
                
                    /*let thisGame = self.createGameObjectUsingSnapshot(snapshot)
                    
                    // Add game to details and update games arrays
                    self.gamesDetail[gameName] = thisGame
                    self.addGameSortedByOddsToWin(thisGame, gameName: gameName, tableView: self.tableView, segmentIndex: self.segmentedControl.selectedSegmentIndex)
                    self.addGameSortedByTopPrize(thisGame, gameName: gameName, tableView: self.tableView, segmentIndex: self.segmentedControl.selectedSegmentIndex)
                    self.addGameSortedByPayout(thisGame, gameName: gameName, tableView: self.tableView, segmentIndex: self.segmentedControl.selectedSegmentIndex)*/
                print("data = \(snapshot.value)")
                
            } else {
                
                print("no snapshot")
                return
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
    }

}
