//
//  SignInVC.swift
//  GroceriesNow Driver
//
//  Created by evan on 3/19/18.
//  Copyright © 2018 evan. All rights reserved.
//

import UIKit

class SignInVC: UIViewController {
    
    private let DRIVER_SEGUE = "DriverVC"
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    @IBAction func logIn(_ sender: AnyObject) {
        
        if emailTextField.text != "" && passwordTextField.text != ""{
            
            AuthProvider.Instance.login(withEmail: emailTextField.text!, password: passwordTextField.text!,
                loginHandler: { (message) in
                                            
                if message != nil{
                    self.alertTheUser(title: "Problem With Authentication", message: message!)
                }else{
                    GroceriesHandler.Instance.driver = self.emailTextField.text!
                    
                    self.emailTextField.text = ""
                    self.passwordTextField.text = ""
                    
                    self.performSegue(withIdentifier: self.DRIVER_SEGUE, sender: nil)
                }
            })
        }else{
            alertTheUser(title: "Emain And Password Are Required", message: "Please enter an email and password in the text fields")
        }
    }

    @IBAction func signUp(_ sender: Any) {
        if emailTextField.text != "" && passwordTextField.text != ""{
            
            AuthProvider.Instance.signUp(withEmail: emailTextField.text!, password: passwordTextField.text!, loginHandler: {(message) in
                
                if message != nil {
                    self.alertTheUser(title: "Problem With Creating A New User", message: message!)
                }else{
                    GroceriesHandler.Instance.driver = self.emailTextField.text!
                    
                    self.emailTextField.text = ""
                    self.passwordTextField.text = ""
                    
                    self.performSegue(withIdentifier: self.DRIVER_SEGUE, sender: nil)
                }
            })
            
        }else{
            alertTheUser(title: "Emain And Password Are Required", message: "Please enter an email and password in the text fields")
        }
    }
    
    //create alert notification
    private func alertTheUser(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
}
