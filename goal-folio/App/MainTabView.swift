//
//  MainTabView.swift
//  goal-folio
//
//  Created by Pratham S on 11/4/25.
//
// (M1.1) Hosts the TabView

import SwiftUI

struct MainTabView: View {
    @StateObject private var stockStore = StockStore()
    @StateObject private var loadingManager = LoadingManager()
    @StateObject private var positionsStore = PositionsStore()

//    init() {
//        #if DEBUG
//        if let bundleID = Bundle.main.bundleIdentifier {
//            UserDefaults.standard.removePersistentDomain(forName: bundleID)
//            UserDefaults.standard.synchronize()
//        }
//        #endif
//    }
    
    var body: some View {
        ZStack {
            TabView {
                Tab("Watchlist", systemImage: "star") {
                    NavigationStack {
                        WatchlistView()
                    }
                }
                
                Tab("Portfolio", systemImage: "person") {
                    NavigationStack {
                        PortfolioView()
                    }
                }
            }
            .environmentObject(stockStore)
            .environmentObject(loadingManager)
            .environmentObject(positionsStore)
            
            if loadingManager.isLoading {
                ZStack {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.accentColor)
                    }
                    .padding(32)
                    .background(Color.black.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: loadingManager.isLoading)
            }
        }
    }
}

#Preview {
    MainTabView()
}
