--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║           🐍 MEDUSA v13.5 — PREDADOR EDITION 🐍            ║
    ║                  Made by .donatorexe.                       ║
    ║             Xeno Executor Optimized | .lua                  ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  Features:                                                  ║
    ║  • Aimbot (Normal + Silent + Trigger + Prediction)          ║
    ║  • ESP (Highlights + 3D Box + Tracers + Skeleton)           ║
    ║  • Movement (Fly + Noclip + Speed + InfJump + SpinBot)      ║
    ║  • Combat (Hitbox + TriggerBot + Kill Aura)                 ║
    ║  • Target HUD Predador (Modular + Draggable)                ║
    ║  • Feedback (Spectator List + Kill Popup + Hit Sound)       ║
    ║  • RGB Engine (Stroke + Title + Indicator + Glow Pulse)     ║
    ║  • Ghost Mode (Fade on mouse leave)                         ║
    ║  • 8 Premium Themes + Full GUI Editor                       ║
    ║  • 19 Configurable Keybinds                                 ║
    ╚══════════════════════════════════════════════════════════════╝
    
    Loadstring:
      loadstring(game:HttpGet("URL_DO_RAW/Medusa.lua"))()
    
    Hotkeys: T=ESP G=Aimbot F=Fly H=Hitbox U=Noclip
             J=Silent K=Trigger M=Speed N=InfJump
             L=Fullbright C=Crosshair Y=GUI P=Eject
             End=Panic  RMB=Lock Target
--]]

-- ══════════════════════════════════════════════════════════════
--  S1: ANTI-DUPLICATE
-- ══════════════════════════════════════════════════════════════
if getgenv and getgenv().MedusaLoaded then
    pcall(function()
        if getgenv().MedusaEject then getgenv().MedusaEject() end
    end)
    task.wait(0.5)
end
if getgenv then getgenv().MedusaLoaded = true end

-- ══════════════════════════════════════════════════════════════
--  S2: POLYFILLS & XENO COMPATIBILITY
-- ══════════════════════════════════════════════════════════════
if not task or not task.wait then
    task = task or {}
    task.wait = task.wait or wait
    task.spawn = task.spawn or function(f)
        local co = coroutine.create(f); coroutine.resume(co); return co
    end
    task.delay = task.delay or function(t, f)
        local co = coroutine.create(function() wait(t); f() end)
        coroutine.resume(co); return co
    end
    task.cancel = task.cancel or function() end
end

local function getService(name)
    local ok, svc = pcall(function() return game:GetService(name) end)
    return ok and svc or nil
end

local Players = getService("Players")
local UserInputService = getService("UserInputService")
local RunService = getService("RunService")
local TweenService = getService("TweenService")
local Workspace = getService("Workspace")
local CoreGui = getService("CoreGui")
local StarterGui = getService("StarterGui")
local TeleportService = getService("TeleportService")
local HttpService = getService("HttpService")
local VirtualInputManager = getService("VirtualInputManager")
local VirtualUser = getService("VirtualUser")
local Lighting = getService("Lighting")
local SoundService = getService("SoundService")

-- Aliases
local UIS = UserInputService
local TS = TweenService
local RS = RunService

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera
local mouse = player:GetMouse()

-- Xeno capability detection
local XC = {
    hookmetamethod = typeof(hookmetamethod) == "function",
    gethui = typeof(gethui) == "function" or (getgenv and typeof(getgenv().gethui) == "function"),
    protect_gui = typeof(protect_gui) == "function" or (syn and typeof(syn.protect_gui) == "function"),
    cloneref = typeof(cloneref) == "function",
    writefile = typeof(writefile) == "function",
    readfile = typeof(readfile) == "function",
    isfile = typeof(isfile) == "function",
    setclipboard = typeof(setclipboard) == "function" or typeof(toclipboard) == "function",
    mouse1click = typeof(mouse1click) == "function",
    VIM = VirtualInputManager ~= nil,
}

print("[Medusa] Xeno Capabilities:")
for k, v in pairs(XC) do print("  " .. k .. ": " .. tostring(v)) end

-- ══════════════════════════════════════════════════════════════
--  S3: CONFIGURATION
-- ══════════════════════════════════════════════════════════════
local cfg = {
    -- Aimbot
    aimbotFOV = 200, fovMin = 50, fovMax = 500,
    aimSmooth = 20, smoothMin = 0, smoothMax = 100,
    aimbotPart = "Head",
    prediction = false, predStrength = 1.0,
    maxDistance = 1000, distMin = 50, distMax = 2000,
    teamCheck = true, visibleCheck = false,
    healthCheck = false, healthMin = 10,
    -- Trigger Bot
    triggerFOV = 30, triggerDelay = 0.1,
    -- ESP
    espRefreshRate = 30, espDistance = 2000,
    -- Hitbox
    hitboxSize = 10, hitboxMin = 1, hitboxMax = 25,
    hitboxTransparency = 0.7,
    -- Movement
    flySpeed = 150, flyMin = 50, flyMax = 300,
    walkSpeed = 16, speedMin = 16, speedMax = 200,
    spinSpeed = 10,
    -- Crosshair
    crossStyle = 1, crossSize = 12, crossGap = 6,
    -- RGB Engine
    rgb = { stroke = false, title = false, indicator = false, speed = 1, saturation = 1, brightness = 1 },
    -- GUI Editor
    gui = {
        panelW = 420, panelH = 580,
        sidebarW = 48, topbarH = 44,
        fontSize = 12, titleSize = 16,
        cardSpacing = 8, cardPadding = 10,
        borderWidth = 1, cornerRadius = 6,
        toggleW = 36, toggleH = 18,
        sliderH = 14, btnH = 32,
        panelOpacity = 0.05,
    },
}

-- ══════════════════════════════════════════════════════════════
--  S4: STATE MANAGEMENT
-- ══════════════════════════════════════════════════════════════
local st = {
    esp = false, aimbot = false, silentAim = false, triggerBot = false,
    fly = false, noclip = false, speed = false, infJump = false,
    hitbox = false, fullbright = false, noFallDmg = false, clickTP = false,
    spinBot = false, antiAfk = true, crosshair = false,
    box3d = false, tracers = false, skeleton = false,
    ghostMode = false, rainbow = false,
    -- Target HUD modules
    thName = true, thHealth = true, thWeapon = true, thDistance = true, thLockStatus = true,
    -- Feedback modules
    spectatorList = false, killPopup = true, hitSound = true,
    -- System
    guiVisible = true, running = true,
}

local obj = {
    -- Physics
    bv = nil, bg = nil,
    -- Aimbot
    lockedTarget = nil, fovCircle = nil,
    -- ESP
    espObjs = {}, origSizes = {},
    -- Connections
    connections = {},
    -- GUI references
    panel = nil, sidebar = nil, topbar = nil,
    tabFrames = {}, switchTab = nil, currentTab = "status",
    -- Toggle registry for bind sync
    toggleRegistry = {},
    -- RGB elements
    rgbElements = {},
    -- Theme elements
    themeElements = {},
    -- Status
    statusPills = {},
    -- Kill feed
    killFeed = {}, killFeedLabel = nil,
    -- HUD
    wmGui = nil, wmLabel = nil, wmFps = "0", wmPing = "0",
    fpsPingLabel = nil,
    -- Target HUD
    thGui = nil, thFrame = nil,
    -- Feedback
    feedbackGui = nil, specListFrame = nil,
    hitSoundObj = nil, killStreak = 0,
    lastTargetHP = {}, feedbackTarget = nil, feedbackDiedConn = nil,
    -- Players
    playersContainer = nil,
    -- Lighting originals
    origLighting = {},
}

local rmbDown = false
local lastESPRefresh = os.time()

-- Keybinds
local keybinds = {
    esp = Enum.KeyCode.T, aimbot = Enum.KeyCode.G,
    silentAim = Enum.KeyCode.J, triggerBot = Enum.KeyCode.K,
    fly = Enum.KeyCode.F, noclip = Enum.KeyCode.U,
    hitbox = Enum.KeyCode.H, speed = Enum.KeyCode.M,
    infJump = Enum.KeyCode.N, fullbright = Enum.KeyCode.L,
    crosshair = Enum.KeyCode.C, toggleGui = Enum.KeyCode.Y,
    eject = Enum.KeyCode.P, clickTP = Enum.KeyCode.B,
    noFallDmg = Enum.KeyCode.V, spinBot = Enum.KeyCode.X,
    panic = Enum.KeyCode.End,
}
local defaultBinds = {}
for k, v in pairs(keybinds) do defaultBinds[k] = v end

-- Connection manager
local function addConn(conn)
    table.insert(obj.connections, conn)
    return conn
end
local addConnection = addConn

local function cleanConns()
    for _, c in ipairs(obj.connections) do
        pcall(function() c:Disconnect() end)
    end
    obj.connections = {}
end

-- ══════════════════════════════════════════════════════════════
--  S5: COLOR SYSTEM & THEMES
-- ══════════════════════════════════════════════════════════════
local C = {
    accent = Color3.fromRGB(0, 212, 170),
    bg = Color3.fromRGB(15, 15, 20),
    bgCard = Color3.fromRGB(22, 22, 30),
    bgDark = Color3.fromRGB(10, 10, 14),
    sidebar = Color3.fromRGB(12, 12, 16),
    topbar = Color3.fromRGB(12, 12, 16),
    text = Color3.fromRGB(225, 225, 230),
    textMuted = Color3.fromRGB(120, 120, 135),
    success = Color3.fromRGB(34, 197, 94),
    error = Color3.fromRGB(239, 68, 68),
    warning = Color3.fromRGB(245, 158, 11),
    purple = Color3.fromRGB(168, 85, 247),
    blue = Color3.fromRGB(59, 130, 246),
    cyan = Color3.fromRGB(6, 182, 212),
    pink = Color3.fromRGB(236, 72, 153),
    border = Color3.fromRGB(40, 40, 55),
    toggleOff = Color3.fromRGB(55, 55, 65),
    sliderTrack = Color3.fromRGB(35, 35, 45),
    killFeed = Color3.fromRGB(255, 80, 80),
}
-- Aliases
C.card = C.bgCard
C.muted = C.textMuted
C.aimbot = C.purple
C.fly = C.blue

local themes = {
    { name = "Medusa",    accent = Color3.fromRGB(0, 212, 170) },
    { name = "Vaporwave", accent = Color3.fromRGB(168, 85, 247) },
    { name = "Midnight",  accent = Color3.fromRGB(59, 130, 246) },
    { name = "Toxic",     accent = Color3.fromRGB(34, 197, 94) },
    { name = "Blood",     accent = Color3.fromRGB(239, 68, 68) },
    { name = "Gold",      accent = Color3.fromRGB(245, 158, 11) },
    { name = "Frost",     accent = Color3.fromRGB(6, 182, 212) },
    { name = "Inferno",   accent = Color3.fromRGB(255, 100, 50) },
}

local function applyTheme(accent)
    C.accent = accent
    for _, el in ipairs(obj.themeElements) do
        pcall(function()
            if el.obj and el.prop then el.obj[el.prop] = accent end
        end)
    end
end

-- Save/Load config
local function saveConfig()
    if not XC.writefile then return end
    pcall(function()
        local data = { accent = { C.accent.R, C.accent.G, C.accent.B } }
        writefile("MedusaConfig.json", HttpService:JSONEncode(data))
    end)
end
local function loadConfig()
    if not XC.readfile or not XC.isfile then return end
    pcall(function()
        if isfile("MedusaConfig.json") then
            local data = HttpService:JSONDecode(readfile("MedusaConfig.json"))
            if data.accent then
                C.accent = Color3.new(data.accent[1], data.accent[2], data.accent[3])
            end
        end
    end)
end
loadConfig()

-- ══════════════════════════════════════════════════════════════
--  S6: GUI CREATION (SIMPLIFIED — NO STREAMPROOF)
-- ══════════════════════════════════════════════════════════════
local guiParent = playerGui
pcall(function()
    if gethui then
        guiParent = gethui()
    elseif getgenv and getgenv().gethui then
        guiParent = getgenv().gethui()
    elseif XC.cloneref then
        guiParent = cloneref(CoreGui)
    elseif CoreGui then
        local test = Instance.new("Folder")
        test.Parent = CoreGui
        test:Destroy()
        guiParent = CoreGui
    end
end)
print("[Medusa] GUI Parent: " .. tostring(guiParent))

local function createGui(name)
    local sg = Instance.new("ScreenGui")
    sg.Name = name or ("Medusa_" .. math.random(100000, 999999))
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 2147483647
    sg.IgnoreGuiInset = true
    local ok = pcall(function() sg.Parent = guiParent end)
    if not ok then
        pcall(function() sg.Parent = CoreGui end)
        if not sg.Parent then sg.Parent = playerGui end
    end
    pcall(function()
        if protect_gui then protect_gui(sg)
        elseif syn and syn.protect_gui then syn.protect_gui(sg) end
    end)
    return sg
end

-- Stub functions for compatibility
local function spEnable() end
local function spDisable() end

-- ══════════════════════════════════════════════════════════════
--  S7: GUI BUILDER FACTORIES
-- ══════════════════════════════════════════════════════════════
local function mkCorner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or cfg.gui.cornerRadius)
    return c
end

