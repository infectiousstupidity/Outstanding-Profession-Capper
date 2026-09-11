local addonName, addonTable = ...

local metadata = {}
addonTable.recipeDifficultyMetadata = metadata

local function number(value)
    value = tonumber(value)
    if value then
        return value
    end
    return nil
end

local function effectiveSkillFor(baseSkill, skillContext)
    if type(addonTable.getEffectiveSkillForBase) == "function" then
        return addonTable.getEffectiveSkillForBase(baseSkill, skillContext)
    end
    local modifier = skillContext and tonumber(skillContext.activeSkillModifier) or 0
    return (tonumber(baseSkill) or 0) + (modifier or 0)
end

function addonTable.validateRecipeDifficultyMetadata(entry)
    if type(entry) ~= "table" then
        return false, "metadata_not_table"
    end

    local spellID = number(entry.spellID or entry.recipeID)
    local required = number(entry.requiredSkill or entry.learnSkill)
    local orange = number(entry.orangeSkill or entry.orange)
    local yellow = number(entry.yellowSkill or entry.yellow)
    local green = number(entry.greenSkill or entry.green)
    local gray = number(entry.graySkill or entry.gray)

    if not spellID or spellID <= 0 then
        return false, "missing_spell_id"
    end
    if type(entry.profession) ~= "string" or entry.profession == "" then
        return false, "missing_profession"
    end
    if not required or not orange or not yellow or not green or not gray then
        return false, "missing_threshold"
    end
    if required < 0 or orange < 0 or yellow < 0 or green < 0 or gray < 0 then
        return false, "negative_threshold"
    end
    if required > orange or orange > yellow or yellow > green or green > gray then
        return false, "non_monotonic_thresholds"
    end

    return true
end

function addonTable.registerRecipeDifficultyMetadata(entry)
    local valid, reason = addonTable.validateRecipeDifficultyMetadata(entry)
    if not valid then
        error("Invalid recipe difficulty metadata: " .. tostring(reason))
    end

    local spellID = tonumber(entry.spellID or entry.recipeID)
    metadata[spellID] = {
        spellID = spellID,
        profession = entry.profession,
        requiredSkill = tonumber(entry.requiredSkill or entry.learnSkill),
        orangeSkill = tonumber(entry.orangeSkill or entry.orange),
        yellowSkill = tonumber(entry.yellowSkill or entry.yellow),
        greenSkill = tonumber(entry.greenSkill or entry.green),
        graySkill = tonumber(entry.graySkill or entry.gray),
        source = entry.source,
    }
    return metadata[spellID]
end

function addonTable.getRecipeDifficultyMetadata(recipeOrSpellID)
    local spellID = recipeOrSpellID
    if type(recipeOrSpellID) == "table" then
        spellID = recipeOrSpellID.spellID or recipeOrSpellID.recipeID
    end
    spellID = tonumber(spellID)
    if not spellID then
        return nil
    end
    return metadata[spellID]
end

function addonTable.isRecipeEligibleForDynamicOptimization(recipeOrSpellID)
    local entry = addonTable.getRecipeDifficultyMetadata(recipeOrSpellID)
    if not entry then
        return false, "missing_difficulty_metadata"
    end
    local valid, reason = addonTable.validateRecipeDifficultyMetadata(entry)
    if not valid then
        return false, reason
    end
    return true
end

function addonTable.evaluateRecipeDifficulty(recipeOrSpellID, baseSkill, skillContext)
    local entry = addonTable.getRecipeDifficultyMetadata(recipeOrSpellID)
    if not entry then
        return {
            metadataKnown = false,
            eligible = false,
            available = false,
            canSkillUp = false,
            guaranteedSkillUp = false,
            reason = "missing_difficulty_metadata",
        }
    end

    local base = tonumber(baseSkill)
    if base == nil and type(skillContext) == "table" then
        base = tonumber(skillContext.baseSkill)
    end
    base = base or 0

    local effective = effectiveSkillFor(base, skillContext)
    local modifier = effective - base

    local result = {
        metadataKnown = true,
        eligible = true,
        available = true,
        canSkillUp = false,
        guaranteedSkillUp = false,
        spellID = entry.spellID,
        profession = entry.profession,
        baseSkill = base,
        effectiveSkill = effective,
        activeSkillModifier = modifier,
        requiredSkill = entry.requiredSkill,
        orangeSkill = entry.orangeSkill,
        yellowSkill = entry.yellowSkill,
        greenSkill = entry.greenSkill,
        graySkill = entry.graySkill,
        displayedThresholds = {
            orange = entry.orangeSkill + modifier,
            yellow = entry.yellowSkill + modifier,
            green = entry.greenSkill + modifier,
            gray = entry.graySkill + modifier,
        },
        source = entry.source,
    }

    -- +profession modifiers affect whether the character meets a recipe's skill
    -- requirement, but skill-up color/chance follows the underlying trained/base
    -- skill. This is why a +10 character sees the color transitions at displayed
    -- values ten points higher without consuming ten real skill points.
    if effective < entry.requiredSkill then
        result.available = false
        result.color = "unavailable"
        result.skillUpChance = 0
        result.reason = "required_skill_not_met"
        return result
    end

    if base >= entry.graySkill then
        result.color = "gray"
        result.skillUpChance = 0
        result.reason = "gray_recipe"
        return result
    end

    if base < entry.yellowSkill then
        result.color = "orange"
        result.skillUpChance = 1
        result.canSkillUp = true
        result.guaranteedSkillUp = true
        return result
    end

    local denominator = entry.graySkill - entry.yellowSkill
    if denominator <= 0 then
        result.available = false
        result.eligible = false
        result.reason = "invalid_difficulty_metadata"
        return result
    end

    local chance = (entry.graySkill - base) / denominator
    if chance < 0 then
        chance = 0
    elseif chance > 1 then
        chance = 1
    end

    if base < entry.greenSkill then
        result.color = "yellow"
    else
        result.color = "green"
    end
    result.skillUpChance = chance
    result.canSkillUp = chance > 0
    result.guaranteedSkillUp = chance >= 1
    return result
end
