
local PANEL = {}
local math_max, math_abs, math_approach, FrameTime, Mantle = math.max, math.abs, math.Approach, FrameTime, Mantle
local draw_SimpleRect, draw_RoundedBox = draw.SimpleRect, draw.RoundedBox

function draw.SimpleRect(x, y, w, h, col)
    surface.SetDrawColor(col)
    surface.DrawRect(x, y, w, h)
end

local function LerpExponential(current, target, speed, deltaTime)
    return current + (target - current) * (1 - math.exp(-speed * deltaTime))
end

local function ApproachScroll(current, target, deltaTime)
    return math_approach(current, target, 10 * math_abs(target - current) * deltaTime)
end

local function Clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

AccessorFunc(PANEL, "m_bDrawBorder", "DrawBorder", FORCE_BOOL);
AccessorFunc(PANEL, "m_bUseSizeLimit", "UseSizeLimit", FORCE_BOOL);

function PANEL:Init()
	self:SetDrawBorder(false);
	self:SetUseSizeLimit(true);

	self.VBar:SetWide(15)
	self.VBar.btnUp:Remove()
	self.VBar.btnDown:Remove()

	self.VBar.targetScroll = 0;
	self.VBar.scrollSpeed = 2;

	self.VBar.SetUp = function(bar, barSize, canvasSize)
		bar.BarSize = barSize;
		bar.CanvasSize = math_max(canvasSize - barSize, 1);

		if (self:GetUseSizeLimit()) then
			bar:SetEnabled(canvasSize > barSize);
		else
			bar:SetEnabled(true);
		end;

		bar:InvalidateLayout()
	end;

	function self.VBar:Paint(w, h)
	end;

	PANEL.Lerp = 5
	function self.VBar.btnGrip:Paint(w, h)
		local parent = self:GetParent():GetParent()
		local x, y = parent:ScreenToLocal(gui.MousePos())
		local w2, h2 = parent:GetSize()
		
		if x >= 0 and x <= w2 and y >= 0 and y <= h2 then
			local hovered = self:GetParent():IsHovered() or self.Hovered
			PANEL.Lerp = LerpExponential(PANEL.Lerp, hovered and 10 or 5, 7, FrameTime())
			draw_SimpleRect(PANEL.Lerp, 0, PANEL.Lerp, h, Mantle.color.theme)
		end
	end
	
	function self.VBar:OnMouseWheeled(delta)
		self.scrollSpeed = Clamp(self.scrollSpeed + 50 * FrameTime(), 2, 20)
		self:AddScroll(delta * -self.scrollSpeed)
	end
	

	function self.VBar:OnCursorMoved(_, _)
		if not (self.Enabled and self.Dragging) then return end
	
		local _, y = self:ScreenToLocal(0, gui.MouseY())
		local trackSize = self:GetTall() - self:GetWide() * 2 - self.btnGrip:GetTall()
		self.targetScroll = Clamp((y - self.HoldPos) / trackSize * self.CanvasSize, 0, self.CanvasSize)
	end

	function self.VBar:PerformLayout()
		local Scroll = self:GetScroll() / self.CanvasSize;
		local BarSize = math_max(self:BarScale() *self:GetTall(), 0);
		local Track = self:GetTall() - BarSize;
		
		Track = Track + 1;
		Scroll = Scroll * Track;
		
		self.btnGrip:SetPos(0, Scroll);
		self.btnGrip:SetSize(self:GetWide(), BarSize);
	end;

	function self.VBar:Think()
		local deltaTime = FrameTime()
		self.scrollSpeed = math_approach(self.scrollSpeed, 4, math_abs(4 - self.scrollSpeed) * deltaTime)
		self.Scroll = ApproachScroll(self.Scroll, self.targetScroll, deltaTime)
	
		if not self.Dragging then
			if self.targetScroll < 0 then
				self.targetScroll = ApproachScroll(self.targetScroll, 0, deltaTime)
			elseif self.targetScroll > self.CanvasSize then
				self.targetScroll = ApproachScroll(self.targetScroll, self.CanvasSize, deltaTime)
			end
		end
	end
	
	function self.VBar:SetScroll(amount)
		self.targetScroll = amount;
		self:InvalidateLayout();
		
		local func = self:GetParent().OnVScroll;

		if (func) then
			func(self:GetParent(), self:GetOffset());
		else
			self:GetParent():InvalidateLayout();
		end;
	end;
end;

function PANEL:Think()
	self.pnlCanvas:SetPos(0, -self.VBar.Scroll);
end;

function PANEL:PerformLayout()
    local width, height = self:GetSize()

    self:Rebuild() 
    self.VBar:SetUp(height, self.pnlCanvas:GetTall())

    self.pnlCanvas:SetWide(width)

    if not self.VBar.Enabled then
        self.pnlCanvas:SetPos(0, 0)
    end
end

function PANEL:Paint(width, height)
	if (self:GetDrawBorder()) then
		draw_RoundedBox(6, 0, 0, width, height, Mantle.color.sp);
		draw_RoundedBox(6, 1, 1, width - 2, height - 2, Mantle.color.sp);
	end;
end;

vgui.Register("MantleScrollPanel", PANEL, "DScrollPanel");
