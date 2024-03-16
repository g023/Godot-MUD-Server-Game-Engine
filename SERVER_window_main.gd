extends Node2D

# Developed in: Godot 4.2.1
# License: BSD 3-Clause (https://opensource.org/licenses/BSD-3-Clause)
# Author: g023 - https://github.com/g023
# Version: 0.01a
# Description: A text based MUD (Multi User Dungeon) game in Godot GDScript
# Example starts up servers on ports 3500 and 3600
# use a telnet client to login. No security is implemented yet, so careful about making this public.
# This is a work in progress and is not complete. It may be a good starting point for a text based MUD game.
# implemented:
# - telnet server
# - state handler
# - game loop for handling ai and other game upkeep
# - basic mob loading
# - items that exist in 2 rooms at once (eg 2 way doors)
# - portals
# - right now world is linearly created at start of game using code.
# - everything routed through a params and flags object for ease of saving and loading later (saving/loading not implemented yet)
# - commands: 
# 	- say: tell players something in room
# 	- tell: tell an ingame player something
# 	- shout: tell everyone something
# 	- look: look at room, or look at object
# 	- get: get an object (get from room, or get from object)
# 	- drop: drop an object
# 	- put: put an object in another object
# 	- enter: enter a portal or door
#   - who: list players in game
#   - stat: show player stats (stat mp,hp,mv for specific)
#   - quit: quit the game
#   - n,e,s,w,ne,se,sw,nw: move in a direction (also handles long form)

# TODO:
	# - Ai integration for editor using local and remote LLM Godot class for tying into chatgpt and lmstudio
	# - show inventory
	# - split out code into separate files
	# - clean out redundant code that is not used and has been drifting in the code since 2020
	# - basic fight engine
	# - saves and loads
	# - more gui control


# BEGIN :: Multidimensional array with 2 keys and a value
# Multidimensional array with 2 keys and a value
# Godot version of my plist class that was made for my C++ mud
# encrypted file saving and loading
class TwoKeyArray:
	var data = {}

	# Initialize the array with default values
	func _init():
		data = {}

	func _reset():
		self.data = {}

	# Set a value in the array
	func set_value(key1, key2, value):
		if not data.has(key1):
			data[key1] = {}
		data[key1][key2] = value

	# Get a value from the array
	func get_value(key1, key2):
		if data.has(key1) and data[key1].has(key2):
			return data[key1][key2]
		else:
			return null

	# Remove a value from the array
	func remove_value(key1, key2):
		if data.has(key1) and data[key1].has(key2):
			data[key1].erase(key2)
			if data[key1].size() == 0:
				data.erase(key1)

	# Check if a key exists in the array
	func has_key(key1, key2):
		return data.has(key1) and data[key1].has(key2)

	# Get all keys from the array
	func get_keys():
		var keys = []
		for key1 in data.keys():
			for key2 in data[key1].keys():
				keys.append([key1, key2])
		return keys
		
	func get_subkeys(key1):
		var subkeys = []
		if data.has(key1):
			for key2 in data[key1].keys():
				subkeys.append(key2)
		return subkeys		
		
	func get_subkey(key1):
		if data.has(key1):
			return data[key1]
		
	func save_str():
		return JSON.stringify(self.data)
	
	func load_str(the_str):
		self.data = JSON.parse_string(the_str)

	# Save function to serialize data to a file
	func _save(filename, key):
		# FileAccess open_encrypted_with_pass ( String path, ModeFlags mode_flags, String pass ) static
		#var file = FileAccess.open(filename, FileAccess.WRITE)
		var file = FileAccess.open_encrypted_with_pass(filename, FileAccess.WRITE, key)
		file.store_string(JSON.stringify(self.data))
	
	# Load function to deserialize data from a file
	func _load(filename, key):
		# FileAccess open_encrypted_with_pass ( String path, ModeFlags mode_flags, String pass ) static
		#var file = FileAccess.open(filename, FileAccess.READ)
		var file = FileAccess.open_encrypted_with_pass(filename, FileAccess.READ, key)
		self.data = JSON.parse_string(file.get_as_text())
## END :: 2 key array class

## TEST:
func test_2key():
	# Create an instance of the TwoKeyArray class
	var two_key_array = TwoKeyArray.new()

	# Set values (first two values are unique, 3rd is the value)
	two_key_array.set_value("key1", "key2", "value")
	two_key_array.set_value("another_key1", "another_key2", "another_value")
	two_key_array.set_value("animal", "pet", "dog")
	two_key_array.set_value("animal", "pet", "cat") # overwrites dog with cat
	
	two_key_array._save("myfile.bin","donkeytacowakkawakka")

	# Get values
	var value = two_key_array.get_value("key1", "key2")
	print("Value:", value) # Output: Value: value

	# Remove a value
	two_key_array.remove_value("key1", "key2")

	# Check if a key exists
	var has_key = two_key_array.has_key("key1", "key2")
	print("Has key:", has_key) # Output: Has key: false

	# Get all keys
	var keys = two_key_array.get_keys()
	print("Keys:", keys) # Output: Keys: [["another_key1", "another_key2"]]
	
	two_key_array._reset()
	two_key_array._load("myfile.bin","donkeytacowakkawakka")
	
	print("Keys:", two_key_array.get_keys())

## END TEST.




### ### ###

# same as TwoKeyArray except value is a boolean
class TwoKeyFlags:
	var two_key_array = TwoKeyArray.new()
	
	func save_str():
		return self.two_key_array.save_str()
	
	func load_str(the_str):
		self.two_key_array.load_str(the_str)
	
	
	func add_flag(flag_name_a, flag_name_b):
		two_key_array.set_value(flag_name_a, flag_name_b, "1")
	
	# TODO: add a function to add multiple flags to a flag_name_a seperated by a delim
	# eg) .add_flags("can",	"wield,hold", 		",");
	# eg) .add_flags	("keywords",	"trash,trash,can,trashcan,garbage", ",");
		
	func add_flags(flag_name_a, flags_str, delim):
		var flags = flags_str.split(delim)
		for flag_name_b in flags:
			two_key_array.set_value(flag_name_a, flag_name_b, "1")
	
	func is_flag(flag_name_a, flag_name_b):
		return two_key_array.has_key(flag_name_a, flag_name_b)

	func rem_flag(flag_name_a, flag_name_b):
		two_key_array.remove_value(flag_name_a, flag_name_b)

	func get_flags(key1):
		return self.two_key_array.get_subkeys(key1)
	pass 
## END :: 2 key array class

## TEST:
func test_2keyflags():
	var tk_flags = TwoKeyFlags.new()
	# Example usage:
	tk_flags.add_flags("can", "wield,hold", ",")
	tk_flags.add_flags("keywords", "trash,trash,can,trashcan,garbage", ",")
	print(tk_flags.two_key_array.get_keys())
	print("keywords:",tk_flags.two_key_array.get_subkeys('keywords'))
	pass

### ### ###



class inventory:
	var game_objects = []
	
	func new_obj():
		self.game_objs.append(game_object.new())
		return self.game_objs.back()
		
	func get_save_str():
		var safe_str_p = ""
		var safe_str_f = ""
		for key in self.game_objects:
			var val = self.game_objects[key]
			
			# poke poke... do something
			# 	two_key_array._save("myfile.bin","donkeytacowakkawakka")
			safe_str_p = safe_str_p + val.params
			safe_str_f = safe_str_f + val.flags
			
		var r = [safe_str_p,safe_str_f]
		return r # get_save_str
	
	pass # inventory

