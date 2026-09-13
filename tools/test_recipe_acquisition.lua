local addonTable={}
addonTable.getEffectiveSkillForBase=function(base,ctx) return (tonumber(base) or 0)+((ctx and tonumber(ctx.activeSkillModifier)) or 0) end
assert(loadfile("RecipeDifficulty.lua"))("Profession_Capper",addonTable)
assert(loadfile("RecipeDifficultyData.lua"))("Profession_Capper",addonTable)
assert(loadfile("RecipeCatalog.lua"))("Profession_Capper",addonTable)
assert(loadfile("RecipeCatalogData.lua"))("Profession_Capper",addonTable)
assert(loadfile("RecipeAcquisition.lua"))("Profession_Capper",addonTable)
assert(loadfile("RecipeAcquisitionData.lua"))("Profession_Capper",addonTable)
local coverage=addonTable.getRecipeCatalogCoverage(); local covered=0; local counts={}; local multiple=0
for _,rows in pairs(addonTable.recipeCatalogByProfession) do for i=1,table.getn(rows) do local r=rows[i]; local sources=addonTable.getRecipeAcquisitionRecords(r.spellID); assert(table.getn(sources)>0,"missing acquisition "..r.spellID); covered=covered+1; if table.getn(sources)>1 then multiple=multiple+1 end; for j=1,table.getn(sources) do local s=sources[j]; counts[s.sourceType]=(counts[s.sourceType] or 0)+1; if s.recipeItemID then assert(tonumber(s.recipeItemID)>0,"invalid recipe item") end end end end
assert(covered==coverage.total and covered==3552,"catalog acquisition coverage")
assert((counts.trainer or 0)>1000,"trainer coverage"); assert((counts.vendor or 0)>100,"vendor coverage"); assert((counts.limited_vendor or 0)>0,"limited vendor coverage"); assert((counts.reputation or 0)>0,"reputation coverage"); assert((counts.manual or 0)>0,"explicit manual fallback coverage"); assert(multiple>500,"multi-source coverage")
local trainerSources=addonTable.getRecipeAcquisitionRecords(7420); local trainer
for i=1,table.getn(trainerSources) do if trainerSources[i].sourceType=="trainer" then trainer=trainerSources[i]; break end end
assert(trainer and trainer.purchasePrice==50,"known trainer price")
local resolved=addonTable.resolveRecipeAcquisition(7420,{}, {baseSkill=15,activeSkillModifier=0},{}); assert(resolved.sourceType=="trainer" and resolved.goldCost==50,"compat resolver")
assert(addonTable.recipeAcquisitionProviders==nil,"external acquisition providers must be removed")
local valid,why=addonTable.validateRecipeAcquisitionEntry({spellID=900001,profession="Test",sourceType="limited_vendor",sourceName="Vendor"}); assert(not valid and why=="limited_vendor_requires_stock_flag","limited vendor validation")
valid,why=addonTable.validateRecipeAcquisitionEntry({spellID=900002,profession="Test",sourceType="reputation",sourceName="Quartermaster"}); assert(not valid and why=="invalid_reputation_requirement","reputation validation")
print("Recipe acquisition model and coverage tests passed.")
