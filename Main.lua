if not game:IsLoaded() then game.Loaded:Wait() end

-- // Studio Detection
local isStudio = not pcall(function() assert(getgenv) end)

-- // Prevent double loading
if isStudio then
    if _G.UUI_Loaded then return end
    _G.UUI_Loaded = true
else
    if getgenv().UUI_Loaded then return end
    getgenv().UUI_Loaded = true
end

-- // Shim Compatibility
local function missing(t, f, fallback)
    if type(f) == t then return f end
    return fallback
end

local function stub() return end
local function stubTrue() return true end
local function stubFalse() return false end

-- // Compatibility Shims (stubs in Studio)
cloneref          = missing("function", cloneref, function(...) return ... end)
checkcaller       = missing("function", checkcaller, stubFalse)
newcclosure       = missing("function", newcclosure, function(f) return f end)
hookfunction      = missing("function", hookfunction, stub)
hookmetamethod    = missing("function", hookmetamethod, stub)
getgc             = missing("function", getgc or get_gc_objects, stub)
replicatesignal   = missing("function", replicatesignal, stub)
firetouchinterest = missing("function", firetouchinterest, stub)

sethidden         = missing("function", sethiddenproperty or set_hidden_property or set_hidden_prop, stub)
gethidden         = missing("function", gethiddenproperty or get_hidden_property or get_hidden_prop, stub)
getnamecallmethod = missing("function", getnamecallmethod or get_namecall_method, stub)
getconnections    = missing("function", getconnections or get_signal_cons, stub)
setthreadidentity = missing("function", setthreadidentity or set_thread_identity or setthreadcontext
    or (syn and syn.set_thread_identity), stub)

queueteleport     = missing("function", queue_on_teleport
    or (syn and syn.queue_on_teleport)
    or (fluxus and fluxus.queue_on_teleport), stub)

httprequest       = missing("function", request or http_request
    or (syn and syn.request)
    or (http and http.request)
    or (fluxus and fluxus.request), stub)

everyClipboard    = missing("function", setclipboard or toclipboard or set_clipboard
    or (Clipboard and Clipboard.set), stub)

waxgetcustomasset = missing("function", getcustomasset or getsynasset, stub)

-- // File System (stubs in Studio)
local _writefile = missing("function", writefile, stub)
local _readfile  = missing("function", readfile, stub)

writefile = function(file, data, safe)
    if safe then return pcall(_writefile, file, data) end
    _writefile(file, data)
end

readfile = function(file, safe)
    if safe then return pcall(_readfile, file) end
    return _readfile(file)
end

isfile = missing("function", isfile, function(file)
    local ok, result = pcall(readfile, file)
    return ok and result ~= nil and result ~= ""
end)

makefolder = missing("function", makefolder, stub)
isfolder   = missing("function", isfolder, stubFalse)

-- // Services
local Services = setmetatable({}, {
    __index = function(self, name)
        local ok, service = pcall(function()
            return cloneref(game:GetService(name))
        end)
        if ok then
            rawset(self, name, service)
            return service
        end
        error("Invalid service: " .. tostring(name))
    end
})

-- // Service Aliases
local Players              = Services.Players
local UserInputService     = Services.UserInputService
local TweenService         = Services.TweenService
local HttpService          = Services.HttpService
local MarketplaceService   = Services.MarketplaceService
local RunService           = Services.RunService
local TeleportService      = Services.TeleportService
local StarterGui           = Services.StarterGui
local GuiService           = Services.GuiService
local Lighting             = Services.Lighting
local ContextActionService = Services.ContextActionService
local ReplicatedStorage    = Services.ReplicatedStorage
local GroupService         = Services.GroupService
local PathService          = Services.PathfindingService
local SoundService         = Services.SoundService
local Teams                = Services.Teams
local StarterPlayer        = Services.StarterPlayer
local InsertService        = Services.InsertService
local ChatService          = Services.Chat
local ProximityPromptService = Services.ProximityPromptService
local ContentProvider      = Services.ContentProvider
local StatsService         = Services.Stats
local MaterialService      = Services.MaterialService
local AvatarEditorService  = Services.AvatarEditorService
local TextService          = Services.TextService
local TextChatService      = Services.TextChatService
local CaptureService       = Services.CaptureService
local VoiceChatService     = Services.VoiceChatService
local SocialService        = Services.SocialService
local WorkspaceService     = Services.Workspace

-- // Local Player
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = cloneref(LocalPlayer:FindFirstChildWhichIsA("PlayerGui"))

-- // CoreGui — falls back to PlayerGui in Studio
local COREGUI = PlayerGui
if not RunService:IsStudio() then
    local ok, coreGui = pcall(function() return Services.CoreGui end)
    COREGUI = ok and coreGui or PlayerGui
end

local Mouse  = cloneref(LocalPlayer:GetMouse())
local PlaceId  = game.PlaceId
local JobId    = game.JobId
local GameName = game.Name

-- // Platform Detection
local IsOnMobile
xpcall(function()
    IsOnMobile = table.find({Enum.Platform.Android, Enum.Platform.IOS}, UserInputService:GetPlatform()) ~= nil
end, function()
    IsOnMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end)

-- // Chat Version
local isLegacyChat = TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService


---- Constants ---------------------------------------------------------------------------------------------
--[[
{Name = '', Type = 'Info', LayoutOrder = 1, Data = {"desc"}},
{Name = '', Type = 'Bool', LayoutOrder = 1, Data = {"desc", false}},
{Name = '', Type = 'Slider', LayoutOrder = 1, Data = {"desc", default, min, max, increment}},
{Name = '', Type = 'Button', LayoutOrder = 1, Data = {"desc"}},
{Name = '', Type = 'Textbox', LayoutOrder = 1, Data = {"desc", "default"}},
{Name = '', Type = 'Dropdown', LayoutOrder = 1, Data = {"desc", default index, {"", "", ""}}}
{Name = '', Type = 'Spacing', LayoutOrder = 1, Data = {space -- px}},
]]

