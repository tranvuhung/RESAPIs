//
//  MasterViewController.swift
//  GitHubGists
//
//  Created by Trần Vũ Hưng on 1/17/18.
//  Copyright © 2018 Tran Vu Hung. All rights reserved.
//

import UIKit
import PINRemoteImage
import SafariServices

class MasterViewController: UITableViewController {

  //MARK: - Properties
  var detailViewController: DetailViewController? = nil
  var objects = [Any]()
  var gists = [Gist]()
  var nextPageUrl: String?
  var isLoading = false
  var dateFormatter = DateFormatter()
  var safariViewController: SFSafariViewController?
  
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
    
    let defaults = UserDefaults.standard
    if (!defaults.bool(forKey: "loadingOAuthToken")) {
      loadInitialData()
    }
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
    let defaults = UserDefaults.standard
    defaults.set(false, forKey: "loadingOAuthToken")
    nextPageUrl = nil // so it doesn't try to append the results
    loadInitialData()
  }
  
  //MARK: - Load Gist
  func loadGists(_ url: String?) {
    isLoading = true
    GitHubAPIManager.sharedIntance.getMyStarredGists(url) { (result, nextPage) in
      self.isLoading = false
      self.nextPageUrl = nextPage
      //print(nextPage!)
      
      if (self.refreshControl != nil && self.refreshControl!.isRefreshing){
        self.refreshControl?.endRefreshing()
      }
      
      guard result.error == nil else {
        print("Lêu Lêu - lỗi 401 - Unauthorized")
        print(result.error!)
        self.nextPageUrl = nil
        self.isLoading = false
        self.showAuthLoginView()
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
  
  //MARK: - Check if Token
  func loadInitialData(){
    isLoading = true
    GitHubAPIManager.sharedIntance.oauthTokenCompletionHandler = { error in
      self.safariViewController?.dismiss(animated: true, completion: nil)
      if let error = error{
        print(error)
        self.isLoading = false
        // TODO: handle error
        // Something went wrong, try again
        self.showAuthLoginView()
      } else {
        self.loadGists(nil)
      }
    }
    if !GitHubAPIManager.sharedIntance.hasAuthToken() {
      //TODO: Show auth login view
      showAuthLoginView()
    } else {
      loadGists(nil)
    }
  }
  
  //MARK: - Auth login view
  func showAuthLoginView(){
    //let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
    if let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
      loginVC.delegate = self
      self.present(loginVC, animated: true, completion: nil)
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
        self.loadGists(nextPage)
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

extension MasterViewController: LoginViewDelegate {
  func didTapLoginButton() {
    //TODO: - Set loadingOAutho token
    let defaults = UserDefaults.standard
    defaults.set(true, forKey: "loadingOAuthToken")
    
    self.dismiss(animated: false, completion: nil)
    //TODO: - show web page
    if let url = GitHubAPIManager.sharedIntance.urlToStartAuth2Login(){
      self.safariViewController = SFSafariViewController(url: url)
      self.safariViewController?.delegate = self
      guard let webViewController = self.safariViewController else {return}
      self.present(webViewController, animated: true, completion: nil)
    } else {
      defaults.set(false, forKey: "loadingOAuthToken")
      if let completionHandler = GitHubAPIManager.sharedIntance.oauthTokenCompletionHandler {
        let error = NSError(domain: GitHubAPIManager.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create an OAuth authorization URL", NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
        completionHandler(error)
      }
    }
  }
}

extension MasterViewController: SFSafariViewControllerDelegate {
  func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
    if !didLoadSuccessfully {
      // TODO: handle this better
      let defaults = UserDefaults.standard
      defaults.set(false, forKey: "loadingOAuthToken")
      
      if let conpletionHandler = GitHubAPIManager.sharedIntance.oauthTokenCompletionHandler {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: "No Internet Connection", NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
        conpletionHandler(error)
      }
      controller.dismiss(animated: true, completion: nil)
    }
  }
}
