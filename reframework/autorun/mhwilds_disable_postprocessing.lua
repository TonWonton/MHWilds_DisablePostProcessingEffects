--Mod header
local mod = {
    name = "Disable Post Processing Effects",
    id = "DisablePostProcessingEffects",
    version = "1.3.2",
    author = "TonWonton",
    settings
}

--Default settings
local settings =
{
    TAA = false,
    jitter = false,
    colorCorrect = true,
    lensDistortionEnable = false,
    localExposure = true,
    localExposureBlurredLuminance = false,
    customContrastEnable = false,
    filmGrain = true,
    lensFlare = true,
    godRay = true,
    fog = true,
    volumetricFog = true,
    customBrightnessEnable = false,
    customContrast = 1.0,
    gamma = 1.0,
    gammaOverlay = 1.0,
    lowerLimit = 0.0,
    upperLimit = 1.0,
    lowerLimitOverlay = 0.0,
    upperLimitOverlay = 1.0
}

mod.settings = settings
_G[mod.id] = mod --Globalize mod header

--Enums
local TAAStrength, localExposureType, lensDistortionSetting
--Singleton and manager types
local cameraManager, cameraManagerType, graphicsManager
--gameobject, component, and type definitions
local camera, cameraGameObject, LDRPostProcess, colorCorrectComponent, tonemapping, tonemappingType, graphicsSetting, displaySettings

local apply = false
local initialized = false
local changeBrightness = false


--Generate enums
function GenerateEnum(typename, double_ended)
    local double_ended = double_ended or false

    local t = sdk.find_type_definition(typename)
    if not t then return {} end

    local fields = t:get_fields()
    local enum = {}

    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)

            log.info(name .. " = " .. tostring(raw_value))

            enum[name] = raw_value

            if double_ended then
                enum[raw_value] = name
            end
        end
    end

    return enum
end

--Saves settings to json
local function SaveSettings()
    json.dump_file("mhwi_remove_postprocessing.json", settings)
end

--Loads settings depending on overload and puts into table
--0 and default = saved user config or script defaults, 1 = script defaults, 2 = game defaults
local function LoadSettings(setting)
    if settings.customBrightnessEnable == true then changeBrightness = true end

    local loadedTable
    if setting == 1 then
        loadedTable = json.load_file("mhwi_disablepostprocessingeffects_defaults.json")
    elseif setting == 2 then
        loadedTable = json.load_file("mhwi_disablepostprocessingeffects_game_defaults.json")
    else
        loadedTable = json.load_file("mhwi_remove_postprocessing.json")
    end

    if loadedTable ~= nil then
        for key, val in pairs(loadedTable) do
            settings[key] = loadedTable[key]
        end
    end
end

--Get component from gameobject
local function get_component(game_object, type_name)
    local t = sdk.typeof(type_name)
    if t == nil then 
        return nil
    end
    return game_object:call("getComponent(System.Type)", t)
end

local function ResetBrightness()
    settings.gamma = 1.0
    settings.gammaOverlay = 1.0
    settings.lowerLimit = 0.0
    settings.upperLimit = 1.0
    settings.lowerLimitOverlay = 0.0
    settings.upperLimitOverlay = 1.0
end


--Apply settings
local function ApplySettings()
    if initialized == false then log.info("[DISABLE POST PROCESSING] Not initialized, not applying settings") return end

    --Set tonemapping
    tonemapping:call("setTemporalAA", settings.TAA and TAAStrength.Manual or TAAStrength.Disable)
    tonemapping:call("set_EchoEnabled", settings.jitter)
    tonemapping:call("set_EnableLocalExposure", settings.localExposure)
    tonemapping:call("setLocalExposureType", settings.localExposureBlurredLuminance and localExposureType.BlurredLuminance or localExposureType.Legacy)

    --Set contrast values depending on customContrastEnable
    if settings.customContrastEnable == true then
        tonemapping:call("set_Contrast", settings.customContrast)
    elseif settings.colorCorrect == false then
        tonemapping:call("set_Contrast", 1.0)
    else
        tonemapping:call("set_Contrast", 0.3)
    end

    --Set gamma and brightness depending on customBrightnessEnable and HDR
    if settings.customBrightnessEnable == true or changeBrightness == true then
        local HDRMode = displaySettings:call("get_HDRMode")
        displaySettings:call("set_UseSDRBrightnessOptionForOverlay", true)
        displaySettings:call("set_Gamma", settings.gamma)
        displaySettings:call("set_GammaForOverlay", settings.gammaOverlay)
        displaySettings:call("set_OutputLowerLimit", settings.lowerLimit)
        displaySettings:call("set_OutputUpperLimit", settings.upperLimit)
        displaySettings:call("set_OutputLowerLimitForOverlay", settings.lowerLimitOverlay)
        displaySettings:call("set_OutputUpperLimitForOverlay", settings.upperLimitOverlay)
        if settings.customBrightnessEnable == false and changeBrightness == true then displaySettings:call("set_UseSDRBrightnessOptionForOverlay", false) end
        if HDRMode == false then displaySettings:call("updateRequest") end
        changeBrightness = false
    else
        displaySettings:call("set_UseSDRBrightnessOptionForOverlay", false)
    end
    
    --Set graphics setting and apply if clicked on apply graphics settings button
    graphicsSetting:call("set_Fog_Enable", settings.fog)
    graphicsSetting:call("set_VolumetricFogControl_Enable", settings.volumetricFog)
    graphicsSetting:call("set_FilmGrain_Enable", settings.filmGrain)
    graphicsSetting:call("set_LensFlare_Enable", settings.lensFlare)
    graphicsSetting:call("set_GodRay_Enable", settings.godRay)
    graphicsSetting:call("set_LensDistortionSetting", settings.lensDistortionEnable and lensDistortionSetting.ON or lensDistortionSetting.OFF)
    if apply == true then graphicsManager:call("setGraphicsSetting", graphicsSetting) end