local PROPERTIES = {
    ["Home"]     = {LayoutOrder = 1, Divider = true, Image = "rbxassetid://132236849357567", 
        Values = {
            -- // Branding
            {Name = "UIName",        Type = "Info",   LayoutOrder = 1,  Data = {"UNIVERSAL UI"}},
            {Name = "Tagline",       Type = "Info",   LayoutOrder = 2,  Data = {"One Script, All Games."}},
            {Name = "Creator",       Type = "Info",   LayoutOrder = 3,  Data = {"By Hebebebe0942 on Discord."}},
            
            -- // Game Info
            {Name = "GameName",      Type = "Info",   LayoutOrder = 4,  Data = {""}}, -- filled in dynamically
            {Name = "PlaceId",       Type = "Info",   LayoutOrder = 5,  Data = {""}}, -- filled in dynamically
            {Name = "CopyPlaceId",   Type = "Button", LayoutOrder = 6,  Data = {"Copy Place ID"}},
            {Name = "ServerHop",     Type = "Button", LayoutOrder = 7,  Data = {"Server Hop"}},
            {Name = "RejoinServer",  Type = "Button", LayoutOrder = 8,  Data = {"Rejoin Server"}},
            
            -- // Player Info
            {Name = "PlayerName",    Type = "Info",   LayoutOrder = 9,  Data = {""}}, -- filled in dynamically
            {Name = "UserId",        Type = "Info",   LayoutOrder = 10, Data = {""}}, -- filled in dynamically
            {Name = "CopyUserId",    Type = "Button", LayoutOrder = 11, Data = {"Copy User ID"}},
            
            -- // UI Settings
           -- {Name = "HideKeybind",   Type = "Keybind",  LayoutOrder = 12, Data = {"Hide UI Keybind", "RightShift"}},
            {Name = "Notifications", Type = "Bool",     LayoutOrder = 13, Data = {"Notifications", true}},
            {Name = "AutoExecute",   Type = "Bool",     LayoutOrder = 14, Data = {"Auto Execute", true}},
            
           
        }    
    };
    ["Player"]   = {LayoutOrder = 2, Divider = true, Image = "rbxassetid://88931379871493",
        Values = {
            -- // Walk Speed
            {Name = 'WalkSpeedToggled'              ,Type = 'Bool',     LayoutOrder = 1,  Data = {"Walk Speed Toggled", false}},
            {Name = 'WalkSpeed'                     ,Type = 'Slider',   LayoutOrder = 2,  Data = {"Walk Speed", 16, 0, 300, 1}},
            {Name = 'Space'                         ,Type = 'Spacing',  LayoutOrder = 3,  Data = {16}},
            
            -- // Jump
            {Name = 'JumpHeightToggled'             ,Type = 'Bool',     LayoutOrder = 4,  Data = {"Jump Height Toggled", false}},
            {Name = 'JumpHeight'                    ,Type = 'Slider',   LayoutOrder = 5,  Data = {"Jump Height", 7.2, 0, 500, 0.1}},
            {Name = 'InfJumpToggled'                ,Type = 'Bool',     LayoutOrder = 6,  Data = {"Infinite Jump Toggled", false}},
            {Name = 'Space'                         ,Type = 'Spacing',  LayoutOrder = 7,  Data = {16}},
            
            -- // Speed
            {Name = 'FlightToggled'                 ,Type = 'Bool',     LayoutOrder = 8,  Data = {"Fly Toggled", false}},
            {Name = 'FlightSpeed'                   ,Type = 'Slider',   LayoutOrder = 9,  Data = {"Fly Speed", 50, 0, 300, 1}},
            {Name = 'Space'                         ,Type = 'Spacing',  LayoutOrder = 10, Data = {16}},
            
            -- // Noclip and Anit-afk
            {Name = 'NoclipToggled'                 ,Type = 'Bool',     LayoutOrder = 11, Data = {"No-clip Toggled", false}},
            {Name = 'AntiAfkToggled'                ,Type = 'Bool',     LayoutOrder = 12, Data = {"Anti-Afk Toggled", false}},
            
            -- // Teleport
            {Name = 'TeleportPosition'              ,Type = 'Textbox',  LayoutOrder = 13, Data = {"Teleport Position", "0, 0, 0"}},
            {Name = 'Teleport'                      ,Type = 'Button',   LayoutOrder = 14, Data = {"Teleport to Position"}},
            {Name = 'Space'                         ,Type = 'Spacing',  LayoutOrder = 15, Data = {16}},
            
            -- more
            {Name = 'TeleportToPlayerType'          ,Type = 'Dropdown', LayoutOrder = 16, Data = {"Teleport to Player type", 1, {"Instant", "Tween", "Pulse", "Loop"}}},
            {Name = 'TeleportPlayerName'            ,Type = 'Textbox',  LayoutOrder = 17, Data = {"Teleport to Player Name", "@random"}},
            {Name = 'TeleportToPlayerTweenDuration' ,Type = 'Textbox',  LayoutOrder = 18, Data = {"Tween Duration", ""}},
            {Name = 'TeleportToPlayerPulseDuration' ,Type = 'Textbox',  LayoutOrder = 19, Data = {"Pulse Duration", ""}},
            {Name = 'TeleportToPlayerOffset'        ,Type = 'Textbox',  LayoutOrder = 20, Data = {"Player Teleport Offset", "0, 3, 0"}},
            {Name = 'TeleportToPlayerLooped'        ,Type = 'Bool',     LayoutOrder = 21, Data = {"Loop Teleport to Player", false}},
            {Name = 'TeleportToPlayer'              ,Type = 'Button',   LayoutOrder = 22, Data = {"Teleport to Player"}},
            {Name = 'Space'                         ,Type = 'Spacing',  LayoutOrder = 23, Data = {16}},
            
            --// Character
            {Name = 'Sit'                           ,Type = 'Button',   LayoutOrder = 24, Data = {"Sit"}},
            {Name = 'Trip'                          ,Type = 'Button',   LayoutOrder = 25, Data = {"Trip"}},
            {Name = 'FreezeToggled'                 ,Type = 'Bool',     LayoutOrder = 26, Data = {"Freeze Character Toggled", false}},
            {Name = "GodToggled"                    ,Type = "Bool",     LayoutOrder = 27, Data = {"God Mode", false} },
            {Name = 'Space'                         ,Type = 'Spacing',  LayoutOrder = 28, Data = {16}},
            
            --// Void
            { Name = "AntiVoidToggled"              ,Type = "Bool",     LayoutOrder = 29, Data = {"Anti-Void", false} },
            { Name = "AntiVoidThreshold"            ,Type = "Slider",   LayoutOrder = 30, Data = {"Void Threshold", 50, 0, 500, 10} },
            { Name = 'Space'                        ,Type = 'Spacing',  LayoutOrder = 31, Data = {16}},
            
            { Name = "NoFrictionToggled"            ,Type = "Bool",     LayoutOrder = 32, Data = {"Less Friction (near 0 friction)", false} },
            { Name = 'Space'                        ,Type = 'Spacing',  LayoutOrder = 33, Data = {16}},
            
            { Name = "SpectateToggled"              ,Type = "Bool",     LayoutOrder = 34, Data = {"Spectate", false}              },
            { Name = "SpectateTarget"               ,Type = "Textbox",  LayoutOrder = 35, Data = {"Spectate Target", "@closest"}  },
            { Name = "SpectateNext"                 ,Type = "Button",   LayoutOrder = 36, Data = {"Next Player"}                  },
            { Name = "SpectatePrev"                 ,Type = "Button",   LayoutOrder = 37, Data = {"Previous Player"}              },
            { Name = 'Space'                        ,Type = 'Spacing',  LayoutOrder = 38, Data = {16}},
            
            { Name = "FreecamToggled"               ,Type = "Bool",     LayoutOrder = 39, Data = {"Freecam",             false}         },
            { Name = "FreecamSpeed"                 ,Type = "Slider",   LayoutOrder = 40, Data = {"Freecam Speed",        50, 1, 300, 1} },
            { Name = "FreecamSensitivity"           ,Type = "Slider",   LayoutOrder = 41, Data = {"Freecam Sensitivity",  0.3, 0.1, 2, 0.1} },
        }
    };
    ["Combat"]   = {LayoutOrder = 3, Divider = true, Image = "rbxassetid://80768163828428",
        Values = {}
    };
    ["Visuals"]  = {LayoutOrder = 4, Divider = true, Image = "rbxassetid://108862841833418",
        Values = {}
    };
    ["World"]    = {LayoutOrder = 5, Divider = true, Image = "rbxassetid://124318997479071",
        Values = {}
    };
    ["Game"]     = {LayoutOrder = 6, Divider = true, Image = "rbxassetid://115110561340057",
        Values = {}
    };
    ["Misc"]     = {LayoutOrder = 7, Divider = true, Image = "rbxassetid://111311704779886",
        Values = {}
    };
    ["Settings"] = {LayoutOrder = 8, Divider = false,Image = "rbxassetid://128315976641061",
        Values = {}
    };
}

local COLORS = {
    ---- // Navigation Bar Colors
    backgroundColor = Color3.new(0.0980392, 0.101961, 0.121569),
    navDividerColor = Color3.new(0.192157, 0.2, 0.239216),
    navStrokeColor = Color3.new(0.192157, 0.2, 0.239216),
    
    navTextColor = Color3.new(0.356863, 0.372549, 0.443137),
    navImageColor = Color3.new(0.411765, 0.427451, 0.509804),
    
    navSelectedTextColor = Color3.new(0.831373, 0.831373, 0.831373),
    navSelectedImageColor = Color3.new(0.831373, 0.831373, 0.831373),
    
    ---- // Panel Colors
    panelStrokeColor = Color3.new(0.192157, 0.2, 0.239216),
    panelTextColor = Color3.new(0.411765, 0.431373, 0.513725),
    
    valueAccentWhite = Color3.new(0.807843, 0.807843, 0.807843),
    
    switchOnBackgroundColor = Color3.new(0.215686, 0.611765, 0),
    switchOffBackgroundColor = Color3.new(0.270588, 0.278431, 0.333333),
    
    sliderBarColor = Color3.new(0.270588, 0.278431, 0.333333),
    sliderBallColor = Color3.new(0.807843, 0.807843, 0.807843),
    
    buttonBackgroundColor = Color3.new(0.156863, 0.160784, 0.192157),
    
    textboxBackgroundColor = Color3.new(0.156863, 0.160784, 0.192157),
    textboxPlaceholderTextColor =  Color3.new(0.32549, 0.341176, 0.403922),
    
    dropboxBackgroundColor = Color3.new(0.156863, 0.160784, 0.192157),
    dropboxIconColor = Color3.new(0.411765, 0.427451, 0.509804),
    
    spacerColor = Color3.new(0.172549, 0.180392, 0.211765),
    
    ----//  Notification Colors
    notificationStrokeColor = Color3.new(0.192157, 0.2, 0.239216),
    notificationIconColor = Color3.new(0.411765, 0.427451, 0.509804),
    notificationTextColor = Color3.new(0.411765, 0.431373, 0.513725),
}

local MAX_PANEL_SIZE_Y = UDim.new(1, -54)

local AUTOEXEC_PATH = "autoexec/UniversalUI.lua"
local SOURCE = "https://raw.githubusercontent.com/ABDULGHANI1010/UNIVERSALUI/refs/heads/main/Main.lua"

---- Variables ---------------------------------------------------------------------------------------------
local values = { } --> initialized values
local valueChangedFuncs = { } --> connections to property changed

local navBar = nil
local createdNavTabs = { } --> stores menu items
local selectedNavTab = nil --> the selected menu item's index

local notificationContainer = nil
local notificationIndex = 0

local buttonFuncs = { } --> stores button funcs: [index] = func
local uniqueIdentifier = HttpService:GenerateGUID(false):gsub("-", ""):sub(1, 8)