class game_object:
	var params = TwoKeyArray.new()
	var flags = TwoKeyFlags.new()
	
	#var inventory = null # right now holding off on this part
	
	func _init():
		# class constructor
		self.params.set_value("info", "uid", self.generate_unique_id())
		# self.inventory = inventory.new() # give this object an inventory
		pass # constructor _init()
	
	func generate_unique_id():
		# Get current timestamp as string
		var timestamp_str := Time.get_ticks_msec()
		# Generate a random number
		var random_num := randi()
		# Concatenate timestamp and random number to form the unique ID
		var unique_id := str(timestamp_str) + "_" + str(random_num)
		return unique_id
		
	pass # class game_object


# TRACK GLOBALS (pass to class in _ready():)
var g_items_proto = [] # stores the templates for the items
var g_items = []
var g_rooms = []
var g_areas = []
var g_mobs_proto  = []
var g_mobs = []

var g_world = game_object.new()

func init_globals():
	

### --- BEGIN: AREA -->
	var avnum
	var cur_area

	# order of creation:
	# 1) create area
	# 2) create items prototypes
	# 3) create mobs prototypes
	# 4) create rooms
	# 5) load items into rooms
	# 6) load items into items
	# 7) load mobs into rooms
	# 8) load items into mobs
	# 9) equip mobs with their items


	avnum = "a9100"
	g_areas.append(game_object.new()) # You get an object... you get an object... everyone gets an object!
	cur_area = g_areas.back()
	
	print(cur_area)
	
### BEGIN ITEMS ###
	var ivnum
	var cur_proto
	ivnum = "i9100"
	g_items_proto.append(game_object.new()) # You get an object... you get an object... everyone gets an object!
	cur_proto = g_items_proto[-1]
	cur_proto.params.set_value("info","vnum", ivnum)
	cur_proto.params.set_value("area","vnum", avnum)
	cur_proto.params.set_value("info","title", "A Thin Glass Rod")
	cur_proto.params.set_value("info","room","A slender transparent rod shimmers.")
	cur_proto.params.set_value("info","description", 
			"There is really nothing special about this thin glass rod. It really looks cheap and inexpensive. It may be useful\r\n"+
			"for something.\r\n"
		)
	cur_proto.flags.add_flags("can","take,hold",",")
	cur_proto.flags.add_flags("keywords","thin,glass,rod,glass rod,thin rod,thin glass rod",",")
	# cur_proto.params.set_value("owner","uid","") # get from "info", "uid" on every object

	ivnum = "i9101"
	g_items_proto.append(game_object.new()) # You get an object... you get an object... everyone gets an object!
	cur_proto = g_items_proto[-1]
	cur_proto.params.set_value("info","vnum", ivnum)
	cur_proto.params.set_value("area","vnum", avnum)
	cur_proto.params.set_value("info","title", "A Rusty Iron Key")
	cur_proto.params.set_value("info","room","A small rusty iron key lies here.")
	cur_proto.params.set_value("info","description", 
			"This small rusty iron key looks like it has been here for a long time. It may be useful for something.\r\n"
		)
	cur_proto.flags.add_flags("can","take,hold",",")
	cur_proto.flags.add_flags("keywords","rusty,iron,key,iron key,rusty key,rusty iron key",",")
	# cur_proto.params.set_value("owner","uid","") # get from "info", "uid" on every object

	ivnum = "i9113"
	g_items_proto.append(game_object.new()) # You get an object... you get an object... everyone gets an object!
	cur_proto = g_items_proto[-1]
	cur_proto.params.set_value("info","vnum", ivnum)
	cur_proto.params.set_value("area","vnum", avnum)
	cur_proto.params.set_value("info","title", "An old oak door")
	cur_proto.params.set_value("info","room", "An old oak door is here.")
	cur_proto.params.set_value("info","description", 
			"This old oak door is very sturdy and looks like it has been here for a long time.\r\n"
		)
	cur_proto.flags.add_flags("is","2way",",")
	cur_proto.flags.add_flags("can","lock,unlock,open,close,enter",",")
	cur_proto.flags.add_flags("keywords","old,oak,door,old door,oak door,old oak door",",")
	# cur_proto.params.set_value("owner","uid","") # get from "info", "uid" on every object
	# cur_proto.params.set_value("to","uid","") # portal info for attached room
	
### END ITEMS ###


### BEGIN MOBS ###
	var mvnum
	var cur_mob
	mvnum = "m9100"
	g_mobs_proto.append(game_object.new())
	cur_mob = g_mobs_proto[-1]
	cur_mob.params.set_value("info","vnum", mvnum)
	cur_mob.params.set_value("area","vnum", avnum)
	cur_mob.params.set_value("info","title", "A Small Dinosaur")
	cur_mob.params.set_value("info","description", "A small dinosaur is here.")
	# keywords
	cur_mob.flags.add_flags("keywords","small,dinosaur,small dinosaur",",")

	
	mvnum = "m9101"
	g_mobs_proto.append(game_object.new())
	cur_mob = g_mobs_proto[-1]
	cur_mob.params.set_value("info","vnum", mvnum)
	cur_mob.params.set_value("area","vnum", avnum)
	cur_mob.params.set_value("info","title", "A Large Dinosaur")
	cur_mob.params.set_value("info","description", "A large dinosaur is here.")

### END MOBS ###

