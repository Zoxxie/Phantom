-- ==============================================
--                 BYPASS
-- ==============================================
local LocalPlayer = game.Players.LocalPlayer
local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.CharacterAdded:Wait():WaitForChild("Humanoid")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)

local Connections = {
    {'CharacterController', Humanoid.GetPropertyChangedSignal(Humanoid, 'WalkSpeed')},
    {'CharacterController', Humanoid.GetPropertyChangedSignal(Humanoid, 'JumpHeight')},
    {'CharacterController', Humanoid.GetPropertyChangedSignal(Humanoid, 'HipHeight')},
    {'CharacterController', Workspace.GetPropertyChangedSignal(Workspace, 'Gravity')},
    {'CharacterController', Humanoid.StateChanged},
    {'CharacterController', Humanoid.ChildAdded},
    {'CharacterController', Humanoid.ChildRemoved},
}

for Index, Array in pairs(Connections) do
    for _, Connection in pairs(getconnections(Array[2])) do
        if type(Connection.Function) == 'function' then
            local Info = debug.getinfo(Connection.Function)

            if Info and string.find(Info.source, Array[1]) then
                print(`[Phantom.cc] disabling '{tostring(Connection.Function)}': {tostring(Array[2])}`)
                Connection:Disable()
            end
        end
    end
end

-- ==============================================
--         PHANTOM.CC UI INITIALIZATION
-- ==============================================
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'Phantom.cc | Game Framework Build',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Aimbot = Window:AddTab('Combat'),
    Visuals = Window:AddTab('Visuals'),
    Movement = Window:AddTab('Movement'),
    Misc = Window:AddTab('Misc Exploit'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local watermarkText = string.format('Phantom.cc | v1.2 | %s | %s fps', 
    LocalPlayer.Name,
    math.floor(game:GetService("Workspace"):GetRealPhysicsFPS())
)
Library:SetWatermarkVisibility(true)
Library:SetWatermark(watermarkText)
Library.KeybindFrame.Visible = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local Toggles = getgenv().Toggles or setmetatable({}, {__index = function() return {Value = false} end})
local Options = getgenv().Options or setmetatable({}, {__index = function() return {Value = 1} end})

-- ==============================================
--                   COMBAT TAB
-- ==============================================
-- Using Tabboxes to act like "Folders" that can be opened/closed for specific features mapping
local CombatLeftTabbox = Tabs.Aimbot:AddLeftTabbox()
local AimTab = CombatLeftTabbox:AddTab('Aimbot')
AimTab:AddToggle('AimLock', { Text = 'Enable Camera Aimbot', Default = false })
AimTab:AddToggle('SilentAim', { Text = 'Enable Silent Aim (RemoteHook)', Default = false })
AimTab:AddDropdown('AimPart', { Values = {'Head', 'HumanoidRootPart', 'Torso'}, Default = 1, Multi = false, Text = 'Target Part' })
AimTab:AddSlider('AimSmoothness', { Text = 'Smoothing', Default = 1, Min = 1, Max = 10, Rounding = 1 })
AimTab:AddSlider('HitChance', { Text = 'Hit Chance (%)', Default = 100, Min = 0, Max = 100, Rounding = 0 })

local GunModsTab = CombatLeftTabbox:AddTab('Gun Mods')
GunModsTab:AddToggle('NoRecoil', { Text = 'No Recoil (Network Drop)', Default = false })
GunModsTab:AddToggle('InfAmmo', { Text = 'Infinite Ammo / Fast Reload', Default = false })
GunModsTab:AddToggle('RapidFire', { Text = 'Rapid Fire', Default = false })

local FOVTabbox = Tabs.Aimbot:AddRightTabbox()
local FOVTab = FOVTabbox:AddTab('FOV System')
FOVTab:AddToggle('ShowFOV', { Text = 'Draw FOV Circle', Default = true })
FOVTab:AddSlider('FOVRadius', { Text = 'FOV Radius', Default = 100, Min = 10, Max = 1000, Rounding = 0 })
FOVTab:AddLabel('FOV Color'):AddColorPicker('FOVColor', { Default = Color3.fromRGB(130, 0, 255) })


local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = 100
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(130, 0, 255)
FOVCircle.Visible = false
FOVCircle.Thickness = 1

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = Options.FOVRadius.Value
    if Toggles.ShowFOV then FOVCircle.Visible = Toggles.ShowFOV.Value end
    if Options.FOVColor then FOVCircle.Color = Options.FOVColor.Value end
end)

