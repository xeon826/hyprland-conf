import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless

    property string batteryText: "🎮 --"
    property int batteryLevel: 0
    property bool available: false
    property bool isCharging: false

    implicitWidth: batteryTextItem.implicitWidth + 10
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    Timer {
        id: updateTimer
        interval: 180000 // Update every 180 seconds (3 minutes, same as AwesomeWM)
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: getBattery.running = true
    }

    Process {
        id: getBattery
        command: ["/usr/bin/dualsensectl", "battery"]
        stdout: SplitParser {
            onRead: (data) => {
                const output = data.trim()

                if (output && output !== "") {
                    if (output.match(/No device found/)) {
                        root.batteryText = "🎮 --"
                        root.available = false
                        root.isCharging = false
                        return
                    }

                    // Parse output like "95 discharging" or "95 charging"
                    const match = output.match(/(\d+)\s+(\w+)/)
                    if (match && match[1] && match[2]) {
                        root.batteryLevel = parseInt(match[1])
                        const status = match[2]
                        root.isCharging = (status === "charging")

                        let statusSymbol = ""
                        if (root.isCharging) {
                            statusSymbol = "⚡"
                        } else if (status === "discharging") {
                            statusSymbol = "🔋"
                        }

                        root.batteryText = "🎮 " + root.batteryLevel + "%" + statusSymbol
                        root.available = true
                    } else {
                        root.batteryText = "🎮 N/A"
                        root.available = false
                        root.isCharging = false
                    }
                } else {
                    root.batteryText = "🎮 --"
                    root.available = false
                    root.isCharging = false
                }
            }
        }
        stderr: SplitParser {
            onRead: (data) => {
                root.batteryText = "🎮 --"
                root.available = false
                root.isCharging = false
            }
        }
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                root.batteryText = "🎮 --"
                root.available = false
                root.isCharging = false
            }
        }
    }

    StyledText {
        id: batteryTextItem
        anchors.centerIn: parent
        text: root.batteryText
        font.pixelSize: Appearance.font.pixelSize.small
        color: Appearance.colors.colOnLayer0
    }

    PopupToolTip {
        id: tooltip
        text: root.available ?
              (root.isCharging ?
               `DualSense controller: ${root.batteryLevel}% (charging)` :
               `DualSense controller: ${root.batteryLevel}%`) :
              "DualSense controller not connected"
        extraVisibleCondition: root.containsMouse && !Config.options.bar.tooltips.clickToShow
        alternativeVisibleCondition: extraVisibleCondition
        anchorEdges: (!Config.options.bar.bottom && !Config.options.bar.vertical) ? Edges.Bottom : Edges.Top
    }

    onClicked: {
        if (Config.options.bar.tooltips.clickToShow) {
            tooltip.visible = !tooltip.visible
        }
    }
}