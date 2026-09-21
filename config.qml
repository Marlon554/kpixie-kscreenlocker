import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

Kirigami.FormLayout {
    id: configForm

    property alias cfg_use24HourClock: use24HourClock.checked
    property bool cfg_use24HourClockDefault: true

    property alias cfg_autoAccentColor: autoAccentColor.checked
    property bool cfg_autoAccentColorDefault: true

    twinFormLayouts: parentLayout

    QQC2.CheckBox {
        id: use24HourClock
        Kirigami.FormData.label: i18ndc("plasma_shell_org.kde.plasma.desktop",
                                        "@title: group",
                                        "Clock format:")
        text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@option:check", "Use 24-hour format")

        KCM.SettingHighlighter {
            highlight: configForm.cfg_use24HourClockDefault != configForm.cfg_use24HourClock
        }
    }

    QQC2.CheckBox {
        id: autoAccentColor
        Kirigami.FormData.label: i18ndc("plasma_shell_org.kde.plasma.desktop",
                                        "@title: group",
                                        "Accent color:")
        text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@option:check", "Pick automatically from wallpaper")

        KCM.SettingHighlighter {
            highlight: configForm.cfg_autoAccentColorDefault != configForm.cfg_autoAccentColor
        }
    }
}
