/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.3
import QtQuick.Controls 2.5
import QtQuick.Layouts  1.2
import QtQuick.Controls.Material 2.0

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
    property real   _rectOpacity:   0.8

    QGCPalette { id: qgcPal }

    Rectangle {
        id:             mvCommands
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         mvCommandsColumn.height + (_margin *2)
        color:          qgcPal.window
        opacity:        _rectOpacity
        radius:         _margin

        DeadMouseArea {
            anchors.fill: parent
        }

        Column {
            id:                 mvCommandsColumn
            anchors.margins:    _margin
            anchors.top:        parent.top
            anchors.left:       parent.left
            anchors.right:      parent.right
            spacing:            _margin

            QGCLabel {
                anchors.left:   parent.left
                anchors.right:  parent.right
                text:           qsTr("The following commands will be applied to all vehicles")
                color:          _textColor
                wrapMode:       Text.WordWrap
                font.pointSize: ScreenTools.smallFontPointSize
            }

            Row {
                spacing:            _margin

                QGCButton {
                    text:       "Pause"
                    onClicked:  guidedActionsController.confirmAction(guidedActionsController.actionMVPause)
                }

                QGCButton {
                    text:       "Start Mision"
                    onClicked:  guidedActionsController.confirmAction(guidedActionsController.actionMVStartMission)
                }
            }
        }
    }

    QGCListView {
        id:                 missionItemEditorListView
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.topMargin:  _margin
        anchors.top:        mvCommands.bottom
        anchors.bottom:     parent.bottom
        spacing:            ScreenTools.defaultFontPixelHeight / 2
        orientation:        ListView.Vertical
        model:              QGroundControl.multiVehicleManager.vehicles
        cacheBuffer:        _cacheBuffer < 0 ? 0 : _cacheBuffer
        clip:               true

        property real _cacheBuffer:     height * 2


        delegate: Rectangle {
            width:      parent.width
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
                anchors.margins:    _margin
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
                anchors.margins:    _margin
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
                source:             getIcon(_vehicle.messagesIn2sec)
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
                        _status = qsTr("%1: %2s").arg(_vehicle.id).arg(_remainTime)
                    }else if (_remainTime <= 0) {
                        if (_remainTime == 0) mainWindow.showMessage(qsTr("WARNING: %1 returning to launch position.").arg(_vehicle.id))
                        _status = qsTr("%1 RTL").arg(_vehicle.id)
                    }else {
                        _status = qsTr("%1 ").arg(_vehicle.id)
                    }
                    _remainTime--
                }
                else{
                    _status = qsTr("%1 ").arg(_vehicle.id)
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
//                anchors.right:      parent.right
                spacing:            _margin

                RowLayout {
                    id:                     statusRow
                    Layout.fillWidth:       true

                    ColumnLayout {
                        id: test
                        Layout.alignment:   Qt.AlignCenter
                        Layout.rightMargin: 15
                        spacing:            _margin

                        QGCLabel {
                            Layout.alignment:           Qt.AlignHCenter
                            text:                       qsTr("%1").arg(_status)
                            color:                      _textColor
                            font.pointSize:             _fontSize
                        }
                    }
                    ColumnLayout{
                        id: videoCol
                        Layout.alignment:   Qt.AlignCenter
                        Layout.rightMargin: 6
                        spacing:            _margin

                        Switch {
                            id: switch_video
                            text: qsTr("Video")
                            font.pointSize: 9

                            indicator: Rectangle {
                                implicitWidth: 44
                                implicitHeight: 20
//                                x: switch_video.leftPadding * 2
                                y: parent.height / 2 - height / 2
                                radius: 10
                                color: !switch_video.checked ? "#777777" : "#d9d9d9"
                                border.color: switch_video.checked ? "#777777" : "#777777"

                                Rectangle {
                                    x: switch_video.checked ? parent.width - width : 0
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: switch_video.down ? "#cccccc" : "#ffffff"
                                    border.color: switch_video.checked ? (switch_video.down ? "#cccccc" : "#cccccc") : "#cccccc"
                                }
                            }
                            contentItem: Text {
                                text: switch_video.text
                                font: switch_video.font
                                opacity: enabled ? 1.0 : 0.3
                                color: switch_video.down ? "black" : "black"
                                verticalAlignment: Text.AlignVCenter
                            }
                            checked: _vehicle.streamingOn
                            onToggled: _vehicle.streamingOn = switch_video.checked
                        }
                    }
                    ColumnLayout{
                        id: bioAirCol
                        Layout.alignment:   Qt.AlignCenter
                        Layout.rightMargin: 6
                        spacing:            _margin * 3

                        Switch{
                            id:   switch_bioAir
                            text: qsTr("BioAir")
                            font.pointSize: 9

                            checked: _vehicle.bioairOn
                            onToggled: _vehicle.bioairOn = switch_bioAir.checked
                            indicator: Rectangle {
                                implicitWidth: 44
                                implicitHeight: 20
//                                x: switch_bioAir.leftPadding * 4
                                y: parent.height / 2 - height / 2
                                radius: 10
                                color: !switch_bioAir.checked ? "#777777" : "#d9d9d9"
                                border.color: switch_bioAir.checked ? "#777777" : "#777777"

                                Rectangle {
                                    x: switch_bioAir.checked ? parent.width - width : 0
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: switch_bioAir.down ? "#cccccc" : "#ffffff"
                                    border.color: switch_bioAir.checked ? (switch_bioAir.down ? "#cccccc" : "#cccccc") : "#cccccc"
                                }
                            }
                            contentItem: Text {
                                text: switch_bioAir.text
                                font: switch_bioAir.font
                                opacity: enabled ? 1.0 : 0.3
                                color: switch_bioAir.down ? "black" : "black"
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                    ColumnLayout{
                        id: aiCol
                        Layout.alignment:   Qt.AlignCenter
                        Layout.rightMargin: 6
                        spacing:            _margin * 3

                        Switch{
                            id:   switch_AI
                            text: qsTr("AI")
                            font.pointSize: 9
                            checked: _vehicle.aiOn
                            onToggled: _vehicle.aiOn = switch_AI.checked

                            indicator: Rectangle {
                                implicitWidth: 44
                                implicitHeight: 20
//                                x: switch_AI.leftPadding * 6
                                y: parent.height / 2 - height / 2
                                radius: 10
                                color: !switch_AI.checked ? "#777777" : "#d9d9d9"
                                border.color: switch_AI.checked ? "#777777" : "#777777"

                                Rectangle {
                                    x: switch_AI.checked ? parent.width - width : 0
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: switch_AI.down ? "#cccccc" : "#ffffff"
                                    border.color: switch_AI.checked ? (switch_AI.down ? "#cccccc" : "#cccccc") : "#cccccc"
                                }
                            }
                            contentItem: Text {
                                text: switch_AI.text
                                font: switch_AI.font
                                opacity: enabled ? 1.0 : 0.3
                                color: switch_AI.down ? "black" : "black"
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                RowLayout {
                    id:                     gcsRow
                    Layout.fillWidth:       true

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
