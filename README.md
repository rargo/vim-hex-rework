## 关于
vim自带了xxd指令可以用于现实十六进制字符串，以及也可以在不改动字符串个数情况下
修改十六进制字符串后还原为十六进制值。但如果对字符串个数有改动的修改，比如插入，删除，
末尾添加十六进制字符串等无法支持。

这个脚本增加了一个命令： `Hexrework`<br>
在十六进制显示界面里，对字符串进行修改：比如中间插入，删除，修改字符串后运行Hexrework命令，
将重新将整个缓冲区的内容整理为符合xxd格式的字符串，这样可以用xxd命令保存为最终的二进制文件。

## 十六进制字符串修改

下面是典型的一行hex显示<br>
`00000000: bbcc 3839 3637 abed ffff 3839 0000 0000  ..8967....89....`

其中各部分是：
- 地址部分   `00000000:`
- hex字符串  `bbcc 3839 3637 abed ffff 3839 0000 0000`                      
- 注释       `..8967....89....`

修改要求：
1. 保持前面的地址部分为8个字节地址值加:号, 这里不要求地址值是正确的，
Hexrework命令会自动重新计算地址部分
2. 中间部分的hex字符串不可以为奇数个数字符，字符间可以不用空格或者间隔一个空格，即类似下面的都可以被接受：
```
aabbcc 3839 3637
aa bb cc 38 39 36 37
aabbccdd38393637
```
但注意**不可以出现两个及两个以上的连续空格**
3. 注释部分以两个空格开始， 注释不需要是对的，也可以忽略不用注释，<br>
Hexrework命令会自动重新生成注释部分
4. 如果格式非法，会有提示，不会进行修改

## .vimrc 配置
首先需要修改.vimrc，加入以下代码,  打开bin和exe文件时自动转换为十六进制显示，<br>
保存时自动恢复为原来的二进制内容，其他格式按需添加

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

如果觉得Hexrework命令不够友好，可以在.vimrc里另外定义命令，格式如下：<br>
`command! -nargs=0 MyCommand :call HexRework()`
