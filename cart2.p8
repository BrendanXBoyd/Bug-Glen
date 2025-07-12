pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- bug glen: the glom king
-- brendan x boyd

--saving/loading
-- first, define game objs
class={
	new=function(self,tbl)
		tbl=tbl or {}
		setmetatable(tbl,{
			__index=self
		})
		return tbl
	end,
}

bug=class:new({
	cmod=0,
	number=0,
	bsquat=false,
	bflip=false,
	
	dbat=function(self,x,y)
		if self.cmod~=0 then
			for i=1,15 do
				pal(i,((i+self.cmod)%15)+1)
			end
		end
		if fcnt==0 or fcnt==15 then
			self.bsquat=not self.bsquat
		end
		if self.bsquat then
			spr(self.number,
			    x,
			    y+1,
			    1,0.875,
			    self.bflip)
			sspr( (self.number%16)*8,
			     ((self.number\16)*8)+7,
			     8,1,
			     x,
			     y+7,
			     8,1,
			     self.bflip)
		else
			spr(self.number,
			    x,
			    y,
			    1,1,
			    self.bflip)
		end
		if self.cmod~=0 then
			for i=1,15 do
				pal(i,i)
			end
		end
	end
})

team_bug=bug:new({
	bflip=true,

	hp_max=0,
	pow_max=0,
	def_max=0,
	spd_max=0,
	
	hp_rem=0,
	lvl=0,
	xp=0,
	
	--calculated info
	hp=0,
	pow=0,
	def=0,
	spd=0,
	
	calcstatsfromlvl=function(self)
		hp=from_lvl(self.lvl,self.hp_max)
		pow=from_lvl(self.lvl,self.pow_max)
		def=from_lvl(self.lvl,self.def_max)
		spd=from_lvl(self.lvl,self.spd_max)
	end
})

game_data=class:new({
	swap_ab_btns=false,
	swap_psprite=false,
	achievs={},
	items_held={},
	health_pns=0,
	revives=0,
	level=0,
	bugs={},
	seed=0,
	
	addbug=function(_ENV,newbug)
		local l=#bugs
		if (l>=27) return false
		bugs[l+1]=newbug
		return true
	end,
	delbug=function(_ENV,b)
		local l=#bugs
		if (l<=1) return -1
		return del(bugs,b)
	end,
	newgame=function(_ENV)
		achievs={}
		items_held={}
		health_pns=0
		revives=0
		level=0
		bugs={}
		seed=0
	end
})
for i=1,16 do
 game_data.achievs[i]=false
 game_data.items_held[i]=false
 game_data.items_held[i+16]=false
end

mw=32--map width

map_bugs={}
portalx=13+mw
portaly=13

function rndi(up)
	return flr(rnd(up))
end

-- like substring for nums.
-- n is the number to subint.
-- i is start index, inclusive,
--  0 indexed.
-- l is length of the result.
-- 16 for ints, 32 for floats
function subint16(n,i,l)
 return flr((n<<i)>>>(16-l))
end
function subint32(n,i,l)
 return (n<<i)>>>(32-l)
end

-- inverse of subint
-- writes n (with length l)
-- to index i (0-indexed).
-- e.g. 7,12,1 will result in 8
--      7,12,2 will result in 12
-- writes to 32-bit nums
-- decimals are not tolerated
function writeint(n,i,l)
	return (flr(n)<<(16-l))>>>i
end


-- game game game --

pal(0,129,1)

game_handler={}
-- handlers for each game mode.
-- to change game mode, assign
-- one of these as game_handler
menu={}
bug_select={}
game={}
btl={}

function _init()
	prepare_menu()
	game_handler=menu
end

gd=game_data:new()

--- game loop ---

fcnt=0
function _update()
	fcnt+=1
	fcnt%=30
	
	game_handler:loop()
end

function menu.loop()
	if (apress()) then
		prepare_bug_select()
		game_handler=bug_select
	end
end

function bug_select.loop()
	update_sprites()
	if (wtng and apress()) then
		local c2=mget(pv.x+mw+mw,pv.y)
		if fget(c2,1) then
			--figure out which bug this is
			local mb=get_mbug_at_pos(pv)
			gd:addbug(mbug_to_bbug(mb))
			--clear the other bugs
			for clrb in all(map_bugs) do
				clrb:clear_from_map()
			end
			map_bugs={}
		end
	else
		-- see if we should move
		checkforinput()
		-- wait until moved before
		-- getting more input
 	if not wtng and mto==nil then
 		wtng=true
 	end
	end
end

function game.loop()
	update_sprites()
	checkforinput()
 --move the player first.
 --then handle any cols
 --then move mobs
 --then handle cols again
 if not wtng and mto==nil then
 	processinput()
 end
end

function btl.loop()
	if btl.menu=='main' then
		if btnp(3) and btl.menu_pos<3 then
			btl.menu_pos+=1
		elseif btnp(2) and btl.menu_pos>0 then
			btl.menu_pos-=1
		end
		if apress() then
			if (btl.menu_pos==0) btl.menu='fight'
			if (btl.menu_pos==1) btl.menu='item'
			if (btl.menu_pos==2) btl.menu='catch'
			if (btl.menu_pos==3) btl.menu='flee'
			btl.menu_pos=0
		end
	elseif btl.menu=='fight' then
		if btl.f1==-1 then
			if (btnp(3) or btnp(1)) and btl.menu_pos<2 then
				btl.menu_pos+=1
			elseif (btnp(2) or btnp(0)) and btl.menu_pos>0 then
				btl.menu_pos-=1
			end
			if (apress()) then 
				btl.f1=btl.menu_pos
				if (btl.f1==0) btl.menu_pos=2
				if (btl.f1~=0) btl.menu_pos=0
			end
			if (bpress()) then
				btl.menu="main"
				btl.menu_pos=0
			end
		elseif btl.f2==-1 then
			if btl.f1==1 then
				if btnp(3) and btl.menu_pos<6 then
					btl.menu_pos+=3
				elseif btnp(2) and btl.menu_pos>2 then
					btl.menu_pos-=3
				elseif btnp(0) and (btl.menu_pos%3)>0 then
					btl.menu_pos-=1
				elseif btnp(1) and (btl.menu_pos%3)<2 then
					btl.menu_pos+=1
				end
			else
				if btnp(3) and btl.menu_pos<6 then
					btl.menu_pos+=6
				elseif btnp(2) and btl.menu_pos>2 then
					btl.menu_pos-=6
				elseif btnp(0) and (btl.menu_pos%3)>0 then
					btl.menu_pos-=2
				elseif btnp(1) and (btl.menu_pos%3)<2 then
					btl.menu_pos+=2
				end
				--todo:prevent f2==f1.
			end
			if (bpress()) then
				btl.menu_pos=btl.f1
				btl.f1=-1
			end
			if (apress()) then
				--todo: battle anim
				game_handler=game
			end
		end
	else
		if (apress()) game_handler=game
	end
end

--- render ---

function menu.draw()
	cls()
	map(0,0,0,0,16,16)
	sspr(16,64,80,17,24,16)
	spr(22,8,32,1,1,true)
 print("the glom king",64-26,40,6)
 line(64-31,35,64+31,35,13)
	print("this is a menu. press z",20,62)
end

