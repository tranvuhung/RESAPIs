//
//  LoginViewController.swift
//  GitHubGists
//
//  Created by Trần Vũ Hưng on 1/20/18.
//  Copyright © 2018 Tran Vu Hung. All rights reserved.
//

import Foundation
import UIKit

protocol LoginViewDelegate: class {
  func didTapLoginButton()
}

class LoginViewController: UIViewController {
  
  weak var  delegate: LoginViewDelegate?
  
  @IBAction func tapLoginButton(){
    if let delegate = delegate {
      delegate.didTapLoginButton()
    }
  }
}
