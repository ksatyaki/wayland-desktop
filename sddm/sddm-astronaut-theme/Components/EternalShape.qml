// DOOM Eternal style panel: a rectangle with per-corner chamfers drawn as a filled, outlined polygon.
// Each corner takes an (x, y) cut; x is measured along the horizontal edge, y along the vertical edge.
// A cut with y == height turns the whole side into one slanted edge, like the Eternal main-menu items.
// Distributed under the GPLv3+ License https://www.gnu.org/licenses/gpl-3.0.html

import QtQuick 2.15
import QtQuick.Shapes 1.15

Item {
    id: es

    property color fillColor: "transparent"
    property real fillOpacity: 1.0
    property color borderColor: "transparent"
    property real borderWidth: 1
    property real tlX: 0
    property real tlY: 0
    property real trX: 0
    property real trY: 0
    property real brX: 0
    property real brY: 0
    property real blX: 0
    property real blY: 0
    // Thin accent line along the bottom edge, inset from the corners (the Eternal menu underline).
    property bool bottomLine: false
    property color lineColor: borderColor

    // keep 1px strokes crisp: inset the path by half the stroke width
    readonly property real i: borderWidth / 2
    readonly property real w: width - borderWidth
    readonly property real h: height - borderWidth

    Behavior on fillColor { ColorAnimation { duration: 150 } }
    Behavior on borderColor { ColorAnimation { duration: 150 } }
    Behavior on fillOpacity { NumberAnimation { duration: 150 } }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Qt.rgba(es.fillColor.r, es.fillColor.g, es.fillColor.b, es.fillColor.a * es.fillOpacity)
            strokeColor: es.borderColor
            strokeWidth: es.borderWidth
            joinStyle: ShapePath.MiterJoin

            startX: es.i + es.tlX
            startY: es.i
            PathLine { x: es.i + es.w - es.trX; y: es.i }
            PathLine { x: es.i + es.w;          y: es.i + es.trY }
            PathLine { x: es.i + es.w;          y: es.i + es.h - es.brY }
            PathLine { x: es.i + es.w - es.brX; y: es.i + es.h }
            PathLine { x: es.i + es.blX;        y: es.i + es.h }
            PathLine { x: es.i;                 y: es.i + es.h - es.blY }
            PathLine { x: es.i;                 y: es.i + es.tlY }
            PathLine { x: es.i + es.tlX;        y: es.i }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: es.bottomLine ? es.lineColor : "transparent"
            strokeWidth: es.borderWidth
            startX: es.i + Math.max(es.blX, 6) + 4
            startY: es.i + es.h - 3 * es.borderWidth
            PathLine { x: es.i + es.w - Math.max(es.brX, 6) - 4; y: es.i + es.h - 3 * es.borderWidth }
        }
    }
}
