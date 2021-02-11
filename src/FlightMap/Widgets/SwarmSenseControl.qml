/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.4
import QtPositioning            5.2
import QtQuick.Layouts          1.2
import QtQuick.Controls         1.4
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

Rectangle {
    height:     mainLayout.height + (_margins * 2)
    color:      "#80000000"
    radius:     _margins
    visible:    !QGroundControl.settingsManager.flyViewSettings.alternateInstrumentPanel.rawValue && (_mavlinkCamera || _videoStreamAvailable || _simpleCameraAvailable) && multiVehiclePanelSelector.showSingleVehiclePanel

    property real   _margins:                                   ScreenTools.defaultFontPixelHeight / 2
    property var    _activeVehicle:                             QGroundControl.multiVehicleManager.activeVehicle

    // The following properties relate to a simple camera
    property var    _flyViewSettings:                           QGroundControl.settingsManager.flyViewSettings
    property bool   _simpleCameraAvailable:                     !_mavlinkCamera && _activeVehicle && _flyViewSettings.showSimpleCameraControl.rawValue
    property bool   _onlySimpleCameraAvailable:                 !_anyVideoStreamAvailable && _simpleCameraAvailable
    property bool   _simpleCameraIsShootingInCurrentMode:       _onlySimpleCameraAvailable && !_simplePhotoCaptureIsIdle

    // The following properties relate to a simple video stream
    property bool   _videoStreamAvailable:                      _videoStreamManager.hasVideo
    property var    _videoStreamSettings:                       QGroundControl.settingsManager.videoSettings
    property var    _videoStreamManager:                        QGroundControl.videoManager
    property bool   _videoStreamAllowsPhotoWhileRecording:      true
    property bool   _videoStreamIsStreaming:                    _videoStreamManager.streaming
    property bool   _simplePhotoCaptureIsIdle:                  true
    property bool   _videoStreamRecording:                      _videoStreamManager.recording
    property bool   _videoStreamCanShoot:                       _videoStreamIsStreaming
    property bool   _videoStreamIsShootingInCurrentMode:        _videoStreamInPhotoMode ? !_simplePhotoCaptureIsIdle : _videoStreamRecording
    property bool   _videoStreamInPhotoMode:                    false
    property bool   _swarmSenseMode:                            false

    // The following properties relate to a mavlink protocol camera
    property var    _mavlinkCameraManager:                      _activeVehicle ? _activeVehicle.cameraManager : null
    property int    _mavlinkCameraManagerCurCameraIndex:        _mavlinkCameraManager ? _mavlinkCameraManager.currentCamera : -1
    property bool   _noMavlinkCameras:                          _mavlinkCameraManager ? _mavlinkCameraManager.cameras.count === 0 : true
    property var    _mavlinkCamera:                             !_noMavlinkCameras ? (_mavlinkCameraManager.cameras.get(_mavlinkCameraManagerCurCameraIndex) && _mavlinkCameraManager.cameras.get(_mavlinkCameraManagerCurCameraIndex).paramComplete ? _mavlinkCameraManager.cameras.get(_mavlinkCameraManagerCurCameraIndex) : null) : null
    property bool   _multipleMavlinkCameras:                    _mavlinkCameraManager ? _mavlinkCameraManager.cameras.count > 1 : false
    property string _mavlinkCameraName:                         _mavlinkCamera && _multipleMavlinkCameras ? _mavlinkCamera.modelName : ""
    property bool   _noMavlinkCameraStreams:                    _mavlinkCamera ? _mavlinkCamera.streamLabels.length : true
    property bool   _multipleMavlinkCameraStreams:              _mavlinkCamera ? _mavlinkCamera.streamLabels.length > 1 : false
    property int    _mavlinCameraCurStreamIndex:                _mavlinkCamera ? _mavlinkCamera.currentStream : -1
    property bool   _mavlinkCameraHasThermalVideoStream:        _mavlinkCamera ? _mavlinkCamera.thermalStreamInstance : false
    property bool   _mavlinkCameraModeUndefined:                _mavlinkCamera ? _mavlinkCamera.cameraMode === QGCCameraControl.CAM_MODE_UNDEFINED : true
    property bool   _mavlinkCameraInVideoMode:                  _mavlinkCamera ? _mavlinkCamera.cameraMode === QGCCameraControl.CAM_MODE_VIDEO : false
    property bool   _mavlinkCameraInPhotoMode:                  _mavlinkCamera ? _mavlinkCamera.cameraMode === QGCCameraControl.CAM_MODE_PHOTO : false
    property bool   _mavlinkCameraElapsedMode:                  _mavlinkCamera && _mavlinkCamera.cameraMode === QGCCameraControl.CAM_MODE_PHOTO && _mavlinkCamera.photoMode === QGCCameraControl.PHOTO_CAPTURE_TIMELAPSE
    property bool   _mavlinkCameraHasModes:                     _mavlinkCamera && _mavlinkCamera.hasModes
    property bool   _mavlinkCameraVideoIsRecording:             _mavlinkCamera && _mavlinkCamera.videoStatus === QGCCameraControl.VIDEO_CAPTURE_STATUS_RUNNING
    property bool   _mavlinkCameraPhotoCaptureIsIdle:           _mavlinkCamera && (_mavlinkCamera.photoStatus === QGCCameraControl.PHOTO_CAPTURE_IDLE || _mavlinkCamera.photoStatus >= QGCCameraControl.PHOTO_CAPTURE_LAST)
    property bool   _mavlinkCameraStorageReady:                 _mavlinkCamera && _mavlinkCamera.storageStatus === QGCCameraControl.STORAGE_READY
    property bool   _mavlinkCameraBatteryReady:                 _mavlinkCamera && _mavlinkCamera.batteryRemaining >= 0
    property bool   _mavlinkCameraStorageSupported:             _mavlinkCamera && _mavlinkCamera.storageStatus === QGCCameraControl.STORAGE_NOT_SUPPORTED
    property bool   _mavlinkCameraAllowsPhotoWhileRecording:    false
    property bool   _mavlinkCameraCanShoot:                     (!_mavlinkCameraModeUndefined && ((_mavlinkCameraStorageReady && _mavlinkCamera.storageFree > 0) || _mavlinkCameraStorageSupported)) || _videoStreamManager.streaming
    property bool   _mavlinkCameraIsShooting:                   ((_mavlinkCameraInVideoMode && _mavlinkCameraVideoIsRecording) || (_mavlinkCameraInPhotoMode && !_mavlinkCameraPhotoCaptureIsIdle)) || _videoStreamManager.recording

    // The following settings and functions unify between a mavlink camera and a simple video stream for simple access

    property bool   _anyVideoStreamAvailable:                   _videoStreamManager.hasVideo
    property string _cameraName:                                _mavlinkCamera ? _mavlinkCameraName : ""
    property bool   _showModeIndicator:                         _mavlinkCamera ? _mavlinkCameraHasModes : _videoStreamManager.hasVideo
    property bool   _modeIndicatorPhotoMode:                    _mavlinkCamera ? _mavlinkCameraInPhotoMode : _swarmSenseMode || _onlySimpleCameraAvailable
    property bool   _allowsPhotoWhileRecording:                  _mavlinkCamera ? _mavlinkCameraAllowsPhotoWhileRecording : _videoStreamAllowsPhotoWhileRecording
    property bool   _switchToPhotoModeAllowed:                  !_modeIndicatorPhotoMode && (_mavlinkCamera ? !_mavlinkCameraIsShooting : true)
    property bool   _switchToVideoModeAllowed:                  _modeIndicatorPhotoMode && (_mavlinkCamera ? !_mavlinkCameraIsShooting : true)
    property bool   _videoIsRecording:                          _mavlinkCamera ? _mavlinkCameraIsShooting : _videoStreamRecording
    property bool   _canShootInCurrentMode:                     _mavlinkCamera ? _mavlinkCameraCanShoot : _videoStreamCanShoot || _simpleCameraAvailable
    property bool   _isShootingInCurrentMode:                   _mavlinkCamera ? _mavlinkCameraIsShooting : _videoStreamIsShootingInCurrentMode || _simpleCameraIsShootingInCurrentMode

    function setSwarmSenseMode(mode) {
        _swarmSenseMode = mode
        if (_swarmSenseMode) {
            console.log("BioAir")
        } else {
            console.log("Video")
        }

    }

    function toggleShooting() {
        console.log("toggleShooting", _anyVideoStreamAvailable)
        if (_mavlinkCamera) {
            if(_mavlinkCameraInVideoMode) {
                _mavlinkCamera.toggleVideo()
            } else {
                if(_mavlinkCameraInPhotoMode && !_mavlinkCameraPhotoCaptureIsIdle && _mavlinkCameraElapsedMode) {
                    _mavlinkCamera.stopTakePhoto()
                } else {
                    _mavlinkCamera.takePhoto()
                }
            }
        } else if (_onlySimpleCameraAvailable || (_simpleCameraAvailable && _anyVideoStreamAvailable && _videoStreamInPhotoMode && !videoGrabRadio.checked)) {
            _simplePhotoCaptureIsIdle = false
            _activeVehicle.triggerSimpleCamera()
            simplePhotoCaptureTimer.start()
        } else if (_anyVideoStreamAvailable) {
            if (_videoStreamInPhotoMode) {
                _simplePhotoCaptureIsIdle = false
                _videoStreamManager.grabImage()
                simplePhotoCaptureTimer.start()
            } else {
                if (_videoStreamManager.recording) {
                    _videoStreamManager.stopRecording()
                } else {
                    _videoStreamManager.startRecording()
                }
            }
        }
    }

    Timer {
        id:             simplePhotoCaptureTimer
        interval:       500
        onTriggered:    _simplePhotoCaptureIsIdle = true
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    QGCColoredImage {
        anchors.margins:    _margins
        anchors.top:        parent.top
        anchors.right:      parent.right
        source:             "/res/gear-black.svg"
        mipmap:             true
        height:             ScreenTools.defaultFontPixelHeight
        width:              height
        sourceSize.height:  height
        color:              qgcPal.text
        fillMode:           Image.PreserveAspectFit
        visible:            !_onlySimpleCameraAvailable

        QGCMouseArea {
            fillItem:   parent
            onClicked:  mainWindow.showPopupDialogFromComponent(settingsDialogComponent)
        }
    }

    ColumnLayout {
        id:                         mainLayout
        anchors.margins:            _margins
        anchors.top:                parent.top
        anchors.horizontalCenter:   parent.horizontalCenter
        spacing:                    ScreenTools.defaultFontPixelHeight / 2

        // Photo/Video Mode Selector
        // IMPORTANT: This control supports both mavlink cameras and simple video streams. Do no reference anything here which is not
        // using the unified properties/functions.
        // ** Select video or photo
        Rectangle {
            Layout.alignment:   Qt.AlignHCenter
            width:              ScreenTools.defaultFontPixelWidth * 10
            height:             width / 2
            color:              qgcPal.windowShadeLight
            radius:             height * 0.5
            visible:            _showModeIndicator

            //-- Video Mode
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width:                  parent.height
                height:                 parent.height
                color:                  _modeIndicatorPhotoMode ? qgcPal.windowShadeLight : qgcPal.window
                radius:                 height * 0.5
                anchors.left:           parent.left
                border.color:           qgcPal.text
                border.width:           _modeIndicatorPhotoMode ? 0 : 1

                QGCColoredImage {
                    height:             parent.height * 0.5
                    width:              height
                    anchors.centerIn:   parent
                    source:             "/qmlimages/camera_video.svg"
                    fillMode:           Image.PreserveAspectFit
                    sourceSize.height:  height
                    color:              _modeIndicatorPhotoMode ? qgcPal.text : qgcPal.colorGreen
                    MouseArea {
                        anchors.fill:   parent
                        enabled:        _switchToVideoModeAllowed
                        onClicked:      setSwarmSenseMode(false)
                    }
                }
            }
            //-- BioAir Mode
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width:                  parent.height
                height:                 parent.height
                color:                  _modeIndicatorPhotoMode ? qgcPal.window : qgcPal.windowShadeLight
                radius:                 height * 0.5
                anchors.right:          parent.right
                border.color:           qgcPal.text
                border.width:           _modeIndicatorPhotoMode ? 1 : 0
                QGCColoredImage {
                    height:             parent.height * 0.5
                    width:              height
                    anchors.centerIn:   parent
                    source:             "/qmlimages/Quad.svg"
                    fillMode:           Image.PreserveAspectFit
                    sourceSize.height:  height
                    color:              _modeIndicatorPhotoMode ? qgcPal.colorGreen : qgcPal.text
                    MouseArea {
                        anchors.fill:   parent
                        enabled:        _switchToPhotoModeAllowed
                        onClicked:      setSwarmSenseMode(true)
                    }
                }
            }
        }

        // **Select button among two
        RowLayout {
            Layout.alignment:   Qt.AlignHCenter
            spacing:            0
            visible:            _showModeIndicator && !_mavlinkCamera && _simpleCameraAvailable && _videoStreamInPhotoMode

            QGCRadioButton {
                id:             videoGrabRadio
                font.pointSize: ScreenTools.smallFontPointSize
                text:           qsTr("Video Grab")
            }
            QGCRadioButton {
                font.pointSize: ScreenTools.smallFontPointSize
                text:           qsTr("Camera Trigger")
                checked:        true
            }
        }

        ColumnLayout {
            visible:    _swarmSenseMode

            RowLayout {
                Layout.alignment:   Qt.AlignHCenter
                Item {
                    width: ScreenTools.defaultFontPixelWidth * 10
                    height: width / 2
                    QGCLabel {
                        Layout.alignment:   Qt.AlignHCenter
                        font.bold:          true
                        text:               qsTr("BioAir")
                        font.pointSize:     ScreenTools.mediumFontPointSize - 2
                        visible:            QGroundControl.videoManager.isGStreamer && QGroundControl.settingsManager.videoSettings.gridLines.visible
                    }
                }

                Item {
                    width: ScreenTools.defaultFontPixelWidth * 10
                    height: width / 2
                    QGCSwitch {
                        id:                 bioairBtn
                        enabled:            _activeVehicle
                        checked:            _activeVehicle ? _activeVehicle.bioairOn : false
                        visible:            _activeVehicle
                        Layout.alignment:   Qt.AlignHCenter
                        onClicked: {
                            if(checked) {
                                _activeVehicle.setBioairOn(true)
                            } else {
                                _activeVehicle.setBioairOn(false)
                            }
                        }
                    }
                }
            }

            Column {
                Layout.alignment:   Qt.AlignHCenter
                spacing: 5

                Repeater {
                    model: QGroundControl.multiVehicleManager.vehicles
                    Layout.alignment:   Qt.AlignHCenter

                    ColumnLayout {
                        width:      ScreenTools.defaultFontPixelWidth * 25
                        height:     width / 2 - 30
                        visible:    _activeVehicle ? _activeVehicle.id !== object.id : false
                        spacing:    1

                        QGCLabel {
                            Layout.alignment:   Qt.AlignHCenter
                            text:               qsTr("Vehicle %1").arg(object.id)
                            font.bold:          true
                            font.pointSize:     ScreenTools.mediumFontPointSize
                            width:              parent.width
                            height:             5
                        }

                        GridLayout {
                            Layout.alignment:   Qt.AlignHCenter
                            width: parent.width
                            height: parent.height - 25
                            rows:       2
                            columns:    3

                            Item {
                                Layout.row:         1
                                Layout.rowSpan:     1
                                Layout.column:      1
                                Layout.columnSpan:  1
                                width:              parent.width / 3
                                height:             parent.height / 4
                                QGCLabel {
                                    Layout.alignment:   Qt.AlignHCenter
                                    text: qsTr("Distance")
                                    font.pointSize:     ScreenTools.smallFontPointSize
                                }
                            }

                            Item {
                                Layout.row:         2
                                Layout.rowSpan:     1
                                Layout.column:      1
                                Layout.columnSpan:  1
                                width:              parent.width / 3
                                height:             parent.height / 4
                                QGCLabel {
                                    Layout.alignment:   Qt.AlignHCenter
                                    text: qsTr("10 m")
                                }
                            }

                            Item {
                                Layout.row:         1
                                Layout.rowSpan:     1
                                Layout.column:      2
                                Layout.columnSpan:  1
                                width:              parent.width / 3
                                height:             parent.height / 4
                                QGCLabel {
                                    Layout.alignment:   Qt.AlignHCenter
                                    text: qsTr("State")
                                    font.pointSize:     ScreenTools.smallFontPointSize
                                }
                            }

                            Item {
                                Layout.row:         2
                                Layout.rowSpan:     1
                                Layout.column:      2
                                Layout.columnSpan:  1
                                width:              parent.width / 3
                                height:             parent.height / 4
                                QGCLabel {
                                    Layout.alignment:   Qt.AlignHCenter
                                    text: qsTr("Origin")
                                }
                            }

                            Image {
                                Layout.row:         1
                                Layout.rowSpan:     4
                                Layout.column:      3
                                Layout.columnSpan:  1
                                width:              parent.width / 2 + 50
                                height:             parent.height + 10
                                source:             "/qmlimages/resources/signal_quality_excellent.png"
                            }
                        }
                    }
                }
            }
        }

        GridLayout {
            rows:       5
            columns:    2
            visible:    !_swarmSenseMode

            Item {
                Layout.row:         1
                Layout.rowSpan:     1
                Layout.column:      1
                Layout.columnSpan:  1
                width:              ScreenTools.defaultFontPixelWidth * 10
                height:             width / 2 + 10

                ColumnLayout {
                    anchors.top:                parent.top
                    anchors.horizontalCenter:   parent.horizontalCenter

                    QGCLabel {
                       text:                qsTr("RGB")
                       font.pointSize:      ScreenTools.mediumFontPointSize-2
                       Layout.alignment:    Qt.AlignHCenter
                       font.bold:           true
                    }

                    QGCSwitch {
                        id:                 rgbBtn
                        enabled:            _activeVehicle
                        checked:            _activeVehicle ? _activeVehicle.streaminOn === 0 || _activeVehicle.streaminOn === 1 : false
                        visible:            _activeVehicle
                        Layout.alignment:   Qt.AlignHCenter
                        onClicked: {
                            if(rgbBtn.checked) {
                                if(_activeVehicle.streamingOn === 2){
                                    _activeVehicle.setStreamingOn(0)
                                } else if (_activeVehicle.streamingOn === -1) {
                                    _activeVehicle.setStreamingOn(1)
                                }

                            } else {
                                if(_activeVehicle.streamingOn === 0){
                                    _activeVehicle.setStreamingOn(2)
                                } else if (_activeVehicle.streamingOn === 1) {
                                    _activeVehicle.setStreamingOn(-1)
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.row:         1
                Layout.rowSpan:     1
                Layout.column:      2
                Layout.columnSpan:  1
                width:              ScreenTools.defaultFontPixelWidth * 10
                height:             width / 2 + 10

                ColumnLayout {
                    anchors.top:                parent.top
                    anchors.horizontalCenter:   parent.horizontalCenter

                    QGCLabel {
                       text:                qsTr("Depth")
                       font.bold:           true
                       font.pointSize:      ScreenTools.mediumFontPointSize-2
                       Layout.alignment:    Qt.AlignHCenter
                    }

                    QGCSwitch {
                        id:                 depthBtn
                        enabled:            _activeVehicle
                        checked:            _activeVehicle ? _activeVehicle.streaminOn === 0 || _activeVehicle.streaminOn === 2 : false
                        visible:            _activeVehicle
                        Layout.alignment:   Qt.AlignHCenter
                        onClicked: {
                            if(depthBtn.checked) {
                                if(_activeVehicle.streamingOn === 1){
                                    _activeVehicle.setStreamingOn(0)
                                } else if (_activeVehicle.streamingOn === -1) {
                                    _activeVehicle.setStreamingOn(2)
                                }
                            } else {
                                if(_activeVehicle.streamingOn === 0){
                                    _activeVehicle.setStreamingOn(1)
                                } else if (_activeVehicle.streamingOn === 2) {
                                    _activeVehicle.setStreamingOn(-1)
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.row:         2
                Layout.rowSpan:     1
                Layout.column:      1
                Layout.columnSpan:  1
                width:              ScreenTools.defaultFontPixelWidth * 10
                height:             width / 2 + 10

                ColumnLayout {
                    anchors.top:                parent.top
                    anchors.horizontalCenter:   parent.horizontalCenter

                    QGCLabel {
                       text:                qsTr("AI")
                       font.bold:           true
                       font.pointSize:      ScreenTools.mediumFontPointSize-2
                       Layout.alignment:    Qt.AlignHCenter
                    }

                    QGCSwitch {
                        id:                 aiBtn
                        enabled:            _activeVehicle
                        checked:            _activeVehicle ? _activeVehicle.aiOn : false
                        visible:            _activeVehicle
                        Layout.alignment:   Qt.AlignHCenter
                        onClicked: {
                            if(checked) {
                                _activeVehicle.setAiOn(true)
                            } else {
                                _activeVehicle.setAiOn(false)
                            }
                        }
                    }
                }
            }

            Item {
                Layout.row:         2
                Layout.rowSpan:     1
                Layout.column:      2
                Layout.columnSpan:  1
                width:              ScreenTools.defaultFontPixelWidth * 10
                height:             width / 2 + 10

                ColumnLayout {
                    anchors.top:                parent.top
                    anchors.horizontalCenter:   parent.horizontalCenter

                    QGCLabel {
                       text:                qsTr("Tracking")
                       font.bold:           true
                       font.pointSize:      ScreenTools.mediumFontPointSize-2
                       Layout.alignment:    Qt.AlignHCenter
                    }

                    QGCSwitch {
                        id:                 trackingBtn
                        enabled:            _activeVehicle
                        checked:            _activeVehicle ? _activeVehicle.aiOn : false
                        visible:            _activeVehicle
                        Layout.alignment:   Qt.AlignHCenter
                        onClicked: {
                            if(checked) {
                                _activeVehicle.setAiOn(true)
                            } else {
                                _activeVehicle.setAiOn(false)
                            }
                        }
                    }
                }
            }

             ColumnLayout {
                Layout.row:         3
                Layout.rowSpan:     1
                Layout.column:      1
                Layout.columnSpan:  2
                Layout.alignment:   Qt.AlignHCenter

                QGCLabel {
                   Layout.alignment:    Qt.AlignHCenter
                   text:                qsTr("Sensor Range")
                   font.pointSize:      ScreenTools.mediumFontPointSize - 2
                   font.bold:           true
                }

                QGCSlider {
                    id:                     wizardPresetsAngleSlider
                    visible:                true//sensorRangeBtn.checked
                    minimumValue:           10
                    maximumValue:           200
                    value:                  _activeVehicle ? _activeVehicle.sensorRange : false
                    stepSize:               10
                    tickmarksEnabled:       false
                    Layout.fillWidth:       true
                    Layout.columnSpan:      2
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
                    onValueChanged:         _activeVehicle ? _activeVehicle.setSensorRange(value) : null
                    updateValueWhileDragging: true
                }
            }
        }
    }

    Component {
        id: settingsDialogComponent

        QGCPopupDialog {
            title:      qsTr("Settings")
            buttons:    StandardButton.Close

            ColumnLayout {
                spacing: _margins

                GridLayout {
                    id:     gridLayout
                    flow:   GridLayout.TopToBottom
                    rows:   dynamicRows + (_mavlinkCamera ? _mavlinkCamera.activeSettings.length : 0)

                    property int dynamicRows: 10

                    // First column
                    QGCLabel {
                        text:               qsTr("Camera")
                        visible:            _multipleMavlinkCameras
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    QGCLabel {
                        text:               qsTr("Video Stream")
                        visible:            _multipleMavlinkCameraStreams
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    QGCLabel {
                        text:               qsTr("Thermal View Mode")
                        visible:            _mavlinkCameraHasThermalVideoStream
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    QGCLabel {
                        text:               qsTr("Blend Opacity")
                        visible:            _mavlinkCameraHasThermalVideoStream && _mavlinkCamera.thermalMode === QGCCameraControl.THERMAL_BLEND
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    // Mavlink Camera Protocol active settings
                    Repeater {
                        model: _mavlinkCamera ? _mavlinkCamera.activeSettings : []

                        QGCLabel {
                            text: _mavlinkCamera.getFact(modelData).shortDescription
                        }
                    }

                    QGCLabel {
                        text:               qsTr("Photo Mode")
                        visible:            _mavlinkCameraHasModes
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    QGCLabel {
                        text:               qsTr("Photo Interval (seconds)")
                        visible:            _mavlinkCameraInPhotoMode && _mavlinkCamera.photoMode === QGCCameraControl.PHOTO_CAPTURE_TIMELAPSE
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    QGCLabel {
                        text:               qsTr("Video Grid Lines")
                        visible:            _anyVideoStreamAvailable
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    QGCLabel {
                        text:               qsTr("Video Screen Fit")
                        visible:            _anyVideoStreamAvailable
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    QGCLabel {
                        text:               qsTr("Reset Camera Defaults")
                        visible:            _mavlinkCamera
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    QGCLabel {
                        text:               qsTr("Storage")
                        visible:            _mavlinkCameraStorageSupported
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    // Second column
                    QGCComboBox {
                        Layout.fillWidth:   true
                        sizeToContents:     true
                        model:              _mavlinkCameraManager ? _mavlinkCameraManager.cameraLabels : []
                        currentIndex:       _mavlinkCameraManagerCurCameraIndex
                        visible:            _multipleMavlinkCameras
                        onActivated:        _mavlinkCameraManager.currentCamera = index
                    }

                    QGCComboBox {
                        Layout.fillWidth:   true
                        sizeToContents:     true
                        model:              _mavlinkCamera ? _mavlinkCamera.streamLabels : []
                        currentIndex:       _mavlinCameraCurStreamIndex
                        visible:            _multipleMavlinkCameraStreams
                        onActivated:        _mavlinkCamera.currentStream = index
                    }

                    QGCComboBox {
                        Layout.fillWidth:   true
                        sizeToContents:     true
                        model:              [ qsTr("Off"), qsTr("Blend"), qsTr("Full"), qsTr("Picture In Picture") ]
                        currentIndex:       _mavlinkCamera ? _mavlinkCamera.thermalMode : -1
                        visible:            _mavlinkCameraHasThermalVideoStream
                        onActivated:        _mavlinkCamera.thermalMode = index
                    }

                    QGCSlider {
                        Layout.fillWidth:           true
                        maximumValue:               100
                        minimumValue:               0
                        value:                      _mavlinkCamera ? _mavlinkCamera.thermalOpacity : 0
                        updateValueWhileDragging:   true
                        visible:                    _mavlinkCameraHasThermalVideoStream && _mavlinkCamera.thermalMode === QGCCameraControl.THERMAL_BLEND
                        onValueChanged:             _mavlinkCamera.thermalOpacity = value
                    }

                    // Mavlink Camera Protocol active settings
                    Repeater {
                        model: _mavlinkCamera ? _mavlinkCamera.activeSettings : []

                        RowLayout {
                            Layout.fillWidth:   true
                            spacing:            ScreenTools.defaultFontPixelWidth

                            property var    _fact:      _mavlinkCamera.getFact(modelData)
                            property bool   _isBool:    _fact.typeIsBool
                            property bool   _isCombo:   !_isBool && _fact.enumStrings.length > 0
                            property bool   _isSlider:  _fact && !isNaN(_fact.increment)
                            property bool   _isEdit:    !_isBool && !_isSlider && _fact.enumStrings.length < 1

                            FactComboBox {
                                Layout.fillWidth:   true
                                sizeToContents:     true
                                fact:               parent._fact
                                indexModel:         false
                                visible:            parent._isCombo
                            }
                            FactTextField {
                                Layout.fillWidth:   true
                                fact:               parent._fact
                                visible:            parent._isEdit
                            }
                            QGCSlider {
                                Layout.fillWidth:           true
                                maximumValue:               parent._fact.max
                                minimumValue:               parent._fact.min
                                stepSize:                   parent._fact.increment
                                visible:                    parent._isSlider
                                updateValueWhileDragging:   false
                                onValueChanged:             parent._fact.value = value
                                Component.onCompleted:      value = parent._fact.value
                            }
                            QGCSwitch {
                                checked:        parent._fact ? parent._fact.value : false
                                visible:        parent._isBool
                                onClicked:      parent._fact.value = checked ? 1 : 0
                            }
                        }
                    }

                    QGCComboBox {
                        Layout.fillWidth:   true
                        sizeToContents:     true
                        model:              [ qsTr("Single"), qsTr("Time Lapse") ]
                        currentIndex:       _mavlinkCamera ? _mavlinkCamera.photoMode : 0
                        visible:            _mavlinkCameraHasModes
                        onActivated:        _mavlinkCamera.photoMode = index
                    }

                    QGCSlider {
                        Layout.fillWidth:           true
                        maximumValue:               60
                        minimumValue:               1
                        stepSize:                   1
                        value:                      _mavlinkCamera ? _mavlinkCamera.photoLapse : 5
                        displayValue:               true
                        updateValueWhileDragging:   true
                        visible:                    _mavlinkCameraInPhotoMode && _mavlinkCamera.photoMode === QGCCameraControl.PHOTO_CAPTURE_TIMELAPSE
                        onValueChanged: {
                            if (_mavlinkCamera) {
                                _mavlinkCamera.photoLapse = value
                            }
                        }
                    }

                    QGCSwitch {
                        checked:            _videoStreamSettings.gridLines.rawValue
                        visible:            _anyVideoStreamAvailable
                        onClicked:          _videoStreamSettings.gridLines.rawValue = checked ? 1 : 0
                    }

                    FactComboBox {
                        Layout.fillWidth:   true
                        sizeToContents:     true
                        fact:               _videoStreamSettings.videoFit
                        indexModel:         false
                        visible:            _anyVideoStreamAvailable
                    }

                    QGCButton {
                        Layout.fillWidth:   true
                        text:               qsTr("Reset")
                        visible:            _mavlinkCamera
                        onClicked:          resetPrompt.open()
                        MessageDialog {
                            id:                 resetPrompt
                            title:              qsTr("Reset Camera to Factory Settings")
                            text:               qsTr("Confirm resetting all settings?")
                            standardButtons:    StandardButton.Yes | StandardButton.No
                            onNo: resetPrompt.close()
                            onYes: {
                                _mavlinkCamera.resetSettings()
                                resetPrompt.close()
                            }
                        }
                    }

                    QGCButton {
                        Layout.fillWidth:   true
                        text:               qsTr("Format")
                        visible:            _mavlinkCameraStorageSupported
                        onClicked:          formatPrompt.open()
                        MessageDialog {
                            id:                 formatPrompt
                            title:              qsTr("Format Camera Storage")
                            text:               qsTr("Confirm erasing all files?")
                            standardButtons:    StandardButton.Yes | StandardButton.No
                            onNo: formatPrompt.close()
                            onYes: {
                                _mavlinkCamera.formatCard()
                                formatPrompt.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