### BEGIN ROOMS ###	
	var rvnum
	var cur_room
	cur_area.params.set_value("info","vnum",avnum)
	
	rvnum = "r9100"
	g_world.params.set_value("start","vnum",rvnum)
	g_rooms.append(game_object.new())
	cur_room = g_rooms[-1]
	cur_room.params.set_value("info","vnum", rvnum)
	cur_room.params.set_value("area","vnum", avnum)
	cur_room.params.set_value("info","title", "Entrance to a Godot MUD")
	cur_room.params.set_value("info","description", "A certain calm befalls this place. The blades of grass bend over rhythmically with the pulse of a gentle breeze.\r\n"+
			"You feel safe here, as if nothing in the world matters, save the calm serenity of peace. The sound of birds singing\r\n"+
			"in the trees and the swaying song of the leaves rustling together in the wind makes you feel a tingly sensation of\r\n"+
			"comfort and warmth."
		)
	cur_room.params.set_value("room","type","outdoors")
	
	cur_room.params.set_value("exit","n","r9101") # use short form
	cur_room.params.set_value("exit_desc","n","A gentle breeze flows at you.")

	### create an object in room ###
	# find the object in the prototypes array matching a vnum and tie its owner uid to current room
	# make a load_proto(proto_vnum, global_items_arr, owner_uid)
	# var g_items_proto = []
	var load_obj = "i9100"
	var last_item = null
	for proto in g_items_proto:
		if proto.params.get_value("info","vnum") == load_obj:
			#var new_item = game_object.new()
			g_items.append(game_object.new())
			var new_item = g_items[-1]
			
			# deep copy
			var params_str = proto.params.save_str()
			var flags_str = proto.flags.save_str()
			print("p:",params_str)
			print("f:",flags_str)
			
			new_item.params.load_str(params_str)
			new_item.flags.load_str(flags_str)
			#new_item.params.load_str(proto.params.save_str)
			#new_item.flags.load_str(proto.flags.save_str)
			
			# last_item = g_items[-1]
			# re-uid it
			# self.params.set_value("info", "uid", self.generate_unique_id())
			new_item.params.set_value("info","uid",new_item.generate_unique_id())
			# set owner uid to room
			new_item.params.set_value("owner","uid",cur_room.params.get_value("info","uid"))
			# set as a portal
			new_item.params.set_value("to","rvnum","r9102")
			
			last_item = new_item
			break
	### end create an object in room ###


	### create an object in object (load in object i9101 to last one) ###
	load_obj = "i9101"
	for proto in g_items_proto:
		if proto.params.get_value("info","vnum") == load_obj:
			#var new_item = game_object.new()
			g_items.append(game_object.new())
			var new_item = g_items[-1]
			
			# deep copy - first get the serialized arrays
			var params_str = proto.params.save_str()
			var flags_str = proto.flags.save_str()
			print("p:",params_str)
			print("f:",flags_str)
			# ... now write them to new object
			new_item.params.load_str(params_str)
			new_item.flags.load_str(flags_str)

			# last_item = g_items[-1]
			# re-uid it
			new_item.params.set_value("info","uid",new_item.generate_unique_id())
			# set owner uid to last_item's uid
			new_item.params.set_value("owner","uid",last_item.params.get_value("info","uid"))
			break
	### end create an object in object ###


	### create an object in room ###
	# find the object in the prototypes array matching a vnum and tie its owner uid to current room
	# make a load_proto(proto_vnum, global_items_arr, owner_uid)
	# var g_items_proto = []
	load_obj = "i9113"
	for proto in g_items_proto:
		if proto.params.get_value("info","vnum") == load_obj:
			g_items.append(game_object.new())
			var new_item = g_items[-1]
			var params_str = proto.params.save_str()
			var flags_str = proto.flags.save_str()
			new_item.params.load_str(params_str)
			new_item.flags.load_str(flags_str)
			new_item.params.set_value("info","uid",new_item.generate_unique_id())
			new_item.params.set_value("owner","uid",cur_room.params.get_value("info","uid"))
			last_item = new_item
			# done loading new proto.. now since this is a door, lets set its remote door
			# .params.set_value("to","uid","") # portal info for attached room
			# get room at vnum r9102
			# set link vnum to r9102
			new_item.params.set_value("to","rvnum","r9102")
			# when a user picks up, set a flag whether it was linked door that was picked up, or main.
			# store destination vnum to be retrieved when exit is dropped in a room



	### end create an object in room ###



	rvnum = "r9101"
	g_rooms.append(game_object.new())
	cur_room = g_rooms[-1]
	cur_room.params.set_value("info","vnum", rvnum)
	cur_room.params.set_value("area","vnum", avnum)
	cur_room.params.set_value("info","title", "A Sandy Beach")
	# a beach with interesting features. Usually the room contains a dinosaur and a treasure chest with a treasure map.
	cur_room.params.set_value("info","description", ""
			+"The sun blazes brilliantly in the clear blue sky, casting a golden glow on the expansive, pristine beach. The sand, \r\n"
			+"soft and warm, seems to dance under the sunlight. The rhythmic symphony of waves crashing onto the shore creates an \r\n"
			+"exhilarating soundtrack to this adventure. The water, a mesmerizing shade of blue, beckons enticingly. A few clouds dot \r\n"
			+"the sky, like cotton candy on a canvas of blue. The beach, untouched by trash or debris, is a testament to the \r\n"
			+"unspoiled beauty of nature. Every element here promises an exciting and unforgettable adventure."		
		)
	cur_room.params.set_value("room","type","outdoors")

	cur_room.params.set_value("exit","n","r9102") # use short form
	cur_room.params.set_value("exit_desc","n","A gentle breeze flows at you.")
	cur_room.params.set_value("exit","s","r9100") # use short form
	cur_room.params.set_value("exit_desc","s","A gentle breeze flows at you.")
	

	# load mobs m9100 and m9101 into room
	var load_mob = ""
	# find the object in the prototypes array matching a vnum and tie its owner uid to current room
	# make a load_proto(proto_vnum, global_mobs_arr, owner_uid)
	# var g_mobs_proto = []
	load_mob = "m9100"
	for proto in g_mobs_proto:
		if proto.params.get_value("info","vnum") == load_mob:
			print("loading matching mob in: ",rvnum)
			g_mobs.append(game_object.new())
			var new_mob = g_mobs[-1]
			var params_str = proto.params.save_str()
			var flags_str = proto.flags.save_str()
			new_mob.params.load_str(params_str)
			new_mob.flags.load_str(flags_str)
			new_mob.params.set_value("info","uid",new_mob.generate_unique_id())
			new_mob.params.set_value("vnum","cur",rvnum)
			
		# end for

	# ---
	
	rvnum = "r9102"
	g_rooms.append(game_object.new())
	cur_room = g_rooms[-1]
	cur_room.params.set_value("info","vnum", rvnum)
	cur_room.params.set_value("area","vnum", avnum)
	cur_room.params.set_value("info","title", "A Dead End")
	cur_room.params.set_value("info","description", ""+
			"Well this place isn't really described very well now is it? Maybe it's because this is just a test room, and getting\r\n"
			+"too crazy now only makes building it harder."
		)
	cur_room.params.set_value("room","type","indoors")
	
	cur_room.params.set_value("exit","s","r9101") # use short form
	cur_room.params.set_value("exit_desc","s","A gentle breeze flows at you.")
	
### END ROOMS ###
	pass


# http://ascii-table.com/ansi-escape-sequences-vt-100.php
#http://ascii-table.com/documents/vt100/chapter3.php#S3.3.3
class telnet_app:
	var servers = []
	var users = []
	
	var world_arr = []
	
	var time_ms_last_data_check = 0
	var delay_ms_data_check = 60
	
	func _init(world_arr):
		pass

	func welcome(user):
		pass

	func telnet_echo_off(user):
		pass
	
	func telnet_echo_on(user):
		pass

	func telnet_clrscr(user):
		self.send(user, "\u001B[2J")

	func telnet_clrln(user):
		self.send(user, "\u001B[2K")

	func send(user, message):
		self.send_nr(user,  message + "\r\n")
		#self.prompt(user)

	func send_nr(user, message): # no return
		var client = user.client
		
		client.put_string("\u001B[2K\r" + message)

	func send_all(message):
		for u in self.users:
			var index = self.users.find(u)
			var client = u.client
			
			if client.is_connected_to_host():
				self.send(u, message)
			else:
				print("client disconnected")

	func send_all_except(except_user, message):
		var index_except = self.users.find(except_user) # find by index
		
		for u in self.users:
			var index = self.users.find(u)
			
			if index != index_except:
				var client = u.client
				
				if client.is_connected_to_host():
					# client.put_string(message)
					self.send(u, message)
					self.prompt(u) # prompting because interrupting other users terminals
				else:
					print("client disconnected")

	func hide_input(user):
		var client = user.client
		client.put_string("\u001B[2K\r")
	
	func show_input(user):
		var client = user.client
		client.put_string("\u001B[2K\r")
		self.prompt(user)

	func prompt(user): # overload
		pass

	func check_for_command(user):
		var client = user.client
		var index 	= users.find( user )
		var buf 	= user.buf
	
		if(buf.find("\n") > -1): # incoming command from client
			var command_str = buf.left( buf.find("\n") ).strip_edges()

			self.users[index].buf = self.users[index].buf.right( buf.find("\n") + 2).strip_edges()

			# debug output in console
			print("command found: [" + command_str + "] ")
			print("new buffer   : [" + users[index].buf + "] ")
			
			self.users[index].buf = "" # wipe buffer
			self.handle_command_string(user, command_str)

	func check_for_command_users():
		for u in self.users:
			var index = self.users.find(u)
			self.check_for_command(u)

	func handle_command_string(user, command_str):
		var client = user.client
		var index = self.users.find( user )

	func create_server(port):
		var svr_obj = {}
		svr_obj.server = TCPServer.new()
		svr_obj.port = port
		
		if svr_obj.server.listen(svr_obj.port) == 0:
			print("server started:" + str(port) )
			self.servers.append(svr_obj)

	func check_for_new_users():
		for svr_obj in self.servers:
			if svr_obj.server.is_connection_available():
				self.create_new_user(svr_obj)


	func create_new_user(svr_obj):
		var server = svr_obj.server
		var port = svr_obj.port

		var client = server.take_connection()

		var cli_obj = {}
		cli_obj.server 		= server
		cli_obj.port 		= port
		cli_obj.client 		= client
		cli_obj.ip			= client.get_connected_host()
		cli_obj.buf 		= ""
		
		print("client ip:" + str(cli_obj.ip))
		
		# Disables Nagle’s algorithm to improve latency for small packets
		client.set_no_delay(true) 
		
		self.users.append(cli_obj)
		var last_index = self.users.size() - 1
		var user = self.users[last_index]

		self.welcome(user)
		

	func check_for_data():
		var cur_msecs = Time.get_ticks_msec()
		
		if cur_msecs - time_ms_last_data_check > delay_ms_data_check:
			for u in self.users:
				var index = self.users.find(u)
				var client = u.client
				
				# if client.is_connected_to_host():
				if client.get_status() == 2:
					if client.get_available_bytes() > 0:
						var buf = client.get_partial_data(1024)
						buf = buf[1].get_string_from_ascii()
						self.users[index].buf += buf
						
						print ("new data in buffer from user #" + str(index) + " : [" +  self.users[index].buf + "]")
				else:
					# print("client disconnected")
					pass
			
			self.time_ms_last_data_check = cur_msecs

	func disconnect_user(user):
		var index = self.users.find(user)
		var client = user.client
		
		# self.users.remove(index) # godot 4 now uses remove_at
		self.users.remove_at(index)

	func server_loop():
		OS.delay_usec(1000)
		
		self.check_for_new_users()
		self.check_for_data()
		self.check_for_command_users()


