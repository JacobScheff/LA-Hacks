//
//  LocaleBundle.swift
//  LA Hacks
//
//  Runtime localization without .strings files. Method-swizzles
//  Bundle.localizedString(forKey:value:table:) on the class so EVERY caller
//  (Foundation, SwiftUI, NSLocalizedString, String(localized:), etc.) routes
//  through our `Translations` dictionary at render time.
//
//  Why method-exchange instead of `object_setClass(Bundle.main, ...)`:
//    - SwiftUI's Text rendering in iOS 16+ doesn't always dispatch through
//      the per-instance class swizzle. Method exchange on the class itself
//      is dispatched via the obj-c method table no matter how Bundle.main
//      was constructed/cached, which is the only reliable path.
//

import Foundation
import ObjectiveC

// Live language code used by the swizzled lookup. nonisolated(unsafe) because
// it's a tiny scalar read by Foundation's Bundle internals on whatever thread
// happens to be doing localization.
enum LanguageRuntime {
    nonisolated(unsafe) static var code: String = "en"
    nonisolated(unsafe) static var callCount: Int = 0
}

// MARK: - Bundle method swizzle

extension Bundle {

    /// Replacement for `localizedString(forKey:value:table:)`. After
    /// `method_exchangeImplementations` runs, calling this method actually
    /// invokes the *original* implementation, and the original selector
    /// invokes ours.
    @objc dynamic func _ms_localizedString(forKey key: String,
                                           value: String?,
                                           table tableName: String?) -> String {
        // Recurse-into-original (post-swizzle, this calls the real method).
        let originalResult = self._ms_localizedString(forKey: key, value: value, table: tableName)

        // #region agent log
        LanguageRuntime.callCount += 1
        let n = LanguageRuntime.callCount
        if n <= 40 || n % 50 == 0 {
            I18nDebug.log("P1", "Bundle._ms_localizedString",
                          "intercepted",
                          ["call#": "\(n)",
                           "key": String(key.prefix(60)),
                           "table": tableName ?? "nil",
                           "lang": LanguageRuntime.code,
                           "isMain": "\(self == Bundle.main)"])
        }
        // #endregion

        let code = LanguageRuntime.code
        guard code != "en" else { return originalResult }

        if let translated = Translations.lookup(key: key, language: code) {
            // #region agent log
            if n <= 40 || n % 50 == 0 {
                I18nDebug.log("P5", "Bundle._ms_localizedString",
                              "translated",
                              ["key": String(key.prefix(40)),
                               "lang": code,
                               "result": String(translated.prefix(40))])
            }
            // #endregion
            return translated
        }
        return originalResult
    }

    private static let _ms_installSwizzle: Void = {
        let cls: AnyClass = Bundle.self
        let originalSel = #selector(Bundle.localizedString(forKey:value:table:))
        let swizzledSel = #selector(Bundle._ms_localizedString(forKey:value:table:))

        guard
            let original = class_getInstanceMethod(cls, originalSel),
            let swizzled = class_getInstanceMethod(cls, swizzledSel)
        else {
            NSLog("[i18n] Failed to acquire methods for swizzle")
            return
        }

        // If the class doesn't already have the original selector defined on
        // itself (i.e. it's inherited), add it first, otherwise we'd swap
        // implementations on the wrong class.
        let didAdd = class_addMethod(cls, originalSel,
                                     method_getImplementation(swizzled),
                                     method_getTypeEncoding(swizzled))
        if didAdd {
            class_replaceMethod(cls, swizzledSel,
                                method_getImplementation(original),
                                method_getTypeEncoding(original))
        } else {
            method_exchangeImplementations(original, swizzled)
        }
        NSLog("[i18n] Bundle.localizedString swizzle installed")
    }()

    /// Idempotent: install swizzle once and update the live language code.
    static func setLanguage(_ code: String) {
        _ = _ms_installSwizzle  // touch to install once

        let beforeProbe = Bundle.main.localizedString(forKey: "Settings", value: nil, table: nil)
        LanguageRuntime.code = code
        let afterProbe = Bundle.main.localizedString(forKey: "Settings", value: nil, table: nil)
        let nsProbe = NSLocalizedString("Settings", comment: "")
        let dictProbe = Translations.lookup(key: "Settings", language: code) ?? "nil"

        // #region agent log
        I18nDebug.log("P2", "Bundle.setLanguage",
                      "language activated",
                      ["code": code,
                       "Bundle.main.localizedString(before)": beforeProbe,
                       "Bundle.main.localizedString(after)": afterProbe,
                       "NSLocalizedString": nsProbe,
                       "Translations.lookup": dictProbe])
        // #endregion

        NSLog("[i18n] setLanguage(\(code)) probes: bundle.before=\(beforeProbe) bundle.after=\(afterProbe) NSLocalized=\(nsProbe) dict=\(dictProbe)")
    }
}
