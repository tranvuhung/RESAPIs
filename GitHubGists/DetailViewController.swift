//
//  DetailViewController.swift
//  GitHubGists
//
//  Created by Trần Vũ Hưng on 1/17/18.
//  Copyright © 2018 Tran Vu Hung. All rights reserved.
//

import UIKit
import SafariServices

class DetailViewController: UIViewController {

  @IBOutlet weak var tableView: UITableView!
  
  var gist: Gist? {
    didSet {
      // Update the view.
      configureView()
    }
  }

  func configureView() {
    // Update the user interface for the detail item.
    if let detailView = tableView {
      detailView.reloadData()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    configureView()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

extension DetailViewController: UITableViewDataSource, UITableViewDelegate {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return 2
    } else {
      return gist?.files?.count ?? 0
    }
  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section == 0 {
      return "About"
    } else {
      return "Files"
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "gistCell", for: indexPath)
    if indexPath.section == 0 {
      if indexPath.row == 0 {
        cell.textLabel?.text = gist?.description
      } else if indexPath.row == 1 {
        cell.textLabel?.text = gist?.ownerLogin
      }
    } else {
      if let file = gist?.files?[indexPath.row] {
        cell.textLabel?.text = file.filename
      }
    }
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 1 {
      if let file = gist?.files?[indexPath.row], let urlString = file.raw_url, let url = URL(string: urlString) {
        let safari = SFSafariViewController(url: url)
        safari.title = file.filename
        self.navigationController?.pushViewController(safari, animated: true)
      }
    }
  }
}
