//
//  LicenseView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  开源许可展示页面，列出项目中使用的第三方库。
//

import SwiftUI

struct LicenseView: View {
    
    // MARK: - Body
    
    var body: some View {
        List {
            Section(header: Text("开源库")) {
                NavigationLink(destination: LicenseDetailView(title: "Mantis", licenseContent: mantisLicense)) {
                    VStack(alignment: .leading) {
                        Text("Mantis")
                            .font(.headline)
                        Text("Copyright © 2018-2025 Yingtao Guo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section {
                Text("本应用使用了一些优秀的开源软件，感谢所有贡献者。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("开源许可")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LicenseDetailView: View {
    
    // MARK: - Properties
    
    let title: String
    let licenseContent: String
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            Text(licenseContent)
                .font(.system(.caption, design: .monospaced))
                .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private let mantisLicense = """
The MIT License (MIT)

Copyright (c) 2018-2025 Yingtao Guo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

#Preview {
    NavigationStack {
        LicenseView()
    }
}
