-- Server-side script
-- Runs on the FiveM server process

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
  print(("[Eonexis] %s is connecting..."):format(name))
end)

AddEventHandler('playerDropped', function(reason)
  print(("[Eonexis] Player dropped: %s"):format(reason))
end)
