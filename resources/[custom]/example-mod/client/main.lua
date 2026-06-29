-- Client-side script
-- Runs on every player's game client

AddEventHandler('onClientGameTypeStart', function()
  -- Example: notify player on spawn
  TriggerEvent('chat:addMessage', {
    color = {255, 165, 0},
    multiline = true,
    args = {"Eonexis", "Welcome to the server!"}
  })
end)
