//
//  Constants.swift
//  LA Hacks
//
//  Created by Jacob Scheff on 4/24/26.
//

import SwiftUI

let personalToken = "ztp_92c5cc5cc8024dc89ce028f7bd2aa11d";
let gemmaApiKey = "AIzaSyBD0fw_cSzd-mBJVhI8O94NaAdj4Tn2EIM";

// MARK: - Keyboard Dismissal

extension View {
    /// Dismiss the keyboard when the user taps outside a text field or scrolls.
    /// Apply to any container that hosts text fields for consistent behavior.
    func dismissesKeyboard() -> some View {
        self
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(
                TapGesture().onEnded {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
            )
    }
}
