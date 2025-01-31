local QuestWaypoints = CreateFrame("Frame","QuestWaypointsMain")

local HBD = LibStub("HereBeDragons-2.0")
local HBDP = LibStub("HereBeDragons-Pins-2.0-QuestWaypoints")

QuestWaypoints:RegisterEvent("ADDON_LOADED")
QuestWaypoints:RegisterEvent("PLAYER_ENTERING_WORLD")
QuestWaypoints:RegisterEvent("QUEST_TURNED_IN")


local playerInstanceID = -1
local customPin = nil

local selectedQuest = {}


QuestWaypoints:SetScript("OnEvent", function(_, event, arg1, arg2,arg3, arg4, arg5)
	if event == "ADDON_LOADED" and arg1 == "QuestWaypoints" then
		QuestWaypoints.Print("Addon loaded.")						
				
		HBDP:setSelectedQuest(selectedQuest)
		-- init world map frames
		CreateFrame("Frame", "QuestWaypointsOverlay", WorldMapFrame.ScrollContainer.Child)
		QuestWaypointsOverlay:SetPoint("TOPLEFT")
		QuestWaypointsOverlay:SetAllPoints()	
		QuestWaypointsOverlay:SetFrameStrata("MEDIUM")
		QuestWaypointsOverlay:SetFrameLevel(2500)
		QuestWaypointsOverlay:SetClipsChildren(true)	
		QuestWaypointsOverlay:Hide()			
		
		CreateFrame("Frame", "QuestWaypointsOverlayPointStart", QuestWaypointsOverlay)
		QuestWaypointsOverlayPointStart:SetSize(1, 1)
		CreateFrame("Frame", "QuestWaypointsOverlayPointEnd", QuestWaypointsOverlay)
		QuestWaypointsOverlayPointEnd:SetSize(1, 1)

		local Line = QuestWaypointsOverlay:CreateLine(nil, "OVERLAY")
		Line:SetTexture("Interface\\AddOns\\QuestWaypoints\\image\\map-line", "REPEAT", "CLAMP")		
		Line:SetThickness(40)
		Line:SetHorizTile(true)
		Line:SetStartPoint("CENTER", QuestWaypointsOverlayPointStart, 0, 0)
		Line:SetEndPoint("CENTER", QuestWaypointsOverlayPointEnd, 0, 0)		
		
		local Icon = CreateFrame("Frame", "QuestWaypointsOverlayIcon", QuestWaypointsOverlay)		
		Icon:SetPoint("CENTER", QuestWaypointsOverlay, "CENTER", 0, 0)	
		Icon:SetHeight(16)
		Icon:SetWidth(16)
		local t = Icon:CreateTexture(nil,"BACKGROUND")
		t:SetTexture("Interface\\MINIMAP\\MapQuestHub_Icon32")
		t:SetAllPoints(Icon)
		Icon.texture = t		
		
		-- init minimap frames
		CreateFrame("Frame", "QuestWaypointsMinimapOverlay", Minimap)
		QuestWaypointsMinimapOverlay:SetPoint("TOPLEFT")
		QuestWaypointsMinimapOverlay:SetAllPoints()	
		QuestWaypointsMinimapOverlay:SetFrameStrata("MEDIUM")
		QuestWaypointsMinimapOverlay:SetFrameLevel(4)
		QuestWaypointsMinimapOverlay:SetClipsChildren(true)		
		QuestWaypointsMinimapOverlay:Hide()				
		
		CreateFrame("Frame", "QuestWaypointsOverlayMinimapPointStart", QuestWaypointsMinimapOverlay)
		QuestWaypointsOverlayMinimapPointStart:SetSize(1, 1)
		CreateFrame("Frame", "QuestWaypointsOverlayMinimapPointEnd", QuestWaypointsMinimapOverlay)
		QuestWaypointsOverlayMinimapPointEnd:SetSize(1, 1)
		
		local Line = QuestWaypointsMinimapOverlay:CreateLine("QuestWaypointsMinimapOverlayArrow", "OVERLAY")		
		Line:SetTexture("Interface\\AddOns\\QuestWaypoints\\image\\arrow", "REPEAT", "CLAMP", "TRILINEAR")
		Line:SetThickness(64)
		Line:SetHorizTile(true)
		Line:SetStartPoint("CENTER", QuestWaypointsOverlayMinimapPointStart, 0, 0)
		Line:SetEndPoint("CENTER", QuestWaypointsOverlayMinimapPointEnd, 0, 0)
		
		local Icon = CreateFrame("Frame", "QuestWaypointsMinimapOverlayIcon", QuestWaypointsMinimapOverlay)		
		Icon:SetPoint("CENTER", QuestWaypointsMinimapOverlay, "CENTER", 0, 0)	
		Icon:SetHeight(16)
		Icon:SetWidth(16)
		local t = Icon:CreateTexture(nil,"BACKGROUND")
		t:SetTexture("Interface\\MINIMAP\\MapQuestHub_Icon32")
		t:SetAllPoints(Icon)
		Icon.texture = t
		Icon:Hide()
		Icon:SetScript("OnEnter", function(self)
			if selectedQuest.questID then
				local questLogIndex = GetQuestLogIndexByID(selectedQuest.questID);
				local title = GetQuestLogTitle(questLogIndex);
				GameTooltip:SetOwner(self, "LEFT", 5, 2);
				GameTooltip:SetText(title);
				QuestUtils_AddQuestTypeToTooltip(GameTooltip, selectedQuest.questID, NORMAL_FONT_COLOR);

				if poiButton and poiButton.style ~= "numeric" then
					local completionText = GetQuestLogCompletionText(questLogIndex) or QUEST_WATCH_QUEST_READY;
					GameTooltip:AddLine(QUEST_DASH..completionText, 1, 1, 1, true);
				else
					local numItemDropTooltips = GetNumQuestItemDrops(questLogIndex);
					if numItemDropTooltips > 0 then
						for i = 1, numItemDropTooltips do
							local text, objectiveType, finished = GetQuestLogItemDrop(i, questLogIndex);
							if ( text and not finished ) then
								GameTooltip:AddLine(QUEST_DASH..text, 1, 1, 1, true);
							end
						end
					else
						local numObjectives = GetNumQuestLeaderBoards(questLogIndex);
						for i = 1, numObjectives do
							local text, objectiveType, finished = GetQuestLogLeaderBoard(i, questLogIndex);
							if ( text and not finished ) then
								GameTooltip:AddLine(QUEST_DASH..text, 1, 1, 1, true);
							end
						end
					end
				end
				GameTooltip:Show();
			end
		end)		
		
		-- quest data provider
		local questDataProvider = CreateFromMixins(QuestDataProviderMixin)
		WorldMapFrame:AddDataProvider(questDataProvider)
		
		hooksecurefunc(questDataProvider, "AddQuest",function(self, questID, x, y, frameLevelOffset)
			if selectedQuest.questID and selectedQuest.questID == questID and selectedQuest.localX ~= x and selectedQuest.localY ~= y then			
				local instanceInfo = C_Map.GetMapInfo(self:GetMap().mapID)				
				-- if dungeon
				if instanceInfo.mapType == 4 then
					QuestWaypoints.Print("Can't track this quest anymore because dungeons are restricted areas for coordinates.")
					QuestWaypoints.RemoveTracking()
					return
				end
				
				local instanceID, worldPosition = C_Map.GetWorldPosFromMapPos(self:GetMap().mapID, {x = x, y = y})
				--print("update data: " .. questID .. " " .. x .. " " .. y) 
				selectedQuest.localX = x
				selectedQuest.localY = y
				selectedQuest.worldX = worldPosition.x
				selectedQuest.worldY = worldPosition.y		
				selectedQuest.mapID = self:GetMap().mapID	
				selectedQuest.continentID = self:GetMap().continentInfo.mapID				
				selectedQuest.instanceID = instanceID

				HBDP:RemoveMinimapIcon('QuestWaypoints', QuestWaypointsMinimapOverlayIcon)
				HBDP:RemoveWorldMapIcon("QuestWaypoints", QuestWaypointsOverlayIcon)
				HBDP:AddMinimapIconMap('QuestWaypoints', QuestWaypointsMinimapOverlayIcon, selectedQuest.mapID, x, y, true, false)				
				HBDP:AddWorldMapIconMap("QuestWaypoints", QuestWaypointsOverlayIcon, self:GetMap().mapID, x, y, HBD_PINS_WORLDMAP_SHOW_CONTINENT, PIN_FRAME_LEVEL_QUEST_BLOB)
				
				customPin:Refresh()
				C_Timer.NewTimer(0, function() 
					QuestWaypoints.UpdateMinimap()
				end)
			end
		end)
				
		-- world map		
		hooksecurefunc(WorldMapFrame, 'OnMapChanged', function(self)
			if selectedQuest.questID == nil then
				return
			end
					
			if self.continentInfo == nil then
				QuestWaypointsOverlay:Hide()
			else
				local mapInstanceID, _ = C_Map.GetWorldPosFromMapPos(WorldMapFrame:GetMapID(), {x = 0, y = 0})
				if mapInstanceID and mapInstanceID == selectedQuest.instanceID and mapInstanceID == playerInstanceID then
					QuestWaypointsOverlay:Show()
				else 
					QuestWaypointsOverlay:Hide()
				end
			end					
		end)
		
		-- select quest if wold map display state changes
		hooksecurefunc(WorldMapFrame, 'SynchronizeDisplayState', function(self)
			if selectedQuest.questID and WorldMapFrame:GetMapID() == selectedQuest.mapID then
				if WorldMapFrame.isMaximized then
					if QuestScrollFrame:IsVisible() then
						QuestMapFrame_ShowQuestDetails(selectedQuest.questID)
					end
				else
					QuestMapFrame_ShowQuestDetails(selectedQuest.questID)
				end
			end
		end)
		
		-- quest world map button
		hooksecurefunc(QuestPinMixin, 'OnAcquired', function(self)
			local pin = self
			local selectedButtonTexture = "Interface\\AddOns\\QuestWaypoints\\image\\ui-questpoi-numbericons"
			C_Timer.NewTimer(0, function() 
				if selectedQuest.questID and pin.questID == selectedQuest.questID then
					pin.Texture:SetSize(89, 90);
					pin.PushedTexture:SetSize(89, 90);
					pin.Highlight:SetSize(89, 90);
					pin.Number:SetSize(74, 74);
					pin.Number:ClearAllPoints();
					pin.Number:SetPoint("CENTER", -1, -1);
					pin.Texture:SetTexture(selectedButtonTexture);
					pin.Texture:SetTexCoord(0.500, 0.625, 0.375, 0.5);
					pin.PushedTexture:SetTexture(selectedButtonTexture);
					pin.PushedTexture:SetTexCoord(0.375, 0.500, 0.375, 0.5);
					if not IsQuestComplete(pin.questID) then
						pin.Number:SetTexture(selectedButtonTexture);
					end
					pin.Number:Show();
					
					local questsOnMap = C_QuestLog.GetQuestsOnMap(WorldMapFrame:GetMapID());
					if questsOnMap then
						for i, info in ipairs(questsOnMap) do
							local poiButton =  QuestPOI_FindButton(QuestScrollFrame.Contents, info.questID);
							if poiButton then
								if poiButton.style == "normal" then
									QuestPOI_UpdateNormalStyleTexture(poiButton)
								elseif poiButton.style == "numeric" then
									QuestPOI_UpdateNumericStyleTextures(poiButton)
								end
							end
						end
					end
					
					local poiButton =  QuestPOI_FindButton(QuestScrollFrame.Contents, pin.questID);
					if poiButton then
						QuestWaypoints.QuestPOI_SetTexture(poiButton.NormalTexture, 32, 32, selectedButtonTexture, 0.500, 0.625, 0.375, 0.5);
						QuestWaypoints.QuestPOI_SetTexture(poiButton.PushedTexture, 32, 32, selectedButtonTexture, 0.500, 0.625, 0.375, 0.5);
						if not IsQuestComplete(pin.questID) then
							poiButton.Display.Icon:SetTexture(selectedButtonTexture);
						end
					end
				end							
			end)
		end)
		hooksecurefunc(QuestPinMixin, 'OnMouseEnter', function(self)
			if selectedQuest.questID and selectedQuest.questID == self.questID then
				WorldMapTooltip:AddLine("Remove QuestWaypoints tracking", 1, 0.5, 0)
			else
				WorldMapTooltip:AddLine("Right click to track with QuestWaypoints", 0, 1, 0)
			end
			WorldMapTooltip:Show();
		end)
		hooksecurefunc(QuestPinMixin, 'OnClick', function(self, button)
			if (button == "RightButton") then
				-- remove tracking
				if self.questID == selectedQuest.questID then
					QuestWaypoints.RemoveTracking()		
					return
				end
				
				local instanceInfo = C_Map.GetMapInfo(WorldMapFrame:GetMapID())				
				-- if dungeon
				if instanceInfo.mapType == 4 then
					QuestWaypoints.Print("Can't track this quest because dungeons are restricted areas for coordinates.")
				else 
					local questsOnMap = C_QuestLog.GetQuestsOnMap(WorldMapFrame:GetMapID());
					if questsOnMap then
						for i, info in ipairs(questsOnMap) do
							if info.questID == self.questID then							
								local instanceID, worldPosition = C_Map.GetWorldPosFromMapPos(WorldMapFrame:GetMapID(), {x = info.x, y = info.y})
								selectedQuest.questID = info.questID
								selectedQuest.localX = info.x
								selectedQuest.localY = info.y
								selectedQuest.worldX = worldPosition.x
								selectedQuest.worldY = worldPosition.y
								selectedQuest.mapID = WorldMapFrame:GetMapID()
								selectedQuest.continentID = WorldMapFrame.continentInfo.mapID
								selectedQuest.instanceID = instanceID
								
								HBDP:AddMinimapIconMap("QuestWaypoints", QuestWaypointsMinimapOverlayIcon, WorldMapFrame:GetMapID(), info.x, info.y, true, false)							
								HBDP:AddWorldMapIconMap("QuestWaypoints", QuestWaypointsOverlayIcon, WorldMapFrame:GetMapID(), info.x, info.y, HBD_PINS_WORLDMAP_SHOW_CONTINENT, PIN_FRAME_LEVEL_QUEST_BLOB)							
																						
								if selectedQuest.instanceID == playerInstanceID then
									QuestWaypointsOverlay:Show()
									QuestWaypointsMinimapOverlayArrow:Show()
									QuestWaypointsMinimapOverlay:Show()
								else								
									QuestWaypointsOverlay:Hide()
									QuestWaypointsMinimapOverlayArrow:Hide()
									QuestWaypointsMinimapOverlay:Hide()									
								end
								
								local questLogIndex = GetQuestLogIndexByID(info.questID);
								local title = GetQuestLogTitle(questLogIndex);
								QuestWaypoints.Print("Tracking quest: " .. NORMAL_FONT_COLOR:GenerateHexColorMarkup() .. "[" .. info.questID .. "] " .. title)
								customPin:SetQuestID(info.questID)
								C_Timer.NewTimer(0, function() 
									QuestWaypoints.UpdateMinimap()
								end)
								return
							end
						end
					end
				end							
			end
		end)			
		
		-- world map player-target line
		for dataProvider, _ in pairs(WorldMapFrame.dataProviders) do
			if dataProvider.pin then
				if  dataProvider.SetUnitPinSize and dataProvider.pin:GetObjectType() == "UnitPositionFrame" then
					hooksecurefunc(dataProvider.pin, "UpdatePlayerPins", function(self)	
						if selectedQuest.questID ~= nil and QuestWaypointsOverlay:IsVisible() and playerInstanceID == selectedQuest.instanceID then
							local playerWorldPosX, playerWorldPosY, playerWorldPosZ, instanceID = UnitPosition("player")									
							local _, playerMapPosition = C_Map.GetMapPosFromWorldPos(instanceID, {x = playerWorldPosX ,y = playerWorldPosY}, WorldMapFrame:GetMapID())
							local _, endMapPosition = C_Map.GetMapPosFromWorldPos(instanceID, {x = selectedQuest.worldX, y = selectedQuest.worldY}, WorldMapFrame:GetMapID())
								
							QuestWaypointsOverlayPointStart:SetPoint("CENTER", QuestWaypointsOverlay, "TOPLEFT", QuestWaypointsOverlay:GetWidth() * playerMapPosition.x, -QuestWaypointsOverlay:GetHeight() * playerMapPosition.y)											
							QuestWaypointsOverlayPointEnd:SetPoint("CENTER", QuestWaypointsOverlay, "TOPLEFT", QuestWaypointsOverlay:GetWidth() * endMapPosition.x, -QuestWaypointsOverlay:GetHeight() * endMapPosition.y)					
						end
					end)
				end
			end
		end
		
		-- custom quest blob
		local questBlobDataProvider = CreateFromMixins(CustomQuestBlobDataProviderMixin)
		WorldMapFrame:AddDataProvider(questBlobDataProvider)	
		customPin = questBlobDataProvider.pin
		hooksecurefunc(customPin, "Refresh", function(self, questID)				
			if selectedQuest.mapID and selectedQuest.mapID == C_Map.GetBestMapForUnit("player") then
				HBDP:RemoveWorldMapIcon("QuestWaypoints", self)
				HBDP:AddMinimapIconMap('QuestWaypoints', self, WorldMapFrame:GetMapID(), 0.5, 0.5, true, false)
			end
		end)
		
		-- quest minimap arrow
		QuestWaypointsMinimapOverlay:SetScript("OnUpdate", function(self, elapsed)
			if GetUnitSpeed("player") > 0 and selectedQuest.localX then
				QuestWaypoints.UpdateMinimap()
			end
		end)
		
	elseif event == "QUEST_TURNED_IN" then
		if selectedQuest.questID and selectedQuest.questID == arg1 then
			QuestWaypoints.RemoveTracking()
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		local _, _, _, instanceID = UnitPosition("player")		
		playerInstanceID = instanceID

		if selectedQuest.instanceID then
			if playerInstanceID == selectedQuest.instanceID then
				QuestWaypointsOverlay:Show()
				QuestWaypointsMinimapOverlay:Show()
				C_Timer.NewTimer(0, function() 
					QuestWaypoints.UpdateMinimap()	
				end)
			else
				QuestWaypointsOverlay:Hide()
				QuestWaypointsMinimapOverlay:Hide()
			end			
		end
	end
end)

