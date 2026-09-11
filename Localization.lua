local addonName, addonTable = ...

local L = {}
addonTable.L = L

local function applyEnglish()
    L["craft_button"] = "Craft (%d)"
    L["craft_button_unavail"] = "Unavailable"
    L["not_learned"] = "Not learned or unavailable"
    L["profession_cap"] = "Profession cap reached"
    L["recipe_prefix"] = "Materials: "
    L["unknown_recipe_prefix"] = "Recipe: "
    L["header_label"] = "Profession Capper"
    L["loaded_for"] = "[Profession Capper] loaded for"
    L["crafting"] = "[Profession Capper] crafting"
    L["train_profession"] = "Train the next profession rank to continue"
    L["no_guide_step"] = "No guide step is available for this skill level"
    L["profession_progress"] = "%s  %d / %d"
    L["target_line"] = "Skill %d → %d"
    L["stats_exact"] = "Need: %d skill-ups · Can: %d · Crafts: %d"
    L["stats_minimum"] = "Need: %d skill-ups · Can: %d · Crafts: at least %d"
    L["stats_unlearned"] = "Need: %d skill-ups"
    L["eta_exact"] = "Estimated time: %s"
    L["eta_minimum"] = "Minimum time: %s"
    L["eta_unavailable"] = "Estimated time: unavailable"
    L["craft_to"] = "Craft to %d"
    L["continue_to"] = "Continue to %d"
    L["crafting_button"] = "Crafting..."
    L["craft_progress"] = "Crafting %d/%d · ~%s left"
    L["craft_progress_no_eta"] = "Crafting %d/%d"
    L["craft_batch_done"] = "Batch complete · %d skill-ups still needed"
    L["target_reached"] = "Target reached"
    L["recipe_position"] = "%d / %d"
end

local function applySpanish()
    L["craft_button"] = "Fabricar (%d)"
    L["craft_button_unavail"] = "No disponible"
    L["not_learned"] = "No aprendida o no disponible"
    L["profession_cap"] = "Nivel máximo de profesión alcanzado"
    L["recipe_prefix"] = "Materiales: "
    L["unknown_recipe_prefix"] = "Receta: "
    L["loaded_for"] = "[Profession Capper] cargado para"
    L["crafting"] = "[Profession Capper] fabricando"
    L["train_profession"] = "Entrena el siguiente rango de profesión para continuar"
    L["no_guide_step"] = "No hay un paso de guía para este nivel"
    L["target_line"] = "Habilidad %d → %d"
    L["stats_exact"] = "Faltan: %d puntos · Puedes: %d · Fabricaciones: %d"
    L["stats_minimum"] = "Faltan: %d puntos · Puedes: %d · Fabricaciones: al menos %d"
    L["stats_unlearned"] = "Faltan: %d puntos"
    L["eta_exact"] = "Tiempo estimado: %s"
    L["eta_minimum"] = "Tiempo mínimo: %s"
    L["eta_unavailable"] = "Tiempo estimado: no disponible"
    L["craft_to"] = "Fabricar hasta %d"
    L["continue_to"] = "Continuar hasta %d"
    L["crafting_button"] = "Fabricando..."
    L["craft_progress"] = "Fabricando %d/%d · ~%s restantes"
    L["craft_progress_no_eta"] = "Fabricando %d/%d"
    L["craft_batch_done"] = "Lote terminado · faltan %d puntos"
    L["target_reached"] = "Objetivo alcanzado"
end

local function applyRussian()
    L["craft_button"] = "Изготовить (%d)"
    L["craft_button_unavail"] = "Недоступно"
    L["not_learned"] = "Не изучен или недоступен"
    L["profession_cap"] = "Достигнут максимум профессии"
    L["recipe_prefix"] = "Материалы: "
    L["unknown_recipe_prefix"] = "Рецепт: "
    L["loaded_for"] = "[Profession Capper] загружен для"
    L["crafting"] = "[Profession Capper] изготовление"
    L["train_profession"] = "Изучите следующий ранг профессии, чтобы продолжить"
    L["no_guide_step"] = "Для этого уровня навыка нет шага руководства"
    L["target_line"] = "Навык %d → %d"
    L["stats_exact"] = "Нужно: %d очк. · Можно: %d · Создать: %d"
    L["stats_minimum"] = "Нужно: %d очк. · Можно: %d · Создать: минимум %d"
    L["stats_unlearned"] = "Нужно: %d очк."
    L["eta_exact"] = "Примерное время: %s"
    L["eta_minimum"] = "Минимальное время: %s"
    L["eta_unavailable"] = "Примерное время: недоступно"
    L["craft_to"] = "Создать до %d"
    L["continue_to"] = "Продолжить до %d"
    L["crafting_button"] = "Создание..."
    L["craft_progress"] = "Создание %d/%d · ~%s осталось"
    L["craft_progress_no_eta"] = "Создание %d/%d"
    L["craft_batch_done"] = "Партия завершена · осталось %d очк."
    L["target_reached"] = "Цель достигнута"
end

function addonTable.applyLocale()
    applyEnglish()

    local locale = GetLocale()
    if locale == "esES" or locale == "esMX" then
        applySpanish()
    elseif locale == "ruRU" then
        applyRussian()
    end

    if addonTable.applyRecipeLocale then
        addonTable.applyRecipeLocale()
    end
end
