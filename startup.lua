p = peripheral.wrap("front")

local function gdsm(a)
    for yi = 0, -60, -1 do
        block = coordinate.getBlock(a.x,a.y + yi,a.z)
        if block ~= "minecraft:air" and block ~= "minecraft:cave_air" and block ~= "minecraft:void_air" then
            return(yi)
        end
    end              
end
-- 添加低通滤波器结构
local filterState = {}

function initFilter(jointName, alpha)
    filterState[jointName] = {
        value = 0,
        alpha = alpha or 0.3
    }
end

function lowPassFilter(jointName, newValue)
    if not filterState[jointName] then
        initFilter(jointName)
    end
    
    local state = filterState[jointName]
    state.value = state.alpha * newValue + (1 - state.alpha) * state.value
    return state.value
end
local function distance(a, b)
    return math.sqrt((b.x-a.x)^2 + (b.y-a.y)^2 + (b.z-a.z)^2)
end

local function paowux(a,g,s)
    return {jul = a , taijiao = ((-4*g)/(s*s))*a*a + ((4*g)/s)*a}
end
local function xlcf(a,b)
    return a.x*b.x+a.y*b.y+a.z*b.z
end
local function rotateVector(q, v)
    if q and v then
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

end
local function laufen(gc1,gc2,pi,joint,foothand1,gc22,pi2,joint2,foothand2,bigleg,smallleg,foot,lang1,lang2,zx,g,s,tf,rfd,lfd,yfd,rightarm,leftarm,yaobu,rightzero,leftzero,yaozero)--,
    zmzt = 0
    step2 = tf*s*1
    step = 0
    time = 0
    time2 = 0
    zmzt = 0
    move1 = 0
    move2 = 0
    rfd = 1
    lfd = 1
    yfd = 1
    while true do
        local jbjl = s
        vorVector = {x = 1, y = 0 , z = 0}
        if redstone.getAnalogInput("back") > 0 then
            dc = -1
            else
                dc = 1
        end
        local shipQuat = p.callRemote(gc1,"getQuaternion")
        local shipPos2 = p.callRemote(gc1,"getPosition")
        local shipPos = p.callRemote(gc2,"getPosition")
        local xvt = rotateVector(shipQuat,vorVector)
        targetPos = {x = shipPos2.x - xvt.x *0.3 , y = shipPos2.y-lang1-lang2 , z = shipPos2.z - xvt.z *0.3 }
            --commands.execAsync(string.format("particle cosmos:bluethrustedlarge %.1f %.1f %.1f 0.1 0.1 0.1 0.05 10 force @a",shipPos2.x+xvt.x*s, shipPos2.y-lang1-lang2 , shipPos2.z+xvt.z*s))       
        if redstone.getAnalogInput("front") > 0 or redstone.getAnalogInput("back") > 0 or qifei then   
            move1 = 0
        local bujs = step/tf
        if qifei then
            kv = {x = shipPos2.x - xvt.x *2 , y = shipPos2.y-lang1-lang2+6 , z = shipPos2.z - xvt.z *2 }
            else
            kt = paowux(bujs,g,s)
            kv = {x = shipPos.x + (bujs*xvt.x-xvt.x*zx)*dc, y = shipPos.y-lang1-lang2 + kt.taijiao+0.4,z = shipPos.z + (bujs*xvt.z-xvt.z*zx)*dc} 
            --commands.execAsync(string.format("particle cosmos:bluethrustedlarge %.1f %.1f %.1f 0.1 0.1 0.1 0.05 10 force @a",kv.x, kv.y , kv.z))

            if bujs > jbjl and bujs < 2*jbjl then
                kt = paowux(2 * jbjl - bujs,g,jbjl)
                kv = {x = shipPos.x + ((2 * jbjl - bujs)*xvt.x-xvt.x*zx)*dc, y = shipPos.y-lang1-lang2 - kt.taijiao+0.4,z = shipPos.z + ((2 * jbjl - bujs)*xvt.z-xvt.z*zx)*dc}        
            end                     
        end

        targetPos = kv--{x = shipPos2.x-xvt.x*s , y = shipPos2.y-lang1-lang2 , z = shipPos2.z-xvt.z*s }
        --print(targetPos.x,targetPos.y,targetPos.z)
            if bujs > 2 * s then
                step = 0
            end     
        local cj = {x = shipPos.x-targetPos.x,y = shipPos.y-targetPos.y,z = shipPos.z-targetPos.z}
        local dblang = distance(targetPos,shipPos)
        if xlcf(cj,xvt) > 0 then
            bisangle = -math.acos((shipPos.y-targetPos.y)/dblang)       
            else
                bisangle = math.acos((shipPos.y-targetPos.y)/dblang) 
        end
        if dblang < lang1 + lang2 then
        local anglecos = (lang2*lang2 - lang1*lang1 - dblang * dblang)/(-2*lang1*dblang)
        anadd = math.acos(anglecos)
        local anglesin = (dblang*math.sin(anadd))/lang2
        anadd2 = math.asin(anglesin)
        else
            anadd = 0
            anadd2 = 0
        end        
            setTurretPitch(rfd*0.6*math.cos((math.pi/(s*tf))*step),rightarm,rightzero)--摆臂
            setTurretPitch(bisangle+anadd,pi,bigleg)--大腿
            setTurretPitch2(anadd2,joint,smallleg)--小腿
            setTurretPitch3(anadd2/2+0.05,foothand1,foot)--脚踝
        zmzt = 0
        if qifei then
            step = 0
            else
                step = step + 1
        end
        
            else
                if move1 < 2 then
                p.callRemote(pi, "setTargetValue", bigleg)
                p.callRemote(joint, "setTargetValue", smallleg)
                p.callRemote(foothand1, "setTargetValue", foot)
                p.callRemote(rightarm, "setTargetValue", rightzero)
                step = 0                    
                move1 = move1 + 1
                end

        end
        local jbjl = s
        local shipPos = p.callRemote(gc22,"getPosition")
        if redstone.getAnalogInput("front") > 0 or redstone.getAnalogInput("back") > 0 or qifei then
            move2 = 0
        local bujs = step2/tf
        if qifei then
            kv = {x = shipPos2.x - xvt.x *0.3 , y = shipPos2.y-lang1-lang2 , z = shipPos2.z - xvt.z *0.3 }
            else
            kt = paowux(bujs,g,s)
            kv = {x = shipPos.x + (bujs*xvt.x-xvt.x*zx)*dc, y = shipPos.y-lang1-lang2 + kt.taijiao+0.4,z = shipPos.z + (bujs*xvt.z-xvt.z*zx)*dc} 
            
            if bujs > jbjl and bujs < 2*jbjl then
                kt = paowux(2 * jbjl - bujs,g,jbjl)
                kv = {x = shipPos.x + ((2 * jbjl - bujs)*xvt.x-xvt.x*zx)*dc, y = shipPos.y-lang1-lang2 - kt.taijiao+0.4,z = shipPos.z + ((2 * jbjl - bujs)*xvt.z-xvt.z*zx)*dc}
                                
            end                     
        end
        targetPos1 = kv
        
            if bujs > 2 * s then
                step2 = 0
            end     
        local cj = {x = shipPos.x-targetPos1.x,y = shipPos.y-targetPos1.y,z = shipPos.z-targetPos1.z}
        local dblang = distance(targetPos1,shipPos)
        if xlcf(cj,xvt) > 0 then
            bisangle1 = -math.acos((shipPos.y-targetPos1.y)/dblang)       
            else
                bisangle1 = math.acos((shipPos.y-targetPos1.y)/dblang) 
        end
        if dblang < lang1 + lang2 then
        local anglecos = (lang2*lang2 - lang1*lang1 - dblang * dblang)/(-2*lang1*dblang)
        anadd1 = math.acos(anglecos)
        local anglesin = (dblang*math.sin(anadd1))/lang2
        anadd21 = math.asin(anglesin)
        else
            anadd1 = 0
            anadd21 = 0
        end    
            setTurretYaw(yfd*0.4*math.cos((math.pi/(s*tf))*step2),yaobu,yaozero)--腰
            setTurretPitch(lfd*0.6*math.cos((math.pi/(s*tf))*step2),leftarm,leftzero)--摆臂
            setTurretPitch(bisangle1+anadd1,pi2,bigleg) --大腿
            setTurretPitch2(anadd21,joint2,smallleg)--小腿
            setTurretPitch2(anadd21/2+0.05,foothand2,foot)--脚踝
        zmzt = 0
        if qifei then
            step2 = tf*s*1
            else
                step2 = step2 + 1
        end
            else
                if move2 < 2 then
                step2 = tf*s*1
                p.callRemote(pi2, "setTargetValue", bigleg)
                p.callRemote(joint2, "setTargetValue", smallleg)
                p.callRemote(foothand2, "setTargetValue", foot)
                p.callRemote(leftarm, "setTargetValue", leftzero)
                p.callRemote(yaobu, "setControlTarget", yaozero)
  
                move2 = move2 +1
                end

        end

    sleep(0)
    end