function bug_select.draw()
	cls()
	map(0,0,36,36,7,7)
	for b in all(map_bugs) do
 	b:db()
 end
 dp()
 print(bug_select.t1,7,3,13)
 print(bug_select.t2,7,28,7)
end

screen_x=0 screen_y=0
function game.draw()
	cls()
	screen_x=max(min(pv.x-8,mw-16),0)
	screen_y=max(min(pv.y-8,mw-16),0)
 map(screen_x,screen_y,0,0,mw,32)
 map(mw+screen_x,screen_y,0,0,mw,32)
 for b in all(map_bugs) do
 	b:db()
 end
 dp()
end

function btl.draw()
	cls()
	map(3*mw,0,12,8,13,9)
	map(mw+screen_x+3,screen_y+2,
	    20,16,11,7)
	idleat(20,40)
	print("this is a btl. press z",13)
	
	if btl.menu=='main' then
		print("fight",56,88,7)
		print("item" ,56,96,7)
		print("catch",56,104,7)
		print("flee" ,56,112,7)
		print(chr(23),
		      48+(abs(fcnt-15)/5.3),
		      88+(btl.menu_pos*8),
		      7)
	elseif btl.menu=='fight' then
		rect(49,88,76,115,13)
		line(49,97,76,97,13)
		line(49,106,76,106,13)
		line(58,88,58,115,13)
		line(67,88,67,115,13)
		for i=1,9 do
			local b=gd.bugs[i]
			if b~=nil then
				b:dbat(50+(((i-1)%3)*9),
				       89+(flr(i/3)*9))
			end
		end
		--highlight sqr for select
		if btl.f1==-1 then
			if flr(fcnt/8)%2==0 then
				local dx=btl.menu_pos*9
				rect(49+dx,88+dx,58+dx,97+dx,7)
			end
		elseif btl.f2==-1 then
			local dx=btl.f1*9
			rect(49+dx,88+dx,58+dx,97+dx,7)
			if flr(fcnt/8)%2==0 then
				dx=btl.menu_pos%3*9
				local dy=flr(btl.menu_pos/3)*9
				rect(49+dx,88+dy,58+dx,97+dy,10)
				--todo:draw full line
			end
		end
	end
	
	--todo:draw btl bugs
end

function _draw()
 game_handler:draw()
end



shop_names={
"ye olde glom shoppe",
"the glom shop",
"the glommery",
"glom",
"ye olde glom shoppe",
"the glom shop",
"the glommery",
"glom here",
"ye olde glom shoppe",
"the glom shop",
"the glommery",
"glom",
"ye olde glom shoppe",
"ye olde glom shoppe",
"glom",
"gloms",
"ye olde glom shoppe",
"the glom shop",
"the glommery",
"glom",
"ye olde glom shoppe",
"the glom shop",
"the glommery",
"glom",
"ye olde glom shoppe",
"the glom shop",
"the glommery",
"glom",
"ye olde glom shoppe",
"ye olde glom shoppe",
"glom",
"glom",
"will glom 4 gold", --keep says he has a sale when this one is rolled
"gloms 4 cash",
"glom one, glom all!",
"the olde glommery",
"aglominations",
"aglominable shopman",
"a glommy place",
"never glum glommery",
"here be glommers",
"glomming for glory",
"glom here!",
"dropping the glom",
"* glam gloms *",
"gleeful gloms",
"church of glommism",
"glommity glom glom",
"we glom here",
"glomming 4 dummies",
"gloms",
"glitz, glam, gloms",
"g7om",
"glommification",
"glom!",
"glommery 2.0",
"the glom squad"
}
-->8
--- position handling ---
function mts_x(x)--map to screen
 return (x-screen_x)*8
end
function mts_y(y)
 return (y-screen_y)*8
end

local pos_mt={
	__eq=function(a,b)
		return a.x==b.x and a.y==b.y
	end
}
function pos(x,y)
	local t={x=x,y=y}
	setmetatable(t,pos_mt)
	return t
end

function mv(v,dx,dy)
 local nx=v.x+dx
 local ny=v.y+dy
 
 local c1=mget(nx,ny)
 if (fget(c1,0)) return nil
 return pos(nx,ny)
end

--checks all map versions for col
function check_pos(pos)
	for i=0,2 do
		local s=mget((i*mw)+pos.x,pos.y)
		if (fget(s)~=0) return s
	end
end
function check_pos2(x,y)
	return check_pos(pos(x,y))
end

function processinput()
 wtng=true
end

-- drawing --

menu_drawing={
	{80,80,80,82,81,82,82,80,80,81,80,82,80,80,80,80},
	{80,83,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,83,80},
	{80,0 ,73,86,0 ,0 ,0 ,84,0 ,0 ,0 ,0 ,88,74,0 ,80},
	{80,0 ,88,0 ,0 ,84,84,0 ,0 ,0 ,0 ,0 ,0 ,87,26,80},
	{81,0 ,0 ,89,0 ,0 ,0 ,86,84,0 ,0 ,0 ,89,89,0 ,81},
	{82,0 ,89,89,85,88,84,0 ,0 ,0 ,0 ,84,0 ,89,0 ,81},
	{80,0 ,0 ,0 ,0 ,84,0 ,0 ,0 ,0 ,0 ,84,0 ,89,0 ,82},
	{80,0 ,0 ,0 ,87,0 ,0 ,0 ,0 ,0 ,0 ,84,0 ,0 ,0 ,82},
	{80,0 ,84,88,0 ,0 ,0 ,0 ,0 ,89,89,84,0 ,0 ,0 ,81},
	{80,0 ,87,86,84,0 ,0 ,0 ,0 ,0 ,89,89,0 ,87,0 ,80},
	{80,0 ,84,84,84,93,0 ,0 ,0 ,0 ,0 ,85,88,89,0 ,80},
	{80,0 ,0 ,0 ,84,84,0 ,0 ,0 ,82,85,0 ,89,89,0 ,80},
	{80,0 ,85,0 ,0 ,89,0 ,0 ,83,83,0 ,0 ,84,86,0 ,81},
	{80,0 ,67,87,89,89,0 ,83,0 ,84,83,0 ,85,77,0 ,81},
	{82,83,0 ,89,89,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,83,81},
	{82,82,81,82,81,80,80,80,80,80,80,81,82,81,82,81}
}
function prepare_menu()
	clearmap()
 for j,r in ipairs(menu_drawing) do
 	for i,c in ipairs(r) do
 		mset(i-1,j-1,c)
 	end
 end
end

bug_select_drawing={
	{80,80,80,80,80,80,80},
	{80,93,84,84,84,84,80},
	{80,84,84,0 ,84,84,80},
	{80,84,86,84,0 ,84,80},
	{80,84,84,0 ,84,87,80},
	{80,84,84,84,84,84,80},
	{80,80,80,80,80,80,80}
}
function prepare_bug_select()
	clearmap()
 screen_x=-4.5
 screen_y=-4.5
	gd:newgame()
 for j,r in ipairs(bug_select_drawing) do
 	for i,c in ipairs(r) do
 		mset(i-1,j-1,c)
 	end
 end
 pv=pos(2,3)
 gd.level=0 --no shinies yet
 local b1=genmob()
 b1:bmv(pos(3,2))
 local b2=genmob()
 b2:bmv(pos(4,3))
 local b3=genmob()--allow dups?
 b3:bmv(pos(3,4))
 map_bugs={b1,b2,b3}
 portalx=5
 portaly=5
	mset(portalx,portaly,75)
 if (rnd(10)<1) mset(1,5,67)
 bug_select.t1='let\'s see, which bug should\ni bring along this time?'
 bug_select.t2=''
