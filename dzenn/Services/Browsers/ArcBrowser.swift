import Foundation

class ArcBrowser: BaseBrowser {
    init() {
        super.init(bundleId: "company.com.Arc", displayName: "Arc")
    }

    override var currentURLScript: String {
        return """
            tell application "Arc"
                if (count of windows) > 0 then
                    set currentTab to active tab of window 1
                    return URL of currentTab
                end if
            end tell
            """
    }
}
