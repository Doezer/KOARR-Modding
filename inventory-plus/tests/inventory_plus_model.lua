math.floor=nil
local M=dofile('mods/InventoryPlus/model.lua')
local rows={{header_id='Weapon',header_text=100,len=3},
 {item_id=10,stack=2},{item_id=20,equipped=true},{item_id=30},
 {header_id='Potions',header_text=200,len=1},{item_id=40}}
local names={[10]='Frost Sword',[20]='ÉPÉE',[30]='Frost Sword',[40]='Healing Potion'}
local function name(id)return names[id]end
local function fold(s)
 s=string.lower(s);s=string.gsub(s,'É','é');return s
end
local status={Weapon={collapsed=false},Potions={collapsed=false}}
local v=M.project(rows,'fROst','native',name,fold,status)
assert(v.total==4 and v.matched==2 and #v.rows==4)
assert(v.rows[2]==rows[2] and v.rows[3]==rows[4])
assert(v.rows[1]~=rows[1] and v.rows[1].len==2 and rows[1].len==3)
assert(v.rows[4].len==0 and v.categories.Potions==4)
assert(M.selection(v.rows,30,4)==3 and M.selection(v.rows,999,3)==3)
local accent=M.project(rows,'épée','native',name,fold,status)
assert(accent.matched==1 and accent.rows[2].item_id==20)
assert(M.project(rows,'epee','native',name,fold,status).matched==0)
assert(M.project(rows,'.*','native',name,fold,status).matched==0) -- literal, not pattern
assert(M.selection({},10,1)==nil)
local az=M.project(rows,'','az',name,fold,status)
assert(az.rows[2].item_id==10 and az.rows[3].item_id==30 and az.rows[4].item_id==20)
local za=M.project(rows,'','za',name,fold,status)
assert(za.rows[2].item_id==20 and za.rows[3].item_id==10 and za.rows[4].item_id==30)
status.Weapon.collapsed=true
v=M.project(rows,'frost','native',name,fold,status)
assert(v.matched==2 and v.total==4 and #v.rows==2 and v.categories.Potions==2)
assert(status.Weapon.collapsed and rows[2].stack==2 and rows[3].equipped)
local empty=M.project(rows,'missing','native',name,fold,status)
assert(#empty.rows==2 and empty.matched==0 and M.selection(empty.rows,10,2)==1)
assert(not pcall(M.project,rows,'x','native',function()return nil end,fold,status))
assert(not pcall(M.project,rows,'x','native',name,function()return nil end,status))
assert(M.trim(' \t Frost sword\r\n')=='Frost sword')
assert(M.short('Épée blanche',4)=='Épée…' and M.short('短剣',1)=='短…')
-- Large bags keep distinct handles and stable ordering for duplicate names.
local bag={{header_id='Bag',len=1000}}
for i=1,1000 do bag[#bag+1]={item_id=i}end
v=M.project(bag,'','za',function()return 'same' end,fold,{Bag={collapsed=false}})
assert(v.matched==1000 and #v.rows==1001)
for i=1,1000 do assert(v.rows[i+1].item_id==i)end
-- Numeric orders: high to low, unknown last (never zero), name then ordinal tie-breaks.
local gear={{header_id='Gear',header_text=1,len=5},{item_id=1},{item_id=2},{item_id=3},{item_id=4},{item_id=5}}
local gnames={[1]='b',[2]='a',[3]='c',[4]='d',[5]='e'}
local stats={[1]=10,[2]=10,[3]=0,[4]=nil,[5]=25}
local function gname(id)return gnames[id]end
local function gstat(id)if id==4 then error('unreadable')end;return stats[id]end
local order=M.project(gear,'','dmg',gname,fold,{Gear={collapsed=false}},gstat)
local ids={};for i=2,#order.rows do ids[#ids+1]=order.rows[i].item_id end
assert(table.concat(ids,',')=='5,2,1,3,4') -- 25; 10 (a before b); 10; 0 is known and beats unknown 4
assert(order.matched==5 and gear[2].item_id==1) -- source rows untouched
assert(not pcall(M.project,gear,'','dmg',gname,fold,{},nil)) -- numeric order needs a reader
assert(not pcall(M.project,gear,'','nonsense',gname,fold,{},gstat))
print('Model: numeric orders, unknown values last and tie-breaks passed')
