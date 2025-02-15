pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- pico sweeper
-- carson r.

-- sprites --
tile = 0
open_tile = 1
curs = 2
mine_spr = 3
flag_spr = 4
wrong_spr = 5

-- sfx --
uncover = 0
explode = 1

-- data --
board = {}
curs_pos = {x=0, y=0}
num_mines = 40
game_over = false
-- constants --
colmap = {
	12,
	3,
	8,
	1,
	2,
	13,
	14,
	5
}
-- bitmasks 
-- (these are shift values)
mine = 0
open = 1
flag = 2


function rnd_tile()
	return {
	x=flr(rnd(16)),
	y=flr(rnd(16))
	}
end

function init_board()
	-- init board
	for x=0, 15 do
		col = {}
		for y=0, 15 do
			col[y] = {flags=0, num=0}
		end
		board[x] = col
	end
	
	-- add mines
	for m=0,num_mines do
		coord = rnd_tile()
		while get_tile_dat(coord.x,
	 						coord.y,
	 						mine) do
			coord = rnd_tile()
		end
		set_tile_dat(coord.x,coord.y,
		true,
		mine)
		
		-- compute num for adjacent
		-- tiles
		for x=max(coord.x-1, 0),
						min(coord.x + 1, 15) do
			for y=max(coord.y-1, 0),
							min(coord.y+1, 15) do
				--print(tostr(x) .. ", " ..tostr(y))	
				board[x][y].num += 1
			end
		end
	end
end

function get_tile_dat(x, y, bitindex)
	local tile_bits = board[x][y].flags
	local mask = shl(1, bitindex)
	local res = band(tile_bits, mask)
	if res == 0 then
		return false
	else
		return true
	end	
end

function set_tile_dat(x, y, val, bitindex)
	local mask
	if val then
		mask = shl(1, bitindex)
		board[x][y].flags = bor(board[x][y].flags, mask)
	else
		mask = shl(1, 16) - 1
		mask = bxor(shl(1, bitindex), mask)
		board[x][y].flags = band(board[x][y].flags, mask)
	end
end

function uncover_tile(x, y)
	if get_tile_dat(x, y, open) or
				get_tile_dat(x, y, flag) then
		return
	end
	if get_tile_dat(x, y, mine) then
		game_over = true
		sfx(explode)
		return
	end
	set_tile_dat(x, y, true, open)
	sfx(uncover)
	if board[x][y].num == 0 then
		for xi=max(x-1, 0),
						min(x+1, 15) do
			for yi=max(y-1,0),
							min(y+1,15) do
				uncover_tile(xi, yi)
			end
		end
	end
end

function draw_tile(x, y) 
	spr_x = x * 8
	spr_y = y * 8
	tile_dat = board[x][y]
	if not get_tile_dat(x, y, open) then
		spr(tile, spr_x, spr_y)
		if get_tile_dat(x, y, flag) then
			if game_over then
				spr(wrong_spr, spr_x, spr_y)
			else
				spr(flag_spr, spr_x, spr_y)
			end
		end
	else
		spr(open_tile, spr_x, spr_y)
		if board[x][y].num ~= 0 then
		print(tostr(board[x][y].num), spr_x + 3,spr_y + 2,
		 colmap[board[x][y].num])
		end	
	end
	is_mine = get_tile_dat(x, y, mine)
	if game_over and is_mine then
		rectfill(spr_x, spr_y,
							spr_x + 8, spr_y + 8,
							8)
		spr(mine_spr, spr_x, spr_y)
	end
end

function draw_board()
	for x=0, 15 do
		for y=0, 15 do
			draw_tile(x, y)
		end
	end
end

function draw_cursor()
	spr(curs,
			 	curs_pos.x * 8,
					curs_pos.y * 8)
end

function handle_input()
	-- move cursor
	if btnp(⬆️) then
		curs_pos.y=max(curs_pos.y-1,0)
	end
	if btnp(⬇️) then
		curs_pos.y=min(curs_pos.y+1,15)
	end
	if btnp(⬅️) then
		curs_pos.x=max(curs_pos.x-1,0)
	end
	if btnp(➡️) then
		curs_pos.x=min(curs_pos.x+1,15)
	end
	
	--check for selection
	if btn(❎) then
		uncover_tile(curs_pos.x, curs_pos.y)
	end
	if btnp(🅾️) then
		is_flagged = get_tile_dat(
															curs_pos.x,
		 												curs_pos.y, flag)
		set_tile_dat(curs_pos.x,
															curs_pos.y,
															not is_flagged,
															flag)
	end
end

function _init()
	init_board()
end

function _draw()
	handle_input()
	draw_board()
	draw_cursor()
end


__gfx__
77777776656565658880088800000000000000005000000500555500000000000000000000000000000000000000000000000000000000000000000000000000
7666666556666666800000080101101000088000050000500500005000aaaa0000aaaa0000aaaa0000aaaa000000000000000000000000000000000000000000
766666656666666680000008001711000088800000500500000000500a1aa1a00a1aa1a00a1aa1a0011111100000000000000000000000000000000000000000
766666655666666600000000017111100088500000055000000000500aaaaaa00aaaaaa0011aa1100a11a1100000000000000000000000000000000000000000
766666656666666600000000011111100000500000055000000055000a1aa1a00aa11aa00caaaac00aaaaaa00000000000000000000000000000000000000000
766666655666666680000008001111000055550000500500000500000aa11aa00aa11aa00ca11ac00a1aaaa00000000000000000000000000000000000000000
7666666566666666800000080101101000000000050000500000000000aaaa0000aaaa0000aaaa0000a11a000000000000000000000000000000000000000000
65555555566666668880088800000000000000005000000500050000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000100000000000000000004000010000000000000000000000015150191501a0501c1501c1501a050161500e0500615000150001500100000000070000700008000080000700006000000002f0002f000
000d00003765035650336502f6502965025650216501f6501e6501c6501a65018650166501465011650106500e6500d6500c6500b650096500865007650066500465003650036500365001650006500065000650
000100000000000000000000000000000273501d3501d3500b3500b3500d3500d3501035011350133501535017350183501a3501c3501d3502035021350203501f3501d350183501835000000000000000000000
