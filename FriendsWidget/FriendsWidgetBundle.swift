//
//  FriendsWidgetBundle.swift
//  FriendsWidget
//
//  Widget bundle containing all Friends widgets
//  - Medium: Home Screen widget (3-4 friends)
//  - Lock Screen: Circular, Rectangular, Inline
//
//  Created by sezgin paksoy on 4.11.2025.
//

import WidgetKit
import SwiftUI

@main
struct FriendsWidgetBundle: WidgetBundle {
    var body: some Widget {
        MediumFriendsWidget()        // Medium Home Screen Widget
        FriendsLockScreenWidget()    // Lock Screen Widgets (Circular, Rectangular, Inline)
    }
}