#
#
#
#
#var server_app
#
#
#func _ready():
#	server_app = telnet_app.new()
#	server_app.create_server(3500)
#	server_app.create_server(3600)	
#
#
#func _process(delta):
#	server_app.server_loop()
#

class game_command_util:
	# standalone functions
	# TODO: add in process backspaces, one arg, and any other universal functions
	
	func _init():
		pass


# class to handle incoming game_commands - used by class game_app
class game_command:
	var p # parent
	var util = game_command_util.new()
	
	func _init(the_parent):
		print("creating game_command object")
		self.p = the_parent
		pass
		
	
	# step 1
	func process_string(user, command_str):
#		print("inside game_command object")
#		print("parent"  + to_json( self.p.users ))
#
#		var i = self.p.users.find(user)
#		self.p.users[i].username = "nnnn" # test to see if child object writing properly
		pass
	
	# step 2
	func process_state(user, command_str):
		var index 		= self.p.users.find(user)
		var user_state 	= self.p.users[index].player.state
		pass
	
	# step 3
	func process_command(user, command_str):
		pass
	
# end class: handle incoming game_commands


class game_app:
	extends telnet_app
	

	#var world = game_world.new()
	var globals = {}

	var time_ms_last_game_loop = 0
	var delay_ms_game_loop = 50000

	var time_ms_last_action_loop = 0
	var delay_ms_action_loop = 5000

	# handle incoming game commands
	var gc = game_command.new(self)

	func _init(globals_ref):
		print("game created")
		self.globals = globals_ref
		pass

	func prompt(user):
		# show a prompt to our player based on their state
		match(user.player.state):
			"login":
				self.send_nr(user, "what is your name adventurer? ")
			"password":
				self.send_nr(user, "what is your password? ")
			_: # default in godot is a _
				self.send_nr(user, ">> ")

	func create_dummy():
		# SHOULD BE OBSOLETE!
		# make a blank user
		var temp_player = {}
		
		temp_player.params = TwoKeyArray.new()
		temp_player.flags = TwoKeyFlags.new()
		
		temp_player.inventory = inventory.new()
	
		temp_player.state = "login"
		temp_player.in_world = false
		
		print("starting vnum:", self.globals.g_world.params.get_value("start","vnum"))

