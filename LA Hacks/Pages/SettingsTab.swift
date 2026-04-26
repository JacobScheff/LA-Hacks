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
    @State private var notifHour: Int = 6
    @State private var notifMinute: Int = 0
    @State private var notifIsAM: Bool = false
    @State private var editingName: Bool = false

    private let avatars = ["🦊","🐸","🐧","🦁","🐙","🦋","🐬","🦄"]
    private let grades = ["K","1st","2nd","3rd","4th","5th","6th","7th","8th","9th","10th","11th","12th"]
    private typealias Language = (code: String, name: String, flag: String)
    private let languages: [Language] = [
        (code: "af",      name: "Afrikaans",        flag: "🇿🇦"),
        (code: "am",      name: "አማርኛ",              flag: "🇪🇹"),
        (code: "ar",      name: "العربية",            flag: "🇸🇦"),
        (code: "bg",      name: "Български",          flag: "🇧🇬"),
        (code: "bn",      name: "বাংলা",              flag: "🇧🇩"),
        (code: "ca",      name: "Català",             flag: "🇪🇸"),
        (code: "cs",      name: "Čeština",            flag: "🇨🇿"),
        (code: "da",      name: "Dansk",              flag: "🇩🇰"),
        (code: "de",      name: "Deutsch",            flag: "🇩🇪"),
        (code: "el",      name: "Ελληνικά",           flag: "🇬🇷"),
        (code: "en",      name: "English",            flag: "🇺🇸"),
        (code: "es",      name: "Español",            flag: "🇪🇸"),
        (code: "et",      name: "Eesti",              flag: "🇪🇪"),
        (code: "fa",      name: "فارسی",              flag: "🇮🇷"),
        (code: "fi",      name: "Suomi",              flag: "🇫🇮"),
        (code: "fil",     name: "Filipino",           flag: "🇵🇭"),
        (code: "fr",      name: "Français",           flag: "🇫🇷"),
        (code: "gu",      name: "ગુજરાતી",            flag: "🇮🇳"),
        (code: "he",      name: "עברית",              flag: "🇮🇱"),
        (code: "hi",      name: "हिन्दी",              flag: "🇮🇳"),
        (code: "hr",      name: "Hrvatski",           flag: "🇭🇷"),
        (code: "hu",      name: "Magyar",             flag: "🇭🇺"),
        (code: "hy",      name: "Հայերեն",            flag: "🇦🇲"),
        (code: "id",      name: "Indonesia",          flag: "🇮🇩"),
        (code: "it",      name: "Italiano",           flag: "🇮🇹"),
        (code: "ja",      name: "日本語",              flag: "🇯🇵"),
        (code: "ka",      name: "ქართული",            flag: "🇬🇪"),
        (code: "kn",      name: "ಕನ್ನಡ",              flag: "🇮🇳"),
        (code: "ko",      name: "한국어",              flag: "🇰🇷"),
        (code: "lt",      name: "Lietuvių",           flag: "🇱🇹"),
        (code: "lv",      name: "Latviešu",           flag: "🇱🇻"),
        (code: "mk",      name: "Македонски",         flag: "🇲🇰"),
        (code: "ml",      name: "മലയാളം",             flag: "🇮🇳"),
        (code: "mn",      name: "Монгол",             flag: "🇲🇳"),
        (code: "mr",      name: "मराठी",              flag: "🇮🇳"),
        (code: "ms",      name: "Melayu",             flag: "🇲🇾"),
        (code: "my",      name: "မြန်မာဘာသာ",          flag: "🇲🇲"),
        (code: "nb",      name: "Norsk",              flag: "🇳🇴"),
        (code: "ne",      name: "नेपाली",              flag: "🇳🇵"),
        (code: "nl",      name: "Nederlands",         flag: "🇳🇱"),
        (code: "pa",      name: "ਪੰਜਾਬੀ",             flag: "🇮🇳"),
        (code: "pl",      name: "Polski",             flag: "🇵🇱"),
        (code: "pt",      name: "Português",          flag: "🇧🇷"),
        (code: "ro",      name: "Română",             flag: "🇷🇴"),
        (code: "ru",      name: "Русский",            flag: "🇷🇺"),
        (code: "sk",      name: "Slovenčina",         flag: "🇸🇰"),
        (code: "sl",      name: "Slovenščina",        flag: "🇸🇮"),
        (code: "sr",      name: "Српски",             flag: "🇷🇸"),
        (code: "sv",      name: "Svenska",            flag: "🇸🇪"),
        (code: "sw",      name: "Kiswahili",          flag: "🇰🇪"),
        (code: "ta",      name: "தமிழ்",              flag: "🇮🇳"),
        (code: "te",      name: "తెలుగు",             flag: "🇮🇳"),
        (code: "th",      name: "ภาษาไทย",            flag: "🇹🇭"),
        (code: "tr",      name: "Türkçe",             flag: "🇹🇷"),
        (code: "uk",      name: "Українська",         flag: "🇺🇦"),
        (code: "ur",      name: "اردو",               flag: "🇵🇰"),
        (code: "vi",      name: "Tiếng Việt",         flag: "🇻🇳"),
        (code: "zh-Hans", name: "中文（简体）",          flag: "🇨🇳"),
        (code: "zh-Hant", name: "中文（繁體）",          flag: "🇹🇼"),
        (code: "zu",      name: "isiZulu",            flag: "🇿🇦"),
    ]
    private var currentLanguage: Language {
        languages.first { $0.code == userSettings.language } ?? languages[10] // fallback: English
    }

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

                TabHeader(kicker: "", title: "Settings", emoji: "", subtitle: "")

                VStack(spacing: 12) {
                    profileSection
                    soundSection
                    reminderSection
                    aboutSection
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 35)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .dismissesKeyboard()
        .foregroundColor(.white)
        .onAppear {
            let parsed = Self.parseNotifTime(userSettings.notifTime)
            notifHour   = parsed.hour
            notifMinute = parsed.minute
            notifIsAM   = parsed.isAM
        }
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
            .padding(.bottom, 14)

            // Language
            VStack(alignment: .leading, spacing: 8) {
                SettingsLabel("Language")
                Menu {
                    ForEach(languages, id: \.code) { lang in
                        Button(action: { userSettings.language = lang.code }) {
                            Label(
                                "\(lang.flag) \(lang.name)",
                                systemImage: userSettings.language == lang.code ? "checkmark" : ""
                            )
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(currentLanguage.flag)
                            .font(.system(size: 20))
                        Text(currentLanguage.name)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.07))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: 0x5EE7FF, opacity: 0.45), Color(hex: 0xA78BFA, opacity: 0.45)],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                }
                .buttonStyle(.plain)
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
            ToggleRow(label: "Remind me to study", sub: "Never miss your streak!", on: userSettings.notifOn, accent: Color(hex: 0xFF8AD8)) {
                userSettings.notifOn.toggle()
            }
            if userSettings.notifOn {
                VStack(alignment: .leading, spacing: 8) {
                    SettingsLabel("Reminder time").padding(.top, 12)
                    StarHopTimePicker(hour: $notifHour, minute: $notifMinute, isAM: $notifIsAM)
                        .onChange(of: notifHour)   { _, _ in syncNotifTime() }
                        .onChange(of: notifMinute) { _, _ in syncNotifTime() }
                        .onChange(of: notifIsAM)   { _, _ in syncNotifTime() }
                }
            }
        }
    }

    private func syncNotifTime() {
        let h24: Int
        if notifIsAM {
            h24 = notifHour == 12 ? 0 : notifHour
        } else {
            h24 = notifHour == 12 ? 12 : notifHour + 12
        }
        userSettings.notifTime = String(format: "%02d:%02d", h24, notifMinute)
    }

    private static func parseNotifTime(_ time: String) -> (hour: Int, minute: Int, isAM: Bool) {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return (6, 0, false) }
        let h24 = parts[0], m = parts[1]
        let hour12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24)
        return (hour12, m, h24 < 12)
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

}

// MARK: - Time Picker

struct StarHopTimePicker: View {
    @Binding var hour: Int     // 1–12
    @Binding var minute: Int   // 0–59
    @Binding var isAM: Bool

    var body: some View {
        HStack(spacing: 0) {
            Picker("", selection: $hour) {
                ForEach(1...12, id: \.self) { h in
                    Text("\(h)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .tag(h)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Text(":")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .padding(.bottom, 2)

            Picker("", selection: $minute) {
                ForEach(0...59, id: \.self) { m in
                    Text(String(format: "%02d", m))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Picker("", selection: $isAM) {
                Text("AM")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .tag(true)
                Text("PM")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .tag(false)
            }
            .pickerStyle(.wheel)
            .frame(width: 72)
        }
        .colorScheme(.dark)
        .frame(height: 150)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: 0xFF8AD8, opacity: 0.5), Color(hex: 0xA78BFA, opacity: 0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
