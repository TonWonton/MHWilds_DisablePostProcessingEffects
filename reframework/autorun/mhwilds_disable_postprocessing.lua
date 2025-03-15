--v1.1.3
local statics = require("utility/Statics")
local TAAStrength = statics.generate("via.render.ToneMapping.TemporalAA", true)
local localExposureType = statics.generate("via.render.ToneMapping.LocalExposureType", true)
local lensDistortionSetting = statics.generate("via.render.RenderConfig.LensDistortionSetting", true)

--Default settings
local settings =
{
    TAA = false,
    jitter = false,
    LDRPostProcessEnable = true,
    colorCorrect = true,
    lensDistortionEnable = false,
    localExposure = false,
    localExposureBlurredLuminance = true,
    customContrastEnable = false,
    filmGrain = true,
    lensFlare = true,
    godRay = true,
    fog = true,
    volumetricFog = true,
    customContrast = 1.0
}

local apply = false
local save = false
local changed = false
local initialized = false

--Singleton and manager types
local cameraManager, cameraManagerType, graphicsManager, graphicsManagerType
--gameobject, component, and type definitions
local camera, cameraGameObject, LDRPostProcess, colorCorrectComponent, tonemapping, tonemappingType, graphicsSetting


--Saves settings to json
local function SaveSettings()
    json.dump_file("mhwi_remove_postprocessing.json", settings)
end

--Loads settings from json and puts into settings table
local function LoadSettings()
    local loadedTable = json.load_file("mhwi_remove_postprocessing.json")
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


--Apply settings
local function ApplySettings()
    if initialized == false then log.info("[DISABLE POST PROCESSING] Not initialized, not applying settings") return end
    log.info("[DISABLE POST PROCESSING] Applying settings")

    --Set tonemapping and LDRPostProcessing
    tonemapping:call("setTemporalAA", settings.TAA and TAAStrength.Strong or TAAStrength.Disable)
    tonemapping:call("set_EchoEnabled", settings.jitter)
    tonemapping:call("set_EnableLocalExposure", settings.localExposure)
    tonemapping:call("setLocalExposureType", settings.localExposureBlurredLuminance and localExposureType.BlurredLuminance or localExposureType.Legacy)

    --Set contast values depending on customContrastEnable
    if settings.customContrastEnable == true then
        tonemapping:call("set_Contrast", settings.customContrast)
    elseif settings.colorCorrect == false then
        tonemapping:call("set_Contrast", 1.0)
    else
        tonemapping:call("set_Contrast", 0.3)
    end
    
    --Set graphics setting
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
    log.info("[DISABLE POST PROCESSING] Trying to initialize...")

    --Get singletons managers
    cameraManager = sdk.get_managed_singleton("app.CameraManager")
    if cameraManager == nil then return end
    graphicsManager = sdk.get_managed_singleton("app.GraphicsManager")
    if graphicsManager == nil then return end
    log.info("[DISABLE POST PROCESSING] Singleton managers get successful")

    --Get types
    cameraManagerType = sdk.find_type_definition("app.CameraManager")
    graphicsManagerType = sdk.find_type_definition("app.GraphicsManager")
    log.info("[DISABLE POST PROCESSING] Singleton managers type definition get successful")

    --Get gameobjects, components, and type definitions
    camera = cameraManager:call("get_PrimaryCamera")
    cameraGameObject = camera:call("get_GameObject")
    LDRPostProcess = get_component(cameraGameObject, "via.render.LDRPostProcess")
    colorCorrectComponent = LDRPostProcess:call("get_ColorCorrect")
    tonemapping = get_component(cameraGameObject, "via.render.ToneMapping")
    tonemappingType = sdk.find_type_definition("via.render.ToneMapping")
    graphicsSetting = graphicsManager:call("get_NowGraphicsSetting")
    log.info("[DISABLE POST PROCESSING] Component get successful")

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
LoadSettings()
re.on_frame(function() if initialized == false then Initialize() end end)


--Script generated UI
re.on_draw_ui(function()
    if imgui.tree_node("Post Processing Settings") then
        changed = false

        --Settings menu
        changed, settings.TAA = imgui.checkbox("TAA enabled", settings.TAA)
        if changed == true then ApplySettings() end
        changed, settings.jitter = imgui.checkbox("TAA jitter enabled", settings.jitter)
        if changed == true then ApplySettings() end
        imgui.new_line()

        changed, settings.colorCorrect = imgui.checkbox("Color correction", settings.colorCorrect)
        if changed == true then ApplySettings() end
        changed, settings.localExposure = imgui.checkbox("Local exposure enabled", settings.localExposure)
        if changed == true then ApplySettings() end
        imgui.text("    ") imgui.same_line()
        changed, settings.localExposureBlurredLuminance = imgui.checkbox("Use blurred luminance (sharpens)", settings.localExposureBlurredLuminance)
        if changed == true then ApplySettings() end
        changed, settings.customContrastEnable = imgui.checkbox("Custom contrast enabled", settings.customContrastEnable)
        if changed == true then ApplySettings() end
        changed, settings.customContrast = imgui.drag_float("Contrast", settings.customContrast, 0.01, 0.01, 5.0)
        if changed == true then ApplySettings() end
        imgui.new_line()

        imgui.text("Graphics Settings")
        changed, settings.lensDistortionEnable = imgui.checkbox("Lens distortion enabled", settings.lensDistortionEnable)
        if changed == true then ApplySettings() end
        changed, settings.fog = imgui.checkbox("Fog enabled", settings.fog)
        if changed == true then ApplySettings() end
        changed, settings.volumetricFog = imgui.checkbox("Volumetric fog enabled", settings.volumetricFog)
        if changed == true then ApplySettings() end
        changed, settings.filmGrain = imgui.checkbox("Film grain enabled", settings.filmGrain)
        if changed == true then ApplySettings() end
        changed, settings.lensFlare = imgui.checkbox("Lens flare enabled", settings.lensFlare)
        if changed == true then ApplySettings() end
        changed, settings.godRay = imgui.checkbox("Godray enabled", settings.godRay)
        if changed == true then ApplySettings() end
        imgui.spacing()

        --Apply graphics settings when clicking on apply box
        changed, apply = imgui.checkbox("Apply graphics settings", apply)
        if apply == true then
            ApplySettings()
            apply = false
        end
        imgui.text("WARNING: applying graphics settings will set")
        imgui.text("ambient lighting to high due to a bug in the game")
        imgui.text("until returning to title or restarting the game")
        imgui.new_line()

        --Save settings when clicking on save box
        changed, save = imgui.checkbox("Save settings", save)
        if save == true then
            SaveSettings()
            save = false
        end
        imgui.new_line()

        imgui.tree_pop()
    end
end)