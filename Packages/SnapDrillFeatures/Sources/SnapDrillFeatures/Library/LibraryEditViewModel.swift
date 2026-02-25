//
//  LibraryEditViewModel.swift
//  SnapDrillFeatureLibrary
//
//  Created by SnapDrill Architect on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//

import SwiftUI
import SnapDrillData
import SnapDrillCore

@Observable
@MainActor
public class LibraryEditViewModel {
    public var content: String
    public var answer: String
    public var selectedSubject: String
    public var selectedSource: String
    public var tagList: [String]
    public var difficulty: Int
    
    public var displayedImage: UIImage?
    public var isProcessing = false
    public var isSavedNormally = false
    public var isCropping = false
    public var imageToCrop: UIImage?
    
    // Form Data
    public var subjects: [SubjectModel] = []
    public var sources: [SourceModel] = []
    public var allTags: [TagModel] = []
    
    private let item: ReviewItemModel
    private let reviewRepository: ReviewRepositoryProtocol
    private let subjectRepository: SubjectRepositoryProtocol
    private let sourceRepository: SourceRepositoryProtocol
    private let tagRepository: TagRepositoryProtocol
    private let imageStorage = ImageStorage()
    private let ocrService = OCRService()
    
    public init(
        item: ReviewItemModel,
        reviewRepository: ReviewRepositoryProtocol,
        subjectRepository: SubjectRepositoryProtocol,
        sourceRepository: SourceRepositoryProtocol,
        tagRepository: TagRepositoryProtocol
    ) {
        self.item = item
        self.reviewRepository = reviewRepository
        self.subjectRepository = subjectRepository
        self.sourceRepository = sourceRepository
        self.tagRepository = tagRepository
        self.content = item.content
        self.answer = item.answerText
        self.selectedSubject = item.subject
        self.selectedSource = item.source
        self.tagList = item.tags?.map { $0.name } ?? []
        self.difficulty = item.difficulty
    }
    
    public func loadData() {
        if displayedImage == nil, let path = item.imagePath {
            displayedImage = imageStorage.loadImage(path: path)
        }
        
        do {
            self.subjects = try subjectRepository.fetchAll()
            self.sources = try sourceRepository.fetchAll()
            self.allTags = try tagRepository.fetchAll()
        } catch {
            SnapDrillLogger.generic.error("LibraryEditViewModel: Failed to load metadata: \(error)")
        }
    }
    
    public func loadMetadata(subjects: [SubjectModel], sources: [SourceModel], tags: [TagModel]) {
        self.subjects = subjects
        self.sources = sources
        self.allTags = tags
    }
    
    public func handleNewImage(_ image: UIImage) {
        self.displayedImage = image
        self.isProcessing = true
        
        Task {
            do {
                guard let cgImage = image.cgImage else {
                    throw OCRError.invalidImage
                }
                let recognizedText = try await ocrService.recognizeText(from: cgImage)
                
                await MainActor.run {
                    self.content = recognizedText
                    self.isProcessing = false
                }
            } catch {
                SnapDrillLogger.generic.info("OCR Error: \(error)")
                await MainActor.run {
                    self.isProcessing = false
                }
            }
        }
    }
    
    public func saveDraftIfNeeded() {
        if !isSavedNormally, let _ = displayedImage {
            // Note: CaptureDraftService singleton access
            // CaptureDraftService.shared.saveDraft(image: image, content: content)
            SnapDrillLogger.generic.info("saveDraftIfNeeded called")
        }
    }
    
    public func save() async {
        isSavedNormally = true
        
        item.content = content
        item.answerText = answer
        item.subject = selectedSubject
        item.source = selectedSource
        item.difficulty = difficulty
        
        // Update Tags securely via Repository
        var newTags: [TagModel] = []
        for name in tagList {
            do {
                // Defaulting to a generic color for new tags during quick edit
                let tag = try tagRepository.getOrCreate(name: name, colorHex: "#9E9E9E")
                newTags.append(tag)
            } catch {
                SnapDrillLogger.generic.error("Failed to get/create tag '\(name)': \(error)")
            }
        }
        item.tags = newTags
        
        if let newImage = displayedImage {
            do {
                let newPath = try await imageStorage.saveImage(newImage)
                item.imagePath = newPath
            } catch {
                SnapDrillLogger.generic.info("Failed to save new image: \(error)")
            }
        }
        
        try? reviewRepository.save()
    }
}
