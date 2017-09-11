//
//  BackplaneSettingsViewController.swift
//  VirtuosoClientEngineDemo
//
//  Created by Alexey Afanasyev on 11/09/2017.
//
//

import UIKit

class BackplaneSettingsViewController: UIViewController {

    @IBOutlet weak var backplaneUrlTextField: UITextField!
    @IBOutlet weak var publicKeyTextField: UITextField!
    @IBOutlet weak var privateKeyTextField: UITextField!
    @IBOutlet var scrollView: UIScrollView!
    
    var activeField: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Backplane Settings"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(doCancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveSettings))
        self.edgesForExtendedLayout = []
        self.navigationController?.navigationBar.isTranslucent = false
        
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    @objc private func keyboardWasShown(notification: NSNotification) {
        guard let activeField = activeField else {
            return
        }
        let info = notification.userInfo as NSDictionary?
        guard let kbSize = (info?.object(forKey: UIKeyboardFrameBeginUserInfoKey) as? CGRect)?.size else {
            return
        }
        
        let contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        
        // If active text field is hidden by keyboard, scroll it so it's visible
        // Your app might not need or want this behavior.
        var aRect = self.view.frame;
        aRect.size.height -= kbSize.height;
        if (!aRect.contains(activeField.frame.origin) ) {
            self.scrollView.scrollRectToVisible(activeField.frame, animated: true)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        let contentInsets = UIEdgeInsets.zero;
        scrollView.contentInset = contentInsets;
        scrollView.scrollIndicatorInsets = contentInsets;
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    enum UserDefaultsKeys: String {
        case backplaneURL = "BackplaneURL"
        case publicKey = "PublicKey"
        case privateKey = "PrivateKey"
        case userName = "TestHarnessUserName"
    }
    
    private func loadData() {
        backplaneUrlTextField.text = UserDefaults.standard.object(forKey: UserDefaultsKeys.backplaneURL.rawValue) as? String ?? ""
        publicKeyTextField.text = UserDefaults.standard.object(forKey: UserDefaultsKeys.publicKey.rawValue) as? String ?? ""
        privateKeyTextField.text = UserDefaults.standard.object(forKey: UserDefaultsKeys.privateKey.rawValue) as? String ?? ""
    }
    
    fileprivate func saveData () {
        guard let backplaneUrl = backplaneUrlTextField.text, backplaneUrl != "",
        let privateKey = privateKeyTextField.text, privateKey != "",
        let publicKey = publicKeyTextField.text, publicKey != "" else {
            UIAlertView(title: "Data incomplete", message: "You should fill in all the fields", delegate: nil, cancelButtonTitle: "Continue editing").show()
            return
        }
        
        guard let userName = UserDefaults.standard.object(forKey: UserDefaultsKeys.userName.rawValue) as? String, userName != "" else {
            UIAlertView(title: "User is not specified", message: "User name must not be empty", delegate: nil, cancelButtonTitle: "Continue").show()
            return
        }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        UserDefaults.standard.set(backplaneUrl, forKey: UserDefaultsKeys.backplaneURL.rawValue)
        UserDefaults.standard.set(privateKey, forKey: UserDefaultsKeys.privateKey.rawValue)
        UserDefaults.standard.set(publicKey, forKey: UserDefaultsKeys.publicKey.rawValue)

        if VirtuosoDownloadEngine.instance().started {
            VirtuosoDownloadEngine.instance().shutdown()
            VirtuosoDownloadEngine.instance().startup(withBackplane: backplaneUrl, user: userName, externalDeviceID: nil, privateKey: privateKey, publicKey: publicKey)
        }
        
        MBProgressHUD.hide(for: self.view, animated: true)

        self.navigationController?.popViewController(animated: true)
    }

    @objc private func doCancel() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func saveSettings() {
        saveData()
    }

}

extension BackplaneSettingsViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        activeField = nil
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        switch textField {
        case backplaneUrlTextField:
            publicKeyTextField.becomeFirstResponder()
        case publicKeyTextField:
            privateKeyTextField.becomeFirstResponder()
        default:
            saveData()
        }
        return true
    }
}
