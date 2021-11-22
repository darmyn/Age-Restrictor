local Players = game:GetService("Players")

local AgeRestrictionWhitelist = require(script.Parent.AgeRestrictionWhitelist)
local AgeRestrictor = require(script.AgeRestrictor)

local GAME_MINUMUM_AGE_REQUIREMENT = 5000 -- in days
local EVALUATION_RESULT_TYPES = AgeRestrictor.enums.evaluationResultTypes

local GameAgeRestrictor = AgeRestrictor.new(GAME_MINUMUM_AGE_REQUIREMENT, AgeRestrictionWhitelist)

local function setFFlags()
	AgeRestrictor.fflags.verifyUserIDsCorrespondToAnAccount = true
	AgeRestrictor.fflags.verifyWhitelistedUserIDsHaveUpdatedName = false
end

local function connectPlayer(player)
	print("New user connected to server: ".. player.Name)
	local resultType, reasonForExemption = GameAgeRestrictor:evaluate(player)
	if resultType == EVALUATION_RESULT_TYPES.passed then
		print("Age Requirement Met: User meets the minimum age requirement for this experience.")
	elseif resultType == EVALUATION_RESULT_TYPES.exempted then
		warn("Age Requirement Exemption Notice: User `"..player.Name.."` has been exempt from the games age requirements.")
		warn("Reason: "..reasonForExemption)
	elseif resultType == EVALUATION_RESULT_TYPES.failed then
		player:Kick("this experience is meant for accounts created over "..GAME_MINUMUM_AGE_REQUIREMENT.." days ago.")
		warn("Age Requirement Failed: User has been removed from the server.")
	end
end

local function connectPlayersThatLoadedBeforeSystemsReady()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(connectPlayer, player)
	end
end

local function connectMainSignals()
	Players.PlayerAdded:Connect(connectPlayer)
end

do
	setFFlags()
	connectPlayersThatLoadedBeforeSystemsReady()
	connectMainSignals()
end
