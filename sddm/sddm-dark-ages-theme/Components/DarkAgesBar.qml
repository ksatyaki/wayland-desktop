// DOOM: The Dark Ages style menu row. At rest it is only a hairline rule under the text (the plain rows
// of the Dark Ages menus); when "lit" a bar with spear-tip ends fades in over it (the focused row).
// Part of sddm-dark-ages-theme, a restyle of sddm-astronaut-theme by Keyitdev https://github.com/Keyitdev/sddm-astronaut-theme
// Copyright (C) 2022-2025 Keyitdev
// Distributed under the GPLv3+ License https://www.gnu.org/licenses/gpl-3.0.html

import QtQuick 2.15
import QtQuick.Shapes 1.15

Item {
    id: bar

    property color fillColor: "transparent"
    property real fillOpacity: 1.0
    property color borderColor: "transparent"
    property real borderWidth: 1.5
    // 0..1: how visible the pointed bar is (the hairline rule is always drawn when rule is true)
    property real barOpacity: 0
    // length of the pointed ends measured along the bar; height / 2 gives a 90 degree spear tip
    property real tip: height * 0.6
    // hairline under the row, fading out towards both ends
    property bool rule: true
    property color ruleColor: borderColor
    property real ruleInset: tip

    // keep strokes crisp: inset the path by half the stroke width
    readonly property real i: borderWidth / 2
    readonly property real w: width - borderWidth
    readonly property real h: height - borderWidth
    // inset of the soft inner outline (PathLine children cannot see ShapePath properties, so it lives here)
    readonly property real d: 4

    Behavior on fillColor { ColorAnimation { duration: 150 } }
    Behavior on borderColor { ColorAnimation { duration: 150 } }
    Behavior on fillOpacity { NumberAnimation { duration: 150 } }
    Behavior on barOpacity { NumberAnimation { duration: 180 } }

    DarkAgesRule {
        visible: bar.rule
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: bar.ruleInset
        anchors.rightMargin: bar.ruleInset
        color: bar.ruleColor
        opacity: 1 - bar.barOpacity * 0.6
    }

    Shape {
        anchors.fill: parent
        opacity: bar.barOpacity
        visible: opacity > 0
        preferredRendererType: Shape.CurveRenderer

        // the bar itself: a glow that is stronger towards the tips, like the lit rows in the game
        ShapePath {
            strokeColor: bar.borderColor
            strokeWidth: bar.borderWidth
            joinStyle: ShapePath.MiterJoin
            fillGradient: LinearGradient {
                x1: 0; y1: 0; x2: bar.width; y2: 0
                GradientStop { position: 0.0;  color: Qt.rgba(bar.borderColor.r, bar.borderColor.g, bar.borderColor.b, 0.55 * bar.fillOpacity) }
                GradientStop { position: 0.12; color: Qt.rgba(bar.fillColor.r, bar.fillColor.g, bar.fillColor.b, bar.fillColor.a * bar.fillOpacity) }
                GradientStop { position: 0.88; color: Qt.rgba(bar.fillColor.r, bar.fillColor.g, bar.fillColor.b, bar.fillColor.a * bar.fillOpacity) }
                GradientStop { position: 1.0;  color: Qt.rgba(bar.borderColor.r, bar.borderColor.g, bar.borderColor.b, 0.55 * bar.fillOpacity) }
            }

            startX: bar.i + bar.tip
            startY: bar.i
            PathLine { x: bar.i + bar.w - bar.tip; y: bar.i }
            PathLine { x: bar.i + bar.w;           y: bar.i + bar.h / 2 }
            PathLine { x: bar.i + bar.w - bar.tip; y: bar.i + bar.h }
            PathLine { x: bar.i + bar.tip;         y: bar.i + bar.h }
            PathLine { x: bar.i;                   y: bar.i + bar.h / 2 }
            PathLine { x: bar.i + bar.tip;         y: bar.i }
        }

        // soft inner outline
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(bar.borderColor.r, bar.borderColor.g, bar.borderColor.b, 0.35)
            strokeWidth: 3
            joinStyle: ShapePath.MiterJoin
            startX: bar.i + bar.tip + bar.d * 0.6
            startY: bar.i + bar.d
            PathLine { x: bar.i + bar.w - bar.tip - bar.d * 0.6; y: bar.i + bar.d }
            PathLine { x: bar.i + bar.w - bar.d * 1.4;           y: bar.i + bar.h / 2 }
            PathLine { x: bar.i + bar.w - bar.tip - bar.d * 0.6; y: bar.i + bar.h - bar.d }
            PathLine { x: bar.i + bar.tip + bar.d * 0.6;         y: bar.i + bar.h - bar.d }
            PathLine { x: bar.i + bar.d * 1.4;                   y: bar.i + bar.h / 2 }
            PathLine { x: bar.i + bar.tip + bar.d * 0.6;         y: bar.i + bar.d }
        }
    }
}