#
#		temp_player.username = ""
#		temp_player.password = ""
		
		temp_player.login_time = Time.get_unix_time_from_system()
		temp_player.last_access = Time.get_unix_time_from_system()
		
		temp_player.race = "-1"
		temp_player.guild  = "-1"
		
		temp_player.room = "-1"
		temp_player.fighting = "-1"
		temp_player.position = "standing"
		temp_player.currency = 100
		
		temp_player.stats = {}
		
		temp_player.stats.hp = 20
		temp_player.stats.hp_max = 20
		temp_player.stats.mv = 20
		temp_player.stats.mv_max = 20
		temp_player.stats.mp = 20
		temp_player.stats.mp_max = 20
		
		temp_player.stats.strength = 12
		temp_player.stats.wisdom = 12
		temp_player.stats.intelligence = 12
		temp_player.stats.constitution = 12
		temp_player.stats.charisma = 12
		temp_player.stats.dexterity = 12
		

		
		return temp_player
		pass

	func generate_unique_id():
		# Get current timestamp as string
		var timestamp_str := Time.get_ticks_msec()
		# Generate a random number
		var random_num := randi()
		# Concatenate timestamp and random number to form the unique ID
		var unique_id := str(timestamp_str) + "_" + str(random_num)
		return unique_id
		
		
	func dummy(the_user):
		var p = the_user.params
		var f = the_user.flags
		var login_time = Time.get_unix_time_from_system()
		var last_access = Time.get_unix_time_from_system()
		
		p.set_value('info','uid',self.generate_unique_id())
		
		p.set_value('vnum','cur',self.globals.g_world.params.get_value("start","vnum"))
		
		#p.params.set_value('','',)
		p.set_value('time','login',login_time)
		p.set_value('time','last_access',last_access)
		p.set_value('state','ui','login')
		p.set_value('state','pose','standing')
		# when finished login states add flag in game
		# when fighting create a fighting key and then second key is vnum as a flag
		# eg) f.add_flag('fighting','m1234') # allows for multiple enemies
		p.set_value('stat','hp','20')
		p.set_value('stat','mp','20')
		p.set_value('stat','mv','20')
		
		p.set_value('max','hp','20')
		p.set_value('max','mp','20')		
		p.set_value('max','mv','20')
		
		p.set_value('stat','str','12')
		p.set_value('stat','wis','12')
		p.set_value('stat','int','12')
		p.set_value('stat','con','12')
		p.set_value('stat','cha','12')
		p.set_value('stat','dex','12')
		
		p.set_value('max','str','18')
		p.set_value('max','wis','18')
		p.set_value('max','int','18')
		p.set_value('max','con','18')
		p.set_value('max','cha','18')
		p.set_value('max','dex','18')
		
		pass # dummy.. use params/flags


	func welcome(user):
		var index = self.users.find( user )
		
		self.telnet_clrscr(user)
		self.telnet_echo_off(user)

		self.send(user, "Welcome new user on port:" + str(user.port) )
		# self.send_all_except(user, "NEW CONNECTION")
		users[index].params = TwoKeyArray.new()
		users[index].flags = TwoKeyFlags.new()
		users[index].player = self.create_dummy() # should be using the object class # old dummy
		print("starting vnum:", self.globals.g_world.params.get_value("start","vnum"))
		self.dummy(users[index]) # new dummy
		
		self.prompt(user)
		
		pass

	func action_loop():
		var cur_ms = Time.get_ticks_msec()
		
		if cur_ms - time_ms_last_action_loop > delay_ms_action_loop:
			time_ms_last_action_loop = cur_ms
			print("action loop")
		pass

	func game_loop():
		var cur_ms = Time.get_ticks_msec()

		if cur_ms - time_ms_last_game_loop > delay_ms_game_loop:
			time_ms_last_game_loop = cur_ms
			print("game loop")
		pass

	func is_playername(str_name):
		return true
	
	func is_playerpassword(str_pass):
		return true
	
	func get_user_by_name(find_username):
		for u in self.users:
			var i = self.users.find(u) # index in main array
			var username = u.username
			
			if(username == find_username):
				print("found user:" + username)
				return u
		
		return false
		
		
	func get_users():
		# return self.users

		# actually just return in game users so has a flag set "in","game"
		var ret_users = []
		
		for u in self.users:
			var in_world = u.flags.is_flag("in","game")

			if in_world:
				ret_users.append(u)
		
		return ret_users
	
	func processBackspace(input_string):
		# made a gist mar6-2024: https://gist.github.com/g023/3dea8c91cc1c681ae0da4d4ad6d9c548
		var result = ""
		var stack := []
		
		if input_string.find("\b") == -1:
			return input_string

		for char in input_string:
			if char == "\b":
				if stack.size() > 0:
					stack.pop_back()
				else:
					stack.push_back(char)
			else:
				stack.append(char)

		for char in stack:
			result += char

		return result


	func one_arg(command_str):
		# made a gist mar6-2024: https://gist.github.com/g023/f5044e68a0711448b0077c67b62da5d6
		# strips out a single word before a space
		# returns [0] -> command, [1] -> param
		var split_str = []

		command_str = command_str.strip_edges()
		command_str = self.processBackspace(command_str)
		
		var command = ""
		var params = ""
		
		if command_str.find(" ") == -1:
			print("single command no params")
			command = command_str
		else:
			command = command_str.get_slice(" ", 0).strip_edges()
			params = command_str.split(" ", true, 1)
			params = params[1].strip_edges() # only want second part
			print("command + params")
			
		split_str.append(command)
		split_str.append(params)

		return split_str

	func handle_command_string(user, command_str):
		print("using gc object:") # REPLACE OLD PROCESS
		gc.process_string(user, command_str)
		
		var client = user.client
		var index = users.find(user)
		print("handling command")
		
		var r = self.one_arg(command_str)
		var command = r[0]
		var params = r[1]

		handle_command(user, command, params)

	func handle_command(user, command, params):
		# state processor
		# command processor
		var index = self.users.find( user )

		print("command:" + command)
		print("params:" + params)

		if user.player.state == "login":
			var try_username = command
			self.users[index].player.name = try_username
			print("handling player login:" + try_username)

			if is_playername(try_username):
				self.users[index].username = try_username
				self.users[index].player.state = "password" # old
				self.users[index].params.set_value("state","ui","password") # new

		elif user.player.state == "password":
			var try_password = command
			print("handling player password:" + try_password)
			
			if is_playerpassword(try_password):
				self.send_all_ingame_except(user, "Player " + user.username + " has entered the game")
				self.users[index].player.state = "game"
				self.users[index].player.in_world = true
				# set the game able to see player
				self.users[index].params.set_value("info","username",self.users[index].username)
				self.users[index].params.set_value("state","ui","game")
				self.users[index].flags.add_flag("in","game")
				
				# first look command
				#users[index].params.set_value("vnum","cur", self.globals.g_world.params.get_value("start","vnum"))
				self.do_look(users[index],users[index].params.get_value("vnum","cur"))
		

		else: # we are in game
			self.do_command(user,command,params)

		self.prompt(user)
	
	func send_all_ingame_except (except_user, message):
		var index_except = self.users.find(except_user)
		
		for u in self.users:
			var index = self.users.find(u)
			
			if index != index_except:

				var client = u.client
				
				#if client.is_connected_to_host() && u.player.in_world:
				if client.get_status() == 2 && u.player.in_world:
					# client.put_string(message)
					self.send(u, message)
					self.prompt(u) # prompting because interrupting other users terminals
				else:
					# print("client disconnected")
					pass
	
	
	func get_room_by_vnum(rvnum):
		var r_arr = self.globals.g_rooms
		for r in r_arr:
			if r.params.get_value("info","vnum") == rvnum:
				return r
		return null

	func get_room_by_uid(uid):
		var r_arr = self.globals.g_rooms
		for r in r_arr:
			if r.params.get_value("info","uid") == uid:
				return r
		return null
		
	
	func get_users_by_vnum(vnum):
		var cur_users = self.get_users()
		var ret_users = []
		for u in cur_users:
			if u.params.get_value("vnum","cur") == vnum:
				ret_users.append(u)
		return ret_users

	func get_mobs_by_vnum(vnum):
		var cur_mobs = self.globals.g_mobs
		var ret_mobs = []
		for m in cur_mobs:
			if m.params.get_value("vnum","cur") == vnum:
				ret_mobs.append(m)
		return ret_mobs
	
	func get_user_by_username(username):
		# only checks in game players.. eg) those who have ("info","username"
		# ("info","username"
		users = self.get_users()
		for u in users:
			if u.params.get_value("info","username") and u.params.get_value("info","username") == username:
				return u
		return null
	
	func msg_all_vnum(vnum, msg):
		# message all players who are currently in a specific vnum
		var users = get_users_by_vnum(vnum)
		for u in users:
			self.msg_player(u,msg)
		pass
	
	func msg_others_vnum(cur_user,vnum,msg):
		var users = get_users_by_vnum(vnum)
		var cur_username = cur_user.params.get_value("info","username")
	
		for u in users:
			if u.params.get_value("info","username") != cur_user.params.get_value("info","username"):
				self.msg_player(u,msg)
		pass
	
	func get_users_world_ignore(ignore_users):
		var room_users = self.get_users()
		var ret_users = []
		var ignore = false
		for ru in room_users:
			ignore = false
			for iu in ignore_users:
				if iu.params.get_value("info","username") == ru.params.get_value("info","username"):
					ignore = true
				
			# if not ignore than we want to send a message
			if not ignore:
				ret_users.append(ru)
		return ret_users
	
	
	func get_users_room_ignore(ignore_users,vnum):
		var room_users = get_users_by_vnum(vnum)
		var ret_users = []
		var ignore = false
		for ru in room_users:
			ignore = false
			for iu in ignore_users:
				if iu.params.get_value("info","username") == ru.params.get_value("info","username"):
					ignore = true
				
			# if not ignore than we want to send a message
			if not ignore:
				ret_users.append(ru)
		return ret_users
	
	func msg_ignore_vnum(ignore_users,vnum,msg):
		# ignore a group of users in room when sending a message
		# useful when two players interact to show room a different interaction message
		# send an array of users
		var room_users = get_users_by_vnum(vnum)
		
		var ignore = false
		for ru in room_users:
			ignore = false
			for iu in ignore_users:
				if iu.params.get_value("info","username") == ru.params.get_value("info","username"):
					ignore = true
				
			# if not ignore than we want to send a message
			if not ignore:
				self.msg_player(ru, msg)
		pass
	
	func msg_player(dest_user,msg):
			
		if dest_user == null:
			return false
		if msg == '':
			return false
		#print(dest_user)
		#self.send(dest_user,"TESSSTIGNNNGNG\r\n\r\n")
		self.send(dest_user, msg)
		return true
				
	
	func exit_expand_str(exit_str):
		match exit_str:
			'u':return  'up'
			'd':return  'down'
			'n':return  'north'
			'e':return  'east'
			's':return  'south'
			'w':return  'west'
			'ne':return  'northeast'
			'nw':return  'northwest'
			'se':return  'southeast'
			'sw':return  'southwest'
			_:
				return exit_str
	
	func exit_shrink_str(exit_str):
		match exit_str:
			'up':return 'u'
			'down':return 'd'
			'north':return 'n'
			'east':return 'e'
			'south':return 's'
			'west':return 'w'
			'northeast':return 'ne'
			'northwest':return 'nw'
			'southeast':return 'se'
			'southwest':return 'sw'
			_:
				return exit_str		
	
	func exit_opp_str(exit_str):
		match exit_str:
			'u':return  'd'
			'd':return  'u'
			'n':return  's'
			'e':return  'w'
			's':return  'n'
			'w':return  'e'
			'ne':return  'sw'
			'nw':return  'se'
			'se':return  'nw'
			'sw':return  'ne'
			_:
				return exit_str



	# get items that belong to a specific uid
	func get_items(uid):
		var items = []
		for item in self.globals.g_items:
			# print ("----------------------------------------------\r\n")
			# print ("to room:",item.params.get_value("to","rvnum"))
			# print ("to uid:",item.params.get_value("to","uid"))
			# print ("----------------------------------------------\r\n")
			# now handling doors as well...
			# check if too room is set, and if so we need to establish its uid if to,uid does not exist
			# setup our linked object (eg: a door), or an object that exists in two places at once.
			# if not to room empty and empty uid then we need to set it
