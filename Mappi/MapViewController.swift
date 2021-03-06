//
//  MapViewController.swift
//  Mappi
//
//  Created by Gillian Dibbs Laming on 11/4/19.
//  Copyright © 2019 cse438. All rights reserved.
//

//test commit from jane 12/1
//test commit from caleb

import UIKit
import MapKit


protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

protocol MenuControllerDelegate {
    
    func passID(forID id: Int?)
}

class MapViewController: UIViewController, MKMapViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    
    let locationManager = CLLocationManager()
    var resultSearchController:UISearchController? = nil
    
    var selectedPin:MKPlacemark? = nil
    let btnAdd = UIButton(type: .contactAdd)
    
    @IBOutlet weak var mapView: MKMapView!
    
    var places:[[place]] = []
    
    var currentPin:MKPointAnnotation?
    
    //span
    var avgCoord:CLLocationCoordinate2D?
    var spanLat:CLLocationDegrees?
    var spanLong:CLLocationDegrees?
    var maxSpan:CLLocationDegrees?
    
    //picker
    var toolBar = UIToolbar()
    var picker  = UIPickerView()
    var pickerFolder:String?
    
    var currentID: Int? = nil
    
    override func viewDidLoad() {
        //will need to go into this and run some stuff in the background probably
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        let searchResultsTable = storyboard!.instantiateViewController(withIdentifier: "SearchResultsTable") as! SearchResultsTable
        resultSearchController = UISearchController(searchResultsController: searchResultsTable)
        resultSearchController?.searchResultsUpdater = searchResultsTable
        
        //search controller
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        searchResultsTable.mapView = mapView
        
        searchResultsTable.handleMapSearchDelegate = self
 
        configureNavBar()
    }
    
    var delegate: MapControllerDelegate?
    
    @objc func handleMenuToggle(){
        delegate?.handleMenuToggle(forID: nil)
    }
    
    
    func configureNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "folder"), style: .plain, target: self, action: #selector(callPickerViewFolderView))
    }
    
    func getPins() {
        //FINAL DB TODO: replace code in here with the pull from the db, basically needs to do exactly the same thing as these hardcoded values. not sure if folderID system here fits w/ the database but even if it doesn't, make sure

        // grab from db all folderID with owner = myID or sharedUserID = myID
        let folderList = loadAllFolders()
        if folderList.count > 0{
            // for each folder id, grab all places and append to places[folderID]
            for folderID in folderList{
                print("getting places in folder \(folderID)")
                let placesInFolder = getPlaces(folderID : folderID)
                places.append(placesInFolder)
//                print("done with places in \(folderID)")
            }
        } else {
            print("couldn't get list of folderIDs")
        }
    }
    
    // create place objects from db data
    func getPlaces(folderID : Int) -> [place]{
        var places : [place] = []
        let thepath = Bundle.main.path(forResource: "mappi", ofType: "db")
        let DB = FMDatabase(path: thepath)
        
        if !(DB.open()) {
            print("Unable to open database")
        } else {
            do{
                let results = try DB.executeQuery("select * from places where folderID=?", values:[folderID])
                
                while(results.next()) {
                    let xcoord = Double(results.string(forColumn: "xcoord") ?? "0.0")
                    let ycoord = Double(results.string(forColumn: "ycoord") ?? "0.0")
                    let ln = results.string(forColumn: "locationName") ?? ""
                    let c = results.string(forColumn: "city") ?? ""
                    let s = results.string(forColumn: "state") ?? ""
                    let thisPlace = place(locationName: ln, lat: xcoord!, long: ycoord!, city: c, state: s, folderID: folderID)
//                    print("added \(thisPlace.locationName)")
                    places.append(thisPlace)
                }
                
                return places
            }
            catch let error as NSError {
                print("failed \(error)")
            }
        }
        defineSpan(folder: places)
        return places
    }
    
    func loadAllFolders() -> [Int]{
        let thepath = Bundle.main.path(forResource: "mappi", ofType: "db")
        let folderDB = FMDatabase(path: thepath)
        var folderIDs : [Int] = []
        
        if !(folderDB.open()) {
            print("Unable to open database")
        } else {
            do{
                let myID = UserDefaults.standard.integer(forKey: "id")
                let results = try folderDB.executeQuery("select * from folders where owner=?", values:[myID])
                
                while(results.next()) {
                    let folderID = Int(results.int(forColumn: "folderID"))
                    folderIDs.append(folderID)
                }
                
                let results2 = try folderDB.executeQuery("select * from sharedFolders where sharedUserID=?", values:[myID])
                while(results2.next()) {
                    let folderID = Int(results2.int(forColumn: "folderID"))
                    folderIDs.append(folderID)
                }
                return folderIDs
            }
            catch let error as NSError {
                print("failed \(error)")
            }
        }
        return folderIDs
    }
    
    func defineSpan(folder:[place]) {
        var lats = [Double]()
        var longs = [Double]()
        var difsLats = [Double]()
        var difsLongs = [Double]()
        
        for place in folder {
            lats.append(place.lat)
            longs.append(place.long)
        }
        
        let sumLats = lats.reduce(0,+)
        let avgLats = sumLats/Double(lats.count)
        
        let sumLongs = longs.reduce(0,+)
        let avgLongs = sumLongs/Double(longs.count)
        
        avgCoord = CLLocationCoordinate2D(latitude: CLLocationDegrees(avgLats), longitude: CLLocationDegrees(avgLongs))
       
        for lat in lats {
            difsLats.append(abs(avgLats-lat))
            print(abs(avgLats-lat))
        }
        for long in longs {
            difsLongs.append(abs(avgLongs-long))
            print(abs(avgLongs-long))
        }
        
        // THIS RESETS VALUES TO 0.0 ??
        spanLat = difsLats.max()
       // print("latitude = \(String(describing: spanLat))")
        spanLong = difsLongs.max()
      //  print("longitude = \(String(describing: spanLong))")
        
        if (spanLat ?? 0) > (spanLong ?? 0) {
            maxSpan = spanLat
        }
        else {
            maxSpan = spanLong
        }
        
    }
    
    
    //desc: modifies appearance of pins
    //more editing on creating the pin, all other pin content should be put in here i think
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }
        print ("dropping pins 1")
        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView!.canShowCallout = true
        } else {
            annotationView!.annotation = annotation
        }
        
        //adds button to annotation view
        annotationView?.rightCalloutAccessoryView = btnAdd
        btnAdd.addTarget(self, action: #selector(clickBtnAdd), for: .touchUpInside)
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let selectedAnn = view.annotation
        {
            currentPin = selectedAnn as? MKPointAnnotation
            print("User tapped on annotation with title: \(String(describing: selectedAnn.title))")
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        toolBar.removeFromSuperview()
        picker.removeFromSuperview()
    }
    
    func callPickerView() {
        picker = UIPickerView.init()
        self.picker.delegate = self as UIPickerViewDelegate
        self.picker.dataSource = self as UIPickerViewDataSource
        picker.backgroundColor = UIColor.white
        picker.setValue(UIColor.black, forKey: "textColor")
        picker.autoresizingMask = .flexibleWidth
        picker.contentMode = .center
        picker.frame = CGRect.init(x: 0.0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 300)
        
        self.view.addSubview(picker)
        
        toolBar = UIToolbar.init(frame: CGRect.init(x: 0.0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 50))
        toolBar.barStyle = .default
        toolBar.items = [UIBarButtonItem.init(title: "Done", style: .done, target: self, action: #selector(onDoneButtonTapped)),UIBarButtonItem.init(title: "New Folder", style: .plain, target: self, action: #selector(onNewFolderTapped)),UIBarButtonItem.init(title: "Add", style: .plain, target: self, action: #selector(onAddButtonTapped))]
        self.view.addSubview(toolBar)
    }
    
    @objc func callPickerViewFolderView() {
        print(self.view.subviews.count)
        let count = self.view.subviews.count
        if count == 1 {
            picker = UIPickerView.init()
            self.picker.delegate = self as UIPickerViewDelegate
            self.picker.dataSource = self as UIPickerViewDataSource
            picker.backgroundColor = UIColor.white
            picker.setValue(UIColor.black, forKey: "textColor")
            picker.autoresizingMask = .flexibleWidth
            picker.contentMode = .center
            picker.frame = CGRect.init(x: 0.0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 300)
            
            self.view.addSubview(picker)
            print(self.view.subviews.count)
            toolBar = UIToolbar.init(frame: CGRect.init(x: 0.0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 50))
            toolBar.barStyle = .default
            toolBar.items = [UIBarButtonItem.init(title: "Done", style: .done, target: self, action: #selector(onDoneButtonTapped)),UIBarButtonItem.init(title: "Drop Pins", style: .plain, target: self, action: #selector(onDropPinsTapped))]
            self.view.addSubview(toolBar)
        }
       else {
            toolBar.removeFromSuperview()
            picker.removeFromSuperview()
        }
    }
    
    func addFolderToDB(_ folderName: String){
        let thepath = Bundle.main.path(forResource: "mappi", ofType: "db")
        let DB = FMDatabase(path: thepath)
        if !(DB.open()) {
            print("Unable to open database")
        } else {
            do{
                let unique = try DB.executeQuery("select * from folders where name=?", values:[folderName])
                if (unique.next() == false){
                    print("folder name unique unique")
                    let myID = UserDefaults.standard.integer(forKey: "id")
                    try DB.executeUpdate("INSERT INTO folders (name, color, owner) VALUES (?, ?, ?)", values:[folderName, "blue", myID])
                }
                else {
                    print("folder name not unique")
                    let fac = UIAlertController(title: "folder name not unique", message: "Please try again" , preferredStyle: .alert)
                    fac.addAction(UIAlertAction(title:"Return", style: .default, handler:nil))
                    present(fac, animated:true, completion: nil)
                }
            } catch let error as NSError {
                print("failed \(error)")
            }
        }
    }
    
    func addLoc(_ xCoord: Double, _ yCoord: Double, _ locationName: String, _ city: String, _ state: String){
        let xCoord1 = String(xCoord)
        let yCoord1 = String(yCoord)
        
        let thepath = Bundle.main.path(forResource: "mappi", ofType: "db")
        let folderDB = FMDatabase(path: thepath)
        var folderID = -1
        if !(folderDB.open()) {
            print("Unable to open database")
            return
        } else {
            do{
                let query = "select folderID from folders where name=?"
                let f = try folderDB.executeQuery(query, values: [pickerFolder])
                while(f.next()){
                    folderID = Int(f.int(forColumn: "folderID"))
                    print("folder id: \(folderID)")
                }
                let query1 = "insert into places (locationName, xcoord, ycoord, city, state, folderID) values (?, ?, ?, ?, ?, ?)"
                
                try folderDB.executeUpdate(query1, values: [locationName, xCoord1, yCoord1, city, state, folderID])
                let newPlace = place(locationName: locationName, lat: xCoord, long: yCoord, city: city, state: state, folderID: folderID)
                //places[folderID].append(newPlace)
                print("sucessfully added location")
                
            } catch let error as NSError {
                print("failed \(error)")
            }
        }
    }
    
    //desc: adds searched location to array
    @objc
    func clickBtnAdd(sender: UIButton!) {
        callPickerView()
        
    }
    
    //Jane TODO: figure out why this sometimes doesn't work
    @objc func onDoneButtonTapped() {
        toolBar.removeFromSuperview()
        picker.removeFromSuperview()
    }

    @objc func onNewFolderTapped() {
        let alertController = UIAlertController(title: "New Folder", message: "Enter Folder Name", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Enter", style: .default) { (_) in
            let folderName = alertController.textFields?[0].text
            self.addFolderToDB(folderName!);
            let newFolder:[place] = []
            self.places.append(newFolder)
            if folderName != nil {
                self.pickerTest.append(folderName!)
                self.onDoneButtonTapped()
                self.callPickerView()
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Enter Folder Name"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    //TODO: add to actual folder, check if already in folder, maybe add remove from folder? remove force unwraps, using for testing
    //DB TODO: account for trying to add same location multiple times, make added pin stay b/w builds
    @objc func onAddButtonTapped() -> Bool {
        if String(describing: pickerFolder) == "nil" {
            print ("it is nil")
            let fac = UIAlertController(title: "Please select a folder", message: "Please try again" , preferredStyle: .alert)
            fac.addAction(UIAlertAction(title:"Return", style: .default, handler:nil))
            present(fac, animated:true, completion: nil)
            return false
        }
        print("current pin added to \(String(describing: pickerFolder))")
        
        //DB TODO: push this data into db based on pickerFolder, make sure force unwraps don't crash
        let yCoord = Double((currentPin?.coordinate.longitude)!)
        print(yCoord)
        let xCoord = Double((currentPin?.coordinate.latitude)!)
        print(xCoord)
        let locationName = currentPin!.title
        print(locationName)
        let cityState = currentPin?.subtitle?.components(separatedBy: " ")
        let city = cityState?[0] ?? "unknown"
        print(city)
        let state = cityState?[1] ?? "unknown"
        print(state)
        addLoc(xCoord, yCoord, locationName!, city, state)
        return true;
    }
    

    var pickerID:Int = 0
    @objc func onDropPinsTapped() {
        mapView.removeAnnotations(mapView.annotations)
        getPins()
        pickerID = pickerID - 1
        //let size = places.count
        if (pickerID < 0){
            let fac = UIAlertController(title: "Please select a folder", message: "Try again" , preferredStyle: .alert)
            fac.addAction(UIAlertAction(title:"Return", style: .default, handler:nil))
            present(fac, animated:true, completion: nil)
            return
        }
        for place in places[pickerID] {
            print("number of place \(places[pickerID].count)")
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(place.lat), longitude: CLLocationDegrees(place.long))
            annotation.title = place.locationName
            annotation.subtitle = "\(place.city) \(place.state)"
            mapView.addAnnotation(annotation)
        }

        defineSpan(folder: places[pickerID])
            let span:MKCoordinateSpan
            //for some reason it's slightly off center but this zooms to always fit
            span = MKCoordinateSpan(latitudeDelta: maxSpan! + 0.1, longitudeDelta: maxSpan! + 0.1)
        
            let region = MKCoordinateRegion(center: avgCoord!, span: span)
            mapView.setRegion(region, animated: true)
    }
  
    //grab all folders for current user
    var pickerTest = grabFolders()
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerTest.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerTest[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerFolder = pickerTest[row]
        pickerID = row
        print("chosen folder = \(String(describing: pickerFolder))")
    }
    
}

func grabFolders() -> [String]{
    var retArray = [""]
    let thepath = Bundle.main.path(forResource: "mappi", ofType: "db")
    let folderDB = FMDatabase(path: thepath)
    
    if !(folderDB.open()) {
        print("Unable to open database")
        return [""]
    } else {
        do{
            let myID = UserDefaults.standard.integer(forKey: "id")
            let results = try folderDB.executeQuery("select * from folders where owner=?", values:[myID])
            
            while(results.next()) {
                let someName = results.string(forColumn: "name")
                retArray.append(someName!)
            }
            let results2 = try folderDB.executeQuery("select * from sharedFolders where sharedUserID=?", values:[myID])
            
            while(results2.next()) {
                let folderID = Int(results2.int(forColumn: "folderID"))
                let results3 = try folderDB.executeQuery("select * from folders where folderID=?", values: [folderID])
                while(results3.next()){
                    let someName = results3.string(forColumn: "name")
                    retArray.append(someName!)
                }
            }
        }
        catch let error as NSError {
            print("failed \(error)")
            
        }
    }
    return retArray
}


//current location
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    //this is where zoom occurs for current location. want to update location it uses as to center span as center of all locations with span being max lat or long
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error \(error)")
    }
}

//creates annotation based on search
//also search seems pretty limited to locations close to current map view, confirm if this is ok
extension MapViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark){
        // cache the pin
        selectedPin = placemark
        
        // clear existing pins, may want to remove this
        mapView.removeAnnotations(mapView.annotations)
        
        //creates annotation based on placemark info
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        print(annotation.coordinate)
        annotation.title = placemark.name
        
        //annotation.subtitle = "content if there's something else we want to show other than city state"
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        
        //this is temporary, need to find way to set existing pin in folder to currentPin
        //        currentPin = annotation
        //adds annotation to map
        mapView.addAnnotation(annotation)
        
        let span:MKCoordinateSpan
        //zoom in on selected pin
        //need to get this to change when multiple pins on page
        span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        
        
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
}
extension MapViewController: MenuControllerDelegate{
    func passID(forID id: Int?) {
        print("in menudelegate")
        currentID = id ?? 0
    }
}


