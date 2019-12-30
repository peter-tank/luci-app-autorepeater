-- Copyright (C) 2017 peter-tank
-- Licensed to the public under the GNU General Public License v3.

module("luci.controller.autorepeater", package.seeall)

function index()
	local page

--	page = node("admin", "services")
--	page.target = firstchild()
--	page.title  = _("AutoRepeater")
--	page.order  = 50
--	page.index  = true

	local uci = require("luci.model.uci").cursor()
	local nxfs	= require "nixio.fs"
	local has_wifi = false

	uci:foreach("wireless", "wifi-device",
		function(s)
			has_wifi = true
			return false
		end)
	-- no config create an empty one
	if not nxfs.access("/etc/config/autorepeater") then
		nxfs.writefile("/etc/config/autorepeater", "")
	end

	if has_wifi then
		page = entry({"admin", "services", "wifi_dev"}, post("wifi_dev"), nil)
		page.leaf = true
		page = entry({"admin", "services", "sta_add"}, post("sta_add"), nil)
		page.leaf = true

		page = entry( {"admin", "services", "logread"}, call("logread"), nil)
		page.leaf = true
		page = entry( {"admin", "services", "bthandler"}, call("bthandler"), nil)
		page.leaf = true
		page = entry( {"admin", "services", "connect"}, call("connect"), nil)
		page.leaf = true
		page = entry( {"admin", "services", "overview_status"}, call("overview_status"), nil)
		page.leaf = true

		page = entry({"admin", "services", "autorepeater"}, arcombine(template("autorepeater/wifi_overview"), cbi("autorepeater/autorepeater")), _("AutoRepeater"), 1)
		page.leaf = true

		page = entry({"admin", "services", "atrp_post_page"}, post("atrp_post_page"), nil)
		page.leaf = true

		page = entry( {"admin", "services", "autorepeater-hints"}, cbi("autorepeater/hints"), nil )
		page.leaf = true
		page = entry( {"admin", "services", "autorepeater-global"}, cbi("autorepeater/global"), nil )
		page.leaf = true
		page = entry({"admin", "services", "autorepeater-logview"}, cbi("autorepeater/logview", {hideapplybtn=true, hidesavebtn=true, hideresetbtn=true}), nil )
		page.leaf = true

		page = entry( {"admin", "services", "autorepeater-overview"}, cbi("autorepeater/overview"), nil )
		page.leaf = true
		page = entry( {"admin", "services", "autorepeater-stations"}, cbi("autorepeater/stations"), nil )
		page.leaf = true
		page = entry( {"admin", "services", "autorepeater-pnpmaps"}, cbi("autorepeater/pnpmaps"), nil )
		page.leaf = true

	end

end

function wifi_dev()
	local tpl  = require "luci.template"
	local http = require "luci.http"
	local dev  = http.formvalue("device")
	local ssid = http.formvalue("join")

	if dev and ssid then
		local cancel = (http.formvalue("cancel") or http.formvalue("cbi.cancel"))
		if not cancel then
			local cbi = require "luci.cbi"
			local map = cbi.load("autorepeater/wifi_dev")[1]

			if map:parse() ~= cbi.FORM_DONE then
				tpl.render("header")
				map:render()
				tpl.render("footer")
			end

			return
		end
	end

	tpl.render("autorepeater/wifi_dev")
end

function sta_add()
	local dev = luci.http.formvalue("device")
	local ntm = require "luci.model.network".init()

	local sta = {mode="sta", network="wan", disassoc_low_ack="0", ssid="station to join", encryption="none"}
	dev = dev and ntm:get_wifidev(dev)

	if dev then
		local net = dev:add_wifinet(sta)
--[[		local net = dev:add_wifinet({
			mode       = "sta",
			network       = "wan",
			disassoc_low_ack = "0",
			ssid       = "station to join",
			encryption = "none"
		})
]]
--		ntm:save("wireless")
		ntm:commit("wireless")
		luci.http.redirect(luci.dispatcher.build_url("admin/services/autorepeater"))
	end
end

function atrp_post_page()
	local tpl  = require "luci.template"
	local http = require "luci.http"
	local cbiname  = http.formvalue("cbiname")
	local tplname  = http.formvalue("tplname")
	local isec = http.formvalue("isec")

	if cbiname then
		if tplname == "" then
			luci.http.redirect(luci.dispatcher.build_url("admin/services/autorepeater-" .. cbiname), isec)
		else
		local cancel = (http.formvalue("cancel") or http.formvalue("cbi.cancel"))
			if not cancel then
				local cbi = require "luci.cbi"
				local map = cbi.load("autorepeater/" .. cbiname)[1]
--[[
				if map:parse() ~= cbi.FORM_DONE then
					tpl.render("header")
					map:render()
					tpl.render("footer")
				end
				return
]]
				tpl.render(tplname)
			end
		end
	else
		luci.http.redirect(luci.dispatcher.build_url("admin/services/autorepeater"))
	end
end

-- called by XHR.get from logview.htm
function logread(lfile)
	-- read application settings
	local NXFS = require "nixio.fs"
	local HTTP = require "luci.http"
	local lfile = HTTP.formvalue("lfile")
	local ldata={}
	ldata[#ldata+1] = NXFS.readfile(lfile) or "_nofile_"
	if ldata[1] == "" then
		ldata[1] = "_nodata_"
	end
	HTTP.prepare_content("application/json")
	HTTP.write_json(ldata)
end

-- called by XHR.get from global_buttons.htm
function bthandler(button)
	-- read application settings
	local UCI = require("luci.model.uci").cursor()
	local HTTP = require "luci.http"
	local handler = "_skiped_"
	if button then
		handler = "_nosection_"
		local type = UCI:get("system", button) or ""
		if type == "button" then
		handler = UCI:get("system", button, "handler") or "_nohandler_"
		end
	end
	UCI:unload("system")
	HTTP.write(handler)
end

function connect()
end

-- called by XHR.get from overview_updater.htm
function overview_status(sfile)
	-- read application settings
	local NXFS = require "nixio.fs"
	local HTTP = require "luci.http"
	local sfile = HTTP.formvalue("sfile")
	local sdata=""
	sdata = NXFS.readfile(sfile) or "{}"
	HTTP.prepare_content("application/json")
	--HTTP.write_json(sdata)
	HTTP.write(sdata)
end