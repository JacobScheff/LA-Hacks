//
//  LocaleBundle.swift
//  LA Hacks
//
//  Swizzles Bundle.main so every Text("literal") call re-routes through our
//  translation dictionary at runtime — no .strings files needed.
//

import Foundation
import ObjectiveC

// MARK: - Custom bundle that intercepts localizedString(forKey:)

private final class LanguageBundle: Bundle, @unchecked Sendable {
    nonisolated(unsafe) static var currentCode: String = "en"

    override func localizedString(forKey key: String,
                                  value: String?,
                                  table tableName: String?) -> String {
        NSLog("[i18n] localizedString called  key=\(key)  table=\(tableName ?? "nil")  currentCode=\(LanguageBundle.currentCode)")
        guard LanguageBundle.currentCode != "en" else { return value ?? key }
        let result = Translations.lookup(key: key, language: LanguageBundle.currentCode) ?? value ?? key
        // #region agent log
        let hit = (Translations.lookup(key: key, language: LanguageBundle.currentCode) != nil)
        if key.count > 2 && key.count < 60 {
            let line = "{\"sessionId\":\"2da7cf\",\"hypothesisId\":\"B\",\"location\":\"LocaleBundle.swift:localizedString\",\"message\":\"Translation lookup\",\"data\":{\"key\":\"\(key.prefix(40).replacingOccurrences(of: "\"", with: "'"))\",\"currentCode\":\"\(LanguageBundle.currentCode)\",\"hit\":\"\(hit)\",\"result\":\"\(result.prefix(40).replacingOccurrences(of: "\"", with: "'"))\"},\"timestamp\":\(Int(Date().timeIntervalSince1970*1000))}\n"
            let p = "/Users/genami133/Projects/LA-Hacks/.cursor/debug-2da7cf.log"
            if let fh = FileHandle(forWritingAtPath: p) { fh.seekToEndOfFile(); fh.write(line.data(using: .utf8)!); fh.closeFile() }
            else { try? line.data(using: .utf8)?.write(to: URL(fileURLWithPath: p)) }
        }
        // #endregion
        NSLog("[i18n]   -> returning: \(result)")
        return result
    }

    override var localizations: [String] {
        let list = ["en", "es", "fr", "de", "ja", "zh-Hans", "zh-Hant",
                    "ar", "pt", "ru", "ko", "hi", "it", "tr", "nl", "pl", "uk"]
        NSLog("[i18n] localizations queried -> \(list)")
        return list
    }

    override var preferredLocalizations: [String] {
        let list = [LanguageBundle.currentCode, "en"]
        NSLog("[i18n] preferredLocalizations queried -> \(list)")
        return list
    }

    override var developmentLocalization: String? {
        NSLog("[i18n] developmentLocalization queried")
        return "en"
    }
}

// MARK: - Public API

extension Bundle {
    /// Call once on app launch (and again whenever language changes).
    /// Swizzles Bundle.main on the first call; subsequent calls just update the code.
    static func setLanguage(_ code: String) {
        let before = String(describing: type(of: Bundle.main))
        object_setClass(Bundle.main, LanguageBundle.self)
        let after = String(describing: type(of: Bundle.main))
        LanguageBundle.currentCode = code
        NSLog("[i18n] setLanguage(\(code))  bundleClass: \(before) -> \(after)  isLanguageBundle=\(Bundle.main is LanguageBundle)")
    }
}