local function getClosestPlayer()
    local closestDist = Options.FOVRadius.Value
    local closestPlayer = nil
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            local targetPart = v.Character:FindFirstChild(Options.AimPart.Value or "Head")
            if targetPart then
                local vector, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(vector.X, vector.Y) - UserInputService:GetMouseLocation()).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPlayer = v
                    end
                end
            end
        end
    end
    return closestPlayer
end

RunService.RenderStepped:Connect(function()
    if Toggles.AimLock and Toggles.AimLock.Value then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = getClosestPlayer()
            if target and target.Character then
                local part = target.Character:FindFirstChild(Options.AimPart.Value or "Head")
                if part then
                    local smoothness = Options.AimSmoothness.Value
                    local lookVec = CFrame.new(Camera.CFrame.Position, part.Position)
                    Camera.CFrame = Camera.CFrame:Lerp(lookVec, 1 / smoothness)
                end
            end
        end
    end
end)


-- ==============================================
--                   VISUALS
-- ==============================================
local EspTabbox = Tabs.Visuals:AddLeftTabbox()
local EspTab = EspTabbox:AddTab('Player ESP')
EspTab:AddToggle('ESPBoxes', { Text = 'Enable Boxes (2D)', Default = false })
EspTab:AddToggle('ESPNames', { Text = 'Enable Names', Default = false })
EspTab:AddToggle('ESPHealth', { Text = 'Enable Health Bar', Default = false })
EspTab:AddToggle('ESPDistance', { Text = 'Enable Distance', Default = false })
EspTab:AddToggle('ESPTracers', { Text = 'Enable Snapline Tracers', Default = false })
EspTab:AddToggle('Chams', { Text = 'Enable Highlight Chams', Default = false })

local VisualWorldTabbox = Tabs.Visuals:AddRightTabbox()
local VisualMiscTab = VisualWorldTabbox:AddTab('World / Camera')
VisualMiscTab:AddToggle('ThirdPerson', { Text = 'Third Person Camera', Default = false })
VisualMiscTab:AddSlider('ThirdPersonDistance', { Text = 'Camera Distance', Default = 10, Min = 5, Max = 50, Rounding = 1 })
VisualMiscTab:AddToggle('FOVChanger', { Text = 'Override Render FOV', Default = false })
VisualMiscTab:AddSlider('CamFOV', { Text = 'Field of View', Default = 70, Min = 30, Max = 150, Rounding = 1 })
VisualMiscTab:AddToggle('Crosshair', { Text = 'Draw Crosshair', Default = false })


local CrossX = Drawing.new("Line")
local CrossY = Drawing.new("Line")
RunService.RenderStepped:Connect(function()
    if Toggles.Crosshair and Toggles.Crosshair.Value then
        local mousePos = UserInputService:GetMouseLocation()
        CrossX.Visible = true; CrossY.Visible = true
        CrossX.Color = Options.FOVColor and Options.FOVColor.Value or Color3.fromRGB(255, 255, 255)
        CrossY.Color = CrossX.Color
        CrossX.Thickness = 2; CrossY.Thickness = 2
        CrossX.From = Vector2.new(mousePos.X - 10, mousePos.Y); CrossX.To = Vector2.new(mousePos.X + 10, mousePos.Y)
        CrossY.From = Vector2.new(mousePos.X, mousePos.Y - 10); CrossY.To = Vector2.new(mousePos.X, mousePos.Y + 10)
    else
        CrossX.Visible = false; CrossY.Visible = false
    end
end)

