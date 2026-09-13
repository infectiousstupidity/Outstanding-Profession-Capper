local addonTable={}
assert(loadfile("RecipeDifficulty.lua"))("Profession_Capper",addonTable)
assert(loadfile("RecipeDifficultyData.lua"))("Profession_Capper",addonTable)
assert(loadfile("RecipeCatalog.lua"))("Profession_Capper",addonTable)
assert(loadfile("RecipeCatalogData.lua"))("Profession_Capper",addonTable)
local c=addonTable.getRecipeCatalogCoverage(); assert(c.total==3552,"catalog size"); assert(c.optimizerEligible>=3235,"difficulty coverage")
for _,p in ipairs({"Alchemy","Blacksmithing","Enchanting","Engineering","Inscription","Jewelcrafting","Leatherworking","Tailoring","Cooking","First Aid"}) do assert(c.professions[p] and c.professions[p].total>0,"missing "..p) end
local x=addonTable.getRecipeCatalogRecord(3275); assert(x and x.profession=="First Aid" and x.reagents[1].itemID==2589,"classic fixture"); assert(addonTable.getRecipeCatalogRecord(56004).profession=="Tailoring","wrath fixture")
local input=addonTable.buildRecipeCatalogInput("First Aid",{[3275]={name="Localized Linen",reagents={}}}); local known,unknown=false,false; for i=1,table.getn(input) do if input[i].spellID==3275 then known=input[i].learned and input[i].name=="Localized Linen" and table.getn(input[i].reagents)>0 end; if input[i].spellID==3276 then unknown=input[i].learned==false end end; assert(known and unknown,"overlay/unknown behavior")
local ok=pcall(addonTable.registerRecipeCatalogRecord,{spellID=3275,profession="First Aid",name="x",requiredSkill=1,reagents={}}); assert(not ok,"duplicate accepted"); print("Recipe catalog tests passed.")