end

-- 改进的设置函数
function setTurretYaw(angle, ya, oay)
    local filteredAngle = lowPassFilter(ya, angle)
    p.callRemote(ya, "setControlTarget", filteredAngle+oay)
end

function setTurretPitch(angle, pi, oa)
    local filteredAngle = lowPassFilter(pi, -angle)
    p.callRemote(pi, "setTargetValue", filteredAngle+oa)
end

function setTurretPitch2(angle, pi, oa)
    local filteredAngle = lowPassFilter(pi, angle)
    p.callRemote(pi, "setTargetValue", filteredAngle+oa)
end

function setTurretPitch3(angle, pi , oa)
    local filteredAngle = lowPassFilter(pi, angle)
    p.callRemote(pi, "setTargetValue", filteredAngle+oa) 
end

local function xz(force)
    vorVector = {x = 1, y = 0 , z = 0}
    while true do
    xxb = 0
    yyb = 0
    qifei = false
    yzy = 0
    ltf = 1
    zx = 7
    tk = 0
    bugao = 3
    buchang =14
    angle66 = 0
    wa = 0
    q2 = ship.getQuaternion()
    mass=ship.getMass()
    qq = ship.getOmega()
    a1=ship.getWorldspacePosition()
    local xvt = rotateVector(q2,vorVector)
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
    manq = {x = a1.x + xvt.x *5 , y = a1.y , z = a1.z + xvt.z *5 }
    bsg = gdsm(a1)
    if bsg ==nil or bsg < -16 then
        qifei = true
    end
    if redstone.getAnalogInput("front") > 0 and qifei then
        yzy = mass * 30
    --yyb=-math.cos(yewb-(math.pi/2))*mass*20
    --xxb=-math.sin(yewb-(math.pi/2))*mass*20
    --commands.execAsync("particle cosmos:bluethrustedlarge ~-2.5 ~2 ~2 -0.4 -1 0.4 1 0 force @a")
    --commands.execAsync("particle cosmos:bluethrustedlarge ~-2.5 ~2 ~-3 -0.4 -1 -0.4 1 0 force @a")
    end
    xb=-math.cos(yewb)*angle66
    yb=-math.sin(yewb)*angle66  
        if redstone.getAnalogInput("right") > 0 then
            wa = 1
        end
        if redstone.getAnalogInput("left") > 0 then
            wa = -1
        end
        if redstone.getAnalogInput("bottom") > 0 then
            yzy = mass * 100
            --commands.execAsync("particle cosmos:bluethrustedlarge ~-2.5 ~2 ~2 -0.4 -1 0.4 1 0 force @a")
            --commands.execAsync("particle cosmos:bluethrustedlarge ~-2.5 ~2 ~-3 -0.4 -1 -0.4 1 0 force @a")
        end
        rzx = ((4*yb-4*rollb)-qq.x)*mass*force
        rzy = (wa*4-qq.y)*mass*force
        rzz = ((4*xb-4*pitchb)-qq.z)*mass*force
        ship.applyInvariantTorque(rzx,rzy,rzz) 
        sleep(0)        
        ship.applyInvariantForce(xxb,yzy,yyb)
    end

end
parallel.waitForAll(function () xz(
    400
) end,
function() laufen("kua",                       --胯部频道
"lroot",                                       --左腿根频道
"l1","l4","l6",                                --大腿小腿脚踝频道
"rroot",                                       --右腿根频道
"r1","r4","r6",                                --大腿小腿脚踝频道
0,                                             --大腿角度调零
0,                                             --小腿调零
0,                                             --脚踝调零
6,                                             --大腿长
6,                                             --小腿长
7,                                             --步伐滞后
bugao,                                         --抬腿步高
buchang,                                        --迈步长度
ltf,                                            --频率
1,                                             --胳膊1幅度
1,                                             --胳膊2幅度
0,                                             --腰部幅度
"ar2",                                         --胳膊频道1
"--",                                         --胳膊频道2
"--",                                         --腰子频道
0,                                             --胳膊1调零
0,                                             --胳膊2调零
0                                              --腰部调零

)

    
end
)