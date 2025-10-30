//
//  CallReminderWidgetBundle.swift
//  CallReminderWidget
//
//  Created by sezgin paksoy on 30.10.2025.
//

import WidgetKit
import SwiftUI

@main
struct CallReminderWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Sadece Live Activity kullanıyoruz
        CallReminderWidgetLiveActivity()
    }
}
