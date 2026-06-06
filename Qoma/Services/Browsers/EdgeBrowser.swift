import Foundation

class EdgeBrowser: BaseBrowser {
    init() {
        super.init(bundleId: "com.microsoft.edgemac", displayName: "Edge")
    }

    override var currentURLScript: String {
        return """
            tell application "Microsoft Edge"
                if (count of windows) > 0 then
                    set currentTab to active tab of window 1
                    return URL of currentTab
                end if
            end tell
            """
    }
}