local EspLibrary = {}
local Highlights = {}
local function createEsp(player)
    local esp = {
        Box = Drawing.new("Square"),
        BoxOutline = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HealthBg = Drawing.new("Square"),
        HealthInfo = Drawing.new("Square"),
        Tracer = Drawing.new("Line")
    }
    esp.BoxOutline.Thickness = 3; esp.BoxOutline.Filled = false; esp.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
    esp.Box.Thickness = 1; esp.Box.Filled = false; esp.Box.Color = Color3.fromRGB(255, 255, 255)
    esp.Name.Size = 16; esp.Name.Center = true; esp.Name.Outline = true; esp.Name.Color = Color3.fromRGB(255, 255, 255)
    esp.HealthBg.Filled = true; esp.HealthBg.Color = Color3.fromRGB(0, 0, 0)
    esp.HealthInfo.Filled = true; esp.HealthInfo.Color = Color3.fromRGB(0, 255, 0)
    esp.Tracer.Thickness = 1; esp.Tracer.Color = Color3.fromRGB(255, 255, 255)
    EspLibrary[player] = esp
end

for _, v in pairs(Players:GetPlayers()) do
    if v ~= LocalPlayer then createEsp(v) end
end
Players.PlayerAdded:Connect(function(v) createEsp(v) end)
Players.PlayerRemoving:Connect(function(v) 
    if EspLibrary[v] then for _, d in pairs(EspLibrary[v]) do d:Remove() end; EspLibrary[v] = nil end 
    if Highlights[v] then Highlights[v]:Destroy() Highlights[v] = nil end
end)

RunService.RenderStepped:Connect(function()
    for player, esp in pairs(EspLibrary) do
        if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local head = player.Character:FindFirstChild("Head") or hrp
            local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local headVector = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local legVector = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
            
            if onScreen then
                local height = legVector.Y - headVector.Y
                local width = height / 1.5
                
                if Toggles.ESPBoxes and Toggles.ESPBoxes.Value then
                    esp.BoxOutline.Size = Vector2.new(width, height); esp.BoxOutline.Position = Vector2.new(vector.X - width / 2, headVector.Y); esp.BoxOutline.Visible = true
                    esp.Box.Size = Vector2.new(width, height); esp.Box.Position = Vector2.new(vector.X - width / 2, headVector.Y); esp.Box.Visible = true
                else
                    esp.Box.Visible = false; esp.BoxOutline.Visible = false
                end
                
                if Toggles.ESPNames or Toggles.ESPDistance then
                    local displayStr = ""
                    if Toggles.ESPNames and Toggles.ESPNames.Value then displayStr = player.Name end
                    if Toggles.ESPDistance and Toggles.ESPDistance.Value then 
                        local dist = math.floor((hrp.Position - Camera.CFrame.Position).Magnitude)
                        displayStr = displayStr .. " [" .. tostring(dist) .. "s]"
                    end
                    if displayStr ~= "" then
                        esp.Name.Text = displayStr; esp.Name.Position = Vector2.new(vector.X, headVector.Y - 20); esp.Name.Visible = true
                    else
                        esp.Name.Visible = false
                    end
                else
                    esp.Name.Visible = false
                end
                
                if Toggles.ESPHealth and Toggles.ESPHealth.Value then
                    local healthPct = player.Character.Humanoid.Health / player.Character.Humanoid.MaxHealth
                    esp.HealthBg.Size = Vector2.new(4, height + 2); esp.HealthBg.Position = Vector2.new(vector.X - (width / 2) - 6, headVector.Y - 1); esp.HealthBg.Visible = true
                    esp.HealthInfo.Size = Vector2.new(2, height * healthPct); esp.HealthInfo.Position = Vector2.new(vector.X - (width / 2) - 5, headVector.Y + (height * (1 - healthPct)))
                    esp.HealthInfo.Color = Color3.fromRGB(255 - (255 * healthPct), 255 * healthPct, 0); esp.HealthInfo.Visible = true
                else
                    esp.HealthBg.Visible = false; esp.HealthInfo.Visible = false
                end
                
                if Toggles.ESPTracers and Toggles.ESPTracers.Value then
                    esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y); esp.Tracer.To = Vector2.new(vector.X, legVector.Y); esp.Tracer.Visible = true
                else
                    esp.Tracer.Visible = false
                end
                
                if Toggles.Chams and Toggles.Chams.Value then
                    if not Highlights[player] then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = Options.FOVColor and Options.FOVColor.Value or Color3.fromRGB(130, 0, 255)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = player.Character
                        Highlights[player] = hl
                    elseif Highlights[player].Parent ~= player.Character then
                        Highlights[player].Parent = player.Character
                    end
                    if Highlights[player] then
                        Highlights[player].FillColor = Options.FOVColor and Options.FOVColor.Value or Color3.fromRGB(130, 0, 255)
                    end
                else
                    if Highlights[player] then Highlights[player]:Destroy(); Highlights[player] = nil end
                end
            else
                for _, obj in pairs(esp) do obj.Visible = false end
            end
        else
            for _, obj in pairs(esp) do obj.Visible = false end
            if Highlights[player] then Highlights[player]:Destroy() Highlights[player] = nil end
        end
    end
    
    if Toggles.FOVChanger and Toggles.FOVChanger.Value and Options.CamFOV then
        Camera.FieldOfView = Options.CamFOV.Value
    end
    
    if Toggles.ThirdPerson and Toggles.ThirdPerson.Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and Options.ThirdPersonDistance then
        LocalPlayer.CameraMaxZoomDistance = Options.ThirdPersonDistance.Value
        LocalPlayer.CameraMinZoomDistance = Options.ThirdPersonDistance.Value
    else
        LocalPlayer.CameraMaxZoomDistance = 120
        LocalPlayer.CameraMinZoomDistance = 0.5
    end
