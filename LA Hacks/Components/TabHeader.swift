//
//  TabHeader.swift
//  LA Hacks
//
//  Star Hop! shared TabHeader used in Quests, Trips, Nova AI, Settings tabs.
//  Ported from project/tabs.jsx.
//

import SwiftUI

// MARK: - Shared

struct TabHeader: View {
    let kicker: String
    let title: String
    let emoji: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(LocalizedStringKey(kicker))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(0.5)
                .foregroundColor(Color(hex: 0xFFE066))
                .shadow(color: Color(hex: 0xFFE066, opacity: 0.5), radius: 6)
            // Emoji is rendered verbatim, title is localized separately. Interpolating
            // the two into a single LocalizedStringKey produced lookup keys like
            // "🚀 Trips" or " Settings" (leading space) that don't exist in the
            // translation table, causing the fallback to the English key.
            (Text(verbatim: emoji.isEmpty ? "" : "\(emoji) ")
                + Text(LocalizedStringKey(title)))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .tracking(-0.4)
                .foregroundColor(.white)
            if let subtitle {
                Text(LocalizedStringKey(subtitle))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
    }
}

extension View {
    /// Dismisses the keyboard when the user taps anywhere inside this view.
    /// Uses `simultaneousGesture` so taps still propagate to buttons, scroll
    /// recognizers, and other interactive controls beneath.
    func dismissesKeyboard() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }

    /// Adds a Star Hop! styled "Done" button to the keyboard's input accessory
    /// toolbar. Apply directly to a `TextField` or `TextEditor` so the user
    /// always has an explicit dismiss path — even when the surrounding view
    /// can't catch a tap (e.g. small modals, chat input rows pinned to the
    /// keyboard, or text fields that fill the screen).
    func keyboardDoneToolbar() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: 0xFFE066))
                }
            }
        }
    }

    func sCard(stroke: Color = Color.white.opacity(0.12), padding: EdgeInsets = EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(stroke, lineWidth: 1.5)
            )
    }
}
