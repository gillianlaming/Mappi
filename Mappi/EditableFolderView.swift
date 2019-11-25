//
//  EditableFolderView.swift
//  Mappi
//
//  Created by Gillian Dibbs Laming on 11/4/19.
//  Copyright © 2019 cse438. All rights reserved.
//

import UIKit

class EditableFolderView: UIViewController, UITableViewDataSource, UITableViewDelegate {
   
    @IBOutlet weak var placesTable: UITableView!
    @IBOutlet weak var nameOfFolderLabel: UILabel!
    var folderName = ""
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getPlaces().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let myCell = placesTable.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath) as! FolderTableViewCell
        var places = getPlaces()
        myCell.colorLabel.backgroundColor = UIColor.green
        print(places)
        myCell.placeTitleLabel.text = places[indexPath.item][0]!
        myCell.placeDescriptionText.text = places[indexPath.item][1]!

        return myCell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 156
    }
    
    func updateValues(){
        nameOfFolderLabel.text = folderName
    }
    
    @IBOutlet weak var folderView: UITableView!
     var myArray = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        folderView.dataSource = self
        folderView.delegate = self
        folderView.register(UITableViewCell.self, forCellReuseIdentifier: "theCell")
        updateValues()
        self.folderView.reloadData()
    }
    
    func getPlaces() -> [[String?]]{
        var places = [[String?]]()
        let thepath = Bundle.main.path(forResource: "mappi", ofType: "db")
        let DB = FMDatabase(path: thepath)
        
        var folderID = 0
        if !(DB.open()) {
            print("Unable to open database")
        } else {
            do{
                let folderResults = try DB.executeQuery("select * from folders where name=?", values:[folderName])
                while(folderResults.next()){
                    folderID = Int(folderResults.int(forColumn: "folderID"))
                }
                let results = try DB.executeQuery("select * from places where folderID=?", values:[folderID])
                while(results.next()) {
                    let placeName = results.string(forColumn: "locationName")
                    let desc = results.string(forColumn: "description")
                    let city = results.string(forColumn: "city")
                    let state = results.string(forColumn: "state")
                    let arr = [placeName, desc, city, state]
                    places.append(arr)
                }
            }
            catch let error as NSError {
                print("failed \(error)")
                
            }
        }
        return places
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            print(myArray[indexPath.row])
            
            let thepath = Bundle.main.path(forResource: "mappi", ofType: "db")
            let folderDB = FMDatabase(path: thepath)
            
            if !(folderDB.open()) {
                print("Unable to open database")
                return
            } else {
                do{
                    let query = "delete from folders where name=?"
                    try folderDB.executeUpdate(query, values: [myArray[indexPath.row]])
                    myArray.remove(at: indexPath.row)
                    let ac = UIAlertController(title: "Item deleted", message: "" , preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title:"Return", style: .default, handler:nil))
                    present(ac, animated:true, completion:nil)
                    
                    
                } catch let error as NSError {
                    print("error!")
                    print("failed \(error)")
                }
            }
            
            tableView.reloadData()
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