end


--Initialize by getting singletons, types, objects, then create hooks
local function Initialize()
    --Get singletons managers
    cameraManager = sdk.get_managed_singleton("app.CameraManager")
    if cameraManager == nil then return end
    graphicsManager = sdk.get_managed_singleton("app.GraphicsManager")
    if graphicsManager == nil then return end
    log.info("[DISABLE POST PROCESSING] Singleton managers get successful")

    --Get types
    cameraManagerType = sdk.find_type_definition("app.CameraManager")
    log.info("[DISABLE POST PROCESSING] Singleton managers type definition get successful")

    --Get gameobjects, components, type definitions, and enums
    camera = cameraManager:call("get_PrimaryCamera")
    cameraGameObject = camera:call("get_GameObject")
    LDRPostProcess = get_component(cameraGameObject, "via.render.LDRPostProcess")
    colorCorrectComponent = LDRPostProcess:call("get_ColorCorrect")
    tonemapping = get_component(cameraGameObject, "via.render.ToneMapping")
    tonemappingType = sdk.find_type_definition("via.render.ToneMapping")
    graphicsSetting = graphicsManager:call("get_NowGraphicsSetting")
    displaySettings = graphicsManager:call("get_DisplaySettings")
    TAAStrength = GenerateEnum("via.render.ToneMapping.TemporalAA", true)
    localExposureType = GenerateEnum("via.render.ToneMapping.LocalExposureType", true)
    lensDistortionSetting = GenerateEnum("via.render.RenderConfig.LensDistortionSetting", true)
    log.info("[DISABLE POST PROCESSING] Component get and enum generation successful")

    --Create hooks and register callback
    sdk.hook(cameraManagerType:get_method("onSceneLoadFadeIn"), function() end, function() ApplySettings() end)
    sdk.hook(tonemappingType:get_method("clearHistogram"), function() end, function() tonemapping:call("set_EnableLocalExposure", settings.localExposure) end)
    re.on_application_entry("LockScene", function() colorCorrectComponent:call("set_Enabled", settings.colorCorrect) end)
    log.info("[DISABLE POST PROCESSING] Hook and callback creation successful")

    --Apply settings after initialization
    initialized = true
    ApplySettings()
    log.info("[DISABLE POST PROCESSING] Initialization successful")
end


--Load settings at the start and keep trying to initialize until all singleton managers get
LoadSettings(0)
re.on_frame(function() if initialized == false then Initialize() end end)
--Save settings at the same time as REFramework
re.on_config_save(SaveSettings)


