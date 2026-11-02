-- Inventory Plus stats probe 0.1.0: Ctrl+D logs the selected item's native damage/armor tables.
local function bootstrap()
local G=_G
local previous=rawget(G,'InventoryPlusStats')
if previous and previous.enabled then previous.attach();return previous end
local function log(message)print('[InventoryPlusStats] '..message)end
local N=rawget(G,'InventoryPlusStatsNative')
if type(N)~='table' or type(N.self_test)~='function' or type(N.poll)~='function' or type(N.stats)~='function' then
 log('Native helper unavailable; probe not installed.');return false
end
if N.self_test('InventoryPlusStats 0.1.0')~=1 then log('Native version mismatch; replace the complete package.');return false end
local S={enabled=true,hooks={}}
G.InventoryPlusStats=S
local function pack(...)return {n=select('#',...),...}end
local function dump()
 local I,A,W=rawget(G,'inventory_win'),rawget(G,'ACTOR'),rawget(G,'WINDOW')
 if type(I)~='table' or not I.m_inited or not I.m_window or type(W)~='table' or not W.is_visible(I.m_window)
  or type(I.get_selected_item)~='function' then return end
 local handle=I.get_selected_item()
 if handle==nil or type(handle)=='string' or type(A)~='table' or type(A.is_valid)~='function' or not A.is_valid(handle) then
  log('No valid selected item.');return
 end
 local r=pack(pcall(N.stats,handle))
 if not r[1] or r.n<6 then log('Item has no readable stats ('..tostring(r[2])..').');return end
 log('item="'..tostring(r[2])..'" slot='..tostring(I.m_selected_slot)..' indices 0..13')
 log('damage raw    ='..r[3]);log('damage scaled ='..r[4])
 log('armor  raw    ='..r[5]);log('armor  scaled ='..r[6])
end
function S.attach()
 local I=rawget(G,'inventory_win')
 if type(I)~='table' or type(I.on_update_event)~='function' then return end
 for _,h in ipairs(S.hooks)do if h.module==I then return end end
 local original=I.on_update_event
 local replacement=function(...)
  local result=pack(original(...))
  if S.enabled and N.poll('Ctrl+D')then local ok,err=pcall(dump);if not ok then log('Dump failed: '..tostring(err))end end
  return unpack(result,1,result.n)
 end
 I.on_update_event=replacement
 S.hooks[#S.hooks+1]={module=I,original=original,replacement=replacement}
 if not S.announced then S.announced=true;log('Ready. Select an item in Inventory and press Ctrl+D.')end
end
function S.detach()
 S.enabled=false
 for i=#S.hooks,1,-1 do local h=S.hooks[i];if h.module.on_update_event==h.replacement then h.module.on_update_event=h.original end end
 return true
end
S.attach();return S
end
local ok,result=pcall(bootstrap)
if not ok then print('[InventoryPlusStats] Probe disabled: '..tostring(result));return false end
return result
