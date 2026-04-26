//
//  SettingsTab.swift
//  LA Hacks
//
//  App settings tab — toggles, sound/music, age, parent PIN, etc.
//  Extracted from GalaxyTabs.swift.
//

import SwiftUI

// MARK: - Settings Tab

struct SettingsTab: View {
    let onBack: () -> Void

    @Environment(UserSettings.self) var userSettings
    @State private var soundOn: Bool = true
    @State private var musicOn: Bool = true
    @State private var notifOn: Bool = true
    @State private var notifTime: String = "18:00"
    @State private var editingName: Bool = false
    @State private var parentUnlocked: Bool = false
    @State private var parentPin: String = ""
    @State private var pinError: Bool = false

    private let avatars = ["🦊","🐸","🐧","🦁","🐙","🦋","🐬","🦄"]
    private let grades = ["K","1st","2nd","3rd","4th","5th","6th","7th","8th","9th","10th","11th","12th"]
    private let times = ["07:00","12:00","15:30","18:00","20:00"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Text("←")
                        Text("Me")
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        Capsule().fill(Color.white.opacity(0.10))
                    )
                    .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                TabHeader(kicker: "⚙️ PREFERENCES", title: "Settings", emoji: "", subtitle: "Make Star Hop yours!")

                VStack(spacing: 12) {
                    profileSection
                    soundSection
                    reminderSection
                    grownUpSection
                    aboutSection
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 70)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .foregroundColor(.white)
    }

    // MARK: Profile

    private var profileSection: some View {
        SettingsSection(label: "🧑‍🚀 My Profile") {
            // Avatar picker
            VStack(alignment: .leading, spacing: 8) {
                SettingsLabel("Avatar")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(avatars, id: \.self) { a in
                            Button(action: { userSettings.avatar = a }) {
                                Text(a).font(.system(size: 26))
                                    .frame(width: 48, height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(userSettings.avatar == a
                                                  ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0x5EE7FF, opacity: 0.3), Color(hex: 0xA78BFA, opacity: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                  : AnyShapeStyle(Color.white.opacity(0.06)))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(userSettings.avatar == a ? Color(hex: 0x5EE7FF) : Color.clear, lineWidth: 2)
                                    )
                                    .animation(.easeOut(duration: 0.15), value: userSettings.avatar == a)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.bottom, 14)

            // Name
            VStack(alignment: .leading, spacing: 6) {
                SettingsLabel("Explorer name")
                if editingName {
                    HStack(spacing: 8) {
                        TextField("Explorer name", text: Binding(
                            get: { userSettings.explorerName },
                            set: { userSettings.explorerName = $0 }
                        ))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.07))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(hex: 0x5EE7FF, opacity: 0.4), lineWidth: 1.5)
                            )
                            .onSubmit { editingName = false }
                        Button(action: { editingName = false }) {
                            Text("Save")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: 0x1A0B40))
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(
                                    LinearGradient(colors: [Color(hex: 0x5EE7FF), Color(hex: 0xA78BFA)], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button(action: { editingName = true }) {
                        HStack {
                            Text(userSettings.explorerName)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 14)

            // Grade
            VStack(alignment: .leading, spacing: 8) {
                SettingsLabel("Grade")
                FlexWrap(spacing: 6) {
                    ForEach(grades, id: \.self) { g in
                        Button(action: { userSettings.grade = g }) {
                            Text(g)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(userSettings.grade == g ? Color(hex: 0x1A0B40) : .white.opacity(0.75))
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(
                                    Capsule().fill(userSettings.grade == g
                                                   ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xFFE066), Color(hex: 0xFF8AD8)], startPoint: .leading, endPoint: .trailing))
                                                   : AnyShapeStyle(Color.white.opacity(0.07)))
                                )
                                .shadow(color: userSettings.grade == g ? Color(hex: 0xFFE066, opacity: 0.35) : .clear, radius: 8)
                                .animation(.easeOut(duration: 0.15), value: userSettings.grade == g)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Sound

    private var soundSection: some View {
        SettingsSection(label: "🔊 Sound") {
            ToggleRow(label: "Sound effects", sub: "Whooshes, pops, and cheers", on: soundOn, accent: Color(hex: 0x5EE7FF)) {
                soundOn.toggle()
            }
            SettingsDivider()
            ToggleRow(label: "Background music", sub: "Calm space tunes while you learn", on: musicOn, accent: Color(hex: 0xA78BFA)) {
                musicOn.toggle()
            }
        }
    }

    // MARK: Reminders

    private var reminderSection: some View {
        SettingsSection(label: "🔔 Daily Reminder") {
            ToggleRow(label: "Remind me to study", sub: "Never miss your streak!", on: notifOn, accent: Color(hex: 0xFF8AD8)) {
                notifOn.toggle()
            }
            if notifOn {
                VStack(alignment: .leading, spacing: 8) {
                    SettingsLabel("Reminder time").padding(.top, 12)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(times, id: \.self) { t in
                                Button(action: { notifTime = t }) {
                                    Text(t)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(notifTime == t ? Color(hex: 0x1A0B40) : .white.opacity(0.75))
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(
                                            Capsule().fill(notifTime == t
                                                           ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xFF8AD8), Color(hex: 0xA78BFA)], startPoint: .leading, endPoint: .trailing))
                                                           : AnyShapeStyle(Color.white.opacity(0.07)))
                                        )
                                        .animation(.easeOut(duration: 0.15), value: notifTime == t)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Grown-up corner

    private var grownUpSection: some View {
        SettingsSection(label: "👨‍👩‍👧 Grown-Up Corner") {
            if !parentUnlocked {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Enter your grown-up PIN to see progress reports and manage the account.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .lineSpacing(2)

                    HStack(spacing: 8) {
                        SecureField("PIN", text: $parentPin)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 90)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(pinError ? Color(hex: 0xFF5050, opacity: 0.15) : Color.white.opacity(0.07))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(pinError ? Color(hex: 0xFF5050, opacity: 0.6) : Color.white.opacity(0.12), lineWidth: 1.5)
                            )
                            .onSubmit { tryUnlock() }
                            .animation(.easeOut(duration: 0.2), value: pinError)

                        Button(action: tryUnlock) {
                            Text("Unlock")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    if pinError {
                        Text("Hmm, that PIN doesn't match. Try again! (hint: 1234)")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(Color(hex: 0xFF8080))
                    }
                }
            } else {
                VStack(spacing: 0) {
                    ForEach([
                        ("📊", "Progress report",      "Full breakdown by subject"),
                        ("⏱️", "Screen time",           "Set daily limits"),
                        ("📧", "Weekly email digest",   "maya@example.com"),
                        ("🔒", "Change grown-up PIN",   "Currently 4 digits"),
                    ], id: \.1) { (icon, title, sub) in
                        HStack(spacing: 12) {
                            Text(icon).font(.system(size: 18))
                                .frame(width: 38, height: 38)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.07))
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title).font(.system(size: 14, weight: .semibold, design: .rounded))
                                Text(sub).font(.system(size: 11, design: .rounded)).foregroundColor(.white.opacity(0.5))
                            }
                            Spacer()
                            Text("›").foregroundColor(.white.opacity(0.3))
                        }
                        .padding(.vertical, 12)
                        .overlay(Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1), alignment: .bottom)
                    }
                    Button(action: { parentUnlocked = false }) {
                        Text("🔒 Lock grown-up corner")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: 0xFF8080))
                            .frame(maxWidth: .infinity).padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(hex: 0xFF5050, opacity: 0.12))
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        SettingsSection(label: "ℹ️ About") {
            VStack(spacing: 0) {
                ForEach([
                    ("App version", "1.0.0 🚀"),
                    ("Stars available", "47"),
                    ("Last updated", "Apr 2026"),
                ], id: \.0) { (label, val) in
                    HStack {
                        Text(label).font(.system(size: 13, design: .rounded)).foregroundColor(.white.opacity(0.65))
                        Spacer()
                        Text(val).font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .padding(.vertical, 10)
                    .overlay(Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1), alignment: .bottom)
                }
            }
        }
    }

    private func tryUnlock() {
        if parentPin == "1234" {
            parentUnlocked = true; pinError = false; parentPin = ""
        } else {
            pinError = true; parentPin = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { pinError = false }
        }
    }
}