local function mkCard(parent, height, order)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, height)
    c.BackgroundColor3 = C.bgCard
    c.BorderSizePixel = 0
    c.LayoutOrder = order or 0
    c.ClipsDescendants = false
    c.Parent = parent
    mkCorner(c)
    local sk = Instance.new("UIStroke", c)
    sk.Color = C.border
    sk.Thickness = cfg.gui.borderWidth
    sk.Transparency = 0.5
    return c
end

local function mkLabel(parent, text, size, color, x, y, w, h)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(w or 1, w == 1 and -20 or 0, 0, h or 20)
    l.Position = UDim2.new(0, x or 10, 0, y or 8)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = size or cfg.gui.fontSize
    l.TextColor3 = color or C.textMuted
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = text
    l.Parent = parent
    return l
end

local function mkSep(parent, order)
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1, -16, 0, 1)
    s.Position = UDim2.new(0, 8, 0, 0)
    s.BackgroundColor3 = C.border
    s.BackgroundTransparency = 0.5
    s.BorderSizePixel = 0
    s.LayoutOrder = order or 0
    s.Parent = parent
    return s
end

-- mkToggle with visual sync support
local function mkToggle(parent, text, default, order, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order or 0
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -56, 0, 28)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = cfg.gui.fontSize
    lbl.TextColor3 = C.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    lbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, cfg.gui.toggleW, 0, cfg.gui.toggleH)
    track.Position = UDim2.new(1, -(cfg.gui.toggleW + 10), 0.5, -cfg.gui.toggleH / 2)
    track.BackgroundColor3 = default and C.accent or C.toggleOff
    track.BorderSizePixel = 0
    track.Parent = row
    mkCorner(track, cfg.gui.toggleH / 2)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, cfg.gui.toggleH - 4, 0, cfg.gui.toggleH - 4)
    knob.Position = default and UDim2.new(1, -(cfg.gui.toggleH - 2), 0.5, -(cfg.gui.toggleH - 4) / 2) or UDim2.new(0, 2, 0.5, -(cfg.gui.toggleH - 4) / 2)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = track
    mkCorner(knob, (cfg.gui.toggleH - 4) / 2)

    local on = default
    local function setVisual(state)
        on = state
        local posX = state and (1) or (0)
        local offX = state and (-(cfg.gui.toggleH - 2)) or 2
        TS:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Position = UDim2.new(posX, offX, 0.5, -(cfg.gui.toggleH - 4) / 2)
        }):Play()
        TS:Create(track, TweenInfo.new(0.15), {
            BackgroundColor3 = state and C.accent or C.toggleOff
        }):Play()
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        on = not on
        setVisual(on)
        if callback then callback(on) end
    end)

    table.insert(obj.themeElements, { obj = track, prop = "BackgroundColor3", condition = function() return on end })

    return setVisual
end

-- mkSyncToggle: toggle that auto-registers for bind sync
local function mkSyncToggle(parent, text, stateKey, order, extraCallback)
    local setVisual = mkToggle(parent, text, st[stateKey], order, function(on)
        st[stateKey] = on
        if extraCallback then extraCallback(on) end
    end)
    obj.toggleRegistry[stateKey] = { setVisual = setVisual }
    return setVisual
end

-- Sync toggle visual from external source (keybind)
local function syncToggleVisual(key, on)
    local reg = obj.toggleRegistry[key]
    if reg and reg.setVisual then
        pcall(function() reg.setVisual(on) end)
    end
end

-- mkSlider
local function mkSlider(parent, text, initVal, minV, maxV, order, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order or 0
    row.ClipsDescendants = false
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = cfg.gui.fontSize
    lbl.TextColor3 = C.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    lbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 40, 0, 18)
    valLbl.Position = UDim2.new(1, -50, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = cfg.gui.fontSize
    valLbl.TextColor3 = C.accent
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Text = tostring(initVal)
    valLbl.Parent = row
    table.insert(obj.themeElements, { obj = valLbl, prop = "TextColor3" })

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, cfg.gui.sliderH)
    track.Position = UDim2.new(0, 10, 0, 24)
    track.BackgroundColor3 = C.sliderTrack
    track.BorderSizePixel = 0
    track.ClipsDescendants = false
    track.Parent = row
    mkCorner(track, cfg.gui.sliderH / 2)

    local pct = math.clamp((initVal - minV) / (maxV - minV), 0, 1)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    mkCorner(fill, cfg.gui.sliderH / 2)
    table.insert(obj.themeElements, { obj = fill, prop = "BackgroundColor3" })

    local knobSize = cfg.gui.sliderH + 4
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, knobSize, 0, knobSize)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(pct, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 10
    knob.Parent = track
    mkCorner(knob, knobSize / 2)
    local ksk = Instance.new("UIStroke", knob)
    ksk.Color = C.accent
    ksk.Thickness = 2
    table.insert(obj.themeElements, { obj = ksk, prop = "Color" })

    local dragging = false
    local function applyPos(mouseX)
        local bx = track.AbsolutePosition.X
        local bw = track.AbsoluteSize.X
        if bw <= 0 then return end
        local p = math.clamp((mouseX - bx) / bw, 0, 1)
        local val = math.floor(minV + p * (maxV - minV))
        fill.Size = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, 0, 0.5, 0)
        valLbl.Text = tostring(val)
        if callback then callback(val) end
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; applyPos(i.Position.X)
        end
    end)
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    addConn(UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then applyPos(i.Position.X) end
    end))
    addConn(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))

    return lbl, valLbl
end

-- mkBtn
local function mkBtn(parent, text, color, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, cfg.gui.btnH)
    btn.LayoutOrder = order or 0
    btn.BackgroundColor3 = C.bgDark
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = cfg.gui.fontSize
    btn.TextColor3 = color or C.text
    btn.Text = text
    btn.Parent = parent
    mkCorner(btn)
    local sk = Instance.new("UIStroke", btn)
    sk.Color = color or C.accent
    sk.Thickness = 1
    sk.Transparency = 0.5
    btn.MouseEnter:Connect(function()
        TS:Create(sk, TweenInfo.new(0.15), { Transparency = 0.1 }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(sk, TweenInfo.new(0.15), { Transparency = 0.5 }):Play()
    end)
    if callback then btn.MouseButton1Click:Connect(callback) end
    return btn
end

-- mkPartSelector
local function mkPartSelector(parent, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order or 0
    row.Parent = parent

    mkLabel(row, "Hit Part", cfg.gui.fontSize, C.textMuted, 10, 6)

    local parts = { "Head", "Torso", "Random" }
    local btns = {}
    local bw = 65
    for i, nm in ipairs(parts) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, bw, 0, 24)
        b.Position = UDim2.new(1, -(bw * (#parts - i + 1) + 8 * (#parts - i) + 10), 0, 4)
        b.BackgroundColor3 = nm == cfg.aimbotPart and C.accent or C.bgDark
        b.BackgroundTransparency = nm == cfg.aimbotPart and 0.3 or 0.7
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.TextColor3 = nm == cfg.aimbotPart and C.accent or C.textMuted
        b.Text = nm
        b.Parent = row
        mkCorner(b, 6)
        btns[nm] = b
        b.MouseButton1Click:Connect(function()
            cfg.aimbotPart = nm
            for n, bb in pairs(btns) do
                local active = n == nm
                TS:Create(bb, TweenInfo.new(0.15), {
                    BackgroundTransparency = active and 0.3 or 0.7,
                    TextColor3 = active and C.accent or C.textMuted,
                }):Play()
            end
        end)
    end
    return row
end

-- ══════════════════════════════════════════════════════════════
--  S8: NOTIFICATION SYSTEM
-- ══════════════════════════════════════════════════════════════
local notifStack = {}
local MAX_NOTIFS = 5

local function notify(text, color)
    color = color or C.accent
    local sg = createGui("MedusaNotif")
    local fr = Instance.new("Frame")
    fr.Size = UDim2.new(0, 260, 0, 44)
    fr.Position = UDim2.new(0, -280, 1, -60 - (#notifStack * 52))
    fr.BackgroundColor3 = C.bgDark
    fr.BackgroundTransparency = 0.08
    fr.BorderSizePixel = 0
    fr.Parent = sg
    mkCorner(fr, 8)
    local sk = Instance.new("UIStroke", fr)
    sk.Color = color; sk.Thickness = 1.5; sk.Transparency = 0.3

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0.7, 0)
    bar.Position = UDim2.new(0, 6, 0.15, 0)
    bar.BackgroundColor3 = color
    bar.BorderSizePixel = 0
    bar.Parent = fr
    mkCorner(bar, 2)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 1, -6)
    lbl.Position = UDim2.new(0, 16, 0, 3)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Text = text
    lbl.Parent = fr

    local timeLbl = Instance.new("TextLabel")
    timeLbl.Size = UDim2.new(0, 50, 0, 12)
    timeLbl.Position = UDim2.new(1, -56, 0, 4)
    timeLbl.BackgroundTransparency = 1
    timeLbl.Font = Enum.Font.Gotham
    timeLbl.TextSize = 9
    timeLbl.TextColor3 = C.textMuted
    timeLbl.TextXAlignment = Enum.TextXAlignment.Right
    timeLbl.Text = os.date("%H:%M:%S")
    timeLbl.Parent = fr

    table.insert(notifStack, { gui = sg, frame = fr })
    if #notifStack > MAX_NOTIFS then
        local old = table.remove(notifStack, 1)
        pcall(function() old.gui:Destroy() end)
    end

    -- Restack positions
    for i, n in ipairs(notifStack) do
        local targetPos = UDim2.new(0, 16, 1, -60 - ((#notifStack - i) * 52))
        TS:Create(n.frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Position = targetPos }):Play()
    end

    -- Slide in
    fr:TweenPosition(UDim2.new(0, 16, 1, -60 - ((#notifStack - 1) * 0)), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.4, true)

    -- Auto dismiss
    task.delay(3.5, function()
        TS:Create(fr, TweenInfo.new(0.3), { Position = UDim2.new(0, -280, fr.Position.Y.Scale, fr.Position.Y.Offset) }):Play()
        task.wait(0.4)
        for i, n in ipairs(notifStack) do
            if n.gui == sg then table.remove(notifStack, i); break end
        end
        pcall(function() sg:Destroy() end)
    end)
end

-- ══════════════════════════════════════════════════════════════
--  S9: DRAG SYSTEM
-- ══════════════════════════════════════════════════════════════
local function makeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = target.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    addConn(UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            TS:Create(target, TweenInfo.new(0.06), { Position = newPos }):Play()
        end
    end))
end

-- ══════════════════════════════════════════════════════════════
--  S10: MAIN GUI STRUCTURE
-- ══════════════════════════════════════════════════════════════
local screenGui = createGui("MedusaMain")
obj.wmGui = screenGui

-- Shadow
local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(0, cfg.gui.panelW + 12, 0, cfg.gui.panelH + 12)
shadow.Position = UDim2.new(1, -(cfg.gui.panelW + 30), 0.5, -(cfg.gui.panelH / 2) - 6)
shadow.BackgroundColor3 = Color3.new(0, 0, 0)
shadow.BackgroundTransparency = 0.7
shadow.BorderSizePixel = 0
shadow.ZIndex = 0
shadow.Parent = screenGui
mkCorner(shadow, cfg.gui.cornerRadius + 4)

-- Panel
local panel = Instance.new("Frame")
panel.Name = "MedusaPanel"
panel.Size = UDim2.new(0, cfg.gui.panelW, 0, cfg.gui.panelH)
panel.Position = UDim2.new(1, -(cfg.gui.panelW + 24), 0.5, -cfg.gui.panelH / 2)
panel.BackgroundColor3 = C.bg
panel.BackgroundTransparency = cfg.gui.panelOpacity
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.ZIndex = 1
panel.Parent = screenGui
mkCorner(panel, cfg.gui.cornerRadius)
obj.panel = panel

local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color = C.accent
panelStroke.Thickness = 1.5
panelStroke.Transparency = 0.3
table.insert(obj.rgbElements, { obj = panelStroke, prop = "Color", type = "stroke" })
table.insert(obj.themeElements, { obj = panelStroke, prop = "Color" })

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, cfg.gui.sidebarW, 1, 0)
sidebar.BackgroundColor3 = C.sidebar
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 3
sidebar.Parent = panel
obj.sidebar = sidebar

local sidebarLine = Instance.new("Frame")
sidebarLine.Size = UDim2.new(0, 1, 1, 0)
sidebarLine.Position = UDim2.new(1, 0, 0, 0)
sidebarLine.BackgroundColor3 = C.border
sidebarLine.BackgroundTransparency = 0.4
sidebarLine.BorderSizePixel = 0
sidebarLine.ZIndex = 3
sidebarLine.Parent = sidebar

-- Tab indicator
local tabIndicator = Instance.new("Frame")
tabIndicator.Size = UDim2.new(0, 3, 0, 24)
tabIndicator.Position = UDim2.new(0, 0, 0, cfg.gui.topbarH + 10)
tabIndicator.BackgroundColor3 = C.accent
tabIndicator.BorderSizePixel = 0
tabIndicator.ZIndex = 5
tabIndicator.Parent = sidebar
mkCorner(tabIndicator, 2)
table.insert(obj.rgbElements, { obj = tabIndicator, prop = "BackgroundColor3", type = "indicator" })
table.insert(obj.themeElements, { obj = tabIndicator, prop = "BackgroundColor3" })

-- Topbar
local topbar = Instance.new("Frame")
topbar.Size = UDim2.new(1, -cfg.gui.sidebarW, 0, cfg.gui.topbarH)
topbar.Position = UDim2.new(0, cfg.gui.sidebarW, 0, 0)
topbar.BackgroundColor3 = C.topbar
topbar.BorderSizePixel = 0
topbar.ZIndex = 4
topbar.Parent = panel
obj.topbar = topbar

local topbarLine = Instance.new("Frame")
topbarLine.Size = UDim2.new(1, 0, 0, 1)
topbarLine.Position = UDim2.new(0, 0, 1, 0)
topbarLine.BackgroundColor3 = C.border
topbarLine.BackgroundTransparency = 0.4
topbarLine.BorderSizePixel = 0
topbarLine.ZIndex = 4
topbarLine.Parent = topbar

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0, 140, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = cfg.gui.titleSize
titleLbl.TextColor3 = C.accent
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Text = "🐍 MEDUSA"
titleLbl.ZIndex = 5
titleLbl.Parent = topbar
table.insert(obj.rgbElements, { obj = titleLbl, prop = "TextColor3", type = "title" })
table.insert(obj.themeElements, { obj = titleLbl, prop = "TextColor3" })

obj.fpsPingLabel = Instance.new("TextLabel")
obj.fpsPingLabel.Size = UDim2.new(0, 100, 1, 0)
obj.fpsPingLabel.Position = UDim2.new(1, -160, 0, 0)
obj.fpsPingLabel.BackgroundTransparency = 1
obj.fpsPingLabel.Font = Enum.Font.Gotham
obj.fpsPingLabel.TextSize = 10
obj.fpsPingLabel.TextColor3 = C.textMuted
obj.fpsPingLabel.TextXAlignment = Enum.TextXAlignment.Right
obj.fpsPingLabel.Text = "-- FPS | --ms"
obj.fpsPingLabel.ZIndex = 5
obj.fpsPingLabel.Parent = topbar

-- Minimize button
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -64, 0.5, -14)
minBtn.BackgroundTransparency = 1
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 18
minBtn.TextColor3 = C.textMuted
minBtn.Text = "—"
minBtn.ZIndex = 6
minBtn.Parent = topbar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
closeBtn.BackgroundTransparency = 1
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = C.error
closeBtn.Text = "×"
closeBtn.ZIndex = 6
closeBtn.Parent = topbar

-- Make draggable
makeDraggable(topbar, panel)

-- Tab icons
local TABS = {
    { id = "status",   icon = "📊" },
    { id = "aimbot",   icon = "🎯" },
    { id = "visuals",  icon = "👁️" },
    { id = "movement", icon = "🏃" },
    { id = "combat",   icon = "⚔️" },
    { id = "players",  icon = "👥" },
    { id = "misc",     icon = "🔧" },
    { id = "binds",    icon = "🎮" },
    { id = "style",    icon = "🎨" },
    { id = "gui",      icon = "🖥️" },
}

-- Create tab buttons and scroll frames
for i, tab in ipairs(TABS) do
    local tbtn = Instance.new("TextButton")
    tbtn.Size = UDim2.new(1, 0, 0, cfg.gui.sidebarW)
    tbtn.Position = UDim2.new(0, 0, 0, cfg.gui.topbarH + (i - 1) * cfg.gui.sidebarW)
    tbtn.BackgroundTransparency = 1
    tbtn.Font = Enum.Font.Unknown
    tbtn.TextSize = 20
    tbtn.TextColor3 = C.textMuted
    tbtn.Text = tab.icon
    tbtn.ZIndex = 4
    tbtn.Parent = sidebar

    -- Tooltip
    local tooltip = Instance.new("TextLabel")
    tooltip.Size = UDim2.new(0, 70, 0, 22)
    tooltip.Position = UDim2.new(1, 8, 0.5, -11)
    tooltip.BackgroundColor3 = C.bgDark
    tooltip.BackgroundTransparency = 0.1
    tooltip.BorderSizePixel = 0
    tooltip.Font = Enum.Font.GothamMedium
    tooltip.TextSize = 10
    tooltip.TextColor3 = C.text
    tooltip.Text = tab.id:upper()
    tooltip.ZIndex = 20
    tooltip.Visible = false
    tooltip.Parent = tbtn
    mkCorner(tooltip, 4)

    tbtn.MouseEnter:Connect(function()
        tooltip.Visible = true
        TS:Create(tbtn, TweenInfo.new(0.1), { TextColor3 = C.accent }):Play()
    end)
    tbtn.MouseLeave:Connect(function()
        tooltip.Visible = false
        if obj.currentTab ~= tab.id then
            TS:Create(tbtn, TweenInfo.new(0.1), { TextColor3 = C.textMuted }):Play()
        end
    end)

    -- Scroll frame for this tab
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -(cfg.gui.sidebarW + 8), 1, -(cfg.gui.topbarH + 4))
    scroll.Position = UDim2.new(0, cfg.gui.sidebarW + 4, 0, cfg.gui.topbarH + 2)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = C.accent
    scroll.ScrollBarImageTransparency = 0.4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Visible = (i == 1)
    scroll.ZIndex = 2
    scroll.Parent = panel

    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 4)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 8)

    local list = Instance.new("UIListLayout", scroll)
    list.Padding = UDim.new(0, cfg.gui.cardSpacing)
    list.SortOrder = Enum.SortOrder.LayoutOrder

    obj.tabFrames[tab.id] = scroll

    tbtn.MouseButton1Click:Connect(function()
        if obj.switchTab then obj.switchTab(tab.id) end
    end)
end

-- Switch tab function
local function switchTab(id)
    obj.currentTab = id
    for _, tab in ipairs(TABS) do
        local frame = obj.tabFrames[tab.id]
        if frame then frame.Visible = (tab.id == id) end
    end
    -- Move indicator
    for i, tab in ipairs(TABS) do
        if tab.id == id then
            TS:Create(tabIndicator, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
                Position = UDim2.new(0, 0, 0, cfg.gui.topbarH + (i - 1) * cfg.gui.sidebarW + (cfg.gui.sidebarW / 2) - 12)
            }):Play()
            break
        end
    end
end
obj.switchTab = switchTab

-- Minimize
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TS:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, cfg.gui.panelW, 0, cfg.gui.topbarH)
        }):Play()
        TS:Create(shadow, TweenInfo.new(0.3), {
            Size = UDim2.new(0, cfg.gui.panelW + 12, 0, cfg.gui.topbarH + 12)
        }):Play()
    else
        TS:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, cfg.gui.panelW, 0, cfg.gui.panelH)
        }):Play()
        TS:Create(shadow, TweenInfo.new(0.3), {
            Size = UDim2.new(0, cfg.gui.panelW + 12, 0, cfg.gui.panelH + 12)
        }):Play()
    end
