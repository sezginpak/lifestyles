//
//  ContentView.swift
//  LifeStyles
//
//  Created by sezgin paksoy on 15.10.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .dashboard
    @State private var toastManager = ToastManager.shared
    @Environment(DeepLinkRouter.self) private var deepLinkRouter

    enum Tab: Int {
        case dashboard = 0
        case contacts = 1
        case moodJournal = 2
        case location = 3
        case goals = 4
        case settings = 5

        var title: String {
            switch self {
            case .dashboard: return String(localized: "tab.dashboard", comment: "Dashboard tab title")
            case .contacts: return String(localized: "tab.contacts", comment: "Contacts/Friends tab title")
            case .moodJournal: return "Mood"
            case .location: return String(localized: "tab.location", comment: "Location/Activity tab title")
            case .goals: return String(localized: "tab.goals", comment: "Goals tab title")
            case .settings: return String(localized: "tab.settings", comment: "Settings tab title")
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .contacts: return "person.2.fill"
            case .moodJournal: return "face.smiling"
            case .location: return "location.fill"
            case .goals: return "target"
            case .settings: return "gearshape.fill"
            }
        }

        var color: Color {
            switch self {
            case .dashboard: return .brandPrimary
            case .contacts: return .cardCommunication
            case .moodJournal: return .purple
            case .location: return .cardActivity
            case .goals: return .cardGoals
            case .settings: return .textSecondary
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardViewNew()
                .tag(Tab.dashboard)
                .tabItem {
                    Label(Tab.dashboard.title, systemImage: Tab.dashboard.icon)
                }

            FriendsView()
                .tag(Tab.contacts)
                .tabItem {
                    Label(Tab.contacts.title, systemImage: Tab.contacts.icon)
                }

            MoodJournalView()
                .tag(Tab.moodJournal)
                .tabItem {
                    Label(Tab.moodJournal.title, systemImage: Tab.moodJournal.icon)
                }

            LocationView()
                .tag(Tab.location)
                .tabItem {
                    Label(Tab.location.title, systemImage: Tab.location.icon)
                }

            GoalsViewNew()
                .tag(Tab.goals)
                .tabItem {
                    Label(Tab.goals.title, systemImage: Tab.goals.icon)
                }

            SettingsView()
                .tag(Tab.settings)
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.icon)
                }
        }
        .tint(.brandPrimary)
        .withToast(manager: toastManager)
        .environment(\.toastManager, toastManager)
        .onChange(of: deepLinkRouter.activeTab) { _, newTab in
            // Deep link'ten gelen tab değişikliğini uygula
            if let tab = Tab(rawValue: newTab) {
                selectedTab = tab
                print("📲 Deep link tab change: \(tab)")
            }
        }
    }
}

#Preview {
    ContentView()
}
