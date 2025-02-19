## 检查申请单特殊字符
```js
let item = "%^&&<>   	' ' '";
item = item.replace(/\s/g,''); //whitespace

console.log(item);
item = item.replace(/&/g, '&amp;').replace(/\^/g, '&Hat;').replace(/'/g,'&apos;');

console.log(item);
```
