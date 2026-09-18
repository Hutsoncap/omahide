import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omahide"

  property var icons: []

  readonly property int workspaceId: {
    var ws = Hyprland.focusedWorkspace
    return ws && ws.id > 0 ? ws.id : 0
  }

  readonly property int count: icons.length
  readonly property int slot: Style.bar.iconSlot
  readonly property int canvas: Style.bar.iconCanvas

  visible: count > 0
  implicitWidth: count > 0 ? (count * slot + Math.max(0, count - 1) * Style.space(1)) : 0
  implicitHeight: barSize

  FileView {
    id: hideFile
    path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/omahide.json"
    watchChanges: true
    printErrors: false
    onFileChanged: hideFile.reload()
    onLoaded: root.rebuild()
  }

  function iconSource(klass, title) {
    var k = String(klass || "")
    var blob = (k + " " + String(title || "")).toLowerCase()
    if (blob.indexOf("flea") !== -1) return Qt.resolvedUrl("flea.png")
    if (blob.indexOf("x.com") !== -1) return Qt.resolvedUrl("x.png")
    if (k.toLowerCase() === "helium") return Qt.resolvedUrl("helium.png")
    var m = k.match(/chrome-([a-z0-9-]+)/i)
    if (m) return "file:///usr/share/icons/hicolor/256x256/apps/" + m[1].toLowerCase() + ".png"
    var themed = k ? Quickshell.iconPath(k, true) : ""
    return themed || Quickshell.iconPath("application-x-executable", true)
  }

  function rebuild() {
    var raw = []
    try {
      var text = hideFile.text()
      if (text) raw = JSON.parse(text)
    } catch (e) { raw = [] }
    if (!Array.isArray(raw)) raw = []

    var want = workspaceId > 0 ? "special:hidden-" + workspaceId : ""
    var next = []
    var seenAddr = {}
    for (var i = 0; i < raw.length; i++) {
      var c = raw[i]
      if (!c || String(c.workspace || "") !== want) continue
      var addr = String(c.address || "").replace(/^0x/i, "").toLowerCase()
      var klass = String(c["class"] || "")
      if (!addr || seenAddr[addr]) continue
      seenAddr[addr] = true
      next.push({
        address: String(c.address || ""),
        klass: klass,
        title: String(c.title || ""),
        source: iconSource(klass, c.title)
      })
    }
    icons = next
  }

  function restore(addr) {
    var hex = String(addr || "").replace(/^0x/i, "")
    if (!/^[0-9a-f]+$/i.test(hex) || workspaceId <= 0) return
    Util.execDetached("hyprctl eval " + Util.shellQuote("omahide_restore('0x" + hex + "', " + String(workspaceId) + ")"))
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(1)

    Repeater {
      model: root.count
      WidgetButton {
        required property int index
        readonly property var item: root.icons[index] || {}
        bar: root.bar
        hasVisualContent: true
        labelVisible: false
        tooltipText: item.title || ""
        fixedWidth: root.slot
        onPressed: function(button) {
          if (button === Qt.LeftButton) root.restore(item.address)
        }
        Image {
          anchors.centerIn: parent
          width: root.canvas
          height: root.canvas
          fillMode: Image.PreserveAspectFit
          asynchronous: false
          source: item.source || ""
        }
      }
    }
  }

  onWorkspaceIdChanged: rebuild()
  Component.onCompleted: hideFile.reload()
}
