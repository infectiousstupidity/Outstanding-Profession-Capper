local addonName, addonTable = ...
local bySpell,byProfession={},{}
addonTable.recipeCatalogBySpell,addonTable.recipeCatalogByProfession=bySpell,byProfession
local function positive(v) v=tonumber(v); if v and v>0 then return v end end
local function shallow(t) local o={}; if type(t)=="table" then for k,v in pairs(t) do o[k]=v end end; return o end
function addonTable.validateRecipeCatalogRecord(r)
 if type(r)~="table" then return false,"record_not_table" end
 if not positive(r.spellID or r.recipeID) then return false,"missing_spell_id" end
 if type(r.profession)~="string" or r.profession=="" then return false,"missing_profession" end
 if type(r.name)~="string" or r.name=="" then return false,"missing_name" end
 local req=tonumber(r.requiredSkill); if not req or req<0 or req>450 then return false,"invalid_required_skill" end
 if type(r.reagents)~="table" then return false,"missing_reagents" end
 for i=1,table.getn(r.reagents) do local x=r.reagents[i]; if type(x)~="table" or not positive(x.itemID) or not positive(x.count) then return false,"invalid_reagent" end end
 if r.outputItemID~=nil and not positive(r.outputItemID) then return false,"invalid_output_item" end
 if r.outputQuantity~=nil and not positive(r.outputQuantity) then return false,"invalid_output_quantity" end
 if r.recipeItemID~=nil and not positive(r.recipeItemID) then return false,"invalid_recipe_item" end
 return true
end
function addonTable.registerRecipeCatalogRecord(r)
 local ok,why=addonTable.validateRecipeCatalogRecord(r); if not ok then error("Invalid recipe catalog record: "..tostring(why)) end
 local id=tonumber(r.spellID or r.recipeID); if bySpell[id] then error("Duplicate recipe catalog spell ID: "..tostring(id)) end
 local c=shallow(r); c.spellID=id; c.outputQuantity=tonumber(c.outputQuantity) or 1; c.reagents={}; for i=1,table.getn(r.reagents) do local x=r.reagents[i]; c.reagents[i]={itemID=tonumber(x.itemID),count=tonumber(x.count),name=x.name} end
 bySpell[id]=c; byProfession[c.profession]=byProfession[c.profession] or {}; table.insert(byProfession[c.profession],c); return c
end
function addonTable.registerRecipeCatalogBatch(rows) if type(rows)~="table" then error("Recipe catalog batch must be a table") end; for i=1,table.getn(rows) do addonTable.registerRecipeCatalogRecord(rows[i]) end end
function addonTable.getRecipeCatalogRecord(v) local id=v; if type(v)=="table" then id=v.spellID or v.recipeID end; id=tonumber(id); return id and bySpell[id] or nil end
function addonTable.getRecipeCatalogRecipes(p) local src,out=byProfession[p] or {},{}; for i=1,table.getn(src) do out[i]=src[i] end; return out end
function addonTable.overlayLiveRecipe(s,l)
 local r=shallow(s); if type(l)=="table" then for k,v in pairs(l) do if v~=nil then r[k]=v end end end; r.spellID=tonumber(r.spellID or r.recipeID); r.catalogRecord=s; r.learned=type(l)=="table"
 if s and type(s.reagents)=="table" and (type(l)~="table" or type(l.reagents)~="table" or table.getn(l.reagents)==0) then r.reagents=s.reagents end
 r.name=r.name or (r.spellID and ("Spell "..tostring(r.spellID))) or "Unknown recipe"; return r
end
function addonTable.buildRecipeCatalogInput(p,live)
 local out,rows={},addonTable.getRecipeCatalogRecipes(p); live=type(live)=="table" and live or {}; for i=1,table.getn(rows) do local s=rows[i]; out[i]=addonTable.overlayLiveRecipe(s,live[s.spellID] or live[tostring(s.spellID)]) end; return out
end
function addonTable.getRecipeCatalogCoverage()
 local total,eligible,prof=0,0,{}; for p,rows in pairs(byProfession) do local pe=0; for i=1,table.getn(rows) do total=total+1; if type(addonTable.isRecipeEligibleForDynamicOptimization)=="function" then local ok=addonTable.isRecipeEligibleForDynamicOptimization(rows[i].spellID); if ok then pe=pe+1; eligible=eligible+1 end end end; prof[p]={total=table.getn(rows),optimizerEligible=pe} end; return {total=total,optimizerEligible=eligible,professions=prof}
end
