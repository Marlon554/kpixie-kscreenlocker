/*
 * Pixie Lockscreen — MainBlock
 * Visual design: Pixie SDDM by xCaptaiN09 (MIT)
 * Base: Plasma kscreenlocker (GPL-2.0-or-later)
 *
 * Standalone login card (not a SessionManagementScreen subclass) that still
 * exposes the API LockScreenUi and VirtualKeyboardLoader expect.
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kscreenlocker as ScreenLocker

import org.kde.breeze.components

Item {
    id: mainBlock

    // ── API required by LockScreenUi / VirtualKeyboardLoader ──────────────
    readonly property alias mainPasswordBox: passwordField

    property bool   lockScreenUiVisible: false
    property string notificationMessage: ""
    property var    userListModel:        null
    property bool   showUserList:         false
    property bool   numLockOn:             false
    property bool   isLoggingIn:          false
    property list<Item> actionItems

    property int visibleBoundary: height * 0.7
    readonly property Item userList: _dummyUserList
    Item { id: _dummyUserList; y: mainBlock.height * 0.3; height: 0 }

    signal passwordResult(string password)

    function playHighlightAnimation() { _highlightAnim.start(); }
    function startLogin() {
        if (isLoggingIn || passwordField.text.length === 0) return;
        isLoggingIn = true;
        passwordResult(passwordField.text);
    }

    Connections {
        target: authenticator
        function onFailed(kind)  { if (kind === 0) mainBlock.isLoggingIn = false; }
        function onSucceeded()   { mainBlock.isLoggingIn = false; }
    }
    Connections {
        target: root
        function onClearPassword() { mainBlock.isLoggingIn = false; }
    }

    // Visual dependencies are supplied explicitly by LockScreenUi.
    property color  accent:              "#A9C78F"
    property string pixieFont:           ""
    property string pixieFontBold:       ""
    property color  baseColor:            "#1A1C18"
    property color  surfaceColor:         "#22241F"
    property color  surfaceVariantColor:  "#2A2D26"
    property color  textColor:            "#E3E3DC"
    property var    sessionManagement:    null

    property string userName: (userListModel && userListModel.count > 0)
                              ? (userListModel.get(0).realName || userListModel.get(0).name) : ""
    property string userIcon: (userListModel && userListModel.count > 0)
                              ? userListModel.get(0).icon : ""

    SequentialAnimation {
        id: _highlightAnim
        PropertyAnimation { target: cardVisual; property: "opacity"; to: 0.4; duration: 80 }
        PropertyAnimation { target: cardVisual; property: "opacity"; to: 0.7; duration: 80 }
    }

    // Login card. Explicit x/y (not anchors.centerIn) so it can grow/bounce
    // when the Num Lock hint appears.
    Rectangle {
        id: cardVisual
        width: 380
        height: 430 + (numLockLabel.visible ? 40 : 0)
        x: (parent.width - width) / 2
        y: (parent.height - 430) / 2

        property bool isError: false
        color:   isError ? "#442222" : mainBlock.baseColor
        radius:  32
        opacity: mainBlock.lockScreenUiVisible ? 0.7 : 0.0
        Behavior on opacity { NumberAnimation { duration: 400 } }
        Behavior on color   { ColorAnimation  { duration: 200 } }
        Behavior on height  { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
        Behavior on y       { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

        SequentialAnimation {
            id: shakeAnimation; loops: 2
            PropertyAnimation {
                target: cardVisual; property: "x"
                from: (mainBlock.width - cardVisual.width) / 2
                to:   (mainBlock.width - cardVisual.width) / 2 - 10
                duration: 50; easing.type: Easing.InOutQuad
            }
            PropertyAnimation {
                target: cardVisual; property: "x"
                from: (mainBlock.width - cardVisual.width) / 2 - 10
                to:   (mainBlock.width - cardVisual.width) / 2 + 10
                duration: 50; easing.type: Easing.InOutQuad
            }
            PropertyAnimation {
                target: cardVisual; property: "x"
                from: (mainBlock.width - cardVisual.width) / 2 + 10
                to:   (mainBlock.width - cardVisual.width) / 2
                duration: 50; easing.type: Easing.InOutQuad
            }
            onStopped: cardVisual.isError = false
        }

        Connections {
            target: authenticator
            function onFailed(kind) {
                if (kind !== 0) return;
                cardVisual.isError = true;
                shakeAnimation.start();
            }
        }

        ColumnLayout {
            anchors { fill: parent; margins: 40 }
            spacing: 15

            // ── Avatar ─────────────────────────────────────────────────────
            Item {
                Layout.preferredWidth: 120; Layout.preferredHeight: 120
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    anchors.fill: parent; color: mainBlock.surfaceColor; radius: width / 2
                    visible: avatarImage.status !== Image.Ready
                    Text {
                        anchors.centerIn: parent
                        text: mainBlock.userName.charAt(0).toUpperCase() || "?"
                        color: mainBlock.accent
                        font.pixelSize: 48; font.family: mainBlock.pixieFontBold; font.weight: Font.Bold
                    }
                }

                Canvas {
                    id: avatarCanvas
                    anchors.fill: parent
                    visible: avatarImage.status === Image.Ready
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.beginPath();
                        ctx.arc(width / 2, height / 2, width / 2, 0, 2 * Math.PI);
                        ctx.closePath(); ctx.clip();
                        ctx.drawImage(avatarImage, 0, 0, width, height);
                    }
                    Timer { id: repaintTimer; interval: 500; onTriggered: avatarCanvas.requestPaint() }
                    Image {
                        id: avatarImage
                        anchors.fill: parent; fillMode: Image.PreserveAspectCrop
                        smooth: true; visible: false; source: mainBlock.userIcon
                        onStatusChanged: { if (status === Image.Ready) repaintTimer.start(); }
                    }
                }
            }

            // ── Username / Switch User ───────────────────────────────────────
            // The username itself is the click target; a small chevron hints
            // it's clickable instead of a separate "Switch User" button.
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: userNameRow.implicitWidth + 40
                Layout.preferredHeight: userNameRow.implicitHeight + 20
                Layout.topMargin: 10
                visible: mainBlock.userName !== ""

                Rectangle {
                    anchors.fill: parent
                    color: "white"
                    opacity: userClickArea.pressed ? 0.2 : 0
                    radius: 12
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                }

                Row {
                    id: userNameRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        id: userNameLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: mainBlock.userName
                              || i18ndc("plasma_shell_org.kde.plasma.desktop", "@label", "User")
                        color: "white"
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        font.family: mainBlock.pixieFont
                    }

                    // Switch-user chevron.
                    Text {
                        id: switchIndicator
                        anchors.verticalCenter: parent.verticalCenter
                        text: "▾"
                        visible: mainBlock.sessionManagement !== null
                                 && mainBlock.sessionManagement.canSwitchUser
                        color: "white"
                        font.pixelSize: 12
                    }
                }

                MouseArea {
                    id: userClickArea
                    anchors.fill: parent
                    enabled: mainBlock.sessionManagement !== null
                             && mainBlock.sessionManagement.canSwitchUser
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: mainBlock.sessionManagement.switchUser()
                }

                scale: userClickArea.pressed ? 0.95 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }
            }

            // ── Password field ────────────────────────────────────────────
            TextField {
                id: passwordField
                Layout.topMargin: 14
                echoMode: TextInput.Password
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 18
                color: "white"
                focus: true
                enabled: !authenticator.graceLocked && !mainBlock.isLoggingIn
                placeholderText: ""

                background: Rectangle {
                    color: mainBlock.surfaceColor
                    radius: 16
                    border.width: passwordField.activeFocus ? 2 : 0
                    border.color: mainBlock.accent
                    opacity: passwordField.enabled ? 1.0 : 0.5
                }

                Text {
                    text: i18ndc("plasma_shell_org.kde.plasma.desktop",
                                 "@info:placeholder in text field", "Enter Password")
                    color: "gray"
                    font.pixelSize: 16
                    visible: !parent.text
                    anchors.centerIn: parent
                    opacity: 0.5
                }

                onAccepted: {
                    if (mainBlock.lockScreenUiVisible) mainBlock.startLogin();
                }

                Keys.onTabPressed:      loginButton.forceActiveFocus()
                Keys.onBacktabPressed:  loginButton.forceActiveFocus()

                Connections {
                    target: root
                    function onClearPassword() {
                        passwordField.clear();
                        passwordField.forceActiveFocus();
                    }
                    function onNotificationRepeated() { mainBlock.playHighlightAnimation(); }
                }
            }

            // ── Num Lock indicator ────────────────────────────────────────
            Text {
                id: numLockLabel
                Layout.alignment: Qt.AlignHCenter
                text: i18ndc("plasma_shell_org.kde.plasma.desktop",
                             "@info:status", "Num Lock is on")
                color: mainBlock.accent
                font.pixelSize: 14
                font.family: mainBlock.pixieFont
                font.weight: Font.Medium
                visible: mainBlock.numLockOn
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // ── Notification — wrong password / errors ─────────────────────
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: mainBlock.notificationMessage
                color: mainBlock.accent
                font.pixelSize: 14; font.family: mainBlock.pixieFont; font.weight: Font.Medium
                wrapMode: Text.WordWrap
                visible: text !== ""
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // ── Fingerprint / smartcard hints ──────────────────────────────
            component FailableLabel : Text {
                id: _flab
                required property int    kind
                required property string label
                visible: authenticator.authenticatorTypes & kind
                text: label; horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true; font.pixelSize: 13
                opacity: 0.6; color: mainBlock.textColor; wrapMode: Text.WordWrap
                RejectPasswordAnimation { id: _rej; target: _flab; onFinished: _t.restart() }
                Connections {
                    target: authenticator
                    function onNoninteractiveError(kind, auth) {
                        if (kind & _flab.kind) { _flab.text = Qt.binding(() => auth.errorMessage); _rej.start(); }
                    }
                }
                Timer { id: _t; interval: Kirigami.Units.humanMoment; onTriggered: _flab.text = Qt.binding(() => _flab.label) }
            }
            FailableLabel {
                kind:  ScreenLocker.Authenticator.Fingerprint
                label: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:usagetip", "(or scan your fingerprint on the reader)")
            }
            FailableLabel {
                kind:  ScreenLocker.Authenticator.Smartcard
                label: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:usagetip", "(or scan your smartcard)")
            }

            // ── Unlock button ────────────────────────────────────────────
            // No keyboard focus, no Behavior on color/opacity (matches Pixie).
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 64
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    id: loginButton
                    width: 64; height: 64; radius: 32
                    anchors.centerIn: parent

                    color: mainBlock.isLoggingIn
                           ? mainBlock.surfaceVariantColor
                           : (loginArea.containsPress
                              ? Qt.darker(mainBlock.accent, 1.1)
                              : mainBlock.accent)
                    opacity: mainBlock.isLoggingIn ? 0.5 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: mainBlock.isLoggingIn ? "⋯" : "→"
                        color: "white"
                        font.pixelSize: 32
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment:   Text.AlignVCenter
                    }

                    MouseArea {
                        id: loginArea
                        anchors.fill: parent
                        enabled: !mainBlock.isLoggingIn
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mainBlock.startLogin()
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
