//
//  AuthProvider.swift
//  GroceriesNow
//
//  Created by evan on 3/21/18.
//  Copyright © 2018 evan. All rights reserved.
//

import Foundation
import FirebaseAuth //will be referenced as "Auth" in code

typealias LoginHandler = (_ msg: String?) -> Void

struct LoginErrorCode {
    static let INVALID_EMAIL = "Invalid Email Address"
    static let WRONG_PASSWORD = "Wrong Password"
    static let PROBLEM_CONNECTING = "Database Connection Error, Please Try Later"
    static let USER_NOT_FOUND = "User Not Found, Please Register"
    static let TAKEN_EMAIL = "Email Already In Use, Please Enter Another Email"
    static let WEAK_PASSWORD = "Password Should Be 6 Or More Charachters Long"
}

class AuthProvider{
    private static let _instance = AuthProvider();
    
    static var Instance: AuthProvider {
        return _instance
    }
    
    func login(withEmail: String, password: String, loginHandler: LoginHandler?){
        
        //try to sign in user, catch any errors
        Auth.auth().signIn(withEmail: withEmail, password: password,
                           completion: { (user, error) in
                            
                            if error != nil{
                                self.handleError(err: error! as NSError, loginHandler: loginHandler)
                            } else {
                                loginHandler?(nil)
                            }
        })
    }// login func
    
    func signUp(withEmail: String, password: String, loginHandler: LoginHandler?){
        
        Auth.auth().createUser(withEmail: withEmail, password: password, completion: {(user, error) in
            
            //handle any sign in errors
            if error != nil{
                self.handleError(err: error! as NSError, loginHandler: loginHandler)
            }else{
                if user?.uid != nil {
                    //store user to database
                    DBProvider.Instance.saveUser(withID: user!.uid, email: withEmail, password: password)
                    //sign up+log in user
                    self.login(withEmail: withEmail, password: password, loginHandler: loginHandler)
                }
            }
        })
        
    }//sign up func
    
    func logOut() -> Bool {
        if Auth.auth().currentUser != nil {
            do{
                try Auth.auth().signOut()
                return true
            } catch {
                return false
            }
        }
        return true
    }
    
    //handle login errors
    private func handleError(err: NSError, loginHandler: LoginHandler?){
        
        //test if we have error passed
        if let errCode = AuthErrorCode(rawValue: err.code){
            
            //handle errors with switch
            switch errCode{
                
            case .wrongPassword:
                loginHandler?(LoginErrorCode.WRONG_PASSWORD)
                break
                
            case .invalidEmail:
                loginHandler?(LoginErrorCode.INVALID_EMAIL)
                break
                
            case .userNotFound:
                loginHandler?(LoginErrorCode.USER_NOT_FOUND)
                break
                
            case .emailAlreadyInUse:
                loginHandler?(LoginErrorCode.TAKEN_EMAIL)
                break
                
            case .weakPassword:
                loginHandler?(LoginErrorCode.WEAK_PASSWORD)
                break
                
            //if no case satisfied we will assume there was a connection error
            default:
                loginHandler?(LoginErrorCode.PROBLEM_CONNECTING)
                break
            }
        }
    }
    
}//class
