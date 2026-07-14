local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

-- POPRAWIONY LINK: Dodaliśmy "stats/" przed nickiem gracza
local FIREBASE_URL = "https://stattrack-1eff0-default-rtdb.firebaseio.com/stats/" .. localPlayer.Name .. ".json"

local Library = require(ReplicatedStorage:WaitForChild("Library"))
local SaveModule = Library.Save

local function sendDataToFirebase()
    local playerData = SaveModule.Get(localPlayer)
    if not playerData or not playerData.Inventory then return end

    local hugeCount = 0
    local titanicCount = 0
    local diamondsCount = playerData.Diamonds or 0

    local petInventory = playerData.Inventory.Pet
    if petInventory then
        for _, petData in pairs(petInventory) do
            local petId = petData.id
            if petId then
                if string.find(string.lower(petId), "huge") then
                    hugeCount = hugeCount + (petData._am or 1)
                elseif string.find(string.lower(petId), "titanic") then
                    titanicCount = titanicCount + (petData._am or 1)
                end
            end
        end
    end

    local payload = {
        username = localPlayer.Name,
        hugePets = hugeCount,
        titanicPets = titanicCount,
        diamonds = diamondsCount
    }

    -- Uniwersalne żądanie dla różnych executorów (Xeno / Potassium / i inne)
    local requestFunction = request or http_request or (syn and syn.request)

    if requestFunction then
        local success, response = pcall(function()
            return requestFunction({
                Url = FIREBASE_URL,
                Method = "PUT",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = game:GetService("HttpService"):JSONEncode(payload)
            })
        end)

        if success then
            print("Zaktualizowano konto " .. localPlayer.Name .. " w Firebase!")
        else
            warn("Błąd wysyłania konta " .. localPlayer.Name .. ":", response)
        end
    else
        warn("Twój executor nie obsługuje wysyłania żądań HTTP!")
    end
end

-- Wysyłanie co 10 sekund
task.spawn(function()
    while task.wait(10) do
        sendDataToFirebase()
    end
end)

sendDataToFirebase()
