--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║       🐍 MEDUSA v15.1 — CINEMATIC EDITION 🐍              ║
    ║                Made by .donatorexe.                         ║
    ║           Xeno Executor Optimized | .lua                    ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  Layout: Horizontal Dashboard + 2-Column Content            ║
    ║  Combat: Aimbot + Silent v2 (Curve) + Trigger + Prediction  ║
    ║  Vision: ESP + 3D Box + Tracers + Skeleton + View Angles    ║
    ║  Motion: Fly + Noclip + Speed + InfJump + SpinBot           ║
    ║  HUD: Target Predador + Kill Popup + Hit Sound + Spectators ║
    ║  Sound: UI Click/Tab Sounds + Hit Sound Feedback            ║
    ║  Alive: Active HUD + Custom Cursor + Cinematic Intro       ║
    ║  Engine: RGB Glow + 8 Themes + GUI Editor + Auto-Save       ║
    ║  Style: RGB Pickers + Roundness + Transparency + Profiles   ║
    ╚══════════════════════════════════════════════════════════════╝
    
    Loadstring:
      loadstring(game:HttpGet("URL_DO_RAW/Medusa.lua"))()
    
    Hotkeys: T=ESP G=Aimbot F=Fly H=Hitbox U=Noclip
             J=Silent K=Trigger M=Speed N=InfJump
             L=Fullbright C=Crosshair Y=GUI P=Eject
             End=Panic  RMB=Lock Target
--]]

-- S1: ANTI-DUPLICATE
if getgenv and getgenv().MedusaLoaded then
    pcall(function() if getgenv().MedusaEject then getgenv().MedusaEject() end end)
    task.wait(0.5)
end
if getgenv then getgenv().MedusaLoaded = true end

-- S2: POLYFILLS & XENO COMPATIBILITY
if not task or not task.wait then
    task = task or {}
    task.wait = task.wait or wait
    task.spawn = task.spawn or function(f) local co = coroutine.create(f); coroutine.resume(co); return co end
    task.delay = task.delay or function(t, f) local co = coroutine.create(function() wait(t); f() end); coroutine.resume(co); return co end
    task.cancel = task.cancel or function() end
end

local function getService(name) local ok, svc = pcall(function() return game:GetService(name) end); return ok and svc or nil end

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
local LocalizationService = getService("LocalizationService")

local UIS = UserInputService
local TS = TweenService

-- ── UI Sound System (v15.1) ────────────────────────────────
local function createSound(id, volume, pitch)
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://" .. tostring(id)
    s.Volume = volume or 0.3; s.PlaybackSpeed = pitch or 1
    pcall(function() s.Parent = SoundService or game end)
    return s
end

local uiClickSound = createSound(6895079853, 0.25, 1.1)   -- subtle click
local uiTabSound = createSound(6895079853, 0.15, 0.75)    -- deeper tab switch
local uiToggleOnSound = createSound(6895079853, 0.2, 1.3) -- higher pitch ON
local uiToggleOffSound = createSound(6895079853, 0.2, 0.9) -- lower pitch OFF

local function playClick() pcall(function() uiClickSound:Play() end) end
local function playTab() pcall(function() uiTabSound:Play() end) end
local function playToggleOn() pcall(function() uiToggleOnSound:Play() end) end
local function playToggleOff() pcall(function() uiToggleOffSound:Play() end) end

-- ── Location Detection (runs ONCE) ──────────────────────────
local myRegion = "??"   -- Player's own country (from locale)
local svRegion = "??"   -- Server's actual location (from IP)

task.spawn(function()
    -- STEP 1: Detect MY location (from client locale — always works)
    pcall(function()
        if LocalizationService and LocalizationService.GetCountryRegionForPlayerAsync then
            local code = LocalizationService:GetCountryRegionForPlayerAsync(Players.LocalPlayer)
            if code and code ~= "" then myRegion = code end
        end
    end)
    if myRegion == "??" then pcall(function()
        local lid = (LocalizationService and LocalizationService.SystemLocaleId) or Players.LocalPlayer.LocaleId or ""
        local r = lid:match("%-(%a%a)$") or lid:match("^(%a%a)$")
        if r then myRegion = r:upper() end
    end) end

    -- STEP 2: Detect SERVER location (via HTTP IP geolocation)
    pcall(function()
        local httpGet = game.HttpGet or (HttpService and HttpService.GetAsync)
        if not httpGet then svRegion = myRegion; return end

        -- Try ip-api.com first (free, no key needed)
        local ok, raw = pcall(function() return game:HttpGet("http://ip-api.com/json/?fields=status,country,regionName,city,countryCode") end)
        if ok and raw and raw ~= "" then
            local data = HttpService:JSONDecode(raw)
            if data and data.status == "success" then
                local cc = data.countryCode or "??"
                local city = data.city or data.regionName or ""
                if city ~= "" then
                    svRegion = cc .. ", " .. city
                else
                    svRegion = cc
                end
                print("[Medusa] 🌍 Server: " .. svRegion)
                return
            end
        end

        -- Fallback: try ipinfo.io
        local ok2, raw2 = pcall(function() return game:HttpGet("https://ipinfo.io/json") end)
        if ok2 and raw2 and raw2 ~= "" then
            local data2 = HttpService:JSONDecode(raw2)
            if data2 then
                local country = data2.country or "??"
                local city = data2.city or ""
                svRegion = city ~= "" and (country .. ", " .. city) or country
                print("[Medusa] 🌍 Server (ipinfo): " .. svRegion)
                return
            end
        end

        -- Final fallback: use my region as server region
        svRegion = myRegion ~= "??" and myRegion or "LIVE"
    end)

    if svRegion == "??" then svRegion = myRegion ~= "??" and myRegion or "LIVE" end
    print("[Medusa] 👤 ME: " .. myRegion .. " | 🖥️ SV: " .. svRegion)
end)
local RS = RunService

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera
local mouse = player:GetMouse()

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
    makefolder = typeof(makefolder) == "function",
    listfiles = typeof(listfiles) == "function",
    delfile = typeof(delfile) == "function",
    isfolder = typeof(isfolder) == "function",
}
print("[Medusa] Xeno Capabilities:"); for k, v in pairs(XC) do print("  " .. k .. ": " .. tostring(v)) end

-- S3: CONFIGURATION
local cfg = {
    aimbotFOV = 200, fovMin = 50, fovMax = 500,
    aimSmooth = 20, smoothMin = 0, smoothMax = 100,
    aimbotPart = "Head", prediction = false, predStrength = 1.0,
    maxDistance = 1000, distMin = 50, distMax = 2000,
    teamCheck = true, visibleCheck = false, healthCheck = false, healthMin = 10,
    triggerFOV = 30, triggerDelay = 0.1,
    espRefreshRate = 30, espDistance = 2000,
    hitboxSize = 10, hitboxMin = 1, hitboxMax = 25, hitboxTransparency = 0.7,
    flySpeed = 150, flyMin = 50, flyMax = 300,
    walkSpeed = 16, speedMin = 16, speedMax = 200, spinSpeed = 10,
    crossStyle = 1, crossSize = 12, crossGap = 6,
    -- Silent Aim v2: Curve & Hit Chance
    silentCurve = true,       -- curved trajectory (human-like)
    silentCurveStr = 0.15,    -- curve strength (0-1) lower=more subtle
    hitChanceHead = 30,       -- % chance to aim at head
    hitChanceTorso = 70,      -- % chance to aim at torso
    -- Discord Rich Presence
    discordWebhook = "",      -- paste your webhook URL here
    discordRPC = false,       -- auto-update discord status
    discordInterval = 60,     -- seconds between updates
    -- Auto-save
    autoSave = true,          -- save config on every change
    autoSaveDelay = 3,        -- debounce delay in seconds
    -- RGB
    rgb = { stroke = false, title = false, indicator = false, speed = 1, saturation = 1, brightness = 1 },
    gui = {
        panelW = 680, panelH = 540, sidebarW = 52, topbarH = 48,
        fontSize = 12, titleSize = 18, cardSpacing = 10, cardPadding = 12,
        borderWidth = 1.5, cornerRadius = 14,
        toggleW = 40, toggleH = 20, sliderH = 10, btnH = 36,
        panelOpacity = 0.12,
        -- RGB Color Pickers (custom accent, bg, sidebar)
        accentR = 0, accentG = 220, accentB = 180,
        bgR = 12, bgG = 12, bgB = 18,
        sideR = 10, sideG = 10, sideB = 16,
    },
}

-- S4: STATE MANAGEMENT
local st = {
    esp = false, aimbot = false, silentAim = false, triggerBot = false,
    fly = false, noclip = false, speed = false, infJump = false,
    hitbox = false, fullbright = false, noFallDmg = false, clickTP = false,
    spinBot = false, antiAfk = true, crosshair = false,
    box3d = false, tracers = false, skeleton = false,
    ghostMode = false, rainbow = false,
    thName = true, thHealth = true, thWeapon = true, thDistance = true, thLockStatus = true,
    spectatorList = false, killPopup = true, hitSound = true,
    discordRPC = false,
    viewAngles = false, adminDetector = true, metatableBypass = false,
    guiVisible = true, running = true,
}

local obj = {
    bv = nil, bg = nil, lockedTarget = nil, fovCircle = nil,
    espObjs = {}, origSizes = {}, connections = {},
    panel = nil, sidebar = nil, topbar = nil,
    tabFrames = {}, switchTab = nil, currentTab = "status",
    toggleRegistry = {}, rgbElements = {}, themeElements = {}, statusPills = {},
    killFeed = {}, killFeedLabel = nil,
    wmGui = nil, wmLabel = nil, wmFps = "0", wmPing = "0", fpsPingLabel = nil,
    thGui = nil, thFrame = nil,
    feedbackGui = nil, specListFrame = nil,
    hitSoundObj = nil, killStreak = 0,
    lastTargetHP = {}, feedbackTarget = nil, feedbackDiedConn = nil,
    playersContainer = nil, origLighting = {},
    -- v15.1: Sound + Active HUD + Cursor
    clickSound = nil, tabSound = nil,
    activeHudGui = nil, activeHudFrame = nil, activeHudLabels = {},
    cursorGui = nil, cursorFrame = nil,
}

local rmbDown = false
local lastESPRefresh = os.time()

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
local defaultBinds = {}; for k, v in pairs(keybinds) do defaultBinds[k] = v end

local function addConn(conn) table.insert(obj.connections, conn); return conn end
local addConnection = addConn
local function cleanConns() for _, c in ipairs(obj.connections) do pcall(function() c:Disconnect() end) end; obj.connections = {} end

-- S5: COLOR SYSTEM & THEMES (Glass Palette)
local C = {
    accent    = Color3.fromRGB(0, 220, 180),
    bg        = Color3.fromRGB(12, 12, 18),
    bgCard    = Color3.fromRGB(18, 18, 28),
    bgDark    = Color3.fromRGB(8, 8, 14),
    sidebar   = Color3.fromRGB(10, 10, 16),
    topbar    = Color3.fromRGB(10, 10, 16),
    glass     = Color3.fromRGB(22, 22, 35),
    glassHi   = Color3.fromRGB(35, 35, 55),
    text      = Color3.fromRGB(230, 230, 240),
    textMuted = Color3.fromRGB(110, 110, 130),
    success   = Color3.fromRGB(40, 210, 100),
    error     = Color3.fromRGB(245, 70, 70),
    warning   = Color3.fromRGB(250, 165, 15),
    purple    = Color3.fromRGB(170, 90, 250),
    blue      = Color3.fromRGB(65, 140, 255),
    cyan      = Color3.fromRGB(10, 190, 220),
    pink      = Color3.fromRGB(240, 80, 160),
    border    = Color3.fromRGB(50, 50, 75),
    toggleOff = Color3.fromRGB(45, 45, 60),
    sliderTrack = Color3.fromRGB(30, 30, 45),
    killFeed  = Color3.fromRGB(255, 80, 80),
    neonGlow  = Color3.fromRGB(0, 255, 200),
    shadowCol = Color3.fromRGB(0, 0, 0),
}
C.card = C.bgCard; C.muted = C.textMuted; C.aimbot = C.purple; C.fly = C.blue

local themes = {
    { name = "Medusa",    accent = Color3.fromRGB(0, 220, 180) },
    { name = "Vaporwave", accent = Color3.fromRGB(170, 90, 250) },
    { name = "Midnight",  accent = Color3.fromRGB(65, 140, 255) },
    { name = "Toxic",     accent = Color3.fromRGB(40, 210, 100) },
    { name = "Blood",     accent = Color3.fromRGB(245, 70, 70) },
    { name = "Gold",      accent = Color3.fromRGB(250, 165, 15) },
    { name = "Frost",     accent = Color3.fromRGB(10, 190, 220) },
    { name = "Inferno",   accent = Color3.fromRGB(255, 110, 55) },
}

local function applyTheme(accent)
    C.accent = accent; C.neonGlow = accent
    for _, el in ipairs(obj.themeElements) do pcall(function() if el.obj and el.prop then el.obj[el.prop] = accent end end) end
end

local CONFIG_FILE = "Medusa_Config.json"
local _saveQueued = false

local function saveConfig()
    if not XC.writefile then return end
    pcall(function()
        local data = {
            version = "13.9",
            accent = { C.accent.R, C.accent.G, C.accent.B },
            -- Aimbot settings
            aimbotFOV = cfg.aimbotFOV, aimSmooth = cfg.aimSmooth, aimbotPart = cfg.aimbotPart,
            maxDistance = cfg.maxDistance, triggerFOV = cfg.triggerFOV, triggerDelay = cfg.triggerDelay,
            predStrength = cfg.predStrength,
            -- Silent v2
            silentCurve = cfg.silentCurve, silentCurveStr = cfg.silentCurveStr,
            hitChanceHead = cfg.hitChanceHead, hitChanceTorso = cfg.hitChanceTorso,
            -- Checks
            teamCheck = cfg.teamCheck, visibleCheck = cfg.visibleCheck,
            healthCheck = cfg.healthCheck, healthMin = cfg.healthMin,
            -- ESP
            espRefreshRate = cfg.espRefreshRate, espDistance = cfg.espDistance,
            -- Hitbox
            hitboxSize = cfg.hitboxSize, hitboxTransparency = cfg.hitboxTransparency,
            -- Movement
            flySpeed = cfg.flySpeed, walkSpeed = cfg.walkSpeed, spinSpeed = cfg.spinSpeed,
            -- Crosshair
            crossStyle = cfg.crossStyle, crossSize = cfg.crossSize, crossGap = cfg.crossGap,
            -- RGB
            rgb = cfg.rgb,
            -- GUI
            gui = cfg.gui,
            -- Toggles
            toggles = {
                esp = st.esp, aimbot = st.aimbot, silentAim = st.silentAim,
                triggerBot = st.triggerBot, prediction = st.prediction,
                fly = st.fly, noclip = st.noclip, speed = st.speed,
                infJump = st.infJump, hitbox = st.hitbox, fullbright = st.fullbright,
                noFallDmg = st.noFallDmg, clickTP = st.clickTP, spinBot = st.spinBot,
                crosshair = st.crosshair, box3d = st.box3d, tracers = st.tracers,
                skeleton = st.skeleton, rainbow = st.rainbow,
                spectatorList = st.spectatorList, killPopup = st.killPopup, hitSound = st.hitSound,
                thName = st.thName, thHealth = st.thHealth, thWeapon = st.thWeapon,
                thDistance = st.thDistance, thLockStatus = st.thLockStatus,
                viewAngles = st.viewAngles, adminDetector = st.adminDetector, metatableBypass = st.metatableBypass,
            },
            -- Keybinds
            binds = {},
            -- Discord
            discordWebhook = cfg.discordWebhook, discordRPC = st.discordRPC,
        }
        for k, v in pairs(keybinds) do data.binds[k] = v.Name end
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
end

local function autoSave()
    if not cfg.autoSave or _saveQueued then return end
    _saveQueued = true
    task.delay(cfg.autoSaveDelay, function()
        _saveQueued = false
        saveConfig()
    end)
end

-- ══════════════════════════════════════════════════════════════
--  PROFILES SYSTEM (Multi-Config Management)
-- ══════════════════════════════════════════════════════════════
local PROFILES_DIR = "Medusa/Configs"
local function ensureProfileDir()
    pcall(function()
        if XC.makefolder then
            if not isfolder("Medusa") then makefolder("Medusa") end
            if not isfolder(PROFILES_DIR) then makefolder(PROFILES_DIR) end
        end
    end)
end
ensureProfileDir()

local function saveProfile(name)
    if not XC.writefile then Notify("❌ Error", "Executor does not support writefile", 3); return false end
    if not name or name == "" then Notify("❌ Error", "Profile name cannot be empty", 3); return false end
    ensureProfileDir()
    local safeName = name:gsub("[^%w%-%_]", "_")
    local path = PROFILES_DIR .. "/" .. safeName .. ".json"
    local ok, err = pcall(function()
        -- Reuse the same data structure as saveConfig
        local data = {
            profileName = name, version = "14.4", savedAt = os.time(),
            accent = { C.accent.R, C.accent.G, C.accent.B },
            aimbotFOV = cfg.aimbotFOV, aimSmooth = cfg.aimSmooth, aimbotPart = cfg.aimbotPart,
            maxDistance = cfg.maxDistance, triggerFOV = cfg.triggerFOV, triggerDelay = cfg.triggerDelay,
            predStrength = cfg.predStrength, silentCurve = cfg.silentCurve, silentCurveStr = cfg.silentCurveStr,
            hitChanceHead = cfg.hitChanceHead, hitChanceTorso = cfg.hitChanceTorso,
            teamCheck = cfg.teamCheck, visibleCheck = cfg.visibleCheck, healthCheck = cfg.healthCheck, healthMin = cfg.healthMin,
            espRefreshRate = cfg.espRefreshRate, espDistance = cfg.espDistance,
            hitboxSize = cfg.hitboxSize, hitboxTransparency = cfg.hitboxTransparency,
            flySpeed = cfg.flySpeed, walkSpeed = cfg.walkSpeed, spinSpeed = cfg.spinSpeed,
            crossStyle = cfg.crossStyle, crossSize = cfg.crossSize, crossGap = cfg.crossGap,
            rgb = cfg.rgb, gui = cfg.gui,
            toggles = {
                esp = st.esp, aimbot = st.aimbot, silentAim = st.silentAim, triggerBot = st.triggerBot,
                prediction = st.prediction, fly = st.fly, noclip = st.noclip, speed = st.speed,
                infJump = st.infJump, hitbox = st.hitbox, fullbright = st.fullbright,
                noFallDmg = st.noFallDmg, clickTP = st.clickTP, spinBot = st.spinBot,
                crosshair = st.crosshair, box3d = st.box3d, tracers = st.tracers, skeleton = st.skeleton,
                rainbow = st.rainbow, viewAngles = st.viewAngles, adminDetector = st.adminDetector,
                metatableBypass = st.metatableBypass, ghostMode = st.ghostMode,
            },
            binds = {},
            discordWebhook = cfg.discordWebhook, discordRPC = st.discordRPC,
        }
        for k, v in pairs(keybinds) do data.binds[k] = v.Name end
        writefile(path, HttpService:JSONEncode(data))
    end)
    if ok then
        Notify("💾 Profile Saved", "'" .. name .. "' saved successfully!", 3)
    else
        Notify("❌ Save Failed", tostring(err), 3)
    end
    return ok
end

local function loadProfile(name)
    if not XC.readfile then Notify("❌ Error", "Executor does not support readfile", 3); return false end
    local safeName = name:gsub("[^%w%-%_]", "_")
    local path = PROFILES_DIR .. "/" .. safeName .. ".json"
    local ok, err = pcall(function()
        if not isfile(path) then error("File not found: " .. path) end
        local raw = readfile(path)
        if not raw or raw == "" then error("Empty file") end
        local data = HttpService:JSONDecode(raw)
        if not data then error("Invalid JSON") end
        -- Apply all settings (same as loadConfig)
        if data.accent then C.accent = Color3.new(data.accent[1], data.accent[2], data.accent[3]); C.neonGlow = C.accent end
        if data.aimbotFOV then cfg.aimbotFOV = data.aimbotFOV end
        if data.aimSmooth then cfg.aimSmooth = data.aimSmooth end
        if data.aimbotPart then cfg.aimbotPart = data.aimbotPart end
        if data.maxDistance then cfg.maxDistance = data.maxDistance end
        if data.triggerFOV then cfg.triggerFOV = data.triggerFOV end
        if data.triggerDelay then cfg.triggerDelay = data.triggerDelay end
        if data.predStrength then cfg.predStrength = data.predStrength end
        if data.silentCurve ~= nil then cfg.silentCurve = data.silentCurve end
        if data.silentCurveStr then cfg.silentCurveStr = data.silentCurveStr end
        if data.hitChanceHead then cfg.hitChanceHead = data.hitChanceHead end
        if data.hitChanceTorso then cfg.hitChanceTorso = data.hitChanceTorso end
        if data.teamCheck ~= nil then cfg.teamCheck = data.teamCheck end
        if data.visibleCheck ~= nil then cfg.visibleCheck = data.visibleCheck end
        if data.healthCheck ~= nil then cfg.healthCheck = data.healthCheck end
        if data.healthMin then cfg.healthMin = data.healthMin end
        if data.espRefreshRate then cfg.espRefreshRate = data.espRefreshRate end
        if data.espDistance then cfg.espDistance = data.espDistance end
        if data.hitboxSize then cfg.hitboxSize = data.hitboxSize end
        if data.hitboxTransparency then cfg.hitboxTransparency = data.hitboxTransparency end
        if data.flySpeed then cfg.flySpeed = data.flySpeed end
        if data.walkSpeed then cfg.walkSpeed = data.walkSpeed end
        if data.spinSpeed then cfg.spinSpeed = data.spinSpeed end
        if data.crossStyle then cfg.crossStyle = data.crossStyle end
        if data.crossSize then cfg.crossSize = data.crossSize end
        if data.crossGap then cfg.crossGap = data.crossGap end
        if data.rgb then for k, v in pairs(data.rgb) do cfg.rgb[k] = v end end
        if data.gui then for k, v in pairs(data.gui) do cfg.gui[k] = v end end
        if data.discordWebhook then cfg.discordWebhook = data.discordWebhook end
        if data.toggles then for k, v in pairs(data.toggles) do if st[k] ~= nil then st[k] = v; pcall(function() syncToggleVisual(k, v) end) end end end
        if data.binds then for k, v in pairs(data.binds) do pcall(function() keybinds[k] = Enum.KeyCode[v] end) end end
        if data.discordRPC ~= nil then st.discordRPC = data.discordRPC end
    end)
    if ok then
        Notify("✅ Profile Loaded", "'" .. name .. "' applied! Restart recommended for full effect.", 4)
    else
        Notify("❌ Load Failed", tostring(err), 3)
    end
    return ok
end

local function deleteProfile(name)
    if not XC.writefile then return false end
    local safeName = name:gsub("[^%w%-%_]", "_")
    local path = PROFILES_DIR .. "/" .. safeName .. ".json"
    local ok = pcall(function()
        if XC.delfile and isfile(path) then delfile(path) end
    end)
    if ok then Notify("🗑️ Deleted", "Profile '" .. name .. "' removed.", 3) end
    return ok
end

local function listProfiles()
    local profiles = {}
    pcall(function()
        if XC.listfiles and isfolder(PROFILES_DIR) then
            for _, file in ipairs(listfiles(PROFILES_DIR)) do
                local fname = file:match("([^/\\]+)%.json$")
                if fname then table.insert(profiles, fname) end
            end
        end
    end)
    return profiles
end

local function loadConfig()
    if not XC.readfile or not XC.isfile then return false end
    local ok = pcall(function()
        if not isfile(CONFIG_FILE) then return end
        local raw = readfile(CONFIG_FILE)
        if not raw or raw == "" then return end
        local data = HttpService:JSONDecode(raw)
        if not data then return end
        -- Accent
        if data.accent then C.accent = Color3.new(data.accent[1], data.accent[2], data.accent[3]); C.neonGlow = C.accent end
        -- Aimbot
        if data.aimbotFOV then cfg.aimbotFOV = data.aimbotFOV end
        if data.aimSmooth then cfg.aimSmooth = data.aimSmooth end
        if data.aimbotPart then cfg.aimbotPart = data.aimbotPart end
        if data.maxDistance then cfg.maxDistance = data.maxDistance end
        if data.triggerFOV then cfg.triggerFOV = data.triggerFOV end
        if data.triggerDelay then cfg.triggerDelay = data.triggerDelay end
        if data.predStrength then cfg.predStrength = data.predStrength end
        -- Silent v2
        if data.silentCurve ~= nil then cfg.silentCurve = data.silentCurve end
        if data.silentCurveStr then cfg.silentCurveStr = data.silentCurveStr end
        if data.hitChanceHead then cfg.hitChanceHead = data.hitChanceHead end
        if data.hitChanceTorso then cfg.hitChanceTorso = data.hitChanceTorso end
        -- Checks
        if data.teamCheck ~= nil then cfg.teamCheck = data.teamCheck end
        if data.visibleCheck ~= nil then cfg.visibleCheck = data.visibleCheck end
        if data.healthCheck ~= nil then cfg.healthCheck = data.healthCheck end
        if data.healthMin then cfg.healthMin = data.healthMin end
        -- ESP
        if data.espRefreshRate then cfg.espRefreshRate = data.espRefreshRate end
        if data.espDistance then cfg.espDistance = data.espDistance end
        -- Hitbox
        if data.hitboxSize then cfg.hitboxSize = data.hitboxSize end
        if data.hitboxTransparency then cfg.hitboxTransparency = data.hitboxTransparency end
        -- Movement
        if data.flySpeed then cfg.flySpeed = data.flySpeed end
        if data.walkSpeed then cfg.walkSpeed = data.walkSpeed end
        if data.spinSpeed then cfg.spinSpeed = data.spinSpeed end
        -- Crosshair
        if data.crossStyle then cfg.crossStyle = data.crossStyle end
        if data.crossSize then cfg.crossSize = data.crossSize end
        if data.crossGap then cfg.crossGap = data.crossGap end
        -- RGB
        if data.rgb then for k, v in pairs(data.rgb) do cfg.rgb[k] = v end end
        -- GUI
        if data.gui then for k, v in pairs(data.gui) do cfg.gui[k] = v end end
        -- Discord
        if data.discordWebhook then cfg.discordWebhook = data.discordWebhook end
        if data.discordRPC ~= nil then st.discordRPC = data.discordRPC end
        -- Safe toggles (cosmetic/detection only — auto-restore)
        if data.toggles then
            if data.toggles.viewAngles ~= nil then st.viewAngles = data.toggles.viewAngles end
            if data.toggles.adminDetector ~= nil then st.adminDetector = data.toggles.adminDetector end
            if data.toggles.metatableBypass ~= nil then st.metatableBypass = data.toggles.metatableBypass end
        end
        -- Keybinds
        if data.binds then for k, name in pairs(data.binds) do pcall(function() keybinds[k] = Enum.KeyCode[name] end) end end
        -- Note: combat/movement toggles NOT auto-restored (safety)
    end)
    return ok
end
local configLoaded = loadConfig()
if configLoaded and XC.isfile and pcall(function() return isfile(CONFIG_FILE) end) then
    print("[Medusa] ✅ Config loaded from " .. CONFIG_FILE)
end

-- S6: GUI CREATION
local guiParent = playerGui
pcall(function()
    if gethui then guiParent = gethui()
    elseif getgenv and getgenv().gethui then guiParent = getgenv().gethui()
    elseif XC.cloneref then guiParent = cloneref(CoreGui)
    elseif CoreGui then local t = Instance.new("Folder"); t.Parent = CoreGui; t:Destroy(); guiParent = CoreGui end
end)

local function createGui(name)
    local sg = Instance.new("ScreenGui")
    sg.Name = name or ("Medusa_" .. math.random(100000, 999999))
    sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 2147483647; sg.IgnoreGuiInset = true
    local ok = pcall(function() sg.Parent = guiParent end)
    if not ok then pcall(function() sg.Parent = CoreGui end); if not sg.Parent then sg.Parent = playerGui end end
    pcall(function() if protect_gui then protect_gui(sg) elseif syn and syn.protect_gui then syn.protect_gui(sg) end end)
    return sg
end
local function spEnable() end
local function spDisable() end

-- ══════════════════════════════════════════════════════════════
--  S7: GLASS EDITION GUI FACTORIES
-- ══════════════════════════════════════════════════════════════
local CR = cfg.gui.cornerRadius

local function mkCorner(parent, radius)
    local c = Instance.new("UICorner", parent); c.CornerRadius = UDim.new(0, radius or CR); return c
end

local function mkCard(parent, height, order)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, height)
    c.BackgroundColor3 = C.glass; c.BackgroundTransparency = 0.35
    c.BorderSizePixel = 0; c.LayoutOrder = order or 0
    c.ClipsDescendants = false; c.Parent = parent
    mkCorner(c, CR)
    local sk = Instance.new("UIStroke", c)
    sk.Color = C.border; sk.Thickness = 1; sk.Transparency = 0.55
    -- Inner glow gradient
    local grad = Instance.new("UIGradient", c)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25)),
    })
    grad.Rotation = 135
    return c
