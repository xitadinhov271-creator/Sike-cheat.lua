-- ==========================================================
-- V48 SIKE — PAINEL COM SISTEMA DE TRAVAR/MOVER (Anti-Bug FOV)
-- ==========================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Camera           = Workspace.CurrentCamera
local LP               = Players.LocalPlayer
local Mouse            = LP:GetMouse()

-- ===================== ESTADO =====================
local S = {
    Aimbot          = false,
    AimbotAuto      = false,
    AimbotBotaoDir  = true,
    AimbotFOV       = 250,
    AimbotSmooth    = 0.15,
    AimbotPart      = "Head",
    MostrarFOV      = false,
    AimbotVisivel   = true,
    AimbotTeamCheck = false,

    ESP             = false,
    ESPBox          = false,
    ESPName         = false,
    ESPLine         = false,
    ESPHealth       = false,
    ESPTeamCheck    = false,
    ESPColor        = Color3.fromRGB(255, 60, 60),
}

local ESPCache = {}
local painelArrastavel = false -- Estado do painel

-- ===================== FUNÇÃO DE TIME =====================
local function obterTime(player)
    if not player then return nil end
    if player.Team and player.Team.Name then return player.Team.Name end
    local att = player:GetAttribute("Team") or player:GetAttribute("Time")
    if att then return tostring(att) end
    return nil
end

local function mesmoTime(p1, p2)
    local t1 = obterTime(p1)
    local t2 = obterTime(p2)
    if not t1 or not t2 then return false end
    return string.lower(tostring(t1)) == string.lower(tostring(t2))
end

-- ===================== UI BASE =====================
local gui = Instance.new("ScreenGui")
gui.Name = "SystemUpdate"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local espContainer = Instance.new("Frame")
espContainer.Name = "ESPContainer"
espContainer.Size = UDim2.new(1, 0, 1, 0)
espContainer.BackgroundTransparency = 1
espContainer.ZIndex = 1
espContainer.Parent = gui

local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.ZIndex = 2
fovCircle.Visible = false
fovCircle.Parent = gui
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Thickness = 1.5
fovStroke.Color = Color3.fromRGB(255, 60, 60)
fovStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local menuBtn = Instance.new("TextButton")
menuBtn.Size = UDim2.new(0, 90, 0, 40)
menuBtn.Position = UDim2.new(0, 20, 0, 100)
menuBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
menuBtn.Text = "MENU"
menuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
menuBtn.Font = Enum.Font.GothamBold
menuBtn.TextSize = 15
menuBtn.Active = true
menuBtn.Draggable = true
menuBtn.ZIndex = 20
menuBtn.Parent = gui
Instance.new("UICorner", menuBtn).CornerRadius = UDim.new(0, 8)

-- ⚡ PAINEL PRINCIPAL (Começa travado)
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 540, 0, 440)
main.Position = UDim2.new(0.5, -270, 0.5, -220)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = false -- Começa falso para não bugar o FOV
main.ZIndex = 10
main.Visible = false
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

-- HEADER (Barra de cima)
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
header.ZIndex = 11
header.Parent = main
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -130, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "SYSTEM CONFIG"
title.TextColor3 = Color3.fromRGB(255, 80, 80)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 12
title.Parent = header

-- ⚡ BOTÃO DE MOVER (SETINHA)
local btnMover = Instance.new("TextButton")
btnMover.Size = UDim2.new(0, 28, 0, 28)
btnMover.Position = UDim2.new(1, -72, 0, 7)
btnMover.BackgroundColor3 = Color3.fromRGB(200, 60, 60) -- Vermelho = Travado
btnMover.Text = "↔"
btnMover.TextColor3 = Color3.fromRGB(255, 255, 255)
btnMover.Font = Enum.Font.GothamBold
btnMover.TextSize = 18
btnMover.ZIndex = 12
btnMover.Parent = header
Instance.new("UICorner", btnMover).CornerRadius = UDim.new(0, 6)

btnMover.MouseButton1Click:Connect(function()
    painelArrastavel = not painelArrastavel
    main.Draggable = painelArrastavel
    
    if painelArrastavel then
        btnMover.BackgroundColor3 = Color3.fromRGB(60, 200, 100) -- Verde = Pode mover
        btnMover.Text = "✥"
    else
        btnMover.BackgroundColor3 = Color3.fromRGB(200, 60, 60) -- Vermelho = Travado
        btnMover.Text = "↔"
    end
end)

-- Botão Fechar
local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 28, 0, 28)
close.Position = UDim2.new(1, -36, 0, 7)
close.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
close.Text = "✕"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.ZIndex = 12
close.Parent = header
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
close.MouseButton1Click:Connect(function() main.Visible = false end)

