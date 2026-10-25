-- Pure view projection. Native rows/handles and category state are never changed.
if _G.InventoryPlusModel then return _G.InventoryPlusModel end
local M={}
function M.trim(text)
 local first,last=1,#text
 while first<=last and string.byte(text,first)<=32 do first=first+1 end
 while last>=first and string.byte(text,last)<=32 do last=last-1 end
 return string.sub(text,first,last)
end
function M.short(text,limit)
 local at,count=1,0
 while at<=#text and count<limit do
  local b=string.byte(text,at)
  at=at+(b<128 and 1 or b<224 and 2 or b<240 and 3 or 4);count=count+1
 end
 return at>#text and text or (string.sub(text,1,at-1)..'…')
end
function M.project(rows,query,order,read_name,fold,status)
 assert(type(rows)=='table' and type(query)=='string')
 assert(order=='native' or order=='az' or order=='za')
 local needle=fold(query)
 assert(type(needle)=='string','Could not normalize search text')
 local view={rows={},categories={},total=0,matched=0}
 local group={items={}}
 local function flush()
  if order~='native' then
   table.sort(group.items,function(a,b)
    if a.key==b.key then return a.ordinal<b.ordinal end
    if order=='za' then return a.key>b.key end
    return a.key<b.key
   end)
  end
  local collapsed=false
  if group.header then
   local header={};for k,v in pairs(group.header)do header[k]=v end
   header.len=#group.items
   view.rows[#view.rows+1]=header;view.categories[header.header_id]=#view.rows
   local state=status and status[header.header_id]
   collapsed=type(state)=='table' and not not state.collapsed
  end
  if not collapsed then for _,item in ipairs(group.items)do view.rows[#view.rows+1]=item.row end end
 end
 for ordinal,row in ipairs(rows)do
  assert(type(row)=='table','Unexpected inventory row')
  if row.header_id~=nil then
   flush();group={header=row,items={}}
  else
   assert(row.item_id~=nil,'Inventory row has no item handle')
   local name=read_name(row.item_id)
   assert(type(name)=='string' and name~='','Item name unavailable')
   local key=fold(name)
   assert(type(key)=='string','Could not normalize item name')
   view.total=view.total+1
   if needle=='' or string.find(key,needle,1,true)then
    group.items[#group.items+1]={row=row,key=key,ordinal=ordinal}
    view.matched=view.matched+1
   end
  end
 end
 flush();return view
end
function M.selection(rows,handle,old_index)
 if handle~=nil then for i,row in ipairs(rows)do if row.item_id==handle then return i end end end
 local nearest,distance
 for i,row in ipairs(rows)do
  if row.item_id~=nil then
   local d=i-(old_index or 1);if d<0 then d=-d end
   if not distance or d<distance then nearest=i;distance=d end
  end
 end
 return nearest or (#rows>0 and 1 or nil)
end
_G.InventoryPlusModel=M
return M
