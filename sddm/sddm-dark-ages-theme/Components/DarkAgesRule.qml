// Hairline rule that fades out towards both ends (the separators of the Dark Ages menus).
// Part of sddm-dark-ages-theme, a restyle of sddm-astronaut-theme by Keyitdev https://github.com/Keyitdev/sddm-astronaut-theme
// Copyright (C) 2022-2025 Keyitdev
// Distributed under the GPLv3+ License https://www.gnu.org/licenses/gpl-3.0.html

import QtQuick 2.15

Item {
    id: rule

    property color color: "white"
    // 0..0.5: how much of each end fades out (fadeLeft / fadeRight override one side)
    property real fade: 0.25
    property real fadeLeft: fade
    property real fadeRight: fade

    height: 1

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0;                  color: "transparent" }
            GradientStop { position: rule.fadeLeft;        color: rule.color }
            GradientStop { position: 1.0 - rule.fadeRight; color: rule.color }
            GradientStop { position: 1.0;                  color: "transparent" }
        }
    }
}
