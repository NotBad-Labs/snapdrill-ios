//
//  ReviewRatingView.swift
//  NotBadFeatures
//
//  Created by NotBad Agent on 2025/12/31.
//

import SwiftUI
import NotBadCore

struct BinaryRatingBar: View {
    let onRate: (ReviewRating) -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Forget / Again
            Button(action: { onRate(.again) }, label: {
                VStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .bold))
                    Text("忘记")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(Color.red.opacity(0.15))
                .foregroundStyle(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            })
            
            // Remember / Good
            Button(action: { onRate(.good) }, label: {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                    Text("记得")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(Color.green.opacity(0.15))
                .foregroundStyle(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            })
        }
        .padding(.horizontal, 32)
    }
}

struct ReviewActionPill: View {
    let title: String
    let rating: ReviewRating
    let color: Color
    let action: (ReviewRating) -> Void
    
    private var timeString: String {
        let interval = ReviewScheduler().interval(for: rating)
        return formatInterval(interval)
    }
    
    var body: some View {
        Button(action: { action(rating) }, label: {
            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(timeString)
                    .font(.caption2)
                    .opacity(0.8)
            }
            .frame(width: 80, height: 60)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        })
    }
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes < 60 { return "\(minutes)分" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)时" }
        let days = hours / 24
        return "\(days)天"
    }
}
