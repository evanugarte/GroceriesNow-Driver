//
//  DBProvider.swift
//  GroceriesNow
//
//  Created by evan on 3/29/18.
//  Copyright © 2018 evan. All rights reserved.
//

import Foundation
import FirebaseDatabase

class DBProvider{
    private static let _instance = DBProvider()
    
    static var Instance: DBProvider {
        return _instance
    }
    
    //allows us to reference accounts made in firebase
    var dbRef: DatabaseReference{
        return Database.database().reference()
    }
    
    var driversRef: DatabaseReference{
        //return name of driver from Firebase
        return dbRef.child(Constants.DRIVERS)
    }
    var requestRef: DatabaseReference{
        //return groceries request
        return dbRef.child(Constants.GROCERIES_REQUEST)
    }
    var requestAcceptedRef: DatabaseReference{
        //return accepted groceries request
        return dbRef.child(Constants.GROCERIES_ACCEPTED)
    }
    
    func saveUser(withID: String, email: String, password: String){
        let data: Dictionary<String, Any> = [Constants.EMAIL: email, Constants.PASSWORD: password, Constants.isCustomer: false]
        
        //adds user to database
        driversRef.child(withID).child(Constants.DATA).setValue(data)
        
    }
    
} //class
