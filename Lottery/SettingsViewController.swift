//
//  SettingsViewController.swift
//  Lottery
//
//  Created by Peter Brooks on 9/25/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import UIKit
import CoreLocation

class SettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //textField.delegate = self

    }

    
    
    func numberOfSections(in tableView: UITableView) -> Int {

        return 1
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return 2
        
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
    
    
}
