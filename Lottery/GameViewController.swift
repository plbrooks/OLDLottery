//
//  GameViewController.swift
//  Lottery
//
//  Created by Peter Brooks on 9/5/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

// TODO - swiftspinner, get rid of HandySwift


import UIKit
import CoreLocation
import Firebase
import SwiftLocation

/*fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}*/


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
        
        if getLocationFromUserDefaults() == nil {
        
            var _ = Location.getLocation(withAccuracy: .city, frequency: .oneShot, timeout: 30, onSuccess: { (loc) in
            
                var _ = Location.reverse(coordinates: loc.coordinate, onSuccess: { foundPlacemark in
                    // foundPlacemark is a CLPlacemark object
                    self.saveLocationToUserDefaults(location: foundPlacemark)
                    
                }) { err in
                    print("err \(err)")
                }
            
            }) { (last, err) in
                print("err \(err)")
            }

        }
        
        tableView.delegate      = self
        tableView.dataSource    = self
        
        ref = FIRDatabase.database().reference()
        //FIRDatabase.database().persistenceEnabled = true
        
        loadData()

        
        
    }

    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        segmentedControl.selectedSegmentIndex = getSegmentOptionFromUserDefaults()!
        setTableHeader(segmentedControl)
        
        tableView.reloadData()
        print("data reloaded")

        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
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
        
        self.ref.child(lotteryLocation["country"]!).removeObserver(withHandle: refHandleAddGames)
        self.ref.child(lotteryLocation["country"]!).removeObserver(withHandle: refHandleChangeGames)
        self.ref.child(lotteryLocation["country"]!).removeObserver(withHandle: refHandleRemoveGames)
        
    }
    
    func loadData() {  // first inititialization
       
        // Listen for new Country in the Firebase database
        
        let refKey = lotteryLocation["country"]! + "/" + lotteryLocation["division"]!

        refHandleAddGames = self.ref.child(refKey).observe(.childAdded, with: { (snapshot) -> Void in
            
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
        
        refHandleChangeGames = self.ref.child(refKey).observe(.childChanged, with: { (snapshot) -> Void in
            
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
    
        refHandleChangeGames = self.ref.child(refKey).observe(.childRemoved, with: { (snapshot) -> Void in
            
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
   

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "GameCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! GameTableViewCell
        
        switch(segmentedControl.selectedSegmentIndex)
        {
        case segmentOptionIs.oddsToWin:
            
            let gamesRow = gamesByOddsToWin[(indexPath as NSIndexPath).row]
            cell.gameName.text = gamesRow.name
            cell.gameValue.text = String(gamesRow.oddsToWin)
            
            break
        case segmentOptionIs.topPrize:
            let gamesRow = gamesByTopPrize[(indexPath as NSIndexPath).row]
            cell.gameName.text = gamesRow.name
            if (gamesRow.topPrize == 0) {
                cell.gameValue.text = "varies"
            } else {
                cell.gameValue.text = priceFromInt(gamesRow.topPrize)
            }
            break
            
        case segmentOptionIs.payout:
            
            let gamesRow = gamesByPayout[(indexPath as NSIndexPath).row]
            cell.gameName.text = gamesRow.name
            cell.gameValue.text = String(gamesRow.payout)
            
            break
            
        default:
            break
            
        }
        
        return cell
    }
    
    @IBAction func segmentedControlActionChanged(_ sender: UISegmentedControl) {
        
        setTableHeader(segmentedControl)
        tableView.reloadData()
        saveSegmentOptionToUserDefaults(segmentedControl: segmentedControl)
    
    }
    
    func formatName(_ oldName: String) -> String? {
        
        var newName = oldName
        if !(oldName.isEmpty) {
            let range = newName.startIndex..<newName.characters.index(newName.startIndex, offsetBy: 4)
            newName.removeSubrange(range)
            newName = newName.replacingOccurrences(of: "@", with: "$")
        
        }
        
        return(newName)
        
    }
    
    func setTableHeader(_ segmentOption: UISegmentedControl) {
        
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
    
    // MARK: User Defaults

    
    func saveSegmentOptionToUserDefaults(segmentedControl: UISegmentedControl) {
        
        let defaults = UserDefaults.standard
        defaults.set(segmentedControl.selectedSegmentIndex, forKey: "SegmentValue")
    }
    
    func getSegmentOptionFromUserDefaults() -> Int? {
        let defaults = UserDefaults.standard
        return defaults.integer(forKey: "SegmentValue")
    }

    func saveLocationToUserDefaults(location: CLPlacemark) {
    
        let defaults = UserDefaults.standard
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: location)
        defaults.set(encodedData, forKey: "Location")
        //print("end of save location")
        //defaults.set(location, forKey: "Location")
    }
    
    func getLocationFromUserDefaults() -> CLPlacemark? {
        
        let defaults = UserDefaults.standard
        let location = defaults.object(forKey: "Location") as? NSData
        var decodedLocation: CLPlacemark?
        if location != nil {
            decodedLocation = NSKeyedUnarchiver.unarchiveObject(with: location as! Data) as! CLPlacemark?
        }
        //let defaults = UserDefaults.standard
        //return defaults.string(forKey: "Location")!
        //print("loc = \(decodedLocation?.administrativeArea)")
        return decodedLocation
    }
    
    
    // MARK: Add games
    
    func addGameSortedByOddsToWin (_ thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        
        let thisOddsToWin = sortedByOddsToWin(name:gameName,oddsToWin:thisGame.oddsToWin)
        
        var rowNumber = 0
        
        // if the new Odds to win > any in the existing array
        
        if gamesByOddsToWin.isEmpty || (thisGame.oddsToWin >= (gamesByOddsToWin.last?.oddsToWin)!) {
            
            gamesByOddsToWin.append(thisOddsToWin)
            rowNumber = self.gamesByOddsToWin.count-1
            
        } else {
            
            let indexOfFirstGreaterValue = gamesByOddsToWin.index(where: {$0.oddsToWin > thisGame.oddsToWin })
            gamesByOddsToWin.insert(thisOddsToWin, at: indexOfFirstGreaterValue!)
            rowNumber = indexOfFirstGreaterValue!
            
        }
        
        if segmentIndex == segmentOptionIs.oddsToWin {
            self.tableView.insertRows(at: [IndexPath(row: rowNumber, section: 0)], with: UITableViewRowAnimation.automatic)
        }
    }
    
    func addGameSortedByTopPrize (_ thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        
        let thisTopPrize = sortedByTopPrize(name: gameName, topPrize: thisGame.topPrize)
        var rowNumber = 0
        
        // if the new prize > any in the existing array
        if  gamesByTopPrize.isEmpty || (thisGame.topPrize <= (gamesByTopPrize.last?.topPrize)!) {
            gamesByTopPrize.append(thisTopPrize)
            rowNumber = self.gamesByTopPrize.count-1
        } else {
            
            let indexOfFirstLowerValue = gamesByTopPrize.index(where: {$0.topPrize < thisGame.topPrize })
            gamesByTopPrize.insert(thisTopPrize, at: indexOfFirstLowerValue!)
            rowNumber = indexOfFirstLowerValue!
            
        }
        if segmentIndex == segmentOptionIs.topPrize {
            self.tableView.insertRows(at: [IndexPath(row: rowNumber, section: 0)], with: UITableViewRowAnimation.automatic)
        }
    }

    func addGameSortedByPayout (_ thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        
        let thisPayout = sortedByPayout(name: gameName, payout: thisGame.totalWinnings)
        
        var rowNumber = 0
        
        // if the new prize > any in the existing array
        
        if gamesByPayout.isEmpty || (thisGame.totalWinnings <= (gamesByPayout.last?.payout)!) {
            gamesByPayout.append(thisPayout)
            rowNumber = self.gamesByPayout.count-1
        } else {
            
            let indexOfFirstLowerValue = gamesByTopPrize.index(where: {$0.topPrize < thisGame.topPrize })
            gamesByPayout.insert(thisPayout, at: indexOfFirstLowerValue!)
            rowNumber = indexOfFirstLowerValue!
            
        }
        
        if segmentIndex == segmentOptionIs.payout {
            self.tableView.insertRows(at: [IndexPath(row: rowNumber, section: 0)], with: UITableViewRowAnimation.automatic)
        }
    }

    // MARK: Change games
    
    func changeGameSortedByOddsToWin (_ thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        
        let currentIndex = gamesByOddsToWin.index(where: {$0.name == gameName})                  // find index of current row
        let newIndex = gamesByOddsToWin.index(where: {$0.oddsToWin >= thisGame.oddsToWin})   // find index of new row
        
        let newRow =  sortedByOddsToWin(name:gameName, oddsToWin: thisGame.oddsToWin)
        
        gamesByOddsToWin.remove(at: currentIndex!)
        if segmentIndex == segmentOptionIs.oddsToWin {
            self.tableView.deleteRows(at: [IndexPath(row: currentIndex!, section: 0)], with: UITableViewRowAnimation.automatic)
        }
        
        gamesByOddsToWin.insert(newRow, at: newIndex!)
        if segmentIndex == segmentOptionIs.oddsToWin {
            self.tableView.insertRows(at: [IndexPath(row: newIndex!, section: 0)], with: UITableViewRowAnimation.automatic)
        }
        
    }
    
    func changeGameSortedByTopPrize (_ thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        
        let currentIndex = gamesByTopPrize.index(where: {$0.name == gameName})                  // find index of current row
        let newIndex = gamesByTopPrize.index(where: {$0.topPrize <= thisGame.topPrize})   // find index of new row
        
        let newRow =  sortedByTopPrize(name:gameName, topPrize:  thisGame.topPrize)
        
        gamesByTopPrize.remove(at: currentIndex!)
        if segmentIndex == segmentOptionIs.topPrize {
            self.tableView.deleteRows(at: [IndexPath(row: currentIndex!, section: 0)], with: UITableViewRowAnimation.automatic)
        }
        
        gamesByTopPrize.insert(newRow, at: newIndex!)
        if segmentIndex == segmentOptionIs.topPrize {
            self.tableView.insertRows(at: [IndexPath(row: newIndex!, section: 0)], with: UITableViewRowAnimation.automatic)
        }

    }
    
    func changeGameSortedByPayout (_ thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        
        let currentIndex = gamesByPayout.index(where: {$0.name == gameName})                  // find index of current row
        let newIndex = gamesByPayout.index(where: {$0.payout <= thisGame.totalWinnings})   // find index of new row
        
        let newRow =  sortedByPayout(name:gameName, payout:  thisGame.totalWinnings)
        
        gamesByPayout.remove(at: currentIndex!)
        if segmentIndex == segmentOptionIs.payout {
            self.tableView.deleteRows(at: [IndexPath(row: currentIndex!, section: 0)], with: UITableViewRowAnimation.automatic)
        }
        
        gamesByPayout.insert(newRow, at: newIndex!)
        if segmentIndex == segmentOptionIs.payout {
            self.tableView.insertRows(at: [IndexPath(row: newIndex!, section: 0)], with: UITableViewRowAnimation.automatic)
        }

       
    }

    // MARK: Move games
    
    func removeGameSortedByOddsToWin (_ thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        
        let rowNumber = gamesByOddsToWin.index(where: {$0.name == gameName})
        gamesByOddsToWin.remove(at: rowNumber!)
        
        if segmentIndex == segmentOptionIs.oddsToWin {
            self.tableView.deleteRows(at: [IndexPath(row: rowNumber!, section: 0)], with: UITableViewRowAnimation.automatic)
        }
        
    }

    func removeGameSortedByTopPrize (_ thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        let rowNumber = gamesByTopPrize.index(where: {$0.name == gameName})
        gamesByTopPrize.remove(at: rowNumber!)
        
        if segmentIndex == segmentOptionIs.topPrize {
            self.tableView.deleteRows(at: [IndexPath(row: rowNumber!, section: 0)], with: UITableViewRowAnimation.automatic)
        }
    }
    
    func removeGameSortedByPayout (_ thisGame: gameData, gameName: String, tableView: UITableView, segmentIndex: Int) {
        let rowNumber = gamesByPayout.index(where: {$0.name == gameName})
        gamesByPayout.remove(at: rowNumber!)
        
        if segmentIndex == segmentOptionIs.payout {
            self.tableView.deleteRows(at: [IndexPath(row: rowNumber!, section: 0)], with: UITableViewRowAnimation.automatic)
        }
        
    }
    
    // MARK: Create game
    
    func createGameObjectUsingSnapshot(_ snapshot: FIRDataSnapshot) -> gameData {
        
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
    
    // MARK: Convenience funcs
    
    func priceFromInt(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.positiveFormat = "$#,##0"
        formatter.zeroSymbol = ""
        // formatter.locale = NSLocale.currentLocale()  // This is the default
        return(formatter.string(from: NSNumber(value: num)))!       // "$123.44"
    }
    
}