end

btl_drawing={
	{82,82,82,82,82,82,82,82,82,82,82,82,82},
	{82, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,82},
	{82, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,82},
	{82, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,82},
	{82, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,82},
	{82, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,82},
	{82, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,82},
	{82, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,82},
	{82,82,82,82,82,82,82,82,82,82,82,82,82},
}
function prepare_btl()
	--screen_x=max(min(pv.x-8,mw-16),0)
	--screen_y=max(min(pv.y-8,mw-16),0)
	clearm4()
	for j,r in ipairs(btl_drawing) do
 	for i,c in ipairs(r) do
 		mset(3*mw+i-1,j-1,c)
 	end
 end
 pflip=false
 btl.menu='main'
 btl.menu_pos=0
 btl.f1=-1
 btl.f2=-1
 --todo: assign btl bugs. remove
 --      bug from map
end
-->8
--- player handling ---
pv=pos(1,1)
pflip=false
mto=nil
mf=0
function dp()--draw player
	if mto!=nil then
	 move()
	else
  idle()
 end
end

function get_psprite()
	if (gd.swap_psprite) return 69
	return 101
end
pf=get_psprite()

function idle()
	idleat(mts_x(pv.x),
	       mts_y(pv.y))
end

function idleat(x,y)
	spr(pf,x,y,
	    1,1,pflip)
 if fcnt==0 or fcnt==8 or fcnt==15 or fcnt==23 then
 	local p0=get_psprite()
 	if pf==p0 then
 		pf=p0+3
 	elseif pf==p0+3 then
 	 pf=p0
 	end
 end
end

function move()
 --move first, then check cols
 --then unset mto so mobs move
 if mf==0 then
 	spr(get_psprite(),
 	    mts_x(pv.x),
 	    mts_y(pv.y),
 	    1,1,pflip)
		mf+=1
 elseif mf==1 then
 	spr(get_psprite()+1,
 	    mts_x(((mto.x-pv.x)*0.4)+pv.x),
 	    mts_y(((mto.y-pv.y)*0.4)+pv.y),
 	    1,1,pflip)
		mf+=1
 elseif mf==2 then
 	spr(get_psprite()+2,
 	    mts_x(((mto.x-pv.x)*0.6)+pv.x),
 	    mts_y(((mto.y-pv.y)*0.6)+pv.y),
 	    1,1,pflip)
		mf+=1
 else
 	spr(get_psprite(),
 	    mts_x(mto.x),
 	    mts_y(mto.y),
 	    1,1,pflip)
 	pv=mto
 	mto=nil
		mf=0
		game_handler:handlecols()
 end
end

function game.handlecols()
 --note that wall cols are handled
 --in mv() so we only need obj cols here
	local c2=mget(pv.x+mw+mw,pv.y)
	local c1=mget(pv.x+mw,pv.y)
	local c0=mget(pv.x,pv.y)
	if fget(c2,1) then
		--this is a monster. init btl.
		prepare_btl()
	 game_handler=btl
	elseif fget(c0,3) then
		--portal. new level.
		gd.level+=1
		init_genlvl()
	end
end

function bug_select.handlecols()
 --note that wall cols are handled
 --in mv() so we only need obj cols here
	local c2=mget(pv.x+mw+mw,pv.y)
	local c0=mget(pv.x,pv.y)
	if fget(c2,1) then
		--this is a monster.
	 bug_select.t2='press 🅾️ to select'
	elseif fget(c0,3) then
		if (gd.bugs[1]==nil) then
			bug_select.t2='i need to pick a bug first.'
		else
			--portal. first level
			gd.level=0
			init_genlvl()
			game_handler=game
		end
	else
		bug_select.t2=''
	end
end

-- legel gen --

function init_genlvl()
	genlvl(rndi(0x7fff.ffff))
end

function genlvl(seed)
	gd.seed=seed
	srand(seed)
	clearmap()
	pv=pos(rndi(mw-2)+1,
	       rndi(30)+1)
	mset(pv.x,pv.y,80)
	genwalls()
	genimportants()
	gendecor()
	for i=1,24 do
		map_bugs[i]=genmob()
	end
	mset(pv.x,pv.y,0)
end

function clearmap()
	for i=0,3*mw-1 do
		for j=0,31 do
			mset(i,j,0)
		end
	end
end

function clearm4()
	for i=3*mw,4*mw-1 do
		for j=0,31 do
			mset(i,j,0)
		end
	end
end

-- all 8 dirs
-- starts at o r and goes around
-- cir ccwise. opposites 4 apt.
local dir8 = {
	pos(1,0),
	pos(1,1),
	pos(0,1),
	pos(-1,1),
	pos(-1,0),
	pos(-1,-1),
	pos(0,-1),
	pos(1,-1)
}
function genwalls()
	-- draw the border
	for j=0,31 do
		mset(0,j,randwall())
		mset(mw-1,j,randwall())
	end
	for i=1,mw-2 do
		mset(i,0,randwall())
		mset(i,31,randwall())
	end
	-- dance around dropping more
	-- walls in.
	for i=0,rnd(6) do
		local last=pos(0,0)
		-- pick a starting point
		local st=pos(rndi(mw-2)+1,
		             rndi(29)+1)
		if (wallcheck(st,last)) then
			mset(st.x,st.y,randwall())
		end
	end
end

function randwall()
	local i=rndi(3)
	return i+80
end

function wallcheck(p,last)
	-- if there's already a wall
	-- here, it's ok to have one
	if (fget(mget(p.x,p.y),0)) return true
	-- if there's a wall in any
	-- of the 8 dirs, except the
	-- borders, then this is a col
	-- that we can't permit.
	-- we also skip last, which is
	-- the wall we just came from.
	local skip=pos(-last.x,-last.y)
	for i=1,8 do
		local dp=dir8[i]
		if dp~=skip then
			local check_x=p.x+dp.x
			local check_y=p.y+dp.y
			if check_x>0 and check_x<mw-1 and check_y>0 and check_y<31 then
				-- we actually care about this one
				if (fget(mget(check_x,check_y),0)) return false
			end
		end
	end
	return true
	--todo: this isnt quite right
	--this will block off walls
	--need to have some starts on
	--walls and some off and need
	--to check walls for cols here
end

function genimportants()
	--chest:67 can be 0-2
	--nurse:73 glom:74 port:75
	--decor sprite
	local success
	repeat
		portalx=rndi(mw-2)+1
		portaly=rndi(29)+1
		success=mv(pos(0,0),
		           portalx,
		           portaly)
	until success~=nil
	mset(portalx,portaly,75)
end

function gendecor()
	for i=1,30 do
		for j=1,30 do
			if check_pos2(i,j)==nil and rnd(7)<1 then
				local s=83+rndi(11)
				mset(i+mw,j,s)
			end
		end
	end
