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
import Alamofire
import BRYXBanner

class MasterViewController: UITableViewController {
  
  //MARK: IBOutlet
  @IBOutlet weak var segmentedController: UISegmentedControl!

  //MARK: - Properties
  var detailViewController: DetailViewController? = nil
  var gists = [Gist]()
  var nextPageUrl: String?
  var isLoading = false
  var dateFormatter = DateFormatter()
  var safariViewController: SFSafariViewController?
  var notConnectedBanner: Banner?
  
  //MARK: - Life cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
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
  
  //MARK: - dismiss the banner when we change views
  override func viewWillDisappear(_ animated: Bool) {
    if let existingBanner = self.notConnectedBanner {
      existingBanner.dismiss()
    }
    super.viewWillDisappear(animated)
  }

  //MARK: - Creation
  func insertNewObject(_ sender: Any) {
    let createVC = CreateGistsViewController(nibName: nil, bundle: nil)
    self.navigationController?.pushViewController(createVC!, animated: true)
  }
  
  //MARK: - Segmented Action
  @IBAction func segmentedValueChanged(_ sender: Any) {
    // only show add button for my gists
    if segmentedController.selectedSegmentIndex == 2 {
      navigationItem.leftBarButtonItem = self.editButtonItem
      let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject))
      navigationItem.rightBarButtonItem = addButton
    } else {
      navigationItem.leftBarButtonItem = nil
      navigationItem.rightBarButtonItem = nil
    }
    // clear gists so they can't get shown for the wrong list
    self.gists = [Gist]()
    self.tableView.reloadData()
    loadGists(nil)
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
    isLoading = false
    let completionHandler: (Result<[Gist]>, String?) -> () = { (result, nextPage) in
      self.isLoading = false
      self.nextPageUrl = nextPage
      
      if (self.refreshControl != nil && self.refreshControl!.isRefreshing){
        self.refreshControl?.endRefreshing()
      }
      
      guard result.error == nil else {
        print("Lêu Lêu - lỗi 401 - Unauthorized")
        print(result.error!)
        self.nextPageUrl = nil
        self.isLoading = false
        
        if let error = result.error as NSError? {
          if error.domain == NSURLErrorDomain{
            if error.code == NSURLErrorUserAuthenticationRequired{
              self.showAuthLoginView()
            } else if error.code == NSURLErrorNotConnectedToInternet{
              //Load gists if not internet connection
              let path: Path
              if self.segmentedController.selectedSegmentIndex == 0 {
                path = .Public
              } else if self.segmentedController.selectedSegmentIndex == 1 {
                path = .Starred
              } else {
                path = .MyGists
              }
              if let archived: [Gist] = PersistenceManager.loadArray(path: path){
                self.gists = archived
              } else {
                self.gists = []  // don't have any saved gists
              }
              
              // show banner
              if let existingBanner = self.notConnectedBanner{
                existingBanner.dismiss()
              }
              self.notConnectedBanner = Banner(title: "No Internet Connection", subtitle: "Could not load gists. Try again when you're connected to the internet", image: nil, backgroundColor: .red, didTapBlock: nil)
              self.notConnectedBanner?.dismissesOnSwipe = true
              self.notConnectedBanner?.show()
            }
          }
        }
        
        
        return
      }
      if let gists = result.value {
        if url != nil /* nextPageUrl != nil */ {
          self.gists += gists
        } else {
          self.gists = gists
        }
        let path: Path
        if self.segmentedController.selectedSegmentIndex == 0 {
          path = .Public
        } else if self.segmentedController.selectedSegmentIndex == 1 {
          path = .Starred
        } else {
          path = .MyGists
        }
        PersistenceManager.saveArray(toSave: self.gists, path: path)
      }
      
      // update "last updated" title for refresh control
      let now = Date()
      let updateString = "Last update at: \(self.dateFormatter.string(from: now))"
      self.refreshControl?.attributedTitle = NSAttributedString(string: updateString)
      self.tableView.reloadData()
    }
    
    switch segmentedController.selectedSegmentIndex {
    case 0:
      GitHubAPIManager.sharedIntance.getPublicGists(url, completionHandler: completionHandler)
    case 1:
      GitHubAPIManager.sharedIntance.getMyStarredGists(url, completionHandler: completionHandler)
    case 2:
      GitHubAPIManager.sharedIntance.getMyGists(url, completionHandler: completionHandler)
    default:
      print("got an index that I didn't expect for selectedSegmentIndex")
    }
    
  }
  
  //MARK: - Check if Token
  func loadInitialData(){
    isLoading = true
    GitHubAPIManager.sharedIntance.oauthTokenCompletionHandler = { error in
      self.safariViewController?.dismiss(animated: true, completion: nil)
      if let error = error as NSError?{
        print(error)
        self.isLoading = false
        // TODO: handle error
        if error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet{
          if let existingBanner = self.notConnectedBanner{
            existingBanner.dismiss()
          }
          self.notConnectedBanner = Banner(title: "No Internet Connection", subtitle: "Could not load gists. Try again when you're connected to the internet", image: nil, backgroundColor: .red, didTapBlock: nil)
          self.notConnectedBanner?.dismissesOnSwipe = true
          self.notConnectedBanner?.show()
        } else {
          // Something went wrong, try again
          self.showAuthLoginView()
        }
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
            let gist = gists[indexPath.row] 
            let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
            controller.gist = gist
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
    cell.textLabel?.text = gist.gistDescription
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
    return segmentedController.selectedSegmentIndex == 2
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let gistDelete = gists.remove(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
      //Delete form API
      guard let id = gists[indexPath.row].id else {return}
      GitHubAPIManager.sharedIntance.deleteGist(gistId: id, completionHandler: { (error) in
        if error != nil {
          print(error!)
          //put it back
          self.gists.insert(gistDelete, at: indexPath.row)
          self.tableView.insertRows(at: [indexPath], with: .right)
          // tell them it didn't work
          let alertController = UIAlertController(title: "Could not delete gist",
                                                  message: "Sorry, your gist couldn't be deleted. Maybe GitHub is down or you don't have an internet connection.",preferredStyle: .alert)
          // add ok button
          let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
          alertController.addAction(okAction)
          self.present(alertController, animated: true, completion: nil)
        }
      })
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
      //let defaults = UserDefaults.standard
      //defaults.set(false, forKey: "loadingOAuthToken")
      
      if let conpletionHandler = GitHubAPIManager.sharedIntance.oauthTokenCompletionHandler {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: "No Internet Connection", NSLocalizedRecoverySuggestionErrorKey: "Please retry your request"])
        conpletionHandler(error)
      }
      controller.dismiss(animated: true, completion: nil)
    }
  }
}
