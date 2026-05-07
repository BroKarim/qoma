import Foundation

enum AppConstants {
    enum QuickPresets {
        static let preset1Key = "quickPreset1"
        static let preset2Key = "quickPreset2"
        static let preset3Key = "quickPreset3"
        static let defaultValues: [Int] = [5, 10, 25]
        static let minMinutes: Int = 1
        static let maxMinutes: Int = 60
    }

    enum SoundSettings {
        static let selectedSoundKey = "selectedSoundID"
        static let autoMuteAfter5SecondsKey = "autoMuteAfter5Seconds"
        static let volumeKey = "soundVolume"

        static let defaultSoundID = "alarm-1"
        static let defaultVolume = 0.6
        static let minVolume = 0.0
        static let maxVolume = 1.0
        static let options: [SoundOption] = [
            SoundOption(id: "alarm-1", title: "Alarm 1", fileName: "alarm-1", fileExtension: "m4a"),
            SoundOption(id: "alarm-2", title: "Alarm 2", fileName: "alarm-2", fileExtension: "m4a"),
            SoundOption(id: "alarm-3", title: "Alarm 3", fileName: "alarm-3", fileExtension: "m4a"),
        ]
    }

    enum FloatingThemeSettings {
        static let opacityKey = "floatingOpacity"
        static let selectedThemeKey = "floatingThemeID"
        static let defaultThemeID = "graphite"
        static let defaultOpacity = 0.85
        static let minOpacity = 0.4
        static let maxOpacity = 1.0
    }

    enum FloatingLayoutSettings {
        static let selectedLayoutKey = "floatingLayoutMode"
        static let defaultLayoutID = "timerOnly"
        static let imagePathKey = "floatingImagePath"
        static let showTimerOnImageKey = "showTimerOnImage"
        static let imageOffsetXKey = "floatingImageOffsetX"
        static let imageOffsetYKey = "floatingImageOffsetY"
        static let defaultImageOffset = 0.0
        static let timerOnlyWidth: CGFloat = 110
        static let width: CGFloat = 230
        static let timerOnlyHeight: CGFloat = 62
        static let timerOnlyFontSize: CGFloat = 30
        static let timerOnlyHorizontalPadding: CGFloat = 0
        static let timerOnlyVerticalOffset: CGFloat = 1
        static let imageOnlyHeight: CGFloat = 142
        static let mixedHeight: CGFloat = 192
        static let mixedImageHeight: CGFloat = 142
        static let mixedTimerHeight: CGFloat = 50
        static let mixedTimerFontSize: CGFloat = 28
        static let mixedTimerHorizontalPadding: CGFloat = 12
    }

    enum BreakDuration {
        static let shortMinutes: Int = 5
        static let longMinutes: Int = 15
    }

    enum MenuBarSettings {
        static let compactIconKey = "menuBarCompactIcon"
        static let selectedPresetMinutesKey = "menuBarSelectedPresetMinutes"
        static let defaultPresetMinutes = 25
        static let panelWidth: CGFloat = 250
        static let panelHeight: CGFloat = 138
    }

    enum AnalyticsSettings {
        static let focusSessionsFile = "focus-sessions.json"
        static let appActivityFile = "app-activity.json"
        static let websiteVisitsFile = "website-visits.json"
        static let analyticsDirectoryName = "Analytics"
        static let retentionDays = 180
        static let analyticsEnabledKey = "analyticsEnabled"
        static let defaultDashboardRangeDays = 30
        static let heatmapDays = 30
        static let weeklySummaryDays = 7

        static let supportedBrowsers: [String: String] = [
            "com.apple.Safari": "Safari",
            "com.google.Chrome": "Google Chrome",
            "org.mozilla.firefox": "Firefox",
            "com.microsoft.edgemac": "Microsoft Edge",
            "com.brave.Browser": "Brave Browser",
            "com.operasoftware.Opera": "Opera",
        ]

        static var analyticsDirectoryURL: URL {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            return appSupport.appendingPathComponent("Dzenn").appendingPathComponent(analyticsDirectoryName)
        }
    }
}
