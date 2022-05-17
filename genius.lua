--| SICK CUNT YAW $$$
--| begin ffi
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
local antiaim_lib = require("gamesense/antiaim_funcs") or error("anti-aim library required")
local logo_url, logo = "https://media.discordapp.net/attachments/897698279037476925/897727573134573578/unknown.png", nil
local logo_url1, logo1 = "https://media.discordapp.net/attachments/897698279037476925/897728706108338216/9k.png", nil
local logo_url2, logo2 = "https://media.discordapp.net/attachments/897698279037476925/897727614779805766/unknown.png", nil
client.exec("playvol \"survival/money_collect_01.wav\" 1")

local ZYZZQUOTES = {
	"Were all gonna make it brah",
	"Everyone has a little zyzz in them",
	"Haters gonna hate!",
	"Go hard mate the gym lifestyle is the best!",
	"my message is to train hard",
}

local vars = {
	pos1 = 0,
	pos2 = 0,
	deathtimer = 0,
	killtimer = 0,
	dtalpha = 0,
    dtalpha1 = 0,
	fsalpha = 0,
	fsalpha1 = 0,
	target = nil,
	freestand_side = 180,
	text = "nil"
}

local refs = {
	antiaim = {
        enabled = { ui.reference("AA", "Anti-aimbot angles", "Enabled") },
        pitch = ui.reference("AA", "Anti-aimbot angles", "Pitch"),
        yaw = { ui.reference("AA", "Anti-aimbot angles", "Yaw") },
        yaw_base = ui.reference("AA", "Anti-aimbot angles", "Yaw Base"),
        jitter = { ui.reference("AA", "Anti-aimbot angles", "Yaw jitter") },
        body_yaw = { ui.reference("AA", "Anti-aimbot angles", "Body yaw") },
        fs = { ui.reference("AA", "Anti-aimbot angles", "Freestanding")},
        fs_body_yaw = ui.reference("AA", "Anti-aimbot angles", "Freestanding body yaw"),
        fake_limit = ui.reference("AA", "Anti-aimbot angles", "Fake yaw limit"),
        edge = ui.reference("AA", "Anti-aimbot angles", "Edge yaw"),
        roll = ui.reference("AA", "Anti-aimbot angles", "Roll"),
    },
	dt = {ui.reference("RAGE", "Other", "Double tap")},
	alive_thirdperson = {ui.reference("VISUALS", "Effects", "Force third person (alive)")},
	freestanding = {ui.reference("AA", "Anti-aimbot angles", "Freestanding")}
}

local elements = {
	tab = ui.new_combobox(tab, container, "[Sick cunt] Tab", "Anti-aim", "Visuals"),

	aatab = {
		freestanding_hk = ui.new_hotkey(tab, container, 'Freestanding', false),
	},

	visualstab = {
		indoptions = ui.new_multiselect(tab, container, "Visual options", "Crosshair", "Motivational Zyzz"),
	},
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
}