end
-->8
--- input handling ---
wtng=true--whether we're awaiting input
function checkforinput()
	if (not wtng) return

	local dx=0 dy=0 movebtn=false
 if btn(0) then
 	dx=-1
 	pflip=true
 	movebtn=true
 elseif btn(1) then
 	dx=1
 	pflip=false
  movebtn=true
 elseif btn(2) then
 	dy=-1
  movebtn=true
 elseif btn(3) then
 	dy=1
  movebtn=true
 end
 
 if movebtn then
 	mto=mv(pv,dx,dy)
 	if (mto!=nil) wtng=false
 end
end

function apress()
	return (gd.swap_ab_btns and btnp(5)) or (btnp(4) and not gd.swap_ab_buttons)
end

function bpress()
	return (gd.swap_ab_btns and btnp(4)) or (btnp(5) and not gd.swap_ab_buttons)
end

function update_sprites()
	if (fcnt%15)==0 then
		local portals=mget(portalx,portaly)
		portals+=1
		if (portals==78) portals=75
		mset(portalx,portaly,portals)
	end
end
-->8
--- mob handling ---

mapbug=bug:new({
	p=pos(0,0),
	
	bmv=function(self,dest)
		mset(self.p.x+mw+mw,
		     self.p.y,
		     0)
		self.p=dest
		mset(dest.x+mw+mw,
		     dest.y,
		     self.number)
	end,
	db=function(self)
		self:dbat(mts_x(self.p.x),
			         mts_y(self.p.y))
	end,
	clear_from_map=function(self)
		mset(self.p.x+mw+mw,
		     self.p.y,
		     0)
	end
})

function genmob()
	local b=mapbug:new()
	--number must happen b4 bmv
	b.number=rndi(55)+1
	b.cmod=cmod()
	b.bflip=rndi(2)==1
	local moved
	repeat
		moved=mv(b.p,
		         rndi(mw),
		         rndi(32))
		if (moved~=nil and check_pos(moved)~=nil) moved=nil
	until moved~=nil
	b:bmv(moved)
	return b
end

function cmod()
	if (rndi(256) >= gd.level) return 0

	local n=rndi(32767)
	local i=1 j=2^15
	while i<15 do
		if ((j&n)==j) return i
		i+=1
		j=j>>>1
	end
	return i
end

function get_mbug_at_pos(p)
	for mb in all(map_bugs) do
		if (mb.p==p) return mb
	end
	return nil
end

function mbug_to_bbug(mbug)
	--bug lvl goes 0-31
	--on highest floor (8), want
	--bugs high lvl but not max.
	--max should only happen via
	--training. so say wild bug
	--max is... 23. then just
	--3 lvls per floor.
	lvl=3*gd.level+rndi(3)
	b=team_bug:new()
	b.lvl=lvl
	b.number=mbug.number
	b.cmod=mbug.cmod
	
	--todo: tune stats
	b.max_hp=63
	b.max_pow=31
	b.max_def=31
	b.max_spd=31
	b:calcstatsfromlvl()
	b.hp_rem=b.hp
	
	return b
end

function from_lvl(lvl,statmax)
	--max lvl 31.
	--idk just linear spline
	return statmax*(lvl+1)/32