---- Helpers -----------------------------------------------------------------------------------------------
local assignProperties = function(instance, properies)
    for k, v in pairs(properies) do
        instance[k] = v
    end
end

local new = function(instance, properties)
    local new = Instance.new(instance)
    assignProperties(new, properties)
    return new
end

local newAnimation = function(data) --> class for creating bulk animations
    local tweens = {}
    for _, tweenData in data do
        table.insert(
            tweens,
            TweenService:Create(tweenData[1], tweenData[2], tweenData[3])
        )
    end
    
    local function play()
        for _, tween in tweens do
            tween:Play()
        end
    end
    
    return {play = play}
end

local callFuncsWithParams = function(funcs, ...)
    for _, func in funcs do
        task.spawn(func, ...)
    end
end

local setValue = function(valueName, value)
    if values[valueName] == value then
        -- prevent unnecessary function calls and aware UI listeners from looping
        return
    end
    values[valueName] = value
    callFuncsWithParams(valueChangedFuncs[valueName] or {}, value)
end

local getValue = function(valueName)
    if values[valueName] == nil then
        error('Value ' .. valueName .. ' is not defined')
    end
    return values[valueName]
end

local valueChanged = function(valueName, func)
    if not valueChangedFuncs[valueName] then
        valueChangedFuncs[valueName] = { }
    end
    table.insert(valueChangedFuncs[valueName], func)
end

local setButtonFunc = function(name, func)
    if not buttonFuncs[name] then
        buttonFuncs[name] = { }
    end
    table.insert(buttonFuncs[name], func)
end

local setValueVisible = function(menuName, name, visible)
    local navTabData = createdNavTabs[menuName]
    if not navTabData then return end
    local panel = navTabData.Panel
    if not panel then return end
    local value = panel:FindFirstChild(name)
    if not value then return end
    value.Visible = visible
end

local setValueText = function(menuName, name, text)
    local navTabData = createdNavTabs[menuName]
    if not navTabData then return end
    local panel = navTabData.Panel
    if not panel then return end
    local value = panel:FindFirstChild(name)
    if not value then return end
    value.Text = text
end

---- UI Start ----------------------------------------------------------------------------------------------
local screenGui = new('ScreenGui', {
    Name = "UniversalUI"..uniqueIdentifier, 
    Parent = COREGUI, 
    IgnoreGuiInset = true, 
    ResetOnSpawn = false, 
    DisplayOrder = 99999
})

---- Menu Frame ----
local newNavBar = function()
    local navBar = new('Frame', {
        Name = "NavigationBar", 
        Parent = screenGui, 
        Size = UDim2.fromOffset(44, 44), 
        AnchorPoint = Vector2.new(0.5, 0), 
        Position = UDim2.new(0.5, 0, 0, 16), 
        BackgroundColor3 = COLORS.backgroundColor,
        AutomaticSize = Enum.AutomaticSize.X, 
    })
    new('UIListLayout', {
        FillDirection = Enum.FillDirection.Horizontal, 
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = navBar,
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })
    new('UICorner', {
        CornerRadius = UDim.new(1, 0), 
        Parent = navBar
    })
    new('UIStroke', {
        Thickness = 2,
        Color = COLORS.navStrokeColor,
        Parent = navBar
    })
    return navBar
end

local newTab = function(name, data)     --  [Tab] / [Tab] / [Tab] / [Tab] / [Tab]
    local frame = new('ImageButton', {
        Name = name,
        Size = UDim2.new(0, 90, 1, 0),
        BackgroundTransparency = 1,
        ImageTransparency = 1,
        LayoutOrder = data.LayoutOrder
    })
    new('ImageLabel', {
        Image = data.Image,
        Parent = frame,
        Size = UDim2.fromOffset(24, 24),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.fromScale(0.5, 0),
        BackgroundTransparency = 1,
        ImageColor3 = COLORS.navImageColor,
        Name = "Icon"
    })
    new('TextLabel', {
        Text = name,
        Parent = frame,
        Size = UDim2.new(1, 0, 1, 0),
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.fromScale(0.5, 1),
        BackgroundTransparency = 1,
        TextColor3 = COLORS.navTextColor,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Bottom,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        ZIndex = 2,
        Name = "Label"
    })
    new('UIPadding', {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 5),
        PaddingTop = UDim.new(0, 5),
        Parent = frame
    })
    if data.Divider then
        new('Frame', {
            Size = UDim2.new(0, 2, 0.7, 0),
            Position = UDim2.new(1, 10, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = COLORS.navDividerColor,
            Parent = frame,
            BorderSizePixel = 0,
        })
    end
    return frame
end

---- Panel Frame ----
local newInfo = function(name, data)    --  [................Text................]
    local textLabel = new('TextLabel', {
        Name = name,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, 
        Text = data[1],
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = COLORS.panelTextColor,
        BackgroundTransparency = 1,
        TextWrapped = true
    })
    new('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingTop = UDim.new(0, 5),
        Parent = textLabel
    })
    return textLabel
end

local newBool = function(name, data)    --  [.Text......................[Switch].]
    local frame = new('Frame', {
        Name = name,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
    }) 
    
    local textLabel = new('TextLabel', {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        Text = data[1],
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = COLORS.panelTextColor,
        BackgroundTransparency = 1,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = frame
    })
    
    new('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingTop = UDim.new(0, 5),
        Parent = textLabel
    })
    
    local switchContainer = new('ImageButton', {
        Size = UDim2.new(0, 44, 0.8, 0),
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = COLORS.switchOffBackgroundColor,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = frame
    })
    
    new('UICorner', {
        CornerRadius = UDim.new(1, 0),
        Parent = switchContainer
    })
    
    new('UIPadding', {
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingTop = UDim.new(0, 4),
        Parent = switchContainer
    })
    
    local switchStroke = new('UIStroke', {
        Color = COLORS.valueAccentWhite,
        Parent = switchContainer,
        BorderStrokePosition = Enum.BorderStrokePosition.Inner,
    })
    
    local switch = new('ImageLabel', {
        Parent = switchContainer,
        Size = UDim2.new(1, 0, 1, 0),
        
        BackgroundColor3 = COLORS.valueAccentWhite,
        BorderSizePixel = 0,
    })
    
    local switchOnAnim = newAnimation({
        {
            switch, 
            TweenInfo.new(0.3, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut),
            {Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.new(1, 2, 1, 2)}
        },
        {
            switchContainer,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {BackgroundColor3 = COLORS.switchOnBackgroundColor}
        },
        {
            switchStroke,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {Thickness = 0}
        }
    })
    
    local switchOffAnim = newAnimation({
        {
            switch, 
            TweenInfo.new(0.3, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut),
            {Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, 0, 1, 0)}
        },
        {
            switchContainer,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {BackgroundColor3 = COLORS.switchOffBackgroundColor}
        },
        {
            switchStroke,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {Thickness = 1.25}
        }
    })
    
    local function toggle(bool)
        if typeof(bool) ~= 'boolean' then bool = not values[name] end
        
        setValue(name, bool)
        if bool then
            switchOnAnim.play()
        else
            switchOffAnim.play()
        end
    end
    
    toggle(data[2]) --> initial toggle
    switchContainer.Activated:Connect(toggle)
    
    new('UIAspectRatioConstraint', {
        Parent = switch,
    })
    
    new('UICorner', {
        CornerRadius = UDim.new(1, 0),
        Parent = switch
    })
    
    return frame
end

