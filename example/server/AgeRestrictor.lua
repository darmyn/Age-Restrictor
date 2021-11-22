
local Players = game:GetService("Players")

-- reusable phrases for system output
local EXPECTED_GOT_STATEMENT = "Expected `%s` representing `%s` got '%s'."
local MISSING_ARGUMENT_ERROR = "Missing argument @ position %d. "..EXPECTED_GOT_STATEMENT
local INCORRECT_ARGUMENT_TYPE_ERROR  = "Incorrect type passed to argument @ position %d. "..EXPECTED_GOT_STATEMENT
local UNEXPECTED_ARGUMENT_VALUE_ERROR = "Unexpected value passed to argument @ position %d. "..EXPECTED_GOT_STATEMENT

-- standard enum for nice code structure (gets exported to use scope as well).
local RANK_WHITELIST_TYPES = {
	includeHigherRanks = "includeHigherRanks",
	onlyIncludedRanks = "onlyIncludedRanks",
	inBetweenRanks = "inBetweenRanks",
}
local EVALUATION_RESULT_TYPES = {
	passed = "passed",
	failed = "failed",
	exempted = "exempted"
}

local function createTableAndCopyKeyValuePairsFromTableMaintainingNestStructure(t)
	local copy = {}
	for k, v in pairs(t) do
		if typeof(v) == "table" then
			copy[k] = createTableAndCopyKeyValuePairsFromTableMaintainingNestStructure(v)
		else
			copy[k] = v
		end
	end
	return copy
end

local function isPlayerExemptFromAgeThresholdDueToGroupRelationsMatchingWhitelist(player, groupIDWhitelist)
	for groupId, groupData in pairs(groupIDWhitelist) do
		local plrRankInGroup = player:GetRankInGroup(groupId)
		local rankWhitelists = groupData.rankWhitelists
		if rankWhitelists then
			for _, whitelist in ipairs(rankWhitelists) do
				if whitelist.type == RANK_WHITELIST_TYPES.includeHigherRanks then
					if plrRankInGroup >= whitelist.value then
						return true
					end
				elseif whitelist.type == RANK_WHITELIST_TYPES.onlyIncludedRanks then
					if table.find(whitelist.value, plrRankInGroup) then
						return true
					end
				elseif whitelist.type == RANK_WHITELIST_TYPES.inBetweenRanks then
					if plrRankInGroup >= whitelist.value.min and plrRankInGroup <= whitelist.value.max then
						return true
					end
				end
			end
		else
			if plrRankInGroup > 0 then
				return true
			end
		end
	end
end

local AgeRestrictor = {}
AgeRestrictor.__index = AgeRestrictor
AgeRestrictor.enums = {rankWhitelistTypes=RANK_WHITELIST_TYPES, evaluationResultTypes=EVALUATION_RESULT_TYPES}
AgeRestrictor.fflags = {verifyUserIDsCorrespondToAnAccount=true, verifyWhitelistedUserIDsHaveUpdatedName=false}

function AgeRestrictor.new(minimumAccountAge, whitelist)
	local self = setmetatable({}, AgeRestrictor)
	self:setMinimumAccountAge(minimumAccountAge)
	self:_setWhitelist(whitelist)
	return self
end

function AgeRestrictor:evaluate(player)
	if player.AccountAge < self._minimumAccountAge then
		local whitelist = self._whitelist
		if whitelist then
			if whitelist.userIDs then
				if whitelist.userIDs[player.UserId] then
					return EVALUATION_RESULT_TYPES.exempted, "UserId was whitelisted."
				end
			end
			if whitelist.groupIDs then
				if isPlayerExemptFromAgeThresholdDueToGroupRelationsMatchingWhitelist(player, whitelist.groupIDs) then
					return EVALUATION_RESULT_TYPES.exempted, "Group Relations"
				end
			end
		end
		return EVALUATION_RESULT_TYPES.failed
	else
		return EVALUATION_RESULT_TYPES.passed
	end
end

function AgeRestrictor:setMinimumAccountAge(minimumAccountAge)
	assert(minimumAccountAge, (MISSING_ARGUMENT_ERROR):format(1, "number", "minimumAccountAge", "nil"))
	assert(typeof(minimumAccountAge) == "number", (INCORRECT_ARGUMENT_TYPE_ERROR):format(1, 'number', 'minimumAccountAge', typeof(minimumAccountAge)))
	assert(minimumAccountAge > 0, (UNEXPECTED_ARGUMENT_VALUE_ERROR):format(1, "number", "minimumAccountAge", "number, but number was not greater than 0."))
	self._minimumAccountAge = minimumAccountAge
end

function AgeRestrictor:_setWhitelist(whitelist)
	if whitelist then
		whitelist = createTableAndCopyKeyValuePairsFromTableMaintainingNestStructure(whitelist) --> we block the possibility of module user corrupting their whitelist at runtime, since `whitelist` is a user generated table.
		assert(typeof(whitelist) == "table", (INCORRECT_ARGUMENT_TYPE_ERROR):format(1, "table", "whitelist", typeof(whitelist)))
		local userIDs = whitelist.userIDs
		local groupIDs = whitelist.groupIDs
		if userIDs then
			assert(typeof(userIDs) == "table", (UNEXPECTED_ARGUMENT_VALUE_ERROR):format(1, "table", "whitelist", "table, but key `userIDs` value is not a table, got `"..typeof(userIDs).."`."))
			for userID, userName in pairs(userIDs) do
				assert(typeof(userID) == "number", (UNEXPECTED_ARGUMENT_VALUE_ERROR):format(1, "table", "whitelist", "table, but value of key `userIDs` should be a dictionary "))
				local verifyUserIDsCorrespondToAnAccount = AgeRestrictor.fflags.verifyUserIDsCorrespondToAnAccount
				local verifyWhitelistedUserIDsHaveUpdatedName = AgeRestrictor.fflags.verifyWhitelistedUserIDsHaveUpdatedName
				if verifyUserIDsCorrespondToAnAccount or verifyWhitelistedUserIDsHaveUpdatedName then
					local success, result = pcall(Players.GetNameFromUserIdAsync, Players, userID)
					if verifyUserIDsCorrespondToAnAccount then
						assert(success, "[FFLAG FAILED] Could not find account matching UserID. \n\n [ERROR]: "..result)
					end
					if verifyWhitelistedUserIDsHaveUpdatedName then
						assert((success and result == userName), "[FFLAG FAILED] Name corresponding to UserID does not match account name. \n\n Actual Name: "..result.." Expected Name: "..userName)
					end
				end
			end
		end
		if groupIDs then
			assert(typeof(groupIDs) == "table", (UNEXPECTED_ARGUMENT_VALUE_ERROR):format(1, "table", "whitelist", "table, but key `groupIDs` value is not a table, got `"..typeof(groupIDs).."`."))
            -- strict mode for this data not finished
		end
		self._whitelist = whitelist
	end
end

return AgeRestrictor