end

local function mkLabel(parent, text, size, color, x, y, w, h)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(w or 1, w == 1 and -20 or 0, 0, h or 20)
    l.Position = UDim2.new(0, x or 10, 0, y or 8)
    l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamSemibold
    l.TextSize = size or cfg.gui.fontSize; l.TextColor3 = color or C.textMuted
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Text = text; l.Parent = parent
    return l
end

local function mkSep(parent, order)
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1, -20, 0, 1); s.Position = UDim2.new(0, 10, 0, 0)
    s.BackgroundColor3 = C.border; s.BackgroundTransparency = 0.6
    s.BorderSizePixel = 0; s.LayoutOrder = order or 0; s.Parent = parent
    return s
end

-- ── GLASS TOGGLE ───────────────────────────────────────────
local function mkToggle(parent, text, default, order, callback)
    local TW, TH = cfg.gui.toggleW, cfg.gui.toggleH

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = C.glassHi; row.BackgroundTransparency = 0.88
    row.BorderSizePixel = 0; row.LayoutOrder = order or 0; row.Parent = parent
    mkCorner(row, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 0, 34); lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = cfg.gui.fontSize; lbl.TextColor3 = C.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = text; lbl.Parent = row

    -- Glass track with inner shadow
    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, TW, 0, TH)
    track.Position = UDim2.new(1, -(TW + 12), 0.5, -TH / 2)
    track.BackgroundColor3 = default and C.accent or C.toggleOff
    track.BackgroundTransparency = default and 0.15 or 0.3
    track.BorderSizePixel = 0; track.Parent = row
    mkCorner(track, TH / 2)

    -- Neon glow aura (only visible when ON)
    local glow = Instance.new("UIStroke", track)
    glow.Color = C.accent; glow.Thickness = default and 2.5 or 0; glow.Transparency = default and 0.25 or 1

    local knobSize = TH - 4
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, knobSize, 0, knobSize)
    knob.Position = default and UDim2.new(1, -(knobSize + 2), 0.5, -knobSize / 2) or UDim2.new(0, 2, 0.5, -knobSize / 2)
    knob.BackgroundColor3 = Color3.new(1, 1, 1); knob.BorderSizePixel = 0; knob.ZIndex = 2; knob.Parent = track
    mkCorner(knob, knobSize / 2)
    -- Knob inner glow
    local knobGlow = Instance.new("UIStroke", knob)
    knobGlow.Color = default and C.accent or Color3.fromRGB(80, 80, 80)
    knobGlow.Thickness = 1.5; knobGlow.Transparency = 0.3

    local on = default
    local function setVisual(state)
        on = state
        local posX = state and 1 or 0
        local offX = state and -(knobSize + 2) or 2
        TS:Create(knob, TweenInfo.new(0.28, Enum.EasingStyle.Back), {
            Position = UDim2.new(posX, offX, 0.5, -knobSize / 2)
        }):Play()
        TS:Create(track, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {
            BackgroundColor3 = state and C.accent or C.toggleOff,
            BackgroundTransparency = state and 0.15 or 0.3,
        }):Play()
        TS:Create(glow, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            Thickness = state and 2.5 or 0, Transparency = state and 0.25 or 1, Color = C.accent,
        }):Play()
        TS:Create(knobGlow, TweenInfo.new(0.25), {
            Color = state and C.accent or Color3.fromRGB(80, 80, 80),
        }):Play()
        TS:Create(lbl, TweenInfo.new(0.2), {
            TextColor3 = state and Color3.new(1, 1, 1) or C.text
        }):Play()
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1
    btn.Text = ""; btn.ZIndex = 3; btn.Parent = row

    -- Hover: scale effect + glass highlight
    btn.MouseEnter:Connect(function()
        TS:Create(row, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            BackgroundTransparency = 0.65,
            Size = UDim2.new(1, 2, 0, 36),
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(row, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
            BackgroundTransparency = 0.88,
            Size = UDim2.new(1, 0, 0, 34),
        }):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        on = not on; setVisual(on)
        if on then playToggleOn() else playToggleOff() end
        TS:Create(row, TweenInfo.new(0.06), { BackgroundTransparency = 0.3 }):Play()
        task.delay(0.12, function() TS:Create(row, TweenInfo.new(0.18), { BackgroundTransparency = 0.88 }):Play() end)
        if callback then callback(on) end
    end)

    table.insert(obj.themeElements, { obj = track, prop = "BackgroundColor3", condition = function() return on end })
    table.insert(obj.themeElements, { obj = glow, prop = "Color" })
    return setVisual
end

local function mkSyncToggle(parent, text, stateKey, order, extraCallback)
    local setVisual = mkToggle(parent, text, st[stateKey], order, function(on)
        st[stateKey] = on; if extraCallback then extraCallback(on) end
    end)
    obj.toggleRegistry[stateKey] = { setVisual = setVisual, knob = nil }
    -- Try to find the knob in the toggle we just created
    pcall(function()
        local lastRow = parent:FindFirstChildWhichIsA("Frame", true)
        if lastRow then
            local track = nil
            for _, c in ipairs(lastRow:GetChildren()) do
                if c:IsA("Frame") and c:FindFirstChild("Frame") then track = c; break end
            end
            if track then
                for _, c in ipairs(track:GetChildren()) do
                    if c:IsA("Frame") and c.ZIndex == 2 then
                        obj.toggleRegistry[stateKey].knob = c; break
                    end
                end
            end
        end
    end)
    return setVisual
end

local function syncToggleVisual(key, on)
    local reg = obj.toggleRegistry[key]; if reg and reg.setVisual then pcall(function() reg.setVisual(on) end) end
end

-- ── GLASS SLIDER ───────────────────────────────────────────
local function mkSlider(parent, text, initVal, minV, maxV, order, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 48)
    row.BackgroundColor3 = C.glassHi; row.BackgroundTransparency = 0.88
    row.BorderSizePixel = 0; row.LayoutOrder = order or 0
    row.ClipsDescendants = false; row.Parent = parent
    mkCorner(row, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 0, 18); lbl.Position = UDim2.new(0, 14, 0, 3)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = cfg.gui.fontSize; lbl.TextColor3 = C.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = text; lbl.Parent = row

    -- Glass value badge
    local valBadge = Instance.new("TextLabel")
    valBadge.Size = UDim2.new(0, 46, 0, 18); valBadge.Position = UDim2.new(1, -56, 0, 2)
    valBadge.BackgroundColor3 = C.accent; valBadge.BackgroundTransparency = 0.78
    valBadge.BorderSizePixel = 0; valBadge.Font = Enum.Font.GothamBold
    valBadge.TextSize = 10; valBadge.TextColor3 = C.accent
    valBadge.Text = tostring(initVal); valBadge.Parent = row
    mkCorner(valBadge, 6)
    local vbSk = Instance.new("UIStroke", valBadge); vbSk.Color = C.accent; vbSk.Thickness = 1; vbSk.Transparency = 0.6
    table.insert(obj.themeElements, { obj = valBadge, prop = "TextColor3" })
    table.insert(obj.themeElements, { obj = valBadge, prop = "BackgroundColor3" })
    table.insert(obj.themeElements, { obj = vbSk, prop = "Color" })

    -- Frosted track
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, cfg.gui.sliderH)
    track.Position = UDim2.new(0, 14, 0, 28)
    track.BackgroundColor3 = C.sliderTrack; track.BackgroundTransparency = 0.3
    track.BorderSizePixel = 0; track.ClipsDescendants = false; track.Parent = row
    mkCorner(track, cfg.gui.sliderH / 2)

    local pct = math.clamp((initVal - minV) / (maxV - minV), 0, 1)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = C.accent; fill.BackgroundTransparency = 0.15
    fill.BorderSizePixel = 0; fill.Parent = track
    mkCorner(fill, cfg.gui.sliderH / 2)
    table.insert(obj.themeElements, { obj = fill, prop = "BackgroundColor3" })
    -- Neon glow on fill
    local fillGlow = Instance.new("UIStroke", fill)
    fillGlow.Color = C.accent; fillGlow.Thickness = 1; fillGlow.Transparency = 0.5
    table.insert(obj.themeElements, { obj = fillGlow, prop = "Color" })

    -- Glass knob with glow
    local knobSize = cfg.gui.sliderH + 8
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, knobSize, 0, knobSize)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(pct, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BackgroundTransparency = 0.05
    knob.BorderSizePixel = 0; knob.ZIndex = 10; knob.Parent = track
    mkCorner(knob, knobSize / 2)
    local ksk = Instance.new("UIStroke", knob); ksk.Color = C.accent; ksk.Thickness = 2.5; ksk.Transparency = 0.1
    table.insert(obj.themeElements, { obj = ksk, prop = "Color" })

    local dragging = false
    local function applyPos(mouseX)
        local bx = track.AbsolutePosition.X; local bw = track.AbsoluteSize.X
        if bw <= 0 then return end
        local p = math.clamp((mouseX - bx) / bw, 0, 1)
        local val = math.floor(minV + p * (maxV - minV))
        TS:Create(fill, TweenInfo.new(0.08, Enum.EasingStyle.Quint), { Size = UDim2.new(p, 0, 1, 0) }):Play()
        TS:Create(knob, TweenInfo.new(0.08, Enum.EasingStyle.Quint), { Position = UDim2.new(p, 0, 0.5, 0) }):Play()
        valBadge.Text = tostring(val)
        if callback then callback(val) end
    end

    track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; applyPos(i.Position.X) end end)
    knob.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    addConn(UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then applyPos(i.Position.X) end end))
    addConn(UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end))

    row.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then TS:Create(row, TweenInfo.new(0.15), { BackgroundTransparency = 0.65 }):Play() end end)
    row.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then TS:Create(row, TweenInfo.new(0.15), { BackgroundTransparency = 0.88 }):Play() end end)
    return lbl, valBadge
end

-- ── GLASS BUTTON ───────────────────────────────────────────
local function mkBtn(parent, text, color, order, callback)
    local ac = color or C.accent
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, cfg.gui.btnH)
    btn.LayoutOrder = order or 0
    btn.BackgroundColor3 = C.glass; btn.BackgroundTransparency = 0.55
    btn.BorderSizePixel = 0; btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamBold; btn.TextSize = cfg.gui.fontSize
    btn.TextColor3 = C.text; btn.Text = text; btn.Parent = parent
    mkCorner(btn, 10)
    -- Left neon bar
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0.5, 0); bar.Position = UDim2.new(0, 0, 0.25, 0)
    bar.BackgroundColor3 = ac; bar.BorderSizePixel = 0; bar.Parent = btn
    mkCorner(bar, 2)
    -- Glass border
    local sk = Instance.new("UIStroke", btn); sk.Color = ac; sk.Thickness = 1; sk.Transparency = 0.7
    -- Hover: glass highlight + bar expand
    btn.MouseEnter:Connect(function()
        TS:Create(sk, TweenInfo.new(0.18, Enum.EasingStyle.Quint), { Transparency = 0.15, Thickness = 1.5 }):Play()
        TS:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quint), { BackgroundTransparency = 0.25 }):Play()
        TS:Create(bar, TweenInfo.new(0.18, Enum.EasingStyle.Quint), { Size = UDim2.new(0, 4, 0.8, 0), Position = UDim2.new(0, 0, 0.1, 0) }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(sk, TweenInfo.new(0.18, Enum.EasingStyle.Quint), { Transparency = 0.7, Thickness = 1 }):Play()
        TS:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quint), { BackgroundTransparency = 0.55 }):Play()
        TS:Create(bar, TweenInfo.new(0.18, Enum.EasingStyle.Quint), { Size = UDim2.new(0, 3, 0.5, 0), Position = UDim2.new(0, 0, 0.25, 0) }):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        playClick()
        TS:Create(btn, TweenInfo.new(0.06), { BackgroundTransparency = 0.08 }):Play()
        TS:Create(sk, TweenInfo.new(0.06), { Transparency = 0, Thickness = 2.5 }):Play()
        task.delay(0.15, function()
            TS:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { BackgroundTransparency = 0.55 }):Play()
            TS:Create(sk, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { Transparency = 0.7, Thickness = 1 }):Play()
        end)
        if callback then callback() end
    end)
    return btn
end

local function mkPartSelector(parent, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34); row.BackgroundTransparency = 1
    row.LayoutOrder = order or 0; row.Parent = parent
    mkLabel(row, "Hit Part", cfg.gui.fontSize, C.textMuted, 10, 7)
    local parts = { "Head", "Torso", "Random" }; local btns = {}; local bw = 68
    for i, nm in ipairs(parts) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, bw, 0, 26)
        b.Position = UDim2.new(1, -(bw * (#parts - i + 1) + 6 * (#parts - i) + 10), 0, 4)
        b.BackgroundColor3 = nm == cfg.aimbotPart and C.accent or C.glass
        b.BackgroundTransparency = nm == cfg.aimbotPart and 0.25 or 0.6
        b.BorderSizePixel = 0; b.AutoButtonColor = false; b.Font = Enum.Font.GothamBold
        b.TextSize = 11; b.TextColor3 = nm == cfg.aimbotPart and C.accent or C.textMuted
        b.Text = nm; b.Parent = row; mkCorner(b, 8)
        local bsk = Instance.new("UIStroke", b); bsk.Color = nm == cfg.aimbotPart and C.accent or C.border
        bsk.Thickness = 1; bsk.Transparency = nm == cfg.aimbotPart and 0.2 or 0.6
        btns[nm] = { btn = b, sk = bsk }
        b.MouseButton1Click:Connect(function()
            cfg.aimbotPart = nm
            for n, bb in pairs(btns) do
                local active = n == nm
                TS:Create(bb.btn, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                    BackgroundTransparency = active and 0.25 or 0.6, TextColor3 = active and C.accent or C.textMuted,
                }):Play()
                TS:Create(bb.sk, TweenInfo.new(0.2), { Color = active and C.accent or C.border, Transparency = active and 0.2 or 0.6 }):Play()
            end
        end)
    end
    return row
end

-- ══════════════════════════════════════════════════════════════
--  S8: GLASS NOTIFICATION SYSTEM
-- ══════════════════════════════════════════════════════════════
local notifStack = {}
local MAX_NOTIFS = 5

-- Premium Notification System v15.1
-- Notify(title, text, duration) OR notify(text, color) (backwards compatible)
local function Notify(titleOrText, textOrColor, durationOrNil)
    local title, text, color, duration
    -- Backwards compatibility: notify(text, color) still works
    if type(textOrColor) == "userdata" or textOrColor == nil then
        title = "🐍 MEDUSA"
        text = tostring(titleOrText)
        color = textOrColor or C.accent
        duration = durationOrNil or 3.5
    else
        title = tostring(titleOrText)
        text = tostring(textOrColor)
        color = C.accent
        duration = durationOrNil or 4
    end

    local sg = createGui("MedusaNotif")
    local fr = Instance.new("Frame")
    fr.Size = UDim2.new(0, 340, 0, 78)
    fr.Position = UDim2.new(1, 360, 1, -90 - (#notifStack * 86))
    fr.BackgroundColor3 = C.glass; fr.BackgroundTransparency = 0.06
    fr.BorderSizePixel = 0; fr.Parent = sg
    mkCorner(fr, 12)
    
    -- Toast stroke — uses accent color with rainbow support
    local sk = Instance.new("UIStroke", fr); sk.Color = color; sk.Thickness = 1.5; sk.Transparency = 0.1
    -- Register for rainbow if RGB is on
    if cfg.rgb.stroke then
        table.insert(obj.rgbElements, { obj = sk, prop = "Color", type = "stroke" })
    end

    -- Glass gradient (premium)
    local grad = Instance.new("UIGradient", fr)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 40)),
        ColorSequenceKeypoint.new(0.5, C.glass),
        ColorSequenceKeypoint.new(1, C.bg)
    })
    grad.Rotation = 145

    -- Left accent neon bar (animated — grows in from top)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0, 0); bar.Position = UDim2.new(0, 8, 0.1, 0)
    bar.BackgroundColor3 = color; bar.BorderSizePixel = 0; bar.Parent = fr
    mkCorner(bar, 2)
    TS:Create(bar, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 3, 0.8, 0)
    }):Play()

    -- Neon glow behind bar
    local barGlow = Instance.new("Frame")
    barGlow.Size = UDim2.new(0, 14, 0.8, 0); barGlow.Position = UDim2.new(0, 4, 0.1, 0)
    barGlow.BackgroundColor3 = color; barGlow.BackgroundTransparency = 0.75
    barGlow.BorderSizePixel = 0; barGlow.ZIndex = 0; barGlow.Parent = fr
    mkCorner(barGlow, 6)

    -- Icon circle (accent colored dot)
    local iconDot = Instance.new("Frame")
    iconDot.Size = UDim2.new(0, 6, 0, 6); iconDot.Position = UDim2.new(0, 20, 0, 12)
    iconDot.BackgroundColor3 = color; iconDot.BorderSizePixel = 0; iconDot.Parent = fr
    mkCorner(iconDot, 3)

    -- Title label (bold + icon)
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -44, 0, 16); titleLbl.Position = UDim2.new(0, 30, 0, 8)
    titleLbl.BackgroundTransparency = 1; titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 11; titleLbl.TextColor3 = color
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Text = title; titleLbl.Parent = fr

    -- Main text (message)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -44, 0, 22); lbl.Position = UDim2.new(0, 30, 0, 26)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13; lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextWrapped = true
    lbl.Text = text; lbl.Parent = fr

    -- Timestamp + version
    local timeLbl = Instance.new("TextLabel")
    timeLbl.Size = UDim2.new(1, -44, 0, 12); timeLbl.Position = UDim2.new(0, 30, 0, 50)
    timeLbl.BackgroundTransparency = 1; timeLbl.Font = Enum.Font.Gotham
    timeLbl.TextSize = 9; timeLbl.TextColor3 = C.textMuted
    timeLbl.TextXAlignment = Enum.TextXAlignment.Left
    timeLbl.Text = "MEDUSA v15.1 • " .. os.date("%H:%M:%S"); timeLbl.Parent = fr

    -- Progress bar (premium — glass track + colored fill that shrinks)
    local progTrack = Instance.new("Frame")
    progTrack.Size = UDim2.new(1, -24, 0, 3); progTrack.Position = UDim2.new(0, 12, 1, -8)
    progTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 50); progTrack.BackgroundTransparency = 0.4
    progTrack.BorderSizePixel = 0; progTrack.Parent = fr
    mkCorner(progTrack, 2)

    local progFill = Instance.new("Frame")
    progFill.Size = UDim2.new(1, 0, 1, 0)
    progFill.BackgroundColor3 = color; progFill.BackgroundTransparency = 0.15
    progFill.BorderSizePixel = 0; progFill.Parent = progTrack
    mkCorner(progFill, 2)
    TS:Create(progFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) }):Play()

    -- Close button (X) with hover
    local closeN = Instance.new("TextButton")
    closeN.Size = UDim2.new(0, 22, 0, 22); closeN.Position = UDim2.new(1, -28, 0, 4)
    closeN.BackgroundTransparency = 1; closeN.Font = Enum.Font.GothamBold
    closeN.TextSize = 14; closeN.TextColor3 = C.textMuted; closeN.Text = "×"
    closeN.AutoButtonColor = false; closeN.Parent = fr
    closeN.MouseEnter:Connect(function() TS:Create(closeN, TweenInfo.new(0.15), { TextColor3 = C.error }):Play() end)
    closeN.MouseLeave:Connect(function() TS:Create(closeN, TweenInfo.new(0.15), { TextColor3 = C.textMuted }):Play() end)

    -- Stack management
    table.insert(notifStack, { gui = sg, frame = fr })
    if #notifStack > MAX_NOTIFS then local old = table.remove(notifStack, 1); pcall(function() old.gui:Destroy() end) end
    for i, n in ipairs(notifStack) do
        TS:Create(n.frame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
            Position = UDim2.new(1, -360, 1, -90 - ((#notifStack - i) * 86))
        }):Play()
    end
    -- Slide in from right (premium elastic bounce)
    fr:TweenPosition(UDim2.new(1, -360, 1, -90), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.5, true)

    -- Auto-dismiss function (premium slide-out + fade)
    local function dismissNotif()
        -- Slide out to the right with fade
        TS:Create(fr, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 380, fr.Position.Y.Scale, fr.Position.Y.Offset),
            BackgroundTransparency = 1,
        }):Play()
        TS:Create(sk, TweenInfo.new(0.35), { Transparency = 1 }):Play()
        TS:Create(bar, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        TS:Create(barGlow, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        task.wait(0.5)
        for i, n in ipairs(notifStack) do if n.gui == sg then table.remove(notifStack, i); break end end
        -- Restack remaining with smooth animation
        for i, n in ipairs(notifStack) do
            TS:Create(n.frame, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {
                Position = UDim2.new(1, -360, 1, -90 - ((#notifStack - i) * 86))
            }):Play()
        end
        pcall(function() sg:Destroy() end)
    end

    -- Close button click
    closeN.MouseButton1Click:Connect(function() task.spawn(dismissNotif) end)
    -- Auto-dismiss after duration
    task.delay(duration, function() if sg and sg.Parent then dismissNotif() end end)
end
-- Backwards compatible alias
local notify = Notify

-- ══════════════════════════════════════════════════════════════
--  S8B: DYNAMIC BLUR SYSTEM (Glassmorphism Real)
-- ══════════════════════════════════════════════════════════════
local blurEffect = nil
local function showBlur()
    pcall(function()
        if blurEffect and blurEffect.Parent then return end -- already visible
        blurEffect = Instance.new("BlurEffect")
        blurEffect.Name = "MedusaBlur"
        blurEffect.Size = 0
        blurEffect.Parent = Lighting
        TS:Create(blurEffect, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { Size = 15 }):Play()
    end)
end
local function hideBlur()
    pcall(function()
        if blurEffect and blurEffect.Parent then
            TS:Create(blurEffect, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { Size = 0 }):Play()
            task.delay(0.5, function()
                pcall(function() if blurEffect then blurEffect:Destroy(); blurEffect = nil end end)
            end)
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
--  S9: SMOOTH DRAG SYSTEM
-- ══════════════════════════════════════════════════════════════
local function makeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = i.Position; startPos = target.Position end end)
    handle.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    addConn(UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            TS:Create(target, TweenInfo.new(0.08, Enum.EasingStyle.Quint), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            }):Play()
        end
    end))
end

-- ══════════════════════════════════════════════════════════════
--  S10: GLASS MAIN GUI
-- ══════════════════════════════════════════════════════════════
local screenGui = createGui("MedusaMain")
obj.wmGui = screenGui

-- (Shadow REMOVED — was causing giant rainbow square bug)

-- Frosted glass panel
local panel = Instance.new("Frame")
panel.Name = "MedusaPanel"
panel.Size = UDim2.new(0, cfg.gui.panelW, 0, cfg.gui.panelH)
panel.Position = UDim2.new(1, -(cfg.gui.panelW + 24), 0.5, -cfg.gui.panelH / 2)
panel.BackgroundColor3 = C.bg; panel.BackgroundTransparency = cfg.gui.panelOpacity
panel.BorderSizePixel = 0; panel.ClipsDescendants = true; panel.ZIndex = 1; panel.Parent = screenGui
mkCorner(panel, CR)
obj.panel = panel

-- Neon border glow
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color = C.accent; panelStroke.Thickness = 2; panelStroke.Transparency = 0.2
table.insert(obj.rgbElements, { obj = panelStroke, prop = "Color", type = "stroke" })
table.insert(obj.themeElements, { obj = panelStroke, prop = "Color" })

-- Glass gradient overlay
local panelGrad = Instance.new("UIGradient", panel)
panelGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 28)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12, 12, 20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 14)),
})
panelGrad.Rotation = 145

