//
//  LoginViewController.swift
//  AC3-2-Final-Retake-Fireblog
//
//  Created by Tyler Newton on 6/9/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import UIKit
import SnapKit
import Firebase
import FirebaseAuth

class LoginViewController: UIViewController {
    
    var user: FIRUser?
    var databaseRef: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupHierarchy()
        configureConstraints()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    //    MARK: Setup View Hierarchy -
    private func setupHierarchy(){
        view.backgroundColor = .white
        view.addSubview(usernameTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)
        view.addSubview(registerButton)
    }
    
    //    MARK: Configure Constraints -
    private func configureConstraints() {
        loginButton.snp.makeConstraints { (button) in
            button.top.equalTo(passwordTextField.snp.bottom).offset(5)
            button.trailing.equalToSuperview().inset(110)
        }
        registerButton.snp.makeConstraints { (button) in
            button.top.equalTo(passwordTextField.snp.bottom).offset(5)
            button.leading.equalToSuperview().offset(110)
        }
        
        passwordTextField.snp.makeConstraints { (field) in
            field.centerX.equalToSuperview()
            field.leading.equalToSuperview().offset(10)
            field.trailing.equalToSuperview().inset(10)
            field.height.equalTo(40)
            field.top.equalTo(usernameTextField.snp.bottom).offset(10)
            
        }
        
        usernameTextField.snp.makeConstraints { (field) in
            field.centerX.equalToSuperview()
            field.leading.equalTo(passwordTextField.snp.leading)
            field.trailing.equalTo(passwordTextField.snp.trailing)
            field.height.equalTo(passwordTextField.snp.height)
            field.top.equalToSuperview().offset(40)
        }
        
    }
    
    
    //    MARK: Lazy Vars -
    internal lazy var usernameTextField: UITextField = {
        let textField: UITextField = UITextField()
        textField.textAlignment = .center
        textField.textColor = UIColor.black
        textField.tintColor = UIColor.blue
        textField.layer.borderWidth = 0.5
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.font = UIFont(name: "Apple SD Gothic Neo", size: 15.0)
        textField.attributedPlaceholder = NSAttributedString(string: "EMAIL", attributes: [NSForegroundColorAttributeName: UIColor.gray])
        textField.backgroundColor = .clear
        
        return textField
    }()
    
    internal lazy var passwordTextField: UITextField = {
        let textField: UITextField = UITextField()
        textField.textAlignment = .center
        textField.textColor = UIColor.black
        textField.tintColor = UIColor.blue
        textField.layer.borderWidth = 0.5
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.font = UIFont(name: "Apple SD Gothic Neo", size: 15.0)
        textField.attributedPlaceholder = NSAttributedString(string: "PASSWORD", attributes: [NSForegroundColorAttributeName: UIColor.gray])
        textField.backgroundColor = .clear
        
        return textField
    }()
    
    internal lazy var registerButton: UIButton = {
        let button: UIButton = UIButton(type: .system)
        button.setTitle("Register", for: .normal)
        button.titleLabel?.font = UIFont(name: "Al Nile-Bold", size: 17.0)
        button.setTitleColor(.blue, for: .normal)
        button.addTarget(self, action: #selector(registerButtonPressed(_:)), for: .touchUpInside)
        
        return button
    }()
    
    internal lazy var loginButton: UIButton = {
        let button: UIButton = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.titleLabel?.font = UIFont(name: "Al Nile-Bold", size: 17.0)
        button.setTitleColor(.blue, for: .normal)
        button.addTarget(self, action: #selector(loginButtonPressed(_:)), for: .touchUpInside)
        
        return button
    }()
    
    //    MARK: Registration & Login -
    
    func registerButtonPressed(_ sender: UIButton) {
        print("A NEW USER WOULD LIKE TO REGISTER.")
        
        if usernameTextField.text == "" && passwordTextField.text == "" {
            let alertController = UIAlertController(title: "Error", message: "Please enter valid email and password.", preferredStyle: .alert)
            
            let userAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(userAction)
            
            present(alertController, animated: true, completion: nil)
        } else if usernameTextField.text == "" {
            let alertController = UIAlertController(title: "Error", message: "Please enter a valid email address.", preferredStyle: .alert)
            
            let userAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(userAction)
            
            present(alertController, animated: true, completion: nil)
        } else if (passwordTextField.text?.characters.count)! < 5 {
            let alertController = UIAlertController(title: "Error", message: "Password must be at least 5 characters", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            
            present(alertController, animated: true, completion: nil)
        } else {
            FIRAuth.auth()?.createUser(withEmail: usernameTextField.text!, password: passwordTextField.text!) { (user, error) in
                
                if error == nil {
                    print("You have successfully registered your account. Please login.")
                    
                    self.databaseRef = FIRDatabase.database().reference(fromURL: "https://ac-32-final-retake.firebaseio.com/")
                    guard let email = self.usernameTextField.text else { return }
                    let userRef = self.databaseRef.child("posts").child(user!.uid)
                    
                    userRef.updateChildValues(["email" : email]) { (err, ref) in
                        if err != nil {
                            print("ERROR UPLOADING NEW USER TO DB!")
                        }
                        print("SUCCESSFULLY UPLOADED NEW USER INTO DB")
                    }
                } else {
                    let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                    
                    let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(defaultAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                    
                }
            }
        }
    }
    
    func loginButtonPressed(_ sender: UIButton) {
        if usernameTextField.text == "" && passwordTextField.text == "" {
            let alertController = UIAlertController(title: "Error", message: "Please enter valid email and password", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            
            present(alertController, animated: true, completion: nil)
        } else if usernameTextField.text == "" {
            let alertController = UIAlertController(title: "Error", message: "Please enter valid email address", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            
            present(alertController, animated: true, completion: nil)
        } else if (passwordTextField.text?.characters.count)! < 5 {
            let alertController = UIAlertController(title: "Error", message: "Password must be at least 5 characters", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            
            present(alertController, animated: true, completion: nil)
        } else {
            FIRAuth.auth()?.signIn(withEmail: self.usernameTextField.text!, password: self.passwordTextField.text!) { (user, error) in
                if error != nil {
                    print("You have successfully logged in.")
                    
                    self.user = user
                    self.presentApp()
                } else {
                    let alertController = UIAlertController(title: "ERROR", message: error?.localizedDescription, preferredStyle: .alert)
                    
                    let userAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(userAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func presentApp() {
        let feedController = UINavigationController(rootViewController: FeedViewController())
        let postController = UINavigationController(rootViewController: PostViewController())
        
        let tabBarController = UITabBarController()
        let controllers = [feedController, postController]
        
        tabBarController.viewControllers = controllers
        UITabBar.appearance().tintColor = UIColor.gray
        feedController.tabBarItem = UITabBarItem(title: nil, image: nil, tag: 0)
        postController.tabBarItem = UITabBarItem(title: nil, image: nil, tag: 1)
        
        self.present(tabBarController, animated: true, completion: nil)
        
    }
    
}

