//
//  LMFeedPostDocumentCell.swift
//  LMFramework
//
//  Created by Devansh Mohata on 13/12/23.
//

import UIKit

public protocol LMFeedPostDocumentCellProtocol: LMPostWidgetTableViewCellProtocol {
    func didTapShowMoreDocuments(for indexPath: IndexPath)
    func didTapDocument(with url: URL)
}

@IBDesignable
open class LMFeedPostDocumentCell: LMPostWidgetTableViewCell {
    // MARK: Data Model
    public struct ContentModel: LMFeedPostTableCellProtocol {
        public var postID: String
        public var userUUID: String
        public var headerData: LMFeedPostHeaderView.ContentModel
        public var postText: String
        public var topics: LMFeedTopicView.ContentModel
        public let documents: [LMFeedDocumentPreview.ContentModel]
        public var isShowMore: Bool
        public var isShowAllDocuments: Bool
        public var footerData: LMFeedPostFooterView.ContentModel
        public var totalCommentCount: Int
        
        public init( postID: String,
                     userUUID: String,
                     headerData: LMFeedPostHeaderView.ContentModel,
                     topics: LMFeedTopicView.ContentModel?,
                     postText: String?,
                     documents: [LMFeedDocumentPreview.ContentModel],
                     footerData: LMFeedPostFooterView.ContentModel,
                     totalCommentCount: Int,
                     isShowMore: Bool = true,
                     isShowAllDocuments: Bool = false) {
            self.postID = postID
            self.userUUID = userUUID
            self.headerData = headerData
            self.postText = postText ?? ""
            self.topics = topics ?? .init()
            self.documents = documents
            self.footerData = footerData
            self.totalCommentCount = totalCommentCount
            self.isShowMore = isShowMore
            self.isShowAllDocuments = isShowAllDocuments
        }
    }
    
    // MARK: UI Elements
    open private(set) lazy var documentContainerStack: LMStackView = {
        let stack = LMStackView().translatesAutoresizingMaskIntoConstraints()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.distribution = .fill
        stack.spacing = 8
        return stack
    }()
        
    open private(set) lazy var seeMoreDocumentsButton: LMButton = {
        let button = LMButton.createButton(with: "See More", image: nil, textColor: Appearance.shared.colors.appTintColor, textFont: Appearance.shared.fonts.headingFont1, contentSpacing: .init(top: 8, left: 8, bottom: 8, right: 8))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = Appearance.shared.colors.appTintColor
        return button
    }()
    
    
    // MARK: Variables
    public weak var delegate: LMFeedPostDocumentCellProtocol?
    var indexPath: IndexPath?
    
    deinit { }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        print("Document Cell is Dequeued")
    }
    
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        
        contentView.addSubview(containerView)
        containerView.addSubview(contentStack)
        
        [topicFeed, postText, seeMoreButton, documentContainerStack].forEach { subView in
            contentStack.addArrangedSubview(subView)
        }
    }
    
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        
        contentView.pinSubView(subView: containerView)
        containerView.pinSubView(subView: contentStack)
        
        topicFeed.addConstraint(leading: (contentStack.leadingAnchor, 16), trailing: (contentStack.trailingAnchor, -16))
        postText.addConstraint(leading: (contentStack.leadingAnchor, 16), trailing: (contentStack.trailingAnchor, -16))
        documentContainerStack.addConstraint(leading: (contentStack.leadingAnchor, 16), trailing: (contentStack.trailingAnchor, -16))
    }
    
    
    // MARK: setupAppearance
    open override func setupAppearance() {
        super.setupAppearance()
        backgroundColor = Appearance.shared.colors.clear
        contentView.backgroundColor = Appearance.shared.colors.clear
    }
    
    
    // MARK: setupActions
    open override func setupActions() {
        super.setupActions()
        seeMoreDocumentsButton.addTarget(self, action: #selector(didTapSeeMoreDocuments), for: .touchUpInside)
    }
    
    @objc
    open func didTapSeeMoreDocuments() {
        guard let indexPath else { return }
        delegate?.didTapShowMoreDocuments(for: indexPath)
    }
        
    
    // MARK: configure
    open func configure(for indexPath: IndexPath, with data: ContentModel, delegate: LMFeedPostDocumentCellProtocol?) {
        self.indexPath = indexPath
        self.delegate = delegate
        self.actionDelegate = delegate
        
        postID = data.postID
        userUUID = data.userUUID
                
        setupPostText(text: data.postText, showMore: data.isShowMore)
        
        topicFeed.configure(with: data.topics)
        
        topicFeed.isHidden = data.topics.topics.isEmpty
                
        documentContainerStack.removeAllArrangedSubviews()
        
        data.documents.enumerated().forEach { index, document in
            guard index < Constants.shared.number.maxDocumentView || data.isShowAllDocuments else { return }
            let documentView = LMUIComponents.shared.documentPreview.init()
            
            documentView.setHeightConstraint(with: Constants.shared.number.documentPreviewSize)
            
            documentView.configure(with: document, delegate: self)
            documentContainerStack.addArrangedSubview(documentView)
            
            NSLayoutConstraint.activate([
                documentView.leadingAnchor.constraint(equalTo: documentContainerStack.leadingAnchor),
                documentView.trailingAnchor.constraint(equalTo: documentContainerStack.trailingAnchor)
            ])
        }
        
        if data.documents.count > Constants.shared.number.maxDocumentView && !data.isShowAllDocuments {
            seeMoreDocumentsButton.setTitle("+\(data.documents.count - Constants.shared.number.maxDocumentView) more", for: .normal)
            seeMoreDocumentsButton.setImage(nil, for: .normal)
            
            documentContainerStack.addArrangedSubview(seeMoreDocumentsButton)
            
            NSLayoutConstraint.activate([
                seeMoreDocumentsButton.leadingAnchor.constraint(equalTo: documentContainerStack.leadingAnchor)
            ])
        }
    }
}


// MARK: LMFeedDocumentPreviewProtocol
@objc
extension LMFeedPostDocumentCell: LMFeedDocumentPreviewProtocol {
    public func didTapDocument(documentID: URL) {
        delegate?.didTapDocument(with: documentID)
    }
}
