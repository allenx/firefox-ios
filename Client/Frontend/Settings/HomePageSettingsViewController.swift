/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SnapKit

private let log = Logger.browserLogger

struct HomePageConstants {
    static let HomePageURLPrefKey = "homepage.url"
    static let HomePageButtonIsInMenuPrefKey = "homepage.button.isInMenu"
    static let DefaultHomePageURLPrefKey = "homepage.url.default"
}

class HomePageSettingsViewController: SettingsTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsHomePageTitle
    }

    override func generateSettings() -> [SettingSection] {
        let prefs = profile.prefs

        typealias WebPageSource = () -> NSURL?
        func setHomePage(source: WebPageSource) -> ((UINavigationController?) -> ()) {
            return { nav in
                if let url = source() {
                    prefs.setString(url.absoluteString, forKey: HomePageConstants.HomePageURLPrefKey)
                } else {
                    prefs.removeObjectForKey(HomePageConstants.HomePageURLPrefKey)
                }
                self.tableView.reloadData()
            }
        }

        func isHomePage(source: WebPageSource) -> (() -> Bool) {
            return {
                return source()?.isWebPage() ?? false
            }
        }

        let currentTab: WebPageSource = {
            return self.tabManager.selectedTab?.displayURL
        }

        let clipboardURL: WebPageSource = {
            let string = UIPasteboard.generalPasteboard().string ?? " "
            return NSURL(string: string)
        }

        let defaultURL: WebPageSource = {
            let string = prefs.stringForKey(HomePageConstants.DefaultHomePageURLPrefKey) ?? " "
            return NSURL(string: string)
        }

        var basicSettings: [Setting] = [
            WebPageSetting(prefs: prefs,
                prefKey: HomePageConstants.HomePageURLPrefKey,
                placeholder: Strings.SettingsHomePagePlaceholder,
                accessibilityIdentifier: "HomePageSetting"),
            ButtonSetting(title: NSAttributedString(string: Strings.SettingsHomePageUseCurrentPage),
                accessibilityIdentifier: "UseCurrentTab",
                isEnabled: isHomePage(currentTab),
                onClick: setHomePage(currentTab)),
            ButtonSetting(title: NSAttributedString(string: Strings.SettingsHomePageUseCopiedLink),
                accessibilityIdentifier: "UseCopiedLink",
                isEnabled: isHomePage(clipboardURL),
                onClick: setHomePage(clipboardURL)),
        ]

        if let _ = defaultURL() {
            basicSettings += [
                ButtonSetting(title: NSAttributedString(string: Strings.SettingsHomePageUseDefault),
                    accessibilityIdentifier: "UseDefault",
                    onClick: setHomePage(defaultURL)
                )
            ]
        }

        basicSettings += [
            ButtonSetting(title: NSAttributedString(string: Strings.SettingsHomePageClear),
                destructive: true,
                accessibilityIdentifier: "ClearHomePage",
                onClick: setHomePage({ nil })
            )
        ]

        var settings: [SettingSection] = [
            SettingSection(title: NSAttributedString(string: Strings.SettingsHomePageURLSectionTitle), children: basicSettings),
        ]

        if AppConstants.MOZ_MENU {
            settings += [
                SettingSection(children: [
                    BoolSetting(prefs: prefs,
                        prefKey: HomePageConstants.HomePageButtonIsInMenuPrefKey,
                        defaultValue: true,
                        titleText: Strings.SettingsHomePageUIPositionTitle,
                        statusText: Strings.SettingsHomePageUIPositionSubtitle
                    ),
                ]),
            ]
        }

        return settings
    }
}

class WebPageSetting: StringSetting {
    init(prefs: Prefs, prefKey: String, defaultValue: String? = nil, placeholder: String? = nil, accessibilityIdentifier: String? = nil, settingDidChange: ((String?) -> Void)? = nil) {
        super.init(prefs: prefs,
                   prefKey: prefKey,
                   defaultValue: defaultValue,
                   placeholder: placeholder,
                   accessibilityIdentifier: accessibilityIdentifier,
                   settingIsValid: WebPageSetting.isURL,
                   settingDidChange: settingDidChange)
        textField.keyboardType = .URL
        textField.autocapitalizationType = .None
        textField.autocorrectionType = .No
    }

    static func isURL(string: String?) -> Bool {
        return NSURL(string: string ?? "invalid://")?.isWebPage() ?? false
    }
}