end)

-- FPS Counter
task.spawn(function()
    local frames = 0
    addConn(RS.RenderStepped:Connect(function() frames = frames + 1 end))
    while st.running do
        task.wait(0.5)
        obj.wmFps = tostring(frames * 2)
        frames = 0
        -- Ping
        pcall(function()
            local stats = getService("Stats")
            if stats then
                local ping = stats:FindFirstChild("PerformanceStats")
                if ping then
                    local p = ping:FindFirstChild("Ping")
                    if p then obj.wmPing = tostring(math.floor(p:GetValue())) end
                end
            end
        end)
        pcall(function()
            if obj.fpsPingLabel then
                obj.fpsPingLabel.Text = obj.wmFps .. " FPS | " .. obj.wmPing .. "ms"
            end
        end)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  S11: TAB STATUS
-- ══════════════════════════════════════════════════════════════
do
    local tab = obj.tabFrames["status"]
    if tab then
        -- Status pills
        local pillCard = mkCard(tab, 80, 1)
        mkLabel(pillCard, "📊 STATUS", cfg.gui.fontSize, C.textMuted, 10, 6)

        local pillFrame = Instance.new("Frame")
        pillFrame.Size = UDim2.new(1, -16, 0, 44)
        pillFrame.Position = UDim2.new(0, 8, 0, 28)
        pillFrame.BackgroundTransparency = 1
        pillFrame.Parent = pillCard

        local pillGrid = Instance.new("UIGridLayout", pillFrame)
        pillGrid.CellSize = UDim2.new(0.33, -4, 0, 18)
        pillGrid.CellPadding = UDim2.new(0, 4, 0, 4)

        local pillData = {
            { key = "esp",       txt = "👁️ ESP",    col = C.success },
            { key = "aimbot",    txt = "🎯 Aimbot",  col = C.purple },
            { key = "silentAim", txt = "🔇 Silent",  col = C.cyan },
            { key = "fly",       txt = "✈️ Fly",     col = C.blue },
            { key = "noclip",    txt = "👻 Noclip",  col = C.success },
            { key = "triggerBot",txt = "🔫 Trigger", col = C.warning },
        }
        for _, pd in ipairs(pillData) do
            local p = Instance.new("TextLabel")
            p.BackgroundColor3 = C.bgDark
            p.BackgroundTransparency = 0.4
            p.BorderSizePixel = 0
            p.Font = Enum.Font.GothamMedium
            p.TextSize = 10
            p.TextColor3 = C.textMuted
            p.Text = pd.txt .. " OFF"
            p.Parent = pillFrame
            mkCorner(p, 4)
            obj.statusPills[pd.key] = { label = p, color = pd.col }
        end

        -- Lock card
        local lockCard = mkCard(tab, 44, 2)
        local lockLbl = mkLabel(lockCard, "🔓 No Target", cfg.gui.fontSize, C.textMuted, 10, 12)
        obj.statusPills["lock"] = { label = lockLbl }

        -- Kill Feed
        local kfCard = mkCard(tab, 74, 3)
        mkLabel(kfCard, "☠️ KILL FEED", cfg.gui.fontSize, C.textMuted, 10, 6)
        obj.killFeedLabel = mkLabel(kfCard, "No kills yet", 10, C.textMuted, 10, 26, 1, 40)
        obj.killFeedLabel.TextWrapped = true
        obj.killFeedLabel.TextYAlignment = Enum.TextYAlignment.Top

        -- ESP Timer
        local timerCard = mkCard(tab, 36, 4)
        obj.statusPills["espTimer"] = { label = mkLabel(timerCard, "🔄 ESP Refresh: --", 10, C.textMuted, 10, 8) }

        -- Credits
        local credCard = mkCard(tab, 36, 5)
        mkLabel(credCard, "🐍 Medusa v13.5 — Made by .donatorexe.", 10, C.textMuted, 10, 8)
    end
end

-- ══════════════════════════════════════════════════════════════
--  S12: TAB AIMBOT
-- ══════════════════════════════════════════════════════════════
do
    local tab = obj.tabFrames["aimbot"]
    if tab then
        local mainCard = mkCard(tab, 150, 1)
        mkLabel(mainCard, "🎯 AIMBOT ENGINE", cfg.gui.fontSize, C.textMuted, 10, 6)

        local inner = Instance.new("Frame")
        inner.Size = UDim2.new(1, -16, 0, 120)
        inner.Position = UDim2.new(0, 8, 0, 26)
        inner.BackgroundTransparency = 1
        inner.Parent = mainCard
        local il = Instance.new("UIListLayout", inner)
        il.Padding = UDim.new(0, 4)

        mkSyncToggle(inner, "🎯 Aimbot (RMB Lock)", "aimbot", 1, function(on)
            if not on then obj.lockedTarget = nil; rmbDown = false end
            notify(on and "🎯 Aimbot ON" or "❌ Aimbot OFF", on and C.purple or C.error)
        end)
        mkSyncToggle(inner, "🔇 Silent Aim", "silentAim", 2, function(on)
            notify(on and "🔇 Silent Aim ON" or "❌ Silent Aim OFF", on and C.cyan or C.error)
        end)
        mkSyncToggle(inner, "🔫 Trigger Bot", "triggerBot", 3, function(on)
            notify(on and "🔫 Trigger Bot ON" or "❌ Trigger Bot OFF", on and C.warning or C.error)
        end)
        mkSyncToggle(inner, "🔮 Prediction", "prediction", 4, function() end)

        -- Sliders
        local sliderCard = mkCard(tab, 220, 2)
        mkLabel(sliderCard, "⚙️ ADJUSTMENTS", cfg.gui.fontSize, C.textMuted, 10, 6)

        local si = Instance.new("Frame")
        si.Size = UDim2.new(1, -16, 0, 190)
        si.Position = UDim2.new(0, 8, 0, 26)
        si.BackgroundTransparency = 1
        si.Parent = sliderCard
        local sil = Instance.new("UIListLayout", si)
        sil.Padding = UDim.new(0, 4)

        mkSlider(si, "📏 FOV Radius", cfg.aimbotFOV, cfg.fovMin, cfg.fovMax, 1, function(v) cfg.aimbotFOV = v end)
        mkSlider(si, "🎚️ Smooth", cfg.aimSmooth, cfg.smoothMin, cfg.smoothMax, 2, function(v) cfg.aimSmooth = v end)
        mkSlider(si, "📐 Max Distance", cfg.maxDistance, cfg.distMin, cfg.distMax, 3, function(v) cfg.maxDistance = v end)
        mkSlider(si, "⏱️ Trigger Delay", math.floor(cfg.triggerDelay * 100), 1, 100, 4, function(v) cfg.triggerDelay = v / 100 end)

        -- Hit Part
        local partCard = mkCard(tab, 42, 3)
        mkPartSelector(partCard, 1)

        -- Checks
        local checkCard = mkCard(tab, 140, 4)
        mkLabel(checkCard, "✅ CHECKS", cfg.gui.fontSize, C.textMuted, 10, 6)

        local ci = Instance.new("Frame")
        ci.Size = UDim2.new(1, -16, 0, 110)
        ci.Position = UDim2.new(0, 8, 0, 26)
        ci.BackgroundTransparency = 1
        ci.Parent = checkCard
        local cil = Instance.new("UIListLayout", ci)
        cil.Padding = UDim.new(0, 4)

        mkSyncToggle(ci, "👥 Team Check", "teamCheck", 1, function() end)
        mkSyncToggle(ci, "👁️ Visible Check", "visibleCheck", 2, function() end)
        mkSyncToggle(ci, "❤️ Health Check", "healthCheck", 3, function() end)
        mkSlider(ci, "💚 Min HP %", cfg.healthMin, 1, 100, 4, function(v) cfg.healthMin = v end)
    end
end

-- ══════════════════════════════════════════════════════════════
--  S13: TAB VISUALS
-- ══════════════════════════════════════════════════════════════
do
    local tab = obj.tabFrames["visuals"]
    if tab then
        local espCard = mkCard(tab, 180, 1)
        mkLabel(espCard, "👁️ ESP SYSTEM", cfg.gui.fontSize, C.textMuted, 10, 6)

        local ei = Instance.new("Frame")
        ei.Size = UDim2.new(1, -16, 0, 150)
        ei.Position = UDim2.new(0, 8, 0, 26)
        ei.BackgroundTransparency = 1
        ei.Parent = espCard
        local eil = Instance.new("UIListLayout", ei)
        eil.Padding = UDim.new(0, 4)

        mkSyncToggle(ei, "👁️ ESP Highlights", "esp", 1, function(on)
            if not on then pcall(function() clearESP() end) end
            notify(on and "👁️ ESP ON" or "❌ ESP OFF", on and C.success or C.error)
        end)
        mkSyncToggle(ei, "📦 3D Boxes", "box3d", 2, function() end)
        mkSyncToggle(ei, "📐 Tracers", "tracers", 3, function() end)
        mkSyncToggle(ei, "🦴 Skeleton", "skeleton", 4, function() end)
        mkSlider(ei, "📏 ESP Distance", cfg.espDistance, 50, 5000, 5, function(v) cfg.espDistance = v end)

        -- World
        local worldCard = mkCard(tab, 110, 2)
        mkLabel(worldCard, "🌍 WORLD", cfg.gui.fontSize, C.textMuted, 10, 6)

        local wi = Instance.new("Frame")
        wi.Size = UDim2.new(1, -16, 0, 80)
        wi.Position = UDim2.new(0, 8, 0, 26)
        wi.BackgroundTransparency = 1
        wi.Parent = worldCard
        local wil = Instance.new("UIListLayout", wi)
        wil.Padding = UDim.new(0, 4)

        mkSyncToggle(wi, "💡 Fullbright", "fullbright", 1, function(on)
            pcall(function() setFullbright(on) end)
            notify(on and "💡 Fullbright ON" or "❌ Fullbright OFF", on and C.warning or C.error)
        end)
        mkSyncToggle(wi, "➕ Crosshair", "crosshair", 2, function(on)
            notify(on and "➕ Crosshair ON" or "❌ Crosshair OFF", on and C.accent or C.error)
        end)
        mkSyncToggle(wi, "🌈 Rainbow Mode", "rainbow", 3, function() end)
    end
end

-- ══════════════════════════════════════════════════════════════
--  S14: TAB MOVEMENT
-- ══════════════════════════════════════════════════════════════
do
    local tab = obj.tabFrames["movement"]
    if tab then
        local moveCard = mkCard(tab, 220, 1)
        mkLabel(moveCard, "🏃 MOVEMENT", cfg.gui.fontSize, C.textMuted, 10, 6)

        local mi = Instance.new("Frame")
        mi.Size = UDim2.new(1, -16, 0, 190)
        mi.Position = UDim2.new(0, 8, 0, 26)
        mi.BackgroundTransparency = 1
        mi.Parent = moveCard
        local mil = Instance.new("UIListLayout", mi)
        mil.Padding = UDim.new(0, 4)

        mkSyncToggle(mi, "✈️ Fly", "fly", 1, function(on)
            if on then pcall(function() enableFly() end) else pcall(function() disableFly() end) end
            notify(on and "✈️ Fly ON" or "❌ Fly OFF", on and C.blue or C.error)
        end)
        mkSyncToggle(mi, "👻 Noclip", "noclip", 2, function(on)
            if not on then
                pcall(function()
                    local char = player.Character
                    if char then
                        for _, p in ipairs(char:GetDescendants()) do
                            if p:IsA("BasePart") then p.CanCollide = true end
                        end
                    end
                end)
            end
            notify(on and "👻 Noclip ON" or "❌ Noclip OFF", on and C.success or C.error)
        end)
        mkSyncToggle(mi, "🏃 Speed Hack", "speed", 3, function(on)
            if not on then
                pcall(function()
                    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
                    if hum then hum.WalkSpeed = 16 end
                end)
            end
            notify(on and "🏃 Speed ON" or "❌ Speed OFF", on and C.accent or C.error)
        end)
        mkSyncToggle(mi, "🦘 Infinite Jump", "infJump", 4, function(on)
            notify(on and "🦘 InfJump ON" or "❌ InfJump OFF", on and C.accent or C.error)
        end)
        mkSyncToggle(mi, "🪂 No Fall Damage", "noFallDmg", 5, function(on)
            notify(on and "🪂 No Fall Dmg ON" or "❌ No Fall Dmg OFF", on and C.accent or C.error)
        end)
        mkSyncToggle(mi, "🖱️ Click TP (Hold " .. keybinds.clickTP.Name .. ")", "clickTP", 6, function(on)
            notify(on and "🖱️ Click TP ON" or "❌ Click TP OFF", on and C.accent or C.error)
        end)

        -- Sliders
        mkSlider(mi, "✈️ Fly Speed", cfg.flySpeed, cfg.flyMin, cfg.flyMax, 7, function(v) cfg.flySpeed = v end)
        mkSlider(mi, "🏃 Walk Speed", cfg.walkSpeed, cfg.speedMin, cfg.speedMax, 8, function(v) cfg.walkSpeed = v end)

        -- SpinBot
        local spinCard = mkCard(tab, 70, 2)
        mkLabel(spinCard, "🌀 SPINBOT", cfg.gui.fontSize, C.textMuted, 10, 6)
        local si = Instance.new("Frame")
        si.Size = UDim2.new(1, -16, 0, 40)
        si.Position = UDim2.new(0, 8, 0, 26)
        si.BackgroundTransparency = 1
        si.Parent = spinCard
        local sil = Instance.new("UIListLayout", si)
        sil.Padding = UDim.new(0, 4)
        mkSyncToggle(si, "🌀 SpinBot", "spinBot", 1, function(on)
            notify(on and "🌀 SpinBot ON" or "❌ SpinBot OFF", on and C.pink or C.error)
        end)
    end
end

-- ══════════════════════════════════════════════════════════════
--  S15: TAB COMBAT
-- ══════════════════════════════════════════════════════════════
do
    local tab = obj.tabFrames["combat"]
    if tab then
        local hitCard = mkCard(tab, 130, 1)
        mkLabel(hitCard, "📦 HITBOX EXPANDER", cfg.gui.fontSize, C.textMuted, 10, 6)

        local hi = Instance.new("Frame")
        hi.Size = UDim2.new(1, -16, 0, 100)
        hi.Position = UDim2.new(0, 8, 0, 26)
        hi.BackgroundTransparency = 1
        hi.Parent = hitCard
        local hil = Instance.new("UIListLayout", hi)
        hil.Padding = UDim.new(0, 4)

        mkSyncToggle(hi, "📦 Hitbox Expander", "hitbox", 1, function(on)
            if not on then pcall(function() resetAllHitboxes() end) end
            notify(on and "📦 Hitbox ON" or "❌ Hitbox OFF", on and C.warning or C.error)
        end)
        mkSlider(hi, "📏 Size Multiplier", cfg.hitboxSize, cfg.hitboxMin, cfg.hitboxMax, 2, function(v) cfg.hitboxSize = v end)
        mkSlider(hi, "👁️ Transparency", math.floor(cfg.hitboxTransparency * 100), 0, 100, 3, function(v) cfg.hitboxTransparency = v / 100 end)

        -- Feedback Module
        local fbCard = mkCard(tab, 130, 2)
        mkLabel(fbCard, "💥 FEEDBACK MODULE", cfg.gui.fontSize, C.textMuted, 10, 6)

        local fi = Instance.new("Frame")
        fi.Size = UDim2.new(1, -16, 0, 100)
        fi.Position = UDim2.new(0, 8, 0, 26)
        fi.BackgroundTransparency = 1
        fi.Parent = fbCard
        local fil = Instance.new("UIListLayout", fi)
        fil.Padding = UDim.new(0, 4)

        mkSyncToggle(fi, "👁️ Spectator List", "spectatorList", 1, function(on)
            notify(on and "👁️ Spectator List ON" or "❌ Spectator List OFF", on and C.accent or C.error)
        end)
        mkSyncToggle(fi, "💀 Kill Pop-up", "killPopup", 2, function() end)
        mkSyncToggle(fi, "🔊 Hit Sound", "hitSound", 3, function() end)

        -- Target HUD modules
        local thCard = mkCard(tab, 190, 3)
        mkLabel(thCard, "🎯 TARGET HUD MODULES", cfg.gui.fontSize, C.textMuted, 10, 6)

        local ti = Instance.new("Frame")
        ti.Size = UDim2.new(1, -16, 0, 160)
        ti.Position = UDim2.new(0, 8, 0, 26)
        ti.BackgroundTransparency = 1
        ti.Parent = thCard
        local til = Instance.new("UIListLayout", ti)
        til.Padding = UDim.new(0, 4)

        mkSyncToggle(ti, "🎯 Show Name", "thName", 1, function() end)
        mkSyncToggle(ti, "🩸 Show Health Bar", "thHealth", 2, function() end)
        mkSyncToggle(ti, "🔫 Show Weapon", "thWeapon", 3, function() end)
        mkSyncToggle(ti, "📏 Show Distance", "thDistance", 4, function() end)
        mkSyncToggle(ti, "🔒 Show Lock Status", "thLockStatus", 5, function() end)
    end
end

-- ══════════════════════════════════════════════════════════════
--  S16: TAB PLAYERS
-- ══════════════════════════════════════════════════════════════
do
    local tab = obj.tabFrames["players"]
    if tab then
        local card = mkCard(tab, 36, 1)
        mkLabel(card, "👥 PLAYER LIST", cfg.gui.fontSize, C.textMuted, 10, 8)

        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 0, 0)
        container.AutomaticSize = Enum.AutomaticSize.Y
        container.BackgroundTransparency = 1
        container.LayoutOrder = 2
        container.Parent = tab
        local cl = Instance.new("UIListLayout", container)
        cl.Padding = UDim.new(0, 4)
        obj.playersContainer = container
    end