end
__gfx__
0000000000000000044420000000000006000000600000000555500000001000077700000111100000000000000600200000000008000800aaaa0b00000a0000
000000000566cc0044444002066600005d600066060000665656550000111100777770001111110005bb000005bb00220080800008888800089a30b0000a0aa0
007007005d776670484842229696600005d6006600600066555555700111110078b77000121211c08bbb00008bbb022200282000089898000999a0b0a0a90a00
0007700001dc71024444412266666000005d40090006400a55555570119111107bb77000111111cc000bb000000bb20000888000008880000899a0b090a4990a
000770002016100244444100ccc66d000004889900048aaa155551771111111077777000111111cc0003b0000003b0000003000000030000444400b042a9a404
0070070024010402011110000ddddd00000080090000000a6171700701111111eeeee00001111ccc0003bbb00003bbb00b03b0000b0030b00000030029898aa0
0000000024f0f402005050000dddddd000000099000000aa60600707011111110eee00000cccccc6000033330000333300b300000bb030b00b00300b24929290
000000000000000000505000015ddddd0000090900000a0a6060060611111111000eeeee06060606000000000000000000030000000b3b0000333bb002444220
0ffff0f000677000000aa0000444400000000000000d0000607000000000000000b03e000e00e0e00000000000070000007700000055500000000b0000220000
f000ff0f0677700000777a00ff1f4400000000000d111d02067000000770000003b03b0000e0e0e0000000000077700000060000057775000000400000022ff0
0fffffff05550000067777a0fffff4400088780002ddd100ff000000a770000008b03bb0e0e66e00074000000d6777000aa00000057cc50000884e000099299f
f00fffff5c5550000697977009fff94008788880de7de7d00fffff7000777700033bba300e6666e0444000400d677700980aaaaa15777510028888e009a9a999
0fffffff55555000d677777a09fff940022222700d2ddd000ffffff0007777000033bb0002dddd20004455000d6677009009090915bb751002c8c8e0049999a9
f00ffff005550000d67777770999904000343f0001ddd20000f0f0f0000770000013b500202dd2000044440000ddd000099009090577750002288880024aaa90
0000fff0000000000d66677000f0f0400004f0000001000100f0f0f000a00a00000150000020202000404400000000000000f0f0005550000022220000224400
000444440000000000dddd00022022000004f0000100000000404040000000000001500002002020004044000000000000000000001010000000000000000000
000000000009000060000000000770000000eeed08b80000000000000400b44000677000087778e00a000a000077700000000000000000000000000000000000
000000e0900990006d0000000eeee700001111ee00b0000000000000bb33330b006370007bbb877e0aa99a000700070700777000006006000000000000000000
0000000e9900904065d000002eeeee000222211e003b700000000000403b3334006b7000b17bb77e0099990a70008070077777000077767000000000000b7700
0000550e09999040065d000023ee3e702ff22211b3b3b6700004400004a3a3b308888e003116b88e0999899a7080007007c7c700077777770000000008867770
00e5555e089899400065d0002eeeee60fffff222b0b13b0000c4c4003b044030888888e03bbbb77ea98999900700770007777700077777770006660000f4fff0
85555550099994000004440002eee6008ff8ff20000013b00002200000044080022222007333778e009999aa007700000777770007b7b7770055556000ffff00
002002000020200000c2c4400002e000ffffff00000b3b3b000000000040040000000000087788e00aa9900a70007700070707000777777700d5d55600011100
0000000000000000000222220b0020b000000000000b0b0b00000000004004000000000000eeeeee0a00a00000000007000000000707070700555555000c0c00
000000000e00000005303b0000220000000000000000000000000000005000500000000000000000000000000000000000000000000000000000000000000000
00000d00beb00000b066600b22222000000000000000000000666600004444500000000000000000000000000000000000000000000000000000000000000000
0000ddd000a90000355876330822200000000000000000000d26d260044444540000000000000000000000000000000000000000000000000000000000000000
000005dd949a900005e1860011111200000888000c00000002262266024224440000000000000000000000000000000000000000000000000000000000000000
0040005d9090a900355e563b0011120e00858850c00bbb0006666616044444440000000000000000000000000000000000000000000000000000000000000000
0484445d00000af03055500300d11202dd8858809cbbbbb000777160070704440000000000000000000000000000000000000000000000000000000000000000
00155550000454d45030330000dd122255222120dd33333000000060000004050000000000000000000000000000000000000000000000000000000000000000
0040040000040404005003b00010100000d0d0d00050505000666600044446060000000000000000000000000000000000000000000000000000000000000000
0ffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaa0000aaaa0000aaaa000000000000000000
ffffffff00000000000000000000000000499400002220000022200000222000000000000077770000444400097cc6a009ccdca009cdd7a00000000000000000
ffffffff000800000000000000444400045555400222211002222110022221100022200007787770044ce4409cdc6cca9c66cdca96c6ccca0000000000000000
9ff9ffff000800080000000004444440045555400fffcf000fffcf000fffcf000222211007888770044444409cc76dca97cd6c7a9c6c7c6a0000000000000000
ffffffff0008002800000000044994400655556000ffff0000ffff0000ffff000fffcf00077877700444114096dc6dca9cd76cca9c7dd6ca0000000000000000
ffffffff0000008000000000066996600666666000333000003332000233300000ffff0007771170044419409cbc3b7a9ccbcbca9cbcb3ca0000000000000000
ffffffff000800000000000004444440044444400020200000200000000020000020200007771170044411409bbbbbba9b3b3bba93bbbbba0000000000000000
0ffffff0000008000000000000000000000000000000000000000000000000000000000000000000000000000999999009999990099999900000000000000000
00066600000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000500000000000000000000000000
00555560000300000000300000000060000000000000000000000000000000000000000000000000000500000000060000000000000000000000000000000000
0055555600033000000333000000000000000000000880000000000000099000000000000300000503000005003000000000d000000000000000000000000000
06655556003333000033330050006000000000000008800000aa000000099000000000000000000000000000000000000060000000aa00000000000000000000
05565555033323300333333000055600030000000000300000aa0000000030000000ee000000000000000000000000030000000003aa00000000000000000000
5555ddd5003333000033330000dd55000030030000003b0000300000000b30000000ee0000000000000000000500000000000030003003000000000000000000
dd550000033333300333333000000000000030000000300000300000000030000000030000000000000600000000000000000000003030000000000000000000
00000000000440000004400000000050000000000000000000000000000000000000000000600000000000000000050000500000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000022200000222000002220000000000000000000006770000002220000000000000767700224008000000000
00000000000000000000000000000000000000000222211002222110022221100022200000022200067777000112222000000000007777772224490000000000
00000000000000000000000000000000000000000444340004443400044434000222211001122220677767000043444000000000007777672244498000000000
00000000000000000000000000000000000000000044440000444400004444000444340000434446776777000044446666666600077677701043490000000000
00000000000000000000000000000000000000000099900000999800089990000044440000444460007767000009990007777700077777700004400000000000
00000000000000000000000000000000000000000080800000800000000080000080800000080800000770000008080000676000066666666660000066600000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002240000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022444000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000123499800000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001044980000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dd0000000000000000099999990000000000000000000000000000000099990000000000000000000000000000000000000000000000000000000000000000
0d55d0000000000000002ccccccc90000000000000000000000000000099cccc9000009000000000000000000000000000000000000000000000000000000000
0d55d000000005500002cccccccc900000000009900009999900000009ccccccc90009c990000000000000000000000000000000000000000000000000000000
0d55d00000005115002ccccc66ccc9000000099cc9099ccccc9000009cccccccc90009ccc9000000000000000000000000000000000000000000000000000000
00d55d00000511150222ccc666ccc900099909ccc99ccc66cc900002cccc99999000009cc9000000000000000000000000000000000000000000000000000000
00d55d00000511550202cccc6ccc99992ccc909ccc9cc6666c900002ccc90000000009ccc9000000000000000000000000000000000000000000000000000000
000dd0000000555000022cccccccccc92ccc909ccc9cc6666c90002ccc900000000002ccc9099999000090000000000000000000000000000000000000000000
000000000000000000002cccccc66ccc92cc909ccc9cc66ccc90002ccc900009990002ccc92ccccc9002c9999900000000000000000000000000000000000000
000dd0000000000000002ccccc6666cc92ccc9cccc9ccccccc90002ccc90009ccc9002cc92ccc66cc902cccccc90000000000000000000000000000000000000
00d55d000000000000002ccccc6666cc92ccccccc90222cccc90002ccc9009ccccc902cc92ccc666c902ccccccc9000000000000000000000000000000000000
00d55d000555000000002cccccc66ccc902cccccc900202ccc90002cccc909cc9ccc22cc9cccccccc92ccc22ccc9000000000000000000000000000000000000
000d5d0051115000000002cccccccccc9002ccc22022c99ccc90002ccccc99999ccc2ccc9cccccc2c22cc2002cc9000000000000000000000000000000000000
000d5d0051111550000002ccccccccc200002220002ccccccc900002cccccccccccc2cc92ccc2222502cc2002cc2000000000000000000000000000000000000
000d5d0005551115000002ccccccccc2000000000022ccccc20000002cccccccccc22cc202cc2999c2cc2292cc20000000000000000000000000000000000000
000d5d00000055150000002ccccc222200000000000222cc22000000022ccccccc222cc202cccccc22cc22ccc200000000000000000000000000000000000000
0000d0000000005000000002222220000000000000000222200000000002222222202c200022222202c222ccc200000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000002200222000000000000000000000000000000000000000
000000a0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000aa99a0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000caaaaa990a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000aaa8aaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d555aaaaab0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d555555aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dd5555255500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000dd555225200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d575556500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d5577555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001d557770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001d55550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000dd500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999290000000000000000000000000ffffffe00000000000777000000000004444440000000000000000000000000000000000000000000000000000000000
11111190000000000000000000000000666666f0000000006777777777777000fffff44000000000000000000000000000000000000000000000000000000000
11111190000000000000000000000000666666f0000000066778777777777700ffffff4000000000000044000000000000454444455544440000000000000000
11111190000000444000000000000000666666f0000000066778777777777770ffffff4000000005504444444400000000044444444444440000000000000000
11111190000000404400444444000000666666f0000000666888887777777770ffffff4000000005554444444440000000044555555555550000000000000000
11111190000044444444444404400000666666f0000000666778777777777770ffffff4000000055544444444444000000004444444444440000000000000000
111111900004044444fff44444440000666666f0000000666778777777777770ffffff4000000055544444444444000000444455444444440000000000000000
1111119000004444fffff44f44044000666666f0000000667777777777777770ffffff4000000055994444444444000000044444444444440000000000000000
111111900000444ffffff44444004000666666f0000000667fffffff77777700ffffff4000000059999444444444000000554444444444440000000000000000
111111900000444ffffff44444404000666666f00000009fffffffffff9ff900ffffff4000040055544444444444004000444555555544550000000000000000
11111190044444fffffff44444404400666666f00000009fffffffffff9ff900ffffff4000044444444444444444440000004444445555540000000000000000
1111119004044ffcc7fffc4444400400666666f00000009fffffffffff9ff900ffffff40000000fffffffffff666000000004444444444440000000000000000
1111119004040ffccffffcc444440440666666f0000000fffeffefffff9ff900ffffff40000000fffffffffff666000000055555444444440000000000000000
1111119004444fffffffffffff044044666666f0000000ffffffffffff9ff900ffffff40000000f66f66fffffff6000000444444444455550000000000000000
1111119000444fffffffffffff044004666666f0000000ffffffffffffff0900ffffff40000000fffffffffffff0000000000000000000000000000000000000
11111111000444fff2222fffff04040466666666000000fff5fff5ffffff0900ffffffff000000ff222ffffffff0000000000000000000000000000000000000
111111110000440fffffffffff040404666666660000000fff555ffffff90900ffffffff0000000ffffffffff440000000000000000000000000000000000000
111111110000044fffffffffff0440446666666600000000ffffffffff090909ffffffff0000000444ffffff4444000000000000000000000000000000000000
11111111000000409ffffff90404404066666666000000000fffffff77790909ffffffff00000004444444444444000000000000000000000000000000000000
1111111100000040f99b999f040400406666666600000000776ff77777770999ffffffff00000044444444444444400000000000000000000000000000000000
111111110006dd6dffffffffd6dddd6066666666000000077677777777777000ffffffff00000044444444444444440000000000000000000000000000000000
11111111006dddd6dddddddd665dd66d66666666000000077677777777777700ffffffff00000444455444444444440000000000000000000000000000000000
1111111106ddddd56ddddd6655ddd6dd66666666000000776677777777777700ffffffff00004444455444444544440000000000000000000000000000000000
00000000d6dddddd55dddddddddddddd000000000000007767777777777777000000000000004454444444444544444000000000000000000000000000000000
000000006dd66ddddddddddddddddddd000000000000007767777777777777700000000000004454444444444544444000000000000000000000000000000000
000000006dd666666dddddd6666ddd6d000000000000077767777777777777700000000000004554554444444554444000000000000000000000000000000000
000000006ddddddd6dddd666dddd5dd6000000000000077767777777777777700000000000004544554444444454444000000000000000000000000000000000
000000006d5ddddddddd66dddddd55d6000000000000077767777777777777700000000000004544444444444454444000000000000000000000000000000000
000000006d5dddddddddddddddddd5d6000000000000077767777777777777700000000000004544444444444454444000000000000000000000000000000000
00000000dd5dddddddd5ddddddddd5d6000000000000077767777777777777700000000000004544554444444554444000000000000000000000000000000000
00000000dd55dddd55dd55ddddddd5dd000000000000077767777777777777700000000000004544554444444544444000000000000000000000000000000000
__label__
hhh666hhhhh666hhhhh666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh666hhhhh666hhhhhhhhhhhhh666hhhhhhhhhhhhh666hhhhh666hhhhh666hhhhh666hh
hh55556hhh55556hhh55556hhhhh3hhhhhh3hhhhhhhh3hhhhhhh3hhhhh55556hhh55556hhhh3hhhhhh55556hhhhh3hhhhh55556hhh55556hhh55556hhh55556h
hh555556hh555556hh555556hhh333hhhhh33hhhhhh333hhhhh333hhhh555556hh555556hhh33hhhhh555556hhh333hhhh555556hh555556hh555556hh555556
h6655556h6655556h6655556hh3333hhhh3333hhhh3333hhhh3333hhh6655556h6655556hh3333hhh6655556hh3333hhh6655556h6655556h6655556h6655556
h5565555h5565555h5565555h333333hh333233hh333333hh333333hh5565555h5565555h333233hh5565555h333333hh5565555h5565555h5565555h5565555
5555ddd55555ddd55555ddd5hh3333hhhh3333hhhh3333hhhh3333hh5555ddd55555ddd5hh3333hh5555ddd5hh3333hh5555ddd55555ddd55555ddd55555ddd5
dd55hhhhdd55hhhhdd55hhhhh333333hh333333hh333333hh333333hdd55hhhhdd55hhhhh333333hdd55hhhhh333333hdd55hhhhdd55hhhhdd55hhhhdd55hhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhh44hhhhhh44hhhhhh44hhhhhh44hhhhhhhhhhhhhhhhhhhhhh44hhhhhhhhhhhhhh44hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhh666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh666hh
hh55556hhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhh55556h
hh555556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh555556
h66555565hhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhh6hhhh6655556
h5565555hhh556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh556hhh5565555
5555ddd5hhdd55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdd55hh5555ddd5
dd55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdd55hhhh
hhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhh
hhh666hhhhhhhhhhhhhhhhhhhhhhh9999999hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9999hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh666hh
hh55556hhhhhhhhhhh7777hhhhhh2ccccccc9hhhhhhhhhhhhhhhhhhhhhhhhhhhhh99cccc9hhhhh9hhhhhhhhhhhhhhhhhhhhhhhhhhh4444hhhhhhhhhhhh55556h
hh555556hhhhhhhhh778777hhhh2cccccccc9hhhhhhhhhh99hhhh99999hhhhhhh9ccccccc9hhh9c99hhhhhhhhhhhhhhhhhhhhhhhh44ce44hhhhhhhhhhh555556
h6655556hhhhhhhhh788877hhh2ccccc66ccc9hhhhhhh99cc9h99ccccc9hhhhh9cccccccc9hhh9ccc9hhhhhhhhhhhhhhhhhhhhhhh444444hhhhhhhhhh6655556
h5565555hhhhhhhhh778777hh222ccc666ccc9hhh999h9ccc99ccc66cc9hhhh2cccc99999hhhhh9cc9hhhhhhhhhhhhhhhhhheehhh444114hhhhhhhhhh5565555
5555ddd5hhhhhhhhh777117hh232cccc6ccc99992ccc9h9ccc9cc6666c9hh3h2ccc9hhhhhhhhh9ccc9hhhhhhhhhhhhhhhhhheehhh444194hhhhhhhhh5555ddd5
dd55hhhhhhhhhhhhh777117hhh322cccccccccc92ccc9h9ccc9cc6666c9h3h2ccc9hhhhhhhhhh2ccc9h99999hhhh9hhhhhhhh3hhh444114hhhhhhhhhdd55hhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhh2cccccc66ccc92cc9h9ccc9cc66ccc9hhh2ccc9hhhh999hhh2ccc92ccccc9hh2c99999hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhh666hhhhhhhhhhhhhhhhhhhhhh2ccccc6666cc92ccc9cccc9ccccccc9hhh2ccc9hhh9ccc9hh2cc92ccc66cc9h2cccccc9hhhhhhhhhhhhhhhhhhhhhhhh666hh
hh55556hhhhhhhhhhhhhhhhhhhhh2ccccc6666cc92ccccccc9h222cccc9hhh2ccc9hh9ccccc9h2cc92ccc666c9h2ccccccc9hhhhhhhhhhhhhhhhhhhhhh55556h
hh555556hhhhhhhhhhhhhhhhhhhh2cccccc66ccc9h2cccccc9hh2h2ccc9hhh2cccc9h9cc9ccc22cc9cccccccc92ccc22ccc9hhhhhhh99hhhh74hhhhhhh555556
h6655556hhhhhhhhhhhhhhhhhhhhh2cccccccccc9hh2ccc22h22c99ccc9hhh2ccccc99999ccc2ccc9cccccc2c22cc2hh2cc9hhhhhhh99hhh444hhh4hh6655556
h5565555hhhhhhhhhhhheehhhhhhh2ccccccccc2h3hh222hh32ccccccc9hhhh2cccccccccccc2cc92ccc22225h2cc2hh2cc2hhhhhhhh3hhhhh4455hhh5565555
5555ddd5hhhhhhhhhhhheehhhhhhh2ccccccccc2hh3hh3hhhh22ccccc2hhhhhh2cccccccccc22cc2h2cc2999c2cc2292cc2hhhhhhhhb3hhhhh4444hh5555ddd5
dd55hhhhhhhhhhhhhhhhh3hhhhhhhh2ccccc2222hhhh3hhhhhh222cc22hhhhhhh22ccccccc222cc2h2cccccc22cc22ccc2hhhhhhhhhh3hhhhh4h44hhdd55hhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh222222hhhhhhhhhhhhhhhh2222hhhhhhhhhh22222222h2c2hhh222222h2c222ccc2hhhhhhhhhhhhhhhh4h44hhhhhhhhhh
hhhhhhhhhhh1111hhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh22hh222hh5hhhhhhh5hhhhhhhhhhhhhhhhhhhh
hhh3hhhhhh111111hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhh
hhh33hhhhc112121hhhhhhhhh3hhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhh5h3hhhhh5hhhhhhhhhhh33hhh
hh3333hhcc111111hhhhhhhhhhhhhhhhhdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddhhhhhhhhhhhhhhhhhhhhhhhhhh3333hh
h333233hcc111111hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhaahhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh333233h
hh3333hhccc1111hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhh3hh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3333hh
h333333h6cccccchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh333333h
hhh44hhh6h6h6h6hhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhh6hhhhhhhhhhhhhhhh44hhh
hhhhhhhhhhhhhhhhhhh5hhhhhhh5hhhhhhhhhh666h6h6h666hhhhhh66h6hhhh66h666hhhhh6h6h666h66hhh66hhhhhhh6h7hhhhhhhh5hhhhhhhhhhhhhhhhhhhh
hhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hh6h6h6hhhhhhh6hhh6hhh6h6h666hhhhh6h6hh6hh6h6h6hhhhhhhhhh67hhhhhhhhhhhhhhhhhhhhhhhh3hhhh
hhh333hhhhhhhhhhh3hhhhh5h3hhhhh5hhh88hh6hh666h66hhhhhh6hhh6hhh6h6h6h6hhhhh66hhh6hh6h6h6hhhhhhhhhffhhhhhhh3hhhhh5hhhhhhhhhhh33hhh
hh3333hhhhhhhhhhhhhhhhhhhhhhhhhhhhh88hh6hh6h6h6hhhhhhh6h6h6hhh6h6h6h6hhhhh6h6hh6hh6h6h6h6hhhhhhhhfffff7hhhhhhhhhhhhhhhhhhh3333hh
h333333hhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hh6hh6h6e6663hhhh666h666h66hh6h6hhhhh6h6h666h6h6h6663hhhhhhhffffffhhhhhhhhhhhhhhhhhh333233h
hh3333hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3bhhhhhheehhhh3hh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hh3hhhhfhfhfhhhhhhhhhhhhhhhhhhh3333hh
h333333hhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhhh3hhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhfhfhfhhhhhhhhhhhhhhhhhh333333h
hhh44hhhhhhhhhhhhh6hhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4h4h4hhh6hhhhhhhhhhhhhhhh44hhh
hhh666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhh
hh55556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhh
hh555556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhh5hhhhhhhhhhh333hh
h6655556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3333hh
h5565555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh333333h
5555ddd5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hh3hhhhhhhhhhhhhhhhhhhhhhhhhhhh3333hh
dd55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhh333333h
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhh44hhh
hhh666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhaaaahbhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hh55556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh89a3hbhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhh
hh555556hhhhhhhhhhhhhhhhhhhhhhhhhhh99hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh999ahbhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh333hh
h6655556hhhhhhhhhhhhhhhhhhhhhhhhhhh99hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh899ahbhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3333hh
h5565555hhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4444hhbhhhhhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh333333h
5555ddd5hhhhhhhhhhhhhhhhhhhhhhhhhhhb3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhhhhhhh3hh3hhhhhhhhhhhhhhhhhhhhhhhhhhhh3333hh
dd55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbhh3hhbhhhhhhhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhh333333h
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh333bbhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44hhh
hhh666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hh55556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhh
hh555556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh222211hhhhhhhhhh3hhhhh5h3hhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh33hhh
h6655556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhfffcfhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3333hh
h5565555hhhhhhhhh3hhhhhhhhhheehhhhhhhhhhhhhhhhhhhhhhhhhhhhffffhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh333233h
5555ddd5hhhhhhhhhh3hh3hhhhhheehhhhhhhhhhhhhhhhhhhhhhhhhhhh333hhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hh3hhhhhhhhhhhhhhhhhhhhhhhhhhhh3333hh
dd55hhhhhhhhhhhhhhhh3hhhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhh2h2hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhh333333h
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44hhh
hhh666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh666hh
hh55556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh55556h
hh555556hhhhhhhhhhh99hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhh5h3hhhhh5hhhhhhhhhhh99hhhhhhhhhhhhh555556
h6655556hhhhhhhhhhh99hhhhhaahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh99hhhhhhhhhhhh6655556
h5565555hhhhhhhhh3hh3hhhhhaahhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhhhhhhh5565555
5555ddd5hhhhhhhhhh3b33hhhh3hhhhhhh3hh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhb3hhhhhhhhhhh5555ddd5
dd55hhhhhhhhhhhhhhhh3hhhhh3hhhhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhhhhhhdd55hhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhh666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhh666hh
hh55556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh55556h
hh555556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh88hhhhhhhhhhhh3hhhhh5hhhhhhhhhh555556
h6655556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhaahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh88hhhhhhhhhhhhhhhhhhhhhhhhhhhh6655556
h5565555hhhhhhhhh3hhhhhhh3hhhhhhh3hhhhhhh3aahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhheehhhhhhhhhhhhhhhhhhh5565555
5555ddd5hhhhhhhhhh3hh3hhhh3hh3hhhh3hh3hhhh3hh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3bhhhhhheehhhhhhhhhhhhhhhhhh5555ddd5
dd55hhhhhhhhhhhhhhhh3hhhhhhh3hhhhhhh3hhhhh3h3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhhh3hhhhhhhhhhhhhhhhhhdd55hhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhh
hhh666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhh5hhhhhhhhhhhhhhh666hh
hh55556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh55556h
hh555556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh333hhhhh88hhhhhhhhhhhh3hhhhh5h3hhhhh5hhhhhhhhhh555556
h6655556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3333hhhhh88hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6655556
h5565555hhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh333333hhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5565555
5555ddd5hhhhhhhhhhhhhhhhhhhhhhhhhh3hh3hhhh3hh3hhhhhhhhhhhhhhhhhhhhhhhhhhhh3333hhhhhh3bhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5555ddd5
dd55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhh333333hhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdd55hhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44hhhhhhhhhhhhhhhhhhhhh6hhhhhhh6hhhhhhhhhhhhhhhhhhhhh
hhh666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hh55556hhhhhhhhhhhhhhhhhhhhhhhhhh77hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhh
hh555556hhhhhhhhhhh88hhhhhhhhhhha77hhhhhh3hhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh33hhh
h6655556hhhhhhhhhhh88hhhhhhhhhhhhh7777hhhhhhhhhhhhhhhhhhhhhhhhhh5hhh6hhh5hhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhaahhhhhhhhhhhhhh3333hh
h5565555hhhhhhhhhhhh3hhhhhhhhhhhhh7777hhhhhhhhhhhhhhhhhhhhhhhhhhhhh556hhhhh556hhhhhhhhhhhhhhhhhhh3hhhhhhhhaahhhhhhhhhhhhh333233h
5555ddd5hhhhhhhhhhhh3bhhhhhhhhhhhhh77hhhhhhhhhhhhhhhhhhhhhhhhhhhhhdd55hhhhdd55hhhhhhhhhhhhhhhhhhhh3hh3hhhh3hhhhhhhhhhhhhhh3333hh
dd55hhhhhhhhhhhhhhhh3hhhhhhhhhhhhhahhahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3hhhhh3hhhhhhhhhhhhhh333333h
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44hhh
hhh666hhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhh7hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhaaaahhhhhhhhhhhhhhhhhh
hh55556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh777hhhhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhhhh9cdd7ahhhhhhhhhhhh3hhhh
hh555556hhhhhhhhhh4444hhhhh99hhhh3hhhhh5hd6777h5hhhhhhhhhhhhhhhhhh8878hhhhhhhhhhhhhhhhhhhhhhhhhhhhh88hhh96c6cccahhhhhhhhhhh33hhh
h6655556hhhhhhhhh444444hhhh99hhhhhhhhhhhhd6777hhhhhhhhhh5hhh6hhhh878888hhhhhhhhh5hhh6hhhhhhhhhhhhhh88hhh9c6c7c6ahhhhhhhhhh3333hh
h5565555hhhhhhhhh449944hhhhh3hhhhhhhhhhhhd6677hhhhhhhhhhhhh556hhh222227hh3hhhhhhhhh556hhhhhhhhhhhhhh3hhh9c7dd6cahhhhhhhhh333233h
5555ddd5hhhhhhhhh669966hhhhb3hhhhhhhhhhhhhdddhhhhhhhhhhhhhdd55hhhh343fhhhh3hh3hhhhdd55hhhhhhhhhhhhhh3bhh9cbcb3cahhhhhhhhhh3333hh
dd55hhhhhhhhhhhhh444444hhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4fhhhhhhh3hhhhhhhhhhhhhhhhhhhhhhh3hhh93bbbbbahhhhhhhhh333333h
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhh6hhhhhhhhhhhhhhhhhhh5hhhh4fhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhh999999hhhhhhhhhhhh44hhh
hhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhh3hhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd111dh2hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhh3hhhh
hhh333hhhhhhhhhhhhhhhhhhh3hhhhh5h3hhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh2ddd1hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh33hhh
hh3333hh5hhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhde7de7dhhhhhhhhhhhhhhhhhhhhhhhhh5hhh6hhhhh3333hh
h333333hhhh556hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd2dddhhhhhhhhhhhhhhhhhhhhhhhhhhhhh556hhh333233h
hh3333hhhhdd55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh1ddd2hhhhhhhhhhhhhhhhhhhhhhhhhhhhdd55hhhh3333hh
h333333hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh1hhh1hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh333333h
hhh44hhhhhhhhh5hhhhhhhhhhh6hhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh1hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhh44hhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh666hhhhh666hhhhh666hhhhh666hhhhh666hhhhh666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhh3hhhhhhh3hhhhhh3hhhhhhhh3hhhhhh3hhhhhh55556hhh55556hhh55556hhh55556hhh55556hhh55556hhhh3hhhhhhhh3hhhhhh3hhhhhhhh3hhhhhh3hhhh
hhh333hhhhh333hhhhh33hhhhhh333hhhhh33hhhhh555556hh555556hh555556hh555556hh555556hh555556hhh33hhhhhh333hhhhh33hhhhhh333hhhhh33hhh
hh3333hhhh3333hhhh3333hhhh3333hhhh3333hhh6655556h6655556h6655556h6655556h6655556h6655556hh3333hhhh3333hhhh3333hhhh3333hhhh3333hh
h333333hh333333hh333233hh333333hh333233hh5565555h5565555h5565555h5565555h5565555h5565555h333233hh333333hh333233hh333333hh333233h
hh3333hhhh3333hhhh3333hhhh3333hhhh3333hh5555ddd55555ddd55555ddd55555ddd55555ddd55555ddd5hh3333hhhh3333hhhh3333hhhh3333hhhh3333hh
h333333hh333333hh333333hh333333hh333333hdd55hhhhdd55hhhhdd55hhhhdd55hhhhdd55hhhhdd55hhhhh333333hh333333hh333333hh333333hh333333h
hhh44hhhhhh44hhhhhh44hhhhhh44hhhhhh44hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44hhhhhh44hhhhhh44hhhhhh44hhhhhh44hhh