-- ── Glass Sidebar (ScrollingFrame for many tabs) ──────────
local sidebarOuter = Instance.new("Frame")
sidebarOuter.Size = UDim2.new(0, cfg.gui.sidebarW, 1, 0)
sidebarOuter.BackgroundColor3 = C.sidebar; sidebarOuter.BackgroundTransparency = 0.25
sidebarOuter.BorderSizePixel = 0; sidebarOuter.ZIndex = 3; sidebarOuter.ClipsDescendants = true
sidebarOuter.Parent = panel

local sideGrad = Instance.new("UIGradient", sidebarOuter)
sideGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 24)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 14)),
})
sideGrad.Rotation = 180

-- Scrollable inner container for tab buttons
local sidebar = Instance.new("ScrollingFrame")
sidebar.Size = UDim2.new(1, 0, 1, -cfg.gui.topbarH)
sidebar.Position = UDim2.new(0, 0, 0, cfg.gui.topbarH)
sidebar.BackgroundTransparency = 1; sidebar.BorderSizePixel = 0
sidebar.ScrollBarThickness = 0; sidebar.ScrollingEnabled = true
sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
sidebar.ScrollingDirection = Enum.ScrollingDirection.Y
sidebar.ZIndex = 3; sidebar.Parent = sidebarOuter
obj.sidebar = sidebarOuter -- store outer for theme changes

local sidebarLine = Instance.new("Frame")
sidebarLine.Size = UDim2.new(0, 1, 1, 0); sidebarLine.Position = UDim2.new(1, 0, 0, 0)
sidebarLine.BackgroundColor3 = C.border; sidebarLine.BackgroundTransparency = 0.45
sidebarLine.BorderSizePixel = 0; sidebarLine.ZIndex = 3; sidebarLine.Parent = sidebarOuter

-- UIListLayout for tab buttons in sidebar (MANDATORY for non-overlapping)
local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Padding = UDim.new(0, 5)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local sidePad = Instance.new("UIPadding", sidebar)
sidePad.PaddingTop = UDim.new(0, 5); sidePad.PaddingBottom = UDim.new(0, 5)
sidePad.PaddingLeft = UDim.new(0, 2); sidePad.PaddingRight = UDim.new(0, 2)

-- Tab indicator with glow (inside scrollable sidebar)
local tabIndicator = Instance.new("Frame")
tabIndicator.Size = UDim2.new(0, 3, 0, 28)
tabIndicator.Position = UDim2.new(0, 0, 0, 10)
tabIndicator.BackgroundColor3 = C.accent; tabIndicator.BorderSizePixel = 0; tabIndicator.ZIndex = 5; tabIndicator.Parent = sidebar
mkCorner(tabIndicator, 2)
local indGlow = Instance.new("UIStroke", tabIndicator); indGlow.Color = C.accent; indGlow.Thickness = 3; indGlow.Transparency = 0.5
table.insert(obj.rgbElements, { obj = tabIndicator, prop = "BackgroundColor3", type = "indicator" })
table.insert(obj.rgbElements, { obj = indGlow, prop = "Color", type = "indicator" })
table.insert(obj.themeElements, { obj = tabIndicator, prop = "BackgroundColor3" })
table.insert(obj.themeElements, { obj = indGlow, prop = "Color" })

-- ── Glass Topbar ───────────────────────────────────────────
local topbar = Instance.new("Frame")
topbar.Size = UDim2.new(1, -cfg.gui.sidebarW, 0, cfg.gui.topbarH)
topbar.Position = UDim2.new(0, cfg.gui.sidebarW, 0, 0)
topbar.BackgroundColor3 = C.topbar; topbar.BackgroundTransparency = 0.15
topbar.BorderSizePixel = 0; topbar.ZIndex = 4; topbar.Parent = panel
obj.topbar = topbar

local topGrad = Instance.new("UIGradient", topbar)
topGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 18)),
})
topGrad.Rotation = 90

local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1, 0, 0, 1); topLine.Position = UDim2.new(0, 0, 1, 0)
topLine.BackgroundColor3 = C.accent; topLine.BackgroundTransparency = 0.65
topLine.BorderSizePixel = 0; topLine.ZIndex = 4; topLine.Parent = topbar

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0, 160, 1, 0); titleLbl.Position = UDim2.new(0, 14, 0, 0)
titleLbl.BackgroundTransparency = 1; titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = cfg.gui.titleSize; titleLbl.TextColor3 = C.accent
titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Text = "🐍 MEDUSA"
titleLbl.ZIndex = 5; titleLbl.Parent = topbar
table.insert(obj.rgbElements, { obj = titleLbl, prop = "TextColor3", type = "title" })
table.insert(obj.themeElements, { obj = titleLbl, prop = "TextColor3" })

-- Version badge
local verBadge = Instance.new("TextLabel")
verBadge.Size = UDim2.new(0, 48, 0, 18); verBadge.Position = UDim2.new(0, 148, 0.5, -9)
verBadge.BackgroundColor3 = C.accent; verBadge.BackgroundTransparency = 0.8
verBadge.BorderSizePixel = 0; verBadge.Font = Enum.Font.GothamBold
verBadge.TextSize = 9; verBadge.TextColor3 = C.accent; verBadge.Text = "v15.1"
verBadge.ZIndex = 5; verBadge.Parent = topbar; mkCorner(verBadge, 6)
table.insert(obj.themeElements, { obj = verBadge, prop = "TextColor3" })
table.insert(obj.themeElements, { obj = verBadge, prop = "BackgroundColor3" })

obj.fpsPingLabel = Instance.new("TextLabel")
obj.fpsPingLabel.Size = UDim2.new(0, 110, 1, 0)
obj.fpsPingLabel.Position = UDim2.new(1, -175, 0, 0)
obj.fpsPingLabel.BackgroundTransparency = 1; obj.fpsPingLabel.Font = Enum.Font.Gotham
obj.fpsPingLabel.TextSize = 10; obj.fpsPingLabel.TextColor3 = C.textMuted
obj.fpsPingLabel.TextXAlignment = Enum.TextXAlignment.Right
obj.fpsPingLabel.Text = "-- FPS | --ms"; obj.fpsPingLabel.ZIndex = 5; obj.fpsPingLabel.Parent = topbar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 30); minBtn.Position = UDim2.new(1, -68, 0.5, -15)
minBtn.BackgroundTransparency = 1; minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 18; minBtn.TextColor3 = C.textMuted; minBtn.Text = "—"; minBtn.ZIndex = 6; minBtn.Parent = topbar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30); closeBtn.Position = UDim2.new(1, -36, 0.5, -15)
closeBtn.BackgroundTransparency = 1; closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16; closeBtn.TextColor3 = C.error; closeBtn.Text = "×"; closeBtn.ZIndex = 6; closeBtn.Parent = topbar

makeDraggable(topbar, panel)

-- Tab definitions
local TABS = {
    { id = "status", icon = "📊" }, { id = "aimbot", icon = "🎯" },
    { id = "visuals", icon = "👁️" }, { id = "movement", icon = "🏃" },
    { id = "combat", icon = "⚔️" }, { id = "players", icon = "👥" },
    { id = "misc", icon = "🔧" }, { id = "binds", icon = "🎮" },
    { id = "style", icon = "🎨" }, { id = "gui", icon = "🖥️" },
}

-- Create tab buttons and scroll frames
for i, tab in ipairs(TABS) do
    local tbtn = Instance.new("TextButton")
    tbtn.Size = UDim2.new(1, -4, 0, 38)
    tbtn.LayoutOrder = i
    tbtn.BackgroundTransparency = 1; tbtn.BorderSizePixel = 0
    tbtn.Font = Enum.Font.Unknown
    tbtn.TextSize = 20; tbtn.TextColor3 = C.textMuted; tbtn.Text = tab.icon
    tbtn.ZIndex = 5; tbtn.Parent = sidebar
    tbtn.AutoButtonColor = false

    local tooltip = Instance.new("TextLabel")
    tooltip.Size = UDim2.new(0, 75, 0, 24); tooltip.Position = UDim2.new(1, 10, 0.5, -12)
    tooltip.BackgroundColor3 = C.glass; tooltip.BackgroundTransparency = 0.1
    tooltip.BorderSizePixel = 0; tooltip.Font = Enum.Font.GothamSemibold
    tooltip.TextSize = 10; tooltip.TextColor3 = C.text; tooltip.Text = tab.id:upper()
    tooltip.ZIndex = 20; tooltip.Visible = false; tooltip.Parent = tbtn; mkCorner(tooltip, 6)
    local ttSk = Instance.new("UIStroke", tooltip); ttSk.Color = C.accent; ttSk.Thickness = 1; ttSk.Transparency = 0.4

    tbtn.MouseEnter:Connect(function()
        tooltip.Visible = true
        TS:Create(tbtn, TweenInfo.new(0.12, Enum.EasingStyle.Quint), { TextColor3 = C.accent }):Play()
    end)
    tbtn.MouseLeave:Connect(function()
        tooltip.Visible = false
        if obj.currentTab ~= tab.id then TS:Create(tbtn, TweenInfo.new(0.12), { TextColor3 = C.textMuted }):Play() end
    end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -(cfg.gui.sidebarW + 8), 1, -(cfg.gui.topbarH + 4))
    scroll.Position = UDim2.new(0, cfg.gui.sidebarW + 4, 0, cfg.gui.topbarH + 2)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3; scroll.ScrollBarImageColor3 = C.accent
    scroll.ScrollBarImageTransparency = 0.4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Visible = (i == 1); scroll.ZIndex = 2; scroll.Parent = panel

    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingLeft = UDim.new(0, 6); pad.PaddingRight = UDim.new(0, 6)
    pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 10)
    Instance.new("UIListLayout", scroll).Padding = UDim.new(0, cfg.gui.cardSpacing)
    scroll:FindFirstChild("UIListLayout").SortOrder = Enum.SortOrder.LayoutOrder

    obj.tabFrames[tab.id] = scroll
    tbtn.MouseButton1Click:Connect(function() if obj.switchTab then obj.switchTab(tab.id) end end)
end

-- ── Slide Transition switchTab ─────────────────────────────
local function switchTab(id)
    playTab()
    local prevTab = obj.currentTab
    obj.currentTab = id
    for _, tab in ipairs(TABS) do
        local frame = obj.tabFrames[tab.id]
        if frame then
            if tab.id == id then
                frame.Visible = true; frame.Position = UDim2.new(0.15, cfg.gui.sidebarW + 4, 0, cfg.gui.topbarH + 2)
                pcall(function() frame.CanvasPosition = Vector2.zero end)
                TS:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                    Position = UDim2.new(0, cfg.gui.sidebarW + 4, 0, cfg.gui.topbarH + 2)
                }):Play()
            elseif tab.id == prevTab then
                TS:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                    Position = UDim2.new(-0.15, cfg.gui.sidebarW + 4, 0, cfg.gui.topbarH + 2)
                }):Play()
                task.delay(0.22, function() frame.Visible = false end)
            else
                frame.Visible = false
            end
        end
    end
    for i, tab in ipairs(TABS) do
        if tab.id == id then
            -- Position relative to sidebar scroll container (no topbarH offset)
            local yPos = (i - 1) * cfg.gui.sidebarW + (cfg.gui.sidebarW / 2) - 14
            TS:Create(tabIndicator, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
                Position = UDim2.new(0, 0, 0, yPos)
            }):Play()
            -- Auto-scroll sidebar to show the active tab
            pcall(function()
                local maxScroll = sidebar.AbsoluteCanvasSize.Y - sidebar.AbsoluteSize.Y
                if maxScroll > 0 then
                    local scrollTo = math.clamp(yPos - sidebar.AbsoluteSize.Y / 2, 0, maxScroll)
                    sidebar.CanvasPosition = Vector2.new(0, scrollTo)
                end
            end)
            break
        end
    end
end
obj.switchTab = switchTab

-- Minimize
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TS:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Back, minimized and Enum.EasingDirection.In or Enum.EasingDirection.Out), {
        Size = UDim2.new(0, cfg.gui.panelW, 0, minimized and cfg.gui.topbarH or cfg.gui.panelH)
    }):Play()
end)

