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
import SnapDrillCore

struct LicenseView: View {
    
    // MARK: - Body
    
    var body: some View {
        List {
            Section(L10n.Settings.openSourceSection) {
                NavigationLink(destination: LicenseDetailView(title: "Mantis", licenseContent: mantisLicense)) {
                    VStack(alignment: .leading) {
                        Text("Mantis")
                            .font(.headline)
                        Text("Copyright © 2018-2025 Yingtao Guo · MIT License")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink(destination: LicenseDetailView(title: "ZIPFoundation", licenseContent: zipFoundationLicense)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ZIPFoundation")
                            .font(.headline)
                        Text("Copyright © Thomas Zoechling · MIT License")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink(destination: LicenseDetailView(title: "Firebase iOS SDK", licenseContent: firebaseLicense)) {
                    VStack(alignment: .leading) {
                        Text("Firebase iOS SDK")
                            .font(.headline)
                        Text("Copyright © Google LLC · Apache License 2.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Text(L10n.Settings.openSourceThanks)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.Settings.openSourceTitle)
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

private let firebaseLicense = """
Apache License
Version 2.0, January 2004

Copyright 2019 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied. See the License for the specific language governing
permissions and limitations under the License.
"""

private let zipFoundationLicense = """
The MIT License (MIT)

Copyright (c) 2017 Thomas Zoechling

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
