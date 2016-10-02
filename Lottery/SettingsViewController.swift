//
//  SettingsViewController.swift
//  Lottery
//
//  Created by Peter Brooks on 9/25/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
//import FirebaseDatabaseUI

class SettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var tableView: UITableView!
   
    var ref: FIRDatabaseReference!
    var refHandleGetLocations: FIRDatabaseHandle!
    //var dataSource: FirebaseTableViewDataSource!
    
    var locationDict = [String: [String]]()
    
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
        ref.removeObserver(withHandle: refHandleGetLocations)
        
    }
    
    func loadDataFromFirebase() {  // first inititialization
        
        // Listen for new Country in the Firebase database
        
        let refKey = "LOCATIONS"
        
        refHandleGetLocations = self.ref.child(refKey).observe(.childAdded, with: { (snapshot) -> Void in
            
            if snapshot.exists() {
                
                let key = snapshot.key
                
                let data = snapshot.value as! NSDictionary
                let dataAsString = data as! [String: Any]
    
                if (dataAsString.count == 1) && (dataAsString.index(forKey: "NONE") != nil) {
                    self.locationDict[key] = []
                } else {
                    self.locationDict[key] = data.allKeys as? [String]
                }
                
                let path = IndexPath(row: 1, section: 0)
                self.tableView.reloadRows(at: [path], with: UITableViewRowAnimation.top)
                
            } else {
                
                print("no snapshot")
                return
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
    }
    
    
    // The number of columns of data
    
    func numberOfComponents(in: UIPickerView) -> Int {
        return 2
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        var numberOfRows = 0
        
        switch component {
        case 0:
            numberOfRows = locationDict.count                               // count = # of countries
        case 1:
            if locationDict.count > 0 {                                     // there is a country
                
                let countryRow = pickerView.selectedRow(inComponent: 0)     // # of selected Country row
                let countryName = countryNameOfRow(countryRow, usingLocationDict: locationDict)    // name of selected country
                let divisions = locationDict[countryName]                          // list of divisions for the country
                numberOfRows = (divisions?.count)!                          // count of the divisions if any

            }
        default:
            break
    
        }
        return numberOfRows
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        var rowTitle = ""
        
        
        if locationDict.count > 0 {             // there is a country
            
            switch component {
            case 0:
                let sortedCountries = Array(locationDict.keys).sorted(by: <)
                rowTitle = sortedCountries[row]
                break
            case 1:
                
                let selectedCountryRow = pickerView.selectedRow(inComponent: 0)
                let countryName = countryNameOfRow(selectedCountryRow, usingLocationDict: locationDict)
                if Array(locationDict[countryName]!).count > 0 {        // there are divisions assoc. with the country
                    
                    let sortedDivisions = Array(locationDict[countryName]!).sorted(by: <)
                    rowTitle = sortedDivisions[row]
                    
                }
            default:
                break
                
            }
        }
        return rowTitle
    }
    
    // Catpure the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            pickerView.reloadComponent(1)
            break
        case 1:
            break
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        var height:CGFloat = 44 // Default
        
        if indexPath.row == 1 {
            height = 126
        }
        
        return height
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {

        return 1
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return 3
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell
        switch indexPath.row{
        case 0:
            
            cell = tableView.dequeueReusableCell(withIdentifier: K.locationCellName, for: indexPath) as! LocationTableViewCell
            if let currentPlacemark = SharedServices.sharedInstance.getValueFromUserDefaultsFor(key: K.locationKey) as? CLPlacemark {
                let country = currentPlacemark.country
                var separator = ", "
                let division = currentPlacemark.administrativeArea
                if division == nil { separator = ""}
                (cell as! LocationTableViewCell).currentLocation.text = division! + separator + country!
            }
            else {
                (cell as! LocationTableViewCell).currentLocation.text = K.defaultLocationTextInCell
            }

        case 1:
            
            cell = tableView.dequeueReusableCell(withIdentifier: K.pickerCellName, for: indexPath) as! PickerTableViewCell
            //let savedName = SharedServices.sharedInstance.getValueFromUserDefaultsFor(key: K.userNameKey) as? String
            //(cell as! PickerTableViewCell).leftPicker.
            //cell.textLabel?.text = "HIHO"
            (cell as! PickerTableViewCell).leftPicker.reloadAllComponents()


        case 2:
            
            cell = tableView.dequeueReusableCell(withIdentifier: K.userNameCellName, for: indexPath) as! NameTableViewCell
            let savedName = SharedServices.sharedInstance.getValueFromUserDefaultsFor(key: K.userNameKey) as? String
            (cell as! NameTableViewCell).userName.text = savedName
            
        default:    // should never happen
            cell = tableView.dequeueReusableCell(withIdentifier: "", for: indexPath)
        }
        
        return cell
    }
    
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        tableView.deselectRow(at: indexPath, animated: true)
    
        //let row =
        
        //if cell.isKindOfClass(NameTableViewCell) {
        //    print("name cell print")
        //}
    
    
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        SharedServices.sharedInstance.saveToUserDefaultsThe(value: textField.text, forKey: K.userNameKey)
    }
    

    /*func textFieldDidBeginEditing(_ textField: UITextField) {
        print("Text field did begin editting")
    }*/
    
    
    func countryNameOfRow(_ ofTitleRow: Int, usingLocationDict: [String: [String]] ) -> String {
        var name = ""
        
        if usingLocationDict.count > 0 {
            
            let sortedCountries = Array(usingLocationDict.keys).sorted(by: <)
            name = sortedCountries[ofTitleRow]     // selected Country
            
        }
        
        return name
    }
    
    
}
