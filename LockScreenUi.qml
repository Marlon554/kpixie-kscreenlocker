/*
 * Pixie Lockscreen — LockScreenUi
 * Visual design: Pixie SDDM by xCaptaiN09 (MIT)
 * Base: Plasma kscreenlocker (GPL-2.0-or-later)
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.workspace.components as PW
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator
import org.kde.plasma.private.battery
import org.kde.kirigami as Kirigami
import org.kde.kscreenlocker as ScreenLocker

import org.kde.plasma.private.sessions
import org.kde.breeze.components

import "components"

Item {
    id: lockScreenUi

    // ── Pixie palette (literal values from pixie-sddm/theme.conf) ───────────
    readonly property color baseColor: "#1A1C18"
    readonly property color surfaceColor: Qt.lighter(baseColor, 1.30)
    readonly property color surfaceVariantColor: Qt.lighter(baseColor, 1.60)
    readonly property color textColor: "#E3E3DC"

    // Accent: extracted from the wallpaper when enabled, else the Plasma theme color.
    property color themeAccent: Kirigami.Theme.highlightColor
    readonly property color accent: config.autoAccentColor
                                     ? accentExtractor.extractedColor
                                     : themeAccent

    // Chrome (date/PowerBar/clock) stays hidden until the accent is ready,
    // so it never flashes the fallback color first.
    readonly property bool uiReady: !config.autoAccentColor || accentExtractor.processed

    PixieAccentExtractor {
        id: accentExtractor
        fallbackColor: lockScreenUi.themeAccent
        source: config.autoAccentColor ? wallpaper : null
    }

    property alias sessionManagement: sessionManagement
    property alias pixieFontMedium:   pixieFontMedium
    property alias pixieFontRegular:  pixieFontRegular
    property alias pixieFontBold:     pixieFontBold
    property alias pixieFontIcons:    pixieFontIcons

    FontLoader { id: pixieFontRegular; source: "assets/fonts/FlexRounded-R.ttf" }
    FontLoader { id: pixieFontMedium;  source: "assets/fonts/FlexRounded-M.ttf" }
    FontLoader { id: pixieFontBold;    source: "assets/fonts/FlexRounded-B.ttf" }
    // Needed for PowerBar glyphs (battery/charging/suspend icons).
    FontLoader { id: pixieFontIcons;   source: "assets/fonts/MaterialDesignIcons.ttf" }

    function handleMessage(msg) {
        if (!root.notification) {
            root.notification += msg;
        } else if (root.notification.includes(msg)) {
            root.notificationRepeated();
        } else {
            root.notification += "\n" + msg;
        }
    }

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary

    Connections {
        target: authenticator
        function onFailed(kind) {
            if (kind !== 0) return;
            lockScreenUi.handleMessage(
                i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:status", "Unlocking failed"));
            graceLockTimer.restart();
            notificationRemoveTimer.restart();
            rejectPasswordAnimation.start();
        }
        function onSucceeded() {
            if (authenticator.hadPrompt) {
                Qt.quit();
            } else {
                mainStack.replace(null, Qt.resolvedUrl("NoPasswordUnlock.qml"),
                    { userListModel: users }, StackView.Immediate);
                mainStack.forceActiveFocus();
            }
        }
        function onInfoMessageChanged()  { lockScreenUi.handleMessage(authenticator.infoMessage); }
        function onErrorMessageChanged() { lockScreenUi.handleMessage(authenticator.errorMessage); }
        function onPromptChanged()       { lockScreenUi.handleMessage(authenticator.prompt); }
        function onPromptForSecretChanged() {
            mainBlock.mainPasswordBox.forceActiveFocus();
        }
    }

    SessionManagement { id: sessionManagement }
    KeyboardIndicator.KeyState { id: numLockState; key: Qt.Key_NumLock }

    Connections {
        target: sessionManagement
        // Also hide the login card: if it was left open, a spurious key
        // event on resume could otherwise land on an already-focused,
        // empty password field and auto-submit a blank password — which
        // counts as a failed attempt and triggers escalating lockout delays.
        function onAboutToSuspend() {
            root.clearPassword();
            lockScreenRoot.uiVisible = false;
        }
    }

    RejectPasswordAnimation { id: rejectPasswordAnimation; target: mainBlock }

    ListModel {
        id: users
        Component.onCompleted: {
            users.append({
                name:     kscreenlocker_userName,
                realName: kscreenlocker_userName,
                icon:     kscreenlocker_userImage !== ""
                          ? "file://" + kscreenlocker_userImage
                                            .split("/").map(encodeURIComponent).join("/")
                          : "",
            });
        }
    }

    // ── Root mouse area ────────────────────────────────────────────────────
    MouseArea {
        id: lockScreenRoot

        property bool uiVisible: false
        property bool blockUI: containsMouse
                               && (mainStack.depth > 1
                                   || mainBlock.mainPasswordBox.text.length > 0
                                   || inputPanel.keyboardActive)

        anchors.fill: parent
        hoverEnabled: true
        focus: true
        cursorShape: uiVisible ? Qt.ArrowCursor : Qt.BlankCursor
        drag.filterChildren: true

        // Card only reveals on click or key press, never on mouse movement.
        onPressed: uiVisible = true
        onUiVisibleChanged: {
            if (uiVisible) Window.window.requestActivate();
            if (blockUI)        fadeoutTimer.running = false;
            else if (uiVisible) fadeoutTimer.restart();
            authenticator.startAuthenticating();
        }
        onBlockUIChanged: {
            if (blockUI) { fadeoutTimer.running = false; uiVisible = true; }
            else           fadeoutTimer.restart();
        }
        onExited: uiVisible = false

        // Any key reveals the card when hidden; Esc hides it again when visible.
        Keys.onPressed: event => {
            if (!uiVisible) {
                uiVisible = true;
                mainBlock.mainPasswordBox.forceActiveFocus();
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Escape) {
                uiVisible = false;
                if (inputPanel.keyboardActive) inputPanel.showHide();
                root.clearPassword();
                event.accepted = true;
            }
        }

        Timer {
            id: fadeoutTimer; interval: 10000
            onTriggered: { if (!lockScreenRoot.blockUI) lockScreenRoot.uiVisible = false; }
        }
        Timer { id: notificationRemoveTimer; interval: 3000; onTriggered: root.notification = "" }
        Timer {
            id: graceLockTimer; interval: 3000
            onTriggered: { root.clearPassword(); authenticator.startAuthenticating(); }
        }

        PropertyAnimation {
            id: launchAnimation; target: lockScreenRoot; property: "opacity"
            from: 0; to: 1; duration: Kirigami.Units.veryLongDuration * 2
        }
        Component.onCompleted: {
            launchAnimation.start();
            forceActiveFocus();
        }

        // Wallpaper blur: sharp at idle, blurs in once the login card opens.
        MultiEffect {
            id: backgroundBlur
            anchors.fill: parent
            source: wallpaper
            blurEnabled: true
            blur: lockScreenRoot.uiVisible ? 1.0 : 0.0
            opacity: lockScreenRoot.uiVisible ? 1.0 : 0.0
            autoPaddingEnabled: false

            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
            Behavior on blur { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
        }

        // Dark overlay — idle: 0.4, login: 0.6 (Pixie Main.qml values)
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: lockScreenRoot.uiVisible ? 0.6 : 0.4
            Behavior on opacity { NumberAnimation { duration: 400 } }
            z: 1
        }

        // ── Top bar ────────────────────────────────────────────────────────
        Item {
            id: topBar
            z: 10
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 80

            // Date label (Pixie layout values)
            Text {
                id: dateLabel
                anchors { top: parent.top; left: parent.left; topMargin: 50; leftMargin: 60 }
                text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
                color: lockScreenUi.accent
                font.pixelSize: 22
                font.family: pixieFontRegular.name
                opacity: lockScreenUi.uiReady ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
                Timer {
                    interval: 60000; running: true; repeat: true
                    onTriggered: dateLabel.text = Qt.formatDateTime(new Date(), "dddd, MMMM d")
                }
            }

            // PowerBar (Pixie layout values)
            Row {
                id: powerBarRow
                anchors { top: parent.top; right: parent.right; topMargin: 30; rightMargin: 40 }
                spacing: 20
                height: 30
                opacity: lockScreenUi.uiReady ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                // Battery — hidden on desktops without a battery
                Row {
                    spacing: 5
                    anchors.verticalCenter: parent.verticalCenter
                    visible: batteryControl.hasInternalBatteries

                    BatteryControlModel { id: batteryControl }

                    Text {
                        text: batteryControl.percent + "%"
                        color: lockScreenUi.accent
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: batteryControl.pluggedIn ? "󱐋" : "󰁹"
                        color: lockScreenUi.accent
                        font.pixelSize: 18
                        font.family: pixieFontIcons.name
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Keyboard layout
                PW.KeyboardLayoutSwitcher {
                    id: keyboardLayoutSwitcher
                    anchors.verticalCenter: parent.verticalCenter
                    width: kbLayoutText.implicitWidth
                    height: 30
                    acceptedButtons: Qt.NoButton
                    visible: hasMultipleKeyboardLayouts

                    Text {
                        id: kbLayoutText
                        anchors.centerIn: parent
                        text: keyboardLayoutSwitcher.layoutNames.shortName
                              || keyboardLayoutSwitcher.layoutNames.longName || "??"
                        color: lockScreenUi.accent
                        font.pixelSize: 14
                        font.capitalization: Font.AllUppercase
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: keyboardLayoutSwitcher.keyboardLayout.switchToNextLayout()
                    }
                }

                // Virtual keyboard toggle — no Pixie equivalent (SDDM greeters
                // don't need one); styled to match the PowerBar icons it sits beside.
                Text {
                    text: inputPanel.keyboardActive ? "󰌐" : "󰌌"
                    color: lockScreenUi.accent
                    font.pixelSize: 20
                    font.family: pixieFontIcons.name
                    anchors.verticalCenter: parent.verticalCenter
                    visible: inputPanel.status === Loader.Ready
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            mainBlock.mainPasswordBox.forceActiveFocus();
                            inputPanel.showHide();
                        }
                    }
                }

                // Suspend — 󰤄 (Pixie PowerBar icon)
                Text {
                    text: "󰤄"
                    color: lockScreenUi.accent
                    font.pixelSize: 20
                    font.family: pixieFontIcons.name
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        id: suspendArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.suspendToRamSupported
                                   ? root.suspendToRam()
                                   : sessionManagement.suspend()
                    }
                }
            }
        }

        // ── Clock — centered, fades out when login UI appears ──────────────
        Item {
            z: 5
            anchors.centerIn: parent
            width:  pixieClock.implicitWidth
            height: pixieClock.implicitHeight
            opacity: lockScreenRoot.uiVisible ? 0 : 1
            Behavior on opacity {
                NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
            }
            PixieClock {
                id: pixieClock
                baseAccent:   lockScreenUi.accent
                fontFamily:   pixieFontMedium.name
                opacity: lockScreenUi.uiReady ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
        }

        // ── "Press any key to unlock" hint — restored from Pixie SDDM ───────
        Text {
            z: 5
            text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:status",
                         "Press any key to unlock")
            color: lockScreenUi.textColor
            font.pixelSize: 16
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 100
            }
            opacity: lockScreenRoot.uiVisible ? 0 : 0.5
            Behavior on opacity {
                NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
            }
        }

        // ── Login card ─────────────────────────────────────────────────────
        StackView {
            id: mainStack
            anchors.fill: parent
            z: 8
            focus: true
            visible: opacity > 0

            initialItem: MainBlock {
                id: mainBlock
                lockScreenUiVisible: lockScreenRoot.uiVisible
                enabled: !graceLockTimer.running
                userListModel: users
                numLockOn: numLockState.locked
                accent: lockScreenUi.accent
                pixieFont: lockScreenUi.pixieFontRegular.name
                pixieFontBold: lockScreenUi.pixieFontBold.name
                baseColor: lockScreenUi.baseColor
                surfaceColor: lockScreenUi.surfaceColor
                surfaceVariantColor: lockScreenUi.surfaceVariantColor
                textColor: lockScreenUi.textColor
                sessionManagement: lockScreenUi.sessionManagement

                StackView.onStatusChanged: {
                    if (StackView.status === StackView.Activating) {
                        mainPasswordBox.clear();
                        mainPasswordBox.focus = true;
                        root.notification = "";
                    }
                }

                notificationMessage: root.notification

                onPasswordResult: password => authenticator.respond(password)
            }
        }

        // ── Virtual keyboard ───────────────────────────────────────────────
        VirtualKeyboardLoader {
            id: inputPanel
            z: 9
            screenRoot: lockScreenRoot
            mainStack:  mainStack
            mainBlock:  mainBlock
            passwordField: mainBlock.mainPasswordBox
        }

        // ── OSD ────────────────────────────────────────────────────────────
        Loader {
            z: 11
            active: root.viewVisible
            source: "LockOsd.qml"
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: Kirigami.Units.gridUnit
            }
        }
    }
}
