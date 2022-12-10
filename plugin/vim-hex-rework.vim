"vim-hex-rework is for change text in vim hex mode, working with xxd
"
"
"
"

command! -nargs=0 HexRework :call s:HexRework()

function s:ToChar(nr)
	if a:nr > 31 && a:nr < 127
		return nr2char(a:nr)
	else
		return '.'
	endif
endfunction

function s:ParseHexLine(line_number, line_content)
		"00000000: 3078 3033 3530 3030 3734 203a 2030 7832  0x03500074 : 0x2
		"end comment split by two spaces
		"TODO confirm end comment detect
		let end_comment_i = match(a:line_content, '\s\s\+', 0)
		"TODO check i
		if end_comment_i != -1
			let end_comment = a:line_content[end_comment_i+2:]
		else
			let end_comment = ""
		endif
		"echo end_comment

		"let end_comment = join(end_comment_list)
		let words = split(a:line_content, " ")
		let start_address = words[0] "start_address: 00000000:
		if end_comment_i != -1
			let hex_content = a:line_content[len(start_address)+1:end_comment_i-1]
		else
			let hex_content = a:line_content[len(start_address)+1:]
		endif

		" echo start_address
		" echo hex_content
		" echo end_comment
		" echo len(start_address)
		" echo len(hex_content)
		" echo len(end_comment)

		if len(start_address) != 9
			echo "Error in line " . a:line_number . ": invalid start address"
			return []
		endif

		if match(start_address, '^\d\+:$', 0) != 0
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
				echo "Error in line " . a:line_number . ": detects even hex digits"
				return []
			endif
		endfor

		" if len(end_comment) != 16
		" 	echo "error: invalid end comment detect"
		" 	return null
		" endif

		let r = []
		call add(r, start_address)
		call add(r, hex_content)
		call add(r, end_comment)

		return r
endfunction

function s:CheckHexContent(startline, endline)

	let all_line_contents = getline(a:startline, a:endline)

	let line_number = a:startline
	for line_content in all_line_contents
		let l = s:ParseHexLine(line_number, line_content)
		if len(l) == 0
			return 1
		endif

		let line_number = line_number + 1
	endfor

	return 0
endfunction

function s:EndComment(hex_contents)
	let comment = ""

	let hex_n = len(a:hex_contents)
	let pad_chs = 16-hex_n

	"echo pad_chs
	"00000040: 3839 6162 6364 6566 3031 3233 3637       89abcdef012367
	if (pad_chs > 0)
		let total_chs = 8*5 
		let chs = hex_n/2*5
		if hex_n%2 != 0
			let chs = chs + 3
		endif

		" echo total_chs
		" echo chs
		for i in range(total_chs-chs)
			let comment = comment . " "
		endfor
	endif

	let comment = comment . " "

	for hex in a:hex_contents
		let nr = str2nr(hex, 16)
		"echo "nr:" . nr
		let ch = s:ToChar(nr)
		"echo "ch:" . ch
		let comment = comment . ch
	endfor

	"echo comment
	return comment
endfunction

function s:DoHexRework(startline, endline)

	let all_line_contents = getline(a:startline, a:endline)
	let line_content = ""
	
	let start_address = 0
	let last_line_left_hex_chs = []
	let current_line = a:startline

	let new_lines = []
	for line_content in all_line_contents

		"current_line para is not matters
		let l = s:ParseHexLine(current_line, line_content)
		"echo "comment: " . l[2]
		"echo l
		let hex_content = l[1]
		"echo "hex_content: " . hex_content

		"echo "line_content:     " . line_content

		"remove space
		let hex_content = substitute(hex_content, " ", '','g')
		"echo "hex_content: " . hex_content

		let _hex_chs = split(hex_content, '\zs')

		let hex_chs = last_line_left_hex_chs[:]
		let last_line_left_hex_chs = []
		for i in range(len(_hex_chs)/2)
			let hex = _hex_chs[i*2] . _hex_chs[i*2+1]
			call add(hex_chs, hex)
		endfor
		" echo "hex_chs:"
		" echo hex_chs
		
		"echo len(hex_chs)
		for hex_ch in hex_chs
			"echo "A"
			"echo hex_ch
			if start_address%16 == 0
				" echo "1. start_address: " . start_address
				let new_line_content = printf("%08x: ", start_address)
			endif

			call add(last_line_left_hex_chs, hex_ch)

			let start_address = start_address + 1
			if start_address%16 == 0
				"echo "2. start_address: " . start_address
				""echo last_line_left_hex_chs
				"echo "last_line_left_hex_chs:"
				"echo last_line_left_hex_chs
				for i in range(8)
					let hex = last_line_left_hex_chs[i*2] . last_line_left_hex_chs[i*2+1]
					let new_line_content = new_line_content . hex . " "
				endfor
				let new_line_content = new_line_content . s:EndComment(last_line_left_hex_chs)
				"echo "@new line_content: " . new_line_content
				let last_line_left_hex_chs = []

				"call add(new_lines, new_line_content)
				"echo "set line:" . current_line
				call setline(current_line, new_line_content)
				let current_line = current_line + 1
			endif
		endfor

		"when the for loop finish, if there is some character not proceed in last_line_left_hex_chs, 
		"the start_address adds the length of last_line_left_hex_chs in the for loop, 
		"but that's wrong, should leave it to the next line for loop, so sub it here
		if len(last_line_left_hex_chs) != 0
			let start_address = start_address - len(last_line_left_hex_chs)
		endif
		"let new_line_content = new_line_content . hex_string
		"add comment
	endfor


	let lines_n = current_line - 1

	if len(last_line_left_hex_chs) != 0
		" echo "tail last_line_left_hex_chs:"
		" echo last_line_left_hex_chs
		for i in range(len(last_line_left_hex_chs)/2)
			let hex = last_line_left_hex_chs[i*2] . last_line_left_hex_chs[i*2+1]
			let new_line_content = new_line_content . hex . " "
		endfor

		if len(last_line_left_hex_chs)%2 != 0
			let hex = last_line_left_hex_chs[-1]
			let new_line_content = new_line_content . hex . " "
		endif
		let new_line_content = new_line_content . s:EndComment(last_line_left_hex_chs)
		"echo "&new line_content: " . new_line_content 
		if current_line > a:endline
			"echo "append line:" . current_line
			call append(current_line-1, new_line_content)
		else
			"echo "set line:" . current_line
			call setline(current_line, new_line_content)
			let lines_n = current_line
		endif
	endif

	"check if some line need to be delete
	if lines_n < a:endline
		for i in range(lines_n+1, a:endline)
			call setline(i, '')
		endfor
	endif

endfunction

function s:HexRework()

	let startline = 1
	let endline = line('$')

	let check = s:CheckHexContent(startline, endline)
	if check != 0
		return
	endif

	call s:DoHexRework(startline, endline)

endfunction

