//
//  LMFeedConvertToFeedPost.swift
//  likeminds-feed-iOS
//
//  Created by Devansh Mohata on 03/01/24.
//

import LikeMindsFeedUI
import LikeMindsFeed

public struct LMFeedConvertToFeedPost {
    public static func convertToViewModel(for post: LMFeedPostDataModel) -> LMFeedPostTableCellProtocol {
        if let link = post.linkAttachment {
            return convertToLinkViewData(from: post, link: link)
        } else if !post.documentAttachment.isEmpty {
            return convertToDocumentCells(from: post)
        } else {
            return convertToImageVideoCells(from: post)
        }
    }
    
    private static func convertToTopicViewData(from topics: [LMFeedTopicDataModel]) -> LMFeedTopicView.ContentModel {
        let mappedTopics: [LMFeedTopicCollectionCellDataModel] = topics.map {
            .init(topic: $0.topicName, topicID: $0.topicID)
        }
        
        return .init(topics: mappedTopics)
    }
    
    public static func convertToHeaderViewData(from data: LMFeedPostDataModel) -> LMFeedPostHeaderView.ContentModel {
        .init(
            profileImage: data.userDetails.userProfileImage,
            authorName: data.userDetails.userName,
            authorTag: data.userDetails.customTitle,
            subtitle: "\(data.createTime)\(data.isEdited ? " • Edited" : "")",
            isPinned: data.isPinned,
            showMenu: !data.postMenu.isEmpty
        )
    }
    
    public static func convertToFooterViewData(from data: LMFeedPostDataModel) -> LMFeedPostFooterView.ContentModel {
        .init(likeCount: data.likeCount, commentCount: data.commentCount, isSaved: data.isSaved, isLiked: data.isLiked)
    }
    
    public static func convertToLinkViewData(from data: LMFeedPostDataModel, link: LMFeedPostDataModel.LinkAttachment) -> LMFeedPostLinkCell.ContentModel {
        .init(
            postID: data.postId,
            userUUID: data.userDetails.userUUID,
            headerData: convertToHeaderViewData(from: data),
            postText: data.postContent,
            topics: convertToTopicViewData(from: data.topics),
            mediaData: .init(linkPreview: link.previewImage, title: link.title, description: link.description, url: link.url),
            footerData: convertToFooterViewData(from: data), 
            totalCommentCount: data.commentCount
        )
    }
    
    public static func convertToDocumentCells(from data: LMFeedPostDataModel) -> LMFeedPostDocumentCell.ContentModel {
        return .init(
            postID: data.postId,
            userUUID: data.userDetails.userUUID,
            headerData: convertToHeaderViewData(from: data),
            topics: convertToTopicViewData(from: data.topics),
            postText: data.postContent,
            documents: convertToDocument(from: data.documentAttachment),
            footerData: convertToFooterViewData(from: data), 
            totalCommentCount: data.commentCount
        )
    }
    
    public static func convertToDocument(from data: [LMFeedPostDataModel.DocumentAttachment]) -> [LMFeedDocumentPreview.ContentModel] {
        data.compactMap { datum in
            guard let url = URL(string: datum.url) else { return nil }
            
            return .init(
                title: datum.name,
                documentURL: url,
                size: datum.size,
                pageCount: datum.pageCount,
                docType: datum.format
            )
        }
    }
    
    public static func convertToImageVideoCells(from data: LMFeedPostDataModel) -> LMFeedPostMediaCell.ContentModel {
        return .init(
            postID: data.postId,
            userUUID: data.userDetails.userUUID,
            headerData: convertToHeaderViewData(from: data),
            postText: data.postContent,
            topics: convertToTopicViewData(from: data.topics),
            mediaData: convertToMediaProtocol(from: data.imageVideoAttachment),
            footerData: convertToFooterViewData(from: data), 
            totalCommentCount: data.commentCount
        )
    }
    
    public static func convertToMediaProtocol(from data: [LMFeedPostDataModel.ImageVideoAttachment]) -> [LMFeedMediaProtocol] {
        data.map { datum in
            if datum.isVideo {
                return LMFeedVideoCollectionCell.ContentModel(videoURL: datum.url)
            } else {
                return LMFeedImageCollectionCell.ContentModel(image: datum.url)
            }
        }
    }
}
