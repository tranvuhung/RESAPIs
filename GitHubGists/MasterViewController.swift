//
//  MasterViewController.swift
//  GitHubGists
//
//  Created by Trần Vũ Hưng on 1/17/18.
//  Copyright © 2018 Tran Vu Hung. All rights reserved.
//

import UIKit
import PINRemoteImage

class MasterViewController: UITableViewController {

  //MARK: - Properties
  var detailViewController: DetailViewController? = nil
  var objects = [Any]()
  var gists = [Gist]()
  var nextPageUrl: String?
  var isLoading = false
  var dateFormatter = DateFormatter()
  
  //MARK: - Life cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    navigationItem.leftBarButtonItem = editButtonItem

    let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
    navigationItem.rightBarButtonItem = addButton
    if let split = splitViewController {
        let controllers = split.viewControllers
        detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    loadGists(url: nil)
  }

  override func viewWillAppear(_ animated: Bool) {
    clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
    if refreshControl == nil {
      refreshControl = UIRefreshControl()
      refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
      dateFormatter.dateStyle = DateFormatter.Style.short
      dateFormatter.timeStyle = DateFormatter.Style.long
    }
    super.viewWillAppear(animated)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func insertNewObject(_ sender: Any) {
    
    let alert = UIAlertController(title: "Not Implementd", message: "Cant't create new gists yet, will implement later", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    
    self.present(alert, animated: true, completion: nil)
  }
  
  //MARK: - Pull to Refresh
  func refresh(sender: AnyObject){
    nextPageUrl = nil
    loadGists(url: nil)
  }
  
  //MARK: - Load Gist
  func loadGists(url: String?) {
    isLoading = true
    GitHubAPIManager.sharedIntance.getPublicGists(urlPage: url) { (result, nextPage) in
      self.isLoading = false
      self.nextPageUrl = nextPage
      print(nextPage!)
      
      if (self.refreshControl != nil && self.refreshControl!.isRefreshing){
        self.refreshControl?.endRefreshing()
      }
      
      guard result.error == nil else {
        print(result.error!)
        return
      }
      if let gists = result.value {
        if url != nil /* nextPageUrl != nil */ {
          self.gists += gists
        } else {
          self.gists = gists
        }
      }
      
      // update "last updated" title for refresh control
      let now = Date()
      let updateString = "Last update at: \(self.dateFormatter.string(from: now))"
      self.refreshControl?.attributedTitle = NSAttributedString(string: updateString)
      self.tableView.reloadData()
    }
    
  }

  // MARK: - Segues
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showDetail" {
        if let indexPath = tableView.indexPathForSelectedRow {
            _ = objects[indexPath.row] as! Gist
            let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
            //controller.detailItem = gist
            controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }
  }

  // MARK: - Table View

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return gists.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

    let gist = gists[indexPath.row]
    cell.textLabel?.text = gist.description
    cell.detailTextLabel?.text = gist.ownerLogin
    cell.imageView?.image = nil
    
    // set cell.imageView to display image at gist.ownerAvatarURL
    if let imageUrl = gist.ownerAvatarUrl, let url = URL(string: imageUrl) {
      cell.imageView?.pin_setImage(from: url, placeholderImage: UIImage(named: "placeholder.png"))
    } else {
      cell.imageView?.image = UIImage(named: "placeholder.png")
    }
    
    // See if we need to load more gists
    let rowsToLoadFormBotton = 5
    let rowsLoaded = gists.count
    if let nextPage = nextPageUrl {
      if (!isLoading && (indexPath.row >= (rowsLoaded - rowsToLoadFormBotton))) {
        self.loadGists(url: nextPage)
      }
    }
    
    return cell
  }

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    // Return false if you do not want the specified item to be editable.
    return false
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
        gists.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    } else if editingStyle == .insert {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
  }


}

