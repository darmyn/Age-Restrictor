local AccountAgeLimiter = require(script.Parent.Parent.Server.AgeLimiter)

local RANK_WHITELIST_TYPES = AccountAgeLimiter.enums.rankWhitelistTypes

return {
	[4720804] = {
		name = "Realm Of Enia",
		rankWhitelists = {
			{
				type = RANK_WHITELIST_TYPES.inBetweenRanks,
				value = {min=40, max=180}
			}
		}
	},	
}