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
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var ref: FIRDatabaseReference!

    var refHandleCountries: FIRDatabaseHandle!
    var refHandleGames: FIRDatabaseHandle!
    var refHandleGameDetail: FIRDatabaseHandle!
    
    var storageRef: FIRStorageReference!
    //var remoteConfig: FIRRemoteConfig!
    
    class game {
        var name                = ""
        var wager               = 0
        var topPrize            = ""
        var oddsToWin           = 0.0
        var oddsToWinTopPrize   = 0
        var totalWinners        = 0
        var totalWinnings       = 0
        var topPrizeDetails     = ""
        var gameType            = ""
        var updateDate          = ""
    }
    
    var gamesInput          : [game] = []               // unsorted array of games read in from
    var gamesByOddsToWin    : [game] = []               // array of game classes sorted bg OddsToWin
    var gamesByMaxPrize     : [game] = []               // array of game classes sorted by maximum prize
    var gamesByPayout       : [game] = []               // array of game classes sorted by maximum payout
    
    // Update defaults!
    
    var lotteryLocation = [
        "country"           : "United States",
        "division"          : "Massachusetts",
        "divisionTitle"     : "",
        "abbrev"            : "",
        "currencyName"      : "",
        "currencySymbol"    : ""
    ]
    
    // add Firebase to viewWillAppear not viewDidLoad?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate      = self
        tableView.dataSource    = self
        
        FIRDatabase.database().persistenceEnabled = true
        configureDatabase()
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
        
        self.ref.child(lotteryLocation["country"]!).removeObserverWithHandle(refHandleGames)
        
    }
    
    func configureDatabase() {  // first inititialization
       
        // parse JSON using pod?
        
        ref = FIRDatabase.database().reference()
        let country = lotteryLocation["country"]!
        let division = lotteryLocation["division"]!
        
        // Listen for new Country in the Firebase database
        refHandleGames = self.ref.child(country).observeEventType(.Value, withBlock: { (snapshot) -> Void in
            
            if snapshot.exists() {
                
                let countryInfo = snapshot.value! as! NSDictionary

                if let description = countryInfo["Description"] {
                    self.lotteryLocation["abbrev"] = description["Abbrev"] as? String
                    self.lotteryLocation["currencyName"] = description["Currency Name"] as? String
                    self.lotteryLocation["currencySymbol"] = description["Currency Symbol"] as? String
                    //print("lotteryLocation = \(self.lotteryLocation)")
                }
        
                if let lotteryInfo = countryInfo[division] as? NSDictionary {
                    for (gameName, gameInfo) in lotteryInfo {
                        
                        // Note: Need to downcast all JSON fields. "Segemention fault: 11" error means mismatch between var definition and JSON
                        // Numbers with no decimal point in the dict are NSNumbers, with "" are Strings,s and with decimal point are Doubles
                        let thisGame = game()
                        thisGame.name = gameName as! String
                        
                        
                        var thisInfo = gameInfo as! [String : AnyObject]
                        thisGame.wager = Int(thisInfo["Wager"] as! NSNumber)
                        thisGame.topPrize = thisInfo["Top Prize"] as! String
                        thisGame.oddsToWin = thisInfo["Odds To Win"] as! Double
                        thisGame.totalWinners = Int(thisInfo["Total Winners"] as! NSNumber)
                        thisGame.totalWinnings = Int(thisInfo["Total Winnings"] as! NSNumber)
                        thisGame.oddsToWinTopPrize = Int(thisInfo["Odds To Win Top Prize"] as! NSNumber)
                        thisGame.topPrizeDetails = thisInfo["Top Prize Details"] as! String
                        thisGame.gameType = thisInfo["Type"] as! String
                        thisGame.updateDate = thisInfo["Updated"] as! String
                        self.gamesByOddsToWin.append(thisGame)
        
                        
                        self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.gamesByOddsToWin.count-1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                    }
                
                // Copy and sort here
                    
                    // how to sort http://stackoverflow.com/questions/24130026/swift-how-to-sort-array-of-custom-objects-by-property-value
                    // https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Closures.html
                  
        
                    //self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.gamesByOddsToWin.count-1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                    
                    self.gamesByOddsToWin.sortInPlace { $0.oddsToWin < $1.oddsToWin }
                
                }
                
                
            } else {
            
                print("no snapshot")
                return
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func sorterForOddsToWinASC(this:game, that:game) -> Bool {
        return this.oddsToWin > that.oddsToWin
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return gamesByOddsToWin.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellIdentifier = "GameCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! GameTableViewCell
        
        let gamesRow = gamesByOddsToWin[indexPath.row]
        
        
        cell.gameName.text = gamesRow.name
        cell.gameValue.text = String(gamesRow.oddsToWin)
        
        return cell
    }
    
    @IBAction func segmentedControlActionChanged(sender: UISegmentedControl) {
        
        tableView.reloadData()
        
    }
    
    
}
