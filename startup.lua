p = peripheral.wrap("top")
local function screen()
    player = coordinate.getPlayers(25000)
    if player ~= nil then
        for k, v in pairs(player) do
        guy = v.name
        if guy == user then
        return player
    end 
    end

    end

end

local SAFE_DISTANCE = 5
local DRONE_COLLISION_DISTANCE = 8 
local GROUND_HEIGHT = 10
local STEP_DISTANCE = 8
local FOLLOW_DISTANCE = 15
local ARRIVAL_THRESHOLD = 30
local SHIP_DETECTION_RANGE = 2500 

local drones = {} 
local targets = {} 
local followMode = {} 
local ships = {}
local droneShips = {}

function initDrones(n)
    for i = 1, n do
        drones[i] = {
            id = i,
            position = {x = 0, y = 0, z = 0},
            target = {x = 0, y = 0, z = 0},
            arrived = false,
            following = false,
            shipId = nil  -- 存储对应的船体ID
        }
        targets[i] = {x = 0, y = 0, z = 0}
        followMode[i] = false
    end
end

-- 获取无人机当前位置
function updateDronePositions()
    for i = 1, #drones do
        local success, pos = pcall(function()
            return p.callRemote("doro"..i, "getPosition")
        end)
        if success and pos then
            drones[i].position = pos
        end
    end
end

-- 获取船体信息并关联无人机
function updateShips()
    ships = {}
    droneShips = {}
    
    local shipData = coordinate.getShips(SHIP_DETECTION_RANGE)
    if shipData then
        for k, v in pairs(shipData) do
            local shipInfo = {
                id = v.id,
                slug = v.slug,
                position = {x = v.x, y = v.y, z = v.z},
                dimension = v.dimension,
                bounds = {
                    min_x = v.min_x, min_y = v.min_y, min_z = v.min_z,
                    max_x = v.max_x, max_y = v.max_y, max_z = v.max_z
                }
            }
            
            table.insert(ships, shipInfo)
            
            -- 尝试将船体与无人机关联
            for i = 1, #drones do
                local dronePos = drones[i].position
                local dist = calculateDistance(dronePos, shipInfo.position)
                if dist < 1 then
                    drones[i].shipId = shipInfo.id
                    droneShips[i] = shipInfo
                    break
                end
            end
        end
    end
end

