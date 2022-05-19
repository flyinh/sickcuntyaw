--| SICK CUNT YAW $$$
--| ffi
local ffi = require 'ffi'
pClientEntityList = client.create_interface("client_panorama.dll", "VClientEntityList003") or error("invalid interface", 2)
fnGetClientEntity = vtable_thunk(3, "void*(__thiscall*)(void*, int)")
ffi.cdef('typedef struct { float x; float y; float z; } bbvec3_t;')
local fnGetAttachment = vtable_thunk(84, "bool(__thiscall*)(void*, int, bbvec3_t&)")
local fnGetMuzzleAttachmentIndex1stPerson = vtable_thunk(468, "int(__thiscall*)(void*, void*)")
local fnGetMuzzleAttachmentIndex3stPerson = vtable_thunk(469, "int(__thiscall*)(void*)")
--| END FFI

local tab, container = "aa", "anti-aimbot angles"
local easing = require("gamesense/easing") or error("easing libary required.")
local images = require("gamesense/images") or error("image library required")
local http = require("gamesense/http") or error("http library required")
local aa_funcs = require("gamesense/antiaim_funcs") or error("anti-aim library required")
local aa_config = { "Global", "Stand", "Slow motion", "Moving" , "Air", "Duck T", "Duck CT", "Warmup" }
local rage = {}
local active_idx = 1
local last_anti = 0
local logo_url, logo = "https://media.discordapp.net/attachments/897698279037476925/897727573134573578/unknown.png", nil
local logo_url1, logo1 = "https://media.discordapp.net/attachments/897698279037476925/897728706108338216/9k.png", nil
local logo_url2, logo2 = "https://media.discordapp.net/attachments/897698279037476925/897727614779805766/unknown.png", nil
client.exec("playvol \"survival/money_collect_01.wav\" 1")
local build = "Live"
if entity.get_steam64(entity.get_local_player()) == 329308421 then
	build = "Dev"
end

local state_to_num = {
    ["Global"] = 1,
    ["Stand"] = 2,
    ["Slow motion"] = 3,
    ["Moving"] = 4,
    ["Air"] = 5,
    ["Duck T"] = 6,
    ["Duck CT"] = 7,
    ["Warmup"] = 8,
}

local name_to_num = {
    ["Global"] = 1,
    ["Stand"] = 2,
    ["Slow motion"] = 3,
    ["Manual right"] = 4,
    ["Manual left"] = 5,
    ["Moving"] = 6,
    ["Air"] = 7,
    ["Duck T"] = 8,
    ["Duck CT"] = 9,
    ["On key"] = 10,
}

local ZYZZQUOTES = {
	"Were all gonna make it brah",
	"Everyone has a little zyzz in them",
	"Haters gonna hate!",
	"Go hard mate the gym lifestyle is the best!",
	"My message is to train hard",
}

local vars = {
	pos1 = 0,
	pos2 = 0,
	killtimer = 0,
	dtalpha = 0,
    dtalpha1 = 0,
	fsalpha = 0,
	fsalpha1 = 0,
	target = nil,
	freestand_side = 180,
	text = "nil"
}