local antiaim = { };
antiaim = {
	handlefreestand = function()
		local state = ui.get(elements.aatab.freestanding_hk)
		for k, v in pairs(refs.freestanding) do
			ui.set(v, hk_switches[state][k])
		end
	end,

	getbesttarget = function()
        local ent = entity.get_local_player();
        if ent == nil then return end
        local lx, ly, lz = entity.get_prop(ent, "m_vecOrigin");

        if lx == nil then return end
        
        local players = entity.get_players(true);
        local pitch, yaw = client.camera_angles();
        local vx, vy, vz = miscfuncs.angle_to_vec(pitch, yaw);
        
        local closest_fov_cos = -1;
        vars.target = nil;
        for i = 1, #players do
            local idx = players[i];
            if entity.is_alive(idx) then
                local fov_cos = miscfuncs.get_fov(idx, vx, vy, vz, lx, ly, lz);
                if fov_cos > closest_fov_cos then
                    closest_fov_cos = fov_cos;
                    vars.target = idx;
                end
            end
        end
    end,

	run = function()
		if entity.is_dormant(vars.target) then 
            ui.set(refs.antiaim.jitter[1], "off");
            ui.set(refs.antiaim.body_yaw[1], "static");
            ui.set(refs.antiaim.fake_limit, 60);
            ui.set(refs.antiaim.jitter[2], 0);
            ui.set(refs.antiaim.body_yaw[2], vars.freestand_side);
            ui.set(refs.antiaim.yaw[2], 0);
        return end

        local lx, ly, lz = entity.get_prop(entity.get_local_player(), "m_vecOrigin");
        local enemyx, enemyy, enemyz = entity.get_prop(vars.target, "m_vecOrigin");
        local dododada = miscfuncs.CalcAngle(lx, ly, enemyx, enemyy)
        local dir_x, dir_y, dir_z = miscfuncs.Angle_Vector(0, (dododada - 50))
        local dir_x1, dir_y1, dir_z1 = miscfuncs.Angle_Vector(0, (dododada + 50))
        local end_x = lx + dir_x * 55
        local end_y = ly + dir_y * 55
        local end_z = lz + 80	
        local end_x1 = lx + dir_x1 * 55
        local end_y1 = ly + dir_y1* 55
        local end_z1 = lz + 80	

		local x1,y1,z1 = miscfuncs.extrapolate_position(enemyx,enemyy,enemyz,18,vars.target)
        local x2,y2,z2 = miscfuncs.extrapolate_position(lx,ly,lz,18,entity.get_local_player())

        local _, freestandleft = client.trace_bullet(vars.target, enemyx, enemyy, enemyz + 65, end_x, end_y, end_z)
        local _, freestandright = client.trace_bullet(vars.target, enemyx, enemyy, enemyz + 65, end_x1, end_y1, end_z1)
        local _, extraptrace = client.trace_bullet(vars.target, x1, y1, z1 + 65, lx, ly, lz + 65)
        local _, extraptracelocal = client.trace_bullet(vars.target, enemyx, enemyy, enemyz + 65, x2, y2, z2 + 65)

		if freestandleft > freestandright then
			vars.freestand_side = 180
		elseif freestandleft < freestandright then
			vars.freestand_side = -180
		end

		if extraptrace > 0 then
			ui.set(refs.antiaim.jitter[1], "off");
			ui.set(refs.antiaim.body_yaw[1], "static");
			ui.set(refs.antiaim.fake_limit, 60);
			ui.set(refs.antiaim.jitter[2], 0);
			ui.set(refs.antiaim.body_yaw[2], -vars.freestand_side);
			ui.set(refs.antiaim.yaw[2], 0);
		elseif extraptracelocal > 0 then
			ui.set(refs.antiaim.jitter[1], "off");
			ui.set(refs.antiaim.body_yaw[1], "jitter");
			ui.set(refs.antiaim.fake_limit, 60);
			ui.set(refs.antiaim.jitter[2], 0);
			ui.set(refs.antiaim.body_yaw[2], 0);
			ui.set(refs.antiaim.yaw[2], 0);
		else
			ui.set(refs.antiaim.jitter[1], "off");
			ui.set(refs.antiaim.body_yaw[1], "static");
			ui.set(refs.antiaim.fake_limit, 60);
			ui.set(refs.antiaim.jitter[2], 0);
			ui.set(refs.antiaim.body_yaw[2], vars.freestand_side);
			ui.set(refs.antiaim.yaw[2], 0);
		end
	end,
}

