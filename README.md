## 

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



对编辑修改的要求：

1. 保持前面的地址部分为8个字节地址值加:号, 这里不要求地址值是正确的，
   Hexrework命令会自动重新计算地址部分
2. 中间部分的hex字符串**不可以为奇数个数字符**，**不可以出现两个及两个以上的连续空格**,字符间可以不用空格或者间隔一个空格，类似下面的都可以被接受：
   
   ```
   aabbcc 3839 3637
   aa bb cc 38 39 36 37
   aabbccdd38393637
   ```
3. 注释部分以两个空格开始， 注释不需要是对的，也可以忽略不用注释，Hexrework命令会自动重新生成注释部分
4. 如果格式非法，会有提示，不会进行修改