local ref = {
    enabled = ui.reference("AA", "Anti-aimbot angles", "Enabled"),
    pitch = ui.reference("AA", "Anti-aimbot angles", "pitch"),
    yawbase = ui.reference("AA", "Anti-aimbot angles", "Yaw base"),
    fakeyawlimit = ui.reference("AA", "anti-aimbot angles", "Fake yaw limit"),
    fsbodyyaw = ui.reference("AA", "anti-aimbot angles", "Freestanding body yaw"),
    edgeyaw = ui.reference("AA", "Anti-aimbot angles", "Edge yaw"),
    maxprocticks = ui.reference("MISC", "Settings", "sv_maxusrcmdprocessticks"),
    fakeduck = ui.reference("RAGE", "Other", "Duck peek assist"),
    safepoint = ui.reference("RAGE", "Aimbot", "Force safe point"),
    forcebaim = ui.reference("RAGE", "Other", "Force body aim"),
    roll = ui.reference("aa", "Anti-aimbot angles", "roll");
    player_list = ui.reference("PLAYERS", "Players", "Player list"),
    reset_all = ui.reference("PLAYERS", "Players", "Reset all"),
    apply_all = ui.reference("PLAYERS", "Adjustments", "Apply to all"),
    load_cfg = ui.reference("Config", "Presets", "Load"),
    fl_limit = ui.reference("AA", "Fake lag", "Limit"),
    dt_limit = ui.reference("RAGE", "Other", "Double tap fake lag limit"),
    dmg = ui.reference("RAGE", "Aimbot", "Minimum damage"),

    --[1] = combobox/checkbox | [2] = slider/hotkey
    rage = { ui.reference("RAGE", "Aimbot", "Enabled") },
    yaw = { ui.reference("AA", "Anti-aimbot angles", "Yaw") },
    quickpeek = { ui.reference("RAGE", "Other", "Quick peek assist") },
    yawjitter = { ui.reference("AA", "Anti-aimbot angles", "Yaw jitter") },
    bodyyaw = { ui.reference("AA", "Anti-aimbot angles", "Body yaw") },
    freestand = { ui.reference("AA", "Anti-aimbot angles", "Freestanding") },
    os = { ui.reference("AA", "Other", "On shot anti-aim") },
    slow = { ui.reference("AA", "Other", "Slow motion") },
    dt = { ui.reference("RAGE", "Other", "Double tap") },
    fakelag = { ui.reference("AA", "Fake lag", "Enabled") },
	alive_thirdperson = { ui.reference("Visuals", "Effects", "Force third person (alive)") }
}

local items = {
    luaenable = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Sickcunt builder'),
    tabselect = ui.new_combobox("AA","Anti-aimbot angles", "Tab selector", "Anti-Aim", "Misc"),
    main_settings = ui.new_multiselect("AA","Anti-aimbot angles", "Anti-Aim Enhancements", "Anti-backstab", "Legit AA on use"),
    aa_condition = ui.new_combobox("AA","Anti-aimbot angles", "Anti-Aim Conditions", aa_config),

    key_edgeyaw = ui.new_hotkey('AA', 'Anti-aimbot angles', 'Edge-yaw'),
    key_roll = ui.new_hotkey('AA', 'Anti-aimbot angles', 'Roll'),
    key_forward = ui.new_hotkey('AA', 'Anti-aimbot angles', 'Manual Forward'),
    key_left = ui.new_hotkey('AA', 'Anti-aimbot angles', 'Manual Left'),
    key_right = ui.new_hotkey('AA', 'Anti-aimbot angles', 'Manual Right'),

    watermark = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Watermark'),
    spectator = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Spectators'),
    keybind = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Keybinds'),
	visoptions = ui.new_multiselect('AA', 'Anti-aimbot angles', "Visual options", "Crosshair", "Motivational Zyzz")
}

local hk_switches = {
	[true] = {'Default', 'Always On'},
    [false] = {'-', 'On hotkey'}
}

http.get(logo_url, function(s, r)
    if s and r.status == 200 then
        logo = images.load(r.body)
    end  
end)
http.get(logo_url1, function(s, r)
    if s and r.status == 200 then
        logo1 = images.load(r.body)
    end  
end)
http.get(logo_url2, function(s, r)
    if s and r.status == 200 then
        logo2 = images.load(r.body)
    end  
end)

local function vec3_normalise(x, y, z) -- have to call outside of the miscfuncs table
    local len = math.sqrt(x * x + y * y + z * z);
    if len == 0 then
        return 0, 0, 0;
    end

    local r = 1 / len;
    return x * r, y * r, z * r;
end
local function vec3(ax, ay, az, bx, by, bz)
    return ax * bx + ay * by + az * bz;
end

