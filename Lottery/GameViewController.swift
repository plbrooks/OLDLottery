//
//  GameViewController.swift
//  Lottery
//
//  Created by Peter Brooks on 9/5/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

// TODO - swiftspinner, get rid of HandySwift


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

   //var refHandleCountries: FIRDatabaseHandle!
    
    var refHandleAddGames: FIRDatabaseHandle!
    var refHandleRemoveGames: FIRDatabaseHandle!
    var refHandleChangeGames: FIRDatabaseHandle!
    
    //var refHandleGameDetail: FIRDatabaseHandle!
    
    var storageRef: FIRStorageReference!
    //var remoteConfig: FIRRemoteConfig!
    
    class gameData {
        //var name                = ""
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
    
    class sortedByOddsToWin {
        var name                = ""
        var oddsToWin           = 0.0
            init (name: String, oddsToWin: Double) {
                self.name = name
                self.oddsToWin = oddsToWin
            }
    }
    
    class sortedByTopPrize {
        var name                = ""
        var topPrize           = 0
            init (name: String, topPrize: Int) {
                self.name = name
                self.topPrize = topPrize
            }
    }
    
    class sortedByPayout {
        var name                = ""
        var payout           = 0
            init (name: String, payout: Int) {
                self.name = name
                self.payout = payout
            }
    }
    
    var gamesByOddsToWin    : [sortedByOddsToWin] = []               // array of game classes sorted bg OddsToWin
    var gamesByTopPrize     : [sortedByTopPrize] = []               // array of game classes sorted by maximum prize
    var gamesByPayout       : [sortedByPayout] = []               // array of game classes sorted by maximum payout
    
    var gamesDetail         = [String: gameData]()               // unsorted array of games read in from Firebase
    
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
        
        ref = FIRDatabase.database().reference()
        //FIRDatabase.database().persistenceEnabled = true
        
        loadData()

        
        
    }

    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        segmentedControl.selectedSegmentIndex = getSegmentOptionFromUserDefaults()
        setTableHeader(segmentedControl)
        
        tableView.reloadData()
        print("data reloaded")

        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
    }
   
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let header = tableHeaderView {
            
            header.frame.size.height = 44.0
            
        }
    }
    
    // when called?
    deinit {
        
        self.ref.child(lotteryLocation["country"]!).removeObserverWithHandle(refHandleAddGames)
        self.ref.child(lotteryLocation["country"]!).removeObserverWithHandle(refHandleChangeGames)
        self.ref.child(lotteryLocation["country"]!).removeObserverWithHandle(refHandleRemoveGames)
        
    }
    
    func loadData() {  // first inititialization
       
        // Listen for new Country in the Firebase database
        
        let refKey = lotteryLocation["country"]! + "/" + lotteryLocation["division"]!

        refHandleAddGames = self.ref.child(refKey).observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
            
            //refHandleGames = self.ref.child(country).observeEventType(.Value, withBlock: { (snapshot) -> Void in
            
            if snapshot.exists() {
                
                let gameName = snapshot.key
                
                if snapshot.key == Constants.descrip {
                    
                    let game = snapshot.value! as! NSDictionary
                    self.lotteryLocation["abbrev"] = game["Abbrev"] as? String
                    self.lotteryLocation["currencyName"] = game["Currency Name"] as? String
                    self.lotteryLocation["currencySymbol"] = game["Currency Symbol"] as? String
                    
                } else {
                    
                    let thisGame = self.createGameObjectUsingSnapshot(snapshot)
                    
                    // Add game to details and update games arrays
                    self.gamesDetail[gameName] = thisGame
                    self.addGameSortedByOddsToWin(thisGame, gameName: gameName, tableView: self.tableView, segmentIndex: self.segmentedControl.selectedSegmentIndex)
                    self.addGameSortedByTopPrize(thisGame, gameName: gameName, tableView: self.tableView, segmentIndex: self.segmentedControl.selectedSegmentIndex)
                    self.addGameSortedByPayout(thisGame, gameName: gameName, tableView: self.tableView, segmentIndex: self.segmentedControl.selectedSegmentIndex)
                    
                }
                
            } else {
                
                print("no snapshot")
                return
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
        refHandleChangeGames = self.ref.child(refKey).observeEventType(.ChildChanged, withBlock: { (snapshot) -> Void in
            
            if snapshot.exists() {
                
                let gameName = snapshot.key
    
                if snapshot.key == Constants.descrip {
                    
                    let game = snapshot.value! as! NSDictionary
                    self.lotteryLocation["abbrev"] = game["Abbrev"] as? String
                    self.lotteryLocation["currencyName"] = game["Currency Name"] as? String
                    self.lotteryLocation["currencySymbol"] = game["Currency Symbol"] as? String
                    
                } else {
                    
                    let thisGame = self.createGameObjectUsingSnapshot(snapshot)
                
                    // Add game to details and update games arrays
                    self.gamesDetail[gameName] = thisGame
                    
                    self.changeGameSortedByOddsToWin(thisGame, gameName: gameName, tableView: self.tableView, segmentIndex: self.segmentedControl.selectedSegmentIndex)
                    self.changeGameSortedByTopPrize(thisGame, gameName: gameName, tableView: self.tableView, segmentIndex: self.segmentedControl.selectedSegmentIndex)
                    self.changeGameSortedByPayout(thisGame, gameName: gameName, tableView: self.tableView, segmentIndex: self.segmentedControl.selectedSegmentIndex)
                    
                }
                
            } else {
                
                print("no snapshot")
                return
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    
        refHandleChangeGames = self.ref.child(refKey).observeEventType(.ChildRemoved, withBlock: { (snapshot) -> Void in
            
            if snapshot.exists() {
                
                let gameName = snapshot.key
                
                if snapshot.key == Constants.descrip {
                    
                    let game = snapshot.value! as! NSDictionary
                    self.lotteryLocation["abbrev"] = game["Abbrev"] as? String
                    self.lotteryLocation["currencyName"] = game["Currency Name"] as? String
                    self.lotteryLocation["currencySymbol"] = game["Currency Symbol"] as? String
                    
                } else {
                    
                    let thisGame = self.createGameObjectUsingSnapshot(snapshot)
                    
                    // Add game to details and update games arrays
                    self.gamesDetail[gameName] = thisGame
                    
                    self.removeGameSortedByOddsToWin(thisGame, gameName: gameName, tableView: self.tableView, segmentIndex: self.segmentedControl.selectedSegmentIndex)
                    self.removeGameSortedByTopPrize(thisGame, gameName: gameName, tableView: self.tableView, segmentIndex: self.segmentedControl.selectedSegmentIndex)
                    self.removeGameSortedByPayout(thisGame, gameName: gameName, tableView: self.tableView, segmentIndex: self.segmentedControl.selectedSegmentIndex)
                    
                }
                
            } else {
                
                print("no snapshot")
                return
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
    }
   

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
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
            cell.gameValue.text = String(gamesRow.payout)
            
            break
            
        default:
            break
            
        }
        
        return cell
    }
    
    @IBAction func segmentedControlActionChanged(sender: UISegmentedControl) {
        
        setTableHeader(segmentedControl)
        tableView.reloadData()
        saveSegmentOptionToUserDefaults(segmentedControl)
    
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
    
    func setTableHeader(segmentOption: UISegmentedControl) {
        
        switch(segmentOption.selectedSegmentIndex)
        {
        case segmentOptionIs.oddsToWin:
            
            sortedColumnHeader.text = sortedColumnHeaderText.oddsToWin
            break
            
        case segmentOptionIs.payout:
            
            sortedColumnHeader.text = sortedColumnHeaderText.payout
            break
            
        case segmentOptionIs.topPrize:
            
            sortedColumnHeader.text = sortedColumnHeaderText.topPrize
            break
            
        default:
            break
            
        }
    
    }
    
    func saveSegmentOptionToUserDefaults(segmentedControl: UISegmentedControl) {
    
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(segmentedControl.selectedSegmentIndex, forKey: "SegmentValue")
    }
    
    func getSegmentOptionFromUserDefaults() -> Int {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.integerForKey("SegmentValue")
    }
    
    func priceFromInt(num: Int) -> String {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        formatter.positiveFormat = "$#,##0"
        formatter.zeroSymbol = ""
        // formatter.locale = NSLocale.currentLocale()  // This is the default
        return(formatter.stringFromNumber(num)!)        // "$123.44"
    }

    func addGameSortedByOddsToWin (thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        
        let thisOddsToWin = sortedByOddsToWin(name:gameName,oddsToWin:thisGame.oddsToWin)
        
        var rowNumber = 0
        
        // if the new Odds to win > any in the existing array
        
        if gamesByOddsToWin.isEmpty || (thisGame.oddsToWin >= gamesByOddsToWin.last?.oddsToWin) {
            
            gamesByOddsToWin.append(thisOddsToWin)
            rowNumber = self.gamesByOddsToWin.count-1
            
        } else {
            
            let indexOfFirstGreaterValue = gamesByOddsToWin.indexOf({$0.oddsToWin > thisGame.oddsToWin })
            gamesByOddsToWin.insert(thisOddsToWin, atIndex: indexOfFirstGreaterValue!)
            rowNumber = indexOfFirstGreaterValue!
            
        }
        
        if segmentIndex == segmentOptionIs.oddsToWin {
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: rowNumber, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    func addGameSortedByTopPrize (thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        
        let thisTopPrize = sortedByTopPrize(name: gameName, topPrize: thisGame.topPrize)
        var rowNumber = 0
        
        // if the new prize > any in the existing array
        if  gamesByTopPrize.isEmpty || (thisGame.topPrize <= gamesByTopPrize.last?.topPrize) {
            gamesByTopPrize.append(thisTopPrize)
            rowNumber = self.gamesByTopPrize.count-1
        } else {
            
            let indexOfFirstLowerValue = gamesByTopPrize.indexOf({$0.topPrize < thisGame.topPrize })
            gamesByTopPrize.insert(thisTopPrize, atIndex: indexOfFirstLowerValue!)
            rowNumber = indexOfFirstLowerValue!
            
        }
        if segmentIndex == segmentOptionIs.topPrize {
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: rowNumber, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }

    func addGameSortedByPayout (thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        
        let thisPayout = sortedByPayout(name: gameName, payout: thisGame.totalWinnings)
        
        var rowNumber = 0
        
        // if the new prize > any in the existing array
        
        if gamesByPayout.isEmpty || (thisGame.totalWinnings <= gamesByPayout.last?.payout) {
            gamesByPayout.append(thisPayout)
            rowNumber = self.gamesByPayout.count-1
        } else {
            
            let indexOfFirstLowerValue = gamesByTopPrize.indexOf({$0.topPrize < thisGame.topPrize })
            gamesByPayout.insert(thisPayout, atIndex: indexOfFirstLowerValue!)
            rowNumber = indexOfFirstLowerValue!
            
        }
        
        if segmentIndex == segmentOptionIs.payout {
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: rowNumber, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }

    func changeGameSortedByOddsToWin (thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        
        let currentIndex = gamesByOddsToWin.indexOf({$0.name == gameName})                  // find index of current row
        let newIndex = gamesByOddsToWin.indexOf({$0.oddsToWin >= thisGame.oddsToWin})   // find index of new row
        
        let newRow =  sortedByOddsToWin(name:gameName, oddsToWin: thisGame.oddsToWin)
        
        gamesByOddsToWin.removeAtIndex(currentIndex!)
        if segmentIndex == segmentOptionIs.oddsToWin {
            self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: currentIndex!, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        
        gamesByOddsToWin.insert(newRow, atIndex: newIndex!)
        if segmentIndex == segmentOptionIs.oddsToWin {
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: newIndex!, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        
    }
    
    func changeGameSortedByTopPrize (thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        
        let currentIndex = gamesByTopPrize.indexOf({$0.name == gameName})                  // find index of current row
        let newIndex = gamesByTopPrize.indexOf({$0.topPrize <= thisGame.topPrize})   // find index of new row
        
        let newRow =  sortedByTopPrize(name:gameName, topPrize:  thisGame.topPrize)
        
        gamesByTopPrize.removeAtIndex(currentIndex!)
        if segmentIndex == segmentOptionIs.topPrize {
            self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: currentIndex!, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        
        gamesByTopPrize.insert(newRow, atIndex: newIndex!)
        if segmentIndex == segmentOptionIs.topPrize {
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: newIndex!, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
        }

    }
    
    func changeGameSortedByPayout (thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        
        let currentIndex = gamesByPayout.indexOf({$0.name == gameName})                  // find index of current row
        let newIndex = gamesByPayout.indexOf({$0.payout <= thisGame.totalWinnings})   // find index of new row
        
        let newRow =  sortedByPayout(name:gameName, payout:  thisGame.totalWinnings)
        
        gamesByPayout.removeAtIndex(currentIndex!)
        if segmentIndex == segmentOptionIs.payout {
            self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: currentIndex!, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        
        gamesByPayout.insert(newRow, atIndex: newIndex!)
        if segmentIndex == segmentOptionIs.payout {
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: newIndex!, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
        }

       
    }

    func removeGameSortedByOddsToWin (thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        
        let rowNumber = gamesByOddsToWin.indexOf({$0.name == gameName})
        gamesByOddsToWin.removeAtIndex(rowNumber!)
        
        if segmentIndex == segmentOptionIs.oddsToWin {
            self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: rowNumber!, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        
    }

    func removeGameSortedByTopPrize (thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        let rowNumber = gamesByTopPrize.indexOf({$0.name == gameName})
        gamesByTopPrize.removeAtIndex(rowNumber!)
        
        if segmentIndex == segmentOptionIs.topPrize {
            self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: rowNumber!, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    func removeGameSortedByPayout (thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        let rowNumber = gamesByPayout.indexOf({$0.name == gameName})
        gamesByPayout.removeAtIndex(rowNumber!)
        
        if segmentIndex == segmentOptionIs.payout {
            self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: rowNumber!, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        
    }
    
    func createGameObjectUsingSnapshot(snapshot: FIRDataSnapshot) -> gameData {
        
        // Note: Need to downcast all JSON fields. "Segemention fault: 11" error means mismatch between var definition and JSON definition
        // Numbers with no decimal point in the dict are NSNumbers, with "" are Strings, and with decimal point are Doubles
        
        let game = snapshot.value! as! NSDictionary
        let thisGame = gameData()
        thisGame.wager = Int(game["Wager"] as! NSNumber)
        thisGame.topPrize = Int(game["Top Prize"] as! NSNumber)
        thisGame.oddsToWin = game["Odds To Win"] as! Double
        thisGame.totalWinners = Int(game["Total Winners"] as! NSNumber)
        thisGame.totalWinnings = Int(game["Total Winnings"] as! NSNumber)
        thisGame.oddsToWinTopPrize = Int(game["Odds To Win Top Prize"] as! NSNumber)
        thisGame.topPrizeDetails = game["Top Prize Details"] as! String
        thisGame.gameType = game["Type"] as! String
        thisGame.updateDate = game["Updated"] as! String
        return thisGame
    }
    
    
    
}
