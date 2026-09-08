import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root
    visible: true
    color: "transparent"

    anchors {
        top: true
        right: true
    }
    margins {
        top: 48
        right: 16
    }

    implicitWidth: 260
    implicitHeight: column.implicitHeight + 24

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "theme-switcher"

    ListModel { id: themeModel }

    Process {
        id: lister
        command: ["theme-list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const items = JSON.parse(text)
                    themeModel.clear()
                    for (const it of items) themeModel.append(it)
                } catch (e) {
                    console.log("theme-list parse error:", e, text)
                }
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: applier
    }

    Timer {
        id: closeTimer
        interval: 150
        onTriggered: Qt.quit()
    }

    function applyTheme(id) {
        // theme-apply takes several seconds (dms restart alone sleeps 3s,
        // then matugen renders GTK/Qt/kitty/Hyprland/nvim). Qt.quit() below
        // tears down `applier`, and Qt kills a QProcess's still-running child
        // when its wrapper object is destroyed -- so without detaching,
        // this decapitates theme-apply moments after it starts.
        //
        // Tried `setsid -f theme-apply id` and `setsid -f bash -c 'exec
        // theme-apply "$0"' id` as this Process's own command to detach it --
        // both proved unreliable under real testing (theme-apply sometimes
        // silently never started, sometimes started and got cut off anyway;
        // reproduced repeatedly, not a one-off). Whatever the exact cause,
        // it's specific to spawning+detaching from within a QProcess-backed
        // Quickshell Process, since the identical setsid invocation is 100%
        // reliable from a plain shell.
        //
        // Instead of fighting that, hand the actual spawn to Hyprland itself
        // via `hyprctl eval`, the same hl.dispatch(hl.dsp.exec_cmd(...)) path
        // every keybind in hyprland.lua already uses reliably. theme-apply
        // then runs as Hyprland's own child, not this widget's -- immune to
        // Qt.quit() below since it's outside this process's tree entirely.
        // `applier` itself only has to run the near-instant `hyprctl eval`
        // call, which is long finished before closeTimer fires.
        const luaCmd = 'hl.dispatch(hl.dsp.exec_cmd("theme-apply ' + id + '"))'
        applier.command = ["hyprctl", "eval", luaCmd]
        applier.running = true
        closeTimer.start()
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: "#1a1a1a"
        border.color: "#333333"
        border.width: 1

        Column {
            id: column
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text {
                text: "Theme"
                color: "#cccccc"
                font.pixelSize: 14
                font.bold: true
                bottomPadding: 4
            }

            Repeater {
                model: themeModel
                delegate: Rectangle {
                    required property string id
                    required property string name
                    required property string primary

                    width: column.width
                    height: 40
                    radius: 8
                    color: hover.hovered ? "#2a2a2a" : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 10

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: primary
                            border.color: "#00000055"
                            border.width: 1
                        }

                        Text {
                            text: name
                            color: "#eeeeee"
                            font.pixelSize: 13
                            Layout.fillWidth: true
                        }
                    }

                    HoverHandler { id: hover }
                    TapHandler {
                        onTapped: root.applyTheme(id)
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Qt.quit()
    }
}