local newSlider = function(name, data)  --  [.Text..............-----[Slider]----]
    local min, max, default, increment = data[3], data[4], data[2], data[5]
    local frame = new('Frame', {
        Name = name,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
    }) 
    local textLabel = new('TextLabel', {
        Size = UDim2.new(1, 0, 1, 0),
        Text = data[1],
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = COLORS.panelTextColor,
        BackgroundTransparency = 1,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = frame
    })
    new('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingTop = UDim.new(0, 5),
        Parent = textLabel
    })
    local valueLabel = new('TextLabel', {
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = COLORS.panelTextColor,
        BackgroundTransparency = 1,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = frame
    })
    new('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingTop = UDim.new(0, 5),
        Parent = valueLabel
    })
    local sliderBar = new('Frame', {
        Size = UDim2.new(0, 200, 0, 4),
        Position = UDim2.new(1, -45, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = COLORS.switchOffBackgroundColor,
        BorderSizePixel = 0,
        Parent = frame
    })
    new('UICorner', {
        CornerRadius = UDim.new(1, 0),
        Parent = sliderBar
    })
    local sliderBall = new('Frame', {
        Parent = sliderBar,
        Size = UDim2.new(0, 16, 0, 16),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = COLORS.valueAccentWhite,
        BorderSizePixel = 0,
    }) :: Frame
    new('UIStroke', {
        Color = COLORS.sliderBarColor,
        Thickness = 1.25,
        Parent = sliderBall
    })
    new('UICorner', {
        CornerRadius = UDim.new(1, 0),
        Parent = sliderBall
    })
    
    local function setSlider(value)
        local stepped = math.round(value / increment) * increment
        local clamped = math.clamp(stepped, min, max)
        
        local places = math.max(0, math.floor(-math.log10(increment)))
        local factor = 10 ^ places
        value = math.round(clamped * factor) / factor
        
        setValue(name, value)
        valueLabel.Text = tostring(value)
        
        local rel = (value - min) / (max - min)
        sliderBall.Position = UDim2.new(rel, 0, 0.5, 0)
    end
    setSlider(data[2])
    
    local dragging = false
    sliderBall.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 
            or inputObject.UserInputType == Enum.UserInputType.Touch 
        then
            dragging = true
        end
        
    end)
    
    UserInputService.InputChanged:Connect(function(inputObject)
        if dragging and 
            (inputObject.UserInputType == Enum.UserInputType.MouseMovement or
            inputObject.UserInputType == Enum.UserInputType.MouseMovement) then
            local rel = math.clamp(
                (inputObject.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1
            )
            local value = min + (max - min) * rel
            setSlider(value)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 
            or inputObject.UserInputType == Enum.UserInputType.Touch 
        then
            dragging = false
        end
    end)
    
   
    
    return frame
end

local newButton = function(name, data)  --  [...............Button...............]
    local frame = new('Frame', {
        Name = name,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
    })
    local textButton = new('TextButton', {
        Size = UDim2.new(1, 0, 1, 0), 
        Text = data[1],
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = COLORS.panelTextColor,
        BackgroundColor3 = COLORS.buttonBackgroundColor,
        TextWrapped = true,
        AutoButtonColor = false,
        Parent = frame
    })
    new('UICorner', {
        CornerRadius = UDim.new(0, 5),
        Parent = textButton
    })
    new('UIPadding', {
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 2),
        Parent = frame
    })
    
    textButton.Activated:Connect(function()
        callFuncsWithParams(buttonFuncs[name] or {})
    end)
    return frame
end

local newTextbox = function(name, data) --  [.Text.............._____[Text box]__]
    local frame = new('Frame', {
        Name = name,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
    })
    new('TextLabel', {
        Size = UDim2.new(1, 0, 1, 0),
        Text = data[1],
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = COLORS.panelTextColor,
        BackgroundTransparency = 1,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = frame
    })
    local textBox = new('TextBox', {
        Size = UDim2.new(0.5, 0, 1, 0), 
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        PlaceholderText = data[1],
        Text = data[2],
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = COLORS.panelTextColor,
        BackgroundColor3 = COLORS.textboxBackgroundColor,
        PlaceholderColor3 = COLORS.textboxPlaceholderTextColor,
        ClearTextOnFocus = false,
        TextWrapped = true,
        Parent = frame
    }) :: TextBox
    new('UICorner', {
        CornerRadius = UDim.new(0, 5),
        Parent = textBox
    })
    new('UIPadding', {
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 2),
        PaddingLeft = UDim.new(0, 5),
        Parent = frame
    })
    new('UIPadding', {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = textBox
    })
    textBox.FocusLost:Connect(function()
        setValue(name, textBox.Text)
    end)
    
    setValue(name, data[2])
    return frame
end

local newDropdown = function(name, data)--  [.Text............[Dropdown container]]v
    local frame = new('Frame', {
        Name = name,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
    }) 
    new('TextLabel', {
        Size = UDim2.new(1, 0, 1, 0),
        Text = data[1],
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = COLORS.panelTextColor,
        BackgroundTransparency = 1,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = frame
    })
    new('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 2),
        PaddingTop = UDim.new(0, 2),
        Parent = frame
    })
    local dropDownContainer = new('TextButton', {
        Size = UDim2.new(0, 180, 1, 0),
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = COLORS.dropboxBackgroundColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = frame,
        TextSize = 15,
        TextColor3 = COLORS.panelTextColor,
        Font = Enum.Font.GothamBold
    })
    new('UICorner', {
        CornerRadius = UDim.new(0, 5),
        Parent = dropDownContainer
    })
    new('UIPadding', {
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 2),
        PaddingTop = UDim.new(0, 2),
        Parent = dropDownContainer
    })
    
    local dropBoxIcon = new('ImageLabel', {
        Size = UDim2.new(0, 14, 0, 14),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Image = "rbxassetid://137146462493528",
        BackgroundTransparency = 1,
        ImageColor3 = COLORS.dropboxIconColor,
        Parent = dropDownContainer,
        Rotation = -90
    })
    new('UIAspectRatioConstraint', {
        Parent = dropBoxIcon
    })
    local dropdown = new('Frame', {
        Parent = dropDownContainer,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 1, 8),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = COLORS.dropboxBackgroundColor,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 99,
    })
    new('UIStroke', {
        Color = COLORS.backgroundColor,
        Thickness = 2,
        Parent = dropdown
    })
    new('UICorner', {
        CornerRadius = UDim.new(0, 5),
        Parent = dropdown
    })
    new('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical, 
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = dropdown,
        VerticalAlignment = Enum.VerticalAlignment.Top
    })
    
    local dropBoxOpenAnim = newAnimation({{
            dropBoxIcon,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {Rotation = 0}
       }})
    local dropBoxCloseAnim = newAnimation({{
            dropBoxIcon,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {Rotation = -90}
    }})
    
    local function addDropdownItem(name)
        local item = new('TextButton', {
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Text = name,
            Parent = dropdown,
            TextSize = 15,
            TextColor3 = COLORS.panelTextColor,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            ZIndex = 100,
        })
        
        new('UIPadding', {
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
            Parent = item
        })
        
        return item
    end
    
    local function setDropdown(index)
        local strng = data[3][index]
        dropDownContainer.Text = strng
        setValue(name, strng)
    end
    
    local isToggled = false
    local function toggleDropdownVisibility(bool)
        if not bool or typeof(bool) ~= "boolean" then
            bool = not isToggled
        end
        isToggled = bool
        if isToggled then
            dropBoxOpenAnim.play()
        else
            dropBoxCloseAnim.play()
        end
        dropdown.Visible = isToggled
    end
    
    dropDownContainer.Activated:Connect(toggleDropdownVisibility)
    
    for index, name in data[3] do
        local item = addDropdownItem(name)
        item.Activated:Connect(function()
            setDropdown(index)
            toggleDropdownVisibility(false)
        end)
    end
    
    setDropdown(data[2])
    
    return frame
end

local newSpacing = function(name, data) --  [                                     ]
    local frame = new('Frame', {
        Name = name,
        Size = UDim2.new(1, 0, 0, data[1]),
        BackgroundTransparency = 1,
    })
    new('Frame', {
        Size = UDim2.new(1, -10, 0, 2),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = COLORS.spacerColor,
        BorderSizePixel = 0,
        Parent = frame
    })
    
    return frame
end

local dataTypeConstructors = {
    Info     = newInfo,     -- string
    Bool     = newBool,     -- bool
    Slider   = newSlider,   -- number
    Button   = newButton,   -- func
    Textbox  = newTextbox,  -- string(number,vector etc)
    Spacing  = newSpacing,   -- none
    Dropdown = newDropdown, -- string(array)
}

local newPanel = function(name, data)
    local panelframe = new('ScrollingFrame', {
        Name = name, 
        Parent = screenGui, 
        Size = UDim2.fromOffset(500, 44), 
        AnchorPoint = Vector2.new(0.5, 0), 
        Position = UDim2.new(0.5, 0, 0, 84), 
        BackgroundColor3 = COLORS.backgroundColor,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0), 
        ScrollBarThickness = 0
    })
    
    new('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical, 
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = panelframe,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Name = "ListLayout"
    })
    new('UICorner', {
        CornerRadius = UDim.new(0, 11), 
        Parent = panelframe
    })
    new('UIStroke', {
        Thickness = 2,
        Color = COLORS.panelStrokeColor,
        Parent = panelframe
    })
    new('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingTop = UDim.new(0, 5),
        Parent = panelframe,
        Name = "Padding"
    })
    
    for _, value in data.Values do
        local dataTypeConstructor = dataTypeConstructors[value.Type]
        if not dataTypeConstructor then
            warn("Invalid data type: " .. value.Type)
            continue
        end
        local dataTypeFrm = dataTypeConstructor(value.Name, value.Data)
        dataTypeFrm.Parent = panelframe
        dataTypeFrm.LayoutOrder = value.LayoutOrder
    end
    
    return panelframe
end

local newNotificationContainer = function()
    local container = new('Frame', {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -10, 1, -10),
        Size = UDim2.fromOffset(250, 30),
        BackgroundTransparency = 1,
        Name = "Notifications",
        Parent = screenGui,
        ClipsDescendants = false
    })
    new('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical, 
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = container,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 10),
        Name = "ListLayout"
    })
    return container
