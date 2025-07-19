//
//  RootView.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import SwiftUI

struct RootView: View {
    @State private var appRouter = AppRouter()
    
    var body: some View {
        Group {
            switch appRouter.currentFlow {
            case .onboarding:
                OnboardingFlow()
            case .authentication:
                AuthenticationFlow()
            case .main:
                MainFlow()
            }
        }
        .environment(appRouter)
        .onAppear {
            appRouter.determineInitialFlow()
        }
    }
}