end

-- ══════════════════════════════════════════════════════════════
--  S17: TAB MISC
-- ══════════════════════════════════════════════════════════════
do
    local tab = obj.tabFrames["misc"]
    if tab then
        local miscCard = mkCard(tab, 70, 1)
        mkLabel(miscCard, "🛡️ UTILITIES", cfg.gui.fontSize, C.textMuted, 10, 6)

        local mi = Instance.new("Frame")
        mi.Size = UDim2.new(1, -16, 0, 40)
        mi.Position = UDim2.new(0, 8, 0, 26)
        mi.BackgroundTransparency = 1
        mi.Parent = miscCard
        local mil = Instance.new("UIListLayout", mi)
        mil.Padding = UDim.new(0, 4)

        mkSyncToggle(mi, "🛡️ Anti-AFK", "antiAfk", 1, function() end)

        -- Actions
        local actCard = mkCard(tab, 240, 2)
        mkLabel(actCard, "🔧 ACTIONS", cfg.gui.fontSize, C.textMuted, 10, 6)

        local ai = Instance.new("Frame")
        ai.Size = UDim2.new(1, -16, 0, 210)
        ai.Position = UDim2.new(0, 8, 0, 26)
        ai.BackgroundTransparency = 1
        ai.Parent = actCard
        local ail = Instance.new("UIListLayout", ai)
        ail.Padding = UDim.new(0, 4)

        mkBtn(ai, "🔄 Refresh ESP", C.accent, 1, function()
            pcall(function() clearESP() end)
            lastESPRefresh = os.time()
            notify("🔄 ESP Refreshed", C.accent)
        end)
        mkBtn(ai, "🔄 Refresh Players", C.accent, 2, function()
            pcall(function() refreshPlayers() end)
            notify("🔄 Players Refreshed", C.accent)
        end)
        mkBtn(ai, "📷 Unspectate", C.blue, 3, function()
            pcall(function()
                camera.CameraSubject = player.Character and player.Character:FindFirstChild("Humanoid")
            end)
            notify("📷 Unspectated", C.blue)
        end)
        mkBtn(ai, "🔁 Rejoin", C.warning, 4, function()
            notify("🔁 Rejoining...", C.warning)
            task.delay(1, function()
                pcall(function() TeleportService:Teleport(game.PlaceId) end)
            end)
        end)
        mkBtn(ai, "🌐 Server Hop", C.cyan, 5, function()
            notify("🌐 Finding server...", C.cyan)
            task.spawn(function()
                pcall(function()
                    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=10"
                    local data = HttpService:JSONDecode(game:HttpGet(url))
                    for _, sv in ipairs(data.data or {}) do
                        if sv.playing and sv.playing < sv.maxPlayers and sv.id ~= game.JobId then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id)
                            return
                        end
                    end
                    notify("❌ No servers found", C.error)
                end)
            end)
        end)

        -- Danger Zone
        local dangerCard = mkCard(tab, 90, 3)
        dangerCard.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
        mkLabel(dangerCard, "🚨 DANGER ZONE", cfg.gui.fontSize, C.error, 10, 6)

        local di = Instance.new("Frame")
        di.Size = UDim2.new(1, -16, 0, 60)
        di.Position = UDim2.new(0, 8, 0, 26)
        di.BackgroundTransparency = 1
        di.Parent = dangerCard
        local dil = Instance.new("UIListLayout", di)
        dil.Padding = UDim.new(0, 4)

        mkBtn(di, "🚨 PANIC (End)", C.error, 1, function()
            notify("🚨 PANIC!", C.error)
            task.delay(0.5, function() pcall(function() doPanic() end) end)
        end)
        mkBtn(di, "🗑️ EJECT (P)", C.error, 2, function()
            notify("🗑️ Ejecting...", C.error)
            task.delay(0.5, function() pcall(function() doEject() end) end)
        end)
    end