end

local newNotification = function(data)
    local mainframe = new('Frame', {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = false
    })
    local frame = new('Frame', {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(1, 10, 0, 0),
        BackgroundColor3 = COLORS.backgroundColor,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = mainframe,
        Name = "GlideFrame"
    })
    new('ImageLabel', {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://77669691130332",
        ImageColor3 = COLORS.notificationIconColor,
        Parent = frame
    })
    new('TextLabel', {
        Size = UDim2.new(1, -28, 0, 24),
        Position = UDim2.new(0, 28, 0, 0),
        BackgroundTransparency = 1,
        Text = data[1],
        TextColor3 = COLORS.notificationTextColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Font = Enum.Font.GothamBold,
        Parent = frame,
        TextSize = 14,
        AutomaticSize = Enum.AutomaticSize.Y,
        SizeConstraint = Enum.SizeConstraint.RelativeXX,
        RichText = true
    })
    new('UICorner', {
        CornerRadius = UDim.new(0, 11), 
        Parent = frame
    })
    new('UIStroke', {
        Thickness = 2,
        Color = COLORS.notificationStrokeColor,
        Parent = frame
    })
    new('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingTop = UDim.new(0, 5),
        Parent = frame,
        Name = "Padding"
    })
    return mainframe
end

---- Construct / Select / Deselect ----
navBar = newNavBar()
notificationContainer = newNotificationContainer()

local function openMenu(menuName)
    if selectedNavTab then
        createdNavTabs[selectedNavTab].Animations.Deselect.play()
        createdNavTabs[selectedNavTab].Panel.Visible = false
        if selectedNavTab == menuName then
            selectedNavTab = nil
            return --> close menu if the same menu is selected again
        end
    end
    
    selectedNavTab = menuName
    createdNavTabs[selectedNavTab].Animations.Select.play()
    createdNavTabs[selectedNavTab].Panel.Visible = true
end

---- Construct ----
for menuName, menuData in PROPERTIES do
    local navTab = newTab(menuName, menuData)
    navTab.Parent = navBar
    
    local panel = newPanel(menuName, menuData)
    panel.Visible = false
    
    ---- Menu Animations ----
    local select = newAnimation({
        {navTab,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {Size = UDim2.new(0, 100, 1, 0)}
        },
        {navTab.Icon, 
            TweenInfo.new(.14, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), 
            {ImageColor3 = COLORS.navSelectedImageColor, Size = UDim2.fromOffset(28, 28), AnchorPoint = Vector2.new(0.5, 0.15)}
        },
        {navTab.Label, 
            TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), 
            {TextColor3 = COLORS.navSelectedTextColor}
        }
    })
    
    local deselect = newAnimation({
        {navTab,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            {Size = UDim2.new(0, 90, 1, 0)}
        },
        {navTab.Icon, 
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), 
            {ImageColor3 = COLORS.navImageColor, Size = UDim2.fromOffset(24, 24), AnchorPoint = Vector2.new(0.5, 0)}
        },
        {navTab.Label, 
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), 
            {TextColor3 = COLORS.navTextColor}
        }  
    })
    
    local function onMenuClick()
        openMenu(menuName)
    end
    navTab.Activated:Connect(onMenuClick)
    
    createdNavTabs[menuName] = {NavTab = navTab, Panel = panel, Animations = {Select = select, Deselect = deselect}}
end

---- Panel Scaling ----
local function updatePanelSize()
    local screenSize = screenGui.AbsoluteSize
    local maximumYOffset = MAX_PANEL_SIZE_Y.Scale * screenSize.Y + MAX_PANEL_SIZE_Y.Offset + MAX_PANEL_SIZE_Y.Offset
    
    for _, menu in pairs(createdNavTabs) do
        local uiListLayout = menu.Panel.ListLayout :: UIListLayout
        local padding = menu.Panel.Padding
        local YOffsetSize = uiListLayout.AbsoluteContentSize.Y + padding.PaddingTop.Offset + padding.PaddingBottom.Offset
        menu.Panel.Size = UDim2.new(0, 500, 0, math.min(YOffsetSize, maximumYOffset))
    end 
end
screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePanelSize)
screenGui.DescendantAdded:Connect(updatePanelSize)
updatePanelSize()

---- Functionality -----------------------------------------------------------------------------------------
local character : Model
local humanoid : Humanoid
local rootPart : BasePart
local camera = WorkspaceService.CurrentCamera :: Camera

local ignoringCharacterAdded = false -- prevents re-entry on CharacterAdded (god-mode guard)

---- Helper Funcs ----
local notify = function(text, duration)
    if not getValue("Notifications") then
        return
    end
    duration = duration or 3
    notificationIndex += 1
    
    local notification = newNotification({text})
    notification.LayoutOrder = notificationIndex
    notification.Parent = notificationContainer
    
    local fadeIn = newAnimation({
        {notification.GlideFrame,
            TweenInfo.new(0.25, Enum.EasingStyle.Circular, Enum.EasingDirection.Out),
            {Position = UDim2.new(0, 0, 0, 0)}
        }
    })
    
    local fadeOut = newAnimation({
        {notification.GlideFrame,
            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 10, 0, 0)}
        }
    })
    
    fadeIn.play()
    
    task.delay(duration, function()
        fadeOut.play()
        task.wait(0.3)
        notification:Destroy()
    end)
end

local function getRootFromChar(character)
    return character:FindFirstChild("HumanoidRootPart") or nil
end

local function stringToVector3(str)
    local _, result = pcall(function()
        return Vector3.new(unpack(string.split(str, ",")))
    end)
    return typeof(result) == "Vector3" and result or nil
end

