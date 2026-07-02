// Quickshell top bar — Tokyo Night, single file.
// Left:  workspaces (persistent 1-5 + occupied), focused window title
// Right: volume, network, tray, clock

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    // ── Theme ────────────────────────────────────────────────────────────
    property color colBg: "#1a1b26"
    property color colFg: "#c0caf5"
    property color colAccent: "#7aa2f7"
    property color colPurple: "#bb9af7"
    property color colMuted: "#414868"
    property color colRed: "#f7768e"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 13

    // ── State ────────────────────────────────────────────────────────────
    property string activeWindow: ""
    property int volumeLevel: 0
    property bool volumeMuted: false
    property string netStatus: "offline" // "ethernet" | "wifi" | "offline"
    property var now: new Date()
    property bool clockShowDate: false

    // ── Focused window title (hyprctl, event-driven + slow fallback) ────
    Process {
        id: windowProc
        command: ["sh", "-c", "hyprctl activewindow -j 2>/dev/null | tr -d '\\n'; echo"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.activeWindow = JSON.parse(data).title ?? ""
                } catch (e) {
                    root.activeWindow = ""
                }
            }
        }
        Component.onCompleted: running = true
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            windowProc.running = true
        }
    }

    // ── Volume (wpctl polling — tony-btw's proven pattern) ──────────────
    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                var match = data.match(/Volume:\s*([\d.]+)/)
                if (match)
                    root.volumeLevel = Math.round(parseFloat(match[1]) * 100)
                root.volumeMuted = data.indexOf("MUTED") !== -1
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: volActionProc
    }

    function volAction(args) {
        // restart so rapid actions (scroll steps) aren't dropped on a running process
        volActionProc.running = false
        volActionProc.command = ["wpctl"].concat(args)
        volActionProc.running = true
        volRefresh.restart()
    }

    Timer {
        id: volRefresh
        interval: 150
        onTriggered: volProc.running = true
    }

    // ── Network (nmcli polling, 5s) ──────────────────────────────────────
    Process {
        id: netProc
        command: ["sh", "-c",
            "out=$(nmcli -t -f TYPE,STATE device status 2>/dev/null" +
            " | awk -F: '$2 ~ /^connected/ && ($1==\"ethernet\"||$1==\"wifi\"){print $1; exit}');" +
            " echo \"${out:-offline}\""]
        stdout: SplitParser {
            onRead: data => root.netStatus = data.trim()
        }
        Component.onCompleted: running = true
    }

    // ── Timers ───────────────────────────────────────────────────────────
    Timer { // slow poll: volume drift + window title fallback
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            volProc.running = true
            windowProc.running = true
        }
    }

    Timer { // network
        interval: 5000
        running: true
        repeat: true
        onTriggered: netProc.running = true
    }

    Timer { // clock
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // ── Bar ──────────────────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 30
            color: root.colBg

            RowLayout {
                anchors.fill: parent
                spacing: 6

                Item { implicitWidth: 6 } // + spacing = 12px left pad

                // Workspaces: persistent 1-5, plus any occupied up to 10
                Repeater {
                    model: 10

                    Rectangle {
                        property var workspace: Hyprland.workspaces.values.find(ws => ws.id === index + 1) ?? null
                        property bool isActive: Hyprland.focusedWorkspace?.id === index + 1
                        property bool occupied: workspace !== null

                        visible: index < 5 || occupied || isActive
                        Layout.preferredWidth: 22
                        Layout.fillHeight: true
                        color: "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: index + 1
                            color: parent.isActive ? root.colAccent
                                 : parent.occupied ? root.colFg
                                 : root.colMuted
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize
                            font.bold: parent.isActive
                        }

                        Rectangle {
                            width: 18
                            height: 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            color: parent.isActive ? root.colAccent : "transparent"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Hyprland.dispatch("workspace " + (index + 1))
                        }
                    }
                }

                // Focused window title
                Text {
                    visible: root.activeWindow !== ""
                    text: root.activeWindow
                    color: root.colMuted
                    font.family: root.fontFamily
                    font.pixelSize: root.fontSize
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    Layout.leftMargin: 8
                    Layout.maximumWidth: 320 // ~40ch at this size
                }

                Item { Layout.fillWidth: true } // spacer

                // Volume: click = mute toggle, scroll = +/- 2%
                Text {
                    text: root.volumeMuted ? "󰝟 muted"
                                           : "󰕾 " + root.volumeLevel + "%"
                    color: root.volumeMuted ? root.colMuted : root.colFg
                    font.family: root.fontFamily
                    font.pixelSize: root.fontSize

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.volAction(["set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                        onWheel: wheel => root.volAction(
                            ["set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@",
                             wheel.angleDelta.y > 0 ? "2%+" : "2%-"])
                    }
                }

                // Network
                Text {
                    text: root.netStatus === "ethernet" ? "󰈀 eth"
                        : root.netStatus === "wifi" ? "󰖩 wifi"
                        : "󰖪 offline"
                    color: root.netStatus === "offline" ? root.colRed : root.colFg
                    font.family: root.fontFamily
                    font.pixelSize: root.fontSize
                }

                // System tray
                Repeater {
                    model: SystemTray.items

                    Image {
                        source: modelData.icon
                        sourceSize.width: 18
                        sourceSize.height: 18
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        Layout.alignment: Qt.AlignVCenter

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.LeftButton)
                                    modelData.activate()
                                else
                                    modelData.secondaryActivate()
                            }
                        }
                    }
                }

                // Clock: click toggles date
                Text {
                    text: Qt.formatDateTime(root.now,
                        root.clockShowDate ? "ddd dd MMM  HH:mm" : "HH:mm")
                    color: root.colPurple
                    font.family: root.fontFamily
                    font.pixelSize: root.fontSize
                    font.bold: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.clockShowDate = !root.clockShowDate
                    }
                }

                Item { implicitWidth: 6 } // + spacing = 12px right pad
            }
        }
    }
}
