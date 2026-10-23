import Foundation

class ArcBrowser: BaseBrowser {
    init() {
        super.init(bundleId: "company.thebrowser.Browser", displayName: "Arc")
    }

    override var currentURLScript: String {
        return """
            tell application "Arc"
                if (count of windows) > 0 then
                    tell front window
                        try
                            return URL of active tab
                        on error errMsg number errNum
                            if errNum is -1728 and errMsg contains "active tab" then
                                return missing value
                            else
                                error errMsg number errNum
                            end if
                        end try
                    end tell
                end if
            end tell
            """
    }

}
