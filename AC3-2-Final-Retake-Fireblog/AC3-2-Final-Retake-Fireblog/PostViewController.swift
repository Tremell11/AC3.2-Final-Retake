//
//  PostViewController.swift
//  AC3-2-Final-Retake-Fireblog
//
//  Created by Tyler Newton on 6/9/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import UIKit
import SnapKit
import Firebase
import MobileCoreServices

class PostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var user: FIRUser?
    var userImagePicker = UIImagePickerController()
    
    var databaseRef: FIRDatabaseReference!
    var storageRef: FIRStorageReference!
    
    fileprivate var _authHandle: FIRAuthStateDidChangeListenerHandle!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .lightGray
        
        setupViewHierarchy()
        configureConstraints()
        configureImagePicker()
        configureNavigation()
        loggedInListener()
    }

    
//    MARK: Setup View Hierarchy -
    
    private func setupViewHierarchy() {
        self.view.addSubview(userImage)
        self.view.addSubview(separatorLabel)
        self.view.addSubview(userTextField)
    }
    
//    MARK: Configure Constraints -
    
    private func configureConstraints() {
        
        userTextField.snp.makeConstraints { (field) in
            field.top.equalToSuperview().offset(75)
            field.leading.equalToSuperview().offset(50)
            field.trailing.equalToSuperview().inset(50)
            field.height.equalTo(250)
        }
        
        separatorLabel.snp.makeConstraints { (label) in
            label.centerX.equalToSuperview()
            label.top.equalTo(userTextField.snp.bottom).offset(5)
            label.width.equalTo(75)
        }
        
        userImage.snp.makeConstraints { (imageView) in
            imageView.top.equalTo(separatorLabel.snp.bottom).offset(5)
            imageView.leading.equalTo(userTextField.snp.leading)
            imageView.trailing.equalTo(userTextField.snp.trailing)
            imageView.height.equalTo(userTextField.snp.height)
        }
    }
    
    // MARK: Configuration -
    
   private func configureImagePicker() {
        userImagePicker.delegate = self
        userImagePicker.sourceType = .savedPhotosAlbum
        userImagePicker.allowsEditing = false
        userImagePicker.mediaTypes = [kUTTypeImage as String]
    }
    
   private func configureNavigation() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Post", style: .plain, target: self, action: #selector(uploadToDB(_:)))
    }
    
    // MARK: Lazy Vars -
    
    lazy var userImage: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .white
        iv.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector (uploadImage(_:)))
        iv.addGestureRecognizer(tapGesture)
        return iv
    }()
    
    lazy var userTextField: UITextView = {
        let view = UITextView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textContainer.maximumNumberOfLines = 10
        view.textContainer.lineBreakMode = .byWordWrapping
        view.backgroundColor = .white
        return view
    }()
    
    lazy var separatorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "-or-"
        label.font = UIFont.systemFont(ofSize: 20, weight: UIFontWeightMedium)
        return label
    }()
    
    // MARK: Action Methods -
    
    func uploadImage(_ sender: UIImageView) {
        self.present(userImagePicker, animated: true, completion: nil)
    }
    
    func uploadToDB(_ sender: UIBarButtonItem) {
        if userImage.image != nil && userTextField.text != "" {
            let alertController = UIAlertController(title: "Sorry", message: "You can only send one type at a time. please select either a message or an image to post.", preferredStyle: .alert)
            
            let userAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            
            alertController.addAction(userAction)
            
            self.present(alertController, animated: true) {
                self.userImage.image = nil
                self.userTextField.text = nil
            }
            
        }
        if userImage.image != nil && userTextField.text == "" {
            //upload image to storage and database
            if let data = UIImageJPEGRepresentation(userImage.image!, 0.8) {
                self.uploadImageToStorage(photoData: data)
            }
        }
        
        if userImage.image == nil && (userTextField.text?.characters.count)! > 0 {
            userTextToDB(userTextField.text!)
        }
    }
    
    // MARK: Firebase -
    
    func uploadImageToStorage(photoData: Data) {
        guard let user = self.user else { return }
        
        databaseRef = FIRDatabase.database().reference(fromURL: "https://ac-32-final-retake.firebaseio.com/")
        
        let postsRef = databaseRef.child("posts/")
        
        let imageKey_Ref = postsRef.childByAutoId()
        
        print("KEY?: \(imageKey_Ref.key)")
        
        storageRef = FIRStorage.storage().reference(forURL: "gs://ac-32-final-retake.appspot.com/")
        
        let imagesRef = storageRef.child("images/\(imageKey_Ref.key)")
        
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "public,max-age=300"
        
        imagesRef.put(photoData, metadata: metadata) { (metadata, error) in
            if error != nil {
                print("Error uploading photo data to storage: \(String(describing: error))")
            }
        }
        imageKey_Ref.setValue(["email" : "\(user.email!)",
            "text" : "",
            "timestamp" : NSDate.timeIntervalSinceReferenceDate,
            "type": PostType.image.rawValue])
        
        uploadSuccessAlert()
        let feedController = FeedViewController()
        DispatchQueue.main.async {
            feedController.messageTableView.reloadData()
        }
    }
    
    func userTextToDB(_ text: String) {
        guard let user = self.user else { return }
        
        databaseRef = FIRDatabase.database().reference(fromURL: "https://ac-32-final-retake.firebaseio.com/")
        
        let postsDBRef = databaseRef.child("posts/")
        
        let userTextRef = postsDBRef.childByAutoId()
        
        userTextRef.updateChildValues(["email" : user.email!,
                                       "text" : text,
                                       "timestamp" : NSDate.timeIntervalSinceReferenceDate,
                                       "type" : PostType.text.rawValue]) { (error, ref) in
                                        if error != nil {
                                            print("Error uploading text post to database: \(String(describing: error))")
                                        }
        }
        uploadSuccessAlert()
        let feedController = FeedViewController()
        DispatchQueue.main.async {
            feedController.messageTableView.reloadData()
        }
        
    }
    
    func loggedInListener() {
        _authHandle = FIRAuth.auth()?.addStateDidChangeListener({ (auth: FIRAuth?, user: FIRUser?) in
            if let activeUser = user {
                self.user = activeUser
            }
        })
    }
    
    func uploadSuccessAlert() {
        let alertController = UIAlertController(title: "Upload Successful!", message: nil, preferredStyle: .alert)
        let userAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        alertController.addAction(userAction)
        self.present(alertController, animated: true, completion: nil)
        userTextField.text = nil
        userImage.image = nil
    }
    
    // MARK: ImagePicker Delegate -
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            userImage.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    
}
