local Teleporter = {}

function Teleporter.teleportToStart(car_index, track_data)
    if physics.allowed() and track_data and track_data.startingPoint then
        physics.setCarPosition(
            car_index,
            track_data.startingPoint.origin:value(),
            track_data.startingPoint.direction * -1
        )
    else
        physics.teleportCarTo(0, ac.SpawnSet.HotlapStart)
    end
end

return Teleporter