local miscfuncs = { };
miscfuncs = {
	set_og_menu = function(state)
		if state == nil then
			state = true
		end
		ui.set_visible(ref.enabled, state)
		ui.set_visible(ref.pitch, state)
		ui.set_visible(ref.yawbase, state)
		ui.set_visible(ref.yaw[1], state)
		ui.set_visible(ref.yaw[2], state)
		ui.set_visible(ref.yawjitter[1], state)
		ui.set_visible(ref.yawjitter[2], state)
		ui.set_visible(ref.bodyyaw[1], state)
		ui.set_visible(ref.bodyyaw[2], state)
		ui.set_visible(ref.fakeyawlimit, state)
		ui.set_visible(ref.fsbodyyaw, state)
		ui.set_visible(ref.edgeyaw, state)
		ui.set_visible(ref.roll, state)
		ui.set_visible(ref.freestand[1], state)
		ui.set_visible(ref.freestand[2], state)
	end,

	set_lua_menu = function()
		ui.set_visible(items.tabselect, false)
		ui.set_visible(items.watermark, false)
		ui.set_visible(items.spectator, false)
		ui.set_visible(items.keybind, false)
		ui.set_visible(items.main_settings, false)
		ui.set_visible(items.aa_condition, false)
		ui.set_visible(items.key_edgeyaw, false)
		ui.set_visible(items.key_forward, false)
		ui.set_visible(items.key_left, false)
		ui.set_visible(items.key_right, false)
		ui.set_visible(items.key_roll, false)
		if ui.get(items.luaenable) then
			miscfuncs.set_og_menu(false)
			ui.set_visible(items.tabselect, true)
			local select_aa = ui.get(items.tabselect) == "Anti-Aim"
			local select_misc = ui.get(items.tabselect) == "Misc"
			ui.set_visible(items.main_settings, select_main)
			ui.set_visible(items.key_roll, select_main)
			ui.set_visible(items.visoptions, select_misc)
			ui.set_visible(items.aa_condition, select_aa)
		end
	end,

	get_attachment_vector = function(world_model)
		local me = entity.get_local_player()
		local wpn = entity.get_player_weapon(me)
		local model =
			world_model and 
			entity.get_prop(wpn, 'm_hWeaponWorldModel') or
			entity.get_prop(me, 'm_hViewModel[0]')
		if me == nil or wpn == nil then
			return
		end
		local active_weapon = fnGetClientEntity(pClientEntityList, wpn)
		local g_model = fnGetClientEntity(pClientEntityList, model)
		if active_weapon == nil or g_model == nil then
			return { 0, 0, 0 }
		end
		local attachment_vector = ffi.new("bbvec3_t[1]")
		local att_index = world_model and
			fnGetMuzzleAttachmentIndex3stPerson(active_weapon) or
			fnGetMuzzleAttachmentIndex1stPerson(active_weapon, g_model)
		if att_index > 0 and fnGetAttachment(g_model, att_index, attachment_vector[0]) then
			return { attachment_vector[0].x, attachment_vector[0].y, attachment_vector[0].z }
		end
	end,

	contains = function(table, val)
        for i = 1, #table do
            if table[i] == val then
                return true;
            end
        end
        return false;
    end,

	visible = function(reference, state)
        if type(reference) == "table" then
            for i,v in pairs(reference) do
                if type(v) == "table" then
                    for j = 1, #v do
                        ui.set_visible(v[j], state);
                    end
                else
                    ui.set_visible(v, state);
                end
            end
        else
            ui.set_visible(reference, state);
        end
    end,

	extrapolate_position = function(xpos,ypos,zpos,ticks,player)
        local x,y,z = entity.get_prop(player, "m_vecVelocity")
        for i=0, ticks do
            xpos =  xpos + (x*globals.tickinterval())
            ypos =  ypos + (y*globals.tickinterval())
            zpos =  zpos + (z*globals.tickinterval())
        end
        return xpos,ypos,zpos
    end,

	CalcAngle = function(localplayerxpos, localplayerypos, enemyxpos, enemyypos)
        local relativeyaw = math.atan( (localplayerypos - enemyypos) / (localplayerxpos - enemyxpos) )
        return relativeyaw * 180 / math.pi
    end,

    Angle_Vector = function(angle_x, angle_y)
        local sp, sy, cp, cy = nil
        sy = math.sin(math.rad(angle_y));
        cy = math.cos(math.rad(angle_y));
        sp = math.sin(math.rad(angle_x));
        cp = math.cos(math.rad(angle_x));
        return cp * cy, cp * sy, -sp;
    end,

	angle_to_vec = function(pitch, yaw)
        local p, y = math.rad(pitch), math.rad(yaw);
        local sp, cp, sy, cy = math.sin(p), math.cos(p), math.sin(y), math.cos(y);
        return cp * cy, cp * sy, -sp;
    end,

	get_fov = function(ent, vx, vy, vz, lx, ly, lz)
        local ox, oy, oz = entity.get_prop(ent, "m_vecOrigin");
        if ox == nil then
            return -1;
        end
    
        local dx, dy, dz = vec3_normalise(ox - lx, oy - ly, oz - lz);
        return vec3(dx, dy, dz, vx, vy, vz);
    end,

	render_outlined_rounded_rectangle = function(x, y, w, h, r, g, b, a, radius, thickness)
        y = y + radius
        local data_circle = {
            {x + radius, y, 180},
            {x + w - radius, y, 270},
            {x + radius, y + h - radius * 2, 90},
            {x + w - radius, y + h - radius * 2, 0},
        }
    
        local data = {
            {x + radius, y - radius, w - radius * 2, thickness},
            {x + radius, y + h - radius - thickness, w - radius * 2, thickness},
            {x, y, thickness, h - radius * 2},
            {x + w - thickness, y, thickness, h - radius * 2},
        }
    
        for _, data in next, data_circle do
            renderer.circle_outline(data[1], data[2], r, g, b, a, radius, data[3], 0.25, thickness)
        end
    
        for _, data in next, data do
            renderer.rectangle(data[1], data[2], data[3], data[4], r, g, b, a)
        end
    end,

	get_velocity = function(ent)
        local x, y, z = entity.get_prop(ent, "m_vecVelocity")
        if x == nil then return end
        return math.sqrt(x * x + y * y + z * z);
    end,
}

