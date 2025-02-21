pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- pico sweeper
-- carson r.
#include scores.lua
-- sprites --
tile = 0
open_tile = 1
curs = 2
mine_spr = 3
flag_spr = 4
wrong_spr = 5
😐 = 7
😐_scared = 8
😐_dead = 9
😐_cool = 10
-- sfx --
uncover = 0
explode = 1

-- data --
-- enum
GameState = {
	START=0,
	PLAYING=1,
	END=2
}
game_state = GameState.START
scores = nil
board = {}
curs_pos = {x=0, y=0}
num_mines = 40
remaining_mines = num_mines
game_time = 0
start_time = 0
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

function draw_title()
	local offset = 25
	rectfill(offset - 1, 10  - 1, (#"picosweeper" * 9) + 4, 22 + 8, 6)
	-- First few characters 'picoswe'
	pal(7, 1)
	for s=16,22 do
		spr(s, offset, 12)
		offset += 7
	end
	-- Reuse existing chars
	spr(22, offset, 12)
	offset += 7
	spr(16, offset, 12)
	offset += 7
	spr(22, offset, 12)
	offset += 7
	spr(23, offset, 12)
	pal()
	-- Draw sub header
	-- rectfill(40, 23, 87, 31, 6)
	print("press 🅾️ to start", 31, 23, 13) 
end

function draw_scores()
	rectfill(32, 48, 95, 111, 6)
	print("scores", 52, 50, 8)
	y_offset = 56
	pnum = 1
	for _, score in pairs(scores) do
		print(pnum .. ".", 38, y_offset, 13)
		print(score.name, 55, y_offset, 13)
		print(score.val, 91 - 4 * #tostr(score.val), y_offset, 13)
		y_offset += 7
		pnum += 1
	end
end

function main_menu()
	cls(7)
	for x=0,15 do
		for y=0,15 do
			spr(tile, x * 8, y * 8)
		end
	end
	draw_title()
	draw_scores()
end

function rnd_tile()
	return {
	x=flr(rnd(16)),
	y=flr(rnd(15))
	}
end

function init_board()
	-- init board
	for x=0, 15 do
		col = {}
		for y=0, 14 do
			col[y] = {flags=0, num=0}
		end
		board[x] = col
	end
	
	-- add mines
	for m=1,num_mines do
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
							min(coord.y+1, 14) do
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

function game_is_won()
	for x=0,15 do
		for y=0,14 do
			is_mine = get_tile_dat(x,y,mine)
			is_open = get_tile_dat(x,y,open)
			if not is_mine and not is_open then
				return false
			end
		end
	end
	return true
end

function uncover_tile(x, y)
	if get_tile_dat(x, y, open) or
				get_tile_dat(x, y, flag) then
		return
	end
	if get_tile_dat(x, y, mine) then
		game_state = GameState.END
		sfx(explode)
		return
	end
	set_tile_dat(x, y, true, open)
	sfx(uncover)
	if board[x][y].num == 0 then
		for xi=max(x-1, 0),
						min(x+1, 15) do
			for yi=max(y-1,0),
							min(y+1,14) do
				uncover_tile(xi, yi)
			end
		end
	end
end

function draw_tile(x, y) 
	spr_x = x * 8
	spr_y = (y + 1) * 8
	is_flag = get_tile_dat(x, y, flag)
	is_mine = get_tile_dat(x, y, mine)
	if not get_tile_dat(x, y, open) then
		spr(tile, spr_x, spr_y)
		if is_flag then
			if game_state == GameState.END and not is_mine then
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
	if game_state == GameState.END and is_mine and not is_flag then
		rectfill(spr_x, spr_y,
							spr_x + 8, spr_y + 8,
							8)
		spr(mine_spr, spr_x, spr_y)
	end
end

function draw_board()
	for x=0, 15 do
		for y=0, 14 do
			draw_tile(x, y)
		end
	end
end

function draw_cursor()
	spr(curs,
			 	curs_pos.x * 8,
					(curs_pos.y + 1) * 8)
end

function toggle_flag(x, y)
	if get_tile_dat(x, y, open) then
		return
	end
	is_flagged = get_tile_dat(x, y, flag)
	set_tile_dat(x, y, not is_flagged, flag)
	if is_flagged then
		remaining_mines += 1
	else
		remaining_mines -= 1
	end
end

function handle_input()
	-- move cursor
	if btnp(⬆️) then
		curs_pos.y=max(curs_pos.y-1,0)
	end
	if btnp(⬇️) then
		curs_pos.y=min(curs_pos.y+1,14)
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
		game_won = game_is_won()
		if game_won then
			game_state = GameState.END
		end
	end
	if btnp(🅾️) then
		-- game_state = GameState.END
		-- game_won = true
		toggle_flag(curs_pos.x, curs_pos.y)
	end
end

function draw_header()
	print(tostr(remaining_mines), 0, 1, 8)
	if not (game_state == GameState.END) then
		game_time = flr(time()) - start_time
	end
	print(game_time, 128 - 4 * #tostr(game_time), 1, 8)
	if game_state == GameState.END then
		if game_won then
			spr(😐_cool, 60, 0)
		else
			spr(😐_dead, 60, 0)
		end
	elseif btn(❎) then
		spr(😐_scared, 60, 0)
	else
		spr(😐, 60, 0)
	end
end

function reset_game()
	game_state = GameState.START
	board = {}
	init_board()
	remaining_mines = num_mines
	curs_pos = {x=0, y=0}
end

function _init()
	cartdata("carsonmonkey_picosweeper_1")
	init_scores(8, 0, true)
	add_score("CAR", 200)
	add_score("DAN", 400)
	scores = get_scores()
	init_board()
end

function _draw()
	cls()
	if game_state == GameState.START then
		main_menu()
		if btnp(🅾️) then
			game_state = GameState.PLAYING
			start_time = flr(time())
		end
	elseif game_state == GameState.PLAYING then
		-- Game loop
		draw_header()
		handle_input()
		draw_board()
		draw_cursor()
	elseif game_state == GameState.END then
		draw_header()
		draw_board()
		if btnp(🅾️) then
			reset_game()
		end
	end
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777700000770000777777007777770077777700700007007777700077777000000000000000000000000000000000000000000000000000000000000000000
07700700000770000770000007700070077000000700707007700000077007000000000000000000000000000000000000000000000000000000000000000000
07700700000770000770000007700070077000000700707007777700077007000000000000000000000000000000000000000000000000000000000000000000
07777700000770000770000007700070077777700700707007700000077777000000000000000000000000000000000000000000000000000000000000000000
07000000000770000770000007700070000007700700707007700000077070000000000000000000000000000000000000000000000000000000000000000000
07000000000770000777777007777770077777700777777007777700077007000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000100000000000000000004000010000000000000000000000015150191501a0501c1501c1501a050161500e0500615000150001500100000000070000700008000080000700006000000002f0002f000
000d00003765035650336502f6502965025650216501f6501e6501c6501a65018650166501465011650106500e6500d6500c6500b650096500865007650066500465003650036500365001650006500065000650
000100000000000000000000000000000273501d3501d3500b3500b3500d3500d3501035011350133501535017350183501a3501c3501d3502035021350203501f3501d350183501835000000000000000000000
