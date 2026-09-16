// Four-pointed star ornament (the marker on the Dark Ages menu headers and sliders).
// Part of sddm-dark-ages-theme, a restyle of sddm-astronaut-theme by Keyitdev https://github.com/Keyitdev/sddm-astronaut-theme
// Copyright (C) 2022-2025 Keyitdev
// Distributed under the GPLv3+ License https://www.gnu.org/licenses/gpl-3.0.html

import QtQuick 2.15
import QtQuick.Shapes 1.15

Item {
    id: star
    property color color: "white"
    // how pinched the star is: 0 gives a diamond, 0.5 a thin cross
    property real pinch: 0.32

    width: 16
    height: 16

    // PathLine children cannot see ShapePath properties, so the geometry lives on the item
    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real px: width * pinch / 2
    readonly property real py: height * pinch / 2

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: star.color
            strokeColor: "transparent"
            startX: star.cx; startY: 0
            PathLine { x: star.cx + star.px; y: star.cy - star.py }
            PathLine { x: star.width;        y: star.cy }
            PathLine { x: star.cx + star.px; y: star.cy + star.py }
            PathLine { x: star.cx;           y: star.height }
            PathLine { x: star.cx - star.px; y: star.cy + star.py }
            PathLine { x: 0;                 y: star.cy }
            PathLine { x: star.cx - star.px; y: star.cy - star.py }
            PathLine { x: star.cx;           y: 0 }
        }
    }
}
