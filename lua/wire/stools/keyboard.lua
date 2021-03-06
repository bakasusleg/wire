WireToolSetup.setCategory( "I/O" )
WireToolSetup.open( "keyboard", "Keyboard", "gmod_wire_keyboard", nil, "Keyboards" )

if ( CLIENT ) then
    language.Add( "Tool.wire_keyboard.name", "Wired Keyboard Tool (Wire)" )
    language.Add( "Tool.wire_keyboard.desc", "Spawns a keyboard input for use with the hi-speed wire system." )
    language.Add( "Tool.wire_keyboard.0", "Primary: Create/Update Keyboard, Secondary: Link Keyboard to pod, Reload: Unlink" )
	language.Add( "Tool.wire_keyboard.1", "Now select the pod to link to.")
	language.Add( "Tool.wire_keyboard.leavekey", "Leave Key" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

if (SERVER) then
	ModelPlug_Register("Keyboard")
	
	function TOOL:GetConVars() 
		return self:GetClientNumber( "autobuffer" ) ~= 0
	end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireKeyboard( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.ClientConVar = {
	model = "models/jaanus/wiretool/wiretool_input.mdl",
	sync = "1",
	layout = "American",
	autobuffer = "1",
	leavekey = KEY_LALT
}

function TOOL:RightClick( trace )
	if (!trace.HitPos) then return false end
	local ent = trace.Entity
	if (ent:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	if self:GetStage() == 0 then
		if ( not ent:IsValid() or ent:GetClass() ~= "gmod_wire_keyboard" ) then return false end

		self:SetStage(1)
		self.LinkSource = ent
		return true
	else
		--TODO: player check is missing. done by the prop protection plugin?
		if ( not ent:IsValid() or not ent:IsVehicle() ) then return false end

		self.LinkSource:LinkPod(ent)

		self:SetStage(0)
		self.LinkSource = nil
		return true
	end
end

function TOOL:Reload(trace)
	self:SetStage(0)
	self.LinkSource = nil

	if (!trace.HitPos) then return false end
	local ent = trace.Entity
	if (ent:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	if ( not ent:IsValid() or ent:GetClass() ~= "gmod_wire_keyboard" ) then return false end
	ent:LinkPod(nil)
	return true
end

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "Keyboard", "wire_keyboard", true)

	panel:Help("Lock player controls when keyboard is active")
	panel:CheckBox("Synchronous", "wire_keyboard_sync")

	local languages = panel:ComboBox("Keyboard Layout", "wire_keyboard_layout")
	local curlayout = LocalPlayer():GetInfo("wire_keyboard_layout")
	for k,v in pairs( Wire_Keyboard_Remap ) do
		languages:AddChoice( k )
		if k == curlayout then 
			local curindex = #languages.Choices 
			timer.Simple(0, function() languages:ChooseOptionID(curindex) end) -- This needs to be delayed or it'll set the box to show "0"
		end
	end
	
	panel:Help("When on, automatically removes the key from the buffer when the user releases it.\nWhen off, leaves all keys in the buffer until they are manually removed.\nTo manually remove a key, write any value to cell 0 to remove the first key, or write a specific ascii value to any address other than 0 to remove that specific key.")
	panel:CheckBox("Automatic buffer clear", "wire_keyboard_autobuffer")

	panel:AddControl("Numpad", {
		Label = "#Tool.wire_keyboard.leavekey",
		Command = "wire_keyboard_leavekey",
	})
end
