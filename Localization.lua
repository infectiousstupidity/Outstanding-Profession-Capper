local addonName, addonTable = ...

local L = {}
addonTable.L = L

local function applyEnglish()
    L["craft_button"] = "Craft (%d)"
    L["craft_button_unavail"] = "Unavailable"
    L["not_learned"] = "Recipe not learned"
    L["profession_cap"] = "Profession cap reached"
    L["recipe_prefix"] = "Materials: "
    L["unknown_recipe_prefix"] = "Recipe: "
    L["header_label"] = "Profession Capper"
    L["loaded_for"] = "[Profession Capper] loaded for"
    L["crafting"] = "[Profession Capper] crafting"
    L["train_profession"] = "Train the next profession rank to continue"
    L["no_guide_step"] = "No guide step is available for this skill level"
    L["profession_progress"] = "%s  %d / %d"
    L["target_line"] = "Skill %d -> %d"
    L["stats_exact"] = "Need: %s  |  Can: %d  |  Crafts: %d"
    L["stats_minimum"] = "Need: %s  |  Can: %d  |  Crafts: at least %d"
    L["stats_unlearned"] = "Need: %s"
    L["eta_exact"] = "Estimated time: %s"
    L["eta_minimum"] = "Minimum time: %s"
    L["eta_unavailable"] = "Estimated time: unavailable"
    L["craft_to"] = "Craft to %d"
    L["continue_to"] = "Continue to %d"
    L["crafting_button"] = "Crafting..."
    L["craft_progress"] = "Crafting %d/%d  |  ~%s left"
    L["craft_progress_no_eta"] = "Crafting %d/%d"
    L["craft_batch_done"] = "Batch complete  |  %s still needed"
    L["target_reached"] = "Target reached"
    L["recipe_position"] = "%d / %d"
    L["skill_up_one"] = "1 skill-up"
    L["skill_up_many"] = "%d skill-ups"
    L["recipe_not_learned"] = "Recipe not learned"
    L["missing_materials"] = "Missing materials"
    L["materials_label"] = "Materials"
    L["material_tooltip_hint"] = "Shift-Right-Click: put this item in the Auction House search"
    L["auction_house_not_open"] = "Open the Auction House browse tab first"
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
    L["target_line"] = "Habilidad %d -> %d"
    L["stats_exact"] = "Faltan: %s  |  Puedes: %d  |  Fabricaciones: %d"
    L["stats_minimum"] = "Faltan: %s  |  Puedes: %d  |  Fabricaciones: al menos %d"
    L["stats_unlearned"] = "Faltan: %s"
    L["eta_exact"] = "Tiempo estimado: %s"
    L["eta_minimum"] = "Tiempo mínimo: %s"
    L["eta_unavailable"] = "Tiempo estimado: no disponible"
    L["craft_to"] = "Fabricar hasta %d"
    L["continue_to"] = "Continuar hasta %d"
    L["crafting_button"] = "Fabricando..."
    L["craft_progress"] = "Fabricando %d/%d · ~%s restantes"
    L["craft_progress_no_eta"] = "Fabricando %d/%d"
    L["craft_batch_done"] = "Lote terminado  |  faltan %s"
    L["target_reached"] = "Objetivo alcanzado"
    L["skill_up_one"] = "1 punto"
    L["skill_up_many"] = "%d puntos"
    L["recipe_not_learned"] = "Receta no aprendida"
    L["missing_materials"] = "Faltan materiales"
    L["materials_label"] = "Materiales"
    L["material_tooltip_hint"] = "Mayús-Clic derecho: poner este objeto en la búsqueda de la Casa de Subastas"
    L["auction_house_not_open"] = "Abre primero la pestaña de búsqueda de la Casa de Subastas"
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
    L["target_line"] = "Навык %d -> %d"
    L["stats_exact"] = "Нужно: %s  |  Можно: %d  |  Создать: %d"
    L["stats_minimum"] = "Нужно: %s  |  Можно: %d  |  Создать: минимум %d"
    L["stats_unlearned"] = "Нужно: %s"
    L["eta_exact"] = "Примерное время: %s"
    L["eta_minimum"] = "Минимальное время: %s"
    L["eta_unavailable"] = "Примерное время: недоступно"
    L["craft_to"] = "Создать до %d"
    L["continue_to"] = "Продолжить до %d"
    L["crafting_button"] = "Создание..."
    L["craft_progress"] = "Создание %d/%d · ~%s осталось"
    L["craft_progress_no_eta"] = "Создание %d/%d"
    L["craft_batch_done"] = "Партия завершена  |  осталось %s"
    L["target_reached"] = "Цель достигнута"
    L["skill_up_one"] = "1 очко"
    L["skill_up_many"] = "%d очк."
    L["recipe_not_learned"] = "Рецепт не изучен"
    L["missing_materials"] = "Не хватает материалов"
    L["materials_label"] = "Материалы"
    L["material_tooltip_hint"] = "Shift-ПКМ: вставить предмет в поиск аукциона"
    L["auction_house_not_open"] = "Сначала откройте вкладку поиска аукциона"
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
