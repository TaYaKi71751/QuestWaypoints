
CustomQuestBlobDataProviderMixin = CreateFromMixins(QuestBlobDataProviderMixin);

function CustomQuestBlobDataProviderMixin:OnAdded(mapCanvas)
	MapCanvasDataProviderMixin.OnAdded(self, mapCanvas);
	self:GetMap():SetPinTemplateType("CustomQuestBlobPinTemplate", "QuestPOIFrame");

	-- a single permanent pin
	local pin = self:GetMap():AcquirePin("CustomQuestBlobPinTemplate");
	pin.dataProvider = self;
	pin:SetPosition(0.5, 0.5);

	self.pin = pin;	
end

function CustomQuestBlobDataProviderMixin:OnRemoved(mapCanvas)
	MapCanvasDataProviderMixin.OnRemoved(self, mapCanvas);
end

--[[ Quest Blob Pin ]]--
CustomQuestBlobPinMixin = CreateFromMixins(QuestBlobPinMixin);

function CustomQuestBlobPinMixin:OnLoad()
	self:SetFillTexture("Interface\\WorldMap\\UI-QuestBlob-Inside");
	self:SetBorderTexture("Interface\\WorldMap\\UI-QuestBlob-Outside");
	self:SetFillAlpha(90);
	self:SetBorderAlpha(140);
	self:SetBorderScalar(1.0);
	self:SetIgnoreGlobalPinScale(true);
	self:UseFrameLevelType("PIN_FRAME_LEVEL_QUEST_BLOB");
	self.questID = 0;
	self:DrawNone()
end

function CustomQuestBlobPinMixin:TryDrawQuest(questID)
	if questID and questID > 0 then
		self:DrawBlob(questID, true)
	end
end

function CustomQuestBlobPinMixin:Refresh()
	-- placeholder
end

function CustomQuestBlobPinMixin:DrawAll()
	self:DrawNone()
	if self.questID and self.questID > 0 then
		self:TryDrawQuest(self.questID)
	end
end

function CustomQuestBlobPinMixin:SetHighlightedQuestID(questID)
	-- empty override
end

function CustomQuestBlobPinMixin:ClearHighlightedQuestID()
	-- empty override
end

function CustomQuestBlobPinMixin:SetFocusedQuestID(questID)
	-- empty override
end

function CustomQuestBlobPinMixin:ClearFocusedQuestID()
	-- empty override
end

function CustomQuestBlobPinMixin:SetHighlightedQuestPOI(questID)
	-- empty override
end

function CustomQuestBlobPinMixin:ClearHighlightedQuestPOI()
	-- empty override
end