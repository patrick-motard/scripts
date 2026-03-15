-- Firefox tab switcher for Hammerspoon
-- Queries tabs via Unix socket from native messaging host
-- Requires: firefox-tab-search extension + host installed

local SOCKET_PATH = "/tmp/firefox-tab-search.sock"

local function queryTabs(callback)
    hs.task.new("/bin/sh", function(code, stdout, stderr)
        if code ~= 0 or stdout == "" then
            hs.notify.new({ informativeText = "Tab search: host not responding. Is the Firefox extension loaded?" }):send()
            return
        end
        local ok, result = pcall(hs.json.decode, stdout)
        if ok and result and result.tabs then
            callback(result.tabs)
        else
            hs.notify.new({ informativeText = "Tab search: bad response: " .. tostring(stdout) }):send()
        end
    end, { "-c", "echo '{\"action\":\"list_tabs\"}' | nc -U " .. SOCKET_PATH }):start()
end

local function focusTab(tabId, windowId)
    local msg = string.format('{"action":"focus_tab","tabId":%d,"windowId":%d}', tabId, windowId)
    hs.task.new("/bin/sh", function()
        local ff = hs.application.get("Firefox")
        if ff then ff:activate() end
    end, { "-c", "echo '" .. msg .. "' | nc -U " .. SOCKET_PATH }):start()
end

function showTabChooser()
    queryTabs(function(tabs)
        local choices = {}
        for _, tab in ipairs(tabs) do
            table.insert(choices, {
                text = tab.title,
                subText = tab.url,
                tabId = tab.id,
                windowId = tab.windowId,
            })
        end

        local chooser = hs.chooser.new(function(choice)
            if choice then
                focusTab(choice.tabId, choice.windowId)
            end
        end)

        chooser:choices(choices)
        chooser:searchSubText(true)
        chooser:bgDark(true)
        chooser:fgColor({ hex = "#ebdbb2" })
        chooser:subTextColor({ hex = "#a89984" })
        chooser:placeholderText("Search tabs...")
        chooser:show()
    end)
end

local function queryBookmarks(callback)
    local tmpfile = "/tmp/hs-bookmarks-$$.json"
    hs.task.new("/bin/sh", function(code, stdout, stderr)
        local f = io.open("/tmp/hs-bookmarks.json", "r")
        if not f then
            hs.notify.new({ informativeText = "Bookmark search: host not responding. Is the Firefox extension loaded?" }):send()
            return
        end
        local data = f:read("*a")
        f:close()
        os.remove("/tmp/hs-bookmarks.json")
        local ok, result = pcall(hs.json.decode, data)
        if ok and result and result.bookmarks then
            callback(result.bookmarks, result.openTabs)
        else
            hs.notify.new({ informativeText = "Bookmark search: bad response" }):send()
        end
    end, { "-c", "echo '{\"action\":\"list_bookmarks\"}' | nc -U " .. SOCKET_PATH .. " > /tmp/hs-bookmarks.json" }):start()
end

local function openUrl(url)
    local msg = string.format('{"action":"open_url","url":"%s"}', url:gsub('"', '\\"'))
    hs.task.new("/bin/sh", function()
        local ff = hs.application.get("Firefox")
        if ff then ff:activate() end
    end, { "-c", "echo '" .. msg:gsub("'", "'\\''") .. "' | nc -U " .. SOCKET_PATH }):start()
end

function showBookmarkChooser()
    queryBookmarks(function(bookmarks, openTabs)
        -- Build a URL -> tab lookup for quick matching
        local tabByUrl = {}
        for _, tab in ipairs(openTabs or {}) do
            tabByUrl[tab.url] = tab
        end

        local choices = {}
        for _, bm in ipairs(bookmarks) do
            local isOpen = tabByUrl[bm.url] ~= nil
            table.insert(choices, {
                text = bm.title,
                subText = (isOpen and "open - " or "") .. bm.url,
                bmUrl = bm.url,
                isOpen = isOpen,
                openTab = tabByUrl[bm.url],
            })
        end

        local chooser = hs.chooser.new(function(choice)
            if not choice then return end
            if choice.isOpen then
                focusTab(choice.openTab.id, choice.openTab.windowId)
            else
                openUrl(choice.bmUrl)
                local ff = hs.application.get("Firefox")
                if ff then ff:activate() end
            end
        end)

        chooser:choices(choices)
        chooser:searchSubText(true)
        chooser:bgDark(true)
        chooser:fgColor({ hex = "#ebdbb2" })
        chooser:subTextColor({ hex = "#a89984" })
        chooser:placeholderText("Search bookmarks...")
        chooser:show()
    end)
end

hs.hotkey.bind(hyper, "t", "Firefox Tab Search", showTabChooser)
hs.hotkey.bind(hyper, "b", "Firefox Bookmark Search", showBookmarkChooser)
