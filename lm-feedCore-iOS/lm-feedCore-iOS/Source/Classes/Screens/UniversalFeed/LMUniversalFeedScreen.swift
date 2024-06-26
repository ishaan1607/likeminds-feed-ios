//
//  LMUniversalFeedScreen.swift
//  LMFramework
//
//  Created by Devansh Mohata on 28/11/23.
//

import LikeMindsFeedUI
import UIKit

open class LMUniversalFeedScreen: LMViewController {
    // MARK: UI Elements
    
    open private(set) lazy var contentStack: LMStackView = {
        let stack = LMStackView().translatesAutoresizingMaskIntoConstraints()
        stack.backgroundColor = Appearance.shared.colors.clear
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 4
        return stack
    }()
    
    open private(set) lazy var topicContainerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = Appearance.shared.colors.white
        return view
    }()
    
    open private(set) lazy var topicStackView: LMStackView = {
        let stack = LMStackView().translatesAutoresizingMaskIntoConstraints()
        stack.backgroundColor = Appearance.shared.colors.white
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 8
        return stack
    }()
    
    open private(set) lazy var topicSelectionButton: LMButton = {
        let button = LMButton().translatesAutoresizingMaskIntoConstraints()
        button.setTitle(Constants.shared.strings.allTopics, for: .normal)
        button.setImage(Constants.shared.images.downArrow, for: .normal)
        button.setFont(Appearance.shared.fonts.buttonFont2)
        button.setTitleColor(Appearance.shared.colors.gray102, for: .normal)
        button.tintColor = Appearance.shared.colors.gray102
        button.semanticContentAttribute = .forceRightToLeft
        return button
    }()
    
    open private(set) lazy var topicCollection: LMCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = .init(width: 100, height: 30)
        
        let collection = LMCollectionView(frame: .zero, collectionViewLayout: layout).translatesAutoresizingMaskIntoConstraints()
        collection.dataSource = self
        collection.delegate = self
        collection.registerCell(type: LMUIComponents.shared.topicFeedEditView)
        collection.showsHorizontalScrollIndicator = false
        collection.showsVerticalScrollIndicator = false
        collection.backgroundColor = Appearance.shared.colors.clear
        return collection
    }()
    
    open private(set) lazy var clearButton: LMButton = {
        let button = LMButton().translatesAutoresizingMaskIntoConstraints()
        button.setFont(Appearance.shared.fonts.buttonFont2)
        button.setTitleColor(Appearance.shared.colors.gray102, for: .normal)
        button.setTitle("Clear", for: .normal)
        button.setImage(nil, for: .normal)
        button.tintColor = Appearance.shared.colors.gray102
        return button
    }()
    
    open private(set) lazy var postList: LMFeedPostListScreen? = {
        do {
            let vc = try LMFeedPostListViewModel.createModule(with: self)
            return vc
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
    }()
    
    open private(set) lazy var createPostButton: LMButton = {
        let button = LMButton.createButton(
            with: "Create Post",
            image: Constants.shared.images.createPostIcon,
            textColor: Appearance.shared.colors.white,
            textFont: Appearance.shared.fonts.buttonFont1,
            contentSpacing: .init(top: 8, left: 8, bottom: 8, right: 8),
            imageSpacing: 8
        )
        button.tintColor = Appearance.shared.colors.appTintColor
        button.backgroundColor = Appearance.shared.colors.appTintColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    open private(set) lazy var createPostLoaderView: LMFeedAddMediaPreview = {
        let view = LMFeedAddMediaPreview().translatesAutoresizingMaskIntoConstraints()
        return view
    }()
    
    
    // MARK: Data Variables
    public var data: [LMFeedPostTableCellProtocol] = []
    public var selectedTopics: [LMFeedTopicCollectionCellDataModel] = []
    public var isShowCreatePost: Bool = false
    public var isPostCreationInProgress: Bool = false
    public var viewModel: LMUniversalFeedViewModel?
    public weak var feedListDelegate: LMFeedPostListVCToProtocol?
    public var createPostButtonWidth: NSLayoutConstraint?
    public var lastVelocityYSign = 0
    
    // MARK: viewDidLoad
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        createPostLoaderView.isHidden = true
        topicContainerView.isHidden = true
        viewModel?.initialSetup()
    }
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        view.addSubview(contentStack)
        view.addSubview(createPostButton)
        
        contentStack.addArrangedSubview(createPostLoaderView)
        contentStack.addArrangedSubview(topicContainerView)
        if let postList {
            addChild(postList)
            contentStack.addArrangedSubview(postList.view)
            postList.didMove(toParent: self)
        }
        
        topicContainerView.addSubview(topicStackView)
        topicStackView.addArrangedSubview(topicSelectionButton)
        topicStackView.addArrangedSubview(topicCollection)
        topicStackView.addArrangedSubview(clearButton)
    }
    
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        
        view.pinSubView(subView: contentStack)
        
        topicStackView.addConstraint(top: (topicContainerView.topAnchor, 0),
                                     bottom: (topicContainerView.bottomAnchor, 0),
                                     leading: (topicContainerView.leadingAnchor, 16))
        
        topicCollection.addConstraint(top: (topicStackView.topAnchor, 0),
                                      bottom: (topicStackView.bottomAnchor, 0))
        
        createPostButton.addConstraint(bottom: (view.safeAreaLayoutGuide.bottomAnchor, -16),
                                       trailing: (view.safeAreaLayoutGuide.trailingAnchor, -16))
        NSLayoutConstraint.activate([
            topicStackView.trailingAnchor.constraint(lessThanOrEqualTo: topicContainerView.trailingAnchor, constant: -16),
        ])
        
        createPostLoaderView.setHeightConstraint(with: 64)
        topicContainerView.setHeightConstraint(with: 50)
        createPostButton.setHeightConstraint(with: 50)
        topicCollection.setWidthConstraint(with: 100, relatedBy: .greaterThanOrEqual)
        topicCollection.setWidthConstraint(with: 500, priority: .defaultLow)
        
        createPostButtonWidth = createPostButton.setWidthConstraint(with: createPostButton.heightAnchor)
        createPostButtonWidth?.isActive = false
        
        topicSelectionButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        clearButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }
    
    
    // MARK: setupActions
    open override func setupActions() {
        super.setupActions()
        
        topicSelectionButton.addTarget(self, action: #selector(didTapTopicSelection), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(didTapClearButton), for: .touchUpInside)
        createPostButton.addTarget(self, action: #selector(didTapNewPostButton), for: .touchUpInside)
        feedListDelegate = postList
    }
    
    @objc
    open func didTapTopicSelection() {
        do {
            let viewController = try LMFeedTopicSelectionViewModel.createModule(topicEnabledState: false, isShowAllTopicsButton: true, delegate: self)
            navigationController?.pushViewController(viewController, animated: true)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    @objc
    open func didTapClearButton() {
        viewModel?.updateSelectedTopics(with: [])
    }
    
    @objc
    open func didTapNewPostButton() {
        guard isShowCreatePost else { return }
        
        guard !isPostCreationInProgress else {
            showError(with: "A post is already uploading!", isPopVC: false)
            return
        }
        do {
            let viewcontroller = try LMFeedCreatePostViewModel.createModule()
            navigationController?.pushViewController(viewcontroller, animated: true)
            
            LMFeedCore.analytics?.trackEvent(for: .postCreationStarted, eventProperties: [:])
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
    // MARK: setupObservers
    open override func setupObservers() {
        super.setupObservers()
        NotificationCenter.default.addObserver(self, selector: #selector(postCreationInProgress), name: .LMPostCreationStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postCreationSuccessful), name: .LMPostCreated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postError), name: .LMPostEditError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postError), name: .LMPostCreateError, object: nil)
    }
    
    @objc
    open func postCreationInProgress(notification: Notification) {
        let image = notification.object as? UIImage
        createPostLoaderView.isHidden = false
        isPostCreationInProgress = true
        createPostLoaderView.configure(with: image)
    }
    
    @objc
    open func postCreationSuccessful() {
        isPostCreationInProgress = false
        createPostLoaderView.stopAnimating()
        createPostLoaderView.isHidden = true
        feedListDelegate?.loadPostsWithTopics(selectedTopics.map { $0.topicID })
    }
    
    @objc
    open func postError(notification: Notification) {
        isPostCreationInProgress = false
        createPostLoaderView.stopAnimating()
        createPostLoaderView.isHidden = true
        
        if let error = notification.object as? LMFeedError {
            showError(with: error.localizedDescription)
        }
    }
    
    // MARK: setupAppearance
    open override func setupAppearance() {
        super.setupAppearance()
        view.backgroundColor = Appearance.shared.colors.backgroundColor
        createPostButton.layer.cornerRadius = createPostButton.frame.height / 2
    }
    
    
    // MARK: setupNavigationBar
    open override func setupNavigationBar() {
        super.setupNavigationBar()
        
        navigationController?.navigationBar.backgroundColor = Appearance.shared.colors.navigationBackgroundColor
        setNavigationTitleAndSubtitle(with: LMStringConstants.shared.appName, subtitle: nil, alignment: .center)
        
        navigationItem.rightBarButtonItems = [UIBarButtonItem(image: Constants.shared.images.personIcon, style: .plain, target: nil, action: nil),
                                              UIBarButtonItem(image: Constants.shared.images.notificationBell, style: .plain, target: self, action: #selector(didTapNotificationButton))]
    }
    
    @objc
    open func didTapNotificationButton() {
        let viewcontroller = LMFeedNotificationFeedViewModel.createModule()
        navigationController?.pushViewController(viewcontroller, animated: true)
    }
}


// MARK: UICollectionView
extension LMUniversalFeedScreen: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        selectedTopics.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(with: LMUIComponents.shared.topicFeedEditView, for: indexPath),
           let data = selectedTopics[safe: indexPath.row] {
            cell.configure(with: data, delegate: self)
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = selectedTopics[indexPath.row].topic.sizeOfString(with: Appearance.shared.fonts.textFont1)
        return .init(width: size.width + 40, height: 30)
    }
}


// MARK: LMUniversalFeedViewModelProtocol
extension LMUniversalFeedScreen: LMUniversalFeedViewModelProtocol {
    public func setupInitialView(isShowTopicFeed: Bool, isShowCreatePost: Bool) {
        self.isShowCreatePost = isShowCreatePost
        createPostButton.backgroundColor = isShowCreatePost ? Appearance.shared.colors.appTintColor : Appearance.shared.colors.gray51
        
        topicContainerView.isHidden = !isShowTopicFeed
        
        if isShowTopicFeed {
            topicSelectionButton.isHidden = !selectedTopics.isEmpty
            topicCollection.isHidden = selectedTopics.isEmpty
            clearButton.isHidden = selectedTopics.isEmpty
        }
    }
    
    public func loadTopics(with topics: [LMFeedTopicCollectionCellDataModel]) {
        self.selectedTopics = topics
        feedListDelegate?.loadPostsWithTopics(selectedTopics.map { $0.topicID })
        
        topicCollection.reloadData()

        topicSelectionButton.isHidden = !topics.isEmpty
        topicCollection.isHidden = topics.isEmpty
        clearButton.isHidden = topics.isEmpty
    }
}


// MARK: LMFeedTopicSelectionViewProtocol
extension LMUniversalFeedScreen: LMFeedTopicSelectionViewProtocol {
    public func updateTopicFeed(with topics: [LMFeedTopicDataModel]) {
        viewModel?.updateSelectedTopics(with: topics)
    }
}


// MARK: LMFeedTopicViewCellProtocol
@objc
extension LMUniversalFeedScreen: LMFeedTopicViewCellProtocol {
    open func didTapCrossButton(for topicId: String) {
        viewModel?.removeTopic(id: topicId)
    }
}

// MARK: LMFeedPostListVCFromProtocol
@objc
extension LMUniversalFeedScreen: LMFeedPostListVCFromProtocol {
    open func onPostListScrolled(_ scrollView: UIScrollView) {
        let currentVelocityY =  scrollView.panGestureRecognizer.velocity(in: scrollView.superview).y
        let currentVelocityYSign = Int(currentVelocityY).signum()
        if currentVelocityYSign != lastVelocityYSign &&
            currentVelocityYSign != 0 {
            lastVelocityYSign = currentVelocityYSign
        }
        
        if lastVelocityYSign < 0,
           createPostButtonWidth?.isActive != true {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: { [weak self] in
                self?.createPostButton.setTitle("", for: .normal)
                self?.createPostButtonWidth?.isActive = true
                self?.createPostButton.layoutIfNeeded()
            }, completion: nil)
        } else if lastVelocityYSign > 0,
                  createPostButtonWidth?.isActive != false {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: { [weak self] in
                self?.createPostButton.setTitle("Create Post", for: .normal)
                self?.createPostButtonWidth?.isActive = false
                self?.createPostButton.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    open func onPostDataFetched(isEmpty: Bool) {
        createPostButton.isHidden = isEmpty
    }
}
