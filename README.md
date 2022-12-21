## About

Vim embeds with xxd to display hex strings,  the hex string can be changed only when the number of hex string is the same, thus you can't insert new hex character, or delete some existing hex character.

vim-hex-rework add one command: **Hexrework**.  You can insert new hex characters, delete hex characters in the hex string,  then run 'Hexrework' command, the 'Hexrework' command will change current buffer's content, make it match with xxd format. When the file is written, the binary file is updated accordingly.

## Usage

### .vimrc configure:

Add the following code in your .vimrc files, when a binary file is opened, Vim use xxd to hex dump the file, display it in a buffer. When the buffer is written, Vim will use xxd to convert buffer content back to binary file. You can add more file format if necessary.

```
"binary file, use xxd to hex editing
augroup Binary
au!
au BufReadPre  *.bin,*.exe let &bin=1
au BufReadPost *.bin,*.exe if &bin | %!xxd
au BufReadPost *.bin,*.exe set ft=xxd | endif
au BufWritePre *.bin,*.exe if &bin | %!xxd -r
au BufWritePre *.bin,*.exe endif
au BufWritePost *.bin,*.exe if &bin | %!xxd
au BufWritePost *.bin,*.exe set nomod | endif
augroup END
```

You can define another command if you feel 'Hexrework' command is not convenient to type.

`command! -nargs=0 MyCommand :call HexRework()`

### Hex file edit

A Hex dump string is shown as below:

`00000000: bbcc 3839 3637 abed ffff 3839 0000 0000 ..8967....89....`

The line is made of by the following parts:

- Address:       `00000000:`
- Hex string:   `bbcc 3839 3637 abed ffff 3839 0000 0000`
- Comment:   `..8967....89....`

Change the hex string part directly, for example:

- Add '112233'： `bbcc 3839 112233 3637 abed ffff 3839 0000 0000`

- Delete 'ff'： `bbcc 3839 3637 abed ff 3839 0000 0000`

- Modify '00' to 'ee'： `bbcc 3839 3637 abed ff 3839 eeee eeee`

Execute 'Hexrework' command, 'Hexrework' command will modify the whole buffer's content to match with xxd format. Save the file, then the binary file is updated accordingly.


### Editing rules

- Keep the address part original format, that is 8 bytes character plus a ':',  the address content does not matter, Hexrework will recalculate the right address.

- The hex string part **can't not be odd number characters, and can't not be separated by two space or more**, because two space is used for detect the comment part.  One space or no space between characters are accepted, like below:

```
aabbcc 3839 3637
aa bb cc 38 39 36 37
aabbccdd38393637
```

- Comment part start with two spaces, comment parts can be omitted, 'Hexrework' Command will regenerate comment part 

'Hexrework' will check the buffer content first, if there is some error detect, error message will be shown, the buffer content will not be modified.

## TODO

When work with big file(> 64KB), this script is slow, need to be optimized.

## 关于

vim自带了xxd指令可以用于现实十六进制字符串，以及也可以在不改动字符串个数情况下修改十六进制字符串后生成新的二进制文件。但如果对字符串个数有改动的修改，比如插入，删除，末尾添加十六进制字符串等无法支持。

vim-hex-rework脚本增加了一个命令： `Hexrework`。  在十六进制显示界面里，对字符串进行修改：比如中间插入，删除，修改字符串后运行Hexrework命令，将重新将整个缓冲区的内容整理为符合xxd格式的字符串，这样可以再用xxd命令保存为最终的二进制文件。

## 使用

### .vimrc 配置

   首先需要修改.vimrc，加入以下代码,  打开bin和exe文件时自动转换为十六进制显示，保存时自动恢复为原来的二进制内容，其他格式请加入对应的文件扩展名。

```
"binary file, use xxd to hex editing
augroup Binary
au!
au BufReadPre  *.bin,*.exe let &bin=1
au BufReadPost *.bin,*.exe if &bin | %!xxd
au BufReadPost *.bin,*.exe set ft=xxd | endif
au BufWritePre *.bin,*.exe if &bin | %!xxd -r
au BufWritePre *.bin,*.exe endif
au BufWritePost *.bin,*.exe if &bin | %!xxd
au BufWritePost *.bin,*.exe set nomod | endif
augroup END
```

   如果觉得Hexrework命令不够方便，也可以在.vimrc里另外定义命令，格式如下：   `command! -nargs=0 MyCommand :call HexRework()`

### 编辑

下面是典型的一行hex显示
`00000000: bbcc 3839 3637 abed ffff 3839 0000 0000  ..8967....89....`

其中各部分是：

- 地址部分：      `00000000:`
- hex字符串：   `bbcc 3839 3637 abed ffff 3839 0000 0000`
- 注释：             `..8967....89....`

直接修改其中的hex字符串部分，比如如下修改:

- 增加字符112233：  `bbcc 3839 112233 3637 abed ffff 3839 0000 0000`

- 删除字符ff：             `bbcc 3839 3637 abed ff 3839 0000 0000`

- 修改字符00为ee：   `bbcc 3839 3637 abed ff 3839 eeee eeee`

然后执行Hexrework命令, Hexrework命令将把所有的缓冲区的内容重新修改使其符合xxd格式。 再保存文件，即完成对bin文件的修改

### 编辑要求

1. 保持前面的地址部分为8个字节地址值加:号, 这里不要求地址值是正确的，
   Hexrework命令会自动重新计算地址部分

2. 中间部分的hex字符串**不可以为奇数个数字符**，**不可以出现两个及两个以上的连续空格**,字符间可以不用空格或者间隔一个空格，类似下面的都可以被接受：
   
   ```
   aabbcc 3839 3637
   aa bb cc 38 39 36 37
   aabbccdd38393637
   ```

3. 注释部分以两个空格开始， 注释不需要是对的，也可以忽略不用注释，Hexrework命令会自动重新生成注释部分

如果格式非法，会有提示，不会进行修改