end)

-- ==============================================
--                   MOVEMENT
-- ==============================================
local MoveTabbox = Tabs.Movement:AddLeftTabbox()
local MoveTab = MoveTabbox:AddTab('Locomotion')
MoveTab:AddToggle('WalkSpeedHack', { Text = 'Enable Speed Boost', Default = false })
MoveTab:AddSlider('WalkSpeedValue', { Text = 'Walk Speed Multiplier', Default = 16, Min = 16, Max = 150, Rounding = 0 })

MoveTab:AddToggle('JumpPowerHack', { Text = 'Enable High Jump', Default = false })
MoveTab:AddSlider('JumpPowerValue', { Text = 'Jump Power / Height', Default = 50, Min = 50, Max = 300, Rounding = 0 })
MoveTab:AddToggle('Noclip', { Text = 'Noclip (Walk through walls)', Default = false }):AddKeyPicker('NoclipKey', { Default = 'V', SyncToggleState = true, Mode = 'Toggle', Text = 'Noclip' })

local FlyTabbox = Tabs.Movement:AddRightTabbox()
local FlyTab = FlyTabbox:AddTab('Flight System')
FlyTab:AddToggle('FlyHack', { Text = 'Enable Fly Hack', Default = false }):AddKeyPicker('FlyKey', { Default = 'F', SyncToggleState = true, Mode = 'Toggle', Text = 'Fly Hacks' })
FlyTab:AddSlider('FlySpeed', { Text = 'Flight Speed', Default = 50, Min = 10, Max = 300, Rounding = 0 })

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        if Toggles.Noclip and Toggles.Noclip.Value then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end
        if Toggles.WalkSpeedHack and Toggles.WalkSpeedHack.Value and Options.WalkSpeedValue then
            char.Humanoid.WalkSpeed = Options.WalkSpeedValue.Value
        end
        if Toggles.JumpPowerHack and Toggles.JumpPowerHack.Value and Options.JumpPowerValue then
            char.Humanoid.JumpPower = Options.JumpPowerValue.Value
            if char.Humanoid.UseJumpPower == false then
                char.Humanoid.JumpHeight = Options.JumpPowerValue.Value / 2
            end
        end
    end
end)

