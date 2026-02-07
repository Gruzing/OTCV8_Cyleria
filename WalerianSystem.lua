-- Walerian System z UI MonsterKill
setDefaultTab("Own")

-- === KONFIGURACJA ===
local wsPanelname = "WalerianSystem"

-- Inicjalizacja storage UI
if not storage[wsPanelname] then 
    storage[wsPanelname] = { min = false } 
end

-- Inicjalizacja storage Danych
if not storage.Walerian then
    warn("[Walerian] Brak danych. Czekam na wiadomosc startowa lub o zabiciu potwora.")
end

-- === UI (Wygląd z Monster Kill) ===
local walerianPanel = setupUI([[
Panel
  margin-top: 5
  height: 115
  
  Button
    id: resetList
    anchors.left: parent.left
    anchors.top: parent.top
    width: 20
    height: 17
    margin-top: 2
    margin-left: 3
    text: !
    color: red
    tooltip: Resetuj Dane Misji

  Button
    id: showList
    anchors.right: parent.right
    anchors.top: parent.top
    width: 20
    height: 17
    margin-top: 2
    margin-right: 3
    text: -
    color: red
    tooltip: Minimalizuj

  Label
    id: title
    text: 
    text-align: center
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 14
    font: verdana-11px-rounded
    color: #FFA500

    id: contentBg
    image-source: /images/ui/menubox
    image-border: 4
    image-border-top: 17
    anchors.top: showList.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 5
    height: 88
    padding: 5
    vertical-scrollbar: mkScroll
    layout:
      type: verticalBox
    
    Label
      id: lblMission
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      text-align: center
      font: verdana-11px-bold
      margin-top: 5
      text: Misja: Brak

    Label
      id: lblMob
      anchors.top: prev.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      text-align: center
      margin-top: 5
      color: #aaaaaa
      text: Cel: -

    Label
      id: lblProgress
      anchors.top: prev.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      text-align: center
      margin-top: 5
      font: verdana-11px-bold
      color: #ffffff
      text: 0 / 0

    Label
      id: lblPercent
      anchors.top: prev.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      text-align: center
      margin-top: 5
      color: orange
      text: 0%

]], parent)

walerianPanel:setId(wsPanelname)

-- === FUNKCJE UI ===

local function toggleWin(load)
    if load then
        walerianPanel:setHeight(22)
       -- walerianPanel.contentBg:setVisible(false)
        walerianPanel.showList:setText("+")
        walerianPanel.showList:setColor("green")
    else
        walerianPanel:setHeight(115)
       -- walerianPanel.contentBg:setVisible(true)
        walerianPanel.showList:setText("-")
        walerianPanel.showList:setColor("red")
    end
end

local function refreshPanel()
    local bg = walerianPanel.contentBg
    
    if not storage.Walerian then
        bg.lblMission:setText("Misja: Brak")
        bg.lblMob:setText("Czekam na info...")
        bg.lblProgress:setText("")
        bg.lblPercent:setText("")
        return
    end

    local s = storage.Walerian
    local percent = 0
    if s.ToKill and s.ToKill > 0 then
        percent = math.floor((s.Killed / s.ToKill) * 100)
    end
    
    local nrMisji = (s.NumerMisji and s.NumerMisji > 0) and s.NumerMisji or "?"
    
    bg.lblMission:setText("Misja: " .. nrMisji)
    bg.lblMob:setText("Cel: " .. (s.MobName or "Nieznany"))
    bg.lblProgress:setText(s.Killed .. " / " .. s.ToKill)
    bg.lblPercent:setText(percent .. "%")

    -- Kolorowanie po zakończeniu
    if s.Killed >= s.ToKill then
        bg.lblProgress:setColor("#00FF00") -- Zielony
        bg.lblPercent:setColor("#00FF00")
    else
        bg.lblProgress:setColor("#FFFFFF") -- Biały
        bg.lblPercent:setColor("orange")
    end
end

-- Obsługa przycisków
walerianPanel.showList.onClick = function(widget)
    storage[wsPanelname].min = not storage[wsPanelname].min
    toggleWin(storage[wsPanelname].min)
end

walerianPanel.resetList.onClick = function(widget)
    -- Resetuje tylko lokalne wyświetlanie, chyba że chcesz zresetować też logikę bota
    storage.Walerian = nil
    print("[Walerian] Dane zresetowane ręcznie.")
    refreshPanel()
end

-- Przywrócenie stanu okna po relogu
toggleWin(storage[wsPanelname].min)
refreshPanel()