for i=1, #aa_config do
    rage[i] = {
        c_enabled = ui.new_checkbox("aa", "anti-aimbot angles", "Enable " .. aa_config[i] .. " config"),
        c_pitch = ui.new_combobox("aa", "anti-aimbot angles", "Pitch", {"Off","Default","Up", "Down", "Minimal", "Random"}),
        c_yawbase = ui.new_combobox("aa", "anti-aimbot angles", "Yaw base", {"Local view","At targets"}),
        c_yaw = ui.new_combobox("aa", "anti-aimbot angles", "Yaw", {"Off", "180", "Spin", "Static", "180z", "Crosshair"}),
        c_yaw_sli = ui.new_slider("aa", "anti-aimbot angles", "\n", -180, 180, 0, true, "°", 1),

        c_jitter = ui.new_combobox("aa", "anti-aimbot angles", "Yaw jitter", {"Off","Offset","Center","Random"}),
        c_jitter_sli = ui.new_slider("aa", "anti-aimbot angles", "\n", -180, 180, 0, true, "°", 1),
        c_body = ui.new_combobox("aa", "anti-aimbot angles", "Body yaw", {"Off","Opposite","Jitter","Static"}),
        c_body_sli = ui.new_slider("aa", "anti-aimbot angles", "\n", -180, 180, 0, true, "°", 1),
        c_free_b_yaw = ui.new_checkbox("aa", "anti-aimbot angles", "Freestanding body yaw"),
        c_lby_limit = ui.new_slider("aa", "anti-aimbot angles", "Fake yaw limit", 0, 60, 60, true, "°", 1),
        c_edge_yaw = ui.new_checkbox("aa", "anti-aimbot angles", "Edge yaw"),
        c_roll = ui.new_slider("AA", "anti-aimbot angles", "Roll AA", -50, 50, 0, true, "°", 1),
        adv_combo = ui.new_multiselect("AA", "Anti-aimbot angles", "Extras", {"Side based yaw"}),
        l_limit = ui.new_slider("AA", "Anti-aimbot angles", "Left yaw", -180, 180, 0, true, "°"),
        r_limit = ui.new_slider("AA", "Anti-aimbot angles", "Right yaw", -180, 180, 0, true, "°"),
		lb_limit = ui.new_slider("AA", "Anti-aimbot angles", "Left body yaw", -180, 180, 0, true, "°"),
        rb_limit = ui.new_slider("AA", "Anti-aimbot angles", "Right body yaw", -180, 180, 0, true, "°")
    }
