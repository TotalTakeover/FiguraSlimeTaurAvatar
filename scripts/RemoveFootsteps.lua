function events.ON_PLAY_SOUND(id, pos, vol, pitch, loop, cat, path)
	
	-- Don't trigger if the sound was played by Figura (prevent potential infinite loop)
	if not path then return end
	
	-- Don't do anything if the user isn't loaded
	if not player:isLoaded() then return end
	
	-- Make sure the sound is (most likely) played by the user
	if (player:getPos() - pos):length() > 0.05 then return end
	
	-- If sound contains ".step", ".fall", ".big_fall", or ".small_fall", stop the sound
	if id:find(".step") or id:find(".fall") or id:find(".big_fall") or id:find(".small_fall") then return true end
	
end