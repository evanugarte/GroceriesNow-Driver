//
//  DriverVC.swift
//  GroceriesNow Driver
//
//  Created by evan on 3/28/18.
//  Copyright © 2018 evan. All rights reserved.
//

import UIKit
import MapKit

class DriverVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, GroceriesController {
    
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var acceptOrderBtn: UIButton!
    @IBOutlet weak var setPriceBtn: UIButton!
    
    private var locationManager = CLLocationManager()
    private var userLocation: CLLocationCoordinate2D?
    private var orderLocation: CLLocationCoordinate2D?
    
    private var timer = Timer()
    
    private var acceptedGroceries = false
    private var driverCancelledGroceries = false
    var orderPrice = ""
    
    var directionsMade = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        canSeeButtons(show: false)
        //extra code added
        myMap.delegate = self
        myMap.showsScale = true
        myMap.showsPointsOfInterest = true
        myMap.showsUserLocation = true
        
        var sourceCoordinates = locationManager.location?.coordinate
        //end extra code added
       
        //request new permissions
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        //if agreed to share location
        if CLLocationManager.locationServicesEnabled(){
            initializeLocationManager()
        }
        
        
        GroceriesHandler.Instance.delegate = self
        GroceriesHandler.Instance.observerMessagesForDriver()
    }
    
    private func initializeLocationManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //if we have coordinates from the manager, create user location
        if let location = locationManager.location?.coordinate{
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            
            let region = MKCoordinateRegion(center: userLocation!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            
            myMap.setRegion(region, animated: true)
            //remove any old annotation from previous runs
            myMap.removeAnnotations(myMap.annotations)
            
            if orderLocation != nil{
                if acceptedGroceries{
                    let orderAnnotation = MKPointAnnotation()
                    orderAnnotation.coordinate = orderLocation!
                    orderAnnotation.title = "Order Location"
                    myMap.addAnnotation(orderAnnotation)
                }
            }
//            
//            let annotation = MKPointAnnotation()
//            annotation.coordinate = userLocation!
//            annotation.title = "Driver's Location"
//            myMap.addAnnotation(annotation)
        }
    }

    func canSeeButtons(show: Bool){
        if show {
            acceptOrderBtn.isHidden = false
            setPriceBtn.isHidden = false
        }else{
            acceptOrderBtn.isHidden = true
            setPriceBtn.isHidden = true
        }
    }
    
    //Accept groceries order
    func acceptGroceries(lat: Double, long: Double, storeID: String) {
        if !acceptedGroceries{
            groceriesRequest(title: "Groceries Request", message: "You have a request at \(storeID), customer location Lat: \(lat), Long: \(long)", requestAlive: true)
        }
        driverCancelledGroceries = false
    }
    
    func getDirectionsToUser(lat: Double, long: Double){
        //extra code added
        let sourceCoordinates = locationManager.location?.coordinate
        let destCoordinates = CLLocationCoordinate2DMake(lat, long)
        
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinates!)
        let destPlacemark = MKPlacemark(coordinate: destCoordinates)
        
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destItem = MKMapItem(placemark: destPlacemark)
        
        let directionRequest = MKDirectionsRequest()
        directionRequest.source = sourceItem
        directionRequest.destination = destItem
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate(completionHandler: {
            response, error in
            
            guard let response = response else{
                if let error = error{
                    print("\n\nsomething wrong\n\n")
                }
                return
            }
            //REMOVE METHOD NEW
            self.myMap.removeOverlays(self.myMap.overlays)
            let route = response.routes[0]
            self.myMap.add(route.polyline, level: .aboveRoads)
            
            let rekt = route.polyline.boundingMapRect
            self.myMap.setRegion(MKCoordinateRegionForMapRect(rekt), animated: true)
            
        })
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5.0
        
        return renderer
    }
    
    func cancelDirections(){
        let overlays = myMap.overlays
        myMap.removeOverlays(overlays)
    }
    
    func customerCancelledGroceries(){
        if !driverCancelledGroceries {
            self.acceptedGroceries = false
            canSeeButtons(show: false)
            groceriesRequest(title: "Order Cancelled", message: "The Customer Has Cancelled The Order", requestAlive: false)
        }
    }
    
    func groceriesOrderCancelled() {
        acceptedGroceries = false
        canSeeButtons(show: false)
        cancelDirections()
        timer.invalidate()
    }
    
    func updateCustomerLocation(lat: Double, long: Double) {
        orderLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
    
    //MAYBE ERROR? THIS COMMENT IS FOR DEBUGGING
    @objc func updateDriversLocation() {
        GroceriesHandler.Instance.updateDriverLocation(lat: userLocation!.latitude, long: userLocation!.longitude)
    }
    
    @IBAction func getOrderDetails(_ sender: Any) {
        groceriesRequest(title: "Order Details", message: "\(GroceriesHandler.Instance.getOrderDetails())", requestAlive: false)
    }
    
    @IBAction func cancelGroceries(_ sender: Any) {
        if acceptedGroceries{
            driverCancelledGroceries = true
            canSeeButtons(show: false)
            
            GroceriesHandler.Instance.cancelGroceriesOrderForDriver()
            timer.invalidate()
        }
    }
    @IBAction func setOrderPrice(_ sender: Any) {
        getPriceEntry()
        GroceriesHandler.Instance.updateOrderPrice(price: self.orderPrice)
    }
    
    func getPriceEntry(){
        //Create Alert Controller
        let alert9 = UIAlertController (title: "Order Price:", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        
        //Create Cancel Action
        let cancel9 = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        alert9.addAction(cancel9)
        
        //Create OK Action
        let ok9 = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (action: UIAlertAction) in
            let textfield = alert9.textFields?[0]
            self.orderPrice = (textfield?.text!)!
        }
        //TEXT FIELD NOTIFICATION
        alert9.addAction(ok9)
        
        //Add Text Field
        alert9.addTextField { (textfield: UITextField) in
            textfield.text = self.orderPrice
            
            textfield.placeholder = "Enter Price Here"
        }
        //Present Alert Controller
        self.present(alert9, animated:true, completion: nil)
    }
    
    @IBAction func logOut(_ sender: Any) {
        if AuthProvider.Instance.logOut(){
            //cancel order if the driver decides to log out
            if acceptedGroceries{
                canSeeButtons(show: false)
                GroceriesHandler.Instance.cancelGroceriesOrderForDriver()
                timer.invalidate()
            }
            
            dismiss(animated: true, completion: nil)
        }else{
            groceriesRequest(title: "Problem Logging out", message: "Unable to logout at the moment, please try again later", requestAlive: false)
        }
    }
    
    private func groceriesRequest(title: String, message: String, requestAlive: Bool){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if requestAlive {
            let accept = UIAlertAction(title: "Accept", style: .default, handler: {(alertAction: UIAlertAction) in
                
                self.acceptedGroceries = true
                self.canSeeButtons(show: true)
                //dest coordinates original spot
                
                
                self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(10), target: self, selector: #selector(DriverVC.updateDriversLocation), userInfo: nil, repeats: true)
                
                //inform customer rider accepted order
                GroceriesHandler.Instance.groceriesOrderAccepted(lat: Double(self.userLocation!.latitude), long: Double(self.userLocation!.longitude))
                
            })
            
            let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            
            alert.addAction(accept)
            alert.addAction(cancel)
        }else{
            let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(ok)
        }
        
        present(alert, animated: true, completion: nil)
    }
    
}