-- FPS Counter
task.spawn(function()
    local frames = 0
    addConn(RS.RenderStepped:Connect(function() frames = frames + 1 end))
    while st.running do
        task.wait(0.5); obj.wmFps = tostring(frames * 2); frames = 0
        pcall(function()
            local stats = getService("Stats")
            if stats then local p = stats:FindFirstChild("PerformanceStats"); if p then local pp = p:FindFirstChild("Ping"); if pp then obj.wmPing = tostring(math.floor(pp:GetValue())) end end end
        end)
        pcall(function() if obj.fpsPingLabel then obj.fpsPingLabel.Text = obj.wmFps .. " FPS | " .. obj.wmPing .. "ms" end end)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  S10B: DYNAMIC PILL WATERMARK
-- ══════════════════════════════════════════════════════════════
local wmPillGui = createGui("MedusaWM")
local wmPill = Instance.new("Frame")
wmPill.Size = UDim2.new(0, 390, 0, 30)
wmPill.Position = UDim2.new(0.5, -195, 0, 8)
wmPill.BackgroundColor3 = C.glass; wmPill.BackgroundTransparency = 0.2
wmPill.BorderSizePixel = 0; wmPill.Parent = wmPillGui
mkCorner(wmPill, 15)
local wmSk = Instance.new("UIStroke", wmPill); wmSk.Color = C.accent; wmSk.Thickness = 1.5; wmSk.Transparency = 0.35
table.insert(obj.themeElements, { obj = wmSk, prop = "Color" })

-- Status light (pulsing dot)
local wmDot = Instance.new("Frame")
wmDot.Size = UDim2.new(0, 8, 0, 8); wmDot.Position = UDim2.new(0, 10, 0.5, -4)
wmDot.BackgroundColor3 = C.success; wmDot.BorderSizePixel = 0; wmDot.Parent = wmPill
mkCorner(wmDot, 4)

obj.wmLabel = Instance.new("TextLabel")
obj.wmLabel.Size = UDim2.new(1, -26, 1, 0); obj.wmLabel.Position = UDim2.new(0, 24, 0, 0)
obj.wmLabel.BackgroundTransparency = 1; obj.wmLabel.Font = Enum.Font.GothamMedium
obj.wmLabel.TextSize = 11; obj.wmLabel.TextColor3 = C.text
obj.wmLabel.TextXAlignment = Enum.TextXAlignment.Left
obj.wmLabel.Text = "🐍 MEDUSA v15.1  |  👤 " .. myRegion .. "  |  🖥️ " .. svRegion .. "  |  📡 --ms  |  🚀 -- FPS"; obj.wmLabel.Parent = wmPill

makeDraggable(wmPill, wmPill)

-- Update watermark + pulse dot
task.spawn(function()
    local dotPhase = 0
    while st.running do
        task.wait(0.5)
        pcall(function()
            obj.wmLabel.Text = "🐍 MEDUSA v15.1  |  👤 " .. myRegion .. "  |  🖥️ " .. svRegion .. "  |  📡 " .. obj.wmPing .. "ms  |  🚀 " .. obj.wmFps .. " FPS"
            dotPhase = dotPhase + 0.3
            wmDot.BackgroundTransparency = math.sin(dotPhase) * 0.3 + 0.1
        end)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  S11-S20: TAB CONTENT (all same logic, Glass visuals)
-- ══════════════════════════════════════════════════════════════
-- S11: STATUS
do local tab = obj.tabFrames["status"]; if tab then
    local pillCard = mkCard(tab, 85, 1); mkLabel(pillCard, "📊 STATUS", cfg.gui.fontSize, C.textMuted, 12, 6)
    local pf = Instance.new("Frame"); pf.Size = UDim2.new(1, -18, 0, 48); pf.Position = UDim2.new(0, 9, 0, 30)
    pf.BackgroundTransparency = 1; pf.Parent = pillCard
    local pg = Instance.new("UIGridLayout", pf); pg.CellSize = UDim2.new(0.33, -4, 0, 20); pg.CellPadding = UDim2.new(0, 4, 0, 4)
    for _, pd in ipairs({
        { key = "esp", txt = "👁️ ESP", col = C.success }, { key = "aimbot", txt = "🎯 Aimbot", col = C.purple },
        { key = "silentAim", txt = "🔇 Silent", col = C.cyan }, { key = "fly", txt = "✈️ Fly", col = C.blue },
        { key = "noclip", txt = "👻 Noclip", col = C.success }, { key = "triggerBot", txt = "🔫 Trigger", col = C.warning },
    }) do
        local p = Instance.new("TextLabel"); p.BackgroundColor3 = C.glass; p.BackgroundTransparency = 0.45
        p.BorderSizePixel = 0; p.Font = Enum.Font.GothamMedium; p.TextSize = 10; p.TextColor3 = C.textMuted
        p.Text = pd.txt .. " OFF"; p.Parent = pf; mkCorner(p, 6)
        obj.statusPills[pd.key] = { label = p, color = pd.col }
    end
    local lockCard = mkCard(tab, 44, 2); local lockLbl = mkLabel(lockCard, "🔓 No Target", cfg.gui.fontSize, C.textMuted, 12, 12)
    obj.statusPills["lock"] = { label = lockLbl }
    local kfCard = mkCard(tab, 78, 3); mkLabel(kfCard, "☠️ KILL FEED", cfg.gui.fontSize, C.textMuted, 12, 6)
    obj.killFeedLabel = mkLabel(kfCard, "No kills yet", 10, C.textMuted, 12, 28, 1, 42); obj.killFeedLabel.TextWrapped = true; obj.killFeedLabel.TextYAlignment = Enum.TextYAlignment.Top
    local timerCard = mkCard(tab, 38, 4); obj.statusPills["espTimer"] = { label = mkLabel(timerCard, "🔄 ESP Refresh: --", 10, C.textMuted, 12, 8) }
    local credCard = mkCard(tab, 38, 5); mkLabel(credCard, "🐍 Medusa v15.1 CINEMATIC EDITION — Made by .donatorexe.", 10, C.textMuted, 12, 8)
end end

-- S12: AIMBOT
do local tab = obj.tabFrames["aimbot"]; if tab then
    local mc = mkCard(tab, 155, 1); mkLabel(mc, "🎯 AIMBOT ENGINE", cfg.gui.fontSize, C.textMuted, 12, 6)
    local mi = Instance.new("Frame"); mi.Size = UDim2.new(1, -18, 0, 125); mi.Position = UDim2.new(0, 9, 0, 28); mi.BackgroundTransparency = 1; mi.Parent = mc
    local mil = Instance.new("UIListLayout", mi); mil.Padding = UDim.new(0, 4)
    mkSyncToggle(mi, "🎯 Aimbot (RMB Lock)", "aimbot", 1, function(on) if not on then obj.lockedTarget = nil; rmbDown = false end; notify(on and "🎯 Aimbot ON" or "❌ Aimbot OFF", on and C.purple or C.error) end)
    mkSyncToggle(mi, "🔇 Silent Aim", "silentAim", 2, function(on) notify(on and "🔇 Silent ON" or "❌ Silent OFF", on and C.cyan or C.error) end)
    mkSyncToggle(mi, "🔫 Trigger Bot", "triggerBot", 3, function(on) notify(on and "🔫 Trigger ON" or "❌ Trigger OFF", on and C.warning or C.error) end)
    mkSyncToggle(mi, "🔮 Prediction", "prediction", 4, function() end)

    local sc = mkCard(tab, 230, 2); mkLabel(sc, "⚙️ ADJUSTMENTS", cfg.gui.fontSize, C.textMuted, 12, 6)
    local si = Instance.new("Frame"); si.Size = UDim2.new(1, -18, 0, 200); si.Position = UDim2.new(0, 9, 0, 28); si.BackgroundTransparency = 1; si.Parent = sc
    local sil = Instance.new("UIListLayout", si); sil.Padding = UDim.new(0, 4)
    mkSlider(si, "📏 FOV Radius", cfg.aimbotFOV, cfg.fovMin, cfg.fovMax, 1, function(v) cfg.aimbotFOV = v; autoSave() end)
    mkSlider(si, "🎚️ Smooth", cfg.aimSmooth, cfg.smoothMin, cfg.smoothMax, 2, function(v) cfg.aimSmooth = v; autoSave() end)
    mkSlider(si, "📐 Max Distance", cfg.maxDistance, cfg.distMin, cfg.distMax, 3, function(v) cfg.maxDistance = v; autoSave() end)
    mkSlider(si, "⏱️ Trigger Delay", math.floor(cfg.triggerDelay * 100), 1, 100, 4, function(v) cfg.triggerDelay = v / 100; autoSave() end)

    local pc = mkCard(tab, 44, 3); mkPartSelector(pc, 1)

    local cc = mkCard(tab, 150, 4); mkLabel(cc, "✅ CHECKS", cfg.gui.fontSize, C.textMuted, 12, 6)
    local ci = Instance.new("Frame"); ci.Size = UDim2.new(1, -18, 0, 120); ci.Position = UDim2.new(0, 9, 0, 28); ci.BackgroundTransparency = 1; ci.Parent = cc
    local cil = Instance.new("UIListLayout", ci); cil.Padding = UDim.new(0, 4)
    mkSyncToggle(ci, "👥 Team Check", "teamCheck", 1, function() end)
    mkSyncToggle(ci, "👁️ Visible Check", "visibleCheck", 2, function() end)
    mkSyncToggle(ci, "❤️ Health Check", "healthCheck", 3, function() autoSave() end)
    mkSlider(ci, "💚 Min HP %", cfg.healthMin, 1, 100, 4, function(v) cfg.healthMin = v; autoSave() end)

    -- Silent Aim v2 Card
    local sac = mkCard(tab, 155, 5); mkLabel(sac, "🔇 SILENT AIM v2 (Curve & Hit Chance)", cfg.gui.fontSize, C.textMuted, 12, 6)
    local sai = Instance.new("Frame"); sai.Size = UDim2.new(1, -18, 0, 125); sai.Position = UDim2.new(0, 9, 0, 28); sai.BackgroundTransparency = 1; sai.Parent = sac
    local sail = Instance.new("UIListLayout", sai); sail.Padding = UDim.new(0, 4)
    mkToggle(sai, "🌀 Curve Trajectory", cfg.silentCurve, 1, function(on) cfg.silentCurve = on; autoSave() end)
    mkSlider(sai, "🎯 Head %", cfg.hitChanceHead, 0, 100, 2, function(v) cfg.hitChanceHead = v; cfg.hitChanceTorso = 100 - v; autoSave() end)
    mkSlider(sai, "🫁 Torso %", cfg.hitChanceTorso, 0, 100, 3, function(v) cfg.hitChanceTorso = v; cfg.hitChanceHead = 100 - v; autoSave() end)
    mkSlider(sai, "🌀 Curve Strength", math.floor(cfg.silentCurveStr * 100), 0, 50, 4, function(v) cfg.silentCurveStr = v / 100; autoSave() end)
end end

-- S13: VISUALS
do local tab = obj.tabFrames["visuals"]; if tab then
    local ec = mkCard(tab, 280, 1); mkLabel(ec, "👁️ ESP SYSTEM", cfg.gui.fontSize, C.textMuted, 12, 6)
    local ei = Instance.new("Frame"); ei.Size = UDim2.new(1, -18, 0, 248); ei.Position = UDim2.new(0, 9, 0, 28); ei.BackgroundTransparency = 1; ei.Parent = ec
    local eiPad = Instance.new("UIPadding", ei); eiPad.PaddingBottom = UDim.new(0, 8)
    local eil = Instance.new("UIListLayout", ei); eil.Padding = UDim.new(0, 4)
    mkSyncToggle(ei, "👁️ ESP Highlights", "esp", 1, function(on) if not on then pcall(function() clearESP() end) end; notify(on and "👁️ ESP ON" or "❌ ESP OFF", on and C.success or C.error) end)
    mkSyncToggle(ei, "📦 3D Boxes", "box3d", 2, function() end)
    mkSyncToggle(ei, "📐 Tracers", "tracers", 3, function() end)
    mkSyncToggle(ei, "🦴 Skeleton", "skeleton", 4, function() end)
    mkSyncToggle(ei, "👁️ View Angles", "viewAngles", 5, function(on)
        if not on then -- Remove existing view angle parts
            for _, d in pairs(obj.espObjs) do pcall(function() if d.viewPart then d.viewPart:Destroy(); d.viewPart = nil end end) end
        end
        autoSave(); notify(on and "👁️ View Angles ON" or "❌ OFF", on and C.accent or C.error)
    end)
    mkSlider(ei, "📏 ESP Distance", cfg.espDistance, 50, 5000, 6, function(v) cfg.espDistance = v end)

    local wc = mkCard(tab, 115, 2); mkLabel(wc, "🌍 WORLD", cfg.gui.fontSize, C.textMuted, 12, 6)
    local wi = Instance.new("Frame"); wi.Size = UDim2.new(1, -18, 0, 85); wi.Position = UDim2.new(0, 9, 0, 28); wi.BackgroundTransparency = 1; wi.Parent = wc
    local wil = Instance.new("UIListLayout", wi); wil.Padding = UDim.new(0, 4)
    mkSyncToggle(wi, "💡 Fullbright", "fullbright", 1, function(on) pcall(function() setFullbright(on) end); notify(on and "💡 Fullbright ON" or "❌ OFF", on and C.warning or C.error) end)
    mkSyncToggle(wi, "➕ Crosshair", "crosshair", 2, function(on) notify(on and "➕ Crosshair ON" or "❌ OFF", on and C.accent or C.error) end)
    mkSyncToggle(wi, "🌈 Rainbow Mode", "rainbow", 3, function() end)

    -- Crosshair settings card
    local chc = mkCard(tab, 185, 3); mkLabel(chc, "➕ CROSSHAIR SETTINGS", cfg.gui.fontSize, C.textMuted, 12, 6)
    local chi = Instance.new("Frame"); chi.Size = UDim2.new(1, -18, 0, 155); chi.Position = UDim2.new(0, 9, 0, 28); chi.BackgroundTransparency = 1; chi.Parent = chc
    local chil = Instance.new("UIListLayout", chi); chil.Padding = UDim.new(0, 4)
    mkSlider(chi, "📏 Size", cfg.crossSize, 4, 40, 1, function(v) cfg.crossSize = v end)
    mkSlider(chi, "↔️ Gap", cfg.crossGap, 0, 20, 2, function(v) cfg.crossGap = v end)
    -- Style selector (1=Cross, 2=Dot, 3=Circle, 4=T-Cross)
    local styleRow = Instance.new("Frame"); styleRow.Size = UDim2.new(1, 0, 0, 34)
    styleRow.BackgroundTransparency = 1; styleRow.LayoutOrder = 3; styleRow.Parent = chi
    mkLabel(styleRow, "Style", cfg.gui.fontSize, C.textMuted, 0, 7)
    local styleNames = { "Cross", "Dot", "Circle", "T-Cross" }
    local styleBtns = {}
    for si, sname in ipairs(styleNames) do
        local sb = Instance.new("TextButton")
        sb.Size = UDim2.new(0, 58, 0, 26)
        sb.Position = UDim2.new(1, -(58 * (5 - si) + 4 * (5 - si)), 0, 4)
        sb.BackgroundColor3 = si == cfg.crossStyle and C.accent or C.glass
        sb.BackgroundTransparency = si == cfg.crossStyle and 0.25 or 0.6
        sb.BorderSizePixel = 0; sb.AutoButtonColor = false; sb.Font = Enum.Font.GothamBold
        sb.TextSize = 10; sb.TextColor3 = si == cfg.crossStyle and C.accent or C.textMuted
        sb.Text = sname; sb.Parent = styleRow; mkCorner(sb, 6)
        local sbsk = Instance.new("UIStroke", sb); sbsk.Color = si == cfg.crossStyle and C.accent or C.border; sbsk.Thickness = 1
        styleBtns[si] = { btn = sb, sk = sbsk }
        sb.MouseButton1Click:Connect(function()
            cfg.crossStyle = si
            for idx, sbd in pairs(styleBtns) do
                local active = idx == si
                TS:Create(sbd.btn, TweenInfo.new(0.2), { BackgroundTransparency = active and 0.25 or 0.6, TextColor3 = active and C.accent or C.textMuted }):Play()
                TS:Create(sbd.sk, TweenInfo.new(0.2), { Color = active and C.accent or C.border }):Play()
            end
        end)
    end
end end

-- S14: MOVEMENT
do local tab = obj.tabFrames["movement"]; if tab then
    local mc = mkCard(tab, 310, 1); mkLabel(mc, "🏃 MOVEMENT", cfg.gui.fontSize, C.textMuted, 12, 6)
    local mi = Instance.new("Frame"); mi.Size = UDim2.new(1, -18, 0, 280); mi.Position = UDim2.new(0, 9, 0, 28); mi.BackgroundTransparency = 1; mi.Parent = mc
    local mil = Instance.new("UIListLayout", mi); mil.Padding = UDim.new(0, 4)
    mkSyncToggle(mi, "✈️ Fly", "fly", 1, function(on) if on then pcall(function() enableFly() end) else pcall(function() disableFly() end) end; notify(on and "✈️ Fly ON" or "❌ OFF", on and C.blue or C.error) end)
    mkSyncToggle(mi, "👻 Noclip", "noclip", 2, function(on) if not on then pcall(function() local c = player.Character; if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end end) end; notify(on and "👻 Noclip ON" or "❌ OFF", on and C.success or C.error) end)
    mkSyncToggle(mi, "🏃 Speed Hack", "speed", 3, function(on) if not on then pcall(function() local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = 16 end end) end; notify(on and "🏃 Speed ON" or "❌ OFF", on and C.accent or C.error) end)
    mkSyncToggle(mi, "🦘 Infinite Jump", "infJump", 4, function(on) notify(on and "🦘 InfJump ON" or "❌ OFF", on and C.accent or C.error) end)
    mkSyncToggle(mi, "🪂 No Fall Damage", "noFallDmg", 5, function(on) notify(on and "🪂 ON" or "❌ OFF", on and C.accent or C.error) end)
    mkSyncToggle(mi, "🖱️ Click TP", "clickTP", 6, function(on) notify(on and "🖱️ ON" or "❌ OFF", on and C.accent or C.error) end)
    mkSlider(mi, "✈️ Fly Speed", cfg.flySpeed, cfg.flyMin, cfg.flyMax, 7, function(v) cfg.flySpeed = v end)
    mkSlider(mi, "🏃 Walk Speed", cfg.walkSpeed, cfg.speedMin, cfg.speedMax, 8, function(v) cfg.walkSpeed = v end)

    local sc = mkCard(tab, 44, 2); mkLabel(sc, "🌀 SPINBOT", cfg.gui.fontSize, C.textMuted, 12, 6)
    local si2 = Instance.new("Frame"); si2.Size = UDim2.new(1, -18, 0, 14); si2.Position = UDim2.new(0, 9, 0, 0); si2.BackgroundTransparency = 1; si2.Parent = sc
    mkSyncToggle(sc, "🌀 SpinBot", "spinBot", 1, function(on) notify(on and "🌀 ON" or "❌ OFF", on and C.pink or C.error) end)
end end

-- S15: COMBAT
do local tab = obj.tabFrames["combat"]; if tab then
    local hc = mkCard(tab, 135, 1); mkLabel(hc, "📦 HITBOX EXPANDER", cfg.gui.fontSize, C.textMuted, 12, 6)
    local hi = Instance.new("Frame"); hi.Size = UDim2.new(1, -18, 0, 105); hi.Position = UDim2.new(0, 9, 0, 28); hi.BackgroundTransparency = 1; hi.Parent = hc
    local hil = Instance.new("UIListLayout", hi); hil.Padding = UDim.new(0, 4)
    mkSyncToggle(hi, "📦 Hitbox Expander", "hitbox", 1, function(on) if not on then pcall(function() resetAllHitboxes() end) end; notify(on and "📦 ON" or "❌ OFF", on and C.warning or C.error) end)
    mkSlider(hi, "📏 Size", cfg.hitboxSize, cfg.hitboxMin, cfg.hitboxMax, 2, function(v) cfg.hitboxSize = v end)
    mkSlider(hi, "👁️ Transparency", math.floor(cfg.hitboxTransparency * 100), 0, 100, 3, function(v) cfg.hitboxTransparency = v / 100 end)

    local fc = mkCard(tab, 135, 2); mkLabel(fc, "💥 FEEDBACK", cfg.gui.fontSize, C.textMuted, 12, 6)
    local fi = Instance.new("Frame"); fi.Size = UDim2.new(1, -18, 0, 105); fi.Position = UDim2.new(0, 9, 0, 28); fi.BackgroundTransparency = 1; fi.Parent = fc
    local fil = Instance.new("UIListLayout", fi); fil.Padding = UDim.new(0, 4)
    mkSyncToggle(fi, "👁️ Spectator List", "spectatorList", 1, function(on) notify(on and "👁️ ON" or "❌ OFF", on and C.accent or C.error) end)
    mkSyncToggle(fi, "💀 Kill Pop-up", "killPopup", 2, function() end)
    mkSyncToggle(fi, "🔊 Hit Sound", "hitSound", 3, function() end)

    local tc = mkCard(tab, 200, 3); mkLabel(tc, "🎯 TARGET HUD", cfg.gui.fontSize, C.textMuted, 12, 6)
    local ti = Instance.new("Frame"); ti.Size = UDim2.new(1, -18, 0, 170); ti.Position = UDim2.new(0, 9, 0, 28); ti.BackgroundTransparency = 1; ti.Parent = tc
    local til = Instance.new("UIListLayout", ti); til.Padding = UDim.new(0, 4)
    mkSyncToggle(ti, "🎯 Show Name", "thName", 1, function() end)
    mkSyncToggle(ti, "🩸 Show Health Bar", "thHealth", 2, function() end)
    mkSyncToggle(ti, "🔫 Show Weapon", "thWeapon", 3, function() end)
    mkSyncToggle(ti, "📏 Show Distance", "thDistance", 4, function() end)
    mkSyncToggle(ti, "🔒 Show Lock Status", "thLockStatus", 5, function() end)
end end

-- S16: PLAYERS
do local tab = obj.tabFrames["players"]; if tab then
    mkCard(tab, 38, 1); mkLabel(obj.tabFrames["players"]:FindFirstChild("Frame") or tab, "👥 PLAYER LIST", cfg.gui.fontSize, C.textMuted, 12, 8)
    -- Search Bar
    local searchFrame = Instance.new("Frame"); searchFrame.Size = UDim2.new(1, 0, 0, 38); searchFrame.BackgroundTransparency = 1; searchFrame.LayoutOrder = 1; searchFrame.Parent = tab
    local searchBox = Instance.new("TextBox"); searchBox.Size = UDim2.new(1, -16, 0, 32); searchBox.Position = UDim2.new(0, 8, 0, 3)
    searchBox.BackgroundColor3 = C.glass; searchBox.BackgroundTransparency = 0.35; searchBox.BorderSizePixel = 0
    searchBox.Font = Enum.Font.GothamMedium; searchBox.TextSize = 13; searchBox.TextColor3 = C.text
    searchBox.PlaceholderText = "🔍 Search players..."; searchBox.PlaceholderColor3 = C.textMuted
    searchBox.TextXAlignment = Enum.TextXAlignment.Left; searchBox.ClearTextOnFocus = false; searchBox.Parent = searchFrame; mkCorner(searchBox, 8)
    local searchStroke = Instance.new("UIStroke", searchBox); searchStroke.Color = C.border; searchStroke.Thickness = 1
    local searchPad = Instance.new("UIPadding", searchBox); searchPad.PaddingLeft = UDim.new(0, 10)
    obj.playerSearchBox = searchBox
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if not obj.playersContainer then return end
        local query = searchBox.Text:lower()
        for _, card in ipairs(obj.playersContainer:GetChildren()) do
            if card:IsA("Frame") then
                if query == "" then
                    card.Visible = true
                else
                    local found = false
                    for _, lbl in ipairs(card:GetDescendants()) do
                        if lbl:IsA("TextLabel") and lbl.Text:lower():find(query, 1, true) then found = true; break end
                    end
                    card.Visible = found
                end
            end
        end
    end)
    searchBox.Focused:Connect(function() TS:Create(searchStroke, TweenInfo.new(0.2), { Color = C.accent, Thickness = 1.5 }):Play() end)
    searchBox.FocusLost:Connect(function() TS:Create(searchStroke, TweenInfo.new(0.2), { Color = C.border, Thickness = 1 }):Play() end)
    -- Player Container
    local container = Instance.new("Frame"); container.Size = UDim2.new(1, 0, 0, 0); container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1; container.LayoutOrder = 2; container.Parent = tab
    Instance.new("UIListLayout", container).Padding = UDim.new(0, 4)
    obj.playersContainer = container
end end

-- S17: MISC
do local tab = obj.tabFrames["misc"]; if tab then
    local uc = mkCard(tab, 270, 1); mkLabel(uc, "🛡️ UTILITIES & PROTECTION", cfg.gui.fontSize, C.textMuted, 12, 6)
    local uci = Instance.new("Frame"); uci.Size = UDim2.new(1, -18, 0, 235); uci.Position = UDim2.new(0, 9, 0, 28); uci.BackgroundTransparency = 1; uci.Parent = uc
    local uciPad = Instance.new("UIPadding", uci); uciPad.PaddingBottom = UDim.new(0, 8)
    local ucil = Instance.new("UIListLayout", uci); ucil.Padding = UDim.new(0, 4)
    mkSyncToggle(uci, "🛡️ Anti-AFK", "antiAfk", 1, function() autoSave() end)
    mkToggle(uci, "💾 Auto-Save Config", cfg.autoSave, 2, function(on) cfg.autoSave = on end)
    mkSyncToggle(uci, "🚨 Admin Detector", "adminDetector", 3, function(on)
        autoSave()
        if on then pcall(function() refreshPlayers() end) end
        notify(on and "🚨 Admin Detector ON" or "❌ OFF", on and C.warning or C.error)
    end)
    mkSyncToggle(uci, "🛡️ Anti-Cheat Spoof", "metatableBypass", 4, function(on)
        autoSave()
        if on then
            notify("🛡️ Metatable Bypass ATIVADO\nWalkSpeed/JumpPower spoofed", C.success)
        else
            notify("❌ Metatable Bypass OFF\nValores reais expostos", C.warning)
        end
    end)
    mkSyncToggle(uci, "👻 Ghost Mode", "ghostMode", 5, function(on) 
        if not on and panel then
            -- Restore normal transparency when turning off
            TS:Create(panel, TweenInfo.new(0.3), { BackgroundTransparency = cfg.gui.panelOpacity }):Play()
            if sidebar then TS:Create(sidebar, TweenInfo.new(0.3), { BackgroundTransparency = 0.25 }):Play() end
            if topbar then TS:Create(topbar, TweenInfo.new(0.3), { BackgroundTransparency = 0.15 }):Play() end
        end
        notify(on and "👻 Ghost Mode ON" or "❌ Ghost Mode OFF", on and C.accent or C.error)
    end)

    -- Discord RPC Card
    local drc = mkCard(tab, 110, 2); mkLabel(drc, "💬 DISCORD RICH PRESENCE", cfg.gui.fontSize, C.textMuted, 12, 6)
    local dri = Instance.new("Frame"); dri.Size = UDim2.new(1, -18, 0, 75); dri.Position = UDim2.new(0, 9, 0, 28); dri.BackgroundTransparency = 1; dri.Parent = drc
    local dril = Instance.new("UIListLayout", dri); dril.Padding = UDim.new(0, 4)
    mkSyncToggle(dri, "📡 Discord RPC Active", "discordRPC", 1, function(on) autoSave() end)
    mkBtn(dri, "📋 Set Webhook URL", C.cyan, 2, function()
        notify("📋 Paste webhook in F9 console", C.cyan)
        -- Uses InputBegan textbox workaround - set via config file
    end)
    mkLabel(dri, "Set webhook URL in Medusa_Config.json", 9, C.textMuted, 2, 0, 1, 14)

    local ac = mkCard(tab, 250, 2); mkLabel(ac, "🔧 ACTIONS", cfg.gui.fontSize, C.textMuted, 12, 6)
    local ai = Instance.new("Frame"); ai.Size = UDim2.new(1, -18, 0, 220); ai.Position = UDim2.new(0, 9, 0, 28); ai.BackgroundTransparency = 1; ai.Parent = ac
    local ail = Instance.new("UIListLayout", ai); ail.Padding = UDim.new(0, 4)
    mkBtn(ai, "🔄 Refresh ESP", C.accent, 1, function() pcall(function() clearESP() end); lastESPRefresh = os.time(); notify("🔄 ESP Refreshed", C.accent) end)
    mkBtn(ai, "🔄 Refresh Players", C.accent, 2, function() pcall(function() refreshPlayers() end); notify("🔄 Players Refreshed", C.accent) end)
    mkBtn(ai, "📷 Unspectate", C.blue, 3, function() pcall(function() camera.CameraSubject = player.Character and player.Character:FindFirstChild("Humanoid") end); notify("📷 Unspectated", C.blue) end)
    mkBtn(ai, "🔁 Rejoin", C.warning, 4, function() notify("🔁 Rejoining...", C.warning); task.delay(1, function() pcall(function() TeleportService:Teleport(game.PlaceId) end) end) end)
    mkBtn(ai, "🌐 Server Hop", C.cyan, 5, function() notify("🌐 Finding server...", C.cyan); task.spawn(function() pcall(function() local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=10"; local data = HttpService:JSONDecode(game:HttpGet(url)); for _, sv in ipairs(data.data or {}) do if sv.playing and sv.playing < sv.maxPlayers and sv.id ~= game.JobId then TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id); return end end; notify("❌ No servers", C.error) end) end) end)
    mkBtn(ai, "📋 Copy Game Link", C.accent, 6, function() pcall(function() local link = "https://www.roblox.com/games/" .. game.PlaceId; if setclipboard then setclipboard(link) elseif toclipboard then toclipboard(link) end; notify("📋 Link copied!", C.success) end) end)

    local dc = mkCard(tab, 95, 3); dc.BackgroundColor3 = Color3.fromRGB(25, 8, 8); mkLabel(dc, "🚨 DANGER ZONE", cfg.gui.fontSize, C.error, 12, 6)
    local di = Instance.new("Frame"); di.Size = UDim2.new(1, -18, 0, 65); di.Position = UDim2.new(0, 9, 0, 28); di.BackgroundTransparency = 1; di.Parent = dc
    local dil = Instance.new("UIListLayout", di); dil.Padding = UDim.new(0, 4)
    mkBtn(di, "🚨 PANIC (End)", C.error, 1, function() notify("🚨 PANIC!", C.error); task.delay(0.5, function() pcall(function() doPanic() end) end) end)
    mkBtn(di, "🗑️ EJECT (P)", C.error, 2, function() notify("🗑️ Ejecting...", C.error); task.delay(0.5, function() pcall(function() doEject() end) end) end)
end end

-- S18: BINDS
do local tab = obj.tabFrames["binds"]; if tab then
    mkCard(tab, 38, 1); mkLabel(tab:FindFirstChild("Frame") or tab, "🎮 KEYBINDS", cfg.gui.fontSize, C.textMuted, 12, 8)
    local bo = { "esp", "aimbot", "silentAim", "triggerBot", "fly", "noclip", "hitbox", "speed", "infJump", "fullbright", "crosshair", "clickTP", "noFallDmg", "spinBot", "toggleGui", "eject", "panic" }
    for i, key in ipairs(bo) do
        local r = Instance.new("Frame"); r.Size = UDim2.new(1, 0, 0, 32); r.BackgroundTransparency = 1; r.LayoutOrder = i + 1; r.Parent = tab
        local l = Instance.new("TextLabel"); l.Size = UDim2.new(0.6, 0, 1, 0); l.Position = UDim2.new(0, 12, 0, 0)
        l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamMedium; l.TextSize = cfg.gui.fontSize; l.TextColor3 = C.text
        l.TextXAlignment = Enum.TextXAlignment.Left; l.Text = key; l.Parent = r
        local b = Instance.new("TextButton"); b.Size = UDim2.new(0, 80, 0, 26); b.Position = UDim2.new(1, -92, 0.5, -13)
        b.BackgroundColor3 = C.glass; b.BackgroundTransparency = 0.4; b.BorderSizePixel = 0; b.AutoButtonColor = false
        b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.TextColor3 = C.accent
        b.Text = keybinds[key] and keybinds[key].Name or "?"; b.Parent = r; mkCorner(b, 6)
        local bsk = Instance.new("UIStroke", b); bsk.Color = C.border; bsk.Thickness = 1
        local listening = false
        b.MouseButton1Click:Connect(function()
            if listening then return end; listening = true; b.Text = "..."; b.TextColor3 = C.warning
            local conn; conn = UIS.InputBegan:Connect(function(inp, gp) if gp then return end
                if inp.KeyCode ~= Enum.KeyCode.Unknown then keybinds[key] = inp.KeyCode; b.Text = inp.KeyCode.Name; b.TextColor3 = C.accent; listening = false; conn:Disconnect(); autoSave() end
            end)
        end)
    end
    mkBtn(tab, "🔄 Reset All Binds", C.warning, 100, function() for k, v in pairs(defaultBinds) do keybinds[k] = v end; notify("🔄 Binds reset!", C.warning) end)
end end

-- S19: STYLE
do local tab = obj.tabFrames["style"]; if tab then
    local tc = mkCard(tab, 95, 1); mkLabel(tc, "🎨 THEMES", cfg.gui.fontSize, C.textMuted, 12, 6)
    local tr = Instance.new("Frame"); tr.Size = UDim2.new(1, -18, 0, 55); tr.Position = UDim2.new(0, 9, 0, 30); tr.BackgroundTransparency = 1; tr.Parent = tc
    local tg = Instance.new("UIGridLayout", tr); tg.CellSize = UDim2.new(0, 42, 0, 42); tg.CellPadding = UDim2.new(0, 6, 0, 6)
    for i, th in ipairs(themes) do
        local tb = Instance.new("TextButton"); tb.Size = UDim2.new(0, 42, 0, 42); tb.LayoutOrder = i
        tb.BackgroundColor3 = th.accent; tb.BackgroundTransparency = 0.25; tb.BorderSizePixel = 0
        tb.AutoButtonColor = false; tb.Text = ""; tb.Parent = tr; mkCorner(tb, 10)
        local tsk = Instance.new("UIStroke", tb); tsk.Color = Color3.new(1,1,1); tsk.Thickness = 1.5; tsk.Transparency = 0.5
        local tl = Instance.new("TextLabel"); tl.Size = UDim2.new(1, 0, 0, 12); tl.Position = UDim2.new(0, 0, 1, -14)
        tl.BackgroundTransparency = 1; tl.Font = Enum.Font.Gotham; tl.TextSize = 8; tl.TextColor3 = Color3.new(1,1,1); tl.Text = th.name; tl.Parent = tb
        tb.MouseButton1Click:Connect(function() applyTheme(th.accent); notify("🎨 " .. th.name, th.accent); autoSave() end)
    end

    local rc = mkCard(tab, 155, 2); mkLabel(rc, "🌈 RGB ENGINE", cfg.gui.fontSize, C.textMuted, 12, 6)
    local ri = Instance.new("Frame"); ri.Size = UDim2.new(1, -18, 0, 125); ri.Position = UDim2.new(0, 9, 0, 28); ri.BackgroundTransparency = 1; ri.Parent = rc
    local ril = Instance.new("UIListLayout", ri); ril.Padding = UDim.new(0, 4)
    mkToggle(ri, "🌈 RGB Stroke", cfg.rgb.stroke, 1, function(on) cfg.rgb.stroke = on end)
    mkToggle(ri, "📝 RGB Title", cfg.rgb.title, 2, function(on) cfg.rgb.title = on end)
    mkToggle(ri, "📍 RGB Indicator", cfg.rgb.indicator, 3, function(on) cfg.rgb.indicator = on end)
    mkSlider(ri, "⚡ Speed", math.floor(cfg.rgb.speed * 100), 10, 300, 4, function(v) cfg.rgb.speed = v / 100 end)

    local pc = mkCard(tab, 115, 3); mkLabel(pc, "🖥️ PANEL & VISIBILITY", cfg.gui.fontSize, C.textMuted, 12, 6)
    local pi = Instance.new("Frame"); pi.Size = UDim2.new(1, -18, 0, 80); pi.Position = UDim2.new(0, 9, 0, 28); pi.BackgroundTransparency = 1; pi.Parent = pc
    local pil = Instance.new("UIListLayout", pi); pil.Padding = UDim.new(0, 4)
    mkSlider(pi, "🔍 Panel Opacity", math.floor(cfg.gui.panelOpacity * 100), 0, 50, 1, function(v) cfg.gui.panelOpacity = v / 100; panel.BackgroundTransparency = v / 100 end)
    mkSyncToggle(pi, "👻 Ghost Mode (Fade on idle)", "ghostMode", 2, function(on)
        if not on and panel then
            TS:Create(panel, TweenInfo.new(0.3), { BackgroundTransparency = cfg.gui.panelOpacity }):Play()
            if sidebar then TS:Create(sidebar, TweenInfo.new(0.3), { BackgroundTransparency = 0.25 }):Play() end
            if topbar then TS:Create(topbar, TweenInfo.new(0.3), { BackgroundTransparency = 0.15 }):Play() end
        end
        Notify("👻 Ghost Mode", on and "Panel will fade when mouse moves away" or "Panel visibility restored", 3)
    end)
    mkBtn(tab, "💾 Save Config", C.accent, 4, function() saveConfig(); Notify("💾 Config", "All settings saved to Medusa_Config.json", 3) end)

    -- ── RGB COLOR PICKERS ────────────────────────────────────
    local rgbCard = mkCard(tab, 220, 5); mkLabel(rgbCard, "🎨 RGB COLOR PICKERS", cfg.gui.fontSize, C.textMuted, 12, 6)
    local rgbInner = Instance.new("Frame"); rgbInner.Size = UDim2.new(1, -18, 0, 190); rgbInner.Position = UDim2.new(0, 9, 0, 28)
    rgbInner.BackgroundTransparency = 1; rgbInner.Parent = rgbCard
    local rgbList = Instance.new("UIListLayout", rgbInner); rgbList.Padding = UDim.new(0, 3)
    mkLabel(rgbInner, "Accent Color", 10, C.textMuted, 0, 0, 1, 14).LayoutOrder = 0
    mkSlider(rgbInner, "🔴 Red", cfg.gui.accentR, 0, 255, 1, function(v) cfg.gui.accentR = v; applyTheme(Color3.fromRGB(cfg.gui.accentR, cfg.gui.accentG, cfg.gui.accentB)); autoSave() end)
    mkSlider(rgbInner, "🟢 Green", cfg.gui.accentG, 0, 255, 2, function(v) cfg.gui.accentG = v; applyTheme(Color3.fromRGB(cfg.gui.accentR, cfg.gui.accentG, cfg.gui.accentB)); autoSave() end)
    mkSlider(rgbInner, "🔵 Blue", cfg.gui.accentB, 0, 255, 3, function(v) cfg.gui.accentB = v; applyTheme(Color3.fromRGB(cfg.gui.accentR, cfg.gui.accentG, cfg.gui.accentB)); autoSave() end)

    -- Background color
    local bgCard2 = mkCard(tab, 170, 6); mkLabel(bgCard2, "🖥️ BACKGROUND COLOR", cfg.gui.fontSize, C.textMuted, 12, 6)
    local bgInner = Instance.new("Frame"); bgInner.Size = UDim2.new(1, -18, 0, 140); bgInner.Position = UDim2.new(0, 9, 0, 28)
    bgInner.BackgroundTransparency = 1; bgInner.Parent = bgCard2
    local bgList = Instance.new("UIListLayout", bgInner); bgList.Padding = UDim.new(0, 3)
    mkSlider(bgInner, "🔴 BG Red", cfg.gui.bgR, 0, 50, 1, function(v) cfg.gui.bgR = v; C.bg = Color3.fromRGB(v, cfg.gui.bgG, cfg.gui.bgB); panel.BackgroundColor3 = C.bg; autoSave() end)
    mkSlider(bgInner, "🟢 BG Green", cfg.gui.bgG, 0, 50, 2, function(v) cfg.gui.bgG = v; C.bg = Color3.fromRGB(cfg.gui.bgR, v, cfg.gui.bgB); panel.BackgroundColor3 = C.bg; autoSave() end)
    mkSlider(bgInner, "🔵 BG Blue", cfg.gui.bgB, 0, 50, 3, function(v) cfg.gui.bgB = v; C.bg = Color3.fromRGB(cfg.gui.bgR, cfg.gui.bgG, v); panel.BackgroundColor3 = C.bg; autoSave() end)

    -- Sidebar color
    local sideCard = mkCard(tab, 170, 7); mkLabel(sideCard, "📊 SIDEBAR COLOR", cfg.gui.fontSize, C.textMuted, 12, 6)
    local sideInner = Instance.new("Frame"); sideInner.Size = UDim2.new(1, -18, 0, 140); sideInner.Position = UDim2.new(0, 9, 0, 28)
    sideInner.BackgroundTransparency = 1; sideInner.Parent = sideCard
    local sideList = Instance.new("UIListLayout", sideInner); sideList.Padding = UDim.new(0, 3)
    mkSlider(sideInner, "🔴 Side Red", cfg.gui.sideR, 0, 50, 1, function(v) cfg.gui.sideR = v; if sidebar then sidebar.BackgroundColor3 = Color3.fromRGB(v, cfg.gui.sideG, cfg.gui.sideB) end; autoSave() end)
    mkSlider(sideInner, "🟢 Side Green", cfg.gui.sideG, 0, 50, 2, function(v) cfg.gui.sideG = v; if sidebar then sidebar.BackgroundColor3 = Color3.fromRGB(cfg.gui.sideR, v, cfg.gui.sideB) end; autoSave() end)
    mkSlider(sideInner, "🔵 Side Blue", cfg.gui.sideB, 0, 50, 3, function(v) cfg.gui.sideB = v; if sidebar then sidebar.BackgroundColor3 = Color3.fromRGB(cfg.gui.sideR, cfg.gui.sideG, v) end; autoSave() end)

    -- Roundness & Transparency
    local rtCard = mkCard(tab, 120, 8); mkLabel(rtCard, "🔲 SHAPE & VISIBILITY", cfg.gui.fontSize, C.textMuted, 12, 6)
    local rtInner = Instance.new("Frame"); rtInner.Size = UDim2.new(1, -18, 0, 85); rtInner.Position = UDim2.new(0, 9, 0, 28)
    rtInner.BackgroundTransparency = 1; rtInner.Parent = rtCard
    local rtList = Instance.new("UIListLayout", rtInner); rtList.Padding = UDim.new(0, 4)
    mkSlider(rtInner, "🔤 Roundness (0=Square, 20=Round)", cfg.gui.cornerRadius, 0, 24, 1, function(v) cfg.gui.cornerRadius = v; autoSave() end)
    mkSlider(rtInner, "🔍 Transparency (0=Opaque, 50=Glass)", math.floor(cfg.gui.panelOpacity * 100), 0, 50, 2, function(v) cfg.gui.panelOpacity = v / 100; panel.BackgroundTransparency = v / 100; autoSave() end)

    -- ── PROFILES SYSTEM ────────────────────────────────────────
    local pfc = mkCard(tab, 280, 11); mkLabel(pfc, "📂 CONFIG PROFILES", cfg.gui.fontSize, C.textMuted, 12, 6)
    local pfInner = Instance.new("Frame"); pfInner.Size = UDim2.new(1, -18, 0, 248); pfInner.Position = UDim2.new(0, 9, 0, 28)
    pfInner.BackgroundTransparency = 1; pfInner.Parent = pfc
    local pfList = Instance.new("UIListLayout", pfInner); pfList.Padding = UDim.new(0, 5)

    -- Profile name input
    local pfNameFrame = Instance.new("Frame"); pfNameFrame.Size = UDim2.new(1, 0, 0, 34); pfNameFrame.BackgroundTransparency = 1; pfNameFrame.LayoutOrder = 1; pfNameFrame.Parent = pfInner
    local pfInput = Instance.new("TextBox"); pfInput.Size = UDim2.new(1, -90, 0, 30); pfInput.Position = UDim2.new(0, 0, 0, 2)
    pfInput.BackgroundColor3 = C.glass; pfInput.BackgroundTransparency = 0.35; pfInput.BorderSizePixel = 0
    pfInput.Font = Enum.Font.GothamMedium; pfInput.TextSize = 12; pfInput.TextColor3 = C.text
    pfInput.PlaceholderText = "Profile name..."; pfInput.PlaceholderColor3 = C.textMuted
    pfInput.TextXAlignment = Enum.TextXAlignment.Left; pfInput.ClearTextOnFocus = false; pfInput.Parent = pfNameFrame; mkCorner(pfInput, 8)
    local pfInputStroke = Instance.new("UIStroke", pfInput); pfInputStroke.Color = C.border; pfInputStroke.Thickness = 1
    local pfInputPad = Instance.new("UIPadding", pfInput); pfInputPad.PaddingLeft = UDim.new(0, 10)

    pfInput.Focused:Connect(function() TS:Create(pfInputStroke, TweenInfo.new(0.2), { Color = C.accent, Thickness = 1.5 }):Play() end)
    pfInput.FocusLost:Connect(function() TS:Create(pfInputStroke, TweenInfo.new(0.2), { Color = C.border, Thickness = 1 }):Play() end)

    -- Create Save button
    local pfSaveBtn = Instance.new("TextButton"); pfSaveBtn.Size = UDim2.new(0, 80, 0, 30); pfSaveBtn.Position = UDim2.new(1, -80, 0, 2)
    pfSaveBtn.BackgroundColor3 = C.accent; pfSaveBtn.BackgroundTransparency = 0.2; pfSaveBtn.BorderSizePixel = 0; pfSaveBtn.AutoButtonColor = false
    pfSaveBtn.Font = Enum.Font.GothamBold; pfSaveBtn.TextSize = 11; pfSaveBtn.TextColor3 = Color3.new(1,1,1); pfSaveBtn.Text = "💾 SAVE"
    pfSaveBtn.Parent = pfNameFrame; mkCorner(pfSaveBtn, 8)
    Instance.new("UIStroke", pfSaveBtn).Color = C.accent; pfSaveBtn:FindFirstChildWhichIsA("UIStroke").Thickness = 1

    -- Profiles scroll list
    local pfScrollLabel = Instance.new("TextLabel"); pfScrollLabel.Size = UDim2.new(1, 0, 0, 18); pfScrollLabel.BackgroundTransparency = 1
    pfScrollLabel.Font = Enum.Font.GothamMedium; pfScrollLabel.TextSize = 10; pfScrollLabel.TextColor3 = C.textMuted
    pfScrollLabel.TextXAlignment = Enum.TextXAlignment.Left; pfScrollLabel.Text = "📁 Saved Profiles:"; pfScrollLabel.LayoutOrder = 2; pfScrollLabel.Parent = pfInner

    local pfScroll = Instance.new("ScrollingFrame"); pfScroll.Size = UDim2.new(1, 0, 0, 150); pfScroll.LayoutOrder = 3
    pfScroll.BackgroundColor3 = C.glass; pfScroll.BackgroundTransparency = 0.5; pfScroll.BorderSizePixel = 0
    pfScroll.ScrollBarThickness = 3; pfScroll.ScrollBarImageColor3 = C.accent; pfScroll.ScrollBarImageTransparency = 0.4
    pfScroll.CanvasSize = UDim2.new(0, 0, 0, 0); pfScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; pfScroll.Parent = pfInner; mkCorner(pfScroll, 8)
    Instance.new("UIStroke", pfScroll).Color = C.border
    local pfScrollList = Instance.new("UIListLayout", pfScroll); pfScrollList.Padding = UDim.new(0, 3)
    local pfScrollPad = Instance.new("UIPadding", pfScroll); pfScrollPad.PaddingTop = UDim.new(0, 4); pfScrollPad.PaddingBottom = UDim.new(0, 4)
    pfScrollPad.PaddingLeft = UDim.new(0, 4); pfScrollPad.PaddingRight = UDim.new(0, 4)

    -- Refresh profile list function
    local function refreshProfileList()
        for _, c in ipairs(pfScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        local profiles = listProfiles()
        if #profiles == 0 then
            local empty = Instance.new("TextLabel"); empty.Size = UDim2.new(1, 0, 0, 30); empty.BackgroundTransparency = 1
            empty.Font = Enum.Font.Gotham; empty.TextSize = 11; empty.TextColor3 = C.textMuted
            empty.Text = "No profiles saved yet"; empty.Parent = pfScroll
        else
            for i, name in ipairs(profiles) do
                local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 32)
                row.BackgroundColor3 = C.glass; row.BackgroundTransparency = 0.4; row.BorderSizePixel = 0; row.Parent = pfScroll; mkCorner(row, 6)
                -- Profile name
                local nl = Instance.new("TextLabel"); nl.Size = UDim2.new(1, -110, 1, 0); nl.Position = UDim2.new(0, 8, 0, 0)
                nl.BackgroundTransparency = 1; nl.Font = Enum.Font.GothamMedium; nl.TextSize = 11; nl.TextColor3 = C.text
                nl.TextXAlignment = Enum.TextXAlignment.Left; nl.Text = "📄 " .. name; nl.TextTruncate = Enum.TextTruncate.AtEnd; nl.Parent = row
                -- Load button
                local lb = Instance.new("TextButton"); lb.Size = UDim2.new(0, 48, 0, 24); lb.Position = UDim2.new(1, -104, 0.5, -12)
                lb.BackgroundColor3 = C.success; lb.BackgroundTransparency = 0.3; lb.BorderSizePixel = 0; lb.AutoButtonColor = false
                lb.Font = Enum.Font.GothamBold; lb.TextSize = 10; lb.TextColor3 = Color3.new(1,1,1); lb.Text = "LOAD"; lb.Parent = row; mkCorner(lb, 5)
                -- Delete button
                local db = Instance.new("TextButton"); db.Size = UDim2.new(0, 48, 0, 24); db.Position = UDim2.new(1, -52, 0.5, -12)
                db.BackgroundColor3 = C.error; db.BackgroundTransparency = 0.3; db.BorderSizePixel = 0; db.AutoButtonColor = false
                db.Font = Enum.Font.GothamBold; db.TextSize = 10; db.TextColor3 = Color3.new(1,1,1); db.Text = "DEL"; db.Parent = row; mkCorner(db, 5)
                -- Hover effects
                local pName = name
                row.MouseEnter:Connect(function() TS:Create(row, TweenInfo.new(0.15), { BackgroundTransparency = 0.2 }):Play() end)
                row.MouseLeave:Connect(function() TS:Create(row, TweenInfo.new(0.15), { BackgroundTransparency = 0.4 }):Play() end)
                lb.MouseEnter:Connect(function() TS:Create(lb, TweenInfo.new(0.1), { BackgroundTransparency = 0.1 }):Play() end)
                lb.MouseLeave:Connect(function() TS:Create(lb, TweenInfo.new(0.1), { BackgroundTransparency = 0.3 }):Play() end)
                db.MouseEnter:Connect(function() TS:Create(db, TweenInfo.new(0.1), { BackgroundTransparency = 0.1 }):Play() end)
                db.MouseLeave:Connect(function() TS:Create(db, TweenInfo.new(0.1), { BackgroundTransparency = 0.3 }):Play() end)
                lb.MouseButton1Click:Connect(function() loadProfile(pName); refreshProfileList() end)
                db.MouseButton1Click:Connect(function() deleteProfile(pName); refreshProfileList() end)
            end
        end
    end

    -- Save button logic
    pfSaveBtn.MouseButton1Click:Connect(function()
        local name = pfInput.Text
        if name and name ~= "" then
            saveProfile(name)
            pfInput.Text = ""
            refreshProfileList()
        else
            Notify("⚠️ Warning", "Enter a profile name first!", 3)
        end
    end)
    pfSaveBtn.MouseEnter:Connect(function() TS:Create(pfSaveBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.05 }):Play() end)
    pfSaveBtn.MouseLeave:Connect(function() TS:Create(pfSaveBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.2 }):Play() end)

    -- Initial refresh
    task.delay(0.5, refreshProfileList)
end end

-- S20: GUI EDITOR
do local tab = obj.tabFrames["gui"]; if tab then
    local dc = mkCard(tab, 110, 1); mkLabel(dc, "📐 DIMENSIONS", cfg.gui.fontSize, C.textMuted, 12, 6)
    local di = Instance.new("Frame"); di.Size = UDim2.new(1, -18, 0, 80); di.Position = UDim2.new(0, 9, 0, 28); di.BackgroundTransparency = 1; di.Parent = dc
    local dil = Instance.new("UIListLayout", di); dil.Padding = UDim.new(0, 4)
    mkSlider(di, "↔️ Panel Width", cfg.gui.panelW, 440, 900, 1, function(v) cfg.gui.panelW = v; panel.Size = UDim2.new(0, v, 0, cfg.gui.panelH) end)
    mkSlider(di, "↕️ Panel Height", cfg.gui.panelH, 400, 900, 2, function(v) cfg.gui.panelH = v; panel.Size = UDim2.new(0, cfg.gui.panelW, 0, v) end)
    local tc = mkCard(tab, 65, 2); mkLabel(tc, "📝 CORNERS", cfg.gui.fontSize, C.textMuted, 12, 6)
    local ti = Instance.new("Frame"); ti.Size = UDim2.new(1, -18, 0, 35); ti.Position = UDim2.new(0, 9, 0, 28); ti.BackgroundTransparency = 1; ti.Parent = tc
    mkSlider(ti, "🔤 Corner Radius", cfg.gui.cornerRadius, 0, 24, 1, function(v) cfg.gui.cornerRadius = v end)
    mkBtn(tab, "🔄 Reset GUI", C.warning, 10, function()
        cfg.gui = { panelW = 680, panelH = 540, sidebarW = 52, topbarH = 48, fontSize = 12, titleSize = 18, cardSpacing = 10, cardPadding = 12, borderWidth = 1.5, cornerRadius = 14, toggleW = 40, toggleH = 20, sliderH = 10, btnH = 36, panelOpacity = 0.12, accentR = 0, accentG = 220, accentB = 180, bgR = 12, bgG = 12, bgB = 18, sideR = 10, sideG = 10, sideB = 16 }
        panel.Size = UDim2.new(0, 680, 0, 540); panel.BackgroundTransparency = 0.12; applyTheme(Color3.fromRGB(0, 220, 180)); notify("🔄 GUI Reset!", C.warning)
    end)
end end

-- ══════════════════════════════════════════════════════════════
--  S21-S27: ALL LOGIC (unchanged from v13.5)
-- ══════════════════════════════════════════════════════════════
local function isValidTarget(plr)
    if not plr or plr == player or not plr.Character then return false end
    local char = plr.Character; local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if cfg.teamCheck and plr.Team and player.Team and plr.Team == player.Team then return false end
    if cfg.healthCheck and hum.MaxHealth > 0 then if (hum.Health / hum.MaxHealth) * 100 < cfg.healthMin then return false end end
    local head = char:FindFirstChild("Head")
    if head and (head.Position - camera.CFrame.Position).Magnitude > cfg.maxDistance then return false end
    if cfg.visibleCheck and head then
        local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = { player.Character, camera }
        local result = Workspace:Raycast(camera.CFrame.Position, (head.Position - camera.CFrame.Position), params)
        if result and not result.Instance:IsDescendantOf(char) then return false end
    end
    return true
end

local function getAimPart(char)
    if not char then return nil end
    if cfg.aimbotPart == "Head" then return char:FindFirstChild("Head")
    elseif cfg.aimbotPart == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    elseif cfg.aimbotPart == "Random" then
        local parts = {}; for _, nm in ipairs({"Head","UpperTorso","Torso","HumanoidRootPart"}) do local p = char:FindFirstChild(nm); if p then table.insert(parts, p) end end
        return #parts > 0 and parts[math.random(#parts)] or char:FindFirstChild("Head")
    end; return char:FindFirstChild("Head")
end

local function predictPosition(part, char)
    if not cfg.prediction or not part then return part.Position end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return part.Position end
    local vel = hrp.AssemblyLinearVelocity or hrp.Velocity or Vector3.zero
    return part.Position + vel * ((part.Position - camera.CFrame.Position).Magnitude / 1000 * cfg.predStrength)
end

local function closestInFOV()
    local mp = UIS:GetMouseLocation(); local best, bestD = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if isValidTarget(plr) then local part = getAimPart(plr.Character)
            if part then local sp, on = camera:WorldToViewportPoint(part.Position)
                if on then local d = (Vector2.new(sp.X, sp.Y) - mp).Magnitude; if d < cfg.aimbotFOV and d < bestD then best = plr; bestD = d end end
            end
        end
    end; return best
end

-- Aimbot render
addConn(RS.RenderStepped:Connect(function()
    if not st.running then return end
    if st.aimbot and rmbDown then
        if obj.lockedTarget and not isValidTarget(obj.lockedTarget) then obj.lockedTarget = nil end
        if not obj.lockedTarget then obj.lockedTarget = closestInFOV() end
    else obj.lockedTarget = nil end
    if st.aimbot and rmbDown and obj.lockedTarget and obj.lockedTarget.Character then
        local part = getAimPart(obj.lockedTarget.Character)
        if part then
            local tp = predictPosition(part, obj.lockedTarget.Character)
            if cfg.aimSmooth == 0 then camera.CFrame = CFrame.new(camera.CFrame.Position, tp)
            else local t = (1 - cfg.aimSmooth / 100) * 0.93 + 0.02; camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + camera.CFrame.LookVector:Lerp((tp - camera.CFrame.Position).Unit, t).Unit) end
        end
    end
    -- Status pills
    for key, pill in pairs(obj.statusPills) do
        if pill.label and key ~= "lock" and key ~= "espTimer" then
            local on = st[key]; pill.label.Text = pill.label.Text:gsub(" ON", ""):gsub(" OFF", "") .. (on and " ON" or " OFF")
            pill.label.TextColor3 = on and (pill.color or C.success) or C.textMuted
        end
    end
    if obj.statusPills["lock"] and obj.statusPills["lock"].label then
        local lbl = obj.statusPills["lock"].label
        if obj.lockedTarget and rmbDown then lbl.Text = "🔒 LOCKED: " .. obj.lockedTarget.DisplayName; lbl.TextColor3 = C.error
        else lbl.Text = "🔓 No Target"; lbl.TextColor3 = C.textMuted end
    end
    if obj.killFeedLabel and #obj.killFeed > 0 then
        local lines = {}; for i = math.max(1, #obj.killFeed - 3), #obj.killFeed do table.insert(lines, obj.killFeed[i]) end
        obj.killFeedLabel.Text = table.concat(lines, "\n")
    end
    if obj.statusPills["espTimer"] and obj.statusPills["espTimer"].label then
        if st.esp then local rem = cfg.espRefreshRate - (os.time() - lastESPRefresh); obj.statusPills["espTimer"].label.Text = string.format("🔄 ESP Refresh: %d:%02d", math.floor(rem / 60), rem % 60)
        else obj.statusPills["espTimer"].label.Text = "🔄 ESP: OFF" end
    end
end))

-- Silent Aim v2 (Curve & Hit Chance)
local function getSilentTarget(char)
    if not char then return nil end
    -- Hit Chance: randomize between head and torso based on configured %
    local roll = math.random(1, 100)
    if roll <= cfg.hitChanceHead then
        return char:FindFirstChild("Head")
    else
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
    end
end

local function applyCurve(origin, targetPos)
    if not cfg.silentCurve then return (targetPos - origin).Unit end
    -- Add subtle curve to make trajectory look human (not a perfect line)
    -- Uses a perpendicular offset that varies with time
    local dir = (targetPos - origin)
    local dist = dir.Magnitude
    if dist < 1 then return dir.Unit end
    local norm = dir.Unit
    -- Create perpendicular vector
    local up = Vector3.new(0, 1, 0)
    local perp = norm:Cross(up)
    if perp.Magnitude < 0.01 then perp = norm:Cross(Vector3.new(1, 0, 0)) end
    perp = perp.Unit
    -- Curve offset: subtle sine wave based on tick(), scaled by strength
    local curveAmount = math.sin(tick() * 3.7) * cfg.silentCurveStr * (dist / 100)
    local curveOffset = perp * curveAmount
    -- Final direction with curve applied
    return (dir + curveOffset).Unit
end

if XC.hookmetamethod then pcall(function()
    local myHumanoid = nil
    local myHRP = nil
    local function getMyHum()
        local char = player.Character
        if char then myHumanoid = char:FindFirstChildOfClass("Humanoid"); myHRP = char:FindFirstChild("HumanoidRootPart") end
        return myHumanoid
    end
    getMyHum(); player.CharacterAdded:Connect(function() task.wait(0.3); getMyHum() end)

    local oldIndex; oldIndex = hookmetamethod(game, "__index", function(self, key)
        -- S26A: METATABLE BYPASS — spoof WalkSpeed/JumpPower/Velocity to anti-cheat
        if st.metatableBypass and not checkcaller() then
            if self == myHumanoid then
                if key == "WalkSpeed" then return 16 end
                if key == "JumpPower" then return 50 end
                if key == "JumpHeight" then return 7.2 end
            end
            if self == myHRP then
                if key == "Velocity" then return Vector3.zero end
                if key == "AssemblyLinearVelocity" then return Vector3.zero end
                if key == "AssemblyAngularVelocity" then return Vector3.zero end
            end
        end
        -- S22: SILENT AIM — redirect mouse.Hit/Target/UnitRay
        if st.silentAim and obj.lockedTarget then
            if self == mouse then
                local part = getSilentTarget(obj.lockedTarget.Character)
                if part then
                    local pos = predictPosition(part, obj.lockedTarget.Character)
                    if key == "Hit" then return CFrame.new(pos) end
                    if key == "Target" then return part end
                    if key == "UnitRay" then
                        local curvedDir = applyCurve(camera.CFrame.Position, pos)
                        return Ray.new(camera.CFrame.Position, curvedDir)
                    end
                end
            end
        end
        return oldIndex(self, key)
    end)
    local oldNc; oldNc = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        -- S26B: ANTI-ADONIS — block remote kick/ban/punish calls
        if st.metatableBypass and not checkcaller() then
            if method == "Kick" and self == player then return end
            if (method == "FireServer" or method == "InvokeServer") and self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                local remoteName = self.Name:lower()
                if remoteName:find("kick") or remoteName:find("ban") or remoteName:find("punish") or remoteName:find("detect") then
                    return -- Block anti-cheat remote calls
                end
            end
        end
        -- S22: SILENT AIM — redirect Raycast/FindPartOnRay
        if st.silentAim and obj.lockedTarget then
            if method == "Raycast" and self == Workspace then
                local part = getSilentTarget(obj.lockedTarget.Character)
                if part then
                    local pos = predictPosition(part, obj.lockedTarget.Character)
                    local curvedDir = applyCurve(camera.CFrame.Position, pos)
                    local args = {...}; args[1] = camera.CFrame.Position; args[2] = curvedDir * 1000
                    return oldNc(self, unpack(args))
                end
            end
            if method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
                local part = getSilentTarget(obj.lockedTarget.Character)
                if part then
                    local pos = predictPosition(part, obj.lockedTarget.Character)
                    local curvedDir = applyCurve(camera.CFrame.Position, pos)
                    local newRay = Ray.new(camera.CFrame.Position, curvedDir * 1000)
                    local args = {...}; args[1] = newRay
                    return oldNc(self, unpack(args))
                end
            end
        end
        return oldNc(self, ...)
    end)
end) end

-- Trigger Bot
task.spawn(function() while st.running do task.wait(cfg.triggerDelay)
    if st.triggerBot then local mp = UIS:GetMouseLocation()
        for _, plr in ipairs(Players:GetPlayers()) do if isValidTarget(plr) then local part = getAimPart(plr.Character)
            if part then local sp, on = camera:WorldToViewportPoint(part.Position)
                if on and (Vector2.new(sp.X, sp.Y) - mp).Magnitude < cfg.triggerFOV then
                    if XC.mouse1click then mouse1click() elseif XC.VIM then pcall(function() VirtualInputManager:SendMouseButtonEvent(mp.X, mp.Y, 0, true, game, 0); task.wait(0.02); VirtualInputManager:SendMouseButtonEvent(mp.X, mp.Y, 0, false, game, 0) end) end; break
                end
            end
        end end
    end
end end)

-- ESP
local bbParent = playerGui; pcall(function() local t = Instance.new("BillboardGui"); t.Parent = CoreGui; t:Destroy(); bbParent = CoreGui end)

local function clearESP()
    local keys = {}; for p in pairs(obj.espObjs) do table.insert(keys, p) end
    for _, p in ipairs(keys) do local d = obj.espObjs[p]; if d then
        pcall(function() if d.hl then d.hl:Destroy() end end)
        pcall(function() if d.bb then d.bb:Destroy() end end)
        pcall(function() if d.box then d.box:Destroy() end end)
        pcall(function() if d.cn then d.cn:Disconnect() end end)
        pcall(function() if d.tracerGui then d.tracerGui:Destroy() end end)
        pcall(function() if d.skelFolder then d.skelFolder:Destroy() end end)
        pcall(function() if d.viewPart then d.viewPart:Destroy() end end)
    end; obj.espObjs[p] = nil end
end

local function addESP(plr)
    if not st.esp or not plr or plr == player or obj.espObjs[plr] then return end
    if not isValidTarget(plr) then return end
    local char = plr.Character; if not char then return end
    local head = char:FindFirstChild("Head"); local hrp = char:FindFirstChild("HumanoidRootPart"); if not head then return end
    local data = {}
    pcall(function() local hl = Instance.new("Highlight"); hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.FillColor = C.accent; hl.OutlineColor = C.accent:Lerp(Color3.new(0,0,0), 0.4); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee = char; hl.Parent = char; data.hl = hl end)
    pcall(function()
        local bb = Instance.new("BillboardGui"); bb.Adornee = head; bb.AlwaysOnTop = true; bb.Size = UDim2.new(0, 140, 0, 50); bb.StudsOffset = Vector3.new(0, 3, 0); bb.Parent = bbParent
        local nl = Instance.new("TextLabel"); nl.Size = UDim2.new(1, 0, 0, 18); nl.BackgroundTransparency = 1; nl.Font = Enum.Font.GothamBold; nl.TextSize = 13; nl.TextColor3 = Color3.new(1,1,1); nl.TextStrokeTransparency = 0.4; nl.Text = plr.DisplayName; nl.Parent = bb
        local dl = Instance.new("TextLabel"); dl.Size = UDim2.new(1, 0, 0, 14); dl.Position = UDim2.new(0,0,0,18); dl.BackgroundTransparency = 1; dl.Font = Enum.Font.Gotham; dl.TextSize = 11; dl.TextColor3 = C.accent; dl.TextStrokeTransparency = 0.4; dl.Text = "0m"; dl.Parent = bb
        local hpBg = Instance.new("Frame"); hpBg.Size = UDim2.new(0.8, 0, 0, 4); hpBg.Position = UDim2.new(0.1, 0, 0, 34); hpBg.BackgroundColor3 = Color3.fromRGB(40,40,40); hpBg.BorderSizePixel = 0; hpBg.Parent = bb; mkCorner(hpBg, 2)
        local hpFill = Instance.new("Frame"); hpFill.Size = UDim2.new(1, 0, 1, 0); hpFill.BackgroundColor3 = C.success; hpFill.BorderSizePixel = 0; hpFill.Parent = hpBg; mkCorner(hpFill, 2)
        data.bb = bb; data.distLabel = dl; data.hpFill = hpFill
    end)
    if st.box3d and hrp then pcall(function() local box = Instance.new("SelectionBox"); box.Adornee = hrp; box.Color3 = C.accent; box.SurfaceTransparency = 0.85; box.LineThickness = 0.03; box.Parent = hrp; data.box = box end) end
    -- Tracer (Frame-based line from bottom of screen to player)
    if st.tracers then pcall(function()
        local tGui = createGui("MedusaTracer_" .. plr.Name)
        local tracerLine = Instance.new("Frame")
        tracerLine.Size = UDim2.new(0, 0, 0, 0) -- Start invisible (zero size)
        tracerLine.Visible = false -- CRITICAL: hidden until updated
        tracerLine.BackgroundColor3 = C.accent; tracerLine.BorderSizePixel = 0
        tracerLine.AnchorPoint = Vector2.new(0.5, 0); tracerLine.Parent = tGui
        data.tracerGui = tGui; data.tracerLine = tracerLine
    end) end
    -- View Angles (direction line from head showing where enemy looks)
    if st.viewAngles and head then pcall(function()
        local vp = Instance.new("Part")
        vp.Name = "MedusaViewAngle"; vp.Anchored = true; vp.CanCollide = false
        vp.Size = Vector3.new(0.12, 0.12, 5); vp.Material = Enum.Material.Neon
        vp.Color = C.accent:Lerp(Color3.new(1, 0.2, 0.2), 0.3); vp.Transparency = 0.35
        vp.CastShadow = false; vp.Parent = char
        data.viewPart = vp
    end) end
    -- Skeleton (Beams connecting body parts)
    if st.skeleton then pcall(function()
        local skelFolder = Instance.new("Folder"); skelFolder.Name = "MedusaSkel_" .. plr.Name; skelFolder.Parent = char
        local bonePairs = {
            {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
            {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
            {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
            {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
            {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
        }
        data.beams = {}
        for _, pair in ipairs(bonePairs) do
            local p0 = char:FindFirstChild(pair[1]); local p1 = char:FindFirstChild(pair[2])
            if p0 and p1 then
                local att0 = Instance.new("Attachment"); att0.Parent = p0
                local att1 = Instance.new("Attachment"); att1.Parent = p1
                local beam = Instance.new("Beam")
                beam.Attachment0 = att0; beam.Attachment1 = att1
                beam.Color = ColorSequence.new(C.accent)
                beam.Width0 = 0.15; beam.Width1 = 0.15
                beam.FaceCamera = true; beam.Transparency = NumberSequence.new(0.3)
                beam.Parent = skelFolder
                table.insert(data.beams, { beam = beam, att0 = att0, att1 = att1 })
            end
        end
        data.skelFolder = skelFolder
    end) end
    data.cn = RS.RenderStepped:Connect(function() pcall(function()
        if not st.running then return end
        if not char or not char.Parent or not head.Parent then
            local d = obj.espObjs[plr]; if d then
                pcall(function() if d.hl then d.hl:Destroy() end end)
                pcall(function() if d.bb then d.bb:Destroy() end end)
                pcall(function() if d.box then d.box:Destroy() end end)
                pcall(function() if d.tracerGui then d.tracerGui:Destroy() end end)
                pcall(function() if d.skelFolder then d.skelFolder:Destroy() end end)
                pcall(function() if d.viewPart then d.viewPart:Destroy() end end)
                pcall(function() if d.cn then d.cn:Disconnect() end end)
                obj.espObjs[plr] = nil
            end; return
        end
        if data.distLabel then data.distLabel.Text = math.floor((head.Position - camera.CFrame.Position).Magnitude) .. "m" end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and data.hpFill and hum.MaxHealth > 0 then local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1); data.hpFill.Size = UDim2.new(pct, 0, 1, 0); data.hpFill.BackgroundColor3 = pct > 0.5 and C.success or pct > 0.25 and C.warning or C.error end
        -- Update View Angles (lightweight — only CFrame update)
        if data.viewPart then
            if st.viewAngles and head and head.Parent then
                data.viewPart.CFrame = head.CFrame * CFrame.new(0, 0, -2.5)
                data.viewPart.Transparency = 0.35
            else
                data.viewPart.Transparency = 1
            end
        end
        -- Update tracer line position
        if data.tracerLine and data.tracerGui then
            local vp = camera.ViewportSize
            local sp, onScreen = camera:WorldToViewportPoint(head.Position)
            if onScreen and st.tracers then
                data.tracerLine.Visible = true
                local startX, startY = vp.X / 2, vp.Y
                local endX, endY = sp.X, sp.Y
                local dx, dy = endX - startX, endY - startY
                local dist = math.sqrt(dx * dx + dy * dy)
                local angle = math.atan2(dy, dx)
                data.tracerLine.Size = UDim2.new(0, dist, 0, 1)
                data.tracerLine.Position = UDim2.new(0, startX, 0, startY)
                data.tracerLine.Rotation = math.deg(angle)
            else
                data.tracerLine.Visible = false
            end
        end
    end) end)
    obj.espObjs[plr] = data
end

task.spawn(function() while st.running do task.wait(1)
    if st.esp then for _, plr in ipairs(Players:GetPlayers()) do if plr ~= player and not obj.espObjs[plr] then pcall(function() addESP(plr) end) end end
        if os.time() - lastESPRefresh >= cfg.espRefreshRate then clearESP(); lastESPRefresh = os.time() end
    else clearESP() end
end end)
addConn(Players.PlayerAdded:Connect(function(plr) task.delay(2, function() if st.esp and st.running then pcall(function() addESP(plr) end) end end) end))
addConn(Players.PlayerRemoving:Connect(function(plr) if obj.espObjs[plr] then local d = obj.espObjs[plr]; pcall(function() if d.hl then d.hl:Destroy() end end); pcall(function() if d.bb then d.bb:Destroy() end end); pcall(function() if d.box then d.box:Destroy() end end); pcall(function() if d.cn then d.cn:Disconnect() end end); obj.espObjs[plr] = nil end end))

-- Movement
function enableFly() local c = player.Character; if not c then return end; local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end; pcall(function() if obj.bv then obj.bv:Destroy() end end); pcall(function() if obj.bg then obj.bg:Destroy() end end); obj.bv = Instance.new("BodyVelocity"); obj.bv.MaxForce = Vector3.new(1e5,1e5,1e5); obj.bv.Velocity = Vector3.zero; obj.bv.Parent = hrp; obj.bg = Instance.new("BodyGyro"); obj.bg.MaxTorque = Vector3.new(1e5,1e5,1e5); obj.bg.P = 1e4; obj.bg.Parent = hrp end
function disableFly() pcall(function() if obj.bv then obj.bv:Destroy(); obj.bv = nil end end); pcall(function() if obj.bg then obj.bg:Destroy(); obj.bg = nil end end) end

addConn(RS.RenderStepped:Connect(function() if not st.running then return end
    if st.fly and obj.bv and obj.bg then local cam = camera.CFrame; local mv = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.LookVector end; if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.RightVector end; if UIS:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.yAxis end; if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.yAxis end
        obj.bv.Velocity = mv.Magnitude > 0 and mv.Unit * cfg.flySpeed or Vector3.zero; obj.bg.CFrame = cam
    end
end))
addConn(RS.Stepped:Connect(function() if not st.running then return end; if not (getgenv and getgenv().MedusaLoaded) then return end; if st.noclip and player.Character then for _, p in ipairs(player.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end))
addConn(RS.RenderStepped:Connect(function() if not st.running then return end; if not (getgenv and getgenv().MedusaLoaded) then return end; if st.speed and player.Character then local h = player.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = cfg.walkSpeed end end end))
addConn(UIS.JumpRequest:Connect(function() if st.infJump and player.Character then local h = player.Character:FindFirstChildOfClass("Humanoid"); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end))
addConn(RS.RenderStepped:Connect(function() if st.noFallDmg and player.Character then local h = player.Character:FindFirstChildOfClass("Humanoid"); if h then h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false); h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end end end))
task.spawn(function() while st.running do task.wait(1/30); if st.spinBot and player.Character then local hrp = player.Character:FindFirstChild("HumanoidRootPart"); if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(cfg.spinSpeed), 0) end end end end)
addConn(player.CharacterAdded:Connect(function() task.wait(0.5); if st.fly then enableFly() end end))

-- Hitbox
local bparts = {"Head","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg","HumanoidRootPart"}
function resetAllHitboxes() for plr, sizes in pairs(obj.origSizes) do if plr.Character then for nm, sz in pairs(sizes) do local p = plr.Character:FindFirstChild(nm); if p and p:IsA("BasePart") then pcall(function() p.Size = sz; p.Transparency = nm == "HumanoidRootPart" and 1 or 0 end) end end end; obj.origSizes[plr] = nil end end
task.spawn(function() while st.running do task.wait(0.8)
    if st.hitbox then for _, plr in ipairs(Players:GetPlayers()) do if plr ~= player and isValidTarget(plr) and plr.Character then obj.origSizes[plr] = obj.origSizes[plr] or {}
        for _, nm in ipairs(bparts) do local p = plr.Character:FindFirstChild(nm); if p and p:IsA("BasePart") then pcall(function() if not obj.origSizes[plr][nm] then obj.origSizes[plr][nm] = p.Size end; p.Size = obj.origSizes[plr][nm] * (cfg.hitboxSize / 5); p.Transparency = cfg.hitboxTransparency; p.CanCollide = false end) end end
    end end else resetAllHitboxes() end
end end)

-- Misc
pcall(function() if VirtualUser then addConn(player.Idled:Connect(function() if st.antiAfk then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.zero) end end)) end end)
pcall(function() obj.origLighting = { Brightness = Lighting.Brightness, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows }; local a = Lighting:FindFirstChildOfClass("Atmosphere"); if a then obj.origLighting.AtmoDensity = a.Density end end)
function setFullbright(on) if on then Lighting.Brightness = 2; Lighting.FogEnd = 1e6; Lighting.GlobalShadows = false; local a = Lighting:FindFirstChildOfClass("Atmosphere"); if a then a.Density = 0 end
else Lighting.Brightness = obj.origLighting.Brightness or 1; Lighting.FogEnd = obj.origLighting.FogEnd or 1e4; Lighting.GlobalShadows = obj.origLighting.GlobalShadows ~= false; local a = Lighting:FindFirstChildOfClass("Atmosphere"); if a and obj.origLighting.AtmoDensity then a.Density = obj.origLighting.AtmoDensity end end end
addConn(mouse.Button1Down:Connect(function() if st.clickTP and UIS:IsKeyDown(keybinds.clickTP) then local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if hrp then hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) end end end))

-- ══════════════════════════════════════════════════════════════
--  S27B: DISCORD RICH PRESENCE ENGINE
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    task.wait(5) -- let everything initialize first
    while st.running do
        task.wait(cfg.discordInterval)
        if st.discordRPC and cfg.discordWebhook ~= "" then
            pcall(function()
                local kills = #obj.killFeed
                local activeMods = {}
                if st.aimbot then table.insert(activeMods, "Aimbot") end
                if st.esp then table.insert(activeMods, "ESP") end
                if st.silentAim then table.insert(activeMods, "Silent") end
                if st.fly then table.insert(activeMods, "Fly") end
                if st.triggerBot then table.insert(activeMods, "Trigger") end
                local modsStr = #activeMods > 0 and table.concat(activeMods, ", ") or "None"
                local payload = {
                    content = nil,
                    embeds = {{
                        title = "🐍 MEDUSA v15.1 — Live Status",
                        color = 56540, -- teal
                        fields = {
                            { name = "🎮 Game", value = "Roblox — " .. (game.Name or "Unknown"), inline = true },
                            { name = "👤 Location", value = "ME: " .. myRegion .. " | SV: " .. svRegion, inline = true },
                            { name = "🚀 Performance", value = obj.wmFps .. " FPS | " .. obj.wmPing .. "ms", inline = true },
                            { name = "⚔️ Active Modules", value = modsStr, inline = false },
                            { name = "☠️ Kills This Session", value = tostring(kills), inline = true },
                            { name = "👥 Players", value = tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers), inline = true },
                        },
                        footer = { text = "Medusa v15.1 — Made by .donatorexe. | " .. os.date("%H:%M:%S") },
                    }},
                }
                local jsonPayload = HttpService:JSONEncode(payload)
                -- Try multiple HTTP methods (Xeno compatibility)
                local sent = false
                pcall(function()
                    if request then
                        request({ Url = cfg.discordWebhook, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = jsonPayload })
                        sent = true
                    end
                end)
                if not sent then pcall(function()
                    if http_request then
                        http_request({ Url = cfg.discordWebhook, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = jsonPayload })
                        sent = true
                    end
                end) end
                if not sent then pcall(function()
                    if syn and syn.request then
                        syn.request({ Url = cfg.discordWebhook, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = jsonPayload })
                        sent = true
                    end
                end) end
                if not sent then pcall(function()
                    if HttpService and HttpService.RequestAsync then
                        HttpService:RequestAsync({ Url = cfg.discordWebhook, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = jsonPayload })
                    end
                end) end
            end)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  S28: RGB ENGINE + NEON GLOW PULSE
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    local hue, pulsePhase = 0, 0
    while st.running do
        task.wait(1 / 30)
        if not st.running then break end
        hue = (hue + cfg.rgb.speed / 300) % 1; pulsePhase = pulsePhase + 0.04
        local rgbColor = Color3.fromHSV(hue, cfg.rgb.saturation, cfg.rgb.brightness)
        -- Apply RGB only to registered elements (stroke, title, indicator)
        for _, el in ipairs(obj.rgbElements) do pcall(function()
            if not el.obj or not el.obj.Parent then return end
            if el.type == "stroke" and cfg.rgb.stroke then el.obj[el.prop] = rgbColor
            elseif el.type == "title" and cfg.rgb.title then el.obj[el.prop] = rgbColor
            elseif el.type == "indicator" and cfg.rgb.indicator then el.obj[el.prop] = rgbColor end
        end) end
        -- Subtle stroke pulse only (NO shadow — was causing giant square)
        if cfg.rgb.stroke or cfg.rgb.title then pcall(function()
            if not panelStroke or not panelStroke.Parent then return end
            local pulse = math.sin(pulsePhase) * 0.5 + 0.5
            panelStroke.Thickness = 1.5 + pulse * 0.5
            panelStroke.Transparency = 0.15 + (1 - pulse) * 0.15
        end) else pcall(function()
            if panelStroke and panelStroke.Parent then panelStroke.Thickness = 1.5; panelStroke.Transparency = 0.2 end
        end) end
        -- INTELLIGENT RAINBOW: Apply to sidebar emoji TextStrokeColor3 + active toggle dots
        if st.rainbow then pcall(function()
            -- Sidebar emojis: change text color with rainbow
            for _, child in ipairs(sidebar:GetChildren()) do
                if child:IsA("TextButton") then
                    child.TextStrokeColor3 = rgbColor
                    child.TextStrokeTransparency = 0.5
                end
            end
            -- Active toggle knobs: pulse with rainbow
            for key, reg in pairs(obj.toggleRegistry) do
                if st[key] and reg.knob then
                    pcall(function() reg.knob.BackgroundColor3 = rgbColor end)
                end
            end
        end) else pcall(function()
            -- Reset sidebar emojis
            for _, child in ipairs(sidebar:GetChildren()) do
                if child:IsA("TextButton") then child.TextStrokeTransparency = 1 end
            end
            -- Reset toggle knobs to accent
            for key, reg in pairs(obj.toggleRegistry) do
                if st[key] and reg.knob then
                    pcall(function() reg.knob.BackgroundColor3 = C.accent end)
                end
            end
        end) end
    end
    -- CLEANUP: Reset to defaults when loop dies
    pcall(function()
        if panelStroke and panelStroke.Parent then panelStroke.Thickness = 1.5; panelStroke.Transparency = 0.2; panelStroke.Color = C.accent end
        -- Reset sidebar emoji strokes
        for _, child in ipairs(sidebar:GetChildren()) do
            if child:IsA("TextButton") then child.TextStrokeTransparency = 1 end
        end
    end)
end)