end

-- ══════════════════════════════════════════════════════════════
--  S18: TAB BINDS
-- ══════════════════════════════════════════════════════════════
do
    local tab = obj.tabFrames["binds"]
    if tab then
        local bindCard = mkCard(tab, 36, 1)
        mkLabel(bindCard, "🎮 KEYBINDS", cfg.gui.fontSize, C.textMuted, 10, 8)

        local bindOrder = { "esp", "aimbot", "silentAim", "triggerBot", "fly", "noclip", "hitbox", "speed", "infJump", "fullbright", "crosshair", "clickTP", "noFallDmg", "spinBot", "toggleGui", "eject", "panic" }

        for i, key in ipairs(bindOrder) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 30)
            row.BackgroundTransparency = 1
            row.LayoutOrder = i + 1
            row.Parent = tab

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.6, 0, 1, 0)
            lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamMedium
            lbl.TextSize = cfg.gui.fontSize
            lbl.TextColor3 = C.text
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Text = key
            lbl.Parent = row

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 80, 0, 24)
            btn.Position = UDim2.new(1, -90, 0.5, -12)
            btn.BackgroundColor3 = C.bgDark
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 11
            btn.TextColor3 = C.accent
            btn.Text = keybinds[key] and keybinds[key].Name or "?"
            btn.Parent = row
            mkCorner(btn, 4)
            local bsk = Instance.new("UIStroke", btn)
            bsk.Color = C.border; bsk.Thickness = 1

            local listening = false
            btn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                btn.Text = "..."
                btn.TextColor3 = C.warning
                local conn
                conn = UIS.InputBegan:Connect(function(inp, gp)
                    if gp then return end
                    if inp.KeyCode ~= Enum.KeyCode.Unknown then
                        keybinds[key] = inp.KeyCode
                        btn.Text = inp.KeyCode.Name
                        btn.TextColor3 = C.accent
                        listening = false
                        conn:Disconnect()
                    end
                end)
            end)
        end

        -- Reset button
        mkBtn(tab, "🔄 Reset All Binds", C.warning, 100, function()
            for k, v in pairs(defaultBinds) do keybinds[k] = v end
            notify("🔄 Binds reset!", C.warning)
            -- Refresh tab
            if obj.switchTab then obj.switchTab("binds") end
        end)
    end
end

-- ══════════════════════════════════════════════════════════════
--  S19: TAB STYLE
-- ══════════════════════════════════════════════════════════════
do
    local tab = obj.tabFrames["style"]
    if tab then
        -- Themes
        local themeCard = mkCard(tab, 90, 1)
        mkLabel(themeCard, "🎨 THEMES", cfg.gui.fontSize, C.textMuted, 10, 6)

        local tRow = Instance.new("Frame")
        tRow.Size = UDim2.new(1, -16, 0, 50)
        tRow.Position = UDim2.new(0, 8, 0, 28)
        tRow.BackgroundTransparency = 1
        tRow.Parent = themeCard

        local tGrid = Instance.new("UIGridLayout", tRow)
        tGrid.CellSize = UDim2.new(0, 40, 0, 40)
        tGrid.CellPadding = UDim2.new(0, 6, 0, 6)

        for i, th in ipairs(themes) do
            local tb = Instance.new("TextButton")
            tb.Size = UDim2.new(0, 40, 0, 40)
            tb.LayoutOrder = i
            tb.BackgroundColor3 = th.accent
            tb.BackgroundTransparency = 0.3
            tb.BorderSizePixel = 0
            tb.AutoButtonColor = false
            tb.Text = ""
            tb.Parent = tRow
            mkCorner(tb, 8)

            local tl = Instance.new("TextLabel")
            tl.Size = UDim2.new(1, 0, 0, 12)
            tl.Position = UDim2.new(0, 0, 1, -14)
            tl.BackgroundTransparency = 1
            tl.Font = Enum.Font.Gotham
            tl.TextSize = 8
            tl.TextColor3 = Color3.new(1, 1, 1)
            tl.Text = th.name
            tl.Parent = tb

            tb.MouseButton1Click:Connect(function()
                applyTheme(th.accent)
                notify("🎨 " .. th.name, th.accent)
            end)
        end

        -- RGB Engine
        local rgbCard = mkCard(tab, 150, 2)
        mkLabel(rgbCard, "🌈 RGB ENGINE", cfg.gui.fontSize, C.textMuted, 10, 6)

        local ri = Instance.new("Frame")
        ri.Size = UDim2.new(1, -16, 0, 120)
        ri.Position = UDim2.new(0, 8, 0, 26)
        ri.BackgroundTransparency = 1
        ri.Parent = rgbCard
        local ril = Instance.new("UIListLayout", ri)
        ril.Padding = UDim.new(0, 4)

        mkToggle(ri, "🌈 RGB Stroke", cfg.rgb.stroke, 1, function(on) cfg.rgb.stroke = on end)
        mkToggle(ri, "📝 RGB Title", cfg.rgb.title, 2, function(on) cfg.rgb.title = on end)
        mkToggle(ri, "📍 RGB Indicator", cfg.rgb.indicator, 3, function(on) cfg.rgb.indicator = on end)
        mkSlider(ri, "⚡ Speed", math.floor(cfg.rgb.speed * 100), 10, 300, 4, function(v) cfg.rgb.speed = v / 100 end)

        -- Panel
        local panelCard = mkCard(tab, 60, 3)
        mkLabel(panelCard, "🖥️ PANEL", cfg.gui.fontSize, C.textMuted, 10, 6)
        local pi = Instance.new("Frame")
        pi.Size = UDim2.new(1, -16, 0, 30)
        pi.Position = UDim2.new(0, 8, 0, 26)
        pi.BackgroundTransparency = 1
        pi.Parent = panelCard
        mkSlider(pi, "🔍 Opacity", math.floor(cfg.gui.panelOpacity * 100), 0, 90, 1, function(v)
            cfg.gui.panelOpacity = v / 100
            panel.BackgroundTransparency = v / 100
        end)

        -- Save/Load
        mkBtn(tab, "💾 Save Config", C.accent, 10, function()
            saveConfig()
            notify("💾 Config Saved!", C.success)
        end)
    end
end

-- ══════════════════════════════════════════════════════════════
--  S20: TAB GUI EDITOR
-- ══════════════════════════════════════════════════════════════
do
    local tab = obj.tabFrames["gui"]
    if tab then
        local sizeCard = mkCard(tab, 130, 1)
        mkLabel(sizeCard, "📐 DIMENSIONS", cfg.gui.fontSize, C.textMuted, 10, 6)

        local si = Instance.new("Frame")
        si.Size = UDim2.new(1, -16, 0, 100)
        si.Position = UDim2.new(0, 8, 0, 26)
        si.BackgroundTransparency = 1
        si.Parent = sizeCard
        local sil = Instance.new("UIListLayout", si)
        sil.Padding = UDim.new(0, 4)

        mkSlider(si, "↔️ Panel Width", cfg.gui.panelW, 340, 600, 1, function(v)
            cfg.gui.panelW = v
            panel.Size = UDim2.new(0, v, 0, cfg.gui.panelH)
            shadow.Size = UDim2.new(0, v + 12, 0, cfg.gui.panelH + 12)
        end)
        mkSlider(si, "↕️ Panel Height", cfg.gui.panelH, 400, 900, 2, function(v)
            cfg.gui.panelH = v
            panel.Size = UDim2.new(0, cfg.gui.panelW, 0, v)
            shadow.Size = UDim2.new(0, cfg.gui.panelW + 12, 0, v + 12)
        end)

        -- Typography
        local typoCard = mkCard(tab, 80, 2)
        mkLabel(typoCard, "📝 TYPOGRAPHY", cfg.gui.fontSize, C.textMuted, 10, 6)
        local ti = Instance.new("Frame")
        ti.Size = UDim2.new(1, -16, 0, 50)
        ti.Position = UDim2.new(0, 8, 0, 26)
        ti.BackgroundTransparency = 1
        ti.Parent = typoCard
        local til = Instance.new("UIListLayout", ti)
        til.Padding = UDim.new(0, 4)

        mkSlider(ti, "🔤 Corner Radius", cfg.gui.cornerRadius, 0, 20, 1, function(v) cfg.gui.cornerRadius = v end)

        -- Reset
        mkBtn(tab, "🔄 Reset GUI to Default", C.warning, 10, function()
            cfg.gui = {
                panelW = 420, panelH = 580, sidebarW = 48, topbarH = 44,
                fontSize = 12, titleSize = 16, cardSpacing = 8, cardPadding = 10,
                borderWidth = 1, cornerRadius = 6, toggleW = 36, toggleH = 18,
                sliderH = 14, btnH = 32, panelOpacity = 0.05,
            }
            panel.Size = UDim2.new(0, 420, 0, 580)
            panel.BackgroundTransparency = 0.05
            notify("🔄 GUI Reset!", C.warning)
        end)
    end
end

-- ══════════════════════════════════════════════════════════════
--  S21: AIMBOT ENGINE
-- ══════════════════════════════════════════════════════════════
local function isValidTarget(plr)
    if not plr or plr == player or not plr.Character then return false end
    local char = plr.Character
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    -- Team check
    if cfg.teamCheck and plr.Team and player.Team and plr.Team == player.Team then return false end
    -- Health check
    if cfg.healthCheck and hum.MaxHealth > 0 then
        local pct = (hum.Health / hum.MaxHealth) * 100
        if pct < cfg.healthMin then return false end
    end
    -- Distance check
    local head = char:FindFirstChild("Head")
    if head then
        local dist = (head.Position - camera.CFrame.Position).Magnitude
        if dist > cfg.maxDistance then return false end
    end
    -- Visible check
    if cfg.visibleCheck and head then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { player.Character, camera }
        local result = Workspace:Raycast(camera.CFrame.Position, (head.Position - camera.CFrame.Position), params)
        if result and not result.Instance:IsDescendantOf(char) then return false end
    end
    return true
end

local function getAimPart(char)
    if not char then return nil end
    if cfg.aimbotPart == "Head" then
        return char:FindFirstChild("Head")
    elseif cfg.aimbotPart == "Torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    elseif cfg.aimbotPart == "Random" then
        local parts = {}
        for _, nm in ipairs({ "Head", "UpperTorso", "Torso", "HumanoidRootPart" }) do
            local p = char:FindFirstChild(nm)
            if p then table.insert(parts, p) end
        end
        return #parts > 0 and parts[math.random(#parts)] or char:FindFirstChild("Head")
    end
    return char:FindFirstChild("Head")
end

local function predictPosition(part, char)
    if not cfg.prediction or not part then return part.Position end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return part.Position end
    local vel = hrp.AssemblyLinearVelocity or hrp.Velocity or Vector3.zero
    local dist = (part.Position - camera.CFrame.Position).Magnitude
    local predTime = dist / 1000 * cfg.predStrength
    return part.Position + vel * predTime
end

local function closestInFOV()
    local mp = UIS:GetMouseLocation()
    local best, bestD = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if isValidTarget(plr) then
            local part = getAimPart(plr.Character)
            if part then
                local sp, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
                    if d < cfg.aimbotFOV and d < bestD then
                        best = plr; bestD = d
                    end
                end
            end
        end
    end
    return best
