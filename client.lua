local transformed = false
local originalModel = nil

-- =========================
-- モデル読み込み
-- =========================
local function LoadModel(model)
    local hash = type(model) == "number" and model or GetHashKey(model)

    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
    end

    return hash
end

-- =========================
-- 共通：アイテム処理関数
-- =========================
local function UseAnimalPotion(data, animalModel)
    if transformed then
        lib.notify({ description = 'すでに変身中です', type = 'error' })
        return
    end

    exports.ox_inventory:useItem(data, function(success)
        if success then
            TransformToAnimal(animalModel)
        end
    end)
end

-- =========================
-- 猫
-- =========================
exports('cat_potion', function(data, slot)
    UseAnimalPotion(data, "a_c_cat_01")
end)

-- =========================
-- コヨーテ
-- =========================
exports('coyote_potion', function(data, slot)
    UseAnimalPotion(data, "a_c_coyote")
end)

-- =========================
-- ネズミ
-- =========================
exports('rat_potion', function(data, slot)
    UseAnimalPotion(data, "a_c_rat")
end)

-- =========================
-- ライオン
-- =========================
exports('lion_potion', function(data, slot)
    UseAnimalPotion(data, "a_c_mtlion")
end)

-- =========================
-- 鹿
-- =========================
exports('deer_potion', function(data, slot)
    UseAnimalPotion(data, "a_c_deer")
end)

-- =========================
-- チンパンジー
-- =========================
exports('chimp_potion', function(data, slot)
    UseAnimalPotion(data, "a_c_chimp")
end)

-- =========================
-- 犬
-- =========================
exports('dog_potion', function(data, slot)
    local dogs = {
        "a_c_shepherd",
        "a_c_rottweiler",
        "a_c_husky",
        "a_c_poodle",
        "a_c_pug",
        "a_c_retriever",
        "a_c_chop"
    }
    local randomDog = dogs[math.random(#dogs)]
    UseAnimalPotion(data, randomDog)
end)

-- =========================
-- 農場
-- =========================
exports('farm_potion', function(data, slot)
    local farmAnimals = {
        "a_c_cow",
        "a_c_pig",
        "a_c_hen"
    }
    local randomAnimal = farmAnimals[math.random(#farmAnimals)]
    UseAnimalPotion(data, randomAnimal)
end)

-- =========================
-- 変身処理
-- =========================
function TransformToAnimal(animalModel)
    local player = PlayerPedId()

    originalModel = GetEntityModel(player)

    local model = LoadModel(animalModel)

    SetPlayerModel(PlayerId(), model)
    SetPedDefaultComponentVariation(PlayerPedId())
    SetModelAsNoLongerNeeded(model)

    transformed = true

    lib.notify({
        description = '動物に変身しました！',
        type = 'success'
    })

    StartRestrictionThread()
    StartSoundThread()

    -- config時間で解除
    SetTimeout(Config.TransformTime, function()
        if transformed then
            RevertToHuman()
        end
    end)
end

-- =========================
-- 元に戻す
-- =========================
function RevertToHuman()
    if not transformed then return end
    transformed = false

    RequestModel(originalModel)
    while not HasModelLoaded(originalModel) do Wait(10) end

    SetPlayerModel(PlayerId(), originalModel)
    SetModelAsNoLongerNeeded(originalModel)

    Wait(200)

    -- ★ ここが重要
    TriggerServerEvent('qb-clothes:loadPlayerSkin')

    lib.notify({
        description = '元の姿に戻りました。',
        type = 'inform'
    })
end

-- =========================
-- 武器＆車禁止
-- =========================
function StartRestrictionThread()
    CreateThread(function()
        while transformed do
            Wait(0)

            local player = PlayerPedId()

            DisablePlayerFiring(PlayerId(), true)
            SetCurrentPedWeapon(player, `WEAPON_UNARMED`, true)

            if IsPedInAnyVehicle(player, false) then
                TaskLeaveVehicle(player, GetVehiclePedIsIn(player, false), 16)
                Wait(1000)
            end
        end
    end)
end

-- =========================
-- 鳴き声
-- =========================
function StartSoundThread()
    CreateThread(function()
        while transformed do
            Wait(Config.SoundInterval)
            PlayAmbientSpeech1(PlayerPedId(), "GENERIC_HI", "SPEECH_PARAMS_FORCE")
        end
    end)
end

-- 死亡解除
AddEventHandler('baseevents:onPlayerDied', function()
    if transformed then
        RevertToHuman()
    end
end)