import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: musicPanel

    property bool visiblePanel: false
    property var matugen: ({})
    property string artUrl: ""
    property string playerStatus: "Stopped"
    property string trackTitle: ""
    property string trackArtist: ""
    property real position: 0
    property real length: 0
    property bool hasTrack: playerStatus === "Playing" || playerStatus === "Paused"

    visible: true
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: visiblePanel ? 60 : -220
    }

    implicitWidth: 400
    implicitHeight: 140
    color: "transparent"

    /* ---------- MATUGEN ---------- */
    FileView {
        id: matugenFile
        path: "/home/rick/.config/quickshell/matugen.json"

        onLoaded: {
            try {
                var txt = text().trim()
                if (txt.length === 0) return
                musicPanel.matugen = JSON.parse(txt)
            } catch(e) {}
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: matugenFile.reload()
    }

    function col(name, fallback) {
        return matugen && matugen[name] !== undefined
            ? matugen[name]
            : fallback
    }

    Behavior on margins.top {
        NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
    }

    /* ---------- MAIN CARD ---------- */
    Rectangle {
        anchors.centerIn: parent
        width: 400
        height: 140
		Layout.bottomMargin: 5
        radius: 30
        color: col("surface", "#282b24")
        border.width: 0
        border.color: col("outline_variant","#44483e")
        clip: true
        antialiasing: true
        layer.enabled: true
		layer.smooth: true

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            /* ---------- ALBUM ART ---------- */
            Rectangle {
                width: 100
                height: 100
                radius: 18
                clip: true
                color: col("surface_variant","#3b3f36")

                Image {
                    anchors.fill: parent
                    source: artUrl
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    antialiasing: true
                    visible: artUrl !== ""
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰝚"
                    font.pixelSize: 36
                    color: col("on_surface_variant","#c4c8ba")
                    visible: artUrl === ""
                }
            }

            /* ---------- TEXT + CONTROLS ---------- */
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                Text {
                    text: trackTitle || "Nothing is playing"
                    color: col("primary","#add18d")
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: trackArtist
                    color: col("on_surface","#e2e3d9")
                    opacity: 0.7
                    font.pixelSize: 12
                    visible: trackArtist !== ""
                }

                Item { Layout.fillHeight: true }

                /* ---------- PROGRESS BAR ---------- */
                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: col("surface_variant","#44483e")

                    Rectangle {
                        width: length > 0 ? parent.width * (position/length) : 0
                        height: parent.height
                        radius: 3
                        color: col("primary","#add18d")
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: mouse => {
                            if(length > 0) {
                                seekProc.command = ["bash","-c",
                                    "playerctl position " +
                                    ((mouse.x/parent.width)*length)]
                                seekProc.running = true
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: hasTrack

                    Text { text: formatTime(position); font.pixelSize: 10; color: col("on_surface_variant","#c4c8ba") }
                    Item { Layout.fillWidth: true }
                    Text { text: formatTime(length); font.pixelSize: 10; color: col("on_surface_variant","#c4c8ba") }
                }

                /* ---------- CONTROLS ---------- */
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    MusicBtn { icon: "󰒮"; cmd: "playerctl previous" }
                    MusicBtn { icon: playerStatus === "Playing" ? "󰏤" : "󰐊"; cmd: "playerctl play-pause"; big: true }
                    MusicBtn { icon: "󰒭"; cmd: "playerctl next" }
                }
            }
        }
    }

    /* ---------- DATA ---------- */
    function formatTime(sec) {
        var m = Math.floor(sec/60)
        var s = Math.floor(sec%60)
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    /* ---------- UPDATE ---------- */
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: musicStatusProc.running = true
    }

    /* ---------- PLAYERCTL ---------- */
    Process { id: musicStatusProc; command: ["bash","-c","playerctl status 2>/dev/null || echo Stopped"]
        stdout: SplitParser { onRead: data => { playerStatus = data.trim(); titleProc.running = true; artistProc.running = true; artProc.running = true; lenProc.running = true; posProc.running = true } }
    }

    Process { id: titleProc; command: ["bash","-c","playerctl metadata title 2>/dev/null"]; stdout: SplitParser { onRead: d => trackTitle = d.trim() } }
    Process { id: artistProc; command: ["bash","-c","playerctl metadata artist 2>/dev/null"]; stdout: SplitParser { onRead: d => trackArtist = d.trim() } }
    Process { id: artProc; command: ["bash","-c","playerctl metadata mpris:artUrl 2>/dev/null"]; stdout: SplitParser { onRead: d => artUrl = d.trim().replace("file://","") } }
    Process { id: posProc; command: ["bash","-c","playerctl position 2>/dev/null || echo 0"]; stdout: SplitParser { onRead: d => position = parseFloat(d) } }
    Process { id: lenProc; command: ["bash","-c","playerctl metadata mpris:length 2>/dev/null | awk '{print $1/1000000}'"]; stdout: SplitParser { onRead: d => length = parseFloat(d) } }
    Process { id: seekProc }

    /* ---------- BUTTON COMPONENT ---------- */
    component MusicBtn: Rectangle {
        property string icon
        property string cmd
        property bool big: false
        width: big ? 44 : 34
        height: width
        radius: big ? 22 : 10
        color: big ? musicPanel.col("primary") : "transparent"

        Text { anchors.centerIn: parent; text: icon; font.pixelSize: 18; color: big ? musicPanel.col("on_primary") : musicPanel.col("on_surface") }

        MouseArea { anchors.fill: parent; onClicked: proc.running = true }

        Process { id: proc; command: ["bash","-c", cmd] }
    }

    /* ---------- IPC ---------- */
    IpcHandler {
        target: "music"
        function toggle(): void { visiblePanel = !visiblePanel }
        function show(): void { visiblePanel = true }
        function hide(): void { visiblePanel = false }
    }
}
