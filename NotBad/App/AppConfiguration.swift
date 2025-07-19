//
//  AppConfiguration.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

struct AppConfiguration {
    static let shared = AppConfiguration()
    
    // 环境配置
    enum Environment {
        case development
        case staging
        case production
    }
    
    let environment: Environment
    let apiBaseURL: String
    let databaseName: String
    
    private init() {
        #if DEBUG
        self.environment = .development
        self.apiBaseURL = "https://api-dev.notbad.com"
        #else
        self.environment = .production
        self.apiBaseURL = "https://api.notbad.com"
        #endif
        
        self.databaseName = "NotBad.sqlite"
    }
}
