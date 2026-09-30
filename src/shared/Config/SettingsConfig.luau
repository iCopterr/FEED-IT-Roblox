local defaults=table.freeze({MusicVolume=1,SFXVolume=1,ShowOwnPets=true,ShowOtherPets=true})
local Config={Defaults=defaults}
function Config.Valid(key,value)
	if defaults[key]==nil then return false end
	if type(defaults[key])=="boolean" then return type(value)=="boolean" end
	return type(value)=="number" and value==value and value>=0 and value<=1
end
function Config.Read(saved)
	local result=table.clone(defaults)
	for key in defaults do if Config.Valid(key,saved[key]) then result[key]=saved[key] end end
	return result
end
return table.freeze(Config)
