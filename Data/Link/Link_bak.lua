-- a link game for something


function log_info(str) print(str.."") end
function log_debug(str)  print(str.."") end
function log_warn(str)  print(str.."") end
function log_error(str) print(str.."") end

function __G__TRACKBACK__(msg)
    log_error("-----------------------------------------------------");
    log_error(msg)
    log_error(debug.traceback())
    log_error("-----------------------------------------------------");
end


local logoSprite = nil
screenJoystickIndex = M_MAX_UNSIGNED -- Screen joystick index for navigational controls (mobile platforms only)
screenJoystickSettingsIndex = M_MAX_UNSIGNED -- Screen joystick index for settings (mobile platforms only)
touchEnabled = false -- Flag to indicate whether touch input has been enabled

function Start()
    print("start---");
	if GetPlatform() == "Android" or GetPlatform() == "iOS" or input.touchEmulation then
        InitTouchInput();
    elseif input:GetNumJoysticks() == 0 then
        -- On desktop platform, do not detect touch when we already got a joystick
        SubscribeToEvent("TouchBegin", "HandleTouchBegin")
    end

    --============================
    local desktopResolution = graphics.desktopResolution;
    local icon = cache:GetResource("Image", "Textures/UrhoIcon.png")
    graphics:SetWindowIcon(icon)
    graphics.windowTitle = "Urho3D Sample"
    local x = (desktopResolution.x - 800) / 2;
    local y = (desktopResolution.y - 600) / 2;
    graphics:SetMode(800, 600)
    graphics:SetWindowPosition(x, y);
    --============================
    local uiStyle = cache:GetResource("XMLFile", "UI/DefaultStyle.xml")
    if uiStyle == nil then
        return
    end

    engine:CreateConsole()
    console.defaultStyle = uiStyle
    console.background.opacity = 0.8
    engine:CreateDebugHud()
    debugHud.defaultStyle = uiStyle
    --============================
    local logoTexture = cache:GetResource("Texture2D", "Textures/LogoLarge.png")
    if logoTexture == nil then
        return
    end

    logoSprite = ui.root:CreateChild("Sprite")
    logoSprite:SetTexture(logoTexture)
    local textureWidth = logoTexture.width
    local textureHeight = logoTexture.height
    logoSprite:SetScale(256 / textureWidth)
    logoSprite:SetSize(textureWidth, textureHeight)
    logoSprite.hotSpot = IntVector2(0, textureHeight)
    logoSprite:SetAlignment(HA_LEFT, VA_BOTTOM);
    logoSprite.opacity = 0.75
    logoSprite.priority = -100
    --============================

	SubscribeToEvent("KeyDown", "HandleKeyDown")
	SubscribeToEvent("SceneUpdate", "HandleSceneUpdate")

	input.mouseVisible = true
	local style = cache:GetResource("XMLFile", "UI/DefaultStyle.xml")
	ui.root.defaultStyle = style

    CreateWindow();

	cache.autoReloadResources = true;
	cache.returnFailedResources = true;
	input.mouseVisible = true;
	ui.useSystemClipboard = true;
end

function Stop()
end