### BEGIN : HANDLE DOOR : INITIALIZE UID ON FIRST ACCESS
			if item.params.get_value("to","rvnum") != "" and item.params.get_value("to","uid") == null:
				var to_room = self.get_room_by_vnum(item.params.get_value("to","rvnum"))
				if to_room != null:
					item.params.set_value("to","uid",to_room.params.get_value("info","uid")) # change to player on pickup of exit
### END : HANDLE DOOR : INITIALIZE UID ON FIRST ACCESS

			if item.flags.is_flag("is","2way"): # handle an object that exists in 2 rooms at once
				if item.params.get_value("owner","uid") == uid or item.params.get_value("to","uid") == uid:
					items.append(item)
			else:
				if item.params.get_value("owner","uid") == uid:
					items.append(item)
		return items

	func get_items_by_keyword(uid,keyword):
		var items = []
		for item in self.globals.g_items:
			if item.params.get_value("owner","uid") == uid or item.params.get_value("to","uid") == uid:
				if item.flags.is_flag("keywords",keyword):
					items.append(item)
		return items
	
	# process a door pickup
	# an object that exists in 2 places at once (determine in get_items based on flag "is","2way")
	func process_door_get(the_item, the_room):
		if the_item.flags.is_flag("is","2way"):
			# get <object>, get all
			var to_uid 		= the_item.params.get_value("to","uid")
			var owner_uid 	= the_item.params.get_value("owner","uid")
			var room_uid 	= the_room.params.get_value("info","uid")

			if to_uid != null:
				print("item is a door.")
				var store_uid = ""
				if room_uid == owner_uid:
					# store destination id
					store_uid = to_uid
				else:
					store_uid = owner_uid

				the_item.params.set_value("old","uid", store_uid)
				the_item.params.set_value("to","uid", "-1")
				# when we drop this item, 
				# we have to check whether to,uid is set to -1, and if it is
				# we have to switch the old,uid to to,uid
				# and set the info,uid to room uid

	# process a door drop
	func process_door_drop(the_item):
		if the_item.flags.is_flag("is","2way"):
			# drop <object>, drop all
			# handle a 2way door drop, set the connecting room back up
			if the_item.params.get_value("to","uid") == "-1":
				the_item.params.set_value("to","uid", the_item.params.get_value("old","uid"))



### BEGIN COMMANDS ###
	
	func do_command(user,command,params):
		var index = self.users.find( user ) # find by index
		var p = user.params
		
		var outmsg = ""

		match command:
			"n","e","s","w","north","east","south","west","ne","nw","se","sw","northeast","northwest","southeast","southwest","u","d","up","down":
				var cur_room_vnum = user.params.get_value("vnum","cur")
				var the_room = self.get_room_by_vnum(cur_room_vnum)
				var the_dir = self.exit_shrink_str(command)

				var the_exit = the_room.params.get_value("exit",the_dir)
				if the_exit == null:
					outmsg += "No exit found in that direction."
				else:
					# handle messages in current room
					var src_username = user.params.get_value("info","username")
					var other_users = self.get_users_room_ignore([user],cur_room_vnum)
					var room_msg = src_username+" leaves " + self.exit_expand_str(the_dir)

					for ou in other_users:
						self.send(ou, room_msg)
						self.prompt(ou)
						
					# move player
					user.params.set_value("vnum","cur",the_exit)
					self.do_look(user,the_exit)
					#print("exit:",the_exit)
					
					# handle messages in new room
					other_users = self.get_users_room_ignore([user],the_exit)
					room_msg = src_username+" enters from the " + self.exit_expand_str(self.exit_opp_str(self.exit_shrink_str(the_dir)))
					for ou in other_users:
						self.send(ou, room_msg)
						self.prompt(ou)

				pass

			"enter":
				# 2way items have to be in room to enter, so will have a -1 in to,uid
				# if we have a to,uid then we can enter.
				# if to_uid is current room and this is a 2way item, then use owner,uid as room to jump to
				# else if just a to,uid and not a 2way item, then use to,uid as room to jump to
				var the_item = null
				var user_uid = user.params.get_value("info","uid")
				var user_items = self.get_items_by_keyword(user.params.get_value("info","uid"),params)

				var cur_room_vnum = user.params.get_value("vnum","cur")
				var the_room = self.get_room_by_vnum(cur_room_vnum)
				var room_items = self.get_items_by_keyword(the_room.params.get_value("info","uid"),params)

				if user_items.size() > 0:
					# we have a matching item in inventory
					print("matching player item")
					for i in user_items:
						if i.params.get_value("to","uid") != null and i.params.get_value("to","uid") != "-1":
							the_item = i
							break
					pass
				else:
					# try and find in room

					if room_items.size() > 0:
						# we have a matching item in room
						print("matching room item")
						for i in room_items:
							if i.params.get_value("to","uid") != null and i.params.get_value("to","uid") != "-1":
								the_item = i
								break
						pass
					
				if the_item == null:
					# we don't have a matching item
					outmsg += "You don't see that here."
				else:
					# we have a matching item
					var to_uid = the_item.params.get_value("to","uid")
					var room = self.get_room_by_uid(to_uid)

					if room == null or to_uid == "-1":
						outmsg += "You can't enter that."
					else:
						# we have a room to enter
						# handle messages in current room

						print("o:",the_item.params.get_value("owner","uid"))
						print("t:",the_item.params.get_value("to","uid"))
						print("r:",the_room.params.get_value("info","uid"))

						# if owner == room then use to uid as room to jump to
						# else use owner uid as room to jump to
						var dest_uid = ""
						if the_item.params.get_value("owner","uid") == the_room.params.get_value("info","uid"):
							dest_uid = the_item.params.get_value("to","uid")
						else:
							dest_uid = the_item.params.get_value("owner","uid")

						if the_item.flags.is_flag("is","2way") != true:
							dest_uid = the_item.params.get_value("to","uid")
						

						# move player
						# user.params.set_value("vnum","cur",to_uid)
						#self.do_look(user,to_uid)
						#print("exit:",the_exit)

						if dest_uid != "" and dest_uid != "-1" and dest_uid != null:
							print("dest uid", dest_uid)
							# get vnum of dest room
							var dest_vnum = self.get_room_by_uid(dest_uid)
							if dest_vnum != null:
								dest_vnum = dest_vnum.params.get_value("info","vnum")
							else:
								dest_vnum = "-1"

							if dest_vnum != "-1":
								# set player to dest room
								#
								
								print("dest_vnum:",dest_vnum)
								print("cur vnum:",user.params.get_value("vnum","cur"))
								user.params.set_value("vnum","cur",dest_vnum)
								#self.do_look(user,dest_uid)


								## SUCCESS : Now send messages
								# <user> enters from the <object>

								# old room:
								var username = user.params.get_value("info","username")
								var orig_room_others = self.get_users_room_ignore([user],cur_room_vnum)
								var orig_room_msg = username+" exits into " + the_item.params.get_value("info","title")

								# send to old room:
								for ou in orig_room_others:
									self.send(ou, orig_room_msg)
									self.prompt(ou)

								# new room:
								var new_room_others = self.get_users_room_ignore([user],dest_vnum)

								# if this is a 2 way door, say what it is:
								# var new_room_msg = username+" enters from the " + the_item.params.get_value("info","title")
								var new_room_msg = ""

								# if entered from a normal portal (1 way), say enter from somewhere
								if the_item.flags.is_flag("is","2way"):
									new_room_msg = username+" enters from the " + the_item.params.get_value("info","title")
								else:
									new_room_msg = username+" enters from somewhere"
								
								# send to new room:
								for ou in new_room_others:
									self.send(ou, new_room_msg)
									self.prompt(ou)

								# player message
								self.send(user, "You enter " + the_item.params.get_value("info","title"))
								self.send(user, "\r\n")
								
								# force a look
								self.do_look(user,dest_vnum)
							else:
								outmsg += "You can't enter that."


						else:
							outmsg += "You can't enter that."
						
						
					# set player to dest room
					
			
			"l","look":
				var cur_room_vnum = user.params.get_value("vnum","cur")
				# if we have a second param then we are looking at an object
				# if that param is "in" then we are looking in an object
				if params != "":
					var new_command = self.one_arg(params)[0]
					if new_command == "in":
						params = self.one_arg(params)[1]
						# do look in object
						var the_object = self.get_items_by_keyword(user.params.get_value("info","uid"),params)
						# if we can't find item on player, find in room
						if the_object.size() == 0:
							the_object = self.get_items_by_keyword(self.get_room_by_vnum(cur_room_vnum).params.get_value("info","uid"),params)
						# if we have an object then work with it
						if the_object.size() > 0:
							the_object = the_object[0]
							var the_object_vnum = the_object.params.get_value("info","vnum")
							var the_object_title = the_object.params.get_value("info","title")
							var the_object_desc = the_object.params.get_value("info","description")
							outmsg += "You look in " + the_object_title + "\r\n" + the_object_desc
							# now show list of objects inside object
							var items = self.get_items(the_object.params.get_value("info","uid"))
							if items.size() > 0:
								outmsg += "You see the following items inside:\r\n"
								for item in items:
									outmsg += item.params.get_value("info","title") + "\r\n"
							else:
								outmsg += "You don't see anything inside."
						else:
							outmsg += "You don't see that here."
					else:
						# do look at object
						var the_object = self.get_items_by_keyword(user.params.get_value("info","uid"),params)
						# if we can't find item on player, find in room
						if the_object.size() == 0:
							the_object = self.get_items_by_keyword(self.get_room_by_vnum(cur_room_vnum).params.get_value("info","uid"),params)
						# if we have an object then work with it
						if the_object.size() > 0:
							the_object = the_object[0]
							var the_object_vnum = the_object.params.get_value("info","vnum")
							var the_object_title = the_object.params.get_value("info","title")
							var the_object_desc = the_object.params.get_value("info","description")
							outmsg += "You look at " + the_object_title + "\r\n" + the_object_desc
						else:
							outmsg += "You don't see that here."
						pass
				else:
					# TODO: add look at <player or mob>
					# look at room
					self.do_look(user,cur_room_vnum)

			"quit","q","qu","qui":
				self.send_all_ingame_except(user, "user #" + str(index) + "("+ user.username +") has disconnected")
				self.disconnect_user(user)

			"msecs":
				outmsg += str(Time.get_ticks_msec())

			"stat":
				var matches = []
				match params:
					"hp":
						matches = ['hp']
					"mv":
						matches = ['mv']
					"mp":
						matches = ['mp']
					_: # default
						matches = ['hp','mv','mp']
				for value in matches:
					outmsg += " "+value+": " + str(p.get_value('stat',value)) + "/" + str(p.get_value('max',value))

			"who":
				for u in self.get_users():
					outmsg += str(u.username) + "\r\n"

			"shout":
				outmsg += "You shout '"+params+"'"
				self.do_shout(user, params)
				pass
			
			"say":
				outmsg += "You say '"+params+"'"
				do_say(user,params)
				pass
			
			"drop":
				var cur_room_vnum = user.params.get_value("vnum","cur")
				var the_room = self.get_room_by_vnum(cur_room_vnum)
				var items
				# Handle 'drop idx.item' command
				var idx = 1
				if "." in params:
					var split_params = params.split(".")
					idx = int(split_params[0])
					params = split_params[1]
				
				# handle empty
				if params == "":
					outmsg += "Drop what?"
				# Handle 'drop all' command
				elif params == "all":
					# Handle 'drop all' command
					# send all items from player inventory to room inventory
					var player_items = self.get_items(user.params.get_value("info","uid"))
					
					if player_items.size() > 0:
						for item in player_items:
