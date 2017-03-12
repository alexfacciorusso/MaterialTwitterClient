//
//  TweetDetailViewController.swift
//  MaterialTwitterClient
//
//  Created by Alex Facciorusso on 11/03/17.
//  Copyright © 2017 Alex Facciorusso. All rights reserved.
//

import UIKit
import Nuke
import NukeToucanPlugin
import MaterialComponents
import PureLayout


class TweetDetailViewController: UIViewController {
    let verticalContentPadding: CGFloat = 16
    let horizontalContentPadding: CGFloat = 16
    let fabMargin: CGFloat = 16
    
    let scrollView = UIScrollView.newAutoLayout()
    let contentView = UIView.newAutoLayout()
    let avatar = UIImageView.newAutoLayout()
    let displayName = UILabel.newAutoLayout()
    let twitterName = UILabel.newAutoLayout()
    let text = UILabel.newAutoLayout()
    let fab = MDCFloatingButton.newAutoLayout()
    
    let appBar = MDCAppBar()
    
    var didSetupConstraints = false
    var tweet: Tweet!
    
    init(fromTweet tweet: Tweet) {
        super.init(nibName: nil, bundle: nil)
        
        self.tweet = tweet
        title = "Tweet by @\(tweet.screenName)"
        
        self.addChildViewController(appBar.headerViewController)
    }
    
    convenience init() {
        self.init()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor.white

        view.addSubview(scrollView)
        view.addSubview(fab)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(avatar)
        contentView.addSubview(displayName)
        contentView.addSubview(twitterName)
        contentView.addSubview(text)
        
        appBar.headerViewController.headerView.backgroundColor = MaterialTwitterClient.colorPrimary
        appBar.navigationBar.tintColor = UIColor.white
        appBar.navigationBar.titleTextAttributes =
            [ NSForegroundColorAttributeName: UIColor.white ]
        
        contentView.layoutMargins = UIEdgeInsets(top: verticalContentPadding, left: horizontalContentPadding, bottom: verticalContentPadding, right: horizontalContentPadding)
        
        fab.setImage(#imageLiteral(resourceName: "ic_reply_white"), for: .normal)
        fab.backgroundColor = MaterialTwitterClient.colorAccent
        fab.addTarget(self, action: #selector(handleFabClicked), for: .touchUpInside)
        
        MDCOverlayObserver(for: nil).addTarget(self, action: #selector(handleOverlayTransition))
        
        displayName.font = MDCTypography.body1Font()
        displayName.alpha = MDCTypography.body1FontOpacity()
        
        twitterName.font = MDCTypography.captionFont()
        twitterName.alpha = MDCTypography.body1FontOpacity()
        twitterName.textColor = MaterialTwitterClient.colorAccent
        
        text.font = MDCTypography.body1Font()
        text.alpha = MDCTypography.body1FontOpacity()
        
        text.tintColor = MaterialTwitterClient.colorAccent
        
        view.setNeedsUpdateConstraints()
    }
    
    func handleFabClicked() {
        let message = MDCSnackbarMessage(text: "This client is too lazy to have a retweet function. 😒")!
        let action = MDCSnackbarMessageAction()
        action.title = "OK"
        message.buttonTextColor = MaterialTwitterClient.colorAccent
        message.action = action
        message.duration = 5.0
        MDCSnackbarManager.show(message)
    }
    
    func handleOverlayTransition(_ transition: MDCOverlayTransitioning) {
        let bounds: CGRect = self.view.bounds
        let coveredRect: CGRect = transition.compositeFrame(in: self.view)
        // Trim the covered rectangle to only consider the current view's bounds.
        let boundedRect: CGRect = bounds.intersection(coveredRect)
        // How much should we shift the FAB up by.
        var fabVerticalShift: CGFloat = 0
        if !boundedRect.isEmpty {
            // Calculate how far from the bottom of the current view the overlay goes. All we really care
            // about is the absolute top of all overlays, we'll put the FAB above that point.
            let distanceFromBottom: CGFloat = bounds.maxY - boundedRect.minY
            // We're applying a transform to the FAB, so no need to account for padding or such.
            fabVerticalShift = distanceFromBottom
        }
        transition.animate(alongsideTransition: {() -> Void in
            if fabVerticalShift > 0 {
                self.fab.transform = CGAffineTransform(translationX: 0, y: -fabVerticalShift)
            }
            else {
                self.fab.transform = CGAffineTransform.identity
            }
        })
    }
    
    override func updateViewConstraints() {
        guard !didSetupConstraints else { return }
        
        scrollView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)
        
        contentView.autoPinEdgesToSuperviewEdges()
        contentView.autoMatch(.width, to: .width, of: view)
        
        avatar.autoPinEdge(toSuperviewMargin: .top)
        avatar.autoPinEdge(toSuperviewMargin: .leading)
        avatar.autoSetDimensions(to: CGSize(width: 60, height: 60))
        
        displayName.autoAlignAxis(.horizontal, toSameAxisOf: avatar)
        displayName.autoPinEdge(.leading, to: .trailing, of: avatar, withOffset: horizontalContentPadding)
        
        twitterName.autoAlignAxis(.firstBaseline, toSameAxisOf: displayName)
        twitterName.autoPinEdge(.leading, to: .trailing, of: displayName, withOffset: 8)
        
        text.autoPinEdges(toSuperviewMarginsExcludingEdge: .top)
        text.autoPinEdge(.top, to: .bottom, of: avatar, withOffset: 16)
        
        fab.sizeToFit()
        fab.autoPinEdge(toSuperviewEdge: .trailing, withInset: fabMargin)
        fab.autoPinEdge(toSuperviewEdge: .bottom, withInset: fabMargin)
        
        didSetupConstraints = true
        super.updateViewConstraints()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appBar.addSubviewsToParent()
        
        appBar.headerViewController.headerView.trackingScrollView = self.scrollView
        self.scrollView.delegate = appBar.headerViewController
        
        let backButton = UIBarButtonItem(title:"",
                                         style:.plain,
                                         target:self,
                                         action:#selector(dismissMyself))
        let backImage = UIImage(named:MDCIcons.pathFor_ic_arrow_back())?.withRenderingMode(.alwaysTemplate)
        backButton.image = backImage
        appBar.navigationBar.leftBarButtonItem = backButton
        
        updateData()
    }
    
    func dismissMyself() {
        dismiss(animated: true, completion: nil)
    }
    
    func updateData() {
        displayName.text = tweet.name
        twitterName.text = "@\(tweet.screenName)"
        text.setTwitterText(fromString: tweet.text)
        text.numberOfLines = 0
        
        if let avatar = tweet.avatar {
            let request = Nuke.Request(url: avatar).processed(key: "Avatar") {
                return $0.resize(CGSize(width: self.avatar.frame.width, height: self.avatar.frame.height), fitMode: .clip)
                    .maskWithEllipse()
            }
            Nuke.loadImage(with: request, into: self.avatar)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
