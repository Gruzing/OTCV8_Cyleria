-- Walerian System v1.0
-- === KONFIGURACJA HUD ===
local hudConfig = {
    pos = {x = 60, y = 200}, 
    textColor = "#FFFFFF",
    doneColor = "#00FF00",
    title = "[Walerian Task]"
}

-- === INICJALIZACJA ===
if not storage.Walerian then
    warn("[Walerian] Brak danych. Czekam na wiadomosc startowa lub o zabiciu potwora.")
end

-- Definicja UI (HUD)
local ui = setupUI([[
Panel
  id: walerianPanel
  height: 80
  width: 250
  anchors.top: parent.top
  anchors.left: parent.left
  margin-top: ]] .. hudConfig.pos.y .. [[
  margin-left: ]] .. hudConfig.pos.x .. [[
  background-color: #00000088
  border: 1 #ffffff

  Label
    id: title
    text: ]] .. hudConfig.title .. [[
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 3
    color: #FFA500
    font: verdana-11px-rounded

  Label
    id: info
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    text-align: center
    text-offset: 0 -5
    color: #ffffff
    font: verdana-11px-rounded
]], modules.game_interface.getMapPanel())

-- Funkcja aktualizująca HUD
local function updateHud()
    local panel = ui
    local label = panel:recursiveGetChildById('info')
    
    if not storage.Walerian then
        label:setText("\nBrak aktywnej misji")
        label:setColor("gray")
        return
    end

    local s = storage.Walerian
    local percent = 0
    if s.ToKill and s.ToKill > 0 then
        percent = math.floor((s.Killed / s.ToKill) * 100)
    end

    -- Jesli misja odtworzona z chatu (brak ID), wyswietl "?"
    local nrMisji = (s.NumerMisji and s.NumerMisji > 0) and s.NumerMisji or "?"

    label:setText(string.format("\nMisja: %s\nCel: %s\nPostep: %d / %d (%d%%)", 
        nrMisji, s.MobName, s.Killed, s.ToKill, percent))

    if s.Killed >= s.ToKill then
        label:setColor(hudConfig.doneColor)
    else
        label:setColor(hudConfig.textColor)
    end
end
function checkKill()
  if storage.Walerian.Killed >= storage.Walerian.ToKill then
    print("[Walerian Check] Zabito wymagana ilosc. Wracam.")
    CaveBot.gotoLabel("Wyjscie")
    else
      CaveBot.gotoLabel("startHunt")
  end
end

macro(200, function() updateHud() end)

-- === OBSŁUGA onTalk ===
onTalk(function(name, level, mode, text, channelId, pos)
    
    -- 1. LICZNIK ZABIĆ + AUTO-TWORZENIE storage (Channel ID 13)
    -- Wzorzec: "Walerian: Pokonales [(*)/(**)] potworow w misji: (***)."
    if channelId == 13 then
        local killed, toKill, mobName = text:match("Walerian: Pokonales %[(%d+)/(%d+)%] potworow w misji: (.+)%.")
        
        if killed then
            local k = tonumber(killed)
            local t = tonumber(toKill)

            -- LOGIKA: Jesli storage nie istnieje, stworz je teraz
            if not storage.Walerian then
                print("[Walerian] Wykryto postep bez aktywnego storage. Tworzenie danych...")
                storage.Walerian = {
                    NumerMisji = 0, -- Nie znamy numeru z tej wiadomosci
                    MobName = mobName,
                    ToKill = t,
                    Killed = k
                }
            else
                -- Jesli istnieje, po prostu aktualizuj
                storage.Walerian.Killed = k
                storage.Walerian.ToKill = t
                storage.Walerian.MobName = mobName
            end

            -- Sprawdzenie powrotu
            if storage.Walerian.Killed >= storage.Walerian.ToKill then
                print("[Walerian] Limit osiagniety ("..k.."/"..t..").")
                --CaveBot.gotoLabel("Wyjscie")
            end
            return
        end
    end

    -- 2. START MISJI (Od NPC)
    -- Wzorzec: "Rozpoczales wlasnie misje numer (*), teraz musisz zabic (**) (***)."
    -- Wzorzec 2: "Aktualnie wykonujesz zadanie: (***), czyli misja numer (*). Jesli zabiles juz wymagana ilosc zdaj mi raport."
    local mID, mCount, mName = text:match("Rozpoczales wlasnie misje numer (%d+), teraz musisz zabic (%d+) (.+)%.")
    if mID and mCount and mName then
        storage.Walerian = {
            NumerMisji = tonumber(mID),
            MobName = mName,
            ToKill = tonumber(mCount),
            Killed = 0
        }
        
        print("[Walerian] Start misji nr " .. mID .. ": " .. mName)
        
        local cfgName = "Walerian_" .. mID
        if CaveBot.setCurrentProfile(cfgName) then
            print("[Walerian] Zaladowano config: " .. cfgName)
        else
            warn("[Walerian] Brak configu: " .. cfgName)
        end
        return
    end

    -- 3. ZAKOŃCZENIE MISJI (Od NPC)
    -- Wzorzec: "Udalo sie! Ukonczyles wlasnie misje numer..."
    -- Wzorzec 2: "Zabiles (****) (***). Zdaj raport jak usmiercisz (**)."
    if text:find("Udalo sie! Ukonczyles wlasnie misje numer") and text:find("Dobra robota") then
        print("[Walerian] Misja oddana. Resetuje i biore nowa.")
        
        storage.Walerian = nil
        schedule(1000, function()
          CaveBot.Conversation("hi", "misja")
        end)
    end
end)

