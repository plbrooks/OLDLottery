//
//  SettingsViewController.swift
//  Lottery
//
//  Created by Peter Brooks on 9/25/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import UIKit
import CoreLocation

class SettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var tableView: UITableView!
   
    
    var pickerData = ("A")
    
    override func viewDidLoad() {
        
    super.viewDidLoad()
        //self.picker.dataSource = self
        //self.picker.delegate = self;
        //textField.delegate = self

    }

    // The number of columns of data
    
    func numberOfComponentsInPickerVIew(_: UIPickerView) -> Int {
        return 1
    }
    
    func numberOfComponents(in: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        //return pickerData.count
        return 3
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //return pickerData[row]
        return "A"
    }
    
    // Catpure the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
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
    
    
}
