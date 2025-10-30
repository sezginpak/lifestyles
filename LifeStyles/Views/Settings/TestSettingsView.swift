//
//  TestSettingsView.swift
//  LifeStyles
//
//  Test için ultra minimal view
//

import SwiftUI

struct TestSettingsView: View {
    var body: some View {
        Text(String(localized: "settings.test.message", comment: "Test message"))
            .font(.largeTitle)
            .padding()
    }
}

#Preview {
    TestSettingsView()
}