local visuals = { };
visuals = {
	Zyzzhud = function()
		if not miscfuncs.contains(ui.get(elements.visualstab.indoptions),"Motivational Zyzz") then return end
		local lx, ly, lz = entity.hitbox_position(entity.get_local_player(), 14)
		local w, h = renderer.measure_text(nil, string.format("  %s  ", vars.text))
		pos = miscfuncs.get_attachment_vector(false)
		if pos == nil and not ui.get(refs.alive_thirdperson[2]) then
			return
		elseif pos == nil or ui.get(refs.alive_thirdperson[2]) then 
			x, y, z = renderer.world_to_screen(lx, ly, lz)
		else
			x, y, z = renderer.world_to_screen(pos[1], pos[2], pos[3])
		end
		vars.pos1 = easing.quint_in(1, vars.pos1, x - vars.pos1, 2)
		vars.pos2 = easing.quint_in(1, vars.pos2, y - vars.pos2, 2)
		if logo ~= nil and logo1 ~= nil and logo2 ~= nil then
			if vars.deathtimer > globals.curtime() then
				logo1:draw(vars.pos1 - 150, vars.pos2 - 150, 100, 100, 255, 255, 255, 255)
			elseif vars.killtimer > globals.curtime() then
				logo2:draw(vars.pos1 - 150, vars.pos2 - 150, 100, 100, 255, 255, 255, 255)
				miscfuncs.render_outlined_rounded_rectangle(vars.pos1 - 165 - w, vars.pos2 - 150, w, 30, 15, 15, 15, 255, 15,30)
				renderer.text(vars.pos1 - 158 - w, vars.pos2 - 143, 255, 255, 255, 225, "l", nil, vars.text)
			else
				logo:draw(vars.pos1 - 150, vars.pos2 - 150, 100, 100, 255, 255, 255, 255)
			end
			renderer.line(x, y, vars.pos1 - 100, vars.pos2 - 50, 255, 255, 255, 115)
		end
	end,

	crosshair = function()
		if not miscfuncs.contains(ui.get(elements.visualstab.indoptions),"Crosshair") then return end
		local w, h = client.screen_size()
		local added = 15
		local charge = antiaim_lib.get_double_tap()
		local dtcolor = { 0,0,0 }

		vars.dtalpha1 = ui.get(refs.dt[2]) and 255 or 0
		vars.fsalpha1 = ui.get(elements.aatab.freestanding_hk) and 255 or 0
		vars.dtalpha = easing.quint_in(1, vars.dtalpha, vars.dtalpha1 - vars.dtalpha, 1.5)
		vars.fsalpha = easing.quint_in(1, vars.fsalpha, vars.fsalpha1 - vars.fsalpha, 1.5)

		if charge then
			dtcolor = { 115, 215, 115 }
		else
			dtcolor = { 215, 115, 115 }
		end

		renderer.text(w/2, h/2 + added, 255, 255, 255, 255, "c-", nil, "SICKCUNT")
		added = added + 8

		renderer.text(w/2, h/2 + added, dtcolor[1], dtcolor[2], dtcolor[3], vars.dtalpha, "c-", nil, "DT")
		added = added + vars.dtalpha / 31.875

		renderer.text(w/2, h/2 + added, 255, 255, 255, vars.fsalpha, "c-", nil, "FREESTAND")
		added = added + vars.fsalpha / 31.875
	end,
}

client.set_event_callback("paint_ui", function()
	miscfuncs.visible(refs.antiaim,false)
	if ui.get(elements.tab) == "Anti-aim" then
		miscfuncs.visible(elements.aatab, true)
		miscfuncs.visible(elements.visualstab, false)
	else
		miscfuncs.visible(elements.aatab, false)
		miscfuncs.visible(elements.visualstab, true)
	end
end)
client.set_event_callback("setup_command", function()
	antiaim.handlefreestand()
	antiaim.getbesttarget()
	antiaim.run()
end)
client.set_event_callback("paint", function()
	visuals.Zyzzhud()
	visuals.crosshair()
end)
client.set_event_callback("player_death", function(e)
	local attacker_entindex = client.userid_to_entindex(e.attacker)
	local victim_entindex   = client.userid_to_entindex(e.userid)
	local local_player 		= entity.get_local_player()
	if attacker_entindex == local_player then
		vars.text = ZYZZQUOTES[client.random_int(-1, #ZYZZQUOTES)]
		vars.killtimer = globals.curtime() + 2
	elseif victim_entindex == local_player then
		vars.text = ZYZZQUOTES[client.random_int(-1, #ZYZZQUOTES)]
		vars.deathtimer = globals.curtime() + 2
	end
end)
