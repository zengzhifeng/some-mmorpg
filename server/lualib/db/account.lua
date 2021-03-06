local constant = require "constant"
local srp = require "srp"


local account = {}
local connection_handler
local id_handler

function account.init (ch, ih)
	connection_handler = ch
	id_handler = ih
end

local function make_key (name)
	return connection_handler (name), string.format ("user:%s", name)
end

function account.load (name)
	assert (name)

	local acc = { name = name }

	local connection, key = make_key (name)
	if connection:exists (key) then
		acc.id = connection:hget (key, "account")
		acc.salt = connection:hget (key, "salt")
		acc.verifier = connection:hget (key, "verifier")
	else
		acc.salt, acc.verifier = srp.create_verifier (name, constant.default_password)
	end

	return acc
end

function account.create (name, password)
	assert (name and #name < 24 and password and #password < 24)
	
	local id = id_handler ()
	local connection, key = make_key (name)
	assert (connection:hsetnx (key, "account", id) ~= 0)

	local salt, verifier = srp.create_verifier (name, password)
	assert (connection:hmset (key, "salt", salt, "verifier", verifier) ~= 0)

	return id
end

return account
