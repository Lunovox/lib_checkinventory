
if type(libCheckInventory)=="nil" then
	libCheckInventory = {}
end
libCheckInventory.translate = rawget(_G, "intllib") and intllib.Getter() or function(s) return s end

minetest.register_privilege("checkinventory",  {
	description=libCheckInventory.translate("Lets you watch another player's inventory!"), 
	give_to_singleplayer=false,
})
minetest.register_privilege("changeinventory",  {
	description=libCheckInventory.translate("Lets you control another player's inventory!"), 
	give_to_singleplayer=false,
})

libCheckInventory.doCheckPlayerInventary = function(playername, param)
	local targetname = string.match(param, "^([^ ]+)$")
	if type(targetname)=="string" and targetname~="" then
		local playertarget = minetest.get_player_by_name(targetname)
		if playertarget then --verifica se o player esta onlyne
			--local invTarget = playertarget:get_inventory()
			local invTarget = minetest.get_inventory({type="player", name=targetname})

			--local invDetached = minetest.create_detached_inventory_raw(targetname)
			local invDetached = minetest.create_detached_inventory(targetname,{
				allow_move = function(inv, from_list, from_index, to_list, to_index, count, player) 
					if not minetest.get_player_privs(playername).changeinventory then 
						minetest.chat_send_player(playername, 
							core.get_color_escape_sequence("#FFFFFF").."["..
							core.get_color_escape_sequence("#FF0000")..
							"LIB_CHECKINVENTORY:ERRO"..
							core.get_color_escape_sequence("#FFFFFF")..
							"] "..libCheckInventory.translate("You do not have the 'changeinventory' privilege to move items.")
						)
						return 0 
					end
					return count 
				end,
				allow_put = function(inv, listname, index, stack, player)
					if not minetest.get_player_privs(playername).changeinventory then 
						minetest.chat_send_player(playername, 
							core.get_color_escape_sequence("#FFFFFF").."["..
							core.get_color_escape_sequence("#FF0000")..
							"LIB_CHECKINVENTORY:ERRO"..
							core.get_color_escape_sequence("#FFFFFF")..
							"] "..libCheckInventory.translate("You do not have the 'changeinventory' privilege to place items.")
						)
						return 0 
					end
					 return stack:get_count() 
				end,
				allow_take = function(inv, listname, index, stack, player)
					if not minetest.get_player_privs(playername).changeinventory then 
						minetest.chat_send_player(playername, 
							core.get_color_escape_sequence("#FFFFFF").."["..
							core.get_color_escape_sequence("#FF0000")..
							"LIB_CHECKINVENTORY:ERRO"..
							core.get_color_escape_sequence("#FFFFFF")..
							"] "..libCheckInventory.translate("You do not have the 'changeinventory' privilege to remove items.")
						)
						return 0 
					end
					return stack:get_count()  
				end,
				on_move = function(inv, from_list, from_index, to_list, to_index, count, player) 
					--print("from_list="..from_list.."count="..count)
					invTarget:set_list(from_list, inv:get_list(from_list))
					if minetest.get_modpath("lib_savelogs") and libSaveLogs~=nil then
						libSaveLogs.addLog(
							"<lib_checkinventory> "..
							libCheckInventory.translate("The player '%s' has the items movimented in inventory per '%s'. %s"):
							format(
								targetname, playername, 
								minetest.pos_to_string(libSaveLogs.getPosResumed(minetest.get_player_by_name(playername):getpos()))
							)
						)
						libSaveLogs.doSave()
					end
				end,
				on_put = function(inv, listname, index, stack, player) 
					--print("listname="..listname.."stack:get_count()="..stack:get_count())
					invTarget:set_list(listname, inv:get_list(listname))
					if minetest.get_modpath("lib_savelogs") and libSaveLogs~=nil then
						libSaveLogs.addLog(
							"<lib_checkinventory> "..
							libCheckInventory.translate("The player '%s' has placed %02d x '%s' in inventory per '%s'. %s"):
							format(
								targetname, stack:get_count(), stack:get_name(), playername, 
								minetest.pos_to_string(libSaveLogs.getPosResumed(minetest.get_player_by_name(playername):getpos()))
							)
						)
						libSaveLogs.doSave()
					end
				end,
				on_take = function(inv, listname, index, stack, player) 
					--print("listname="..listname.."stack:get_count()="..stack:get_count())
					invTarget:set_list(listname, inv:get_list(listname))
					if minetest.get_modpath("lib_savelogs") and libSaveLogs~=nil then
						libSaveLogs.addLog(
							"<lib_checkinventory> "..
							libCheckInventory.translate("The player '%s' has removed %02d x '%s' in inventory per '%s'. %s"):
							format(
								targetname, stack:get_count(), stack:get_name(), playername, 
								minetest.pos_to_string(libSaveLogs.getPosResumed(minetest.get_player_by_name(playername):getpos()))
							)
						)
						libSaveLogs.doSave()
					end
				end,
			})
			--print("################### invTarget.name="..dump(invTarget.name))
			invDetached:set_size("main", invTarget:get_size("main"))
			invDetached:set_list("main", invTarget:get_list("main"))
			minetest.show_formspec(playername,	"frmMain",
				"size[8,9.5]"
				--"size[8,4.5]"
				.."bgcolor[#636D76FF;false]"
				
				.."label[0,0;"..libCheckInventory.translate("Inventory of '%s'"):format(targetname).."]"
				--.."list[detached:safe_"..playername .. ";safe;0,0;8,4;]" -- <= ATENCAO: Nao pode esquecer o prefixo 'detached:xxxxxxx'
				--.."list[player:"..targetname..";main;0,0.5;8,4;]"
				.."list[detached:"..targetname..";main;0,0.5;8,4;]"
				
				.."label[0,5;"..libCheckInventory.translate("Inventory of '%s'"):format(playername).."]"
				--.."list[current_player;main;0,5;8,4;]"
				.."list[player:"..playername..";main;0,5.5;8,4;]"
				
				.."listring[detached:"..targetname..";main]"
				.."listring[player:"..playername..";main]"
			)
			return true
		else
			minetest.chat_send_player(playername, core.get_color_escape_sequence("#FFFFFF").."["..
				core.get_color_escape_sequence("#FF0000")..
				"LIB_CHECKINVENTORY:ERRO"..
				core.get_color_escape_sequence("#FFFFFF")..
				"] "..libCheckInventory.translate("The player '%s' is offline!"):format(targetname)
			)
			if minetest.get_modpath("lib_savelogs") and libSaveLogs~=nil then
				libSaveLogs.addLog(
					"<lib_checkinventory> "..
					libCheckInventory.translate("The player '%s' tried to see the '%s' inventory that was offline. %s"):
					format(
						playername, targetname, 
						minetest.pos_to_string(libSaveLogs.getPosResumed(minetest.get_player_by_name(playername):getpos()))
					)
				)
				libSaveLogs.doSave()
			end
		end
	else
		minetest.chat_send_player(
			playername, 
			core.get_color_escape_sequence("#FFFFFF").."["..
			core.get_color_escape_sequence("#FF0000")..
			"LIB_CHECKINVENTORY:ERRO"..
			core.get_color_escape_sequence("#FFFFFF")..
			"] "..core.get_color_escape_sequence("#00FF00")..
			"/checkinventory <PlayerName> "..
			core.get_color_escape_sequence("#FFFFFF")..": "..
			libCheckInventory.translate("Checks the inventory of the target player.")
		)
	end
	return false
end

minetest.register_chatcommand("ci", {
	params = "<PlayerName>",
	description = libCheckInventory.translate("Checks the inventory of the target player."),
	privs = {checkinventory=true},
	func = function(playername, param)
		return libCheckInventory.doCheckPlayerInventary(playername, param)
	end,
})

minetest.register_chatcommand("checkinventory", {
	params = "<PlayerName>",
	description = libCheckInventory.translate("Checks the inventory of the target player."),
	privs = {checkinventory=true},
	func = function(playername, param)
		return libCheckInventory.doCheckPlayerInventary(playername, param)
	end,
})

--##########################################################################################################


