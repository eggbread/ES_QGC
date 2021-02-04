/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts  1.2

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0
import QGroundControl.Vehicle       1.0
import QGroundControl.FlightMap     1.0

Item {
    property var    guidedActionsController
    readonly property real  _fontSize: Math.min(parent.width * 0.01, ScreenTools.defaultFontPixelWidth * 2)

    property real   _margin:        ScreenTools.defaultFontPixelWidth / 2
    property real   _widgetHeight:  ScreenTools.defaultFontPixelHeight * 3
    property color  _textColor:     "white"
    property real   _rectOpacity:   0.9

    QGCPalette { id: qgcPal }

    Rectangle {
        id:             titleRect
        height:         title.paintedHeight * 1.5
        width:          title.paintedWidth * 1.5

        anchors.horizontalCenter: parent.horizontalCenter

        color:          qgcPal.window
        opacity:        _rectOpacity
        radius:         _margin

        QGCLabel {
            id: title
            anchors.horizontalCenter: titleRect.horizontalCenter
            anchors.verticalCenter:   titleRect.verticalCenter
            text:           qsTr("Connection Status")
            wrapMode:       Text.WordWrap
            font.pointSize: _fontSize
        }
    }

    Rectangle {
        QGCListView {
            id:                 vehicleStatusListView
            anchors.margins:    _margins
            anchors.top:        titleRect.bottom
            anchors.bottom:     parent.bottom
            orientation:        ListView.Horizontal
            spacing:            ScreenTools.defaultFontPixelHeight / 2
            model:              QGroundControl.multiVehicleManager.vehicles

            delegate: Rectangle {
                height: 200
                width:  100
                color:  "blue"
                radius: _margin
            }
        }
    }

    QGCListView {
        id:                 missionItemEditorListView
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.topMargin:  _margin
        anchors.top:        titleRect.bottom
        anchors.bottom:     parent.bottom
        spacing:            ScreenTools.defaultFontPixelHeight / 2
        orientation:        ListView.Vertical
        model:              QGroundControl.multiVehicleManager.vehicles
        cacheBuffer:        _cacheBuffer < 0 ? 0 : _cacheBuffer
        clip:               true

        property real _cacheBuffer:     height * 2


        delegate: Rectangle {
            width:      parent.width / 3;
            height:     innerColumn.y + innerColumn.height + _margin
            color:      qgcPal.window
            opacity:    _rectOpacity
            radius:     _margin

            property var    _vehicle:   object
            property string _status: "Connect"
            property string _signalQuality: ""
            property int _rtlTime: 60
            property int _remainTime: _rtlTime

            Image {
                id:                 homeIcon
                anchors.left:       parent.left
                anchors.bottom:     parent.bottom
                height:             ScreenTools.defaultFontPixelWidth * 3
                width:              ScreenTools.defaultFontPixelWidth * 3
                sourceSize.width:   parent.width
                fillMode:           Image.PreserveAspectFit
                source:             "/qmlimages/MapHome.svg"
            }

            Image {
                id:                 gcsIcon
                anchors.left:       parent.left
                anchors.bottom:     homeIcon.top
                height:             ScreenTools.defaultFontPixelWidth * 3
                width:              ScreenTools.defaultFontPixelWidth * 3
                sourceSize.width:   parent.width
                fillMode:           Image.PreserveAspectFit
                source:             "/res/QGCLogoArrow"
            }

            Image {
                id:                 icon
                anchors.right:      parent.right
                anchors.bottom:     parent.bottom
                height:             ScreenTools.defaultFontPixelWidth * 6
                width:              ScreenTools.defaultFontPixelWidth * 6
                sourceSize.width:   parent.width
                fillMode:           Image.PreserveAspectFit
                source:            getIcon(_vehicle.messagesIn2sec)
            }

            Timer {
                id:             iconTimer
                interval:       1000
                repeat:         true
                running:        true
                onTriggered:    getIcon()
            }

            Timer {
                id:             connectionTimer
                interval:       1000
                repeat:         true
                running:        true
                onTriggered:    countingRemainTime()
            }
            function getIcon(messagesIn2sec){

                if( messagesIn2sec >= 52){
                    return "/qmlimages/resources/signal_quality_excellent.png"
                }
                else if(messagesIn2sec < 52 && messagesIn2sec >= 49){
                    return "/qmlimages/resources/signal_quality_good.png"
                }
                else if(messagesIn2sec !== 0){
                    return "/qmlimages/resources/signal_quality_bad.png"
                }
                else {
                    return "/qmlimages/resources/signal_quality_zero.png"
                }
            }

            function countingRemainTime() {
                if(_vehicle && _vehicle.connectionLost){
                    if (_remainTime == 30) {
                        mainWindow.showMessage(qsTr("WARNING: 30s till Failsafe Mode for Drone %1").arg(_vehicle.id))
                    }else if (_remainTime == 15) {
                        mainWindow.showMessage(qsTr("WARNING: 15s till Failsafe Mode for Drone %1").arg(_vehicle.id))
                    }else if (_remainTime <= 10 && _remainTime > 0) {
                        _status = qsTr("Drone %1 : %2s").arg(_vehicle.id).arg(_remainTime)
                    }else if (_remainTime <= 0) {
                        if (_remainTime == 0) mainWindow.showMessage(qsTr("WARNING: Drone %1 returning to launch position.").arg(_vehicle.id))
                        _status = qsTr("Drone %1 RTL").arg(_vehicle.id)
                    }else {
                        _status = qsTr("Drone %1 disconnected").arg(_vehicle.id)
                    }
                    _remainTime--
                }
                else{
                    _status = qsTr("Drone %1 connected").arg(_vehicle.id)
                    _remainTime = _rtlTime
                }
            }

            function getColor(messagesIn2sec){
                if( messagesIn2sec >= 237){
                    return "white"
                }
                else if(messagesIn2sec <237 && messagesIn2sec >= 236){
                    return "white"
                }
                else if(messagesIn2sec !== 0){
                    return "white"
                }else {
                    return "white"
                }
            }

            function toGCS(distance) {
                if(isNaN(distance)){
                    return qsTr("        -.-m")
                }

                return qsTr("        %1m").arg(distance)
            }

            function toHome(distance) {
                if(isNaN(distance)){
                    return qsTr("        -.-m")
                }

                return qsTr("        %1m").arg(distance)
            }

            ColumnLayout {
                id:                 innerColumn
                anchors.margins:    _margin
                anchors.top:        parent.top
                anchors.left:       parent.left
                anchors.right:      parent.right
                spacing:            _margin

                RowLayout {
                    id:                     statusRow
                    Layout.fillWidth:       true

                    ColumnLayout {
                        Layout.alignment:   Qt.AlignCenter
                        spacing:            _margin

                        QGCLabel {
                            Layout.alignment:           Qt.AlignHCenter
                            text:                       qsTr("%1").arg(_status)
                            color:                      _textColor
                            font.pointSize:             _fontSize
                        }
                    }
                }

                RowLayout {
                    id:                     gcsRow
                    Layout.fillWidth:       true
                    anchors.left:           gcsIcon.right

                    ColumnLayout {
                        Layout.alignment:   Qt.AlignCenter
                        spacing:            _margin

                        QGCLabel {
                            Layout.alignment:           Qt.AlignHCenter
                            text:                       toGCS(_vehicle.distanceToGCS.value)
                            color:                      _textColor
                            font.pointSize:             _fontSize
                        }
                    }
                }
                RowLayout {
                    id:                     homeRow
                    Layout.fillWidth:       true
                    anchors.left:           homeIcon.right
                    ColumnLayout {
                        Layout.alignment:   Qt.AlignCenter
                        spacing:            _margin

                        QGCLabel {
                            Layout.alignment:           Qt.AlignHCenter
                            text:                       toHome(_vehicle.distanceToHome.value)
                            color:                      _textColor
                            font.pointSize:             _fontSize
                        }
                    }
                }
            }
        } // delegate - Rectangle
    } // QGCListView
} // Item