local function stringToPlayers(str)
    str = str:lower()
    
    -- // Special keywords
    if str == "@me" then return {LocalPlayer} end
    if str == "@all" then return Players:GetPlayers() end
    
    -- // Closest player
    if rootPart then
        if str == "@closest" then
            local closest, closestDist = nil, math.huge
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character and getRootFromChar(player.Character)
                    if hrp then
                        local dist = (hrp.Position - rootPart.Position).Magnitude
                        if dist < closestDist then
                            closest, closestDist = player, dist
                        end
                    end
                end
            end
            return {closest}
        end
        
        -- // Farthest player
        if str == "@farthest" then
            local farthest, farthestDist = nil, -math.huge
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character and getRootFromChar(player.Character)
                    if hrp then
                        local dist = (hrp.Position - rootPart.Position).Magnitude
                        if dist > farthestDist then
                            farthest, farthestDist = player, dist
                        end
                    end
                end
            end
            return {farthest}
        end
    end
    
    if str == "@random" then
        local players = Players:GetPlayers()
        table.remove(players, table.find(players, LocalPlayer))
        if #players == 0 then return {} else return {players[math.random(1, #players)]} end
    end
    
    
    -- // Exact match
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name:lower() == str then
            return {player}
        end
    end
    
    -- // Prefix match
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name:lower():sub(1, #str) == str then
            return {player}
        end
    end
    
    return {}
end

-- // Feature Base Class
local Features = {}

local Feature = {}
Feature.__index = Feature

function Feature.new(name)
    local self = setmetatable({}, Feature)
    self.name = name
    self.connections = {}
    return self
end

function Feature:connect(signal, fn)
    local conn = signal:Connect(fn)
    table.insert(self.connections, conn)
    return conn
end

function Feature:cleanup()
    for _, conn in ipairs(self.connections) do
        pcall(conn.Disconnect, conn)
    end
    table.clear(self.connections)
    if self.onCleanup then self:onCleanup() end
end

function Feature:enable()
    if self.onEnable then self:onEnable() end
end

function Feature:disable()
    self:cleanup()
    if self.onDisable then self:onDisable() end
end

function Feature:toggle(bool)
    if bool then self:enable() else self:disable() end
end

local function registerFeature(name)
    local feature = Feature.new(name)
    Features[name] = feature
    return feature
end

local function getFeature(name)
    return Features[name]
end

-- // Walk Speed
local WalkSpeedFeature = registerFeature("WalkSpeed")
local baseWalkSpeed = 16

function WalkSpeedFeature:apply()
    if not humanoid then return end
    humanoid.WalkSpeed = getValue("WalkSpeedToggled") and getValue("WalkSpeed") or baseWalkSpeed
end

function WalkSpeedFeature:onEnable()
    self:apply()
end

function WalkSpeedFeature:onDisable()
    self:apply()
end

-- // Jump Height
local JumpHeightFeature = registerFeature("JumpHeight")
local baseJumpHeight = 7.2

function JumpHeightFeature:apply()
    if not humanoid then return end
    humanoid.UseJumpPower = false
    humanoid.JumpHeight = getValue("JumpHeightToggled") and getValue("JumpHeight") or baseJumpHeight
end

function JumpHeightFeature:onEnable()
    self:apply()
end

function JumpHeightFeature:onDisable()
    self:apply()
end

-- // Fly
local FlyFeature = registerFeature("Fly")
local bodyVelocity, bodyGyro

function FlyFeature:onEnable()
    if not rootPart or not humanoid then return end
    humanoid.PlatformStand = true
    
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Name = uniqueIdentifier
    bodyVelocity.Parent = rootPart
    
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 9e3
    bodyGyro.Name = uniqueIdentifier
    bodyGyro.Parent = rootPart
    
    self:connect(RunService.RenderStepped, function()
        local up = (UserInputService:IsKeyDown(Enum.KeyCode.E) and 1 or 0)
        - (UserInputService:IsKeyDown(Enum.KeyCode.Q) and 1 or 0)
        local move = humanoid.MoveDirection + Vector3.new(0, up, 0)
        
        local flatCam = CFrame.new(
            camera.CFrame.Position,
            camera.CFrame.Position + Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
        )
        local rel = (camera.CFrame * CFrame.new(flatCam:VectorToObjectSpace(move))).Position - camera.CFrame.Position
        
        bodyVelocity.Velocity = rel.Magnitude > 0 and rel.Unit * getValue("FlightSpeed") or Vector3.zero
        bodyGyro.CFrame = camera.CFrame
    end)
end

function FlyFeature:onDisable()
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro     then bodyGyro:Destroy()     bodyGyro = nil end
    if humanoid     then humanoid.PlatformStand = false end
end

-- // Noclip
local NoclipFeature = registerFeature("Noclip")

function NoclipFeature:onEnable()
    self:connect(RunService.Stepped, function()
        if not character then return end
        for _, p in ipairs(character:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide = false
            end
        end
    end)
end

function NoclipFeature:onDisable()
    if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Landed) end
end

-- // Infinite Jump
local InfJumpFeature = registerFeature("InfJump")

function InfJumpFeature:onEnable()
    local debounce = false
    self:connect(UserInputService.JumpRequest, function()
        if debounce or not humanoid then return end
        debounce = true
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait()
        debounce = false
    end)
end

-- // Anti AFK
local AntiAfkFeature = registerFeature("AntiAfk")

function AntiAfkFeature:onEnable()
    self:connect(LocalPlayer.Idled, function()
        Services.VirtualUser:CaptureController()
        Services.VirtualUser:ClickButton2(Vector2.new())
    end)
end

-- // Freeze
local FreezeFeature = registerFeature("Freeze")

function FreezeFeature:onEnable()
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part:SetAttribute(uniqueIdentifier, part.Anchored)
            part.Anchored = true
        end
    end
end

function FreezeFeature:onDisable()
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = part:GetAttribute(uniqueIdentifier) or false
        end
    end
end

-- // Teleport to Position
local TeleportFeature = registerFeature("Teleport")

function TeleportFeature:execute()
    if not rootPart or not character then return end
    local position = stringToVector3(getValue("TeleportPosition"))
    if position then rootPart.CFrame = CFrame.new(position) end
end

-- // Teleport to Player
local TeleportToPlayerFeature = registerFeature("TeleportToPlayer")
TeleportToPlayerFeature.tween = nil
TeleportToPlayerFeature.pulseTask = nil

function TeleportToPlayerFeature:onCleanup()
    if self.tween     then self.tween:Cancel() self.tween = nil end
    if self.pulseTask then task.cancel(self.pulseTask) self.pulseTask = nil end
end

function TeleportToPlayerFeature:getOffset()
    return stringToVector3(getValue("TeleportToPlayerOffset")) or Vector3.zero
end

function TeleportToPlayerFeature:getTargets()
    return stringToPlayers(getValue("TeleportPlayerName"))
end

function TeleportToPlayerFeature:doInstant()
    for _, player in ipairs(self:getTargets()) do
        if player == LocalPlayer then continue end
        local root = player.Character and getRootFromChar(player.Character)
        if not root then continue end
        rootPart.CFrame = root.CFrame + self:getOffset()
        break
    end
end

function TeleportToPlayerFeature:doTween()
    local dur = tonumber(getValue("TeleportToPlayerTweenDuration")) or 1
    for _, player in ipairs(self:getTargets()) do
        if player == LocalPlayer then continue end
        local root = player.Character and getRootFromChar(player.Character)
        if not root then continue end
        self.tween = TweenService:Create(
            rootPart,
            TweenInfo.new(dur, Enum.EasingStyle.Linear),
            { CFrame = root.CFrame + self:getOffset() }
        )
        self.tween:Play()
        break
    end
end

function TeleportToPlayerFeature:doPulse()
    local dur = tonumber(getValue("TeleportToPlayerPulseDuration")) or 1
    self.pulseTask = task.spawn(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local root = player.Character and getRootFromChar(player.Character)
            if not root then continue end
            if humanoid and humanoid.SeatPart then humanoid.Sit = false end
            rootPart.CFrame = root.CFrame + self:getOffset()
            task.wait(dur)
        end
    end)
end

function TeleportToPlayerFeature:doLoop()
    self:connect(RunService.Heartbeat, function()
        if not rootPart then self:cleanup() return end
        for _, player in ipairs(self:getTargets()) do
            if player == LocalPlayer then continue end
            local root = player.Character and getRootFromChar(player.Character)
            if not root then continue end
            rootPart.CFrame = root.CFrame + self:getOffset()
            break
        end
    end)
end

local TELEPORT_MODES = {
    Instant = "doInstant",
    Tween   = "doTween",
    Pulse   = "doPulse",
    Loop    = "doLoop",
}

local TELEPORT_VISIBILITY = {
    Instant = { TeleportToPlayerTweenDuration = false, TeleportToPlayerPulseDuration = false, TeleportToPlayerLooped = false, TeleportPlayerName = true,  TeleportToPlayer = true  },
    Tween   = { TeleportToPlayerTweenDuration = true,  TeleportToPlayerPulseDuration = false, TeleportToPlayerLooped = false, TeleportPlayerName = true,  TeleportToPlayer = true  },
    Pulse   = { TeleportToPlayerTweenDuration = false, TeleportToPlayerPulseDuration = true,  TeleportToPlayerLooped = false, TeleportPlayerName = false, TeleportToPlayer = true  },
    Loop    = { TeleportToPlayerTweenDuration = false, TeleportToPlayerPulseDuration = false, TeleportToPlayerLooped = true,  TeleportPlayerName = true,  TeleportToPlayer = false },
}

function TeleportToPlayerFeature:execute()
    self:cleanup()
    if not rootPart then return end
    local mode = getValue("TeleportToPlayerType")
    local method = TELEPORT_MODES[mode]
    if method then self[method](self) end
end

function TeleportToPlayerFeature:updateVisibility()
    self:cleanup()
    local vis = TELEPORT_VISIBILITY[getValue("TeleportToPlayerType")]
    if not vis then return end
    for name, visible in pairs(vis) do
        setValueVisible("Player", name, visible)
    end
    if getValue("TeleportToPlayerLooped") then
        self:doLoop()
    end
end

-- // Sit
local SitFeature = registerFeature("Sit")

function SitFeature:execute()
    if not humanoid then return end
    humanoid.Sit = not humanoid.Sit
end

-- // Trip
local TripFeature = registerFeature("Trip")

function TripFeature:execute()
    if not humanoid or not rootPart then return end
    if humanoid.PlatformStand then
        humanoid.PlatformStand = false
    else
        rootPart:ApplyAngularImpulse(Vector3.new(250, 0, 0))
        humanoid.PlatformStand = true
    end
end

-- // Rejoin / Server Hop
local ServerFeature = registerFeature("Server")

function ServerFeature:rejoin()
    TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
end

function ServerFeature:hop()
    TeleportService:Teleport(PlaceId, LocalPlayer)
end

-- // Clipboard
local ClipboardFeature = registerFeature("Clipboard")

function ClipboardFeature:copy(text)
    if everyClipboard then
        everyClipboard(tostring(text))
    end
end

-- // Auto Execute
local AutoExecFeature = registerFeature("AutoExec")

function AutoExecFeature:onEnable()
    if not makefolder or not writefile then return end
    if not isfolder("autoexec") then makefolder("autoexec") end
    writefile(AUTOEXEC_PATH, ('loadstring(game:HttpGet("%s"))()'):format(SOURCE))
end

function AutoExecFeature:onDisable()
    if isfile and isfile(AUTOEXEC_PATH) then
        writefile(AUTOEXEC_PATH, "")
    end
end

-- // God Mode Feature
local GodFeature = registerFeature("God")

function GodFeature:onEnable()
    if not character or not humanoid or not rootPart then return end
    
    local cam = WorkspaceService.CurrentCamera
    local camCFrame = cam.CFrame
    
    if replicatesignal then
        pcall(function()
            replicatesignal(LocalPlayer.ConnectDiedSignalBackend)
        end)
    end
    
    local newHumanoid = humanoid:Clone()
    newHumanoid.BreakJointsOnDeath = false
    newHumanoid:SetStateEnabled(Enum.HumanoidStateType.Dead,        false)
    newHumanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    newHumanoid:SetStateEnabled(Enum.HumanoidStateType.None,        false)
    newHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    newHumanoid.Parent = character
    
    -- // guard against reentry
    ignoringCharacterAdded = true
    LocalPlayer.Character = nil
    humanoid:Destroy()
    LocalPlayer.Character = character
    ignoringCharacterAdded = false
    
    cam.CameraSubject = newHumanoid
    task.wait()
    cam.CFrame = camCFrame
    
    local animScript = character:FindFirstChild("Animate")
    if animScript then
        animScript.Disabled = true
        task.wait()
        animScript.Disabled = false
    end
    
    newHumanoid.Health = newHumanoid.MaxHealth
    humanoid = newHumanoid
    
    self:connect(RunService.Heartbeat, function()
        if humanoid and humanoid.Health < humanoid.MaxHealth then
            humanoid.Health = humanoid.MaxHealth
        end
    end)
    
    notify("You are in god mode. This is a client sided feature and will disallow you to interact with other players properly.", 5)
end

-- // Anti Void Feature
local AntiVoidFeature = registerFeature("AntiVoid")
local savedCFrame = nil
local stableFrames = 0
local STABLE_THRESHOLD = 10
local RAYCAST_DEPTH = 50

function AntiVoidFeature:onEnable()
    self:connect(RunService.Heartbeat, function()
        if not rootPart or not humanoid then return end
        
        local isGrounded = humanoid.FloorMaterial ~= Enum.Material.Air
        
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = { character }
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local result = WorkspaceService:Raycast(
            rootPart.Position,
            Vector3.new(0, -RAYCAST_DEPTH, 0),
            rayParams
        )
        
        local hasGroundBelow = result ~= nil
        
        -- // save position only when grounded and has ground below
        if isGrounded and hasGroundBelow then
            stableFrames += 1
            if stableFrames >= STABLE_THRESHOLD then
                savedCFrame = rootPart.CFrame
            end
        else
            stableFrames = 0
        end
        
        -- // only rescue when BOTH conditions met:
        -- // 1. no ground detected below
        -- // 2. below the threshold Y
        local threshold = getValue("AntiVoidThreshold") + workspace.FallenPartsDestroyHeight
        if not hasGroundBelow and rootPart.Position.Y < threshold then
            stableFrames = 0
            if savedCFrame then
                rootPart.CFrame = savedCFrame
            else
                local spawn = WorkspaceService:FindFirstChildOfClass("SpawnLocation")
                rootPart.CFrame = spawn and spawn.CFrame + Vector3.new(0, 5, 0) or CFrame.new(0, 10, 0)
            end
        end
    end)
end

function AntiVoidFeature:onDisable()
    savedCFrame = nil
    stableFrames = 0
end

-- // No Friction Feature
local NoFrictionFeature = registerFeature("NoFriction")
local originalProperties = {}

local ZERO_FRICTION = PhysicalProperties.new(0.004, 0, 0.5, 0, 0)

local function applyTopart(part, props)
    if part and part.Parent and part:IsA("BasePart") then
        part.CustomPhysicalProperties = props
    end
end

function NoFrictionFeature:onEnable()
    if not character then return end
    
    for _, part: BasePart in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            originalProperties[part] = part.CurrentPhysicalProperties
            applyTopart(part, ZERO_FRICTION)
        end
    end
    
    self:connect(character.DescendantAdded, function(part)
        if not part:IsA("BasePart") then return end
        task.defer(function() -- // defer so part is fully initialized
            if not part.Parent then return end
            originalProperties[part] = part.CurrentPhysicalProperties
            applyTopart(part, ZERO_FRICTION)
        end)
    end)
end

function NoFrictionFeature:onDisable()
    for part, props in pairs(originalProperties) do
        pcall(applyTopart, part, props) -- // pcall in case part was destroyed
    end
    table.clear(originalProperties)
end

-- // Spectate Feature
local SpectateFeature = registerFeature("Spectate")
local spectateTarget = nil
local originalCameraType = nil
local originalCameraSubject = nil

function SpectateFeature:setTarget(player)
    if not player or player == LocalPlayer then return end
    local humanoidToSpectate = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoidToSpectate then
        return
    end
    
    spectateTarget = player
    originalCameraType    = originalCameraType    or camera.CameraType
    originalCameraSubject = originalCameraSubject or camera.CameraSubject
    
    camera.CameraType    = Enum.CameraType.Custom
    camera.CameraSubject = humanoidToSpectate
    notify("Spectating: " .. player.Name)
end

function SpectateFeature:onEnable()
    -- // set initial target from value
    local players = stringToPlayers(getValue("SpectateTarget"))
    local target = players and players[1]
    if target then self:setTarget(target) end
    
    -- // follow target if they respawn
    self:connect(Players.PlayerRemoving, function(player)
        if player == spectateTarget then
            self:nextPlayer()
        end
    end)
    
    -- // re-apply subject if character respawns
    self:connect(RunService.Heartbeat, function()
        if not spectateTarget then return end
        local char = spectateTarget.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum and camera.CameraSubject ~= hum then
            camera.CameraSubject = hum
        end
    end)
end

function SpectateFeature:onDisable()
    -- // restore camera
    if originalCameraType    then camera.CameraType    = originalCameraType    end
    if originalCameraSubject then camera.CameraSubject = originalCameraSubject end
    originalCameraType    = nil
    originalCameraSubject = nil
    spectateTarget        = nil
end

function SpectateFeature:nextPlayer()
    local players = Players:GetPlayers()
    -- // remove local player
    for i, p in ipairs(players) do
        if p == LocalPlayer then table.remove(players, i) break end
    end
    if #players == 0 then
        self:disable()
        return
    end
    
    -- // find next player after current target
    if spectateTarget then
        for i, p in ipairs(players) do
            if p == spectateTarget then
                local next = players[i + 1] or players[1]
                self:setTarget(next)
                return
            end
        end
    end
    
    -- // fallback to first player
    self:setTarget(players[1])
end

function SpectateFeature:prevPlayer()
    local players = Players:GetPlayers()
    for i, p in ipairs(players) do
        if p == LocalPlayer then table.remove(players, i) break end
    end
    if #players == 0 then return end
    
    if spectateTarget then
        for i, p in ipairs(players) do
            if p == spectateTarget then
                local prev = players[i - 1] or players[#players]
                self:setTarget(prev)
                return
            end
        end
    end
    
    self:setTarget(players[1])
end

-- // Freecam Feature
local FreecamFeature = registerFeature("Freecam")
local freecamPart = nil

local SHIFT_MULTIPLIER = 3

-- // Touch state
local touchMoveStart = nil
local touchLookStart = nil
local touchLookDelta = Vector2.zero
local activeTouches = {}

function FreecamFeature:onEnable()
    if not rootPart then return end
    
    freecamPart = Instance.new("Part")
    freecamPart.Anchored      = true
    freecamPart.CanCollide    = false
    freecamPart.Transparency  = 1
    freecamPart.Size          = Vector3.one
    freecamPart.CFrame        = camera.CFrame
    freecamPart.Parent        = WorkspaceService
    
    camera.CameraType    = Enum.CameraType.Scriptable
    camera.CameraSubject = freecamPart
    
    local camCF = camera.CFrame
    local _, y, _ = camCF:ToEulerAnglesYXZ()
    
    -- extract pitch manually (important)
    local look = camCF.LookVector
    local pitch = math.asin(look.Y)
    local yaw = y
    
    local targetYaw = yaw
    local targetPitch = pitch
    
    local rotating = false
    local lastTouchLookPos = nil
    
    -- // PC right click handling
    if not IsOnMobile then
        self:connect(UserInputService.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                rotating = true
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
            end
        end)
        
        self:connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                rotating = false
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end
        end)
    end
    
    -- // Mobile touch look (FIXED: delta instead of start position)
    if IsOnMobile then
        self:connect(UserInputService.TouchMoved, function(touch)
            local screenSize = camera.ViewportSize
            
            if touch.Position.X >= screenSize.X / 2 then
                if lastTouchLookPos then
                    touchLookDelta = touch.Position - lastTouchLookPos
                end
                lastTouchLookPos = touch.Position
            end
        end)
        
        self:connect(UserInputService.TouchEnded, function(touch)
            local screenSize = camera.ViewportSize
            if touch.Position.X >= screenSize.X / 2 then
                touchLookDelta = Vector2.zero
                lastTouchLookPos = nil
            end
        end)
    end
    
    self:connect(RunService.RenderStepped, function(dt)
        local sensitivity = getValue("FreecamSensitivity")
        local smoothness = 12 -- higher = smoother
        
        -- // ROTATION INPUT
        if IsOnMobile then
            targetYaw   -= math.rad(touchLookDelta.X * sensitivity)
            targetPitch = math.clamp(
                targetPitch - math.rad(touchLookDelta.Y * sensitivity),
                math.rad(-89), math.rad(89)
            )
            
            -- decay touch delta (smooth stop)
            touchLookDelta *= 0.85
        else
            if rotating then
                local delta = UserInputService:GetMouseDelta()
                
                targetYaw   -= math.rad(delta.X * sensitivity)
                targetPitch = math.clamp(
                    targetPitch - math.rad(delta.Y * sensitivity),
                    math.rad(-89), math.rad(89)
                )
            end
        end
        
        -- // SMOOTH ROTATION (LERP)
        yaw   += (targetYaw   - yaw)   * math.clamp(dt * smoothness, 0, 1)
        pitch += (targetPitch - pitch) * math.clamp(dt * smoothness, 0, 1)
        
        local rotation = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
        
        -- // MOVEMENT
        local moveDir = Vector3.zero
        local speed   = getValue("FreecamSpeed")
            * (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and SHIFT_MULTIPLIER or 1)
        
        if IsOnMobile then
            if touchMoveStart then
                for _, pos in pairs(activeTouches) do
                    if pos.X < camera.ViewportSize.X / 2 then
                        local delta2D = pos - touchMoveStart
                        
                        if delta2D.Magnitude > 10 then
                            local normalized = delta2D.Unit
                            moveDir += rotation.LookVector  * -normalized.Y
                            moveDir += rotation.RightVector *  normalized.X
                        end
                        break
                    end
                end
            end
        else
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += rotation.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= rotation.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= rotation.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += rotation.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveDir += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveDir -= Vector3.yAxis end
        end
        
        -- // APPLY MOVEMENT (SMOOTH)
        if moveDir.Magnitude > 0 then
            freecamPart.CFrame = freecamPart.CFrame:Lerp(
                CFrame.new(freecamPart.Position + moveDir.Unit * speed * dt) * rotation,
                0.5
            )
        else
            freecamPart.CFrame = freecamPart.CFrame:Lerp(
                CFrame.new(freecamPart.Position) * rotation,
                0.5
            )
        end
        
        camera.CFrame = freecamPart.CFrame
    end)
    
    notify("Your character still moves while freecam is on.", 5)
end

function FreecamFeature:onDisable()
    if not IsOnMobile then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
    
    -- // reset touch state
    touchMoveStart = nil
    touchLookStart = nil
    touchLookDelta = Vector2.zero
    table.clear(activeTouches)
    
    camera.CameraType    = Enum.CameraType.Custom
    camera.CameraSubject = humanoid
    
    if freecamPart then
        freecamPart:Destroy()
        freecamPart = nil
    end
end

-- // Property Change Connections (per character)
local wsConn, jhConn

local function setupPropertyConnections()
    if wsConn then wsConn:Disconnect() end
    if jhConn then jhConn:Disconnect() end
    
    wsConn = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if not getValue("WalkSpeedToggled") then
            baseWalkSpeed = math.round(humanoid.WalkSpeed)
        else
            humanoid.WalkSpeed = getValue("WalkSpeed")
        end
    end)
    
    jhConn = humanoid:GetPropertyChangedSignal("JumpHeight"):Connect(function()
        if not getValue("JumpHeightToggled") then
            baseJumpHeight = humanoid.JumpHeight
        else
            humanoid.JumpHeight = getValue("JumpHeight")
        end
    end)
