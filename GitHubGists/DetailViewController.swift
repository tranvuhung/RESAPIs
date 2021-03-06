//
//  DetailViewController.swift
//  GitHubGists
//
//  Created by Trần Vũ Hưng on 1/17/18.
//  Copyright © 2018 Tran Vu Hung. All rights reserved.
//

import UIKit
import SafariServices
import BRYXBanner

class DetailViewController: UIViewController {

  @IBOutlet weak var tableView: UITableView!
  var notConnectedBanner: Banner?
  
  var gist: Gist? {
    didSet {
      // Update the view.
      configureView()
    }
  }
  
  var isStarred: Bool?
  var alertController: UIAlertController?

  func configureView() {
    // Update the user interface for the detail item.
    if let _: Gist = gist{
      fetchStarredStatus()
      if let detailView = tableView {
        detailView.reloadData()
      }
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
  
  //MARK: - dismiss the banner when we change views
  override func viewWillDisappear(_ animated: Bool) {
    if let existingBanner = self.notConnectedBanner {
      existingBanner.dismiss()
    }
    super.viewWillDisappear(animated)
  }
  
  func fetchStarredStatus(){
    if let gistId = gist?.id {
      GitHubAPIManager.sharedIntance.isGistStarred(gistId: gistId, completionHandler: { (result) in
        if let error = result.error as NSError? {
          print(error)
          if error.domain == NSURLErrorDomain{
            if error.code == NSURLErrorUserAuthenticationRequired{
              self.alertController = UIAlertController(title: "Could not get starred status", message: error.description, preferredStyle: .alert)
              // add ok button
              let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
              self.alertController?.addAction(okAction)
              self.present(self.alertController!, animated:true, completion: nil)
            } else if error.code == NSURLErrorNotConnectedToInternet{
              // check for existing banner
              if let existingBanner = self.notConnectedBanner {
                existingBanner.dismiss()
              }
              self.notConnectedBanner = Banner(title: "No Internet Connection",
                                               subtitle: "Can not display starred status. Try again when you're connected to the internet",
                                               image: nil,
                                               backgroundColor: UIColor.orange)
              self.notConnectedBanner?.dismissesOnSwipe = true
              self.notConnectedBanner?.show(duration: nil)
            }
          }
        }
        if let status = result.value, self.isStarred == nil {
          self.isStarred = status
          // TODO: update display
          self.tableView.insertRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
        }
      })
    }
  }
  
  func starThisGist(){
    if let gistId = gist?.id {
      GitHubAPIManager.sharedIntance.starGist(gistId: gistId, completionHandler: { (error) in
        if let error = error as NSError? {
          print(error)
          if error.domain == NSURLErrorDomain && error.code == NSURLErrorUserAuthenticationRequired{
            self.alertController = UIAlertController(title: "Could load starred status", message: error.description, preferredStyle: .alert)
          } else {
            self.alertController = UIAlertController(title: "Could not star gist",
                                                     message: "Sorry, your gist couldn't be starred.Maybe GitHub is down or you don't have an internet connection.",
                                                     preferredStyle: .alert)
          }
          // add ok button
          let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
          self.alertController?.addAction(okAction)
          self.present(self.alertController!, animated:true, completion: nil)
        } else {
          self.isStarred = true
          self.tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
          //self.tableView.reloadSections([0], with: .automatic)
        }
      })
    }
  }
  
  func unstarThisGist(){
    if let gistId = gist?.id {
      GitHubAPIManager.sharedIntance.unstarGist(gistId: gistId, completionHandler: { (error) in
        if let error = error as NSError? {
          print(error)
          if error.domain == NSURLErrorDomain && error.code == NSURLErrorUserAuthenticationRequired{
            self.alertController = UIAlertController(title: "Could load starred status", message: error.description, preferredStyle: .alert)
          } else {
            self.alertController = UIAlertController(title: "Could not star gist",
                                                     message: "Sorry, your gist couldn't be starred.Maybe GitHub is down or you don't have an internet connection.",
                                                     preferredStyle: .alert)
          }
          // add ok button
          let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
          self.alertController?.addAction(okAction)
          self.present(self.alertController!, animated:true, completion: nil)
        } else {
          self.isStarred = false
          self.tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
          //self.tableView.reloadSections([0], with: .automatic)
        }
      })
    }
  }
}

extension DetailViewController: UITableViewDataSource, UITableViewDelegate {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      if isStarred != nil {
        return 3
      }
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
        cell.textLabel?.text = gist?.gistDescription
      } else if indexPath.row == 1 {
        cell.textLabel?.text = gist?.ownerLogin
      } else {
        if let starred = isStarred {
          if starred {
            cell.textLabel?.text = "Unstar"
          } else {
            cell.textLabel?.text = "Star"
          }
        }
      }
    } else {
      if let file = gist?.files?[indexPath.row] {
        cell.textLabel?.text = file.filename
        // TODO: add disclosure indicators
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
    if indexPath.section == 0 {
      if indexPath.row == 2 {
        if let starred = isStarred {
          if starred {
            //Unstar
            unstarThisGist()
          } else {
            //Star
            starThisGist()
          }
        }
      }
    }
  }
}
