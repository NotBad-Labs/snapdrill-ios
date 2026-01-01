//
//  Persistence.swift
//  NotBadData
//
//  Created by Yiming Liao on 2025/12/29.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  SwiftData 持久化控制器，管理 ModelContainer
//

import SwiftData

@MainActor
public class PersistenceController {
    public static let shared = PersistenceController()
    
    public let container: ModelContainer
    
    public init(inMemory: Bool = false) {
        let schema = Schema(versionedSchema: NotBadSchemaV3.self)
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        
        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: NotBadMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
