import Foundation

class BraveBrowser: BaseBrowser {
    init() {
        super.init(bundleId: "com.brave.Browser", displayName: "Brave")
    }

    override var currentURLScript: String {
        return """
            tell application "Brave Browser"
                if (count of windows) > 0 then
                    set currentTab to active tab of window 1
                    return URL of currentTab
                end if
            end tell
            """
    }
}