function calculateDistance(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = pos1.z - pos2.z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

function isPointInShipBounds(point, ship)
    return point.x >= ship.bounds.min_x and point.x <= ship.bounds.max_x and
           point.y >= ship.bounds.min_y and point.y <= ship.bounds.max_y and
           point.z >= ship.bounds.min_z and point.z <= ship.bounds.max_z
end

function checkShipCollision(position, droneId)

    for dx = -1, 1 do
        for dy = -1, 1 do
            for dz = -1, 1 do
                local checkPos = {
                    x = position.x + dx,
                    y = position.y + dy,
                    z = position.z + dz
                }

                for _, ship in ipairs(ships) do
                    -- 排除自身船体
                    if not (droneShips[droneId] and ship.id == droneShips[droneId].id) then
                        if isPointInShipBounds(checkPos, ship) then
                            return true
                        end
                    end
                end
            end
        end
    end
    
    return false
end

function checkDroneCollision(position, droneId)

    for j = 1, #drones do
        if j ~= droneId then
            local dist = calculateDistance(position, drones[j].position)

            if dist < DRONE_COLLISION_DISTANCE then
                return true
            end

            if dist < DRONE_COLLISION_DISTANCE * 1.5 then
                local toOtherDrone = {
                    x = drones[j].position.x - position.x,
                    y = drones[j].position.y - position.y,
                    z = drones[j].position.z - position.z
                }

                local targetDist = calculateDistance(drones[droneId].target, drones[j].target)
                if targetDist < 10 then
                    return true
                end
            end
        end
    end
    
    return false
end

function isPositionSafe(position, droneId)
    if position.y <= GROUND_HEIGHT then
        return false
    end

    if checkShipCollision(position, droneId) then
        return false
    end

    for dx = -1, 1 do
        for dy = -1, 1 do
            for dz = -1, 1 do
                local checkPos = {
                    x = position.x + dx,
                    y = position.y + dy,
                    z = position.z + dz
                }
                
                local blockName = coordinate.getBlock(checkPos.x, checkPos.y, checkPos.z)
                if blockName and blockName ~= "air" and blockName ~= "minecraft:air" then
                    return false
                end
            end
        end
    end

    if checkDroneCollision(position, droneId) then
        return false
    end
    
    return true
end

function findSafeMove(currentPos, targetPos, droneId)
    local directions = {
        {x = 1, y = 0, z = 0},   {x = -1, y = 0, z = 0},
        {x = 0, y = 1, z = 0},   {x = 0, y = -1, z = 0},
        {x = 0, y = 0, z = 1},   {x = 0, y = 0, z = -1},
        {x = 1, y = 1, z = 0},   {x = 1, y = -1, z = 0},
        {x = -1, y = 1, z = 0},  {x = -1, y = -1, z = 0},
        {x = 1, y = 0, z = 1},   {x = 1, y = 0, z = -1},
        {x = -1, y = 0, z = 1},  {x = -1, y = 0, z = -1},
        {x = 0, y = 1, z = 1},   {x = 0, y = 1, z = -1},
        {x = 0, y = -1, z = 1},  {x = 0, y = -1, z = -1}
    }

    local toTarget = {
        x = targetPos.x - currentPos.x,
        y = targetPos.y - currentPos.y,
        z = targetPos.z - currentPos.z
    }

    local length = math.sqrt(toTarget.x*toTarget.x + toTarget.y*toTarget.y + toTarget.z*toTarget.z)
    if length > 0 then
        toTarget.x = toTarget.x / length
        toTarget.y = toTarget.y / length
        toTarget.z = toTarget.z / length
    end

    table.sort(directions, function(a, b)
        local dotA = a.x * toTarget.x + a.y * toTarget.y + a.z * toTarget.z
        local dotB = b.x * toTarget.x + b.y * toTarget.y + b.z * toTarget.z

        if math.abs(dotA - dotB) > 0.1 then
            return dotA > dotB
        end

        local distA = calculateDistance(
            {x = currentPos.x + a.x, y = currentPos.y + a.y, z = currentPos.z + a.z},
            targetPos
        )
        local distB = calculateDistance(
            {x = currentPos.x + b.x, y = currentPos.y + b.y, z = currentPos.z + b.z},
            targetPos
        )
        return distA < distB
    end)

    for _, dir in ipairs(directions) do
        local newPos = {
            x = currentPos.x + dir.x * STEP_DISTANCE,
            y = currentPos.y + dir.y * STEP_DISTANCE,
            z = currentPos.z + dir.z * STEP_DISTANCE
        }
        
        if isPositionSafe(newPos, droneId) then
            return newPos
        end
    end

    local verticalMoves = {
        {x = 0, y = 2, z = 0}, {x = 0, y = 3, z = 0}, {x = 0, y = -1, z = 0}
    }
    
    for _, move in ipairs(verticalMoves) do
        local newPos = {
            x = currentPos.x + move.x,
            y = currentPos.y + move.y,
            z = currentPos.z + move.z
        }
        
        if isPositionSafe(newPos, droneId) then
            return newPos
        end
    end

    local Directions = {
        {x = 2, y = 0, z = 0}, {x = -2, y = 0, z = 0},
        {x = 0, y = 0, z = 2}, {x = 0, y = 0, z = -2},
        {x = 2, y = 2, z = 0}, {x = 2, y = 0, z = 2},
        {x = -2, y = 2, z = 0}, {x = -2, y = 0, z = 2}
    }
    
    for _, dir in ipairs(Directions) do
        local newPos = {
            x = currentPos.x + dir.x,
            y = currentPos.y + dir.y,
            z = currentPos.z + dir.z
        }
        
        if isPositionSafe(newPos, droneId) then
            return newPos
        end
    end

    return currentPos
end

function calculateFollowPosition(dronePos, targetPos)
    local distance = calculateDistance(dronePos, targetPos)
    
    if math.abs(distance - FOLLOW_DISTANCE) <= 2 then
        return dronePos
    else
        local direction = {
            x = dronePos.x - targetPos.x,
            y = dronePos.y - targetPos.y,
            z = dronePos.z - targetPos.z
        }
        
        local length = math.sqrt(direction.x*direction.x + direction.y*direction.y + direction.z*direction.z)
        if length > 0 then
            direction.x = direction.x / length
            direction.y = direction.y / length
            direction.z = direction.z / length
        else
            direction = {x = 1, y = 0, z = 0}
        end

        local followPos = {
            x = targetPos.x + direction.x * FOLLOW_DISTANCE,
            y = targetPos.y + direction.y * FOLLOW_DISTANCE,
            z = targetPos.z + direction.z * FOLLOW_DISTANCE
        }

        if followPos.y <= GROUND_HEIGHT then
            followPos.y = GROUND_HEIGHT + 1
        end
        
        return followPos
    end
end

function calculateExpectedPosition(droneId, targetX, targetY, targetZ)
    local drone = drones[droneId]
    if not drone then
        return nil
    end

    drone.target = {x = targetX, y = targetY, z = targetZ}
    targets[droneId] = drone.target
    
    -- 检查是否启用跟随模式
    local distanceToTarget = calculateDistance(drone.position, drone.target)
    
    if followMode[droneId] then
        local followPos = calculateFollowPosition(drone.position, drone.target)
        local expectedPos = findSafeMove(drone.position, followPos, droneId)
        return expectedPos
    else
        if distanceToTarget <= ARRIVAL_THRESHOLD then
            followMode[droneId] = true
            drone.following = true
            return drone.position
        end
        
        -- 计算中间目标点（保持距离）
        local direction = {
            x = drone.target.x - drone.position.x,
            y = drone.target.y - drone.position.y,
            z = drone.target.z - drone.position.z
        }
        
        -- 归一化方向向量
        local length = math.sqrt(direction.x*direction.x + direction.y*direction.y + direction.z*direction.z)
        if length > 0 then
            direction.x = direction.x / length
            direction.y = direction.y / length
            direction.z = direction.z / length
        else
            direction = {x = 1, y = 0, z = 0}
        end
        local intermediateTarget = {
            x = drone.target.x - direction.x * ARRIVAL_THRESHOLD,
            y = drone.target.y - direction.y * ARRIVAL_THRESHOLD,
            z = drone.target.z - direction.z * ARRIVAL_THRESHOLD
        }
        
        local expectedPos = findSafeMove(drone.position, intermediateTarget, droneId)
        return expectedPos
    end
end

function setDroneTarget(droneId, x, y, z)
    if drones[droneId] then
        drones[droneId].target = {x = x, y = y, z = z}
        targets[droneId] = {x = x, y = y, z = z}
        followMode[droneId] = false
        drones[droneId].following = false
        return true
    end
    return false
end

function setFollowMode(droneId, enable)
    if drones[droneId] then
        followMode[droneId] = enable
        drones[droneId].following = enable
        return true
    end
    return false
end

function getDronePosition(droneId)
    if drones[droneId] then
        return drones[droneId].position
    end
    return nil
end

function getDroneStatus(droneId)
    if drones[droneId] then
        local drone = drones[droneId]
        local distance = calculateDistance(drone.position, drone.target)
        local status = {
            position = drone.position,
            target = drone.target,
            distanceToTarget = distance,
            following = drone.following,
            mode = drone.following and "follow" or "move",
            shipId = drone.shipId
        }
        return status
    end
    return nil
end


local function distance(a, b)
    return math.sqrt((b.x-a.x)^2 + (b.y-a.y)^2 + (b.z-a.z)^2)
end
function rayCast()
    local player = screen()
    if player ~= nil then
        for k, pos in pairs(player) do
        for i = 1, 256, 1 do
            pos.x = pos.x + pos.viewVector.x
            pos.y = pos.y + pos.viewVector.y
            pos.z = pos.z + pos.viewVector.z
            block = coordinate.getBlock(pos.x,pos.y,pos.z)
            local dis = distance(ship.getWorldspacePosition(),pos)
            local ship1 = coordinate.getShipsAll(256)
            for key, value in pairs(ship1) do
                if ship1 ~= nil and pos.x < value.max_x and pos.x > value.min_x and pos.y < value.max_y and pos.y > value.min_y and pos.z < value.max_z and pos.z > value.min_z and dis > 10 then
                    return { x = pos.x ,y = pos.y ,z = pos.z }
                end   
            end
            if block ~= "minecraft:air" and block ~= "minecraft:cave_air" and block ~= "minecraft:void_air" and block ~= "minecraft:snow" or i == 256 then
                return { x = pos.x ,y = pos.y ,z = pos.z }
            end              
        end
              

        end
    end
end
local function postovector(po,target)
    local dis = distance(po,target)
    local x = (target.x - po.x)/dis
    local y = (target.y - po.y)/dis
    local z = (target.z - po.z)/dis
    return {x = x , y = y , z = z}
end
local function rotateVector(q, v)
    local qx, qy, qz, qw = q.x, q.y, q.z, q.w
    local tx = 2 * (qy*v.z - qz*v.y)
    local ty = 2 * (qz*v.x - qx*v.z)
    local tz = 2 * (qx*v.y - qy*v.x)
    
    return {
        x = v.x + qw*tx + (qy*tz - qz*ty),
        y = v.y + qw*ty + (qz*tx - qx*tz),
        z = v.z + qw*tz + (qx*ty - qy*tx)
    }
end    
    playerst=coordinate.getPlayers(1000)
    for k, v in pairs(playerst) do
        user = v.name
    end
    print(user)
local function ff(bianhao,tagetpos)
    fx = 0
    fy = 0
    fz = 0
    tx = 0
    ty = 0
    tz = 0
    er = 0
    xa = 0
    za = 0
    local vt = {x = 0,y = 0,z = -1}
    q2 = p.callRemote(bianhao,"getQuaternion")
    if q2 then
    qq = p.callRemote(bianhao,"getAngularVelocity")
    local pos = p.callRemote(bianhao,"getPosition")
    speed = p.callRemote(bianhao,"getVelocity")
    local vst = rotateVector(q2, vt)
    w2 = q2.w
    x2 = q2.x
    y2 = q2.y
    z2 = q2.z
    rollb  = (math.atan2(2*(w2*x2+z2*y2),1-2*(x2*x2+z2*z2)))
    sindb  = 2*(w2*z2-y2*x2)
    yewb   = (math.atan2(2*(w2*y2+x2*z2),1-2*(z2*z2+y2*y2)))
    if (math.abs(sindb)>=1) then
        if (sindb>0) then
            pitchb = (math.pi/2)
            else
                pitchb = -(math.pi/2)
        end
    else
            pitchb = math.asin(sindb)
    end
    
    distarget = distance(pos,tagetpos)
    if distarget < 5 then
        poser = postovector(pos,tagetpos)
        t = 0.2
        else
            t =20
        poser = postovector(pos,tagetpos)
    end   
    if ta then
    vk = postovector(pos,ta)
    jd2 = math.acos((vk.x*vst.x+vk.z*vst.z)/(math.sqrt(vk.x^2+vk.z^2)*math.sqrt(vst.x^2+vst.z^2)))
    jd3 = vk.x*vst.z-vst.x*vk.z
    if jd3 > 0 then
    jd3 = 1
    end
    if jd3<0 then
    jd3 = -1
    end
    if jd3 == 0 then
    jd3 = 0
    end
    er = jd2*jd3
    angle = math.asin((pos.y - ta.y)/distance(pos,ta))
    xa = -angle*math.cos(yewb+math.pi/2)
    za = -angle*math.sin(yewb+math.pi/2)    
    end

    fx = (poser.x*t-speed.x)*mass
    fy = (0.7+poser.y*t-speed.y)*mass
    fz = (poser.z*t-speed.z)*mass
    tx = (za-rollb-qq.x*0.5)*mass
    ty = (er*5-qq.y*0.5)*mass
    tz = (xa-pitchb-qq.z*0.5)*mass
    
    p.callRemote(bianhao,"applyInvariantForce",fx,fy,fz)    
    p.callRemote(bianhao,"applyInvariantTorque",tx,ty,tz)    
                
    end

end
mass = 200000
initDrones(20)
while true do
        updateDronePositions()
        updateShips()

            for i = 1, #drones do
                 ta = rayCast()
                 if ta then
                    setDroneTarget(i, ta.x, ta.y, ta.z)
                 end
            local target = targets[i]
            local expectedPos = calculateExpectedPosition(i, target.x, target.y, target.z)
            
            if expectedPos then

                local modeText = followMode[i] and "follow" or "move"
                local distance = calculateDistance(drones[i].position, targets[i])
                print(string.format("doro %d (%s) ex: (%.1f, %.1f, %.1f), ta: %.1f", 
                    i, modeText, expectedPos.x, expectedPos.y, expectedPos.z, distance))
                ff("doro"..i.."",expectedPos)

            end
        end
    sleep(0)
end
