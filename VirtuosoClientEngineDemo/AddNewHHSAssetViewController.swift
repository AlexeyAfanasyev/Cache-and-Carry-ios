//
//  AddNewHHSAssetViewController.swift
//  VirtuosoClientEngineDemo
//
//  Created by Alexey Afanasyev on 07/09/2017.
//
//

import UIKit

@objc
class AddNewHHSAssetViewController: UIViewController {

    @IBOutlet weak var mediaItemUrlTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Add New HSS Item"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(doCancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(addMediaItem))
        self.edgesForExtendedLayout = []
        self.navigationController?.navigationBar.isTranslucent = false
    }

    @objc private func doCancel() {
        self.navigationController?.popViewController(animated: true)
    }

    @objc private func addMediaItem() {
        self.mediaItemUrlTextField.resignFirstResponder()
        add(mediaItemUrlTextField.text)
    }
    
    fileprivate func add(_ mediaItemUrl: String?) {
        guard let mediaItemUrl = self.mediaItemUrlTextField.text, mediaItemUrl != "" else {
            UIAlertView(title: "Empty URL", message: "Please specify an URL", delegate: nil, cancelButtonTitle: "OK").show()
            return
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        let timestamp = formatter.string(from: Date())
        print("add media item")
        var _ = VirtuosoAsset(assetID: "MediaItem\(timestamp)",
                              description: "LGI Media Item (\(timestamp))",
                              manifestUrl: mediaItemUrl,
                              maximumVideoBitrate: Int64(Int.max),
                              maximumAudioBitrate: Int64(Int.max),
                              publishDate: nil,
                              expiryDate: nil,
                              expiryAfterDownload: 0,
                              expiryAfterPlay: 0,
                              enableFastPlay: false,
                              userInfo: [:],
                              onReadyForDownload: { (asset) in
                                MBProgressHUD.hide(for: self.view, animated: true)
                                guard let asset = asset else {
                                    UIAlertView.init(title: "Asset is nil", message: "This shouln't have happend :(", delegate: nil, cancelButtonTitle: "Continue").show()
                                    return
                                }
                                print("Media item is ready for download:\n\(String(describing: asset))")
                                VirtuosoDownloadEngine.instance().add(toQueue: asset, at: UInt.max, onComplete: nil)
        }) { (asset, error) in
            if let error = error {
                print("Failed to add media item to queue with error:\n\(error)")
                MBProgressHUD.hide(for: self.view, animated: true)
                return
            }
            print("Media item manifest has been parsed:\n\(String(describing: asset))")
        }
        
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

}

extension AddNewHHSAssetViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        add(textField.text)
        return true
    }
}
