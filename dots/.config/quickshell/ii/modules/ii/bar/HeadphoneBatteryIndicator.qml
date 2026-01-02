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

    property string batteryText: "🎧 --"
    property int batteryLevel: 0
    property bool available: false

    implicitWidth: batteryTextItem.implicitWidth + 10
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    Timer {
        id: updateTimer
        interval: 60000 // Update every 60 seconds (same as AwesomeWM)
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: getBattery.running = true
    }

    Component.onCompleted: getBattery.running = true

    Process {
        id: getBattery
        command: ["/home/dan/.local/bin/headsetcontrol", "-b"]
        stdout: SplitParser {
            onRead: (data) => {
                const output = data
                if (output && output.trim() !== "") {
                    // Parse output like "Level: 99%"
                    const lines = output.split('\n')
                    for (const line of lines) {
                        const match = line.match(/Level:\s*(\d+)%/)
                        if (match && match[1]) {
                            root.batteryLevel = parseInt(match[1])
                            root.batteryText = "🎧 " + root.batteryLevel + "%"
                            root.available = true
                            return
                        }
                    }
                    // If no battery level found
                    root.batteryText = "🎧 N/A"
                    root.available = false
                } else {
                    root.batteryText = "🎧 --"
                    root.available = false
                }
            }
        }
        stderr: SplitParser {
            onRead: (data) => {
                root.batteryText = "🎧 --"
                root.available = false
            }
        }
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                root.batteryText = "🎧 --"
                root.available = false
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
              `Headphone battery: ${root.batteryLevel}%` :
              "Headphone not connected"
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