-- === LOGIKA SYSTEMU (Zachowana z drugiego skryptu) ===

-- Funkcja sprawdzająca (do Auto-Powrotu)
function checkReturnLogic()
  if storage.Walerian and storage.Walerian.ToKill > 0 then
      if storage.Walerian.Killed >= storage.Walerian.ToKill then
        -- Opcjonalnie: Unikaj spamu w konsoli sprawdzając czy już nie wracamy
        -- print("[Walerian Check] Zabito wymagana ilosc. Wracam.") 
        CaveBot.gotoLabel("Wyjscie")
      else
        CaveBot.gotoLabel("startHunt")
      end
  end
end

-- Makro odświeżające UI co 200ms
macro(200, function() 
    refreshPanel() 
end)

-- === OBSŁUGA ONTALK ===
onTalk(function(name, level, mode, text, channelId, pos)
    
    -- 1. LICZNIK ZABIĆ (Channel ID 13 - Server Log/Info)
    -- Wzorzec: "Walerian: Pokonales [(*)/(**)] potworow w misji: (***)."
    if channelId == 13 then
        local killed, toKill, mobName = text:match("Walerian: Pokonales %[(%d+)/(%d+)%] potworow w misji: (.+)%.")
        
        if killed then
            local k = tonumber(killed)
            local t = tonumber(toKill)

            if not storage.Walerian then
                storage.Walerian = {
                    NumerMisji = 0, -- Nie znamy numeru z tej wiadomosci
                    MobName = mobName,
                    ToKill = t,
                    Killed = k
                }
            else
                storage.Walerian.Killed = k
                storage.Walerian.ToKill = t
                storage.Walerian.MobName = mobName
            end
            
            refreshPanel() -- Odśwież UI natychmiast po zabiciu
            
            if storage.Walerian.Killed >= storage.Walerian.ToKill then
                print("[Walerian] Limit osiagniety ("..k.."/"..t..").")
               -- checkReturnLogic() -- Wywołaj powrót
            end
            return
        end
    end

    -- 2. START MISJI (Od NPC)
    local mID, mCount, mName = text:match("Rozpoczales wlasnie misje numer (%d+), teraz musisz zabic (%d+) (.+)%.")
    if mID and mCount and mName then
        storage.Walerian = {
            NumerMisji = tonumber(mID),
            MobName = mName,
            ToKill = tonumber(mCount),
            Killed = 0
        }
        
        print("[Walerian] Start misji nr " .. mID .. ": " .. mName)
        refreshPanel()
        
        local cfgName = "Walerian_" .. mID
        -- Sprawdzenie czy config istnieje w liście (zabezpieczenie)
        if storage._configs.cavebot_configs then
             storage._configs.cavebot_configs.selected = cfgName
             storage._configs.cavebot_configs.enabled = true
        end
        
        CaveBot.setOff()
        schedule(1500, function()
            CaveBot.setOn()
            CaveBot.delay(2000)
         end)
            
        if CaveBot.getCurrentProfile and CaveBot.getCurrentProfile(cfgName) then
            print("[Walerian] Zaladowano config: " .. cfgName)
        end
        return
    end

    -- 3. ZAKOŃCZENIE MISJI (Od NPC)
    if text:find("Udalo sie! Ukonczyles wlasnie misje numer") and text:find("Dobra robota") then
        print("[Walerian] Misja oddana. Resetuje i biore nowa.")
        
        storage.Walerian = nil
        refreshPanel()
        
        schedule(1000, function()
          CaveBot.Conversation("hi", "misja")
        end)
    end
end)


--[[
Co zostało zrobione:
UI: Zamiast prostego przezroczystego tekstu, masz teraz panel z pierwszego skryptu:
Przycisk ! (Resetuje dane wyświetlania).
Przycisk - / + (Zwija i rozwija okienko).
Ramka graficzna (/images/ui/menubox).
Logika: Zachowałem całą logikę onTalk z drugiego skryptu:
Automatyczne wykrywanie postępu (Channel 13).
Automatyczna zmiana profilu CaveBota po wzięciu misji.
Automatyczne oddawanie misji ("hi", "misja") po zakończeniu.
Optymalizacja: Zamiast listy potworów (ScrollablePanel z pierwszego skryptu), wstawiłem statyczne etykiety (Misja, Cel, Ilość, %), ponieważ system Waleriana obsługuje jedną misję na raz, co wygląda czytelniej.
]]-- 
