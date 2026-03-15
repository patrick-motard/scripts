// Connect to native messaging host and handle requests
let port = null;

function connect() {
  port = browser.runtime.connectNative("tab_search_host");

  port.onMessage.addListener(async (msg) => {
    const id = msg._id;
    if (msg.action === "list_tabs") {
      const tabs = await browser.tabs.query({});
      const result = tabs.map(t => ({
        id: t.id,
        title: t.title || "",
        url: t.url || "",
        windowId: t.windowId,
        active: t.active
      }));
      port.postMessage({ _id: id, tabs: result });
    } else if (msg.action === "focus_tab") {
      await browser.tabs.update(msg.tabId, { active: true });
      await browser.windows.update(msg.windowId, { focused: true });
      port.postMessage({ _id: id, ok: true });
    } else if (msg.action === "list_bookmarks") {
      // Recursively collect all bookmarks (skip folders)
      const collect = (nodes) => {
        let out = [];
        for (const node of nodes) {
          if (node.url) {
            out.push({ title: node.title || "", url: node.url });
          }
          if (node.children) {
            out = out.concat(collect(node.children));
          }
        }
        return out;
      };
      const tree = await browser.bookmarks.getTree();
      const bookmarks = collect(tree);
      // Also send open tabs so Hammerspoon can match
      const tabs = await browser.tabs.query({});
      const openTabs = tabs.map(t => ({ id: t.id, url: t.url, windowId: t.windowId }));
      port.postMessage({ _id: id, bookmarks, openTabs });
    } else if (msg.action === "open_url") {
      // Open in new tab
      await browser.tabs.create({ url: msg.url });
      port.postMessage({ _id: id, ok: true });
    }
  });

  port.onDisconnect.addListener(() => {
    const err = browser.runtime.lastError;
    console.error("Native host disconnected:", err ? err.message : "unknown reason");
    port = null;
    // Reconnect after a short delay
    setTimeout(connect, 1000);
  });
}

connect();