end
local enable_anti       = ui.reference("aa", "anti-aimbot angles", "Enabled")
local pitch             = ui.reference("aa", "anti-aimbot angles", "Pitch")
local yawbase           = ui.reference("aa", "anti-aimbot angles", "Yaw base")
local yaw , yaw_sli     = ui.reference("aa", "anti-aimbot angles", "Yaw")
local jitter,jitter_sli = ui.reference("aa", "anti-aimbot angles", "Yaw jitter")
local body ,body_sli    = ui.reference("aa", "anti-aimbot angles", "Body yaw")
local lby_limit         = ui.reference("aa", "anti-aimbot angles", "Fake yaw limit")
local edge              = ui.reference("aa", "anti-aimbot angles", "Edge yaw")
local free,free_key     = ui.reference("aa", "anti-aimbot angles", "Freestanding")

local function get_mode()
	local xxx = "Other"
	local lp = entity.get_local_player()
	local vx,vy,vz = entity.get_prop(lp, "m_vecVelocity")
	local velocity = math.sqrt(vx*vx + vy*vy + vz*vz)
	local slowwalk_key = ui.get(ref.slow[1]) and ui.get(ref.slow[2])
	local flags = entity.get_prop(entity.get_local_player(), "m_fFlags");
	local teamnum = entity.get_prop(lp, "m_iTeamNum")
	local ct = teamnum == 3
	local t = teamnum == 2
	if velocity < 5 then
		xxx = "Stand"
	end
	if bit.band(flags, 4) == 4 then
		if ct then
			xxx = "Duck CT"
		elseif t then
			xxx = "Duck T"
		end
	end
	if velocity > 5 then
		xxx = "Moving"
	end
	if bit.band(flags, 1) == 0 then
		xxx = "Air"
	end
	if velocity > 1.01 and slowwalk_key then
		xxx = "Slow motion"
	end
	return xxx