end


local function characterAdded(char)
    if ignoringCharacterAdded then return end
    character = char
    humanoid  = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")
    rootPart  = getRootFromChar(char)
    
    baseWalkSpeed  = math.round(humanoid.WalkSpeed)
    baseJumpHeight = humanoid.JumpHeight
    
    setupPropertyConnections()
    
    -- // Re-apply all toggled features on respawn
    local toggleMap = {
        { feature = FlyFeature,      value = "FlightToggled"   },
        { feature = NoclipFeature,   value = "NoclipToggled"   },
        { feature = InfJumpFeature,  value = "InfJumpToggled"  },
        { feature = AntiAfkFeature,  value = "AntiAfkToggled"  },
        { feature = FreezeFeature,   value = "FreezeToggled"   },
        { feature = WalkSpeedFeature,value = "WalkSpeedToggled"},
        { feature = JumpHeightFeature,value = "JumpHeightToggled"},
        { feature = GodFeature,      value = "GodToggled"       },
        { feature = AntiVoidFeature, value = "AntiVoidToggled" },
        { feature = NoFrictionFeature,value = "NoFrictionToggled" },
        { feature = SpectateFeature, value = "SpectateToggled" },
        { feature = FreecamFeature,  value = "FreecamToggled" }
    }
    
    for _, entry in ipairs(toggleMap) do
        entry.feature:disable()
        entry.feature:toggle(getValue(entry.value))
    end
    
    TeleportToPlayerFeature:updateVisibility()
