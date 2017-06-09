//
//  FeedViewController.swift
//  AC3-2-Final-Retake-Fireblog
//
//  Created by Tyler Newton on 6/9/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import UIKit
import Firebase

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var user: FIRUser?
    var posts = [Post]()
    var messages: [FIRDataSnapshot]! = []
    var databaseRef: FIRDatabaseReference!
    var storageRef: FIRStorageReference!
    var postFromDatabase = [String:[String:Any]]()
    
    fileprivate var _authHandle: FIRAuthStateDidChangeListenerHandle!
    fileprivate var _refHandle: FIRDatabaseHandle!
    fileprivate var _storageHandle: FIRStorageHandle!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        loggedInListener()
        setupViewHiearchy()
        configureConstraints()
        configureDatabase()
        configureTableView()
        readPostsFromDB { (postInfoDict) in
            DispatchQueue.main.async {
                self.createObjectsFromDB(postInfoDict, completion: { (post) in
                    self.posts.append(post)
                    self.messageTableView.reloadData()
                })
            }
        }
    }
    
    // MARK: View Hierarchy and Constraints -
    
    func setupViewHiearchy() {
        self.view.addSubview(messageTableView)
    }
    
    func configureConstraints() {
        let _ = [
            messageTableView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            messageTableView.heightAnchor.constraint(equalTo: self.view.heightAnchor),
            messageTableView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            messageTableView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
            ].map{ $0.isActive = true }
    }
    
    // MARK: Lazy Vars -
    
    lazy var messageTableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    // MARK: Configure TableView -
    
    func configureTableView() {
        self.messageTableView.delegate = self
        self.messageTableView.dataSource = self
        self.messageTableView.register(FeedTableViewCell.self, forCellReuseIdentifier: "FeedCell")
        self.messageTableView.estimatedRowHeight = 150
        self.messageTableView.rowHeight = UITableViewAutomaticDimension
        self.messageTableView.separatorStyle = .singleLine
    }
    
    // MARK: Firebase -
    
    func loggedInListener() {
        _authHandle = FIRAuth.auth()?.addStateDidChangeListener({ (auth: FIRAuth?, user: FIRUser?) in
            
            if let activeUser = user {
                self.user = activeUser
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(self.logOutUser(_:)))
            }
        })
    }
    
    func configureDatabase() {
        // TODO: configure database to sync messages
        
        databaseRef = FIRDatabase.database().reference()
        
        _refHandle = databaseRef.child("Posts").observe(.childAdded) { (snapshot: FIRDataSnapshot) in
            self.messages.append(snapshot)
            self.messageTableView.insertRows(at: [IndexPath(row: self.messages.count - 1, section: 0)], with: .automatic)
            self.scrollToBottomMessage()
            
            //In this case this listener should be removed when the viewcontroller is deinitialized.
        }
    }
    
    func scrollToBottomMessage() {
        if messages.count == 0 { return }
        let bottomMessageIndex = IndexPath(row: messageTableView.numberOfRows(inSection: 0) - 1, section: 0)
        messageTableView.scrollToRow(at: bottomMessageIndex, at: .bottom, animated: true)
    }
    
    func configureStorage() {
        // TODO: configure storage using your firebase storage
        storageRef = FIRStorage.storage().reference()
    }
    
    func logOutUser(_ sender: UIBarButtonItem) {
        if FIRAuth.auth()?.currentUser != nil {
            do {
                try FIRAuth.auth()?.signOut()
                let loginController = LoginViewController()
                self.present(loginController, animated: true, completion: nil)
            }
            catch let error as NSError {
                print("ERROR \(error.localizedDescription)")
            }
        }
    }
    
    func readPostsFromDB(completion: @escaping ([String:[String:Any]]) -> ()) {
        databaseRef = FIRDatabase.database().reference(fromURL: "https://ac-32-final-retake.firebaseio.com/")
        
        _refHandle = databaseRef.observe(.childAdded, with: { (snapshot) in
            
            if let postsDict = snapshot.value as? [String:Any] {
                for (key, value) in postsDict {
                    if let postDict = value as? [String:Any] {
                        self.postFromDatabase.updateValue(postDict, forKey: key)
                    }
                }
                completion(self.postFromDatabase)
            }
        })
    }
    
    func createObjectsFromDB(_ infoDict: [String:[String:Any]], completion: @escaping (Post) -> ())  {
        
        for (key, value) in infoDict {
            if let email = value["email"] as? String,
                let timestamp = value["timestamp"] as? Double,
                let type = value["type"] as? String,
                let text = value["text"] as? String? {
                
                
                switch type {
                case type where type == PostType.text.rawValue:
                    let textPost = Post(email: email, type: type, timestamp: timestamp, postID: key, text: text, image: nil)
                    completion(textPost)
                case type where type == PostType.image.rawValue:
                    self.readImageFromStorage(key) { (image) in
                        let imagePost = Post(email: email, type: type, timestamp: timestamp, postID: key, text: nil, image: image)
                        completion(imagePost)
                    }
                default:
                    continue
                }
            }
        }
    }
    
    func readImageFromStorage(_ key: String, completion: @escaping (UIImage) -> ()) {
        
        storageRef = FIRStorage.storage().reference(forURL: "gs://ac-32-final-retake.appspot.com").child("images/").child("\(key)")
        
        storageRef.data(withMaxSize: 1 * 1024 * 1024) { (data, error) in
            if error != nil {
                print("ERROR DOWNLOADING IMAGE: \(error!.localizedDescription)")
            }
            }.resume()
    }
    

    
    
    // MARK: Data Source Methods -
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let postByDate = self.posts.sorted() { $0.timestamp > $1.timestamp}
        return postByDate.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath) as! FeedTableViewCell
        
        let postByDate = self.posts.sorted() { $0.timestamp > $1.timestamp}
        let post = postByDate[indexPath.row]
        
        cell.emailLabel.text = post.userEmail
        
        let timeInterval = TimeInterval(post.timestamp)
        let timeIntervalSinceDate = NSDate(timeIntervalSinceReferenceDate: timeInterval)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yy, h:mm a"
        
        let postDateString = dateFormatter.string(from: timeIntervalSinceDate as Date)
        cell.timestampLabel.text = postDateString
        
        if post.type == PostType.text.rawValue {
            cell.postImageView.removeFromSuperview()
            cell.contentView.addSubview(cell.postLabel)
            
            let _ = [
                cell.postLabel.widthAnchor.constraint(equalTo: cell.contentView.widthAnchor, multiplier: 0.6),
                cell.postLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8.0),
                cell.postLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -8.0),
                cell.postLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8.0)
                ].map{ $0.isActive = true }
            
            if let text = post.text {
                cell.postLabel.text = "\(text)\n"
            }
        }
        
        if post.type == PostType.image.rawValue {
            cell.postLabel.removeFromSuperview()
            cell.contentView.addSubview(cell.postImageView)
            
            let _ = [
                cell.postImageView.widthAnchor.constraint(equalTo: cell.contentView.widthAnchor, multiplier: 0.6),
                cell.postImageView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8.0),
                cell.postImageView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -8.0),
                cell.postImageView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8.0)
                ].map{ $0.isActive = true }
            
            if let postImage = post.image {
                cell.postImageView.image = postImage
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}
