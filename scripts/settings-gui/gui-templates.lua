-- GUI templates for the Even Distribution settings

local this = {templates = {}}
local util = scripts.util
local config = require("config")
local gui = scripts["gui-tools"]
local controller

local helpers = scripts.helpers
local _ = helpers.on


-- this.templates.showSettingsButton = {
-- 	type = "sprite-button",
-- 	name = "show-settings-button",
-- 	onCreated = function (self, data)
-- 		-- self.style = "attach-notes-view-button"
-- 		-- self.tooltip = { "tooltips.view-note" }
		
-- 		_(self.style):set{
-- 			width  = 36,
-- 			height = 36,
-- 		}
-- 	end,
-- 	onClicked = function (event)
-- 		local player = _(event.element.gui.player)
-- 		local opened = _(player.opened)
-- 		local cache  = _(global.cache[player.index])
		
-- 		if notes[opened] then
		
-- 			cache.noteIsHidden = not cache.noteIsHidden -- toggle hidden state if note is present
-- 		else
-- 			notes[opened] = {} -- create new note if no note is present
			
-- 			local note = notes[opened]
-- 			local setting = player.mod_settings["show-marker-by-default"].value
-- 			if setting and not components.marker.isDisabledForEntity(opened) then -- create marker if necessary
-- 				if not util.isValid(note.marker) then note.marker = components.marker.create(opened) end
-- 			end
			
-- 			cache.noteIsHidden = false
-- 		end
		
-- 		controller.buildGUI(player, cache) -- rebuild gui
-- 		opened.last_user = player
-- 	end
-- }


local function updateLimiter(flow, profiles, action, newValue) -- switch to next type
	local player  = _(flow.gui.player)
	local value   = action == "value" and newValue or player:setting(profiles.valueSetting)
	local oldType = player:setting(profiles.typeSetting)
	local type    = action == "type" and profiles[oldType].next or oldType
	local profile = profiles[type]
	local name    = profiles.name
	local enabled = player:setting(profiles.enableSetting)
	if action == "enable" then enabled = flow[name.."_checkbox"].state end
	
	-- clamp value to bounds
	local decimal = (profile.step < 1)
	if not decimal then value = math.floor(value) end
	if value > profile.max then value = profile.max end
	if value < profile.min then value = profile.min end
	
	-- update GUI
	flow[name.."_textfield"].allow_decimal = decimal
	flow[name.."_slider"].set_slider_minimum_maximum(profile.min, profile.max)
	flow[name.."_slider"].set_slider_value_step(profile.step)

	flow[name.."_checkbox"].state      = enabled
	flow[name.."_slider"].slider_value = value
	flow[name.."_textfield"].text      = value
	flow[name.."_checkbox"].tooltip    = {profiles.tooltipLocale.."."..(enabled and type or "disabled"), value, math.floor(value*100)}
	flow[name.."_type"].caption        = {profiles.typeLocale.."."..type}

	flow[name.."_slider"].enabled    = enabled
	flow[name.."_textfield"].enabled = enabled
	flow[name.."_type"].enabled      = enabled

	-- save settings
	player:changeSetting(profiles.enableSetting, enabled)
	player:changeSetting(profiles.typeSetting, type)
	player:changeSetting(profiles.valueSetting, value)
end

