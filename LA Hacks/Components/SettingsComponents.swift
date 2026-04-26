//
//  SettingsComponents.swift
//  LA Hacks
//
//  Star Hop! shared building blocks for the Settings tab.
//

import SwiftUI

// MARK: - Settings helpers

struct SettingsSection<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(0.4)
                .textCase(.uppercase)
                .foregroundColor(.white.opacity(0.5))
                .padding(.bottom, 12)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1.5)
        )
    }
}

struct SettingsLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .tracking(0.4)
            .textCase(.uppercase)
            .foregroundColor(.white.opacity(0.5))
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1).padding(.vertical, 10)
    }
}

struct ToggleRow: View {
    let label: String
    let sub: String
    let on: Bool
    let accent: Color
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(sub).font(.system(size: 11, design: .rounded)).foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                Capsule()
                    .fill(on ? accent : Color.white.opacity(0.12))
                    .frame(width: 48, height: 28)
                    .shadow(color: on ? accent.opacity(0.5) : .clear, radius: 6)
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.3), radius: 3)
                    .frame(width: 20, height: 20)
                    .offset(x: on ? 10 : -10)
                    .animation(.spring(response: 0.22, dampingFraction: 0.82), value: on)
            }
            .onTapGesture { onToggle() }
            .animation(.easeOut(duration: 0.22), value: on)
        }
    }
}