function CreateWindow()

    window = Window:new()
    ui.root:AddChild(window)

    window:SetMinSize(384, 192)
    window:SetLayout(LM_VERTICAL, 6, IntRect(6, 6, 6, 6))
    window:SetAlignment(HA_CENTER, VA_CENTER)
    window:SetName("Window")

    local titleBar = UIElement:new()
    titleBar:SetMinSize(0, 24)
    titleBar.verticalAlignment = VA_TOP
    titleBar.layoutMode = LM_HORIZONTAL

    local windowTitle = Text:new()
    windowTitle.name = "WindowTitle"
    windowTitle.text = "Hello GUI!"

    local buttonClose = Button:new()
    buttonClose:SetName("CloseButton")

    titleBar:AddChild(windowTitle)
    titleBar:AddChild(buttonClose)

    window:AddChild(titleBar)
    window:SetStyleAuto()
    windowTitle:SetStyleAuto()
    buttonClose:SetStyle("CloseButton")

    SubscribeToEvent(buttonClose, "Released", 
        function (eventType, eventData)
            engine:Exit()
        end)

    SubscribeToEvent("UIMouseClick", HandleControlClicked)

    --================================================
    local checkBox = CheckBox:new()
    checkBox:SetName("CheckBox")

    local button = Button:new()
    button:SetName("Button")
    button.minHeight = 24

    local lineEdit = LineEdit:new()
    lineEdit:SetName("LineEdit")
    lineEdit.minHeight = 24

    window:AddChild(checkBox)
    window:AddChild(button)
    window:AddChild(lineEdit)

    
    checkBox:SetStyleAuto()
    button:SetStyleAuto()
    lineEdit:SetStyleAuto()

    --========================================
    local draggableFish = ui.root:CreateChild("Button", "Fish")
    draggableFish.texture = cache:GetResource("Texture2D", "Textures/UrhoDecal.dds") -- Set texture
    draggableFish.blendMode = BLEND_ADD
    draggableFish:SetSize(128, 128)
    draggableFish:SetPosition((GetGraphics().width - draggableFish.width) / 2, 200)

    local toolTip = draggableFish:CreateChild("ToolTip")
    toolTip.position = IntVector2(draggableFish.width + 5, draggableFish.width/2) -- Slightly offset from fish
    local textHolder = toolTip:CreateChild("BorderImage")
    textHolder:SetStyle("ToolTipBorderImage")
    local toolTipText = textHolder:CreateChild("Text")
    toolTipText:SetStyle("ToolTipText")
    toolTipText.text = "Please drag me!"

    SubscribeToEvent(draggableFish, "DragBegin", 
        function (eventType, eventData)
            dragBeginPosition = IntVector2(eventData:GetInt("ElementX"), eventData:GetInt("ElementY"))
        end)

    SubscribeToEvent(draggableFish, "DragMove", 
        function (eventType, eventData)
            local dragCurrentPosition = IntVector2(eventData:GetInt("X"), eventData:GetInt("Y"))
            local draggedElement = eventData:GetPtr("UIElement", "Element")
            draggedElement:SetPosition(dragCurrentPosition - dragBeginPosition)
        end)
    
    SubscribeToEvent(draggableFish, "DragEnd", 
        function (eventType, eventData)
        end)
end


function InitTouchInput()
    touchEnabled = true
    local layout = cache:GetResource("XMLFile", "UI/ScreenJoystick_Samples.xml")
    local patchString = GetScreenJoystickPatchString()
    if patchString ~= "" then
        -- Patch the screen joystick layout further on demand
        local patchFile = XMLFile()
        if patchFile:FromString(patchString) then layout:Patch(patchFile) end
    end
    screenJoystickIndex = input:AddScreenJoystick(layout, cache:GetResource("XMLFile", "UI/DefaultStyle.xml"))
    input:SetScreenJoystickVisible(screenJoystickSettingsIndex, true)
end


function HandleKeyDown(eventType, eventData)
    local key = eventData:GetInt("Key")

end

function HandleSceneUpdate(eventType, eventData)
	if touchEnabled then
		for i=0, input:GetNumTouches()-1 do
            local state = input:GetTouch(i)
            if not state.touchedElement then -- Touch on empty space
                if state.delta.x or state.delta.y then
                else
                	local cursor = ui:GetCursor()
                    if cursor and cursor:IsVisible() then cursor:SetPosition(state.position) end
                end
            end
        end

	end
end

function HandleTouchBegin(eventType, eventData)
    InitTouchInput()
    UnsubscribeFromEvent("TouchBegin")
end


function HandleControlClicked(eventType, eventData)
    -- Get the Text control acting as the Window's title
    local element = window:GetChild("WindowTitle", true)
    local windowTitle = tolua.cast(element, 'Text')

    -- Get control that was clicked
    local clicked = eventData:GetPtr("UIElement", "Element")
    local name = "...?"
    if clicked ~= nil then
        -- Get the name of the control that was clicked
        name = clicked.name
    end

    -- Update the Window's title text
    windowTitle.text = "Hello " .. name .. "!"
end

-- Create XML patch instructions for screen joystick layout specific to this sample app
function GetScreenJoystickPatchString()
    return
        "<patch>" ..
        "    <add sel=\"/element/element[./attribute[@name='Name' and @value='Hat0']]\">" ..
        "        <attribute name=\"Is Visible\" value=\"false\" />" ..
        "    </add>" ..
        "</patch>"
end
