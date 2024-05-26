## prefix match
$Extract(Code,1,$L(Target))=Target

## concat \r\n
_$C(13,10)

## quotes escape
In ObjectScript, if you want to create a string that contains double quotes (") within it, you can use two double quotes together to escape them. Here's an example:
set myString = "This is a string with double quotes ""inside"" it."

## Replacing a Substring Using SET $PIECE
SET colorlist="Red,Green,Blue,Yellow,Orange,Black"
WRITE colorlist,!
SET $PIECE(colorlist,",",1)="Magenta"
WRITE colorlist,!
SET $PIECE(colorlist,",",*-3)="Cyan"
WRITE colorlist,!

## Remember arguments
set ^TMP("FindDailyDtl")=$lb(wardId, admStr, stDate, stTime, endDate, endTime, otherQryStr, langId)

## Quit aka Break
for {
	quit:x=1
}

## Break point
- b ;01
- g next breakpoint
- q exit

[Studio Debug](./mumps/studio/studio.md##debug)

## js object array
```js
let myObject = {
  name: 'John',
  age: 25,
  gender: 'male'
};
// Remove the 'age' attribute
delete myObject.age;

console.log(myObject);
let myArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

// Remove the 10th element from the array
let removedElement = myArray.splice(9, 1)[0];

// Insert the removed element at the 5th position
myArray.splice(4, 0, removedElement);

console.log(myArray);
```
## Replace special symbols
&amp;
&Hat;
&#94;

## eval
```js
let x = 10;
let y = 20;
let code = "console.log(x + y);"; // JavaScript code as a string
eval(code); // Outputs: 30
```

## Reload Datagrid
PageLogicObj.m_InPatListTabDataGrid=InitInPatListTabDataGrid();

## context menu
```js
// 锁定页面右键
document.oncontextmenu = function(e){
    return false;
}
```

## innerText
```js
// 获取具有 id 为 'Update' 的 HTML 元素
var obj = document.getElementById('Update');

// 获取原始内容
var originalContent = obj.innerHTML;

// 添加 "第二" 到原始内容后面
var updatedContent = originalContent + "第二";

// 更新元素的内容
obj.innerHTML = updatedContent;
```

## Refer Object Value
```objectscript
s ItmObj = ##class(User.DHCTarItem).%OpenId(Itm)
s SubObj = ##class(User.DHCTarSubCate).%OpenId(ItmObj.TARISubCate.%Id())
s CatObj = ##class(User.DHCTarCate).%OpenId(SubObj.TARSCTARCDR.%Id())
s Cat = SubObj.TARSCTARCDR.%Id()
```
## messager

```js
$.messager.popover({
				msg: '保存成功！',
				type: 'success',
				timeout: 2000, 		//0不自动关闭。3000s
				showType: 'slide'  //show,fade,slide
			});
// success, alert , info, error
```
## Object Refer use
```objectscript
s PatDiagsStr = ##class(User.DHCPAPatMas).%OpenId(##class(User.PAAdm).%OpenId(Adm).PAADMPAPMIDR.%Id()).PAPMIChronic
```

## forEach return
arr.forEach(item => {
	if (item.age == 1) {
		return false;
	}
})

## tabs
```js
// 获取选中的标签页（tab）的文本
var selectedTabText = $('#tabs').tabs('getSelected').panel('options').title;
```

```js
// 隐藏具有特定 ID 的元素
$('#elementID').hide();

// 隐藏所有具有特定类的元素
$('.className').hide();

// 隐藏所有段落元素
$('p').hide();

```

```js
// 显示具有特定 ID 的元素
$('#elementID').show();

// 显示所有具有特定类的元素
$('.className').show();

// 显示所有段落元素
$('p').show();

```

## XML 类 数据传输
```objectscript
s obj.name = name
s:obj.name="" obj.name = " "
// 转 xml 只传输非空值
```

## url para
```js
// Define the base URL
const baseUrl = 'https://example.com/api';

// Define the parameters as an object
const params = {
  page: 1,
  limit: 10,
  search: 'example'
};

// Convert the parameters object to URLSearchParams
const searchParams = new URLSearchParams(params);

// Join the base URL with the parameters
const urlWithParams = `${baseUrl}?${searchParams}`;

console.log(urlWithParams);
```

## css
```js
$("#DeptList").css('height',$(window).height()-395);
```

```
s BillFlag1=$P($G(^MRC("ID",+ICDRowid)),"^",13)
s BillFlag3=$P($G(^MRC("ID",+ICDRowid)),"^",15)
s DiagObj.DiagnosisClass=$SELECT((BillFlag1="Y")&&(BillFlag3="Y"):"证型",BillFlag3="Y":"中医",1:"西医")
```

## <NESTED TOO DEEP>
```objectscript
q json.%ToJSON()

s json = {}.%FromJSON(json)
```

