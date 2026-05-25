import Foundation

class SafariBrowser: BaseBrowser {
    init() {
        super.init(bundleId: "com.apple.Safari", displayName: "Safari")
    }

    override var currentURLScript: String {
        return """
            tell application "Safari"
                if (count of windows) > 0 then
                    set currentTab to current tab of window 1
                    return URL of currentTab
                end if
            end tell
            """
    }
}
