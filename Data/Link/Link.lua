-- a link game for something

URHO3D_VER = 15;

local LinkClass = require("Link/LinkClass")
local LinkTexture = require("Link/LinkTexture")

function log_info(str) 	print(str.."") end
function log_debug(str) print(str.."") end
function log_warn(str)  print(str.."") end
function log_error(str) print(str.."") end

function __G__TRACKBACK__(msg)
    log_error("-----------------------------------------------------");
    log_error(msg)
    log_error(debug.traceback())
    log_error("-----------------------------------------------------");
end

local lk_game = nil
local lk_list = nil;

local lastClicked =  nil; -- {tp=, mx=, my=, win=}

local logoSprite = nil
screenJoystickIndex = M_MAX_UNSIGNED
screenJoystickSettingsIndex = M_MAX_UNSIGNED
touchEnabled = false

function Start()
	if GetPlatform() == "Android" or GetPlatform() == "iOS" or input.touchEmulation then
        InitTouchInput();
    elseif input:GetNumJoysticks() == 0 then
        SubscribeToEvent("TouchBegin", "HandleTouchBegin")
    end

    --============================
    local desktopResolution = graphics.desktopResolution;
    local icon = cache:GetResource("Image", "Textures/UrhoIcon.png")
    graphics:SetWindowIcon(icon)
    graphics.windowTitle = "Urho3D Link"
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
    
    --  window
    window = Window:new()
    ui.root:AddChild(window)

    window:SetMinSize(500, 500)
    window:SetLayout(LM_FREE, 6, IntRect(6, 6, 6, 6))
    window:SetAlignment(HA_CENTER, VA_CENTER)
    window:SetName("Window")

    local titleBar = UIElement:new()
    titleBar:SetMinSize(500, 24)
    titleBar.verticalAlignment = VA_TOP
    titleBar.layoutMode = LM_FREE

    local windowTitle = Text:new()
    windowTitle.name = "WindowTitle"
    windowTitle.text = "Hello GUI!"

    local buttonClose = Button:new()
    buttonClose:SetName("CloseButton")
    buttonClose:SetPosition(480, 0);

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
    local num = #LinkTexture;
    lk_game = LinkClass:new(num);
    lk_game:build();
	
	log_info(lk_game:mapToString());

    -- LinkTexture
    local mx = lk_game:mx();
    local my = lk_game:my();
    local m = lk_game:getMap();
    lk_list = {};

    for i = 1,  mx do
        for j = 1, my do
            local tp = m[i][j];
			if (tp > 0) then
				local img_url = LinkTexture[tp];
				
				local x = (i - 1) * 50;
				local y = (j - 1) * 50;

				local button = Button:new()
				button:SetName("Button"..i.."_"..j)
				button:SetSize(50, 50)
				button.texture = cache:GetResource("Texture2D", img_url)
				if (URHO3D_VER == 14) then
					local vv1 = Variant();
					local vv2 = Variant();
					local vv3 = Variant();
					vv1:SetInt(i);
					vv2:SetInt(j);
					vv3:SetInt(tp);
					
					button:SetVar(StringHash("mx"), vv1);
					button:SetVar(StringHash("my"), vv2);
					button:SetVar(StringHash("tp"), vv3);
				else
					button:SetVar(StringHash("mx"), Variant(i));
					button:SetVar(StringHash("my"), Variant(j));
					button:SetVar(StringHash("tp"), Variant(tp));
				end
				button:SetPosition(x, y);
				window:AddChild(button)

				table.insert(lk_list, {button = button, mx = i, my = j, tp = tp});
			end
        end
    end

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
	if (window == nil) then
		CreateWindow();
    elseif key == KEY_F1 then
        console:Toggle()
    end
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
    local element = window:GetChild("WindowTitle", true)
    local windowTitle = tolua.cast(element, 'Text')

    local clicked = nil;
	if (URHO3D_VER == 14) then
		clicked = eventData:GetPtr("UIElement", "Element")
	else
		clicked = eventData["Element"]:GetPtr("UIElement")
	end
	
    local name = "...?"
    local str = '';
    if clicked ~= nil then
        name = clicked.name
        local mx = clicked:GetVar(StringHash("mx")):GetInt();
        local my = clicked:GetVar(StringHash("my")):GetInt();
        local tp = clicked:GetVar(StringHash("tp")):GetInt();
        str = mx.."_"..my.."_"..tp;
		
		local lc = lastClicked;
		if (lastClicked ~= nil) then
			local p1 = {x = mx, y = my};
			local p2 = {x = lc.mx, y = lc.my};
			if (lc.tp == tp and lc.win ~= clicked and lk_game:checkLink(p1, p2)) then
				window:RemoveChild(lc.win);
				window:RemoveChild(clicked);
				lk_game:removePairs(p1, p2);
				local ss = lk_game:toString();
				str = str .. ss;
			end
			lastClicked = nil;
		else
			lastClicked = {tp = tp, mx = mx, my = my, win = clicked};
		end
    end

    windowTitle.text = "Hello " .. name .. "!" .. str;
end

function GetScreenJoystickPatchString()
    return
        "<patch>" ..
        "    <add sel=\"/element/element[./attribute[@name='Name' and @value='Hat0']]\">" ..
        "        <attribute name=\"Is Visible\" value=\"false\" />" ..
        "    </add>" ..
        "</patch>"
end
