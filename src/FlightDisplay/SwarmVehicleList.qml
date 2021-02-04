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
import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    id:     swarm

    readonly property real  _fontSize: Math.min(parent.width * 0.01, 13)

    property real   _margin:        ScreenTools.defaultFontPixelWidth / 2
    property real   _widgetHeight:  ScreenTools.defaultFontPixelHeight * 3
    property color  _textColor:     "white"
    property real   _rectOpacity:   1

    property bool isHidden:  false
    property bool isDark:    true

    property bool isInitial:    true

    QGCPalette { id: qgcPal }

    //-- PIP Corner Indicator(close button --> if user doesn't want to show drone's information(streaming screen...), this button can disappears all drones information.)
    Rectangle {
        id:                     closePIP
        anchors.left:   parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 2
        height:                 swarmStatusListView.height;
        width:                  ScreenTools.defaultFontPixelHeight
        radius:                 ScreenTools.defaultFontPixelHeight / 3
        visible:                isHidden
        color:                  isDark ? Qt.rgba(0,0,0,0.75) : Qt.rgba(0,0,0,0.5)
        z:   _mapAndVideo.z +6
        Image {
            width:              parent.width  * 0.75
            height:             parent.height * 0.75
            sourceSize.height:  height
            source:             "/res/buttonLeft.svg"
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            anchors.verticalCenter:     parent.verticalCenter
            anchors.horizontalCenter:   parent.horizontalCenter
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                isHidden = false
            }
        }
    }

    //-- show PIP (open button --> if user wants to show drone's information(streaming screen...), this button can appears all drones information.)
    Rectangle {
        id:                     openPIP
        anchors.left:   parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 2
        height:                 swarmStatusListView.height
        width:                  ScreenTools.defaultFontPixelHeight
        radius:                 ScreenTools.defaultFontPixelHeight / 3
        visible:                !isHidden
        color:                  isDark ? Qt.rgba(0,0,0,0.75) : Qt.rgba(0,0,0,0.5)
        z: _mapAndVideo.z +6
        Image {
            width:              parent.width  * 0.75
            height:             parent.height * 0.75
            sourceSize.height:  height
            source:             "/res/buttonRight.svg"
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            anchors.verticalCenter:     parent.verticalCenter
            anchors.horizontalCenter:   parent.horizontalCenter
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                isHidden = true
            }
        }
    }

    // ListView of multiple drones(Bind several drones together)
    QGCListView {
        id:                 swarmStatusListView
        anchors.left:       openPIP.right
        anchors.leftMargin: ScreenTools.defaultFontPixelHeight / 2
        anchors.right:      parent.right
        anchors.bottom:     parent.bottom
        height:             240 + _fontSize //300 + _fontSize
        spacing:            ScreenTools.defaultFontPixelHeight / 2
        orientation:        ListView.Horizontal
        model:              QGroundControl.multiVehicleManager.vehicles
        cacheBuffer:        _cacheBuffer < 0 ? 0 : _cacheBuffer
        clip:               true
        visible:            isHidden

        property real _cacheBuffer:     height * 2
        property int prevIndex:         -1

        delegate: GridLayout { // Use 'GridLayout' for binding several drones (Recommand to find information of GridLayout)
            id: grid
            rows: 2
            flow: GridLayout.TopToBottom
            property var    _vehicle:   object
            property string _status: "Connect"
            property string _signalQuality: ""
            property int _rtlTime: 60
            property int _remainTime: _rtlTime

            property int gridIndex: index

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

            // If drone disconnects in QGC, drone wait 60 seconds.
            // After 60 seconds, If drone continues disconnection in QGC, this drone receives RTL.(come back.)
            function countingRemainTime() {
                if(_vehicle && _vehicle.connectionLost){
                    if (!remainTimer.visible) {
                        _vehicle.rtlOn = true
                        remainTimer.visible = true
                        remainTimer.isDisconnect = false
                    }

                    switch_rgb.checked = false
                    switch_depth.checked = false
                    switch_AI.checked = false
                    switch_bioAir.checked = false

                    if(_vehicle.streamingOn !== -1){
                        _vehicle.streamingOn = -1
                    }

                    if(!_vehicle.mainIsMap){ // When the drone disconnects qgc, main screen is always map screen!
                        if ( _vehicleVideoView ){
                            swarmStatusListView.currentIndex = _curMainVideoVehicle
                            var videoView = swarmStatusListView.currentItem.children[0].children[1]
                            videoView.data = _vehicleVideoView
                        }

                        _prevMainVideoVehicle = _curMainVideoVehicle
                        _curMainVideoVehicle = -1
                        _vehicle.mainIsMap = true
                        swarm.active(_vehicle.mainIsMap,  null)
                    }

                    if (_remainTime == 30) {
                        mainWindow.showWarningMessage(qsTr("WARNING: 30s till Failsafe Mode for Drone %1").arg(_vehicle.id))
                    }else if (_remainTime == 15) {
                        mainWindow.showWarningMessage(qsTr("WARNING: 15s till Failsafe Mode for Drone %1").arg(_vehicle.id))
                    }else if (_remainTime <= 10 && _remainTime > 0) {
                        _status = qsTr("%1 ").arg(_vehicle.id)
                    }else if (_remainTime <= 0) {
                        if (_remainTime == 0) mainWindow.showWarningMessage(qsTr("WARNING: %1 returning to launch position.").arg(_vehicle.id))
                        remainTimer.isDisconnect = true

                    }else {
                        _status = qsTr("%1 ").arg(_vehicle.id)
                    }
                    _remainTime--
                }
                else{
                    _status = qsTr("%1 ").arg(_vehicle.id)
                    _remainTime = _rtlTime
                    remainTimer.visible = false
                    if(_vehicle.rtlOn){ // RTL(disconnect)
                        _vehicle.rtlOn =false
                        if(_vehicle.aiOn){ // For turn off AI that turns on before RTL
                            _vehicle.aiOn = false
                        }
                        if(_vehicle.bioairOn){ // For turn off BioAIR that turns on before RTL
                            _vehicle.bioairOn = false
                        }
                    }
                    if(isInitial){ // To prevent errors, When the qgc on first time, turn off the AI and BioAIR(Initial setting)
                        _vehicle.aiOn = false
                        _vehicle.bioairOn = false
                        isInitial = false
                    }
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

            Item {
                id: _mapAndVideoInSwarmStatus
                width: 240
                height: 185

                //If the full screen is map(drone's video streaming), drone's screen shows video view(map view).
                //-- Map View
                Item {
                    id: _flightMapContainerInSwarmStatus
                    visible: !_vehicle.mainIsMap
                    anchors.fill: parent
                }

                //-- Video View
                Item {
                    id:             _flightVideoInSwarmStatus
                    anchors.fill:   parent
                    visible:       _vehicle.mainIsMap

                    //-- videoView
                    SwarmVehicleListVideo {
                        id: videoStreamingInSwarmStatus
                        anchors.fill: parent
                        visible: QGroundControl.videoManager.isGStreamer
                        vehicleVideoReceiver: _vehicle.videoReceiver
                        vehicleId: _vehicle.id
                    }
                }

                // MouseArea is a screen that shows drone's live streaming
                MouseArea {
                    id: videoMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !remainTimer.visible

                    onClicked: { // When mouseArea clicks, it saves clicked drone's streaming screen.
                        if ( _vehicleVideoView ){
                            swarmStatusListView.currentIndex = _curMainVideoVehicle
                            var videoView = swarmStatusListView.currentItem.children[0].children[1]
                            videoView.data = _vehicleVideoView
                        }

                        if (_vehicle.mainIsMap) {
                            for(var i=0; i<QGroundControl.multiVehicleManager.vehicles.count; i++){
                                var aVehicle = QGroundControl.multiVehicleManager.vehicles.get(i)
                                if(i === gridIndex){
                                    _prevMainVideoVehicle = _curMainVideoVehicle
                                    _curMainVideoVehicle = gridIndex
                                    aVehicle.mainIsMap = false
                                    _flightMapContainerInSwarmStatus.data = mainWindow.flightDisplayMap
                                    swarm.active(aVehicle.mainIsMap,_flightVideoInSwarmStatus.children[0])
                                }else{
                                    aVehicle.mainIsMap = true
                                }
                            }
                        }
                        else {
                            _prevMainVideoVehicle = _curMainVideoVehicle
                            _curMainVideoVehicle = -1
                            _vehicle.mainIsMap = true
                            swarm.active(_vehicle.mainIsMap,  null)
                        }
                    }
                }
            }

            // design part(4 button(function))
            Rectangle {
                width:      240
                height:     swarmStatusListView.height - _mapAndVideoInSwarmStatus.height
                color:      qgcPal.window
                opacity:    _rectOpacity
                radius:     _margin

                Image {
                    id:                 icon
                    visible:            !remainTimer.visible
                    anchors.right:      parent.right
                    anchors.bottom:     parent.bottom
                    height:             ScreenTools.defaultFontPixelWidth * 6
                    width:              ScreenTools.defaultFontPixelWidth * 6
                    sourceSize.width:   parent.width
                    fillMode:           Image.PreserveAspectFit
                    source:             getIcon(_vehicle.messagesIn2sec)
                }

                ColumnLayout {
                    id:                 innerColumn
                    anchors.margins:    _margin
                    anchors.top:        parent.top
                    anchors.left:       parent.left
                    spacing:            _margin

                    RowLayout {
                        id:                     statusRow
                        Layout.fillWidth:       false

                        RowLayout {
                            Layout.alignment:   Qt.AlignCenter
                            Layout.rightMargin: 5
                            spacing:            _margin
                            Layout.preferredWidth: _fontSize * 3

                            QGCLabel {
                                Layout.alignment:           Qt.AlignHCenter
                                text:                       qsTr("%1").arg(_status)
                                color:                      _textColor
                                font.pointSize:             _fontSize
                            }
                        }

                        GridLayout{
                            id: videoCol
                            Layout.alignment:   Qt.AlignCenter
                            Layout.rightMargin: 6
                            rows: 2
                            columns: 2

                            CheckBox {
                                id: switch_rgb
                                text: qsTr("RGB")
                                font.pointSize: 10
                                checked:
                                    (_vehicle.streamingOn === 0 || _vehicle.streamingOn === 1)? true : false
                                onToggled:{
                                    if(!remainTimer.visible){
                                        if(switch_rgb.checked && switch_depth.checked){
                                            _vehicle.streamingOn = 0
                                        }else if(switch_rgb.checked && !switch_depth.checked){
                                            _vehicle.streamingOn = 1
                                        }else if(!switch_rgb.checked && switch_depth.checked){
                                            _vehicle.streamingOn = 2
                                        }else{
                                            _vehicle.streamingOn = -1
                                        }
                                    }
                                }

                                indicator: Rectangle {
                                    implicitWidth: 15
                                    implicitHeight: 15
                                    y: parent.height / 2 - height / 2
                                    radius: 3
                                    color: !switch_rgb.checked ? "#777777" : "#d9d9d9"
                                    border.color: switch_rgb.checked ? "#777777" : "#777777"

                                    Rectangle {
                                        width: 15
                                        height: 15
                                        radius: 3
                                        color: switch_rgb.down ? "#cccccc" : "#ffffff"
                                        border.color: switch_rgb.checked ? (switch_rgb.down ? "#cccccc" : "#cccccc") : "#cccccc"
                                        visible: switch_rgb.checked
                                    }
                                }

                                contentItem: Text {
                                    text: switch_rgb.text
                                    font: switch_rgb.font
                                    opacity: enabled ? 1.0 : 0.3
                                    color: switch_rgb.down ? "white" : "white"
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: switch_rgb.indicator.width
                                }
                            }

                            CheckBox {
                                id: switch_depth
                                text: qsTr("Depth")
                                font.pointSize: 10
                                checked: (_vehicle.streamingOn === 0 || _vehicle.streamingOn === 2)? true : false
                                onToggled:{
                                    if (!remainTimer.visible){
                                        if(switch_rgb.checked && switch_depth.checked){
                                            _vehicle.streamingOn = 0
                                        }else if(switch_rgb.checked && !switch_depth.checked){
                                            _vehicle.streamingOn = 1
                                        }else if(!switch_rgb.checked && switch_depth.checked){
                                            _vehicle.streamingOn = 2
                                        }else{
                                            _vehicle.streamingOn = -1
                                        }
                                    }
                                }

                                indicator: Rectangle {
                                    implicitWidth: 15
                                    implicitHeight: 15
                                    y: parent.height / 2 - height / 2
                                    radius: 3
                                    color: !switch_depth.checked ? "#777777" : "#d9d9d9"
                                    border.color: switch_depth.checked ? "#777777" : "#777777"

                                    Rectangle {
                                        width: 15
                                        height: 15
                                        radius: 3
                                        color: switch_depth.down ? "#cccccc" : "#ffffff"
                                        border.color: switch_depth.checked ? (switch_depth.down ? "#cccccc" : "#cccccc") : "#cccccc"
                                        visible: switch_depth.checked
                                    }
                                }

                                contentItem: Text {
                                    text: switch_depth.text
                                    font: switch_depth.font
                                    opacity: enabled ? 1.0 : 0.3
                                    color: switch_depth.down ? "white" : "white"
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: switch_depth.indicator.width
                                }
                            }

                            CheckBox {
                                id:   switch_AI
                                text: qsTr("AI")
                                font.pointSize: 10
                                checked: _vehicle.aiOn
                                onToggled: _vehicle.aiOn = remainTimer.visible? false : switch_AI.checked

                                indicator: Rectangle {
                                    implicitWidth: 15
                                    implicitHeight: 15
                                    y: parent.height / 2 - height / 2
                                    radius: 3
                                    color: !switch_AI.checked ? "#777777" : "#d9d9d9"
                                    border.color: switch_AI.checked ? "#777777" : "#777777"

                                    Rectangle {
                                        width: 15
                                        height: 15
                                        radius: 3
                                        color: switch_AI.down ? "#cccccc" : "#ffffff"
                                        border.color: switch_AI.checked ? (switch_AI.down ? "#cccccc" : "#cccccc") : "#cccccc"
                                        visible: switch_AI.checked
                                    }
                                }

                                contentItem: Text {
                                    text: switch_AI.text
                                    font: switch_AI.font
                                    opacity: enabled ? 1.0 : 0.3
                                    color: switch_AI.down ? "white" : "white"
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: switch_AI.indicator.width
                                }
                            }

                            CheckBox{
                                id:   switch_bioAir
                                text: qsTr("BioAir")
                                font.pointSize: 10
                                checked: _vehicle.bioairOn
                                onToggled: _vehicle.bioairOn = remainTimer.visible? false : switch_bioAir.checked

                                indicator: Rectangle {
                                    implicitWidth: 15
                                    implicitHeight: 15
                                    y: parent.height / 2 - height / 2
                                    radius: 3
                                    color: !switch_bioAir.checked ? "#777777" : "#d9d9d9"
                                    border.color: switch_bioAir.checked ? "#777777" : "#777777"

                                    Rectangle {
                                        x: switch_bioAir.checked ? parent.width - width : 0
                                        width: 15
                                        height: 15
                                        radius: 3
                                        color: switch_bioAir.down ? "#cccccc" : "#ffffff"
                                        border.color: switch_bioAir.checked ? (switch_bioAir.down ? "#cccccc" : "#cccccc") : "#cccccc"
                                        visible: switch_bioAir.checked
                                    }
                                }
                                contentItem: Text {
                                    text: switch_bioAir.text
                                    font: switch_bioAir.font
                                    opacity: enabled ? 1.0 : 0.3
                                    color: switch_bioAir.down ? "white" : "white"
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: switch_bioAir.indicator.width
                                }
                            }
                        }

                        RowLayout{ //If the drone diconnects in QGC, it shows.
                            Layout.alignment:   Qt.AlignCenter
                            spacing:            _margin

                            QGCLabel {
                                id:                         remainTimer
                                visible:                    false
                                Layout.alignment:           Qt.AlignHCenter
                                text:                       remainTimer.isDisconnect? qsTr("RTL") : qsTr("%1").arg(_remainTime)
                                color:                      Qt.rgba(1, 0, 0, 1)
                                font.pointSize:             _fontSize * 1.5
                                font.family:                "digital-7"
                            }
                        }
                    }

//                    RowLayout {
//                        id:                     gcsRow
//                        Layout.fillWidth:       true

//                        ColumnLayout {
//                            Layout.alignment:   Qt.AlignCenter
//                            spacing:            _margin
//                            Image {
//                                id:                 gcsIcon
//                                height:             ScreenTools.defaultFontPixelWidth * 3
//                                width:              ScreenTools.defaultFontPixelWidth * 3
//                                sourceSize.width:   _fontSize * 1.5
//                                fillMode:           Image.PreserveAspectFit
//                                source:             "/res/QGCLogoArrow"
//                            }
//                        }

//                        ColumnLayout {
//                            Layout.alignment:   Qt.AlignCenter
//                            spacing:            _margin

//                            QGCLabel {
//                                Layout.alignment:           Qt.AlignHCenter
//                                text:                       toGCS(_vehicle.distanceToGCS.value)
//                                color:                      _textColor
//                                font.pointSize:             _fontSize
//                            }
//                        }
//                    }

//                    RowLayout {
//                        id:                     homeRow
//                        Layout.fillWidth:       true

//                        ColumnLayout{
//                            Layout.alignment:   Qt.AlignCenter
//                            spacing:            _margin
//                            Image {
//                                id:                 homeIcon
//                                height:             ScreenTools.defaultFontPixelWidth * 3
//                                width:              ScreenTools.defaultFontPixelWidth * 3
//                                sourceSize.width:   _fontSize * 1.5
//                                fillMode:           Image.PreserveAspectFit
//                                source:             "/qmlimages/MapHome.svg"
//                            }
//                        }

//                        ColumnLayout {
//                            Layout.alignment:   Qt.AlignCenter
//                            spacing:            _margin

//                            QGCLabel {
//                                Layout.alignment:           Qt.AlignHCenter
//                                text:                       toHome(_vehicle.distanceToHome.value)
//                                color:                      _textColor
//                                font.pointSize:             _fontSize
//                            }
//                        }
//                    }
                }
            }
        } // delegate - Rectangle
    } // QGCListView
} // Item