-- SIDEBAR, PÁGINAS E ELEMENTOS (Resto igual)
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 130, 1, -52)
sidebar.Position = UDim2.new(0, 10, 0, 47)
sidebar.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 11
sidebar.Parent = main
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 8)
local sideList = Instance.new("UIListLayout", sidebar)
sideList.Padding = UDim.new(0, 4)
local sidePad = Instance.new("UIPadding", sidebar)
sidePad.PaddingTop = UDim.new(0, 8)
sidePad.PaddingLeft = UDim.new(0, 6)
sidePad.PaddingRight = UDim.new(0, 6)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -160, 1, -52)
content.Position = UDim2.new(0, 150, 0, 47)
content.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
content.BorderSizePixel = 0
content.ZIndex = 11
content.Parent = main
Instance.new("UICorner", content).CornerRadius = UDim.new(0, 8)

local paginas = {}
local function criarPagina(nome)
    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(1, -20, 1, -20)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 4
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    frame.Visible = false
    frame.ZIndex = 12
    frame.Parent = content
    local l = Instance.new("UIListLayout", frame)
    l.Padding = UDim.new(0, 6)
    paginas[nome] = frame
    return frame
end

local pagAimbot  = criarPagina("Aimbot")
local pagESP     = criarPagina("ESP")

local abasBotoes = {}
local function criarAba(nome, pagina)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
    btn.Text = nome
    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    abasBotoes[nome] = btn
    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(paginas) do p.Visible = false end
        for _, b in pairs(abasBotoes) do
            b.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
            b.TextColor3 = Color3.fromRGB(220, 220, 230)
        end
        pagina.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(140, 60, 60)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end
criarAba("🎯 Aimbot",   pagAimbot)
criarAba("👁 ESP",      pagESP)

local function toggle(pagina, nome, key, callback, padrao)
    if padrao ~= nil then S[key] = padrao end
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 32)
    btn.BackgroundColor3 = S[key] and Color3.fromRGB(60, 130, 80) or Color3.fromRGB(38, 38, 52)
    btn.Text = "  " .. nome .. "  [" .. (S[key] and "ON" or "OFF") .. "]"
    btn.TextColor3 = Color3.fromRGB(230, 230, 230)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = pagina
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        S[key] = not S[key]
        btn.Text = "  " .. nome .. "  [" .. (S[key] and "ON" or "OFF") .. "]"
        btn.BackgroundColor3 = S[key] and Color3.fromRGB(60, 130, 80) or Color3.fromRGB(38, 38, 52)
        if callback then callback(S[key]) end
    end)
end

local function slider(pagina, nome, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 46)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    frame.Parent = pagina
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = nome .. ": " .. default
    lbl.TextColor3 = Color3.fromRGB(210, 210, 230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.new(0, 10, 0, 30)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    bar.Parent = frame
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local dragging = false
    local function update(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = nome .. ": " .. val
        callback(val)
    end
    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i.Position.X) end end)
end

local function dropdown(pagina, nome, opcoes, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    frame.Parent = pagina
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = nome
    lbl.TextColor3 = Color3.fromRGB(210, 210, 230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    local atual = 1
    for i, v in ipairs(opcoes) do if v == default then atual = i end end
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 26)
    btn.Position = UDim2.new(0, 10, 0, 26)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    btn.Text = opcoes[atual]
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(function()
        atual = atual % #opcoes + 1
        btn.Text = opcoes[atual]
        callback(opcoes[atual])
    end)
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then main.Visible = not main.Visible end
end)

menuBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

-- ==========================================================
-- 1. AIMBOT
-- ==========================================================
local function estaVisivel(parteAlvo)
    local char = LP.Character
    local minhaHead = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
    if not minhaHead or not parteAlvo then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclusoes = { char }
    for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(exclusoes, p.Character) end end
    params.FilterDescendantsInstances = exclusoes
    return Workspace:Raycast(minhaHead.Position, parteAlvo.Position - minhaHead.Position, params) == nil
end

