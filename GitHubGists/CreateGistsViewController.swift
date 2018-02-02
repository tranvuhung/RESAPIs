//
//  CreateGistsViewController.swift
//  GitHubGists
//
//  Created by Trần Vũ Hưng on 2/1/18.
//  Copyright © 2018 Tran Vu Hung. All rights reserved.
//

import Foundation
import XLForm

class CreateGistsViewController: XLFormViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
  }
  
  required init!(coder aDecoder: NSCoder!) {
    super.init(coder: aDecoder)
    self.initializeForm()
  }
  
  override init!(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    self.initializeForm()
  }
  
  func initializeForm() {
    let form = XLFormDescriptor(title: "Gist")
    
    let section1 = XLFormSectionDescriptor.formSection() as XLFormSectionDescriptor
    form.addFormSection(section1)
    
    let descriptionRow = XLFormRowDescriptor(tag: "description", rowType: XLFormRowDescriptorTypeText, title: "Description")
    descriptionRow.isRequired = true
    section1.addFormRow(descriptionRow)
    
    let isPublicRow = XLFormRowDescriptor(tag: "isPublic", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: "Public?")
    isPublicRow.isRequired = false
    section1.addFormRow(isPublicRow, afterRow: descriptionRow)
    
    let section2 = XLFormSectionDescriptor.formSection(withTitle: "File 1") as XLFormSectionDescriptor
    form.addFormSection(section2)
    
    let fileNameRow = XLFormRowDescriptor(tag: "fileName", rowType: XLFormRowDescriptorTypeText, title: "File Name")
    fileNameRow.isRequired = true
    section2.addFormRow(fileNameRow)
    
    let fileContentRow = XLFormRowDescriptor(tag: "fileContent", rowType: XLFormRowDescriptorTypeTextView, title: "File Content")
    fileContentRow.isRequired = true
    section2.addFormRow(fileContentRow, afterRow: fileNameRow)
    
    self.form = form
  }
  
  func cancel(sender: UIBarButtonItem){
    self.navigationController?.popViewController(animated: true)
  }
  
  func save(sender: UIBarButtonItem){
    let validationError = self.formValidationErrors() as? [NSError]
    if validationError!.count > 0 {
      self.showFormValidationError(validationError!.first)
      return
    }
    self.tableView.endEditing(true)
    let isPublic: Bool
    if let isPublicValue = form.formRow(withTag: "isPublic")?.value as? Bool {
      isPublic = isPublicValue
    } else{
      isPublic = false
    }
    guard let description = form.formRow(withTag: "description")?.value as? String, let fileName = form.formRow(withTag: "fileName")?.value as? String, let fileContent = form.formRow(withTag: "fileContent")?.value as? String else { return }
    
    var files = [File]()
    if let file = File(name: fileName, content: fileContent){
      files.append(file)
    }
    
    GitHubAPIManager.sharedIntance.createNewGist(description: description, isPublic: isPublic, files: files, completionHandler: { (result) in
      guard result.error == nil, result.value == true else {
        if let error = result.error{
          print(error)
        }
        let alertController = UIAlertController(title: "Could not create gist", message: "Sorry, your gist couldn't be deleted. Maybe GitHub is down or you don't have an internet connection.", preferredStyle: .alert)
        // add ok button
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
        return
      }
      print(result.value!)
      self.navigationController?.popViewController(animated: true)
    })
  }
}
