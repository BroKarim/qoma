import Foundation

class VivaldiBrowser: BaseBrowser {
    init() {
        super.init(bundleId: "com.vivaldi.Vivaldi", displayName: "Vivaldi")
    }

    override var currentURLScript: String {
        return """
            tell application "Vivaldi"
                if (count of windows) > 0 then
                    set currentTab to active tab of window 1
                    return URL of currentTab
                end if
            end tell
            """
    }
}