this.templates.settingsWindow = {
	type = "frame",
	name = "ed_settings_window",
	direction = "vertical",
	caption = "Even Distribution",
	root = function(player) return player.gui.screen end,
	onClicked = function(event)
		local index  = event.player_index
		local player = _(event.element.gui.player)
		local cache  = _(global.cache[player.index])

		-- ...
		--dlog("clicked")
	end,
	children = {
		{
			type = "scroll-pane",
			vertical_scroll_policy = "auto-and-reserve-space",
			style = {
				parent = "control_settings_scroll_pane", --"scroll_pane_with_dark_background_under_subheader",
				minimal_width = 530, -- 350,
				minimal_height = 344, -- Inventory GUI height
				maximal_height = 600,
			},
			children = {
				{
					type = "frame",
					direction = "vertical",
					style = "ed_settings_inner_frame",
					children = 
					{
						{
							type = "flow",
							name = "frame_header",
							direction = "horizontal",
							children = 
							{
								{
									type = "label",
									name = "frame_caption",
									style = "heading_3_label_yellow",
									caption = {"settings-gui.drag-title"},
								},
								{
									type = "empty-widget",
									style = "ed_stretch",
								},
								{
									type = "checkbox",
									name = "enable_drag_distribute",
									caption = {"settings-gui.enable"},
									state = true,
									onCreated = function(self)
										local player = _(self.gui.player)
										self.state = player:setting("enableDragDistribute")
										self.parent.frame_caption.enabled = self.state
									end,
									onChanged = function(event)
										local self = event.element
										self.parent.parent.frame_content.visible = self.state
										self.parent.frame_caption.enabled = self.state

										local player = _(self.gui.player)
										player:changeSetting("enableDragDistribute", self.state)
									end,
								},
							}
						},
						{
							type = "flow",
							name = "frame_content",
							direction = "vertical",
							onCreated = function(self)
								self.visible = _(self.gui.player):setting("enableDragDistribute")
							end,
							children = 
							{
								{
									type = "flow",
									direction = "horizontal",
									style = {
										vertical_align = "center",
									},
									onCreated = function(self)
										updateLimiter(self, config.fuelLimitProfiles)
									end,
									children = 
									{
										{
											type = "checkbox",
											name = "fuel_drag_limit_checkbox",
											caption = {"", {"settings-gui.fuel-limit"}, " [img=info]"},
											state = true,
											onChanged = function(event)
												updateLimiter(event.element.parent, config.fuelLimitProfiles, "enable")
											end,
										},
										{
											type = "empty-widget",
											style = "ed_stretch",
										},
										{
											type = "slider",
											name = "fuel_drag_limit_slider",
											--style = "red_slider",
											discrete_slider = false,
											discrete_values = true,
											onChanged = function(event)
												local value = event.element.slider_value
												if type(value) == "number" then
													updateLimiter(event.element.parent, config.fuelLimitProfiles, "value", value)
												end
											end,
										},
										{
											type = "textfield",
											name = "fuel_drag_limit_textfield",
											style = {
												parent = "slider_value_textfield",
												width = 60,
											},
											numeric = true,
											allow_negative = false,
											lose_focus_on_confirm = true,
											onChanged = function(event)
												local value = tonumber(event.element.text)
												if type(value) == "number" then
													updateLimiter(event.element.parent, config.fuelLimitProfiles, "value", value)
												end
											end,
										},
										{
											type = "button",
											name = "fuel_drag_limit_type",
											style = {
												padding = 0,
												width = 56, -- 38,
											},
											-- caption = "Stacks",
											onChanged = function(event)
												updateLimiter(event.element.parent, config.fuelLimitProfiles, "type")
											end,
										},
									}
								},
								{
									type = "flow",
									direction = "horizontal",
									style = {
										vertical_align = "center",
									},
									onCreated = function(self)
										updateLimiter(self, config.ammoLimitProfiles)
									end,
									children = 
									{
										{
											type = "checkbox",
											name = "ammo_drag_limit_checkbox",
											caption = {"", {"settings-gui.ammo-limit"}, " [img=info]"},
											state = true,
											onChanged = function(event)
												updateLimiter(event.element.parent, config.ammoLimitProfiles, "enable")
											end,
										},
										{
											type = "empty-widget",
											style = "ed_stretch",
										},
										{
											type = "slider",
											name = "ammo_drag_limit_slider",
											--style = "red_slider",
											discrete_slider = false,
											discrete_values = true,
											onChanged = function(event)
												local value = event.element.slider_value
												if type(value) == "number" then
													updateLimiter(event.element.parent, config.ammoLimitProfiles, "value", value)
												end
											end,
										},
										{
											type = "textfield",
											name = "ammo_drag_limit_textfield",
											style = {
												parent = "slider_value_textfield",
												width = 60,
											},
											numeric = true,
											allow_negative = false,
											lose_focus_on_confirm = true,
											onChanged = function(event)
												local value = tonumber(event.element.text)
												if type(value) == "number" then
													updateLimiter(event.element.parent, config.ammoLimitProfiles, "value", value)
												end
											end,
										},
										{
											type = "button",
											name = "ammo_drag_limit_type",
											style = {
												padding = 0,
												width = 56, -- 38,
											},
											onChanged = function(event)
												updateLimiter(event.element.parent, config.ammoLimitProfiles, "type")
											end,
										},
									}
								},
								{
									type = "flow",
									direction = "horizontal",
									style = {
										vertical_align = "center",
									},
									children = 
									{
										{
											type = "label",
											-- style = "heading_3_label_yellow",
											caption = {"settings-gui.distribute-from"},
										},
										{
											type = "empty-widget",
											style = "ed_stretch",
										},
										{
											type = "sprite-button",
											name = "button_take_from_hand",
											tooltip = {"settings-gui.hand-tooltip"},
											sprite = "utility/hand",
											style = {
												parent = "ed_switch_button_selected",
												minimal_width  = 40,
												minimal_height = 40,
												left_margin    = -2,
												right_margin   = -2,
											},
											onChanged = function(event)
												local flow = event.element.parent
												flow.button_take_from_inventory.style = "ed_switch_button"
												flow.button_take_from_car.style       = "ed_switch_button"
												
												local player = _(flow.gui.player)
												player:changeSetting("takeFromInventory", false)
												player:changeSetting("takeFromCar", false)
											end,
										},
										{
											type = "sprite-button",
											name = "button_take_from_inventory",
											tooltip = {"settings-gui.inventory-tooltip"},
											sprite = "entity/character",
											style = {
												parent = "ed_switch_button",
												minimal_width  = 40,
												minimal_height = 40,
												left_margin    = -2,
												right_margin   = -2,
											},
											onCreated = function(self)
												local player = _(self.gui.player)
												self.style = player:setting("takeFromInventory") and "ed_switch_button_selected" or "ed_switch_button"
											end,
											onChanged = function(event)
												local flow = event.element.parent
												local nowActive = event.element.style.name == "ed_switch_button"
												if flow.button_take_from_car.style.name == "ed_switch_button_selected" then nowActive = true end

												flow.button_take_from_inventory.style = nowActive and "ed_switch_button_selected" or "ed_switch_button"
												flow.button_take_from_car.style       = "ed_switch_button"
												
												local player = _(flow.gui.player)
												player:changeSetting("takeFromInventory", nowActive)
												player:changeSetting("takeFromCar", false)
											end,
										},
{
											type = "sprite-button",
											name = "button_take_from_car",
											tooltip = {"settings-gui.car-tooltip"},
											sprite = "entity/car",
											style = {
												parent = "ed_switch_button",
												minimal_width  = 40,
												minimal_height = 40,
												left_margin    = -2,
												right_margin   = -2,
											},
											onCreated = function(self)
												local player = _(self.gui.player)
												self.style = player:setting("takeFromCar") and "ed_switch_button_selected" or "ed_switch_button"
											end,
											onChanged = function(event)
												local flow = event.element.parent
												local nowActive = event.element.style.name == "ed_switch_button"
												
												flow.button_take_from_inventory.style = "ed_switch_button_selected"
												flow.button_take_from_car.style       = nowActive and "ed_switch_button_selected" or "ed_switch_button"
												
												local player = _(flow.gui.player)
												player:changeSetting("takeFromInventory", true)
												player:changeSetting("takeFromCar", nowActive)
											end,
										},
									}
								},
							}
						},
					}
				},
				{
					type = "frame",
					direction = "vertical",
					style = "ed_settings_inner_frame",
					children = 
					{
						{
							type = "flow",
							name = "frame_header",
							direction = "horizontal",
							children = 
							{
								{
									type = "label",
									name = "frame_caption",
									style = "heading_3_label_yellow",
									caption = {"settings-gui.drag-title"},
								},
								{
									type = "empty-widget",
									style = "ed_stretch",
								},
								{
									type = "checkbox",
									name = "enable_drag_take",
									caption = {"settings-gui.enable"},
									state = true,
									onCreated = function(self)
										local player = _(self.gui.player)
										self.state = player:setting("enableDragTake")
										self.parent.frame_caption.enabled = self.state
									end,
									onChanged = function(event)
										local self = event.element
										self.parent.parent.frame_content.visible = self.state
										self.parent.frame_caption.enabled = self.state

										local player = _(self.gui.player)
										player:changeSetting("enableDragTake", self.state)
									end,
								},
							}
						},
						{
							type = "flow",
							name = "frame_content",
							direction = "vertical",
							onCreated = function(self)
								self.visible = _(self.gui.player):setting("enableDragTake")
							end,
							children = 
							{
								{
									type = "label",
									caption = "123123123123",
								},
								{
									type = "label",
									caption = "asdasdasdasd",
								},
							}
						},
					}
				},
				{
					type = "frame",
					direction = "vertical",
					style = "ed_settings_inner_frame",
					children = 
					{
						{
							type = "flow",
							name = "frame_header",
							direction = "horizontal",
							children = 
							{
								{
									type = "label",
									name = "frame_caption",
									style = "heading_3_label_yellow",
									caption = {"settings-gui.inventory-cleanup-title"},
								},
								{
									type = "empty-widget",
									style = "ed_stretch",
								},
								{
									type = "checkbox",
									name = "enable_inventory_cleanup_hotkey",
									caption = {"settings-gui.enable"},
									state = true,
									onCreated = function(self)
										local player = _(self.gui.player)
										self.state = player:setting("enableInventoryCleanupHotkey")
										self.parent.frame_caption.enabled = self.state
									end,
									onChanged = function(event)
										local self = event.element
										self.parent.parent.frame_content.visible = self.state
										self.parent.frame_caption.enabled = self.state

										local player = _(self.gui.player)
										player:changeSetting("enableInventoryCleanupHotkey", self.state)
									end,
								},
							}
						},
						{
							type = "flow",
							name = "frame_content",
							direction = "vertical",
							onCreated = function(self)
								self.visible = _(self.gui.player):setting("enableInventoryCleanupHotkey")
							end,
							children = 
							{
								{
									type = "label",
									caption = "123123123123",
								},
								{
									type = "label",
									caption = "asdasdasdasd",
								},
							}
						},
					}
				},
			}
		},
	}
}

return {this, function(_controller) controller = _controller end}