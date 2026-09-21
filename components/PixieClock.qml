/*
 * Pixie Lockscreen — PixieClock
 * Color transform ported from Pixie SDDM's components/Clock.qml; baseAccent
 * comes from this lockscreen's PixieAccentExtractor.
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */
import QtQuick

Item {
    id: clock

    property string fontFamily: "FlexRounded"
    property color baseAccent: "#AED68A"
    property color smartHoursColor: "#AED68A"
    property color smartMinutesColor: "#D4E4BC"
    property string timeStr: ""

    function updateTime() {
        const date = new Date();
        let hours = date.getHours();
        const minutes = date.getMinutes();

        // Preserve the lockscreen's 24-hour setting.
        if (!config.use24HourClock) {
            hours = hours % 12;
            if (hours === 0) hours = 12;
        }

        const hStr = hours < 10 ? "0" + hours : "" + hours;
        const mStr = minutes < 10 ? "0" + minutes : "" + minutes;
        clock.timeStr = hStr + mStr;
    }

    // EXACT Pixie SDDM Clock.qml color transform.
    function updateColors() {
        const base = clock.baseAccent;

        if (base.hsvSaturation < 0.15) {
            clock.smartHoursColor = Qt.lighter(base, 1.3);
            clock.smartMinutesColor = Qt.darker(base, 1.4);
            return;
        }
        if (base.hsvValue < 0.5) {
            clock.smartHoursColor = Qt.hsva(base.hsvHue, 0.7, 0.9, 1.0);
            clock.smartMinutesColor = Qt.hsva(base.hsvHue, 0.45, 0.85, 1.0);
        } else if (base.hsvValue > 0.8 && base.hsvSaturation < 0.2) {
            clock.smartHoursColor = Qt.hsva(base.hsvHue, 0.8, 0.7, 1.0);
            clock.smartMinutesColor = Qt.hsva(base.hsvHue, 0.5, 0.75, 1.0);
        } else {
            clock.smartHoursColor = Qt.hsva(base.hsvHue, Math.min(1.0, base.hsvSaturation * 1.3), 0.95, 1.0);
            clock.smartMinutesColor = Qt.hsva(base.hsvHue, Math.min(1.0, base.hsvSaturation * 0.75), 0.92, 1.0);
        }
    }

    onBaseAccentChanged: updateColors()

    Component.onCompleted: {
        updateColors();
        updateTime();
    }

    implicitWidth: digitRow.implicitWidth
    implicitHeight: digitRow.implicitHeight

    Row {
        id: digitRow
        anchors.centerIn: parent
        spacing: 0

        Column {
            spacing: -130
            Text {
                text: clock.timeStr.charAt(0)
                color: clock.smartHoursColor
                font.pixelSize: 200
                font.family: clock.fontFamily
                font.weight: Font.Medium
                width: 130
                horizontalAlignment: Text.AlignHCenter
                antialiasing: true
            }
            Text {
                text: clock.timeStr.charAt(2)
                color: clock.smartMinutesColor
                font.pixelSize: 200
                font.family: clock.fontFamily
                font.weight: Font.Medium
                width: 130
                horizontalAlignment: Text.AlignHCenter
                antialiasing: true
            }
        }

        Column {
            spacing: -130
            Text {
                text: clock.timeStr.charAt(1)
                color: clock.smartHoursColor
                font.pixelSize: 200
                font.family: clock.fontFamily
                font.weight: Font.Medium
                width: 130
                horizontalAlignment: Text.AlignHCenter
                antialiasing: true
            }
            Text {
                text: clock.timeStr.charAt(3)
                color: clock.smartMinutesColor
                font.pixelSize: 200
                font.family: clock.fontFamily
                font.weight: Font.Medium
                width: 130
                horizontalAlignment: Text.AlignHCenter
                antialiasing: true
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: updateTime()
    }
}
