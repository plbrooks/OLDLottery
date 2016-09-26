//
//  SettingsViewController.swift
//  Lottery
//
//  Created by Peter Brooks on 9/25/16.
//  Copyright © 2016 Peter Brooks. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

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
            
            cell = tableView.dequeueReusableCell(withIdentifier: "LocationTableViewCell", for: indexPath) as! LocationTableViewCell

        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "NameTableViewCell", for: indexPath) as! NameTableViewCell
            (cell as! NameTableViewCell).userName.text = "hi ho"
                       //cell.configure(text: "", placeholder: "Enter some text!")
            
        default:    // should never happen
            cell = tableView.dequeueReusableCell(withIdentifier: "", for: indexPath)
        }
        
        return cell
    }
    
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        /*let cell = tableView(tableView, cellForRowAt: indexPath)
        
        
        if cell.isKindOfClass(NameTableViewCell) {
            print("name cell print")
        }*/
    
    
    }


}