-- ══════════════════════════════════════════════════════════════
--  S29: INPUT HANDLER
-- ══════════════════════════════════════════════════════════════
local function toggleFeature(key)
    st[key] = not st[key]; local on = st[key]; syncToggleVisual(key, on)
    if key == "esp" then if not on then clearESP() else lastESPRefresh = os.time() end; notify(on and "👁️ ESP ON" or "❌ ESP OFF", on and C.success or C.error)
    elseif key == "aimbot" then if not on then obj.lockedTarget = nil; rmbDown = false end; notify(on and "🎯 Aimbot ON" or "❌ OFF", on and C.purple or C.error)
    elseif key == "fly" then if on then enableFly() else disableFly() end; notify(on and "✈️ Fly ON" or "❌ OFF", on and C.blue or C.error)
    elseif key == "noclip" then if not on then pcall(function() local c = player.Character; if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end end) end; notify(on and "👻 Noclip ON" or "❌ OFF", on and C.success or C.error)
    elseif key == "hitbox" then if not on then resetAllHitboxes() end; notify(on and "📦 Hitbox ON" or "❌ OFF", on and C.warning or C.error)
    elseif key == "speed" then if not on then pcall(function() local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = 16 end end) end; notify(on and "🏃 Speed ON" or "❌ OFF", on and C.accent or C.error)
    elseif key == "fullbright" then setFullbright(on); notify(on and "💡 Fullbright ON" or "❌ OFF", on and C.warning or C.error)
    else notify((on and "✅ " or "❌ ") .. key, on and C.accent or C.error) end