local function acharParteAlvo(char, nomeParte)
    if not char then return nil end
    local parte = char:FindFirstChild(nomeParte)
    if parte and parte:IsA("BasePart") then return parte end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.RootPart then return hum.RootPart end
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function getClosest()
    local centroX, centroY = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
    local raio = S.AimbotFOV / 2
    local closest, dist = nil, raio
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character.Parent then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local part = acharParteAlvo(p.Character, S.AimbotPart)
                if part then
                    local podePegar = true
                    if S.AimbotTeamCheck and mesmoTime(LP, p) then podePegar = false end
                    if podePegar and S.AimbotVisivel then podePegar = estaVisivel(part) end
                    if podePegar then
                        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(centroX, centroY)).Magnitude
                            if d < dist then dist = d; closest = part end
                        end
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not S.Aimbot then return end
    local alvo = getClosest()
    
    local vp = Camera.ViewportSize
    fovCircle.Position = UDim2.new(0, vp.X / 2, 0, vp.Y / 2)
    fovCircle.Size = UDim2.new(0, S.AimbotFOV, 0, S.AimbotFOV)
    fovCircle.Visible = S.MostrarFOV
    if S.MostrarFOV then
        fovStroke.Color = alvo and Color3.fromRGB(60, 255, 100) or Color3.fromRGB(255, 60, 60)
    end

    if alvo then
        local deveTravar = S.AimbotAuto or (S.AimbotBotaoDir and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
        if deveTravar then
            local pos = Camera.CFrame.Position
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(pos, alvo.Position), S.AimbotSmooth)
        end
    end
end)

-- ==========================================================
-- 2. ESP
-- ==========================================================
local function criarObjetos(char)
    if ESPCache[char] then return end
    local objetos = { char = char }

    local bordas = {}
    for i = 1, 4 do
        local b = Instance.new("Frame")
        b.BackgroundColor3 = S.ESPColor
        b.BorderSizePixel = 0
        b.ZIndex = 2
        b.Visible = false
        b.Parent = espContainer
        bordas[i] = b
    end
    objetos.bordas = bordas

    local nome = Instance.new("TextLabel")
    nome.BackgroundTransparency = 1
    nome.Text = char.Name
    nome.TextColor3 = S.ESPColor
    nome.TextStrokeTransparency = 0
    nome.Font = Enum.Font.GothamBold
    nome.TextSize = 14
    nome.ZIndex = 3
    nome.Visible = false
    nome.Parent = espContainer
    objetos.nome = nome

    local healthBG = Instance.new("Frame")
    healthBG.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    healthBG.BorderSizePixel = 0
    healthBG.ZIndex = 2
    healthBG.Visible = false
    healthBG.Parent = espContainer
    Instance.new("UICorner", healthBG).CornerRadius = UDim.new(0, 2)

    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.fromRGB(60, 220, 90)
    healthFill.BorderSizePixel = 0
    healthFill.ZIndex = 3
    healthFill.Parent = healthBG
    Instance.new("UICorner", healthFill).CornerRadius = UDim.new(0, 2)

    objetos.healthBG = healthBG
    objetos.healthFill = healthFill

    local line = Instance.new("Frame")
    line.BackgroundColor3 = S.ESPColor
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.ZIndex = 2
    line.Visible = false
    line.Parent = espContainer
    objetos.line = line

    ESPCache[char] = objetos
end

local function deletarObjetos(char)
    local obj = ESPCache[char]
    if not obj then return end
    if obj.bordas then for _, b in ipairs(obj.bordas) do if b.Parent then b:Destroy() end end end
    if obj.nome and obj.nome.Parent then obj.nome:Destroy() end
    if obj.healthBG and obj.healthBG.Parent then obj.healthBG:Destroy() end
    if obj.line and obj.line.Parent then obj.line:Destroy() end
    ESPCache[char] = nil
end

