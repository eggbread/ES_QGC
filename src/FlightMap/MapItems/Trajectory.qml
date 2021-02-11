/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.3
import QtLocation       5.3
import QtPositioning    5.3

import QGroundControl           1.0
import QGroundControl.Controls  1.0
import QGroundControl.FlightMap 1.0

// Adds visual items associated with the Flight Plan to the map.
// Currently only used by Fly View even though it's called PlanMapItems!
Item {
    id: _root

    property var    map                 ///< Map control to show items on

    property var    vehicle             ///< Vehicle associated with these items
    property bool   show

    property var    _map:                       map
    property var    _vehicle:                   vehicle

    property var    _sensorComponent
//    property bool   _isActiveVehicle:           vehicle.active

    property string fmode: vehicle.flightMode

    Component.onCompleted: {
        _sensorComponent = sensorComponent.createObject(map)
        if (_sensorComponent.status === Component.Error)
            console.log(_sensorComponent.errorString())
        map.addMapItem(_sensorComponent)
    }

    Component.onDestruction: {
        _sensorComponent.destroy()
    }

    Component {
        id: sensorComponent

        MapPolyline {
            id: sensorTrajectory
            line.width: 1
            line.color: "#87ceeb"                           // Hack, can't get palette to work in here
            path:       _vehicle.trajectoryPoints.list()
            opacity:    0.2
            visible:    true//_vehicle.showTrajectory

            Connections {
                target:             _vehicle ? _vehicle.trajectoryPoints : nulll
                onPointAdded:       sensorTrajectory.addCoordinate(coordinate)
                onUpdateLastPoint:  sensorTrajectory.replaceCoordinate(sensorTrajectory.pathLength() - 1, coordinate)
                onPointsCleared:    sensorTrajectory.path = []
            }

            Connections {
                target:                     _vehicle ? _vehicle : null
                onShowTrajectoryChanged:    sensorTrajectory.visible = showTrajectory
                onSensorRangeChanged:       sensorTrajectory.line.width = sensorRange
            }
        }
    }
}
