//
//  GroceriesHandler.swift
//  GroceriesNow Driver
//
//  Created by evan on 3/29/18.
//  Copyright © 2018 evan. All rights reserved.
//

import Foundation
import FirebaseDatabase

protocol GroceriesController: class {
    func acceptGroceries(lat: Double, long: Double, storeID: String)
    func customerCancelledGroceries()
    func groceriesOrderCancelled()
    func updateCustomerLocation(lat: Double, long: Double)
    func getDirectionsToUser(lat: Double, long: Double)
}

class GroceriesHandler{
    private static let _instance = GroceriesHandler()
    
    weak var delegate: GroceriesController?
    
    var customer = ""
    var driver = ""
    var driver_id = ""
    var orderDetails = ""
    var orderPrice = ""
    var driverCancelled = false
    var directionsMade = false
    
    var customerInitialLat = 0.0
    var customerInitialLong = 0.0
    
    
    static var Instance: GroceriesHandler{
        return _instance
    }
    
    func observerMessagesForDriver() {
        //CUSTOMER PLACED ORDER
        DBProvider.Instance.requestRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot) in
            
            if let data = snapshot.value as? NSDictionary{
                if let latitude = data[Constants.LATITUDE] as? Double{
                    if let longitude = data[Constants.LONGITUDE] as? Double{
                        if let storeLocation = data[Constants.STORE_NAME] as? String{
                            self.delegate?.acceptGroceries(lat: latitude, long: longitude, storeID: storeLocation)
                            self.customerInitialLat = latitude
                            self.customerInitialLong = longitude
                        }
                    }
                }
                if let orderDets = data[Constants.ORDER_DETAILS] as? String{
                    self.orderDetails = orderDets
                }
                if let name = data[Constants.NAME] as? String{
                    self.customer = name
                }
            }
            //CUSTOMER CANCELLED ORDER
            DBProvider.Instance.requestRef.observe(DataEventType.childRemoved, with: { (snapshot: DataSnapshot) in
                if let data = snapshot.value as? NSDictionary {
                    if let name = data[Constants.NAME] as? String{
                        if name == self.customer && !self.driverCancelled{
                            self.customer = ""
                            self.delegate?.customerCancelledGroceries()
                            self.cancelGroceriesOrderForDriver()
                        }
                    }
                    
                }
            })
        }

        //CUSTOMER UPDATING LOCATION
        DBProvider.Instance.requestRef.observe(DataEventType.childChanged) { (snapshot: DataSnapshot) in
            
            if let data = snapshot.value as? NSDictionary {
                if let lat = data[Constants.LATITUDE] as? Double{
                    if let long = data[Constants.LONGITUDE] as? Double{
                        self.delegate?.updateCustomerLocation(lat: lat, long: long)
                            self.delegate?.getDirectionsToUser(lat: lat, long: long)
                            self.directionsMade = true
                    }
                }
            }
        }
        
        //DRIVER ACCEPTS ORDER
        DBProvider.Instance.requestAcceptedRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot) in
            self.driverCancelled = false
            self.driver_id = snapshot.key
            self.delegate?.getDirectionsToUser(lat: self.customerInitialLat, long: self.customerInitialLong)
            self.directionsMade = true
        }

        //DRIVER CANCELS ORDER
        DBProvider.Instance.requestAcceptedRef.observe(DataEventType.childRemoved) { (snapshot: DataSnapshot) in
            
            self.driverCancelled = true
            if let data = snapshot.value as? NSDictionary {
                if let name = data[Constants.NAME] as? String{
                    if name == self.driver{
                        self.delegate?.groceriesOrderCancelled()
                    }
                }
            }
        }
    
    }//observerMessagesForDriver
    
    func groceriesOrderAccepted(lat: Double, long: Double){
        let data: Dictionary<String, Any> = [Constants.NAME: driver, Constants.LATITUDE: lat, Constants.LONGITUDE: long, Constants.ORDER_PRICE: orderPrice]
        
        DBProvider.Instance.requestAcceptedRef.childByAutoId().setValue(data)
    }
    
    func getOrderDetails() -> String {
        return self.orderDetails
    }
    
    func cancelGroceriesOrderForDriver(){
        directionsMade = false
        DBProvider.Instance.requestAcceptedRef.child(driver_id).removeValue()
    }
    
    func updateDriverLocation(lat: Double, long: Double) {
        DBProvider.Instance.requestAcceptedRef.child(driver_id).updateChildValues([Constants.LATITUDE: lat, Constants.LONGITUDE: long])
    }
    
    func updateOrderPrice(price: String){
        DBProvider.Instance.requestAcceptedRef.child(driver_id).updateChildValues([Constants.ORDER_PRICE : price])
        print("\n\napparenyly updated\n")
    }
} // class
