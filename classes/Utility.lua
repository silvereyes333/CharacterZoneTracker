--[[ 
    ===================================
            UTILITY FUNCTIONS
    ===================================
  ]]
  
local addon = CharacterZoneTracker
local debug = false

-- STATIC CLASS
addon.Utility = ZO_Object:Subclass()

--[[ Outputs formatted message to chat window if debugging is turned on ]]
function addon.Utility.Debug(output, force)
    if not force and not addon.debugMode then
        return
    end
    addon.Utility.Print(output)
end

function addon.Utility.CartesianDistance2D(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Returns the Levenshtein distance between the two given strings
-- Full credit to Badgerati (Matthew Kelley)
-- https://gist.github.com/Badgerati/3261142
function addon.Utility.Levenshtein(str1, str2)
	local len1 = string.len(str1)
	local len2 = string.len(str2)
	local matrix = {}
	local cost = 0
	
        -- quick cut-offs to save time
	if (len1 == 0) then
		return len2
	elseif (len2 == 0) then
		return len1
	elseif (str1 == str2) then
		return 0
	end
	
        -- initialise the base matrix values
	for i = 0, len1, 1 do
		matrix[i] = {}
		matrix[i][0] = i
	end
	for j = 0, len2, 1 do
		matrix[0][j] = j
	end
	
        -- actual Levenshtein algorithm
	for i = 1, len1, 1 do
		for j = 1, len2, 1 do
			if (str1:byte(i) == str2:byte(j)) then
				cost = 0
			else
				cost = 1
			end
			
			matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
		end
	end
	
        -- return the last value - this is the Levenshtein distance
	return matrix[len1][len2]
end

--[[ Outputs formatted message to chat window ]]
function addon.Utility.Print(output)
    if addon.Chat then
        addon.Chat:Print(output)
    else
        d(output)
    end
end