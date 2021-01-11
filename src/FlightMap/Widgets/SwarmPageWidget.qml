/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.11
import QtPositioning            5.2
import QtQuick.Layouts          1.2
import QtQuick.Controls         2.4
import QtQuick.Dialogs          1.2
import QtGraphicalEffects       1.0

import QGroundControl                   1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.Palette           1.0
import QGroundControl.Vehicle           1.0
import QGroundControl.Controllers       1.0
import QGroundControl.FactSystem        1.0
import QGroundControl.FactControls      1.0

/// Video streaming page for Instrument Panel PageView
Item {
    width:              pageWidth
    height:             videoGrid.y + videoGrid.height + _margins
    anchors.margins:    ScreenTools.defaultFontPixelWidth * 2
    anchors.centerIn:   parent

    property var    _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property bool   _rgbChecked:     false
    property bool   _depthChecked:   false
//    property bool   _bioairChecked:     false
//    property bool   _aiChecked:   false

    Connections {
        target: mainWindow
        onActiveVehicleChanged: {
            rgbBtn.checked = activeVehicle.streamingOn === 0 || activeVehicle.streamingOn === 1
            depthBtn.checked = activeVehicle.streamingOn === 0 || activeVehicle.streamingOn === 2
            bioairBtn.checked = activeVehicle.bioairOn
            aiBtn.checked = activeVehicle.aiOn
            sensorRangeBtn.checked = activeVehicle.showTrajectory
        }
    }

    QGCPalette { id:qgcPal; colorGroupEnabled: true }

    GridLayout {
        id:                 videoGrid
        anchors.margins:    _margins
        anchors.top:        parent.top
        anchors.left:       parent.left
        anchors.right:      parent.right
        columns:            2
        columnSpacing:      _margins
        rowSpacing:         ScreenTools.defaultFontPixelHeight

        QGCLabel {
           text:                qsTr("RGB")
           font.pointSize:      ScreenTools.smallFontPointSize
           visible:             true
        }
        QGCSwitch {
            id:                 rgbBtn
            enabled:            activeVehicle
            checked:            activeVehicle.streaminOn === 0 || activeVehicle.streaminOn === 1
            visible:            activeVehicle
            Layout.alignment:   Qt.AlignHCenter
            onClicked: {
                console.log(rgbBtn.checked)
                if(rgbBtn.checked) {
                    if(activeVehicle.streamingOn === 2){
                        activeVehicle.setStreamingOn(0)
                    } else if (activeVehicle.streamingOn === -1) {
                        activeVehicle.setStreamingOn(1)
                    }

                } else {
                    if(activeVehicle.streamingOn === 0){
                        activeVehicle.setStreamingOn(2)
                    } else if (activeVehicle.streamingOn === 1) {
                        activeVehicle.setStreamingOn(-1)
                    }
                }
            }
        }
        QGCLabel {
           text:                qsTr("Depth")
           font.pointSize:      ScreenTools.smallFontPointSize
           visible:             true
        }
        QGCSwitch {
            id:                 depthBtn
            enabled:            activeVehicle
            checked:            activeVehicle.streaminOn === 0 || activeVehicle.streaminOn === 2
            visible:            activeVehicle
            Layout.alignment:   Qt.AlignHCenter
            onClicked: {
                if(depthBtn.checked) {
                    if(activeVehicle.streamingOn === 1){
                        activeVehicle.setStreamingOn(0)
                    } else if (activeVehicle.streamingOn === -1) {
                        activeVehicle.setStreamingOn(2)
                    }
                } else {
                    if(activeVehicle.streamingOn === 0){
                        activeVehicle.setStreamingOn(1)
                    } else if (activeVehicle.streamingOn === 2) {
                        activeVehicle.setStreamingOn(-1)
                    }
                }
            }
        }
        QGCLabel {
           text:                qsTr("BioAir")
           font.pointSize:      ScreenTools.smallFontPointSize
           visible:             QGroundControl.videoManager.isGStreamer && QGroundControl.settingsManager.videoSettings.gridLines.visible
        }
        QGCSwitch {
            id:                 bioairBtn
            enabled:            activeVehicle
            checked:            activeVehicle.bioairOn
            visible:            activeVehicle
            Layout.alignment:   Qt.AlignHCenter
            onClicked: {
                console.log(checked)
                console.log(activeVehicle.bioairOn)
                if(checked) {
                    activeVehicle.setBioairOn(true)
                } else {
                    activeVehicle.setBioairOn(false)
                }
                console.log(activeVehicle.bioairOn)
            }
        }
        // Grid Lines
        QGCLabel {
           text:                qsTr("Vision AI")
           font.pointSize:      ScreenTools.smallFontPointSize
           visible:             QGroundControl.videoManager.isGStreamer && QGroundControl.settingsManager.videoSettings.gridLines.visible
        }
        QGCSwitch {
            id:                 aiBtn
            enabled:            activeVehicle
            checked:            activeVehicle.aiOn
            visible:            activeVehicle
            Layout.alignment:   Qt.AlignHCenter
            onClicked: {
                if(checked) {
                    activeVehicle.setAiOn(true)
                } else {
                    activeVehicle.setAiOn(false)
                }
            }
        }




//        QGCLabel {
//           text:                qsTr("Tracking")
//           font.pointSize:      ScreenTools.smallFontPointSize
//           visible:             QGroundControl.videoManager.isGStreamer && QGroundControl.settingsManager.videoSettings.gridLines.visible
//        }
//        QGCSwitch {
//            enabled:            activeVehicle
//            checked:            QGroundControl.settingsManager.videoSettings.gridLines.rawValue
//            visible:            QGroundControl.videoManager.isGStreamer && QGroundControl.settingsManager.videoSettings.gridLines.visible
//            Layout.alignment:   Qt.AlignHCenter
//            onClicked: {
//                if(checked) {
//                    QGroundControl.settingsManager.videoSettings.gridLines.rawValue = 1
//                } else {
//                    QGroundControl.settingsManager.videoSettings.gridLines.rawValue = 0
//                }
//            }
//        }
        //-- Video Fit
//        QGCLabel {
//            text:               qsTr("Video Fit")
//            visible:            QGroundControl.videoManager.isGStreamer
//            font.pointSize:     ScreenTools.smallFontPointSize
//        }
//        FactComboBox {
//            fact:               QGroundControl.settingsManager.videoSettings.videoFit
//            visible:            QGroundControl.videoManager.isGStreamer
//            indexModel:         false
//            Layout.alignment:   Qt.AlignHCenter
//        }
        QGCLabel {
            text:               qsTr("Sensor Range");
            font.pointSize:     ScreenTools.smallFontPointSize
            visible:            QGroundControl.videoManager.isGStreamer
        }
        QGCSwitch {
            id:                 sensorRangeBtn
            enabled:            activeVehicle
            checked:            activeVehicle.bioairOn
            visible:            activeVehicle
            Layout.alignment:   Qt.AlignHCenter
            onClicked: {
                console.log(checked)
                console.log(activeVehicle.showTrajectory)
                if(checked) {
                    activeVehicle.setShowTrajectory(true)
                } else {
                    activeVehicle.setShowTrajectory(false)
                }
            }
        }
        QGCSlider {
            id:                     wizardPresetsAngleSlider
            visible:                sensorRangeBtn.checked
            minimumValue:           10
            maximumValue:           100
            stepSize:               10
            tickmarksEnabled:       false
            Layout.fillWidth:       true
            Layout.columnSpan:      2
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
            onValueChanged:         _activeVehicle.setSensorRange(value)
            updateValueWhileDragging: true
        }
        QGCLabel {
            text:               qsTr("Text Field");
            font.pointSize:     ScreenTools.smallFontPointSize
            visible:            QGroundControl.videoManager.isGStreamer
        }

        QGCTextField {
            id:                 videoFileName
            Layout.fillWidth:   true
            visible:            QGroundControl.videoManager.isGStreamer
        }

//        QGCLabel {
//           text:                qsTr("Distance")
//           font.pointSize:      ScreenTools.smallFontPointSize
//           visible:             QGroundControl.videoManager.isGStreamer && QGroundControl.settingsManager.videoSettings.gridLines.visible
//        }
//        QGCLabel {
//           text:                qsTr("")
//           font.pointSize:      ScreenTools.smallFontPointSize
//           visible:             QGroundControl.videoManager.isGStreamer && QGroundControl.settingsManager.videoSettings.gridLines.visible
//        }

//        Repeater {
//            model: QGroundControl.multiVehicleManager.vehicles
//            Item {
//                QGCLabel {
//                    width:  parent.width
//                    font.pointSize:     ScreenTools.smallFontPointSize
//                    text:   "id"
//                }
//                QGCLabel {
//                    width:  parent.width
//                    font.pointSize:     ScreenTools.smallFontPointSize
//                    text:   "modelData.id"
//                }
//            }

//        }

//        QGCTextField {
//            id:                 videoFileName
//            Layout.fillWidth:   true
//            visible:            QGroundControl.videoManager.isGStreamer
//        }
        //-- Video Recording
//        QGCLabel {
//           text:            qsTr("Signal Quality")
//           font.pointSize:  ScreenTools.smallFontPointSize
//           visible:         QGroundControl.videoManager.isGStreamer
//        }
//        // Button to start/stop video recording
//        Image {
//            id: signalQuality
//            source: "/qmlimages/resources/signal_quality_excellent.png"
//        }
//        Item {
//            anchors.margins:    ScreenTools.defaultFontPixelHeight / 2
//            height:             ScreenTools.defaultFontPixelHeight * 2
//            width:              height
//            Layout.alignment:   Qt.AlignHCenter
//            visible:            QGroundControl.videoManager.isGStreamer
//            Rectangle {
//                id:                 recordBtnBackground
//                anchors.top:        parent.top
//                anchors.bottom:     parent.bottom
//                width:              height
//                radius:             _recordingVideo ? 0 : height
//                color:              (_videoRunning && _streamingEnabled) ? "red" : "gray"
//                SequentialAnimation on opacity {
//                    running:        _recordingVideo
//                    loops:          Animation.Infinite
//                    PropertyAnimation { to: 0.5; duration: 500 }
//                    PropertyAnimation { to: 1.0; duration: 500 }
//                }
//            }
//            QGCColoredImage {
//                anchors.top:                parent.top
//                anchors.bottom:             parent.bottom
//                anchors.horizontalCenter:   parent.horizontalCenter
//                width:                      height * 0.625
//                sourceSize.width:           width
//                source:                     "/qmlimages/CameraIcon.svg"
//                visible:                    recordBtnBackground.visible
//                fillMode:                   Image.PreserveAspectFit
//                color:                      "white"
//            }
//            MouseArea {
//                anchors.fill:   parent
//                enabled:        _videoRunning && _streamingEnabled
//                onClicked: {
//                    if (_recordingVideo) {
//                        _videoReceiver.stopRecording()
//                        // reset blinking animation
//                        recordBtnBackground.opacity = 1
//                    } else {
//                        _videoReceiver.startRecording(videoFileName.text)
//                    }
//                }
//            }
//        }
//        QGCLabel {
//            text:               qsTr("Video Streaming Not Configured")
//            font.pointSize:     ScreenTools.smallFontPointSize
//            visible:            !_streamingEnabled
//            Layout.columnSpan:  2
//        }
    }
}