end

local function doPanic()
    for k in pairs(st) do if k ~= "running" and k ~= "guiVisible" and k ~= "antiAfk" then st[k] = false; syncToggleVisual(k, false) end end
    clearESP(); resetAllHitboxes(); disableFly(); setFullbright(false)
    pcall(function() local c = player.Character; if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end; local h = c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = 16 end end end)
    -- Remove blur on panic
    pcall(function() hideBlur() end)
    obj.lockedTarget = nil; rmbDown = false; notify("🚨 All features disabled!", C.error)
end

local function doEject()
    st.running = false
    doPanic()
    
    -- S32-MEM: MEMORY CLEANUP — destroy all connections first
    cleanConns()
    
    -- Destroy sound objects
    pcall(function() if obj.hitSoundObj then obj.hitSoundObj:Destroy(); obj.hitSoundObj = nil end end)
    pcall(function() if uiClickSound then uiClickSound:Destroy() end end)
    pcall(function() if uiTabSound then uiTabSound:Destroy() end end)
    pcall(function() if uiToggleOnSound then uiToggleOnSound:Destroy() end end)
    pcall(function() if uiToggleOffSound then uiToggleOffSound:Destroy() end end)
    
    -- Restore default cursor
    pcall(function() UIS.MouseIconEnabled = true end)
    
    -- Reset panel stroke before destroying (shadow was removed — no longer exists)
    pcall(function() if panelStroke and panelStroke.Parent then panelStroke.Thickness = 1.5; panelStroke.Transparency = 0.2; panelStroke.Color = C.accent end end)
    -- Destroy all ScreenGuis
    pcall(function() if screenGui then screenGui:Destroy() end end)
    pcall(function() if wmPillGui then wmPillGui:Destroy() end end)
    pcall(function() if obj.feedbackGui then obj.feedbackGui:Destroy() end end)
    pcall(function() if obj.thGui then obj.thGui:Destroy() end end)
    pcall(function() if obj.activeHudGui then obj.activeHudGui:Destroy() end end)
    pcall(function() if obj.cursorGui then obj.cursorGui:Destroy() end end)
    
    -- Destroy ALL Medusa GUIs from PlayerGui
    pcall(function() 
        for _, g in ipairs(playerGui:GetChildren()) do 
            if g.Name and g.Name:find("Medusa") then g:Destroy() end 
        end 
    end)
    
    -- Destroy ALL Medusa GUIs from CoreGui (including Rainbow remnants)
    pcall(function() 
        for _, g in ipairs(CoreGui:GetChildren()) do 
            if g.Name and (g.Name:find("Medusa") or g.Name:find("Rainbow") or g.Name:find("Cursor") or g.Name:find("ActiveHUD") or g.Name:find("Cinematic")) then g:Destroy() end 
        end 
    end)
    -- Also sweep gethui() if available
    pcall(function()
        local hui = gethui and gethui()
        if hui then
            for _, g in ipairs(hui:GetChildren()) do
                if g.Name and (g.Name:find("Medusa") or g.Name:find("Rainbow") or g.Name:find("Cursor")) then g:Destroy() end
            end
        end
    end)
    
    -- Clear ESP data tables (memory leak prevention)
    pcall(function() clearESP() end)
    for k in pairs(obj.espObjs) do obj.espObjs[k] = nil end
    for k in pairs(obj.origSizes) do obj.origSizes[k] = nil end
    
    -- Destroy Active HUD + Custom Cursor explicitly
    pcall(function() if obj.activeHudGui then obj.activeHudGui:Destroy() end end)
    pcall(function() if obj.cursorGui then obj.cursorGui:Destroy() end end)
    
    -- Destroy UI sounds
    pcall(function() if uiClickSound then uiClickSound:Destroy() end end)
    pcall(function() if uiTabSound then uiTabSound:Destroy() end end)
    pcall(function() if uiToggleOnSound then uiToggleOnSound:Destroy() end end)
    pcall(function() if uiToggleOffSound then uiToggleOffSound:Destroy() end end)
    
    -- Nullify all object references (help GC)
    obj.lockedTarget = nil
    obj.panel = nil
    obj.activeHudGui = nil; obj.activeHudFrame = nil
    obj.cursorGui = nil; obj.cursorFrame = nil
    obj.toggleRegistry = {}
    obj.tabFrames = {}
    obj.statusPills = {}
    obj.themeElements = {}
    obj.rgbElements = {}
    obj.killFeed = {}
    notifStack = {}
    
    -- Restore character state (FULL COLLISION RESTORE)
    st.noclip = false -- kill noclip loop
    pcall(function()
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16; hum.JumpPower = 50; hum.CameraOffset = Vector3.new(0,0,0) end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CanCollide = true; hrp.Velocity = Vector3.new(0,0,0) end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
                if p:IsA("BodyVelocity") or p:IsA("BodyGyro") then p:Destroy() end
            end
        end
    end)
    -- Force noclip OFF globally
    pcall(function() if getgenv then getgenv().Noclip = false end end)
    
    -- Restore camera FULLY (Fix: camera stuck after eject)
    pcall(function() 
        camera.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        camera.FieldOfView = 70
        camera.CameraType = Enum.CameraType.Custom
    end)
    pcall(function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.CameraOffset = Vector3.new(0, 0, 0) end
    end)
    
    -- Restore mouse cursor (Fix: invisible mouse after eject)
    pcall(function() UIS.MouseIconEnabled = true end)
    
    -- Destroy blur effect
    pcall(function() hideBlur() end)
    pcall(function() if blurEffect then blurEffect:Destroy(); blurEffect = nil end end)
    -- Remove any leftover MedusaBlur from Lighting
    pcall(function() for _, b in ipairs(Lighting:GetChildren()) do if b.Name == "MedusaBlur" then b:Destroy() end end end)
    
    -- Restore lighting
    pcall(function() setFullbright(false) end)
    
    -- Destroy cinematic screen if still exists
    pcall(function()
        for _, g in ipairs(playerGui:GetChildren()) do
            if g.Name and g.Name:find("Cinematic") then g:Destroy() end
        end
        for _, g in ipairs(CoreGui:GetChildren()) do
            if g.Name and g.Name:find("Cinematic") then g:Destroy() end
        end
    end)
    
    -- Clear globals
    if getgenv then getgenv().MedusaLoaded = false; getgenv().MedusaEject = nil end
    
    print("═══════════════════════════════════════")
    print("  🐍 MEDUSA v15.1 — Ejected cleanly")
    print("  All connections disconnected")
    print("  All GUIs destroyed")
    print("  Memory freed")
    print("═══════════════════════════════════════")