__gff__
0002020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000004000000000004040808080000010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
5050505251525250505150525050505041414141414141414141414141414141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5053000000000000000000000000535000000000000000000000000000000041005300000000000000000000000053000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
500049560000005400000000584a005000000000000000000000000000000041000049560000005400000000584a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000580000545400000000000057005000000000000000000000000000000041000058000054540000000000005700000042000000000055000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5155005900000056540000005959005100000000000000000000000000000041000000420000005654000000424200000000000000000000000000554200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5200595955585400000000540059005100000000000000000000000000000041000042425558540000000054004200000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000540000000000540059005200000000000000000000000000000041000000000054000000000054004200000000550000550000000000420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000057000000000000540000005200000000000000000000000000000041000000005700000000000054000000000000000000565600000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000545800000000005959540000005100000000000000000000000000000041000054580000000000424254000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000575654000000000059590057005000000000000000000000000000000041000054005400000000004242000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000545454560000000000555859005000000000000000000000000000000041000054545454000000000000004200000000000000000000000055000000420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000054540000005255005959005000000000000000000000000000000041000000005454000000000000424200000056565300000000000000005400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000590000535300005456005100000000000000000000000000000041000055000042000053530000545600000000005600000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
500043005959005300545300554d005100000000000000000000000000000041000043574242005354545300554b00000000565600000057005700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5253005959000000000000000000535100000000000000000000000000000041005300424200000000000000000053000053530000000057560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5252515251505050505050515251525100000000000000000000000000000041000000000000000000000000000000000053000000000057560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5200000000000000000000000000000000000000000000000000000000000041000000000055555400000000000000000000000000420057000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5100000000000000000000000000000000000000000000000000000000000041000000004200000000000000005356000000000000000057000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5200000000000000000000000000000000000000000000000000000000000041000000000000550000000000530000000000540000000000000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5200000000000000000000000000000000000000000000000000000000000041000000004200000000575300000000005454000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000000000000000000000000000000000000041000000000000005656530000000000425400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000000000000000000000000000000000000041000000000000000000000000575756560057570000000000000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000000000000000000000000000000000000041000000000000000000000000000000000000000000565600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000000000000000000000000000000000000041000000000000000000005600000000000000000000005600570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000000000000000000000000000000000000041000000550000000055560000000000000000000000005600000000004255000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000000000000000000000000000000000000041000000000000000000000000545454540054000042000000555500000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000000000000000000000000000000000000041000000000000000000000000420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000000000000000000000000000000000000041000000005500004200000000000000000000000000000000000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000000000000000000000000000000000000041000000000000555600000000000000000042560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000000000000000000000000000000000000041000000000000000000000000000000004200000000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000000000000000000000000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414141414141414141414141414141414141414141414141414141414141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
