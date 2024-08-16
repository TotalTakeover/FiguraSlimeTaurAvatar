--		Wobble Library v2.0.1 by:
	
--		   _______           __                           _           
--	      / ____(_)_________/ /__  ____ ___  ____ _____  (_)___ ______
--		 / /   / / ___/ ___/ / _ \/ __ `__ \/ __ `/ __ \/ / __ `/ ___/
--		/ /___/ / /  / /__/ /  __/ / / / / / /_/ / / / / / /_/ / /__  
--		\____/_/_/   \___/_/\___/_/ /_/ /_/\__,_/_/ /_/_/\__,_/\___/  

--		Credit to GNamimates for library reference (GN's Trail Library)

--		Library that makes values follow a different value in a way that would make it look wobbly (aka a Wobble Value™)
--      using an equation written by Roter Zwerg.



local lib = {}
local wobbles = {}

-----------------------| API |-----------------------

---A Wobble Value™ with its own separate config like dampening, speed etc.
---@class wobbleSetup
---@field wobble number The Wobble Value™
---@field wobbleVel number The Wobble Value™'s velocity
---@field wobbleAccel number The Wobble Value™'s velocity's velocity
---@field s number The Wobble Value™'s wobble speed
---@field d number The Wobble Value™'s wobble dampener
local wobbleSetup = {}
wobbleSetup.__index = wobbleSetup




local wobbleID = 0

---Creates a new Wobble Setup.
---@return wobbleSetup
function lib:newWobbleSetup()
    ---@type wobbleSetup
    local compose = {
        wobble = 0,
        wobbleVel = 0,
        wobbleAccel = 0,
        s = 0.1,
        d = 0.1
    }
    wobbleID = wobbleID + 1
    setmetatable(compose,wobbleSetup)
    table.insert(wobbles,compose)
    return compose
end

---Updates the Wobble Value™ with its Wobble Setup.
---@param a number The Value that b follows
---@param fpsDependant boolean Whether or not to be dependant of framerate or not (completely resets wobble on <30 FPS due to it breaking) (nil - false)
function wobbleSetup:update(a,fpsDependant)
    if fpsDependant then
        if client:getFPS() >= 30 then
            self.wobbleAccel = self.s * (a - self.wobble) - self.d * self.wobbleVel
            self.wobbleVel = self.wobbleVel + self.wobbleAccel / (client:getFPS() / 120)
            self.wobble = self.wobble + self.wobbleVel / (client:getFPS() / 120)
        else
            self:setWobble(nil,nil,nil)
        end
    else
        self.wobbleAccel = self.s * (a - self.wobble) - self.d * self.wobbleVel
        self.wobbleVel = self.wobbleVel + self.wobbleAccel
        self.wobble = self.wobble + self.wobbleVel
    end
        return self
end

---Sets the Wobble Value™ and its properties.
---@param a number The Value to instantly set wobble to (nil - 0)
---@param aVel number The Value to instantly set wobblevel to (nil - 0)
---@param aAccel number The Value to instantly set wobbleaccel to (nil - 0)
function wobbleSetup:setWobble(a,aVel,aAccel)
    if aAccel then
        self.wobbleAccel = aAccel
    else
        self.wobbleAccel = 0
    end
    if aVel then
        self.wobbleVel = aVel
    else
        self.wobbleVel = 0
    end
    if a then
        self.wobble = a
    else
        self.wobble = 0
    end
    return self
end

return lib