//
//  ChatMessageViewController.swift
//  Umbrella
//
//  Created by Lucas Correa on 25/06/2019.
//  Copyright © 2019 Security First. All rights reserved.
//

import UIKit

class ChatMessageViewController: UIViewController {
    
    //
    // MARK: - Properties
    
    @IBOutlet weak var messageText: UITextField!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var sendButtonWidthConstraint: NSLayoutConstraint!
    
    var chatRequestNavigationController: UINavigationController!
    var timer: Timer?
    var isScrollBottom: Bool = false
    
    lazy var chatMessageViewModel: ChatMessageViewModel = {
        let chatMessageViewModel = ChatMessageViewModel()
        return chatMessageViewModel
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardNotification(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        
        self.title = self.chatMessageViewModel.room.name
        self.loadMessages()
        
        self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(loadMessages), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            UserDefaults.standard.set(nil, forKey: self.chatMessageViewModel.room.roomId)
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    @objc func loadMessages() {
        self.chatMessageViewModel.getMessages(success: { (messages) in
            if self.isScrollBottom {
                self.chatTableView.scrollToBottomRow()
            }
            self.chatTableView.reloadData()
        }, failure: { (response, object, error) in
            print(error ?? "")
        })
    }
    
    /// Keyboard notification when change the frame
    ///
    /// - Parameter notification: NSNotification
    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let endFrameY = endFrame?.origin.y ?? 0
            let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
            if endFrameY >= UIScreen.main.bounds.size.height {
                self.bottomConstraint?.constant = 0.0
                self.sendButtonWidthConstraint.constant = 0
            } else {
                // 812 on iPhone X, XS
                // 896 on iPhone XS Max or XR
                if UIScreen.main.bounds.height >= 812 {
                    self.bottomConstraint?.constant = (endFrame?.size.height)! - 84
                } else {
                    self.bottomConstraint?.constant = (endFrame?.size.height)! - 48
                }
                
                self.sendButtonWidthConstraint.constant = 45
            }
            
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    
    @IBAction func sendAction(_ sender: Any) {
        
        let message = self.messageText.text!
        
        self.view.endEditing(true)
        self.messageText.text = ""
        
        if message.count == 0 {
            return
        }
        
        self.chatMessageViewModel.sendMessage(messageType: .text,
                                              message: message,
                                              url: "",
                                              success: { _ in
                                                
                                                //to do a request to update the list of message
                                                self.loadMessages()
        }, failure: { (response, object, error) in
            print(error ?? "")
        })
    }
    
    @IBAction func moreAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Chat", bundle: Bundle.main)
        self.chatRequestNavigationController = (storyboard.instantiateViewController(withIdentifier: "ChatRequestNavigationController") as? UINavigationController)!
        self.chatRequestNavigationController.modalPresentationStyle = .popover
        self.chatRequestNavigationController.preferredContentSize = CGSize(width: 300, height: 250)
        
        let chatRequestViewController = (chatRequestNavigationController.viewControllers.first! as? ChatRequestViewController)!
        chatRequestViewController.chatRequestViewModel.userLogged = self.chatMessageViewModel.userLogged
        chatRequestViewController.chatRequestViewModel.room = self.chatMessageViewModel.room
        let presentationController = (self.chatRequestNavigationController.presentationController as? UIPopoverPresentationController)!
        presentationController.delegate = self
        presentationController.backgroundColor = #colorLiteral(red: 0.5934140086, green: 0.7741840482, blue: 0.2622931898, alpha: 1)
        presentationController.sourceView = (sender as? UIView)!
        presentationController.sourceRect = (sender as? UIView)!.bounds
        presentationController.permittedArrowDirections = [.down, .up]
        self.present(self.chatRequestNavigationController, animated: true)
    }
}

extension ChatMessageViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // return UIModalPresentationStyle.FullScreen
        return UIModalPresentationStyle.none
    }
}

extension ChatMessageViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.chatMessageViewModel.messages.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatMessageViewModel.messages[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as? ChatMessageCell)!
        cell.configure(withViewModel: self.chatMessageViewModel, indexPath: indexPath)
        return cell
    }
    
}

extension ChatMessageViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let firstMessageInSection = self.chatMessageViewModel.messages[section].first {
            
            let label = DateHeaderLabel()
            label.text = firstMessageInSection.dateFromMilliseconds()
            
            let containerView = UIView()
            
            containerView.addSubview(label)
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
            
            return containerView
            
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
}

//
// MARK: - UIScrollViewDelegate
extension ChatMessageViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView.frame.size.height + scrollView.contentOffset.y >= scrollView.contentSize.height {
            self.isScrollBottom = true
        } else {
            self.isScrollBottom = false
        }
    }
}