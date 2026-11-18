import SwiftData
import SwiftUI

/// AC-01 管理壳；Slice 4 接完整 CRUD 与删除保护。
struct SubjectManagementShellView: View {
    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]

    var body: some View {
        List {
            ForEach(subjects) { subject in
                HStack {
                    Circle()
                        .fill(Color(hex: subject.colorHex))
                        .frame(width: 12, height: 12)
                    Text(subject.name)
                    if subject.isUncategorizedBucket {
                        Text(String(localized: "System"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(subject.mistakeCount)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Button(String(localized: "+ Add subject")) {}
                .disabled(true)
        }
        .navigationTitle(String(localized: "Subjects"))
        .paperBackground()
    }
}