end
local antiaim = { };
antiaim = {
	handle_antiaim_builder = function(cmd)
		local localplayer = entity.get_local_player()
		if localplayer == nil or not entity.is_alive(localplayer) then
			return
		end
		local state = get_mode()
		local state_num = state_to_num[state]
		desync_type = entity.get_prop( entity.get_local_player( ), "m_flPoseParameter", 11 )*120-60
		local state_enabled = ui.get(rage[state_num].c_enabled)

		if state_enabled then
			ui.set(ref.pitch, ui.get(rage[state_num].c_pitch))
			ui.set(ref.yawbase, ui.get(rage[state_num].c_yawbase))
			ui.set(ref.yaw[1], ui.get(rage[state_num].c_yaw))
			ui.set(ref.yawjitter[1], ui.get(rage[state_num].c_jitter))
			ui.set(ref.yawjitter[2], ui.get(rage[state_num].c_jitter_sli))
			ui.set(ref.bodyyaw[1], ui.get(rage[state_num].c_body))
			ui.set(ref.fsbodyyaw, ui.get(rage[state_num].c_free_b_yaw))
			ui.set(ref.fakeyawlimit, ui.get(rage[state_num].c_lby_limit))
			ui.set(ref.edgeyaw, ui.get(rage[state_num].c_edge_yaw))
			cmd.roll = ui.get(rage[state_num].c_roll)
			if miscfuncs.contains(ui.get(rage[state_num].adv_combo), "Side based yaw") then
				if desync_type > 0 then
					--left
					ui.set(ref.yaw[2], ui.get(rage[state_num].l_limit))
					ui.set(ref.bodyyaw[2], ui.get(rage[state_num].lb_limit))
				elseif desync_type < 0 then
					--right
					ui.set(ref.yaw[2], ui.get(rage[state_num].r_limit))
					ui.set(ref.bodyyaw[2], ui.get(rage[state_num].rb_limit))
				end
			else
				ui.set(ref.bodyyaw[2], ui.get(rage[state_num].c_body_sli))
				ui.set(ref.yaw[2], ui.get(rage[state_num].c_yaw_sli))
			end
		else
			-- global is 1, check line 183
			ui.set(ref.pitch, ui.get(rage[1].c_pitch))
			ui.set(ref.yawbase, ui.get(rage[1].c_yawbase))
			ui.set(ref.yaw[1], ui.get(rage[1].c_yaw))
			ui.set(ref.yaw[2], ui.get(rage[1].c_yaw_sli))
			ui.set(ref.yawjitter[1], ui.get(rage[1].c_jitter))
			ui.set(ref.yawjitter[2], ui.get(rage[1].c_jitter_sli))
			ui.set(ref.bodyyaw[1], ui.get(rage[1].c_body))
			ui.set(ref.bodyyaw[2], ui.get(rage[1].c_body_sli))
			ui.set(ref.fsbodyyaw, ui.get(rage[1].c_free_b_yaw))
			ui.set(ref.fakeyawlimit, ui.get(rage[1].c_lby_limit))
			ui.set(ref.edgeyaw, ui.get(rage[1].c_edge_yaw))
		end
		ui.set(ref.enabled, true)
	end,
}

local function handle_menu()
    local enabled = ui.get(items.luaenable) and ui.get(items.tabselect) == "Anti-Aim"
    ui.set_visible(items.aa_condition, enabled)

    for i=1, #aa_config do
        local show = ui.get(items.aa_condition) == aa_config[i] and enabled
        ui.set_visible(rage[i].c_enabled, show and i > 1)
        ui.set_visible(rage[i].c_pitch,show)
        ui.set_visible(rage[i].c_yawbase,show)
        ui.set_visible(rage[i].c_yaw,show)
        ui.set_visible(rage[i].c_yaw_sli,show)
        ui.set_visible(rage[i].c_jitter,show)
        ui.set_visible(rage[i].c_jitter_sli,show)
        ui.set_visible(rage[i].c_body,show)
        ui.set_visible(rage[i].c_body_sli,show)
        ui.set_visible(rage[i].c_free_b_yaw, show)
        ui.set_visible(rage[i].c_lby_limit,show)
        ui.set_visible(rage[i].c_edge_yaw, show)
        ui.set_visible(rage[i].c_roll, show)
        ui.set_visible(rage[i].adv_combo, show )
        ui.set_visible(rage[i].l_limit, show and miscfuncs.contains(ui.get(rage[i].adv_combo), "Side based yaw"))
        ui.set_visible(rage[i].r_limit, show and miscfuncs.contains(ui.get(rage[i].adv_combo), "Side based yaw"))
		ui.set_visible(rage[i].lb_limit, show and miscfuncs.contains(ui.get(rage[i].adv_combo), "Side based yaw"))
        ui.set_visible(rage[i].rb_limit, show and miscfuncs.contains(ui.get(rage[i].adv_combo), "Side based yaw"))
    end
end
handle_menu()