# BEGIN :: HANDLE DOOR
							self.process_door_drop(item)
# END :: HANDLE DOOR		
							outmsg += "You drop " + item.params.get_value("info","title") + "\n"
							item.params.set_value("owner","uid", the_room.params.get_value("info","uid"))
					else:
						outmsg += "You don't have any items to drop."
				else:
					# Handle 'drop <object_to_drop>' command
					# send an item from player inventory to room inventory
					items = self.get_items_by_keyword(user.params.get_value("info","uid"),params)
					if items.size() >= idx:
						var item = items[idx-1]
						outmsg += "You drop " + item.params.get_value("info","title") + "\n"
						item.params.set_value("owner","uid", the_room.params.get_value("info","uid"))
# BEGIN :: HANDLE DOOR
						self.process_door_drop(item)
						# if item.params.get_value("to","uid") == "-1":
						# 	item.params.set_value("to","uid", item.params.get_value("old","uid"))
# END :: HANDLE DOOR
					else:
						outmsg += "You don't have that item."
				
			"put":
				# put <object_to_put> in <object_to_put_in>
				# split string on the " in " part
				var split = params.split(" in ")
				var put_what = split[0]
				var put_in = split[1]
				# trim whitespace
				put_what = put_what.strip_edges()
				put_in = put_in.strip_edges()

				outmsg += "You attempt to put " + put_what + " in " + put_in + "\r\n"
				# find object in player inventory
				var match_items = self.get_items_by_keyword(user.params.get_value("info","uid"),put_what)

				if match_items.size() > 0:
					var put_item = match_items[0]
					# find object to put in
					var match_put_in = self.get_items_by_keyword(user.params.get_value("info","uid"),put_in)
					# if not in player inventory, find in room
					if match_put_in.size() == 0:
						match_put_in = self.get_items_by_keyword(self.get_room_by_vnum(user.params.get_value("vnum","cur")).params.get_value("info","uid"),put_in)

					if match_put_in.size() > 0:
						var put_in_item = match_put_in[0]
						outmsg += "You put " + put_item.params.get_value("info","title") + " in " + put_in_item.params.get_value("info","title") + "\r\n"
						put_item.params.set_value("owner","uid",put_in_item.params.get_value("info","uid"))
					else:
						outmsg += "You don't see that here."
				else:
					outmsg += "You don't see that here."
				pass # put

			"get":
				var cur_room_vnum = user.params.get_value("vnum","cur")
				var the_room = self.get_room_by_vnum(cur_room_vnum)
				var items
				# Handle 'get idx.item' command
				var idx = 1
				if "." in params:
					var split_params = params.split(".")
					idx = int(split_params[0])
					params = split_params[1]
				
				# Handle 'get all' command
				if params == "all":
					items = self.get_items(the_room.params.get_value("info","uid"))
					
					if items.size() > 0:
						for item in items:
# BEGIN :: HANDLE DOOR
							self.process_door_get(item, the_room)