function QuestWaypoints.RemoveTracking()
	selectedQuest = nil
	selectedQuest = {}
	QuestWaypointsOverlay:Hide()
	QuestWaypointsMinimapOverlay:Hide()
	customPin:SetQuestID(0)
	HBDP:RemoveAllMinimapIcons("QuestWaypoints")
	HBDP:RemoveAllWorldMapIcons("QuestWaypoints")
	C_Timer.NewTimer(0, function() 
		QuestWaypoints.UpdateMinimap()
	end)
end

function QuestWaypoints.UpdateMinimap()
	if selectedQuest.questID == nil then
		return
	end	
	
	local playerWorldPosX, playerWorldPosY, playerWorldPosZ, instanceID = UnitPosition("player")
	local questInstanceID, _ = C_Map.GetWorldPosFromMapPos(selectedQuest.mapID, {x = selectedQuest.localX, y = selectedQuest.localY})
	
	if instanceID == questInstanceID then 
		
		local _, playerMapPosition = C_Map.GetMapPosFromWorldPos(instanceID, {x = playerWorldPosX ,y = playerWorldPosY}, WorldMapFrame:GetMapID())
		local _, endMapPosition = C_Map.GetMapPosFromWorldPos(instanceID, {x = selectedQuest.worldX, y = selectedQuest.worldY}, WorldMapFrame:GetMapID())
		
		if endMapPosition == nil then		
			return
		end
		
		local angle = math.atan2(endMapPosition.y - playerMapPosition.y, endMapPosition.x - playerMapPosition.x) - (math.pi / 180 * 45) ;
		local cos = math.cos(angle);
		local sin = math.sin(angle);		

		local distanceX = -Minimap:GetHeight()
		local distanceY = -Minimap:GetWidth()

		local endWorldPosition = {}
		endWorldPosition.x = distanceX * cos - distanceY * sin + endMapPosition.x;
		endWorldPosition.y = distanceX * sin + distanceY * cos + endMapPosition.y;
		
		QuestWaypointsOverlayMinimapPointStart:SetPoint("CENTER", QuestWaypointsMinimapOverlay, "CENTER" , 0, 0)											
		QuestWaypointsOverlayMinimapPointEnd:SetPoint("CENTER", QuestWaypointsMinimapOverlay, "CENTER", -endWorldPosition.x, endWorldPosition.y)				

		if QuestWaypointsMinimapOverlayIcon:IsVisible() then
			QuestWaypointsMinimapOverlayArrow:Hide()
		else
			QuestWaypointsMinimapOverlayArrow:Show()
		end
	end
end

-- Print function
function QuestWaypoints.Print(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(ORANGE_FONT_COLOR_CODE .. "[QuestWaypoints] " .. BATTLENET_FONT_COLOR_CODE .. msg)
	end
end


-- From Blizzard code
function QuestWaypoints.QuestPOI_SetTextureSize(texture, width, height)
	if texture then
		local scale = QuestPOI_GetPinScale(texture:GetParent());
		texture:SetSize(scale * width, scale * height);
	end
end

function QuestWaypoints.QuestPOI_SetTexture(texture, width, height, file, texLeft, texRight, texTop, texBottom)
	if texture then
		texture:SetTexture(file);
		texture:SetTexCoord(texLeft or 0, texRight or 1, texTop or 0, texBottom or 1);
		QuestWaypoints.QuestPOI_SetTextureSize(texture, width, height);
	end
end