end
if getgenv then getgenv().MedusaEject = doEject end

addConn(UIS.InputBegan:Connect(function(i, gp)
    if gp or not st.running then return end
    if i.UserInputType == Enum.UserInputType.MouseButton2 then if st.aimbot then rmbDown = true end; return end
    if not i.KeyCode then return end; local k = i.KeyCode
    if k == keybinds.panic then doPanic()
    elseif k == keybinds.eject then notify("🗑️ Ejecting...", C.error); task.delay(0.5, doEject)
    elseif k == keybinds.toggleGui then 
        st.guiVisible = not st.guiVisible; panel.Visible = st.guiVisible
        -- Blur effect: show when menu opens, hide when closes
        if st.guiVisible then showBlur() else hideBlur() end
        -- INSTANT cursor hide when GUI closes (Fix: cursor ghost)
        if not st.guiVisible then
            pcall(function() if obj.cursorFrame then obj.cursorFrame.Visible = false end end)
            pcall(function() UIS.MouseIconEnabled = true end)
        end
    else for key, bind in pairs(keybinds) do if bind == k and key ~= "panic" and key ~= "eject" and key ~= "toggleGui" then toggleFeature(key); break end end end
end))
addConn(UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then rmbDown = false; obj.lockedTarget = nil end end))

-- ══════════════════════════════════════════════════════════════
--  S30: TARGET HUD + FEEDBACK
-- ══════════════════════════════════════════════════════════════
do -- Target HUD
    local thGui = createGui("MedusaTH")
    local thPanel = Instance.new("Frame"); thPanel.Size = UDim2.new(0, 230, 0, 110); thPanel.Position = UDim2.new(0.5, -115, 0.75, 0)
    thPanel.BackgroundColor3 = C.glass; thPanel.BackgroundTransparency = 1; thPanel.BorderSizePixel = 0; thPanel.Visible = false; thPanel.Parent = thGui; mkCorner(thPanel, CR)
    local thSk = Instance.new("UIStroke", thPanel); thSk.Color = C.accent; thSk.Thickness = 1.5; thSk.Transparency = 1
    local thNameLbl = mkLabel(thPanel, "", 14, Color3.new(1,1,1), 10, 8); thNameLbl.Font = Enum.Font.GothamBold
    local thHpBg = Instance.new("Frame"); thHpBg.Size = UDim2.new(1, -20, 0, 6); thHpBg.Position = UDim2.new(0, 10, 0, 30); thHpBg.BackgroundColor3 = Color3.fromRGB(40,40,40); thHpBg.BorderSizePixel = 0; thHpBg.Parent = thPanel; mkCorner(thHpBg, 3)
    local thHpFill = Instance.new("Frame"); thHpFill.Size = UDim2.new(1, 0, 1, 0); thHpFill.BackgroundColor3 = C.success; thHpFill.BorderSizePixel = 0; thHpFill.Parent = thHpBg; mkCorner(thHpFill, 3)
    local thHpText = mkLabel(thPanel, "HP: 100/100", 10, C.textMuted, 10, 38)
    local thWeaponLbl = mkLabel(thPanel, "🤜 Unarmed", 10, C.textMuted, 10, 54)
    local thDistLbl = mkLabel(thPanel, "📏 0m", 10, C.textMuted, 10, 70)
    local thLockLbl = mkLabel(thPanel, "🔒 LOCKED", 10, C.error, 10, 86); thLockLbl.Font = Enum.Font.GothamBold
    makeDraggable(thPanel, thPanel)
    obj.thGui = thGui

    task.spawn(function() local lastTarget = nil; while st.running do task.wait(1/20)
        local show = st.aimbot and rmbDown and obj.lockedTarget ~= nil
        if show then pcall(function()
            local char = obj.lockedTarget.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                thPanel.Visible = true
                if thPanel.BackgroundTransparency > 0.5 then TS:Create(thPanel, TweenInfo.new(0.25), { BackgroundTransparency = 0.15 }):Play(); TS:Create(thSk, TweenInfo.new(0.25), { Transparency = 0.2 }):Play() end
                local y = 8
                thNameLbl.Visible = st.thName; if st.thName then thNameLbl.Text = "🎯 " .. obj.lockedTarget.DisplayName; thNameLbl.Position = UDim2.new(0, 10, 0, y); y = y + 22 end
                thHpBg.Visible = st.thHealth; thHpText.Visible = st.thHealth
                if st.thHealth and hum.MaxHealth > 0 then local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    TS:Create(thHpFill, TweenInfo.new(0.3), { Size = UDim2.new(pct, 0, 1, 0), BackgroundColor3 = pct > 0.5 and C.success or pct > 0.25 and C.warning or C.error }):Play()
                    thHpBg.Position = UDim2.new(0, 10, 0, y); thHpText.Text = string.format("HP: %d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth)); thHpText.Position = UDim2.new(0, 10, 0, y + 10); y = y + 24
                end
                thWeaponLbl.Visible = st.thWeapon; if st.thWeapon then local tool = char:FindFirstChildOfClass("Tool"); thWeaponLbl.Text = tool and ("🔫 " .. tool.Name) or "🤜 Unarmed"; thWeaponLbl.Position = UDim2.new(0, 10, 0, y); y = y + 16 end
                thDistLbl.Visible = st.thDistance; if st.thDistance then local head = char:FindFirstChild("Head"); thDistLbl.Text = "📏 " .. (head and math.floor((head.Position - camera.CFrame.Position).Magnitude) or 0) .. "m"; thDistLbl.Position = UDim2.new(0, 10, 0, y); y = y + 16 end
                thLockLbl.Visible = st.thLockStatus; if st.thLockStatus then thLockLbl.Position = UDim2.new(0, 10, 0, y); y = y + 16 end
                thPanel.Size = UDim2.new(0, 230, 0, y + 8)
                if obj.lockedTarget ~= lastTarget then lastTarget = obj.lockedTarget; TS:Create(thSk, TweenInfo.new(0.1), { Thickness = 3 }):Play(); task.delay(0.2, function() TS:Create(thSk, TweenInfo.new(0.3), { Thickness = 1.5 }):Play() end) end
            end
        end) end
        if not show and thPanel.BackgroundTransparency < 0.9 then TS:Create(thPanel, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play(); TS:Create(thSk, TweenInfo.new(0.2), { Transparency = 1 }):Play(); task.delay(0.25, function() if not (st.aimbot and rmbDown and obj.lockedTarget) then thPanel.Visible = false; lastTarget = nil end end) end
    end end)
end

do -- Feedback Module
    pcall(function() local s = Instance.new("Sound"); s.SoundId = "rbxassetid://6333389871"; s.Volume = 0.5; s.Parent = SoundService; obj.hitSoundObj = s end)
    local function showKillPopup(victimName) if not st.killPopup then return end; obj.killStreak = obj.killStreak + 1
        local sg = createGui("MedusaKill"); local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(0, 300, 0, 50); lbl.Position = UDim2.new(0.5, -150, 0.4, 0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBlack; lbl.TextSize = 32; lbl.TextColor3 = C.error; lbl.TextStrokeTransparency = 0.3; lbl.TextTransparency = 1; lbl.Text = "+" .. obj.killStreak .. " ELIMINATED"; lbl.Parent = sg
        local sub = Instance.new("TextLabel"); sub.Size = UDim2.new(0, 300, 0, 20); sub.Position = UDim2.new(0.5, -150, 0.4, 50); sub.BackgroundTransparency = 1; sub.Font = Enum.Font.GothamBold; sub.TextSize = 16; sub.TextColor3 = Color3.new(1,1,1); sub.TextStrokeTransparency = 0.4; sub.TextTransparency = 1; sub.Text = "☠️ " .. victimName; sub.Parent = sg
        TS:Create(lbl, TweenInfo.new(0.3, Enum.EasingStyle.Back), { TextTransparency = 0, TextSize = 36 }):Play(); TS:Create(sub, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
        table.insert(obj.killFeed, os.date("%H:%M") .. " ☠️ " .. victimName); if #obj.killFeed > 8 then table.remove(obj.killFeed, 1) end
        task.delay(1.5, function() TS:Create(lbl, TweenInfo.new(0.5), { TextTransparency = 1, Position = UDim2.new(0.5, -150, 0.35, 0) }):Play(); TS:Create(sub, TweenInfo.new(0.5), { TextTransparency = 1 }):Play(); task.wait(0.6); pcall(function() sg:Destroy() end) end)
    end
    local specGui = createGui("MedusaSpec"); obj.feedbackGui = specGui
    local specPanel = Instance.new("Frame"); specPanel.Size = UDim2.new(0, 170, 0, 30); specPanel.Position = UDim2.new(0, 16, 0, 50); specPanel.BackgroundColor3 = C.glass; specPanel.BackgroundTransparency = 0.15; specPanel.BorderSizePixel = 0; specPanel.Visible = false; specPanel.Parent = specGui; mkCorner(specPanel, 8)
    local specSk = Instance.new("UIStroke", specPanel); specSk.Color = C.accent; specSk.Thickness = 1; specSk.Transparency = 0.4
    local specTitle = mkLabel(specPanel, "👁️ Spectators: 0", 10, C.text, 8, 2, 1, 16); specTitle.Font = Enum.Font.GothamBold
    local specList = mkLabel(specPanel, "", 9, C.textMuted, 8, 18, 1, 40); specList.TextWrapped = true; specList.TextYAlignment = Enum.TextYAlignment.Top
    makeDraggable(specPanel, specPanel)
    task.spawn(function() local lastHP = {}; while st.running do task.wait(1/15)
        if st.hitSound and obj.lockedTarget and obj.lockedTarget.Character then pcall(function()
            local hum = obj.lockedTarget.Character:FindFirstChildOfClass("Humanoid"); if hum then
                local id = obj.lockedTarget.UserId; local prev = lastHP[id]; lastHP[id] = hum.Health
                if prev and hum.Health < prev and (prev - hum.Health) > 0.1 then if obj.hitSoundObj then obj.hitSoundObj.PlaybackSpeed = 1.0 + math.random() * 0.4; obj.hitSoundObj:Play() end end
                if prev and prev > 0 and hum.Health <= 0 then showKillPopup(obj.lockedTarget.DisplayName) end
            end
        end) end
        if st.spectatorList then pcall(function()
            local specs = {}; for _, plr in ipairs(Players:GetPlayers()) do if plr ~= player then
                local isMod = false; pcall(function() if plr.Character then for _, t in ipairs(plr.Character:GetChildren()) do if t:IsA("Tool") then local nm = t.Name:lower(); if nm:find("admin") or nm:find("ban") or nm:find("kick") or nm:find("mod") then isMod = true end end end end; if plr.Team then local tn = plr.Team.Name:lower(); if tn:find("admin") or tn:find("mod") or tn:find("staff") then isMod = true end end end)
                if not plr.Character or not plr.Character:FindFirstChildOfClass("Humanoid") or plr.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then table.insert(specs, { name = plr.DisplayName, mod = isMod }) end
            end end
            specPanel.Visible = #specs > 0; specTitle.Text = "👁️ Spectators: " .. #specs
            local lines = {}; for _, s in ipairs(specs) do table.insert(lines, s.mod and ("⚠️ [MOD] " .. s.name) or s.name) end
            specList.Text = table.concat(lines, "\n"); specPanel.Size = UDim2.new(0, 170, 0, 22 + math.max(1, #specs) * 14)
        end) else specPanel.Visible = false end
    end end)
end

-- ══════════════════════════════════════════════════════════════
--  S30C: CROSSHAIR RENDERING (4 Styles)
-- ══════════════════════════════════════════════════════════════
do
    local chGui = createGui("MedusaCrosshair")
    local chContainer = Instance.new("Frame")
    chContainer.Size = UDim2.new(0, 100, 0, 100)
    chContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    chContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
    chContainer.BackgroundTransparency = 1
    chContainer.Visible = false
    chContainer.Parent = chGui

    -- Create 4 crosshair lines (reusable for all styles)
    local lines = {}
    for i = 1, 8 do
        local line = Instance.new("Frame")
        line.BackgroundColor3 = C.accent
        line.BorderSizePixel = 0
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Parent = chContainer
        table.insert(lines, line)
        table.insert(obj.themeElements, { obj = line, prop = "BackgroundColor3" })
    end

    -- Center dot (used in Dot and T-Cross styles)
    local centerDot = Instance.new("Frame")
    centerDot.BackgroundColor3 = C.accent
    centerDot.BorderSizePixel = 0
    centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
    centerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
    centerDot.Parent = chContainer
    mkCorner(centerDot, 50)
    table.insert(obj.themeElements, { obj = centerDot, prop = "BackgroundColor3" })

    -- Circle outline (used in Circle style)
    local circleFrame = Instance.new("Frame")
    circleFrame.BackgroundTransparency = 1
    circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    circleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    circleFrame.Parent = chContainer
    mkCorner(circleFrame, 999)
    local circleSk = Instance.new("UIStroke", circleFrame)
    circleSk.Color = C.accent; circleSk.Thickness = 2; circleSk.Transparency = 0.2
    table.insert(obj.themeElements, { obj = circleSk, prop = "Color" })

    task.spawn(function()
        while st.running do
            task.wait(1 / 20)
            chContainer.Visible = st.crosshair
            if st.crosshair then
                local sz = cfg.crossSize
                local gap = cfg.crossGap
                local style = cfg.crossStyle

                -- Reset all
                for _, l in ipairs(lines) do l.Visible = false end
                centerDot.Visible = false
                circleFrame.Visible = false

                if style == 1 then -- Cross (+)
                    -- Top
                    lines[1].Visible = true; lines[1].Size = UDim2.new(0, 2, 0, sz)
                    lines[1].Position = UDim2.new(0.5, 0, 0.5, -(gap + sz))
                    -- Bottom
                    lines[2].Visible = true; lines[2].Size = UDim2.new(0, 2, 0, sz)
                    lines[2].Position = UDim2.new(0.5, 0, 0.5, gap)
                    -- Left
                    lines[3].Visible = true; lines[3].Size = UDim2.new(0, sz, 0, 2)
                    lines[3].Position = UDim2.new(0.5, -(gap + sz), 0.5, 0)
                    -- Right
                    lines[4].Visible = true; lines[4].Size = UDim2.new(0, sz, 0, 2)
                    lines[4].Position = UDim2.new(0.5, gap, 0.5, 0)

                elseif style == 2 then -- Dot
                    centerDot.Visible = true
                    centerDot.Size = UDim2.new(0, sz / 2, 0, sz / 2)

                elseif style == 3 then -- Circle
                    circleFrame.Visible = true
                    circleFrame.Size = UDim2.new(0, sz * 2, 0, sz * 2)
                    centerDot.Visible = true
                    centerDot.Size = UDim2.new(0, 4, 0, 4)

                elseif style == 4 then -- T-Cross (no top line)
                    -- Bottom
                    lines[2].Visible = true; lines[2].Size = UDim2.new(0, 2, 0, sz)
                    lines[2].Position = UDim2.new(0.5, 0, 0.5, gap)
                    -- Left
                    lines[3].Visible = true; lines[3].Size = UDim2.new(0, sz, 0, 2)
                    lines[3].Position = UDim2.new(0.5, -(gap + sz), 0.5, 0)
                    -- Right
                    lines[4].Visible = true; lines[4].Size = UDim2.new(0, sz, 0, 2)
                    lines[4].Position = UDim2.new(0.5, gap, 0.5, 0)
                    centerDot.Visible = true
                    centerDot.Size = UDim2.new(0, 4, 0, 4)
                end
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
--  S30D: FOV CIRCLE (GUI-based, follows mouse)
-- ══════════════════════════════════════════════════════════════
do
    local fovGui = createGui("MedusaFOV")
    local fovCircle = Instance.new("Frame")
    fovCircle.BackgroundTransparency = 1
    fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    fovCircle.Visible = false
    fovCircle.Parent = fovGui
    mkCorner(fovCircle, 9999)
    local fovSk = Instance.new("UIStroke", fovCircle)
    fovSk.Color = C.purple; fovSk.Thickness = 2; fovSk.Transparency = 0.3
    table.insert(obj.themeElements, { obj = fovSk, prop = "Color" })
    obj.fovCircle = fovCircle
    obj.fovStroke = fovSk

    addConn(RS.RenderStepped:Connect(function()
        if st.aimbot and rmbDown then
            local mp = UIS:GetMouseLocation()
            local radius = cfg.aimbotFOV
            fovCircle.Visible = true
            fovCircle.Size = UDim2.new(0, radius * 2, 0, radius * 2)
            fovCircle.Position = UDim2.new(0, mp.X, 0, mp.Y)
        else
            fovCircle.Visible = false
        end
    end))
end

-- ══════════════════════════════════════════════════════════════
--  S30E: GHOST MODE (panel fades when mouse away)
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    while st.running do
        task.wait(0.3)
        if st.ghostMode and panel and panel.Parent then
            pcall(function()
                local mp = UIS:GetMouseLocation()
                local pp = panel.AbsolutePosition
                local ps = panel.AbsoluteSize
                local isHovering = mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
                local targetTrans = isHovering and cfg.gui.panelOpacity or 0.92
                TS:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {
                    BackgroundTransparency = targetTrans
                }):Play()
                -- Also fade sidebar and topbar
                local sideTarget = isHovering and 0.25 or 0.88
                local topTarget = isHovering and 0.15 or 0.88
                if sidebar then TS:Create(sidebar, TweenInfo.new(0.4), { BackgroundTransparency = sideTarget }):Play() end
                if topbar then TS:Create(topbar, TweenInfo.new(0.4), { BackgroundTransparency = topTarget }):Play() end
            end)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  S31: PLAYERS TAB + STARTUP
-- ══════════════════════════════════════════════════════════════
function refreshPlayers()
    if not obj.playersContainer then return end
    for _, c in ipairs(obj.playersContainer:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for _, plr in ipairs(Players:GetPlayers()) do if plr ~= player then pcall(function()
        -- Admin detection
        local isAdmin = false
        if st.adminDetector then
            local nameCheck = (plr.Name .. " " .. plr.DisplayName):lower()
            if nameCheck:find("admin") or nameCheck:find("mod") or nameCheck:find("staff") or nameCheck:find("owner") or nameCheck:find("dev") then isAdmin = true end
            -- Check tools for admin commands
            if not isAdmin and plr.Character then
                for _, item in ipairs(plr.Character:GetChildren()) do
                    if item:IsA("Tool") then
                        local toolName = item.Name:lower()
                        if toolName:find("admin") or toolName:find("ban") or toolName:find("kick") or toolName:find("mod") or toolName:find("cmd") then isAdmin = true; break end
                    end
                end
            end
            -- Check backpack for admin tools
            if not isAdmin then pcall(function()
                for _, item in ipairs(plr.Backpack:GetChildren()) do
                    if item:IsA("Tool") then
                        local toolName = item.Name:lower()
                        if toolName:find("admin") or toolName:find("ban") or toolName:find("kick") or toolName:find("mod") then isAdmin = true; break end
                    end
                end
            end) end
            -- Check team for admin/mod
            if not isAdmin and plr.Team then
                local teamName = plr.Team.Name:lower()
                if teamName:find("admin") or teamName:find("mod") or teamName:find("staff") then isAdmin = true end
            end
        end
        local card = Instance.new("Frame"); card.Size = UDim2.new(1, 0, 0, 62)
        card.BackgroundColor3 = isAdmin and Color3.fromRGB(35, 10, 10) or C.glass
        card.BackgroundTransparency = isAdmin and 0.2 or 0.35; card.BorderSizePixel = 0; card.Parent = obj.playersContainer; mkCorner(card, 8)
        if isAdmin then local sk = Instance.new("UIStroke", card); sk.Color = C.error; sk.Thickness = 1.5; sk.Transparency = 0.3 end
        local nameColor = isAdmin and C.error or C.text
        local nameText = isAdmin and ("⚠️ [ADMIN] " .. plr.DisplayName) or plr.DisplayName
        mkLabel(card, nameText, 12, nameColor, 12, 4); mkLabel(card, "@" .. plr.Name, 10, C.textMuted, 12, 20)
        local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid"); local pct = hum and hum.MaxHealth > 0 and (hum.Health / hum.MaxHealth) or 1
        local hpBg = Instance.new("Frame"); hpBg.Size = UDim2.new(0.5, 0, 0, 4); hpBg.Position = UDim2.new(0, 12, 0, 40); hpBg.BackgroundColor3 = Color3.fromRGB(40,40,40); hpBg.BorderSizePixel = 0; hpBg.Parent = card; mkCorner(hpBg, 2)
        local hpFill = Instance.new("Frame"); hpFill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0); hpFill.BackgroundColor3 = pct > 0.5 and C.success or pct > 0.25 and C.warning or C.error; hpFill.BorderSizePixel = 0; hpFill.Parent = hpBg; mkCorner(hpFill, 2)
        for bi, bd in ipairs({{"📷", C.blue}, {"💥", C.error}, {"🏃", C.success}}) do
            local b = Instance.new("TextButton"); b.Size = UDim2.new(0, 44, 0, 24); b.Position = UDim2.new(1, -(44 * (4 - bi) + 6 * (4 - bi)), 0, 4)
            b.BackgroundColor3 = C.glass; b.BackgroundTransparency = 0.4; b.BorderSizePixel = 0; b.AutoButtonColor = false; b.Font = Enum.Font.GothamBold; b.TextSize = 14; b.TextColor3 = bd[2]; b.Text = bd[1]; b.Parent = card; mkCorner(b, 6)
            if bi == 1 then b.MouseButton1Click:Connect(function() pcall(function() if plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then camera.CameraSubject = plr.Character:FindFirstChildOfClass("Humanoid"); notify("📷 Spectating: " .. plr.DisplayName, C.blue) end end) end)
            elseif bi == 2 then b.MouseButton1Click:Connect(function() pcall(function() local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); local tHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart"); if hrp and tHrp then hrp.CFrame = tHrp.CFrame; hrp.Velocity = Vector3.new(math.random(-500, 500), 500, math.random(-500, 500)); notify("💥 Flung: " .. plr.DisplayName, C.error) end end) end)
            elseif bi == 3 then b.MouseButton1Click:Connect(function() pcall(function() local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); local tHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart"); if hrp and tHrp then hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, -3); notify("🏃 TP to: " .. plr.DisplayName, C.success) end end) end) end
        end
    end) end end
end

task.spawn(function() while st.running do task.wait(5); if obj.currentTab == "players" then pcall(function() refreshPlayers() end) end end end)

-- ══════════════════════════════════════════════════════════════
--  S31C: ACTIVE HUD (Keybind List — top right corner)
-- ══════════════════════════════════════════════════════════════
do
    local hudGui = createGui("MedusaActiveHUD")
    obj.activeHudGui = hudGui

    local hudFrame = Instance.new("Frame")
    hudFrame.Size = UDim2.new(0, 180, 0, 0)
    hudFrame.AutomaticSize = Enum.AutomaticSize.Y
    hudFrame.Position = UDim2.new(1, -195, 0, 12)
    hudFrame.BackgroundColor3 = C.bg
    hudFrame.BackgroundTransparency = 0.25
    hudFrame.BorderSizePixel = 0; hudFrame.Parent = hudGui
    mkCorner(hudFrame, 10)
    local hudSk = Instance.new("UIStroke", hudFrame)
    hudSk.Color = C.accent; hudSk.Thickness = 1; hudSk.Transparency = 0.5
    table.insert(obj.themeElements, { obj = hudSk, prop = "Color" })

    -- Header
    local hudTitle = Instance.new("TextLabel")
    hudTitle.Size = UDim2.new(1, 0, 0, 22)
    hudTitle.BackgroundTransparency = 1; hudTitle.Font = Enum.Font.GothamBold
    hudTitle.TextSize = 10; hudTitle.TextColor3 = C.accent
    hudTitle.Text = "🐍 ACTIVE MODULES"; hudTitle.Parent = hudFrame
    table.insert(obj.themeElements, { obj = hudTitle, prop = "TextColor3" })

    local hudList = Instance.new("Frame")
    hudList.Size = UDim2.new(1, -12, 0, 0)
    hudList.AutomaticSize = Enum.AutomaticSize.Y
    hudList.Position = UDim2.new(0, 6, 0, 22)
    hudList.BackgroundTransparency = 1; hudList.Parent = hudFrame
    local hudLayout = Instance.new("UIListLayout", hudList)
    hudLayout.Padding = UDim.new(0, 1); hudLayout.SortOrder = Enum.SortOrder.Name
    Instance.new("UIPadding", hudList).PaddingBottom = UDim.new(0, 6)

    obj.activeHudFrame = hudList

    -- Feature map: key → display name + icon
    local hudFeatures = {
        { key = "esp",       name = "👁️ ESP" },
        { key = "aimbot",    name = "🎯 Aimbot" },
        { key = "silentAim", name = "🔇 Silent Aim" },
        { key = "triggerBot",name = "🔫 Trigger Bot" },
        { key = "fly",       name = "✈️ Fly" },
        { key = "noclip",    name = "👻 Noclip" },
        { key = "speed",     name = "🏃 Speed" },
        { key = "infJump",   name = "🦘 Inf Jump" },
        { key = "hitbox",    name = "📦 Hitbox" },
        { key = "spinBot",   name = "🔄 SpinBot" },
        { key = "fullbright",name = "💡 Fullbright" },
        { key = "crosshair", name = "➕ Crosshair" },
        { key = "viewAngles",name = "👁️ View Angles" },
        { key = "metatableBypass", name = "🛡️ Anti-Cheat" },
    }

    -- Create labels for each feature
    for _, feat in ipairs(hudFeatures) do
        local row = Instance.new("Frame")
        row.Name = feat.key
        row.Size = UDim2.new(1, 0, 0, 16)
        row.BackgroundTransparency = 1
        row.Visible = st[feat.key] == true
        row.Parent = hudList

        -- Green dot
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 6, 0, 6)
        dot.Position = UDim2.new(0, 4, 0.5, -3)
        dot.BackgroundColor3 = C.success; dot.BorderSizePixel = 0; dot.Parent = row
        mkCorner(dot, 3)

        -- Feature name
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -18, 1, 0)
        lbl.Position = UDim2.new(0, 16, 0, 0)
        lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 10; lbl.TextColor3 = C.text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = feat.name; lbl.Parent = row

        obj.activeHudLabels[feat.key] = row
    end

    -- Update loop: sync HUD with st[] every 0.3s
    task.spawn(function()
        while st.running do
            task.wait(0.3)
            local anyActive = false
            for _, feat in ipairs(hudFeatures) do
                local row = obj.activeHudLabels[feat.key]
                if row then
                    local active = st[feat.key] == true
                    row.Visible = active
                    if active then anyActive = true end
                end
            end
            hudFrame.Visible = anyActive
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
--  S31D: CUSTOM CURSOR (Accent crosshair when panel is open)
-- ══════════════════════════════════════════════════════════════
do
    local curGui = createGui("MedusaCursor")
    curGui.IgnoreGuiInset = true
    obj.cursorGui = curGui

    local curFrame = Instance.new("Frame")
    curFrame.Size = UDim2.new(0, 24, 0, 24)
    curFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    curFrame.BackgroundTransparency = 1
    curFrame.BorderSizePixel = 0
    curFrame.ZIndex = 99999
    curFrame.Visible = false
    curFrame.Parent = curGui
    obj.cursorFrame = curFrame

    -- Crosshair lines (4 lines forming a cross)
    local lineThick = 2
    local lineLen = 8
    local gap = 3

    -- Up
    local lU = Instance.new("Frame", curFrame)
    lU.Size = UDim2.new(0, lineThick, 0, lineLen)
    lU.Position = UDim2.new(0.5, -lineThick/2, 0.5, -(gap + lineLen))
    lU.BackgroundColor3 = C.accent; lU.BorderSizePixel = 0; lU.ZIndex = 99999
    table.insert(obj.themeElements, { obj = lU, prop = "BackgroundColor3" })

    -- Down
    local lD = Instance.new("Frame", curFrame)
    lD.Size = UDim2.new(0, lineThick, 0, lineLen)
    lD.Position = UDim2.new(0.5, -lineThick/2, 0.5, gap)
    lD.BackgroundColor3 = C.accent; lD.BorderSizePixel = 0; lD.ZIndex = 99999
    table.insert(obj.themeElements, { obj = lD, prop = "BackgroundColor3" })

    -- Left
    local lL = Instance.new("Frame", curFrame)
    lL.Size = UDim2.new(0, lineLen, 0, lineThick)
    lL.Position = UDim2.new(0.5, -(gap + lineLen), 0.5, -lineThick/2)
    lL.BackgroundColor3 = C.accent; lL.BorderSizePixel = 0; lL.ZIndex = 99999
    table.insert(obj.themeElements, { obj = lL, prop = "BackgroundColor3" })

    -- Right
    local lR = Instance.new("Frame", curFrame)
    lR.Size = UDim2.new(0, lineLen, 0, lineThick)
    lR.Position = UDim2.new(0.5, gap, 0.5, -lineThick/2)
    lR.BackgroundColor3 = C.accent; lR.BorderSizePixel = 0; lR.ZIndex = 99999
    table.insert(obj.themeElements, { obj = lR, prop = "BackgroundColor3" })

    -- Center dot
    local cDot = Instance.new("Frame", curFrame)
    cDot.Size = UDim2.new(0, 3, 0, 3)
    cDot.Position = UDim2.new(0.5, -1.5, 0.5, -1.5)
    cDot.BackgroundColor3 = C.accent; cDot.BorderSizePixel = 0; cDot.ZIndex = 99999
    mkCorner(cDot, 2)
    table.insert(obj.themeElements, { obj = cDot, prop = "BackgroundColor3" })

    -- Cursor follows mouse — only when panel is visible AND mouse is over panel
    local cursorActive = false
    addConn(RunService.RenderStepped:Connect(function()
        if not st.running then return end
        local mp = UIS:GetMouseLocation()
        -- Show custom cursor when hovering over the Medusa panel
        local panelObj = obj.panel
        if panelObj and panelObj.Visible and st.guiVisible then
            local px = panelObj.AbsolutePosition.X
            local py = panelObj.AbsolutePosition.Y
            local pw = panelObj.AbsoluteSize.X
            local ph = panelObj.AbsoluteSize.Y
            local isOver = mp.X >= px and mp.X <= px + pw and mp.Y >= py and mp.Y <= py + ph
            if isOver then
                curFrame.Visible = true
                curFrame.Position = UDim2.new(0, mp.X, 0, mp.Y)
                if not cursorActive then
                    cursorActive = true
                    pcall(function() UIS.MouseIconEnabled = false end)
                end
            else
                if cursorActive then
                    cursorActive = false
                    curFrame.Visible = false
                    pcall(function() UIS.MouseIconEnabled = true end)
                end
            end
        else
            if cursorActive then
                cursorActive = false
                curFrame.Visible = false
                pcall(function() UIS.MouseIconEnabled = true end)
            end
        end
    end))
end

-- ══════════════════════════════════════════════════════════════
--  S32: CINEMATIC INTRO & STARTUP (v15.1 CINEMATIC EDITION)
-- ══════════════════════════════════════════════════════════════
switchTab("status")
pcall(function() refreshPlayers() end)

-- ── PHASE 0: Hide main panel completely ────────────────────
panel.Visible = false

-- ── CINEMATIC INTRO SCREEN ──────────────────────────────────
local introGui = Instance.new("ScreenGui")
introGui.Name = "MedusaCinematic_" .. math.random(1000, 9999)
introGui.DisplayOrder = 999; introGui.IgnoreGuiInset = true
introGui.ResetOnSpawn = false; introGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() introGui.Parent = guiParent end)

-- Black cinematic backdrop
local introBG = Instance.new("Frame")
introBG.Size = UDim2.new(1, 0, 1, 0); introBG.BackgroundColor3 = Color3.fromRGB(2, 2, 5)
introBG.BackgroundTransparency = 0; introBG.BorderSizePixel = 0; introBG.ZIndex = 1
introBG.Parent = introGui

-- ── Glitch Snake Icon ──────────────────────────────────────
local snakeContainer = Instance.new("Frame")
snakeContainer.Size = UDim2.new(0, 300, 0, 80); snakeContainer.Position = UDim2.new(0.5, -150, 0.35, 0)
snakeContainer.BackgroundTransparency = 1; snakeContainer.ZIndex = 10; snakeContainer.Parent = introBG

-- Main snake emoji
local snakeMain = Instance.new("TextLabel")
snakeMain.Size = UDim2.new(0, 60, 0, 60); snakeMain.Position = UDim2.new(0, 0, 0, 10)
snakeMain.BackgroundTransparency = 1; snakeMain.Font = Enum.Font.GothamBlack
snakeMain.TextSize = 48; snakeMain.TextColor3 = Color3.new(1, 1, 1); snakeMain.Text = "🐍"
snakeMain.ZIndex = 12; snakeMain.Parent = snakeContainer

-- Red glitch offset (RGB effect)
local snakeR = Instance.new("TextLabel")
snakeR.Size = UDim2.new(0, 60, 0, 60); snakeR.Position = UDim2.new(0, 3, 0, 8)
snakeR.BackgroundTransparency = 1; snakeR.Font = Enum.Font.GothamBlack
snakeR.TextSize = 48; snakeR.TextColor3 = Color3.fromRGB(255, 0, 80); snakeR.TextTransparency = 0.6
snakeR.Text = "🐍"; snakeR.ZIndex = 11; snakeR.Parent = snakeContainer

-- Cyan glitch offset
local snakeC = Instance.new("TextLabel")
snakeC.Size = UDim2.new(0, 60, 0, 60); snakeC.Position = UDim2.new(0, -3, 0, 12)
snakeC.BackgroundTransparency = 1; snakeC.Font = Enum.Font.GothamBlack
snakeC.TextSize = 48; snakeC.TextColor3 = Color3.fromRGB(0, 255, 220); snakeC.TextTransparency = 0.6
snakeC.Text = "🐍"; snakeC.ZIndex = 11; snakeC.Parent = snakeContainer

-- Title "MEDUSA"
local introTitle = Instance.new("TextLabel")
introTitle.Size = UDim2.new(0, 220, 0, 50); introTitle.Position = UDim2.new(0, 70, 0, 15)
introTitle.BackgroundTransparency = 1; introTitle.Font = Enum.Font.GothamBlack
introTitle.TextSize = 44; introTitle.TextColor3 = Color3.new(1, 1, 1); introTitle.Text = "MEDUSA"
introTitle.ZIndex = 12; introTitle.Parent = snakeContainer

-- Title glitch layers
local titleR = introTitle:Clone(); titleR.TextColor3 = Color3.fromRGB(255, 0, 80)
titleR.TextTransparency = 0.65; titleR.Position = UDim2.new(0, 73, 0, 13); titleR.ZIndex = 11
titleR.Parent = snakeContainer

local titleC = introTitle:Clone(); titleC.TextColor3 = Color3.fromRGB(0, 255, 220)
titleC.TextTransparency = 0.65; titleC.Position = UDim2.new(0, 67, 0, 17); titleC.ZIndex = 11
titleC.Parent = snakeContainer

-- Subtitle
local introSub = Instance.new("TextLabel")
introSub.Size = UDim2.new(0, 300, 0, 20); introSub.Position = UDim2.new(0.5, -150, 0.35, 85)
introSub.BackgroundTransparency = 1; introSub.Font = Enum.Font.GothamMedium
introSub.TextSize = 13; introSub.TextColor3 = C.textMuted; introSub.TextTransparency = 0.3
introSub.Text = "v15.1 — CINEMATIC EDITION"; introSub.ZIndex = 10; introSub.Parent = introBG

-- ── Progress Bar ───────────────────────────────────────────
local barBG = Instance.new("Frame")
barBG.Size = UDim2.new(0, 280, 0, 6); barBG.Position = UDim2.new(0.5, -140, 0.35, 120)
barBG.BackgroundColor3 = Color3.fromRGB(25, 25, 35); barBG.BorderSizePixel = 0; barBG.ZIndex = 10
barBG.Parent = introBG; mkCorner(barBG, 3)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0); barFill.BackgroundColor3 = C.accent
barFill.BorderSizePixel = 0; barFill.ZIndex = 11; barFill.Parent = barBG; mkCorner(barFill, 3)

-- Glow on fill
local barGlow = Instance.new("UIStroke", barFill)
barGlow.Color = C.accent; barGlow.Thickness = 1.5; barGlow.Transparency = 0.4

-- Percentage
local barPct = Instance.new("TextLabel")
barPct.Size = UDim2.new(0, 280, 0, 18); barPct.Position = UDim2.new(0.5, -140, 0.35, 132)
barPct.BackgroundTransparency = 1; barPct.Font = Enum.Font.GothamBold
barPct.TextSize = 14; barPct.TextColor3 = C.accent; barPct.Text = "0%"
barPct.ZIndex = 10; barPct.Parent = introBG

-- Status text
local barStatus = Instance.new("TextLabel")
barStatus.Size = UDim2.new(0, 300, 0, 16); barStatus.Position = UDim2.new(0.5, -150, 0.35, 155)
barStatus.BackgroundTransparency = 1; barStatus.Font = Enum.Font.Gotham
barStatus.TextSize = 11; barStatus.TextColor3 = C.textMuted; barStatus.Text = ""
barStatus.ZIndex = 10; barStatus.Parent = introBG

-- Credits at bottom
local introCreds = Instance.new("TextLabel")
introCreds.Size = UDim2.new(1, 0, 0, 20); introCreds.Position = UDim2.new(0, 0, 1, -40)
introCreds.BackgroundTransparency = 1; introCreds.Font = Enum.Font.Gotham
introCreds.TextSize = 10; introCreds.TextColor3 = Color3.fromRGB(60, 60, 70)
introCreds.Text = "Made by .donatorexe.  •  Xeno Optimized"; introCreds.ZIndex = 10
introCreds.Parent = introBG

-- ── Glitch Animation Loop ──────────────────────────────────
local glitchRunning = true
task.spawn(function()
    while glitchRunning do
        -- Randomize glitch offsets rapidly
        local rx, ry = math.random(-4, 4), math.random(-3, 3)
        local cx, cy = math.random(-4, 4), math.random(-3, 3)
        snakeR.Position = UDim2.new(0, rx, 0, 10 + ry)
        snakeC.Position = UDim2.new(0, cx, 0, 10 + cy)
        titleR.Position = UDim2.new(0, 70 + rx, 0, 15 + ry)
        titleC.Position = UDim2.new(0, 70 + cx, 0, 15 + cy)
        -- Random transparency flicker
        local flicker = math.random() > 0.85
        snakeR.TextTransparency = flicker and 0.3 or 0.65
        snakeC.TextTransparency = flicker and 0.3 or 0.65
        titleR.TextTransparency = flicker and 0.3 or 0.65
        titleC.TextTransparency = flicker and 0.3 or 0.65
        -- Occasional full glitch flash
        if math.random() > 0.93 then
            snakeMain.TextTransparency = 0.3
            introTitle.TextTransparency = 0.3
            task.wait(0.03)
            snakeMain.TextTransparency = 0
            introTitle.TextTransparency = 0
        end
        task.wait(0.04) -- 25fps glitch
    end
end)

-- ── Boot Sound (rbxassetid://550209561) ────────────────────
local bootSound = createSound(550209561, 0.4, 1)

-- ── Loading Sequence (Real tasks with progress) ────────────
local function setProgress(pct, status)
    TS:Create(barFill, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {
        Size = UDim2.new(pct / 100, 0, 1, 0)
    }):Play()
    barPct.Text = math.floor(pct) .. "%"
    barStatus.Text = status
end

-- Phase 1: Init (0% → 20%)
pcall(function() bootSound:Play() end)
setProgress(0, "Initializing Medusa Protocol...")
task.wait(0.6)
setProgress(12, "Loading configuration files...")
task.wait(0.4)
setProgress(20, "Medusa core initialized ✓")
task.wait(0.3)

-- Phase 2: Bypass (20% → 50%)
setProgress(28, "Bypassing Security Systems...")
task.wait(0.5)
setProgress(38, "Injecting metatable hooks...")
task.wait(0.4)
setProgress(50, "Anti-cheat layer active ✓")
task.wait(0.3)

-- Phase 3: Location (50% → 80%)
setProgress(55, "Identifying Server Location...")
task.wait(0.5)
setProgress(68, "Resolving geo-IP: " .. svRegion)
task.wait(0.4)
setProgress(80, "Server identified ✓")
task.wait(0.3)

-- Phase 4: Sync (80% → 100%)
setProgress(85, "Synchronizing Interface...")
task.wait(0.4)
setProgress(92, "Building dashboard modules...")
task.wait(0.3)
setProgress(100, "🐍 MEDUSA v15.1 READY")

-- Change to green
task.wait(0.2)
local emerald = Color3.fromRGB(0, 200, 120)
TS:Create(barFill, TweenInfo.new(0.3), { BackgroundColor3 = emerald }):Play()
TS:Create(barGlow, TweenInfo.new(0.3), { Color = emerald }):Play()
barPct.TextColor3 = emerald
barStatus.TextColor3 = emerald
introTitle.TextColor3 = emerald
snakeMain.TextColor3 = emerald

-- Stop glitch, stabilize
task.wait(0.5)
glitchRunning = false
snakeR.TextTransparency = 1; snakeC.TextTransparency = 1
titleR.TextTransparency = 1; titleC.TextTransparency = 1

-- ── Transition: Fade out intro, slide up panel ─────────────
task.wait(0.3)

-- Whoosh sound (rbxassetid://9114221515)
local whooshSound = createSound(9114221515, 0.35, 1)
pcall(function() whooshSound:Play() end)

-- Fade out intro
TS:Create(introBG, TweenInfo.new(0.6, Enum.EasingStyle.Quint), { BackgroundTransparency = 1 }):Play()
for _, child in ipairs(introBG:GetDescendants()) do
    pcall(function()
        if child:IsA("TextLabel") then
            TS:Create(child, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
        elseif child:IsA("Frame") then
            TS:Create(child, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
        end
    end)
end

task.wait(0.4)
pcall(function() introGui:Destroy() end)

-- ── Show panel + slide up animation ────────────────────────
showBlur() -- Glassmorphism blur on startup
panel.Visible = true
panel.BackgroundTransparency = 1
if sidebar then sidebar.BackgroundTransparency = 1 end
if topbar then topbar.BackgroundTransparency = 1 end
if panelStroke then panelStroke.Transparency = 1 end

local finalPos = panel.Position
panel.Position = UDim2.new(finalPos.X.Scale, finalPos.X.Offset, finalPos.Y.Scale, finalPos.Y.Offset + 50)

-- Slide up + fade in
task.delay(0.1, function()
    TS:Create(panel, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = finalPos, BackgroundTransparency = cfg.gui.panelOpacity
    }):Play()
end)
task.delay(0.3, function()
    if panelStroke then TS:Create(panelStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { Transparency = 0.15 }):Play() end
end)
task.delay(0.4, function()
    if sidebar then TS:Create(sidebar, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { BackgroundTransparency = 0.25 }):Play() end
end)
task.delay(0.5, function()
    if topbar then TS:Create(topbar, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { BackgroundTransparency = 0.15 }):Play() end
end)
task.delay(0.7, function()
    for _, tf in pairs(obj.tabFrames) do pcall(function() tf.ScrollBarImageTransparency = 0.5 end) end
end)

-- (Duplicate Active HUD removed — S31C handles it correctly)

-- (Duplicate cursor removed — S31D handles it correctly)

-- ── Close/Eject button ─────────────────────────────────────
closeBtn.MouseButton1Click:Connect(function()
    Notify("🗑️ EJECT", "Shutting down Medusa...", 2)
    task.delay(0.5, doEject)
end)

-- ── Delayed notifications ──────────────────────────────────
task.delay(2.5, function()
    if configLoaded and XC.readfile then
        Notify("💾 Config Loaded", "Elite settings restored from Medusa_Config.json", 4)
    end
end)
task.delay(3, function()
    if st.discordRPC and cfg.discordWebhook ~= "" then
        Notify("📡 Discord RPC", "Rich Presence active — updating every 60s", 3)
    end
end)
task.delay(3.5, function()
    if st.metatableBypass then
        Notify("🛡️ Anti-Cheat", "Metatable Bypass active — values spoofed", 3)
    end
end)

-- Final welcome
task.delay(2, function()
    Notify("🐍 MEDUSA v15.1", "Cinematic Edition — All systems operational!", 5)
end)

-- Auto-load default profile
task.delay(3, function()
    pcall(function()
        if XC.isfile and XC.isfile("Medusa/Configs/default.json") then
            local raw = XC.readfile("Medusa/Configs/default.json")
            if raw and raw ~= "" then
                local data = HttpService:JSONDecode(raw)
                if data then
                    for k, v in pairs(data) do
                        if type(v) ~= "table" then cfg[k] = v
                        elseif k == "gui" then for gk, gv in pairs(v) do cfg.gui[gk] = gv end end
                    end
                    Notify("📂 Auto-Load", "Profile 'default' restored", 3)
                end
            end
        end
    end)
end)

-- Cleanup boot sounds
task.delay(8, function()
    pcall(function() bootSound:Destroy() end)
    pcall(function() whooshSound:Destroy() end)
end)

print("═══════════════════════════════════════")
print("  🐍 MEDUSA v15.1 — CINEMATIC EDITION")
print("  Made by .donatorexe.")
print("  Xeno Executor Optimized")
print("  50+ features • 10 tabs • Glassmorphism")
print("  Cinematic Intro • Active HUD • Custom Cursor")
print("  Glitch Animation • Boot Sounds • RGB Crosshair")
print("═══════════════════════════════════════")
print("Medusa v15.1: Cinematic Build Concluido")