end

-- Aimbot render loop
addConn(RS.RenderStepped:Connect(function()
    if not st.running then return end

    if st.aimbot and rmbDown then
        if obj.lockedTarget then
            if not isValidTarget(obj.lockedTarget) then obj.lockedTarget = nil end
        end
        if not obj.lockedTarget then obj.lockedTarget = closestInFOV() end
    else
        obj.lockedTarget = nil
    end

    -- Aim at target
    if st.aimbot and rmbDown and obj.lockedTarget and obj.lockedTarget.Character then
        local part = getAimPart(obj.lockedTarget.Character)
        if part then
            local targetPos = predictPosition(part, obj.lockedTarget.Character)
            if cfg.aimSmooth == 0 then
                camera.CFrame = CFrame.new(camera.CFrame.Position, targetPos)
            else
                local t = (1 - cfg.aimSmooth / 100) * 0.93 + 0.02
                local dir = camera.CFrame.LookVector:Lerp((targetPos - camera.CFrame.Position).Unit, t).Unit
                camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + dir)
            end
        end
    end

    -- Update status pills
    for key, pill in pairs(obj.statusPills) do
        if pill.label and key ~= "lock" and key ~= "espTimer" then
            local on = st[key]
            pill.label.Text = pill.label.Text:gsub(" ON", ""):gsub(" OFF", "") .. (on and " ON" or " OFF")
            pill.label.TextColor3 = on and (pill.color or C.success) or C.textMuted
        end
    end

    -- Lock status
    if obj.statusPills["lock"] and obj.statusPills["lock"].label then
        local lbl = obj.statusPills["lock"].label
        if obj.lockedTarget and rmbDown then
            lbl.Text = "🔒 LOCKED: " .. obj.lockedTarget.DisplayName
            lbl.TextColor3 = C.error
        else
            lbl.Text = "🔓 No Target"
            lbl.TextColor3 = C.textMuted
        end
    end

    -- Kill feed display
    if obj.killFeedLabel then
        if #obj.killFeed > 0 then
            local lines = {}
            for i = math.max(1, #obj.killFeed - 3), #obj.killFeed do
                table.insert(lines, obj.killFeed[i])
            end
            obj.killFeedLabel.Text = table.concat(lines, "\n")
        end
    end

    -- ESP timer
    if obj.statusPills["espTimer"] and obj.statusPills["espTimer"].label then
        if st.esp then
            local rem = cfg.espRefreshRate - (os.time() - lastESPRefresh)
            obj.statusPills["espTimer"].label.Text = string.format("🔄 ESP Refresh: %d:%02d", math.floor(rem / 60), rem % 60)
        else
            obj.statusPills["espTimer"].label.Text = "🔄 ESP: OFF"
        end
    end
end))

-- ══════════════════════════════════════════════════════════════
--  S22: SILENT AIM
-- ══════════════════════════════════════════════════════════════
if XC.hookmetamethod then
    pcall(function()
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", function(self, key)
            if not st.silentAim or not obj.lockedTarget then return oldIndex(self, key) end
            if self == mouse then
                local part = getAimPart(obj.lockedTarget.Character)
                if part then
                    local pos = predictPosition(part, obj.lockedTarget.Character)
                    if key == "Hit" then return CFrame.new(pos) end
                    if key == "Target" then return part end
                    if key == "UnitRay" then
                        return Ray.new(camera.CFrame.Position, (pos - camera.CFrame.Position).Unit)
                    end
                end
            end
            return oldIndex(self, key)
        end)

        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if not st.silentAim or not obj.lockedTarget then return oldNamecall(self, ...) end
            if method == "Raycast" and self == Workspace then
                local part = getAimPart(obj.lockedTarget.Character)
                if part then
                    local pos = predictPosition(part, obj.lockedTarget.Character)
                    local args = { ... }
                    args[1] = camera.CFrame.Position
                    args[2] = (pos - camera.CFrame.Position).Unit * 1000
                    return oldNamecall(self, unpack(args))
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
end

-- ══════════════════════════════════════════════════════════════
--  S23: TRIGGER BOT
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    while st.running do
        task.wait(cfg.triggerDelay)
        if st.triggerBot then
            local mp = UIS:GetMouseLocation()
            for _, plr in ipairs(Players:GetPlayers()) do
                if isValidTarget(plr) then
                    local part = getAimPart(plr.Character)
                    if part then
                        local sp, on = camera:WorldToViewportPoint(part.Position)
                        if on and (Vector2.new(sp.X, sp.Y) - mp).Magnitude < cfg.triggerFOV then
                            if XC.mouse1click then
                                mouse1click()
                            elseif XC.VIM then
                                pcall(function()
                                    VirtualInputManager:SendMouseButtonEvent(mp.X, mp.Y, 0, true, game, 0)
                                    task.wait(0.02)
                                    VirtualInputManager:SendMouseButtonEvent(mp.X, mp.Y, 0, false, game, 0)
                                end)
                            end
                            break
                        end
                    end
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  S24: ESP SYSTEM
-- ══════════════════════════════════════════════════════════════
local bbParent = playerGui
pcall(function()
    local test = Instance.new("BillboardGui")
    test.Parent = CoreGui
    test:Destroy()
    bbParent = CoreGui
end)

local function clearESP()
    local keys = {}
    for p in pairs(obj.espObjs) do table.insert(keys, p) end
    for _, p in ipairs(keys) do
        local d = obj.espObjs[p]
        if d then
            pcall(function() if d.hl then d.hl:Destroy() end end)
            pcall(function() if d.bb then d.bb:Destroy() end end)
            pcall(function() if d.box then d.box:Destroy() end end)
            pcall(function() if d.tracer then d.tracer:Destroy() end end)
            pcall(function() if d.cn then d.cn:Disconnect() end end)
        end
        obj.espObjs[p] = nil
    end
end

local function addESP(plr)
    if not st.esp or not plr or plr == player or obj.espObjs[plr] then return end
    if not isValidTarget(plr) then return end
    local char = plr.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not head then return end

    local data = {}

    -- Highlight
    pcall(function()
        local hl = Instance.new("Highlight")
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.FillColor = C.accent
        hl.OutlineColor = C.accent:Lerp(Color3.new(0, 0, 0), 0.4)
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = char
        hl.Parent = char
        data.hl = hl
    end)

    -- BillboardGui
    pcall(function()
        local bb = Instance.new("BillboardGui")
        bb.Adornee = head
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0, 140, 0, 50)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.Parent = bbParent

        local nl = Instance.new("TextLabel")
        nl.Size = UDim2.new(1, 0, 0, 18)
        nl.BackgroundTransparency = 1
        nl.Font = Enum.Font.GothamBold
        nl.TextSize = 13
        nl.TextColor3 = Color3.new(1, 1, 1)
        nl.TextStrokeTransparency = 0.4
        nl.Text = plr.DisplayName
        nl.Parent = bb

        local dl = Instance.new("TextLabel")
        dl.Size = UDim2.new(1, 0, 0, 14)
        dl.Position = UDim2.new(0, 0, 0, 18)
        dl.BackgroundTransparency = 1
        dl.Font = Enum.Font.Gotham
        dl.TextSize = 11
        dl.TextColor3 = C.accent
        dl.TextStrokeTransparency = 0.4
        dl.Text = "0m"
        dl.Parent = bb

        -- HP bar
        local hpBg = Instance.new("Frame")
        hpBg.Size = UDim2.new(0.8, 0, 0, 4)
        hpBg.Position = UDim2.new(0.1, 0, 0, 34)
        hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        hpBg.BorderSizePixel = 0
        hpBg.Parent = bb
        mkCorner(hpBg, 2)

        local hpFill = Instance.new("Frame")
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpFill.BackgroundColor3 = C.success
        hpFill.BorderSizePixel = 0
        hpFill.Parent = hpBg
        mkCorner(hpFill, 2)

        data.bb = bb
        data.distLabel = dl
        data.hpFill = hpFill
    end)

    -- 3D Box
    if st.box3d and hrp then
        pcall(function()
            local box = Instance.new("SelectionBox")
            box.Adornee = hrp
            box.Color3 = C.accent
            box.SurfaceTransparency = 0.85
            box.LineThickness = 0.03
            box.Parent = hrp
            data.box = box
        end)
    end

    -- Update connection
    data.cn = RS.RenderStepped:Connect(function()
        pcall(function()
            if not char or not char.Parent or not head.Parent then
                local d = obj.espObjs[plr]
                if d then
                    pcall(function() if d.hl then d.hl:Destroy() end end)
                    pcall(function() if d.bb then d.bb:Destroy() end end)
                    pcall(function() if d.box then d.box:Destroy() end end)
                    pcall(function() if d.cn then d.cn:Disconnect() end end)
                    obj.espObjs[plr] = nil
                end
                return
            end
            local dist = math.floor((head.Position - camera.CFrame.Position).Magnitude)
            if data.distLabel then data.distLabel.Text = dist .. "m" end
            -- HP
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and data.hpFill and hum.MaxHealth > 0 then
                local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                data.hpFill.Size = UDim2.new(pct, 0, 1, 0)
                data.hpFill.BackgroundColor3 = pct > 0.5 and C.success or pct > 0.25 and C.warning or C.error
            end
        end)
    end)

    obj.espObjs[plr] = data
end

-- ESP loop
task.spawn(function()
    while st.running do
        task.wait(1)
        if st.esp then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and not obj.espObjs[plr] then
                    pcall(function() addESP(plr) end)
                end
            end
            -- Auto refresh
            if os.time() - lastESPRefresh >= cfg.espRefreshRate then
                clearESP()
                lastESPRefresh = os.time()
            end
        else
            clearESP()
        end
    end
end)

addConn(Players.PlayerAdded:Connect(function(plr)
    task.delay(2, function()
        if st.esp and st.running then pcall(function() addESP(plr) end) end
    end)
end))
addConn(Players.PlayerRemoving:Connect(function(plr)
    if obj.espObjs[plr] then
        local d = obj.espObjs[plr]
        pcall(function() if d.hl then d.hl:Destroy() end end)
        pcall(function() if d.bb then d.bb:Destroy() end end)
        pcall(function() if d.box then d.box:Destroy() end end)
        pcall(function() if d.cn then d.cn:Disconnect() end end)
        obj.espObjs[plr] = nil
    end
end))

-- ══════════════════════════════════════════════════════════════
--  S25: MOVEMENT
-- ══════════════════════════════════════════════════════════════
function enableFly()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function() if obj.bv then obj.bv:Destroy() end end)
    pcall(function() if obj.bg then obj.bg:Destroy() end end)
    obj.bv = Instance.new("BodyVelocity")
    obj.bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    obj.bv.Velocity = Vector3.zero
    obj.bv.Parent = hrp
    obj.bg = Instance.new("BodyGyro")
    obj.bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    obj.bg.P = 1e4
    obj.bg.Parent = hrp
end

function disableFly()
    pcall(function() if obj.bv then obj.bv:Destroy(); obj.bv = nil end end)
    pcall(function() if obj.bg then obj.bg:Destroy(); obj.bg = nil end end)
end

-- Fly update
addConn(RS.RenderStepped:Connect(function()
    if not st.running then return end
    if st.fly and obj.bv and obj.bg then
        local cam = camera.CFrame
        local mv = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.yAxis end
        obj.bv.Velocity = mv.Magnitude > 0 and mv.Unit * cfg.flySpeed or Vector3.zero
        obj.bg.CFrame = cam
    end
end))

