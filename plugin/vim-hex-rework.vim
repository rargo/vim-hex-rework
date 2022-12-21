"vim-hex-rework is for change text in vim hex mode, working with xxd

command! -nargs=0 Hexrework :call HexRework()

function s:ParseHexLine(line_number, line_content)
		"00000000: 3078 3033 3530 3030 3734 203a 2030 7832  0x03500074 : 0x2
		"end comment split by two spaces
		"TODO confirm end comment detect
		let hex_comment_i = match(a:line_content, '\s\s\+', 0)
		"TODO check i
		if hex_comment_i != -1
			let hex_comment_end_i = matchend(a:line_content, '\s\s\+', 0)
			let ii = match(a:line_content, '\s\s\+', hex_comment_end_i)
			if ii != -1
				echo "Error in line " . a:line_number . ": comment detect fail"
				return []
			endif
			let hex_comment = a:line_content[hex_comment_end_i:]
		else
			let hex_comment = ""
		endif

		"echo hex_comment

		"echo a:line_content
		"let hex_comment = join(hex_comment_list)
		let words = split(a:line_content)
		"echo words
		let hex_address = words[0] "hex_address: 00000000:
		if hex_comment_i != -1
			let hex_content = a:line_content[len(hex_address)+1:hex_comment_i-1]
		else
			let hex_content = a:line_content[len(hex_address)+1:]
		endif

		" echo hex_address
		" echo hex_content
		" echo hex_comment
		" echo len(hex_address)
		" echo len(hex_content)
		" echo len(hex_comment)

		if len(hex_address) != 9
			echo "Error in line " . a:line_number . ": invalid start address"
			return []
		endif

		if match(hex_address, '^[0-9a-f]\+:$', 0) != 0
			echo "Error in line " . a:line_number . ": invalid start address"
			return []
		endif

		let hex_chs = split(hex_content)
		for hex_ch in hex_chs
			if match(hex_ch, '^[0-9a-f]\+$', 0) != 0
				echo "Error in line " . a:line_number . ": invalid hex characters"
				return []
			endif

			if len(hex_ch)%2 != 0
				echo "Error in line " . a:line_number . ": detects odd hex digits"
				return []
			endif
		endfor

		" if len(hex_comment) != 16
		" 	echo "error: invalid end comment detect"
		" 	return null
		" endif

		let r = []
		call add(r, hex_address)
		call add(r, hex_content)
		call add(r, hex_comment)

		return r
endfunction

function s:CheckHexContent(startline, endline)

	let all_line_contents = getline(a:startline, a:endline)

	let line_parse_result = []

	let line_number = a:startline
	for line_content in all_line_contents

		"skip line that all is space, or it's empty line
		if match(line_content, "^\s*$") != -1
			call add(line_parse_result, [])
			let line_number = line_number + 1
			continue
		endif

		"check if there's at least one space, so ParseHexLine works
		if match(line_content, '\s') == -1
			echo "Error in line " . line_number . ": error format"
			return []
		endif

		let l = s:ParseHexLine(line_number, line_content)
		if len(l) == 0
			return []
		endif

		call add(line_parse_result, l)
		let line_number = line_number + 1
	endfor

	return line_parse_result
endfunction

function s:ToChar(hex)
	let nr = str2nr(a:hex, 16)
	" condiction from xxd source code
	if nr > 31 && nr < 127
		return nr2char(nr)
	else
		return '.'
	endif
endfunction

function s:NewLineContent(line_start_address, hex_chs)

	let new_line_content = printf("%08x: ", a:line_start_address)
	let comment = " "
	for i in range(len(a:hex_chs)/2)
		let hex1 = a:hex_chs[i*2] 
		let hex2 = a:hex_chs[i*2+1]
		let new_line_content = new_line_content . hex1 . hex2 . " "

		"for speed, don't call ToChar function
		let nr = str2nr(hex1, 16)
		" condiction from xxd source code
		if nr > 31 && nr < 127
			let comment = comment . nr2char(nr)
		else
			let comment = comment . '.'
		endif

		let nr = str2nr(hex2, 16)
		" condiction from xxd source code
		if nr > 31 && nr < 127
			let comment = comment . nr2char(nr)
		else
			let comment = comment . '.'
		endif
		"let comment = comment . s:ToChar(hex1) . s:ToChar(hex2)
	endfor

	if len(a:hex_chs)%2 != 0
		let hex = a:hex_chs[-1]
		let new_line_content = new_line_content . hex . " "
		let comment = comment . s:ToChar(hex)
	endif

	let total_chs = 10 + 8*5 "start_address + hex content
	let len_new_line = len(new_line_content) 
	if (len_new_line < total_chs) 
		for i in range(total_chs-len_new_line)
			let new_line_content = new_line_content . " "
		endfor
	endif

	let new_line_content = new_line_content . comment
	return new_line_content
endfunction

function s:DoHexRework(startline, endline, line_parse_result)

	let start_address = 0
	let line_hex_chs = []
	let current_line = a:startline

	let new_lines = []
	for l in a:line_parse_result
		"skip line that has no content
		if len(l) == 0
			continue
		endif

		let hex_content = substitute(l[1], " ", '','g')
		let _hex_chs = split(hex_content, '\zs')
		for i in range(len(_hex_chs)/2)
			let hex = _hex_chs[i*2] . _hex_chs[i*2+1]
			call add(line_hex_chs, hex)
		endfor
		" echo "hex_chs:"
		" echo hex_chs
		
		let left_len = len(line_hex_chs) 
		let i = 0
		while (left_len >= 16) 
			let new_line_content = s:NewLineContent(start_address, line_hex_chs[i:i+15])
			call setline(current_line, new_line_content)

			let current_line = current_line + 1
			let start_address = start_address + 16
			let left_len = left_len - 16
			let i = i + 16
		endwhile
		
		if left_len > 0
			let line_hex_chs = line_hex_chs[i:i+left_len-1]
		else
			let line_hex_chs = []
		endif
	endfor

	let new_endline = current_line - 1

	if len(line_hex_chs) != 0
		let new_line_content = s:NewLineContent(start_address, line_hex_chs)
		"echo "&new_line_content: " . new_line_content 
		if current_line > a:endline
			"echo "append line:" . current_line
			call append(new_endline, new_line_content)
		else
			"echo "set line:" . current_line
			call setline(current_line, new_line_content)
			let new_endline = current_line
		endif
	endif

	"check if some line need to be delete
	if new_endline < a:endline
		for i in range(new_endline+1, a:endline)
			call setline(i, '')
		endfor
	endif

endfunction

function! HexRework()
	let startline = 1
	let endline = line('$')

	let start_t = reltime()
	let line_parse_result = s:CheckHexContent(startline, endline)
	let t = reltimefloat(reltime(start_t))
	echom "CheckHexContent takes " . t . " seconds"
	if line_parse_result == []
		return
	endif

	let start_t = reltime()
	call s:DoHexRework(startline, endline, line_parse_result)
	let t = reltimefloat(reltime(start_t))
	echom "DoHexRework takes " . t . " seconds"
endfunction

