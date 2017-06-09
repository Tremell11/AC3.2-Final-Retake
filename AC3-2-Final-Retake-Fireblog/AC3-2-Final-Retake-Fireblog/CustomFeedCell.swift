//
//  CustomFeedCell.swift
//  AC3-2-Final-Retake-Fireblog
//
//  Created by Tyler Newton on 6/9/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import UIKit
import SnapKit


import UIKit

class FeedTableViewCell: UITableViewCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViewHierarchy()
        configureConstraints()
        self.clipsToBounds = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
//    MARK: Setup View Hierarchy - 
    
    func setupViewHierarchy() {
        self.contentView.addSubview(emailLabel)
        self.contentView.addSubview(timestampLabel)
    }
    
//    MARK: Configure Constraints - 
    
    func configureConstraints() {
        
        let _ = [
            emailLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 8.0),
            emailLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8.0),
            emailLabel.widthAnchor.constraint(equalTo: self.contentView.widthAnchor, multiplier: 0.4),
            emailLabel.bottomAnchor.constraint(equalTo: timestampLabel.topAnchor, constant: -8.0),
            
            timestampLabel.widthAnchor.constraint(equalTo: self.contentView.widthAnchor, multiplier: 0.4),
            timestampLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 8.0),
            timestampLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8.0)
            ].map{ $0.isActive = true }
        
    }
    
    // MARK: Lazy Vars -
    
    lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont(name: "Gill Sans", size: 12.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var timestampLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Gill Sans", size: 12.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var postLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = UIFont(name: "Gill Sans", size: 12.0)
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    lazy var postImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleToFill
        iv.clipsToBounds = true
        return iv
    }()
    
}
