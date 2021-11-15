//
//  HomeViewController.swift
//  TurnTune
//
//  Created by Louis Menacho on 6/18/20.
//  Copyright © 2020 Louis Menacho. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
        
    @IBOutlet weak var appearanceSwitch: SwitchControl!
    @IBOutlet weak var sessionFormView: SessionFormView!
    @IBOutlet weak var sessionFormViewCenterY: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appearanceSwitch.delegate = self
        sessionFormView.delegate = self
        addKeyboardObserver()
    }
    
    private func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRect = keyboardFrame.cgRectValue
            UIView.animate(withDuration: 0.1) { [self] in
                sessionFormViewCenterY.constant = -(keyboardRect.height - 34)/2
                view.layoutIfNeeded()
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.1) { [self] in
            sessionFormViewCenterY.constant = 0
            view.layoutIfNeeded()
        }
    }
    
    @IBAction func viewTapped(_ sender: UITapGestureRecognizer) {
        print("viewTapped")
        view.endEditing(true)
    }
}

extension HomeViewController: SwitchControlDelegate {
    func switchControl(_ switchControl: SwitchControl, didToggle isOn: Bool) {
        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = isOn ? .light : .dark
        }
    }
}

extension HomeViewController: SessionFormViewDelegate {
    
    func sessionFormView(_ sessionFormView: SessionFormView, selectedSegmentDidChange selectedSegmentIndex: Int) {
        
    }
    
    func sessionFormView(_ sessionFormView: SessionFormView, displayNameTextFieldDidChange text: String?) {
        
    }
    
    func sessionFormView(_ sessionFormView: SessionFormView, roomCodeTextFieldDidChange text: String?) {
        
    }
    
    func sessionFormView(_ sessionFormView: SessionFormView, joinButtonPressed button: UIButton) {
        
    }
    
    func sessionFormView(_ sessionFormView: SessionFormView, spotifyButtonPressed button: UIButton) {
        
    }
}
