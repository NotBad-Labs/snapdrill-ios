//
//  CaptureImageSection.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集结果页的图片预览 section：截图展示 + 裁剪入口 + OCR 识别中遮罩。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

/// 采集结果页 — 图片预览 section
struct CaptureImageSection: View {
    @Bindable var viewModel: CaptureResultViewModel

    var body: some View {
        if let image = viewModel.image {
            ZStack(alignment: .bottomTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibleImage(label: L10n.Accessibility.questionImage)
                    .overlay {
                        if viewModel.isRecognizing {
                            ZStack {
                                Color.black.opacity(0.3)
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                    }

                Button(action: {
                    viewModel.isCropping = true
                }, label: {
                    Image(systemName: "crop")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(10)
                        .background(.regularMaterial)
                        .clipShape(Circle())
                })
                .accessibleButton(label: L10n.Accessibility.cropImage, hint: L10n.Accessibility.cropImageHint)
                .padding(8)
                .disabled(viewModel.isRecognizing)
            }
            .padding(.horizontal)
        }
    }
}
