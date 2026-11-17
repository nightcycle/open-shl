--!strict
--!native
-- Services
local Players = game:GetService("Players")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
local TutorialDefinition = require("@game/ReplicatedStorage/Shared/Definition/Tutorial")
-- Components
local Tutorial = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Tutorial")
-- Hooks
local usePlayerAttribute = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePlayerAttribute")
-- Contexts
local TutorialContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Tutorial")
local TutorialIsEnabledContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Tutorial/IsEnabled")
-- Types
type Progress = TutorialContext.Progress
type SectionId = TutorialDefinition.SectionId
type SectionDefinition = TutorialDefinition.SectionDefinition
type Condition = TutorialDefinition.Condition
type Trigger = ShellService.Trigger
export type Properties = {}
-- Constants
-- drawn over everything else on screen
local Z_INDEX = 30
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local isEnabled = usePlayerAttribute(AttributeDefinition.IsTutorialEnabled)
	local progress: Progress?, setProgress: (Progress?) -> () = React.useState(nil :: Progress?)
	-- a trigger comes in between two renders, so what it goes by is kept where it's current right away
	local progressRef = React.useRef(nil :: Progress?)
	-- only the on / off flag outlives the session, so every section plays once per visit
	local doneSectionIdsRef = React.useRef({} :: { [SectionId]: boolean })
	-- goes up whenever a section that waits out its start delay is called off
	local startIdRef = React.useRef(0)

	local function setCurrent(to: Progress?)
		progressRef.current = to
		setProgress(to)
	end

	local function getIfShown(conditions: { Condition }?): boolean
		local quest = SessionService:GetQuest()
		return TutorialDefinition.getIfShown(
			conditions,
			doneSectionIdsRef.current["Quest" :: SectionId] == true,
			quest ~= nil and quest.Status == "Active"
		)
	end

	local function advance(section: SectionDefinition, fromIndex: number)
		for i = fromIndex + 1, #section.Steps do
			if getIfShown(section.Steps[i].Conditions) then
				setCurrent(table.freeze({
					SectionId = section.Id,
					StepIndex = i,
				}))
				return
			end
		end
		doneSectionIdsRef.current[section.Id] = true
		setCurrent(nil)
	end

	-- the section that's cut short isn't done, so it plays again the next time its trigger comes by
	local function start(section: SectionDefinition)
		local current = progressRef.current
		if
			not AttributeDefinition.get(Players.LocalPlayer, AttributeDefinition.IsTutorialEnabled)
			or doneSectionIdsRef.current[section.Id]
			or (current and current.SectionId == section.Id)
			or not getIfShown(section.Conditions)
		then
			return
		end
		advance(section, 0)
	end

	local function cancel()
		startIdRef.current += 1
		if progressRef.current then
			setCurrent(nil)
		end
	end

	local function onTrigger(trigger: Trigger)
		local current = progressRef.current
		if current then
			local currentSection = TutorialDefinition.get(current.SectionId)
			local step = currentSection.Steps[current.StepIndex]
			if step.Type == "Talk" then
				local stepAdvance = step.Advance
				if stepAdvance.Type == "Trigger" and stepAdvance.Trigger == trigger then
					advance(currentSection, current.StepIndex)
					return
				end
			end
		end
		local sectionOpt = TutorialDefinition.getFromTrigger(trigger)
		if sectionOpt.IsNone then
			return
		end
		local section = sectionOpt.Value
		if section.StartDelay <= 0 then
			start(section)
			return
		end
		startIdRef.current += 1
		local startId = startIdRef.current
		task.delay(section.StartDelay, function()
			if startIdRef.current == startId then
				start(section)
			end
		end)
	end

	local function onNext()
		local current = progressRef.current
		if not current then
			return
		end
		local section = TutorialDefinition.get(current.SectionId)
		local step = section.Steps[current.StepIndex]
		if step.Type == "Talk" and step.Advance.Type == "Next" then
			advance(section, current.StepIndex)
		end
	end

	React.useEffect(function()
		local connection = ShellService.TutorialTriggered:Connect(onTrigger)
		-- the hud comes up once, the moment the boot is over. that may have been before anything listened
		if ShellService:GetBootPhase() == "Playing" then
			onTrigger("HudShown")
		end
		return function()
			connection:Disconnect()
			startIdRef.current += 1
		end
	end, {})
	-- a step he rests on has no bubble + no trigger to move him on, so the clock does
	React.useEffect(function()
		if not progress then
			return function() end
		end
		local section = TutorialDefinition.get(progress.SectionId)
		local step = section.Steps[progress.StepIndex]
		if step.Type ~= "Rest" then
			return function() end
		end
		local isDead = false
		task.delay(step.Duration, function()
			if isDead or progressRef.current ~= progress then
				return
			end
			advance(section, progress.StepIndex)
		end)
		return function()
			isDead = true
		end
	end, { progress })
	React.useEffect(function()
		if not isEnabled then
			cancel()
		end
		return function() end
	end, { isEnabled })

	return e(TutorialContext.Provider, {
		value = progress,
	}, {
		IsEnabled = e(TutorialIsEnabledContext.Provider, {
			value = isEnabled,
		}, {
			Tutorial = e(
				Tutorial,
				{
					Size = UDim2.fromScale(1, 1),
					ZIndex = Z_INDEX,
					OnAction = function(action: Tutorial.ActionInfo)
						if action.Type == "Next" then
							onNext()
						elseif action.Type == "SetEnabled" then
							-- he heads home right away, the flag + his fade follow once the server set it
							if not action.IsEnabled then
								cancel()
							end
							NetworkService:Fire(RemoteDefinition.SetTutorialEnabled, action.IsEnabled)
						end
					end,
				} :: Tutorial.Properties
			),
		}),
	})
end