-- Noclip
addConn(RS.Stepped:Connect(function()
    if not st.running then return end
    if st.noclip and player.Character then
        for _, p in ipairs(player.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end))

-- Speed
addConn(RS.RenderStepped:Connect(function()
    if not st.running then return end
    if st.speed and player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = cfg.walkSpeed end
    end
end))

-- Infinite Jump
addConn(UIS.JumpRequest:Connect(function()
    if st.infJump and player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

-- No Fall Damage
addConn(RS.RenderStepped:Connect(function()
    if st.noFallDmg and player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        end
    end
end))

-- SpinBot
task.spawn(function()
    while st.running do
        task.wait(1 / 30)
        if st.spinBot and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(cfg.spinSpeed), 0)
            end
        end
    end
end)

-- Respawn handler
addConn(player.CharacterAdded:Connect(function()
    task.wait(0.5)
    if st.fly then enableFly() end
end))

-- ══════════════════════════════════════════════════════════════
--  S26: HITBOX EXPANDER
-- ══════════════════════════════════════════════════════════════
local bparts = { "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg", "HumanoidRootPart" }

function resetAllHitboxes()
    for plr, sizes in pairs(obj.origSizes) do
        if plr.Character then
            for nm, sz in pairs(sizes) do
                local p = plr.Character:FindFirstChild(nm)
                if p and p:IsA("BasePart") then
                    pcall(function()
                        p.Size = sz
                        p.Transparency = nm == "HumanoidRootPart" and 1 or 0
                    end)
                end
            end
        end
        obj.origSizes[plr] = nil
    end
end

task.spawn(function()
    while st.running do
        task.wait(0.8)
        if st.hitbox then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and isValidTarget(plr) and plr.Character then
                    obj.origSizes[plr] = obj.origSizes[plr] or {}
                    for _, nm in ipairs(bparts) do
                        local p = plr.Character:FindFirstChild(nm)
                        if p and p:IsA("BasePart") then
                            pcall(function()
                                if not obj.origSizes[plr][nm] then obj.origSizes[plr][nm] = p.Size end
                                p.Size = obj.origSizes[plr][nm] * (cfg.hitboxSize / 5)
                                p.Transparency = cfg.hitboxTransparency
                                p.CanCollide = false
                            end)
                        end
                    end
                end
            end
        else
            resetAllHitboxes()
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  S27: MISC (Anti-AFK, Fullbright, ClickTP)
-- ══════════════════════════════════════════════════════════════
-- Anti-AFK
pcall(function()
    if VirtualUser then
        addConn(player.Idled:Connect(function()
            if st.antiAfk then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.zero) end
        end))
    end
end)

-- Fullbright
pcall(function()
    obj.origLighting = {
        Brightness = Lighting.Brightness,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
    }
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo then obj.origLighting.AtmoDensity = atmo.Density end
end)

function setFullbright(on)
    if on then
        Lighting.Brightness = 2
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
        local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmo then atmo.Density = 0 end
    else
        Lighting.Brightness = obj.origLighting.Brightness or 1
        Lighting.FogEnd = obj.origLighting.FogEnd or 1e4
        Lighting.GlobalShadows = obj.origLighting.GlobalShadows ~= false
        local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmo and obj.origLighting.AtmoDensity then atmo.Density = obj.origLighting.AtmoDensity end
    end
end

-- Click TP
addConn(mouse.Button1Down:Connect(function()
    if st.clickTP and UIS:IsKeyDown(keybinds.clickTP) then
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end))

-- ══════════════════════════════════════════════════════════════
--  S28: RGB ENGINE + GLOW PULSE
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    local hue = 0
    local pulsePhase = 0
    while st.running do
        task.wait(1 / 30)
        hue = (hue + cfg.rgb.speed / 300) % 1
        pulsePhase = pulsePhase + 0.05
        local rgbColor = Color3.fromHSV(hue, cfg.rgb.saturation, cfg.rgb.brightness)

        for _, el in ipairs(obj.rgbElements) do
            pcall(function()
                if el.type == "stroke" and cfg.rgb.stroke then
                    el.obj[el.prop] = rgbColor
                elseif el.type == "title" and cfg.rgb.title then
                    el.obj[el.prop] = rgbColor
                elseif el.type == "indicator" and cfg.rgb.indicator then
                    el.obj[el.prop] = rgbColor
                end
            end)
        end

        -- Glow pulse on panel stroke
        if cfg.rgb.stroke or cfg.rgb.title then
            pcall(function()
                local pulse = math.sin(pulsePhase) * 0.5 + 0.5
                panelStroke.Thickness = 1.5 + pulse * 2
                panelStroke.Transparency = 0.1 + (1 - pulse) * 0.4
            end)
        else
            pcall(function()
                panelStroke.Thickness = 1.5
                panelStroke.Transparency = 0.3
            end)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  S29: INPUT HANDLER
-- ══════════════════════════════════════════════════════════════
local function toggleFeature(key)
    st[key] = not st[key]
    local on = st[key]
    syncToggleVisual(key, on)

    -- Side effects
    if key == "esp" then
        if not on then clearESP() else lastESPRefresh = os.time() end
        notify(on and "👁️ ESP ON" or "❌ ESP OFF", on and C.success or C.error)
    elseif key == "aimbot" then
        if not on then obj.lockedTarget = nil; rmbDown = false end
        notify(on and "🎯 Aimbot ON" or "❌ Aimbot OFF", on and C.purple or C.error)
    elseif key == "silentAim" then
        notify(on and "🔇 Silent ON" or "❌ Silent OFF", on and C.cyan or C.error)
    elseif key == "triggerBot" then
        notify(on and "🔫 Trigger ON" or "❌ Trigger OFF", on and C.warning or C.error)
    elseif key == "fly" then
        if on then enableFly() else disableFly() end
        notify(on and "✈️ Fly ON" or "❌ Fly OFF", on and C.blue or C.error)
    elseif key == "noclip" then
        if not on then
            pcall(function()
                for _, p in ipairs(player.Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end)
        end
        notify(on and "👻 Noclip ON" or "❌ Noclip OFF", on and C.success or C.error)
    elseif key == "hitbox" then
        if not on then resetAllHitboxes() end
        notify(on and "📦 Hitbox ON" or "❌ Hitbox OFF", on and C.warning or C.error)
    elseif key == "speed" then
        if not on then
            pcall(function()
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end)
        end
        notify(on and "🏃 Speed ON" or "❌ Speed OFF", on and C.accent or C.error)
    elseif key == "fullbright" then
        setFullbright(on)
        notify(on and "💡 Fullbright ON" or "❌ Fullbright OFF", on and C.warning or C.error)
    elseif key == "crosshair" then
        notify(on and "➕ Crosshair ON" or "❌ Crosshair OFF", on and C.accent or C.error)
    else
        notify(on and ("✅ " .. key .. " ON") or ("❌ " .. key .. " OFF"), on and C.accent or C.error)
    end
end

local function doPanic()
    for key in pairs(st) do
        if key ~= "running" and key ~= "guiVisible" and key ~= "antiAfk" then
            st[key] = false
            syncToggleVisual(key, false)
        end
    end
    clearESP(); resetAllHitboxes(); disableFly()
    rmbDown = false; obj.lockedTarget = nil
    setFullbright(false)
    pcall(function()
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end)
    pcall(function()
        for _, p in ipairs(player.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end)
    notify("🚨 PANIC — All OFF!", C.error)
end

local function doEject()
    st.running = false
    doPanic()
    cleanConns()
    pcall(function() screenGui:Destroy() end)
    pcall(function() if obj.thGui then obj.thGui:Destroy() end end)
    pcall(function() if obj.feedbackGui then obj.feedbackGui:Destroy() end end)
    pcall(function() if obj.hitSoundObj then obj.hitSoundObj:Destroy() end end)
    for _, n in ipairs(notifStack) do pcall(function() n.gui:Destroy() end) end
    if getgenv then getgenv().MedusaLoaded = false end
    print("[Medusa] Ejected!")
end
if getgenv then getgenv().MedusaEject = doEject end

addConn(UIS.InputBegan:Connect(function(i, gp)
    if gp or not st.running then return end
    if i.UserInputType == Enum.UserInputType.MouseButton2 then
        if st.aimbot then rmbDown = true end
        return
    end
    if not i.KeyCode or i.KeyCode == Enum.KeyCode.Unknown then return end

    -- Check keybinds
    for key, bind in pairs(keybinds) do
        if i.KeyCode == bind then
            if key == "panic" then doPanic()
            elseif key == "eject" then doEject()
            elseif key == "toggleGui" then
                st.guiVisible = not st.guiVisible
                panel.Visible = st.guiVisible
                shadow.Visible = st.guiVisible
            elseif st[key] ~= nil then
                toggleFeature(key)
            end
            return
        end
    end
end))

addConn(UIS.InputEnded:Connect(function(i)
    if not st.running then return end
    if i.UserInputType == Enum.UserInputType.MouseButton2 then
        rmbDown = false
        obj.lockedTarget = nil
    end
end))

-- ══════════════════════════════════════════════════════════════
--  S30: WATERMARK & CROSSHAIR
-- ══════════════════════════════════════════════════════════════
-- Watermark
local wmGui = createGui("MedusaWM")
local wmFrame = Instance.new("Frame")
wmFrame.Size = UDim2.new(0, 220, 0, 26)
wmFrame.Position = UDim2.new(0, 16, 0, 16)
wmFrame.BackgroundColor3 = C.bgDark
wmFrame.BackgroundTransparency = 0.15
wmFrame.BorderSizePixel = 0
wmFrame.Parent = wmGui
mkCorner(wmFrame, 4)
local wmSk = Instance.new("UIStroke", wmFrame)
wmSk.Color = C.accent; wmSk.Thickness = 1; wmSk.Transparency = 0.3
table.insert(obj.themeElements, { obj = wmSk, prop = "Color" })

obj.wmLabel = Instance.new("TextLabel")
obj.wmLabel.Size = UDim2.new(1, -12, 1, 0)
obj.wmLabel.Position = UDim2.new(0, 6, 0, 0)
obj.wmLabel.BackgroundTransparency = 1
obj.wmLabel.Font = Enum.Font.GothamBold
obj.wmLabel.TextSize = 11
obj.wmLabel.TextColor3 = C.text
obj.wmLabel.TextXAlignment = Enum.TextXAlignment.Left
obj.wmLabel.Text = "🐍 MEDUSA v13.5 | -- FPS | --ms"
obj.wmLabel.Parent = wmFrame

makeDraggable(wmFrame, wmFrame)

-- Watermark update
task.spawn(function()
    while st.running do
        task.wait(0.5)
        pcall(function()
            if obj.wmLabel then
                obj.wmLabel.Text = "🐍 MEDUSA v13.5 | " .. obj.wmFps .. " FPS | " .. obj.wmPing .. "ms"
            end
        end)
    end
end)

-- Crosshair
local crossGui = createGui("MedusaCross")
local crossLines = {}
for i = 1, 4 do
    local line = Instance.new("Frame")
    line.BackgroundColor3 = C.accent
    line.BorderSizePixel = 0
    line.Visible = false
    line.ZIndex = 10
    line.Parent = crossGui
    table.insert(crossLines, line)
    table.insert(obj.themeElements, { obj = line, prop = "BackgroundColor3" })
end

addConn(RS.RenderStepped:Connect(function()
    if not st.crosshair then
        for _, l in ipairs(crossLines) do l.Visible = false end
        return
    end
    local vp = camera.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2
    local sz, gap = cfg.crossSize, cfg.crossGap

    for _, l in ipairs(crossLines) do l.Visible = true end
    -- Top
    crossLines[1].Size = UDim2.new(0, 2, 0, sz)
    crossLines[1].Position = UDim2.new(0, cx - 1, 0, cy - gap - sz)
    -- Bottom
    crossLines[2].Size = UDim2.new(0, 2, 0, sz)
    crossLines[2].Position = UDim2.new(0, cx - 1, 0, cy + gap)
    -- Left
    crossLines[3].Size = UDim2.new(0, sz, 0, 2)
    crossLines[3].Position = UDim2.new(0, cx - gap - sz, 0, cy - 1)
    -- Right
    crossLines[4].Size = UDim2.new(0, sz, 0, 2)
    crossLines[4].Position = UDim2.new(0, cx + gap, 0, cy - 1)
end))

-- ══════════════════════════════════════════════════════════════
--  S30B: TARGET HUD PREDADOR (MODULAR)
-- ══════════════════════════════════════════════════════════════
do
    local thGui = createGui("MedusaTH")
    obj.thGui = thGui

    local thPanel = Instance.new("Frame")
    thPanel.Size = UDim2.new(0, 220, 0, 120)
    thPanel.Position = UDim2.new(0.5, -110, 0, 80)
    thPanel.BackgroundColor3 = C.bgDark
    thPanel.BackgroundTransparency = 1
    thPanel.BorderSizePixel = 0
    thPanel.Visible = false
    thPanel.Parent = thGui
    mkCorner(thPanel, 6)
    local thSk = Instance.new("UIStroke", thPanel)
    thSk.Color = C.accent; thSk.Thickness = 1.5; thSk.Transparency = 1
    table.insert(obj.themeElements, { obj = thSk, prop = "Color" })
    obj.thFrame = thPanel

    makeDraggable(thPanel, thPanel)

    -- Elements
    local thNameLbl = mkLabel(thPanel, "", 14, Color3.new(1, 1, 1), 10, 8)
    thNameLbl.Font = Enum.Font.GothamBold

    local thHpBg = Instance.new("Frame")
    thHpBg.Size = UDim2.new(1, -20, 0, 8)
    thHpBg.Position = UDim2.new(0, 10, 0, 30)
    thHpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    thHpBg.BorderSizePixel = 0
    thHpBg.Parent = thPanel
    mkCorner(thHpBg, 4)

    local thHpFill = Instance.new("Frame")
    thHpFill.Size = UDim2.new(1, 0, 1, 0)
    thHpFill.BackgroundColor3 = C.success
    thHpFill.BorderSizePixel = 0
    thHpFill.Parent = thHpBg
    mkCorner(thHpFill, 4)

    local thHpText = mkLabel(thPanel, "", 10, C.text, 10, 42)
    local thWeaponLbl = mkLabel(thPanel, "", 10, C.textMuted, 10, 58)
    local thDistLbl = mkLabel(thPanel, "", 10, C.textMuted, 10, 74)
    local thLockLbl = mkLabel(thPanel, "", 10, C.accent, 10, 90)

    -- Update loop
    task.spawn(function()
        local lastTarget = nil
        while st.running do
            task.wait(1 / 20)
            pcall(function()
                local show = st.aimbot and rmbDown and obj.lockedTarget ~= nil
                if show and obj.lockedTarget and obj.lockedTarget.Character then
                    local char = obj.lockedTarget.Character
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if not hum or hum.Health <= 0 then show = false end

                    if show then
                        -- Calculate height
                        local h = 10
                        if st.thName then h = h + 22 end
                        if st.thHealth then h = h + 24 end
                        if st.thWeapon then h = h + 16 end
                        if st.thDistance then h = h + 16 end
                        if st.thLockStatus then h = h + 16 end

                        -- Show panel
                        if thPanel.BackgroundTransparency > 0.1 then
                            thPanel.Visible = true
                            TS:Create(thPanel, TweenInfo.new(0.25), { BackgroundTransparency = 0.08 }):Play()
                            TS:Create(thSk, TweenInfo.new(0.25), { Transparency = 0.2 }):Play()
                        end

                        -- Position elements dynamically
                        local y = 8
                        -- Name
                        thNameLbl.Visible = st.thName
                        if st.thName then
                            thNameLbl.Text = "🎯 " .. obj.lockedTarget.DisplayName
                            thNameLbl.Position = UDim2.new(0, 10, 0, y)
                            y = y + 22
                        end
                        -- Health
                        thHpBg.Visible = st.thHealth
                        thHpText.Visible = st.thHealth
                        if st.thHealth and hum.MaxHealth > 0 then
                            local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                            TS:Create(thHpFill, TweenInfo.new(0.3), {
                                Size = UDim2.new(pct, 0, 1, 0),
                                BackgroundColor3 = pct > 0.5 and C.success or pct > 0.25 and C.warning or C.error
                            }):Play()
                            thHpBg.Position = UDim2.new(0, 10, 0, y)
                            thHpText.Text = string.format("HP: %d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))
                            thHpText.Position = UDim2.new(0, 10, 0, y + 10)
                            y = y + 24
                        end
                        -- Weapon
                        thWeaponLbl.Visible = st.thWeapon
                        if st.thWeapon then
                            local tool = char:FindFirstChildOfClass("Tool")
                            thWeaponLbl.Text = tool and ("🔫 " .. tool.Name) or "🤜 Unarmed"
                            thWeaponLbl.Position = UDim2.new(0, 10, 0, y)
                            y = y + 16
                        end
                        -- Distance
                        thDistLbl.Visible = st.thDistance
                        if st.thDistance then
                            local head = char:FindFirstChild("Head")
                            local dist = head and math.floor((head.Position - camera.CFrame.Position).Magnitude) or 0
                            thDistLbl.Text = "📏 " .. dist .. "m"
                            thDistLbl.Position = UDim2.new(0, 10, 0, y)
                            y = y + 16
                        end
                        -- Lock status
                        thLockLbl.Visible = st.thLockStatus
                        if st.thLockStatus then
                            thLockLbl.Text = "🔒 LOCKED"
                            thLockLbl.Position = UDim2.new(0, 10, 0, y)
                            y = y + 16
                        end

                        thPanel.Size = UDim2.new(0, 220, 0, h)

                        -- Flash on new target
                        if obj.lockedTarget ~= lastTarget then
                            lastTarget = obj.lockedTarget
                            TS:Create(thSk, TweenInfo.new(0.1), { Thickness = 3 }):Play()
                            task.delay(0.2, function()
                                TS:Create(thSk, TweenInfo.new(0.3), { Thickness = 1.5 }):Play()
                            end)
                        end
                    end
                end

                if not show and thPanel.BackgroundTransparency < 0.9 then
                    TS:Create(thPanel, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
                    TS:Create(thSk, TweenInfo.new(0.2), { Transparency = 1 }):Play()
                    task.delay(0.25, function()
                        if not (st.aimbot and rmbDown and obj.lockedTarget) then
                            thPanel.Visible = false
                            lastTarget = nil
                        end
                    end)
                end
            end)
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
--  S30C: FEEDBACK MODULE
-- ══════════════════════════════════════════════════════════════
do
    -- Hit Sound
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://6333389871"
        sound.Volume = 0.5
        sound.Parent = SoundService
        obj.hitSoundObj = sound
    end)

    -- Kill Popup
    local function showKillPopup(victimName)
        if not st.killPopup then return end
        obj.killStreak = obj.killStreak + 1

        local sg = createGui("MedusaKill")
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 300, 0, 50)
        lbl.Position = UDim2.new(0.5, -150, 0.4, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBlack
        lbl.TextSize = 32
        lbl.TextColor3 = C.error
        lbl.TextStrokeTransparency = 0.3
        lbl.TextTransparency = 1
        lbl.Text = "+" .. obj.killStreak .. " ELIMINATED"
        lbl.Parent = sg

        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(0, 300, 0, 20)
        sub.Position = UDim2.new(0.5, -150, 0.4, 50)
        sub.BackgroundTransparency = 1
        sub.Font = Enum.Font.GothamBold
        sub.TextSize = 16
        sub.TextColor3 = Color3.new(1, 1, 1)
        sub.TextStrokeTransparency = 0.4
        sub.TextTransparency = 1
        sub.Text = "☠️ " .. victimName
        sub.Parent = sg

        -- Animate in
        TS:Create(lbl, TweenInfo.new(0.3, Enum.EasingStyle.Back), { TextTransparency = 0, TextSize = 36 }):Play()
        TS:Create(sub, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()

        -- Kill feed
        table.insert(obj.killFeed, os.date("%H:%M") .. " ☠️ " .. victimName)
        if #obj.killFeed > 8 then table.remove(obj.killFeed, 1) end

        -- Animate out
        task.delay(1.5, function()
            TS:Create(lbl, TweenInfo.new(0.5), { TextTransparency = 1, Position = UDim2.new(0.5, -150, 0.35, 0) }):Play()
            TS:Create(sub, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
            task.wait(0.6)
            pcall(function() sg:Destroy() end)
        end)
    end

    -- Spectator List
    local specGui = createGui("MedusaSpec")
    obj.feedbackGui = specGui
    local specPanel = Instance.new("Frame")
    specPanel.Size = UDim2.new(0, 160, 0, 30)
    specPanel.Position = UDim2.new(0, 16, 0, 50)
    specPanel.BackgroundColor3 = C.bgDark
    specPanel.BackgroundTransparency = 0.15
    specPanel.BorderSizePixel = 0
    specPanel.Visible = false
    specPanel.Parent = specGui
    mkCorner(specPanel, 4)
    local specSk = Instance.new("UIStroke", specPanel)
    specSk.Color = C.accent; specSk.Thickness = 1; specSk.Transparency = 0.4

    local specTitle = mkLabel(specPanel, "👁️ Spectators: 0", 10, C.text, 6, 2, 1, 16)
    specTitle.Font = Enum.Font.GothamBold
    local specList = mkLabel(specPanel, "", 9, C.textMuted, 6, 18, 1, 40)
    specList.TextWrapped = true
    specList.TextYAlignment = Enum.TextYAlignment.Top

    makeDraggable(specPanel, specPanel)

    -- Feedback monitor
    task.spawn(function()
        local lastHP = {}
        while st.running do
            task.wait(1 / 15)
            -- Hit sound
            if st.hitSound and obj.lockedTarget and obj.lockedTarget.Character then
                pcall(function()
                    local hum = obj.lockedTarget.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local id = obj.lockedTarget.UserId
                        local prev = lastHP[id]
                        lastHP[id] = hum.Health
                        if prev and hum.Health < prev and (prev - hum.Health) > 0.1 then
                            if obj.hitSoundObj then
                                obj.hitSoundObj.PlaybackSpeed = 1.0 + math.random() * 0.4
                                obj.hitSoundObj:Play()
                            end
                        end
                        -- Kill detect
                        if prev and prev > 0 and hum.Health <= 0 then
                            showKillPopup(obj.lockedTarget.DisplayName)
                        end
                    end
                end)
            end

            -- Spectator list
            if st.spectatorList then
                pcall(function()
                    local specs = {}
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= player then
                            local isMod = false
                            pcall(function()
                                if plr.Character then
                                    for _, t in ipairs(plr.Character:GetChildren()) do
                                        if t:IsA("Tool") then
                                            local nm = t.Name:lower()
                                            if nm:find("admin") or nm:find("ban") or nm:find("kick") or nm:find("mod") then
                                                isMod = true
                                            end
                                        end
                                    end
                                end
                                if plr.Team then
                                    local tn = plr.Team.Name:lower()
                                    if tn:find("admin") or tn:find("mod") or tn:find("staff") then isMod = true end
                                end
                            end)
                            -- Check if they might be spectating (no character or dead)
                            if not plr.Character or not plr.Character:FindFirstChildOfClass("Humanoid") or plr.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
                                table.insert(specs, { name = plr.DisplayName, mod = isMod })
                            end
                        end
                    end

                    specPanel.Visible = #specs > 0
                    specTitle.Text = "👁️ Spectators: " .. #specs
                    local lines = {}
                    for _, s in ipairs(specs) do
                        table.insert(lines, s.mod and ("⚠️ [MOD] " .. s.name) or s.name)
                    end
                    specList.Text = table.concat(lines, "\n")
                    specPanel.Size = UDim2.new(0, 160, 0, 22 + math.max(1, #specs) * 14)
                end)
            else
                specPanel.Visible = false
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
--  S31: PLAYERS TAB LOGIC
-- ══════════════════════════════════════════════════════════════
function refreshPlayers()
    if not obj.playersContainer then return end
    for _, c in ipairs(obj.playersContainer:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            pcall(function()
                local card = Instance.new("Frame")
                card.Size = UDim2.new(1, 0, 0, 60)
                card.BackgroundColor3 = C.bgCard
                card.BorderSizePixel = 0
                card.Parent = obj.playersContainer
                mkCorner(card, 4)

                mkLabel(card, plr.DisplayName, 12, C.text, 10, 4)
                mkLabel(card, "@" .. plr.Name, 10, C.textMuted, 10, 20)

                -- HP bar
                local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                local pct = hum and hum.MaxHealth > 0 and (hum.Health / hum.MaxHealth) or 1
                local hpBg = Instance.new("Frame")
                hpBg.Size = UDim2.new(0.5, 0, 0, 4)
                hpBg.Position = UDim2.new(0, 10, 0, 38)
                hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                hpBg.BorderSizePixel = 0
                hpBg.Parent = card
                mkCorner(hpBg, 2)
                local hpFill = Instance.new("Frame")
                hpFill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
                hpFill.BackgroundColor3 = pct > 0.5 and C.success or pct > 0.25 and C.warning or C.error
                hpFill.BorderSizePixel = 0
                hpFill.Parent = hpBg
                mkCorner(hpFill, 2)

                -- Buttons
                local btnW = 44
                for bi, bd in ipairs({ { "📷", C.blue }, { "💥", C.error }, { "🏃", C.success } }) do
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(0, btnW, 0, 22)
                    b.Position = UDim2.new(1, -(btnW * (4 - bi) + 6 * (4 - bi)), 0, 4)
                    b.BackgroundColor3 = C.bgDark
                    b.BorderSizePixel = 0
                    b.AutoButtonColor = false
                    b.Font = Enum.Font.GothamBold
                    b.TextSize = 14
                    b.TextColor3 = bd[2]
                    b.Text = bd[1]
                    b.Parent = card
                    mkCorner(b, 4)

                    if bi == 1 then -- Spectate
                        b.MouseButton1Click:Connect(function()
                            pcall(function()
                                if plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
                                    camera.CameraSubject = plr.Character:FindFirstChildOfClass("Humanoid")
                                    notify("📷 Spectating: " .. plr.DisplayName, C.blue)
                                end
                            end)
                        end)
                    elseif bi == 2 then -- Fling
                        b.MouseButton1Click:Connect(function()
                            pcall(function()
                                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                                local tHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                                if hrp and tHrp then
                                    hrp.CFrame = tHrp.CFrame
                                    hrp.Velocity = Vector3.new(math.random(-500, 500), 500, math.random(-500, 500))
                                    notify("💥 Flung: " .. plr.DisplayName, C.error)
                                end
                            end)
                        end)
                    elseif bi == 3 then -- TP
                        b.MouseButton1Click:Connect(function()
                            pcall(function()
                                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                                local tHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                                if hrp and tHrp then
                                    hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, -3)
                                    notify("🏃 TP to: " .. plr.DisplayName, C.success)
                                end
                            end)
                        end)
                    end
                end
            end)
        end
    end
end

-- Auto refresh
task.spawn(function()
    while st.running do
        task.wait(5)
        if obj.currentTab == "players" then
            pcall(function() refreshPlayers() end)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  S32: STARTUP
-- ══════════════════════════════════════════════════════════════
switchTab("status")
refreshPlayers()

-- Fade in
panel.BackgroundTransparency = 1
shadow.BackgroundTransparency = 1
TS:Create(panel, TweenInfo.new(0.5, Enum.EasingStyle.Back), { BackgroundTransparency = cfg.gui.panelOpacity }):Play()
TS:Create(shadow, TweenInfo.new(0.5), { BackgroundTransparency = 0.7 }):Play()

-- Close button
closeBtn.MouseButton1Click:Connect(function()
    notify("🗑️ Ejecting...", C.error)
    task.delay(0.5, doEject)
end)

notify("🐍 Medusa v13.5 Loaded!", C.success)

print("═══════════════════════════════════════")
print("  🐍 MEDUSA v13.5 — PREDADOR EDITION")
print("  Made by .donatorexe.")
print("  Xeno Executor Optimized")
print("═══════════════════════════════════════")
print("Medusa v13.5: Build Final Concluido")