local visuals = { };
visuals = {
	Zyzzhud = function()
		if not miscfuncs.contains(ui.get(items.visoptions),"Motivational Zyzz") then return end
		local lx, ly, lz = entity.hitbox_position(entity.get_local_player(), 14)
 		local w, h = renderer.measure_text(nil, string.format("  %s  ", vars.text))
		pos = miscfuncs.get_attachment_vector(false)
		if pos == nil and not ui.get(ref.alive_thirdperson[2]) then
			return
		elseif pos == nil or ui.get(ref.alive_thirdperson[2]) then 
			x, y, z = renderer.world_to_screen(lx, ly, lz)
		else
			x, y, z = renderer.world_to_screen(pos[1], pos[2], pos[3])
		end
		if x == nil or y == nil then return end
		vars.pos1 = easing.quint_in(1, vars.pos1, x - vars.pos1, 2)
		vars.pos2 = easing.quint_in(1, vars.pos2, y - vars.pos2, 2)
		if logo ~= nil and logo1 ~= nil and logo2 ~= nil then
			if not entity.is_alive(entity.get_local_player()) then
				logo1:draw(vars.pos1 - 150, vars.pos2 - 150, 100, 100, 255, 255, 255, 255)
			elseif vars.killtimer > globals.curtime() then
				miscfuncs.render_outlined_rounded_rectangle(vars.pos1 - 165 - w, vars.pos2 - 150, w, 30, 15, 15, 15, 255, 15,30)
				renderer.text(vars.pos1 - 159 - w, vars.pos2 - 142, 255, 255, 255, 225, "l", nil, vars.text)
				logo2:draw(vars.pos1 - 150, vars.pos2 - 150, 100, 100, 255, 255, 255, 255)
			else
				logo:draw(vars.pos1 - 150, vars.pos2 - 150, 100, 100, 255, 255, 255, 255)
			end
			renderer.line(x, y, vars.pos1 - 100, vars.pos2 - 50, 255, 255, 255, 115)
		end
	end,

	crosshair = function()
		if not miscfuncs.contains(ui.get(items.visoptions),"Crosshair") then return end
		local w, h = client.screen_size()
		local added = 15
		local charge = aa_funcs.get_double_tap()
		local dtcolor = { 0,0,0 }

		vars.dtalpha1 = ui.get(ref.dt[2]) and 255 or 0
		vars.fsalpha1 = ui.get(ref.freestand[2]) and 255 or 0
		vars.dtalpha = easing.quint_in(1, vars.dtalpha, vars.dtalpha1 - vars.dtalpha, 1.5)
		vars.fsalpha = easing.quint_in(1, vars.fsalpha, vars.fsalpha1 - vars.fsalpha, 1.5)

		if charge then
			dtcolor = { 115, 215, 115 }
		else
			dtcolor = { 215, 115, 115 }
		end

		renderer.text(w/2, h/2 + added, 255, 255, 255, 255, "c-", nil, "SICKCUNT")
		added = added + 480 + vars.dtalpha

		renderer.text(w/2, h/2 + (added / 31.875), dtcolor[1], dtcolor[2], dtcolor[3], vars.dtalpha, "c-", nil, "DT")
		added = added + vars.fsalpha

		renderer.text(w/2, h/2 + (added / 31.875), 255, 255, 255, vars.fsalpha, "c-", nil, "FREESTAND")--]]
	end,
}

client.set_event_callback("paint_ui", function()
    handle_menu()
    miscfuncs.set_og_menu()
    miscfuncs.set_lua_menu()
end)
client.set_event_callback("setup_command", function(cmd)
	antiaim.handle_antiaim_builder(cmd)
end)
client.set_event_callback("paint", function()
	visuals.Zyzzhud()
	visuals.crosshair()
end)
client.set_event_callback("player_death", function(e)
	if client.userid_to_entindex(e.attacker) == entity.get_local_player() then
		vars.text = ZYZZQUOTES[client.random_int(1, #ZYZZQUOTES)]
		vars.killtimer = globals.curtime() + 2
	end
end)
client.set_event_callback("shutdown", function()
    miscfuncs.set_og_menu(true)
end)
local function init_callbacks()
    ui.set_callback(items.luaenable, handle_menu)
    ui.set_callback(items.aa_condition, handle_menu)

    for i=1, #aa_config do
       
        ui.set_callback(rage[i].c_yaw, handle_menu)
        ui.set_callback(rage[i].c_jitter, handle_menu)
        ui.set_callback(rage[i].c_body, handle_menu)
    end
end
init_callbacks()
