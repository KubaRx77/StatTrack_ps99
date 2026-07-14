local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

-- Twój link do bazy danych Firebase
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

    local success, response = pcall(function()
        return request({
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
end

-- Wysyłanie co 10 sekund
task.spawn(function()
    while task.wait(10) do
        sendDataToFirebase()
    end
end)

sendDataToFirebase()
