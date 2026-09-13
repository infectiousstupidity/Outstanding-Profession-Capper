local addonTable = {}
assert(loadfile("RouteSolver.lua"))("Profession_Capper", addonTable)

local function eq(actual, expected, label)
    if actual ~= expected then error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual))) end
end

local recipes = {{ id = "A" }, { id = "B" }}
local function globalFixture(recipe, skill, context, state)
    if recipe.id == "A" and skill > 0 then return { available=false,useful=false,incomplete=false,unavailableReason="gray_recipe" } end
    local oneTime = {}
    if recipe.id == "B" and not (state.acquiredOneTime and state.acquiredOneTime["recipe:B"]) then
        oneTime = {{ key="recipe:B",kind="recipe_acquisition",marketCost=5,goldCost=5 }}
    end
    return { available=true,useful=true,expectedCraftsPerSkillUp=1,expectedMarketCostPerSkillUp=recipe.id=="A" and 2 or 1,expectedGoldNeededNowPerSkillUp=recipe.id=="A" and 2 or 1,expectedCurrentPurchaseCostPerSkillUp=recipe.id=="A" and 2 or 1,oneTimeCosts=oneTime,quality="complete",skillUpChance=1 }
end
local global=addonTable.solveCheapestProfessionRoute(recipes,nil,{currentCap=3},{startSkill=0,targetSkill=3,costRecipe=globalFixture})
eq(global.complete,true,"global route complete"); eq(global.actions[1].recipeID,"B","global avoids greedy"); eq(global.totalMarketCost,8,"one-time acquisition")

local trained=addonTable.solveCheapestProfessionRoute({{id="base"},{id="future"}},nil,{currentCap=1},{
 startSkill=0,targetSkill=3,
 trainingSteps={{key="rank",atSkill=1,newCap=3,status="trainable",goldCost=5}},
 costRecipe=function(recipe,skill)
  if recipe.id=="future" and skill<1 then return {available=false,useful=false,incomplete=false} end
  local n=recipe.id=="future" and 1 or 2
  return {available=true,useful=true,expectedCraftsPerSkillUp=1,expectedMarketCostPerSkillUp=n,expectedGoldNeededNowPerSkillUp=n,expectedCurrentPurchaseCostPerSkillUp=n,oneTimeCosts={},quality="complete",skillUpChance=1}
 end
})
eq(trained.complete,true,"training route complete"); eq(trained.actions[2].type,"training","training gate inserted"); eq(trained.actions[3].recipeID,"future","future recipe after training")

local modifierRecipes={{id="cheap-without-modifier"},{id="modifier-route"}}
local function modifierFixture(recipe,skill,context)
 local mod=context and context.activeSkillModifier or 0
 if recipe.id=="cheap-without-modifier" and mod>0 then return {available=false,useful=false,incomplete=false} end
 local n=recipe.id=="modifier-route" and 3 or 1
 return {available=true,useful=true,expectedCraftsPerSkillUp=1,expectedMarketCostPerSkillUp=n,expectedGoldNeededNowPerSkillUp=n,expectedCurrentPurchaseCostPerSkillUp=n,oneTimeCosts={},quality="complete",skillUpChance=1}
end
local noMod=addonTable.solveCheapestProfessionRoute(modifierRecipes,{activeSkillModifier=0},{currentCap=1},{startSkill=0,targetSkill=1,costRecipe=modifierFixture})
eq(noMod.actions[1].recipeID,"cheap-without-modifier","no modifier")
local withMod=addonTable.solveCheapestProfessionRoute(modifierRecipes,{activeSkillModifier=10},{currentCap=1},{startSkill=0,targetSkill=1,costRecipe=modifierFixture})
eq(withMod.actions[1].recipeID,"modifier-route","modifier changes route")

local bounded=addonTable.solveCheapestProfessionRoute({{id="bounded"}},nil,{currentCap=100},{startSkill=0,targetSkill=100,maxStates=2,costRecipe=function()
 return {available=true,useful=true,expectedCraftsPerSkillUp=1,expectedMarketCostPerSkillUp=1,expectedGoldNeededNowPerSkillUp=1,expectedCurrentPurchaseCostPerSkillUp=1,oneTimeCosts={},quality="complete"}
end})
eq(bounded.complete,false,"state bound"); eq(bounded.reason,"state_limit_exceeded","state bound reason")
print("Cheapest route solver tests passed.")