local FlyBodyMover = nil
local FlyGyro = nil
RunService.RenderStepped:Connect(function()
    if Toggles.FlyHack and Toggles.FlyHack.Value then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            if not FlyBodyMover then
                FlyBodyMover = Instance.new("BodyVelocity")
                FlyBodyMover.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                FlyBodyMover.Parent = hrp
                FlyGyro = Instance.new("BodyGyro")
                FlyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                FlyGyro.P = 9e4
                FlyGyro.Parent = hrp
                Workspace.Gravity = 0
            end
            
            local direction = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction = direction - Vector3.new(0, 1, 0) end
            
            FlyBodyMover.Velocity = direction * (Options.FlySpeed and Options.FlySpeed.Value or 50)
            FlyGyro.CFrame = Camera.CFrame
        end
    else
        if FlyBodyMover then FlyBodyMover:Destroy() FlyBodyMover = nil end
        if FlyGyro then FlyGyro:Destroy() FlyGyro = nil end
        Workspace.Gravity = 196.2
    end
end)

-- ==============================================
--                   MISC
-- ==============================================
local ExploitTabbox = Tabs.Misc:AddLeftTabbox()
local ExtraTab = ExploitTabbox:AddTab('Server Tools')
ExtraTab:AddToggle('AntiAim', { Text = 'Anti-Aim (Spinbot)', Default = false })
ExtraTab:AddSlider('SpinSpeed', { Text = 'Spin Speed', Default = 50, Min = 10, Max = 100, Rounding = 0 })

local ItemTabbox = Tabs.Misc:AddRightTabbox()
local ItemTab = ItemTabbox:AddTab('Loot & Items')
ItemTab:AddButton('Auto Pick Up Nearby Items', function() 
    if Remotes and Remotes:FindFirstChild("Take") then
        -- Simulating generic taking of item
        print("[Phantom.cc] Attempting to auto-pickup...")
    end
end)


RunService.RenderStepped:Connect(function()
    if Toggles.AntiAim and Toggles.AntiAim.Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Options.SpinSpeed.Value or 50), 0)
    end
end)

-- Core Metatable Hook for Game Specific Events found in ReplicatedStorage.Remotes
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if not checkcaller() then
        -- Hooking into the actual FireProjectile and ProjectileInflict remotes based on the game files
        if method == "FireServer" and tostring(self) == "FireProjectile" or tostring(self) == "ProjectileInflict" or tostring(self) == "ServerProjectile" then
            if Toggles.SilentAim and Toggles.SilentAim.Value then
                local target = getClosestPlayer()
                if target and target.Character then
                    local part = target.Character:FindFirstChild(Options.AimPart.Value or "Head")
                    if part then
                        if math.random(1, 100) <= Options.HitChance.Value then
                            -- Manipulate standard raycast arguments frequently used by ReplicatedStorage Projectile events
                            if type(args[1]) == "Vector3" then
                                args[1] = part.Position -- Set target hit position directly to player part if remote uses vector positional args
                            end
                            if type(args[2]) == "Vector3" then
                                args[2] = part.Position
                            end
                        end
                    end
                end
            end
        end
        if method == "FireServer" and tostring(self) == "UpdateTilt" and Toggles.NoRecoil and Toggles.NoRecoil.Value then
             -- Blocking viewmodel tilt / recoil updates dynamically
             return nil 
        end
    end
    
    return oldNamecall(self, unpack(args))
end)

-- ==============================================
--                 UI SETTINGS
-- ==============================================
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload Menu', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'RightShift', NoUI = true, Text = 'Menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind 

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('Phantom.cc')
SaveManager:SetFolder('Phantom.cc/configs')

local PhantomThemeColors = {
    FontColor = "ffffff",
    MainColor = "141414",
    AccentColor = "8200ff", -- Phantom Purple
    BackgroundColor = "0f0f0f",
    OutlineColor = "232323"
}

if ThemeManager.BuiltInThemes then
    ThemeManager.BuiltInThemes.Default = { 1, PhantomThemeColors }
end

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

Library.AccentColor = Color3.fromRGB(130, 0, 255)
Library.BackgroundColor = Color3.fromRGB(15, 15, 15)
Library.MainColor = Color3.fromRGB(20, 20, 20)
Library.OutlineColor = Color3.fromRGB(35, 35, 35)
Library.FontColor = Color3.fromRGB(255, 255, 255)
Library:UpdateColorsUsingRegistry()

SaveManager:LoadAutoloadConfig()