--Script generated UI
re.on_draw_ui(function()
    if imgui.tree_node(mod.name .. " v" .. mod.version) then
        local changed = false

        --Save settings or load settings when clicking on buttons
        imgui.push_style_color(21, 0xFF030380)
        changed = imgui.small_button("Save settings")
        if changed == true then SaveSettings() end
        imgui.pop_style_color(1)
        imgui.same_line()
        imgui.push_style_color(21, 0xFF030380)
        changed = imgui.small_button("Load script defaults")
        if changed == true then LoadSettings(1) ApplySettings() end
        imgui.pop_style_color(1)
        imgui.same_line()
        imgui.push_style_color(21, 0xFF030380)
        changed = imgui.small_button("Load game defaults")
        if changed == true then LoadSettings(2) ApplySettings() end
        imgui.pop_style_color(1)
        imgui.push_style_color(21, 0xFF030380)
        changed = imgui.small_button("Load saved settings")
        if changed == true then LoadSettings(0) ApplySettings() end
        imgui.pop_style_color(1)
        imgui.text("NOTE: requires game restart after loading defaults to fully revert brightness changes")
        imgui.spacing()

        imgui.text("Anti-Aliasing & filters")
        changed, settings.TAA = imgui.checkbox("TAA", settings.TAA)
        if changed == true then ApplySettings() end
        imgui.indent(24)
        changed, settings.jitter = imgui.checkbox("TAA jitter", settings.jitter)
        if changed == true then ApplySettings() end
        imgui.unindent(24)
        changed, settings.colorCorrect = imgui.checkbox("Color correction", settings.colorCorrect)
        if changed == true then ApplySettings() end
        changed, settings.localExposure = imgui.checkbox("Local exposure", settings.localExposure)
        if changed == true then ApplySettings() end
        imgui.indent(24)
        changed, settings.localExposureBlurredLuminance = imgui.checkbox("Use blurred luminance (sharpens)", settings.localExposureBlurredLuminance)
        if changed == true then ApplySettings() end
        imgui.unindent(24)
        changed, settings.customContrastEnable = imgui.checkbox("Enable custom contrast", settings.customContrastEnable)
        if changed == true then ApplySettings() end
        changed, settings.customContrast = imgui.drag_float("Contrast", settings.customContrast, 0.01, 0.01, 5.0)
        if changed == true then ApplySettings() end
        imgui.new_line()

        imgui.text("SDR gamma & Brightness")
        changed, settings.customBrightnessEnable = imgui.checkbox("Enable SDR custom gamma & brightness", settings.customBrightnessEnable)
        if changed == true then ApplySettings() end
        imgui.text("NOTE: requires game restart after disabling to revert changes")
        imgui.spacing()

        imgui.text_colored("Use in game brightness options for HDR", 0xAD0000FF)
        imgui.push_style_color(21, 0xFF030380)
        changed = imgui.small_button("Reset gamma & brightness")
        imgui.pop_style_color(1)
        if changed == true then ResetBrightness() ApplySettings() end
        changed, settings.gamma = imgui.drag_float("Gamma", settings.gamma, 0.001, 0.001, 5.0)
        if changed == true then ApplySettings() end
        changed, settings.upperLimit = imgui.drag_float("Max brightness", settings.upperLimit, 0.001, 0.001, 10.0)
        if changed == true then ApplySettings() end
        changed, settings.lowerLimit = imgui.drag_float("Min brightness", settings.lowerLimit, 0.001, -5.0, 5.0)
        if changed == true then ApplySettings() end
        imgui.spacing()

        changed, settings.gammaOverlay = imgui.drag_float("UI gamma", settings.gammaOverlay, 0.001, 0.001, 5.0)
        if changed == true then ApplySettings() end
        changed, settings.upperLimitOverlay = imgui.drag_float("UI max brightness", settings.upperLimitOverlay, 0.001, 0.001, 10.0)
        if changed == true then ApplySettings() end
        changed, settings.lowerLimitOverlay = imgui.drag_float("UI min brightness", settings.lowerLimitOverlay, 0.001, -5.0, 5.0)
        if changed == true then ApplySettings() end
        imgui.new_line()

        imgui.text("Graphics Settings")
        imgui.push_style_color(21, 0xFF030380)
        apply = imgui.small_button("Apply graphics settings")
        imgui.pop_style_color(1)
        if apply == true then ApplySettings() apply = false end
        changed, settings.lensDistortionEnable = imgui.checkbox("Lens distortion", settings.lensDistortionEnable)
        if changed == true then ApplySettings() end
        changed, settings.fog = imgui.checkbox("Fog", settings.fog)
        if changed == true then ApplySettings() end
        changed, settings.volumetricFog = imgui.checkbox("Volumetric fog", settings.volumetricFog)
        if changed == true then ApplySettings() end
        changed, settings.filmGrain = imgui.checkbox("Film grain", settings.filmGrain)
        if changed == true then ApplySettings() end
        changed, settings.lensFlare = imgui.checkbox("Lens flare", settings.lensFlare)
        if changed == true then ApplySettings() end
        changed, settings.godRay = imgui.checkbox("Godray", settings.godRay)
        if changed == true then ApplySettings() end
        imgui.spacing()

        imgui.text("WARNING: applying graphics settings will set")
        imgui.text("ambient lighting to high due to a bug in the game")
        imgui.text("until returning to title or restarting the game")
        imgui.spacing()

        imgui.tree_pop()
    end
end)