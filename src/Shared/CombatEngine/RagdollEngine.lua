--[[
    RagdollEngine.lua  —  Step 6
    Physics-based ragdoll for heavy impacts, finishers, explosions,
    wall smashes, and cinematic deaths.

    How it works in Roblox:
      1. Disable all Motor6D joints → character stops animating
      2. Add BallSocketConstraints between limb attachments so the body
         folds realistically under gravity and applied impulse
      3. After recoverTime, re-enable Motor6D joints and remove constraints

    Use on:
      - Steve ult finale (Last Block Standing)
      - Alex Dragonfall Execution
      - Zombie Grave March end slam
      - Skeleton Bonebreaker Shot
      - Enderman Stolen Ground, You Shouldn't Look finale
      - Any HitStunKnockback with IsGroundBounce = true
--]]

local RagdollEngine = {}

-- Joint names that get disabled during ragdoll
local MOTOR_NAMES = {
    "RootJoint",
    "Neck",
    "Left Shoulder",
    "Right Shoulder",
    "Left Hip",
    "Right Hip",
}

-- Constraint config
local SOCKET_LIMITS = {
    UpperAngle = 45,
    TwistLowerAngle = -30,
    TwistUpperAngle = 30,
}

-- Table of active ragdolls: character -> cleanup function
local activeRagdolls = {}

--[[
    Activate(character, config)
    config = {
        Duration       : number   -- seconds before auto-recover (0 = manual)
        BlastDirection : Vector3  -- optional extra impulse on root
        BlastForce     : number   -- magnitude of extra impulse
        OnRecover      : function -- called when ragdoll ends
    }
--]]
function RagdollEngine.Activate(character, config)
    config = config or {}

    -- Prevent double-ragdoll
    if activeRagdolls[character] then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- Disable animator so animations don't fight physics
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then animator.Enabled = false end

    -- Set humanoid to physics-controlled state
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    -- Collect and disable all Motor6Ds
    local disabledMotors = {}
    for _, desc in ipairs(character:GetDescendants()) do
        if desc:IsA("Motor6D") then
            desc.Enabled = false
            table.insert(disabledMotors, desc)
        end
    end

    -- Add BallSocketConstraints between matching part pairs
    local constraints = {}
    local function addSocket(part0, part1, att0Name, att1Name)
        if not (part0 and part1) then return end

        local att0 = part0:FindFirstChild(att0Name)
            or Instance.new("Attachment", part0)
        local att1 = part1:FindFirstChild(att1Name)
            or Instance.new("Attachment", part1)

        att0.Name = att0Name
        att1.Name = att1Name

        local socket = Instance.new("BallSocketConstraint")
        socket.Attachment0 = att0
        socket.Attachment1 = att1
        socket.LimitsEnabled = true
        socket.UpperAngle   = SOCKET_LIMITS.UpperAngle
        socket.TwistLimitsEnabled = true
        socket.TwistLowerAngle   = SOCKET_LIMITS.TwistLowerAngle
        socket.TwistUpperAngle   = SOCKET_LIMITS.TwistUpperAngle
        socket.Parent = part0

        table.insert(constraints, socket)
    end

    local root  = character:FindFirstChild("HumanoidRootPart")
    local torso = character:FindFirstChild("UpperTorso")
              or character:FindFirstChild("Torso")
    local head  = character:FindFirstChild("Head")
    local lArm  = character:FindFirstChild("LeftUpperArm")
              or character:FindFirstChild("Left Arm")
    local rArm  = character:FindFirstChild("RightUpperArm")
              or character:FindFirstChild("Right Arm")
    local lLeg  = character:FindFirstChild("LeftUpperLeg")
              or character:FindFirstChild("Left Leg")
    local rLeg  = character:FindFirstChild("RightUpperLeg")
              or character:FindFirstChild("Right Leg")
    local lLow  = character:FindFirstChild("LeftLowerLeg")
    local rLow  = character:FindFirstChild("RightLowerLeg")
    local lFoot = character:FindFirstChild("LeftFoot")
    local rFoot = character:FindFirstChild("RightFoot")
    local lLowArm = character:FindFirstChild("LeftLowerArm")
    local rLowArm = character:FindFirstChild("RightLowerArm")
    local lHand = character:FindFirstChild("LeftHand")
    local rHand = character:FindFirstChild("RightHand")
    local lTorso = character:FindFirstChild("LowerTorso")

    addSocket(torso,  head,   "RagdollNeckAtt0",  "RagdollNeckAtt1")
    addSocket(torso,  lArm,   "RagdollLShAtt0",   "RagdollLShAtt1")
    addSocket(torso,  rArm,   "RagdollRShAtt0",   "RagdollRShAtt1")
    addSocket(lTorso or torso, lLeg, "RagdollLHipAtt0", "RagdollLHipAtt1")
    addSocket(lTorso or torso, rLeg, "RagdollRHipAtt0", "RagdollRHipAtt1")
    if lArm  and lLowArm  then addSocket(lArm,  lLowArm,  "RagdollLElbAtt0", "RagdollLElbAtt1") end
    if rArm  and rLowArm  then addSocket(rArm,  rLowArm,  "RagdollRElbAtt0", "RagdollRElbAtt1") end
    if lLowArm and lHand  then addSocket(lLowArm, lHand,  "RagdollLWrAtt0",  "RagdollLWrAtt1")  end
    if rLowArm and rHand  then addSocket(rLowArm, rHand,  "RagdollRWrAtt0",  "RagdollRWrAtt1")  end
    if lLeg  and lLow     then addSocket(lLeg,  lLow,     "RagdollLKnAtt0",  "RagdollLKnAtt1")  end
    if rLeg  and rLow     then addSocket(rLeg,  rLow,     "RagdollRKnAtt0",  "RagdollRKnAtt1")  end
    if lLow  and lFoot    then addSocket(lLow,  lFoot,    "RagdollLAnAtt0",  "RagdollLAnAtt1")  end
    if rLow  and rFoot    then addSocket(rLow,  rFoot,    "RagdollRAnAtt0",  "RagdollRAnAtt1")  end

    -- Apply optional blast impulse
    if root and config.BlastDirection and config.BlastForce and config.BlastForce > 0 then
        root.AssemblyLinearVelocity = config.BlastDirection.Unit * config.BlastForce
    end

    -- VFX: ragdoll start (body flops)
    -- VFXRemote handled by caller (e.g. HitStunKnockback already fires its own VFX)

    -- Cleanup / recover function
    local function recover()
        if not activeRagdolls[character] then return end
        activeRagdolls[character] = nil

        -- Remove constraints
        for _, c in ipairs(constraints) do
            if c and c.Parent then c:Destroy() end
        end

        -- Re-enable motors
        for _, motor in ipairs(disabledMotors) do
            if motor and motor.Parent then
                motor.Enabled = true
            end
        end

        -- Re-enable animator
        if animator and animator.Parent then
            animator.Enabled = true
        end

        -- Return humanoid to normal state
        if humanoid and humanoid.Parent then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end

        if config.OnRecover then
            config.OnRecover()
        end
    end

    activeRagdolls[character] = recover

    -- Auto-recover after duration
    local duration = config.Duration or 1.5
    if duration > 0 then
        task.delay(duration, function()
            if activeRagdolls[character] then
                recover()
            end
        end)
    end
end

-- Manually end a ragdoll early (e.g. player respawns or hits death state)
function RagdollEngine.Recover(character)
    local fn = activeRagdolls[character]
    if fn then fn() end
end

function RagdollEngine.IsRagdolled(character)
    return activeRagdolls[character] ~= nil
end

return RagdollEngine
