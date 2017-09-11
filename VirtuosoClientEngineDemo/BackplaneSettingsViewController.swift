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

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Backplane Settings"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(doCancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveSettings))
        self.edgesForExtendedLayout = []
        self.navigationController?.navigationBar.isTranslucent = false
        
        loadData()
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