end

-- // Wire Up
local VALUE_MAP = {
    { value = "FlightToggled",          feature = FlyFeature,              method = "toggle",            getVal = "FlightToggled"    },
    { value = "NoclipToggled",          feature = NoclipFeature,           method = "toggle",            getVal = "NoclipToggled"    },
    { value = "InfJumpToggled",         feature = InfJumpFeature,          method = "toggle",            getVal = "InfJumpToggled"   },
    { value = "AntiAfkToggled",         feature = AntiAfkFeature,          method = "toggle",            getVal = "AntiAfkToggled"   },
    { value = "FreezeToggled",          feature = FreezeFeature,           method = "toggle",            getVal = "FreezeToggled"    },
    { value = "WalkSpeedToggled",       feature = WalkSpeedFeature,        method = "apply"                                          },
    { value = "WalkSpeed",              feature = WalkSpeedFeature,        method = "apply"                                          },
    { value = "JumpHeightToggled",      feature = JumpHeightFeature,       method = "apply"                                          },
    { value = "JumpHeight",             feature = JumpHeightFeature,       method = "apply"                                          },
    { value = "AutoExecute",            feature = AutoExecFeature,         method = "toggle",            getVal = "AutoExecute"      },
    { value = "TeleportToPlayerType",   feature = TeleportToPlayerFeature, method = "updateVisibility"                               },
    { value = "TeleportToPlayerLooped", feature = TeleportToPlayerFeature, method = "updateVisibility"                               },
    { value = "GodToggled",             feature = GodFeature,              method = "toggle",            getVal = "GodToggled"       },
    { value = "AntiVoidToggled",        feature = AntiVoidFeature,         method = "toggle",            getVal = "AntiVoidToggled"  },
    { value = "NoFrictionToggled",      feature = NoFrictionFeature,       method = "toggle",            getVal = "NoFrictionToggled"},
    { value = "SpectateToggled",        feature = SpectateFeature,         method = "toggle",            getVal = "SpectateToggled"  },
    { value = "SpectateTarget",         feature = SpectateFeature,         method = "onEnable"                                       },
    { value = "FreecamToggled",         feature = FreecamFeature,          method = "toggle",            getVal = "FreecamToggled" },
}

for _, entry in ipairs(VALUE_MAP) do
    valueChanged(entry.value, function(val)
        if entry.getVal then
            entry.feature[entry.method](entry.feature, getValue(entry.getVal))
        else
            entry.feature[entry.method](entry.feature, val)
        end
    end)
end

-- // Buttons
setButtonFunc("Teleport",        function() TeleportFeature:execute() end)
setButtonFunc("TeleportToPlayer",function() TeleportToPlayerFeature:execute() end)
setButtonFunc("Sit",             function() SitFeature:execute() end)
setButtonFunc("Trip",            function() TripFeature:execute() end)
setButtonFunc("ServerHop",       function() ServerFeature:hop() end)
setButtonFunc("RejoinServer",    function() ServerFeature:rejoin() end)
setButtonFunc("CopyPlaceId",     function() ClipboardFeature:copy(PlaceId) end)
setButtonFunc("CopyUserId",      function() ClipboardFeature:copy(LocalPlayer.UserId) end)
setButtonFunc("SpectateNext", function() SpectateFeature:nextPlayer() end)
setButtonFunc("SpectatePrev", function() SpectateFeature:prevPlayer() end)
-- // Init
TeleportToPlayerFeature:updateVisibility()
AntiAfkFeature:toggle(getValue("AntiAfkToggled"))
NoclipFeature:toggle(getValue("NoclipToggled"))
InfJumpFeature:toggle(getValue("InfJumpToggled"))
AutoExecFeature:toggle(getValue("AutoExecute"))

-- // Home Tab Info
setValueText("Home", "GameName",   "Game: "    .. GameName)
setValueText("Home", "PlaceId",    "Place ID: " .. PlaceId)
setValueText("Home", "PlayerName", "Username: " .. LocalPlayer.Name)
setValueText("Home", "UserId",     "User ID: "  .. LocalPlayer.UserId)

-- // Character
if LocalPlayer.Character then characterAdded(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(characterAdded)

notify("Loaded successfully")
notify("Check the Home tab for important information", 10)