# END :: HANDLE DOOR
							outmsg += "You get " + item.params.get_value("info","title") + "\n"
							item.params.set_value("owner","uid",user.params.get_value("info","uid"))
					else:
						outmsg += "There are no items here."

				# Handle 'get <object_to_get> from <object_to_take_from>' command
				# <object_to_get> if 'all' then take everything from <object_to_take_from>
				elif " from " in params:
					var split = self.one_arg(params)
					var get_what = split[0]
					var get_from = split[1] # have to still trim out from
					get_from = self.one_arg(get_from)[1]
					# trim whitespace
					get_from = get_from.strip_edges()
					
					outmsg += "You attempt to get " + get_what + " from " + get_from + "\r\n"

					var user_uid = user.params.get_value("info","uid")
					var room_uid = the_room.params.get_value("info","uid")

				
					# first check player
					var match_player_from = self.get_items_by_keyword(user_uid,get_from)
					print("match_player:",match_player_from)
					var match_room_from = self.get_items_by_keyword(room_uid,get_from)
					print("match_room:",match_room_from)
					
					# player inventory takes priority. Secondary use room. If no items on player but item in room, use room.
					# now we need to find object in first entry of match_player_from or match_room_from
					var first_item = null
					var taken_from_room = false
					if match_player_from.size() > 0:
						first_item = match_player_from[0]
					elif match_room_from.size() > 0:
						first_item = match_room_from[0]
						taken_from_room = true
					
					var from_item = first_item
					if from_item != null:
						# now we have the object we want to take from
						# now we need to find the object we want to take
						var match_items = self.get_items_by_keyword(from_item.params.get_value("info","uid"),get_what)
						if match_items.size() > 0:
							var take_item = match_items[0]							
							outmsg += "You get " + take_item.params.get_value("info","title") + " from " + from_item.params.get_value("info","title") + "\r\n"
							take_item.params.set_value("owner","uid",user.params.get_value("info","uid"))
						else:
							outmsg += "You don't see that here."
					else:
						outmsg += "You don't see that here."
					

				else:
					# Handle 'get <object_to_get>' command
					var match_items = self.get_items_by_keyword(the_room.params.get_value("info","uid"),params)
					
					if match_items.size() > 0:
						# todo: just select first item otherwise we will always pick up all the objects
						for item in match_items:
							var user_uid 	= user.params.get_value("info","uid")


							# TODO: ADD DOOR LOGIC TO GET ALL AND DROP/DROP ALL
							# - PROCESS A GAME OBJECT THAT EXISTS IN TWO ROOMS AT THE SAME TIME
							# handle door if we are picking up from a room
							# - get opposite door's object
### BEGIN :: HANDLE DOOR
							# var to_uid 		= item.params.get_value("to","uid")
							# var owner_uid 	= item.params.get_value("owner","uid")
							# var room_uid 	= the_room.params.get_value("info","uid")

							# if to_uid != null:
							# 	print("item is a door.")
							# 	var store_uid = ""
							# 	if room_uid == owner_uid:
							# 		# store destination id
							# 		store_uid = to_uid
							# 	else:
							# 		store_uid = owner_uid

							# 	item.params.set_value("old","uid", store_uid)
							# 	item.params.set_value("to","uid", "-1")
							self.process_door_get(item, the_room) # replaced code with function
### END :: HANDLE DOOR
								# when we drop this item, 
								# we have to check whether to,uid is set to -1, and if it is
								# we have to switch the old,uid to to,uid
								# and set the info,uid to room uid

							
							### END :: HANDLE DOOR
							
							# we need to switch owner uid to player
							outmsg += "You get " + item.params.get_value("info","title") + "\r\n"
							item.params.set_value("owner","uid",user_uid)
					else:
						outmsg += "You don't see that here."
					
				pass # get

			"tell":
				var r = self.one_arg(params)
				var who_name = r[0]
				var tell_what = r[1]
				
				var src_user = user
				var tgt_username = who_name
				var msg = tell_what
				
				var dest_user = self.get_user_by_username(tgt_username)
				print(dest_user)

				if dest_user == null:
					outmsg += "Tell who?"
					print("no user found")
					#return false
				else:
					outmsg +=  "You tell "+tgt_username+", '" + msg + "'"
					self.do_tell(src_user, dest_user, msg)
					self.prompt(dest_user)
				pass


		self.send(user, outmsg)
		pass

	func do_tell(src_user, tgt_user, msg):
		var src_username = src_user.params.get_value("info","username")
		self.send(tgt_user, src_username + " tells you '" + msg + "' ")
		var cur_room_vnum = src_user.params.get_value("vnum","cur")
		
		var room_msg = ""
		# if both are in same room, say who it is player is telling something to
		if src_user.params.get_value("vnum","cur") == tgt_user.params.get_value("vnum","cur"):
			room_msg = src_username + " tells " + tgt_user.params.get_value("info","username") + " something."
		else:
			room_msg = src_username + " tells someone something."
		
		var other_users = self.get_users_room_ignore([src_user,tgt_user],cur_room_vnum)
		for ou in other_users:
			self.send(ou, room_msg)
			self.prompt(ou)
		pass
	
	func do_say(src_user,msg):
		var src_username = src_user.params.get_value("info","username")
		var cur_room_vnum = src_user.params.get_value("vnum","cur")
		var other_users = self.get_users_room_ignore([src_user],cur_room_vnum)

		var room_msg = src_username+" says '" + msg + "'"
		for ou in other_users:
			self.send(ou, room_msg)
			self.prompt(ou)
		pass

	func do_shout(src_user,msg):
		var src_username = src_user.params.get_value("info","username")
		var other_users = self.get_users_world_ignore([src_user])

		var room_msg = src_username+" shouts '" + msg + "'"
		for ou in other_users:
			self.send(ou, room_msg)
			self.prompt(ou)
		pass


	func do_look(src_user,vnum):
		var the_room = self.get_room_by_vnum(vnum)
		var room_users = self.get_users_by_vnum(vnum)
		var the_exits = the_room.params.get_subkey("exit")
		var outmsg = ""
		
		outmsg += the_room.params.get_value("info","title")+"\r\n\n"
		outmsg += the_room.params.get_value("info","description")+"\r\n"

		outmsg += "\r\nExits: "
		if the_exits:
			for key in the_exits.keys():
				# exit_desc
				outmsg += key + " "
		outmsg += "\r\n"

		outmsg += "\r\n"


		# go though global.g_items and show all items matching a uid on owner,uid param
		outmsg += "\r\nItems: \r\n"
		#print(self.globals.g_items)
		var items = self.get_items(the_room.params.get_value("info","uid"))
		for item in items:
			outmsg += item.params.get_value("info","title") + ", "
		
		outmsg += "\r\n"

		outmsg += "\r\nUsers in room:\r\n"
		for u in room_users:
			outmsg += str(u.params.get_value("info","username"))+","

		
		# find mobs in room
		var mobs = self.get_mobs_by_vnum(vnum)
		print("finding mobs...")
		for m in self.globals.g_mobs:
			print("mob rvnum:",m.params.get_value("info","vnum"))
			if m.params.get_value("vnum","cur") == vnum:
				outmsg += m.params.get_value("info","title") + ", "
		
		self.send(src_user, outmsg)
		self.prompt(src_user)
#### END CLASS

### MAIN() 
var game

func _ready():
	test_2key()
	test_2keyflags()
	
	init_globals()
	
	var globals = {}
	globals.g_items_proto = g_items_proto
	globals.g_items = g_items
	globals.g_world = g_world
	globals.g_areas = g_areas
	globals.g_rooms = g_rooms
	globals.g_mobs_proto = g_mobs_proto
	globals.g_mobs 	= g_mobs
		
	game = game_app.new(globals)
	game.create_server(3500)
	game.create_server(3600)	
	
	
func _process(delta):
	game.server_loop()
	game.game_loop() # game ai movement, weather
	game.action_loop() # combat
	