task.spawn(function()
    local vp = Camera.ViewportSize
    while true do
        RunService.RenderStepped:Wait()

        if not S.ESP then
            for _, obj in pairs(ESPCache) do
                for _, b in ipairs(obj.bordas) do b.Visible = false end
                obj.nome.Visible = false
                obj.healthBG.Visible = false
                obj.line.Visible = false
            end
        else
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP then
                    if p.Character and p.Character.Parent then
                        criarObjetos(p.Character)
                    end
                    for char, obj in pairs(ESPCache) do
                        if char.Name == p.Name and char ~= p.Character then 
                            deletarObjetos(char) 
                        end
                    end
                end
            end

            for char, obj in pairs(ESPCache) do
                if not char.Parent then
                    deletarObjetos(char)
                else
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local head = char:FindFirstChild("Head")
                    
                    if hrp and head then
                        local p2 = Players:GetPlayerFromCharacter(char)
                        local ehMesmoTime = (S.ESPTeamCheck and p2 and mesmoTime(LP, p2))

                        if not ehMesmoTime then
                            local headScreen, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
                            local feetScreen, feetOn = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                            
                            local dist = (Camera.CFrame.Position - head.Position).Magnitude
                            local onScreen = headOn and feetOn and dist < 1500

                            if onScreen then
                                local altura = math.abs(feetScreen.Y - headScreen.Y)
                                local largura = altura * 0.55
                                local cx = (headScreen.X + feetScreen.X) / 2
                                local cyTop = headScreen.Y
                                local cyBot = feetScreen.Y

                                if S.ESPBox then
                                    local esp = 1.5
                                    local b = obj.bordas
                                    b[1].Size = UDim2.new(0, largura, 0, esp); b[1].Position = UDim2.new(0, cx - largura/2, 0, cyTop)
                                    b[2].Size = UDim2.new(0, largura, 0, esp); b[2].Position = UDim2.new(0, cx - largura/2, 0, cyBot)
                                    b[3].Size = UDim2.new(0, esp, 0, altura);  b[3].Position = UDim2.new(0, cx - largura/2, 0, cyTop)
                                    b[4].Size = UDim2.new(0, esp, 0, altura);  b[4].Position = UDim2.new(0, cx + largura/2, 0, cyTop)
                                    for i = 1, 4 do b[i].Visible = true end
                                else
                                    for i = 1, 4 do obj.bordas[i].Visible = false end
                                end

                                if S.ESPName then
                                    local posNome = Camera:WorldToViewportPoint((head.CFrame * CFrame.new(0, 2.5, 0)).Position)
                                    obj.nome.Position = UDim2.new(0, cx - 100, 0, cyTop - 25)
                                    obj.nome.Visible = true
                                else obj.nome.Visible = false end
                                
                                if S.ESPHealth then
                                    local hum = char:FindFirstChildOfClass("Humanoid")
                                    if hum then
                                        local hp = hum.Health / hum.MaxHealth
                                        obj.healthBG.Size = UDim2.new(0, largura, 0, 4)
                                        obj.healthBG.Position = UDim2.new(0, cx - largura/2, 0, cyBot + 3)
                                        obj.healthBG.Visible = true
                                        obj.healthFill.Size = UDim2.new(hp, 0, 1, 0)
                                    end
                                else obj.healthBG.Visible = false end

                                if S.ESPLine then
                                    local origem = Vector2.new(vp.X / 2, vp.Y)
                                    local destino = Vector2.new(cx, cyBot)
                                    local diff = destino - origem
                                    local comprimento = diff.Magnitude
                                    local angulo = math.deg(math.atan2(diff.Y, diff.X))
                                    obj.line.Size = UDim2.new(0, comprimento, 0, 1.5)
                                    obj.line.Position = UDim2.new(0, (origem.X + destino.X) / 2, 0, (origem.Y + destino.Y) / 2)
                                    obj.line.Rotation = angulo
                                    obj.line.Visible = true
                                else obj.line.Visible = false end
                            else
                                for i = 1, 4 do obj.bordas[i].Visible = false end
                                obj.nome.Visible = false
                                obj.healthBG.Visible = false
                                obj.line.Visible = false
                            end
                        else
                            for i = 1, 4 do obj.bordas[i].Visible = false end
                            obj.nome.Visible = false
                            obj.healthBG.Visible = false
                            obj.line.Visible = false
                        end
                    end
                end
            end
        end
    end
end)

-- ===================== CONFIGURAÇÃO DA UI =====================
toggle(pagAimbot, "Ativar Aimbot", "Aimbot", nil, false)
toggle(pagAimbot, "Aimbot Automático", "AimbotAuto", nil, false)
toggle(pagAimbot, "Aimbot Botão Direito", "AimbotBotaoDir", nil, true)
toggle(pagAimbot, "Wall Check", "AimbotVisivel", nil, true)
toggle(pagAimbot, "Team Check (Aimbot)", "AimbotTeamCheck", nil, false)
toggle(pagAimbot, "Mostrar FOV", "MostrarFOV", nil, false)
slider(pagAimbot, "Tamanho FOV", 50, 800, 250, function(v) S.AimbotFOV = v end)
slider(pagAimbot, "Suavidade", 1, 10, 6, function(v) S.AimbotSmooth = 1 / v end)
dropdown(pagAimbot, "Parte do alvo", {"Head", "HumanoidRootPart", "Torso"}, "Head", function(v) S.AimbotPart = v end)

toggle(pagESP, "Ativar ESP", "ESP", nil, false)
toggle(pagESP, "Mostrar Box", "ESPBox", nil, false)
toggle(pagESP, "Mostrar Nome", "ESPName", nil, false)
toggle(pagESP, "Mostrar Vida", "ESPHealth", nil, false)
toggle(pagESP, "Mostrar Line", "ESPLine", nil, false)
toggle(pagESP, "Team Check (ESP)", "ESPTeamCheck", nil, false)

pagAimbot.Visible = true
abasBotoes["🎯 Aimbot"].BackgroundColor3 = Color3.fromRGB(140, 60, 60)
abasBotoes["🎯 Aimbot"].TextColor3 = Color3.fromRGB(255, 255, 255)

print("[V48] Painel com sistema Anti-Bug de arrastar.")
