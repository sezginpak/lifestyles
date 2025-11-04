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
        case memories = 3
        case activities = 4
        case goals = 5
        case analytics = 6
        case aiBrain = 7
        case settings = 8

        var title: String {
            switch self {
            case .dashboard: return String(localized: "tab.dashboard", comment: "Dashboard tab title")
            case .contacts: return String(localized: "tab.contacts", comment: "Contacts/Friends tab title")
            case .moodJournal: return String(localized: "tab.moodJournal", defaultValue: "Mood", comment: "Mood journal tab title")
            case .memories: return String(localized: "tab.memories", defaultValue: "Anılar", comment: "Memories tab title")
            case .activities: return String(localized: "tab.activities", defaultValue: "Aktivite", comment: "Activities tab title")
            case .goals: return String(localized: "tab.goals", comment: "Goals tab title")
            case .analytics: return String(localized: "tab.analytics", defaultValue: "Analiz", comment: "Analytics tab title")
            case .aiBrain: return String(localized: "aibrain.tab.title", defaultValue: "AI Hafıza", comment: "AI Brain tab title")
            case .settings: return String(localized: "tab.settings", comment: "Settings tab title")
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .contacts: return "person.2.fill"
            case .moodJournal: return "face.smiling"
            case .memories: return "photo.on.rectangle.angled"
            case .activities: return "figure.walk"
            case .goals: return "target"
            case .analytics: return "chart.bar.fill"
            case .aiBrain: return "brain.head.profile"
            case .settings: return "gearshape.fill"
            }
        }

        var color: Color {
            switch self {
            case .dashboard: return .brandPrimary
            case .contacts: return .cardCommunication
            case .moodJournal: return .purple
            case .memories: return .teal
            case .activities: return .cardActivity
            case .goals: return .cardGoals
            case .analytics: return .orange
            case .aiBrain: return .purple
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

            MemoriesView()
                .tag(Tab.memories)
                .tabItem {
                    Label(Tab.memories.title, systemImage: Tab.memories.icon)
                }

            LocationView()
                .tag(Tab.activities)
                .tabItem {
                    Label(Tab.activities.title, systemImage: Tab.activities.icon)
                }

            GoalsViewNew()
                .tag(Tab.goals)
                .tabItem {
                    Label(Tab.goals.title, systemImage: Tab.goals.icon)
                }

            AnalyticsView()
                .tag(Tab.analytics)
                .tabItem {
                    Label(Tab.analytics.title, systemImage: Tab.analytics.icon)
                }

            AIBrainView()
                .tag(Tab.aiBrain)
                .tabItem {
                    Label(Tab.aiBrain.title, systemImage: Tab.aiBrain.icon)
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
