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
    @IBOutlet weak var sortedColumnHeader: UILabel!

    struct sortedColumnHeaderText {
        static let oddsToWin = "Odds to Win 1:"
        static let topPrize = "Top Prize"
        static let payout = "Total Payout"
    }
    
    struct segmentOptionIs {
        static let oddsToWin = 0
        static let payout = 1
        static let topPrize = 2
        
    }
    
    var ref: FIRDatabaseReference!

    var refHandleCountries: FIRDatabaseHandle!
    var refHandleGames: FIRDatabaseHandle!
    var refHandleGameDetail: FIRDatabaseHandle!
    
    var storageRef: FIRStorageReference!
    //var remoteConfig: FIRRemoteConfig!
    
    class game {
        var name                = ""
        var wager               = 0
        var topPrize            = 0
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
    var gamesByTopPrize     : [game] = []               // array of game classes sorted by maximum prize
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
       
        // Listen for new Country in the Firebase database
        
        ref = FIRDatabase.database().reference()
        let refKey = lotteryLocation["country"]! + "/" + lotteryLocation["division"]!
        refHandleGames = self.ref.child(refKey).observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
            
        //refHandleGames = self.ref.child(country).observeEventType(.Value, withBlock: { (snapshot) -> Void in
            
            if snapshot.exists() {
                
                let gameInfo = snapshot.value! as! NSDictionary

                print("snapshot key = \(snapshot.key)")
                print("gameInfo = \(gameInfo)")
                
                if snapshot.key == Constants.descrip {
                    
                    self.lotteryLocation["abbrev"] = gameInfo["Abbrev"] as? String
                    self.lotteryLocation["currencyName"] = gameInfo["Currency Name"] as? String
                    self.lotteryLocation["currencySymbol"] = gameInfo["Currency Symbol"] as? String
                    
                } else {
        
                        // Note: Need to downcast all JSON fields. "Segemention fault: 11" error means mismatch between var definition and JSON
                        // Numbers with no decimal point in the dict are NSNumbers, with "" are Strings,s and with decimal point are Doubles

                        
                        let thisGame = game()
                        thisGame.name = self.formatName(snapshot.key)!
                        thisGame.wager = Int(gameInfo["Wager"] as! NSNumber)
                        thisGame.topPrize = Int(gameInfo["Top Prize"] as! NSNumber)
                        thisGame.oddsToWin = gameInfo["Odds To Win"] as! Double
                        thisGame.totalWinners = Int(gameInfo["Total Winners"] as! NSNumber)
                        thisGame.totalWinnings = Int(gameInfo["Total Winnings"] as! NSNumber)
                        thisGame.oddsToWinTopPrize = Int(gameInfo["Odds To Win Top Prize"] as! NSNumber)
                        thisGame.topPrizeDetails = gameInfo["Top Prize Details"] as! String
                        thisGame.gameType = gameInfo["Type"] as! String
                        thisGame.updateDate = gameInfo["Updated"] as! String
                        self.gamesByOddsToWin.append(thisGame)
                        
                        self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.gamesByOddsToWin.count-1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                        
                    //}
                }

                // Copy and sort here
                    
                // how to sort http://stackoverflow.com/questions/24130026/swift-how-to-sort-array-of-custom-objects-by-property-value
                // https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Closures.html
              
    
                //self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.gamesByOddsToWin.count-1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                    
                
                
            } else {
            
                print("no snapshot")
                return
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var returnValue = 0
        
        switch(segmentedControl.selectedSegmentIndex)
        {
        case segmentOptionIs.oddsToWin:
            returnValue = gamesByOddsToWin.count
            break
        case segmentOptionIs.payout:
            returnValue = gamesByPayout.count
            break
            
        case segmentOptionIs.topPrize:
            returnValue = gamesByTopPrize.count
            break
            
        default:
            break
            
        }
        
        return returnValue
        
        //return gamesByOddsToWin.count
        
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellIdentifier = "GameCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! GameTableViewCell
        
        switch(segmentedControl.selectedSegmentIndex)
        {
        case segmentOptionIs.oddsToWin:
            
            let gamesRow = gamesByOddsToWin[indexPath.row]
            cell.gameName.text = gamesRow.name
            cell.gameValue.text = String(gamesRow.oddsToWin)
            
            break
        case segmentOptionIs.topPrize:
            let gamesRow = gamesByTopPrize[indexPath.row]
            cell.gameName.text = gamesRow.name
            if (gamesRow.topPrize == 0) {
                cell.gameValue.text = "varies"
            } else {
                cell.gameValue.text = priceFromInt(gamesRow.topPrize)
            }
            break
            
        case segmentOptionIs.payout:
            
            let gamesRow = gamesByPayout[indexPath.row]
            cell.gameName.text = gamesRow.name
            cell.gameValue.text = String(gamesRow.totalWinnings)
            
            break
            
        default:
            break
            
        }
        
        return cell
    }
    
    @IBAction func segmentedControlActionChanged(sender: UISegmentedControl) {
        
        switch(segmentedControl.selectedSegmentIndex)
        {
        case segmentOptionIs.oddsToWin:
            
            sortedColumnHeader.text = sortedColumnHeaderText.oddsToWin
            // no need to sort, already sorted
            break
            
        case segmentOptionIs.payout:
            
            sortedColumnHeader.text = sortedColumnHeaderText.payout
            self.gamesByPayout = self.gamesByOddsToWin.sort { $0.totalWinnings > $1.totalWinnings }
            break
            
        case segmentOptionIs.topPrize:
            
            sortedColumnHeader.text = sortedColumnHeaderText.topPrize
            self.gamesByTopPrize = self.gamesByOddsToWin.sort { $0.topPrize > $1.topPrize }
            break
            
        default:
            break
            
        }
        tableView.reloadData()
        
        
    }
    
    func formatName(oldName: String) -> String? {
        
        var newName = oldName
        if !(oldName.isEmpty) {
            let range = newName.startIndex..<newName.startIndex.advancedBy(4)
            newName.removeRange(range)
            newName = newName.stringByReplacingOccurrencesOfString("@", withString: "$")
        
        }
        
        return(newName)
        
    }
    
    func priceFromInt(num: Int) -> String {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        formatter.positiveFormat = "$#,##0"
        formatter.zeroSymbol = ""
        // formatter.locale = NSLocale.currentLocale() // This is the default
        return(formatter.stringFromNumber(num)!) // "$123.44"
    }

    
}
