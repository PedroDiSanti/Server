local cfg = {
    chance = 8,            -- chance that the player will succeed in getting the ore
    skill = SKILL_AXE,      -- skill required to mine
    skillStr = ' axe',      -- string for skill name | note: add a space before skill name
    stage2Regen = 3 * 1000, -- 3 seconds
    stage3Regen = 2 * 1000, -- 2 seconds
    ores = {
        {effect = CONST_ME_BLOCKHIT, ore = 5880, amount = {1, 3}, skillReq = 10, veins = {
                {id = 5709, lv = 50},
                {id = 5708, lv = 75},
                {id = 5707, lv = 100}
            }
        },
        {effect = CONST_ME_BLOCKHIT, ore = 5880, amount = {1, 3}, skillReq = 10, veins = {
                {id = 5868, lv = 50},
                {id = 5866, lv = 75},
                {id = 5867, lv = 100}
            }
        },
        {effect = CONST_ME_BLOCKHIT, ore = 5880, amount = {1, 3}, skillReq = 10, veins = {
                {id = 5750, lv = 50},
                {id = 5751, lv = 75},
                {id = 5752, lv = 100}
            }
        },
        {effect = CONST_ME_BLOCKHIT, ore = 5880, amount = {1, 3}, skillReq = 10, veins = {
                {id = 5619, lv = 50},
                {id = 5620, lv = 75},
                {id = 5621, lv = 100}
            }
        },
        {effect = CONST_ME_BLOCKHIT, ore = 5880, amount = {1, 3}, skillReq = 10, veins = {
                {id = 8633, lv = 50},
                {id = 8637, lv = 75}
            }
        },
        {effect = CONST_ME_BLOCKHIT, ore = 5880, amount = {1, 3}, skillReq = 10, veins = {
                {id = 8634, lv = 50},
                {id = 8638, lv = 75}
            }
        },
        {effect = CONST_ME_BLOCKHIT, ore = 5880, amount = {1, 3}, skillReq = 10, veins = {
                {id = 8635, lv = 50},
                {id = 8639, lv = 75}
            }
        },
        {effect = CONST_ME_BLOCKHIT, ore = 5880, amount = {1, 3}, skillReq = 10, veins = {
                {id = 8636, lv = 50},
                {id = 8640, lv = 75}
            }
        }
    }
}
 
local function isInTable(value)
    for i = 1, #cfg.ores do
        for j = 1, #cfg.ores[i].veins do
            if cfg.ores[i].veins[j].id == value then
                return i, j -- Return ore row and vein index
            end
        end
    end
    return false
end
 
local regenerating = {}
 
local function regenVein(pos, id, row, index)
    local item = Tile(pos):getItemById(id)
    if not item then
        return false
    end
    local currVein = cfg.ores[row].veins
    local transformId = currVein[index].id
    item:transform(transformId)
    if currVein[index-1] and currVein[index-1].id then
        regenerating[pos] = addEvent(regenVein, cfg.stage3Regen, pos, transformId, row, index-1)
    end
end
 
 
function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local row, vein = isInTable(target:getId())
    if (row and vein) then
        local playerPos = player:getPosition()
        local currOre = cfg.ores[row]
        local currVein = currOre.veins[vein]
        local skillLevel = player:getSkillLevel(cfg.skill)
 
        -- Check player skill level
        if not (skillLevel >= currOre.skillReq) then
            player:sendTextMessage(MESSAGE_STATUS_SMALL, 'You must have '.. currOre.skillReq .. cfg.skillStr ..' before you may mine.')
            return true
        end
         
        -- Check player level
        if not (player:getLevel() >= currVein.lv) then
            player:sendTextMessage(MESSAGE_STATUS_SMALL, 'You must have '.. cfg.level ..' level before you may mine.')
            return true
        end
 
        -- If the vein is at the last stage, tell the player to wait
        if #currOre.veins == vein then
            player:sendTextMessage(MESSAGE_STATUS_SMALL, 'You must wait for this vein to regen.')
            playerPos:sendMagicEffect(CONST_ME_POFF)
            return true
        end
 
        -- Stop current regeneration process (since the player hit the rock again)
        if regenerating[toPosition] then
            stopEvent(regenerating[toPosition])
        end
 
        -- If chance is correct, add the item to the player and start regeneration process
        if math.random(100) <= (cfg.chance + skillLevel/2) then
            local nextId = currOre.veins[vein+1].id
            local it = player:addItem(currOre.ore, math.random(currOre.amount[1], currOre.amount[2]))
            local count = it:getCount()
            local name = count > 1 and it:getPluralName() or it:getName()
            player:sendTextMessage(MESSAGE_STATUS_SMALL, 'You have mined '.. count .. ' '.. name)
            player:addSkillTries(cfg.skill, math.random(3000, 5000) / skillLevel)
            toPosition:sendMagicEffect(currOre.effect)
            regenerating[toPosition] = addEvent(regenVein, (vein == 2) and cfg.stage2Regen or cfg.stage3Regen, toPosition, nextId, row, vein)
            target:transform(nextId)
        else
            playerPos:sendMagicEffect(CONST_ME_POFF)
        end
 
    end
    return true
end