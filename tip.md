## nested structure
.
..

{
	{
	}
}

## variable usage
i var '= "" s var=""

## iris terminal
iris
irisdb

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

## record arguments
set ^TMP("FindDailyDtl")=$lb(wardId, admStr, stDate, stTime, endDate, endTime, otherQryStr, langId)

## quit aka break
for {
	quit:x=1
}

## debug
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
## replace symbols
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

## reload
PageLogicObj.m_InPatListTabDataGrid=InitInPatListTabDataGrid();

## sql col2
SELECT 1, 2
FROM table_name
WHERE 1 = 2;

## xml read
ClassMethod GetOPPatList() As %GlobalCharacterStream
w ##Class(EMRservice.BL.opInterface).GetOPPatList().Read()

## context menu
```js
// 锁定页面右键
document.oncontextmenu = function(e){
    return false;
}
```

## json
JSON.parse(json)



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

## 对象指向
s ItmObj = ##class(User.DHCTarItem).%OpenId(Itm)
s SubObj = ##class(User.DHCTarSubCate).%OpenId(ItmObj.TARISubCate.%Id())
s CatObj = ##class(User.DHCTarCate).%OpenId(SubObj.TARSCTARCDR.%Id())
s Cat = SubObj.TARSCTARCDR.%Id()

## messager
```js
$.messager.popover({
				msg: '保存成功！',
				type: 'success',
				timeout: 2000, 		//0不自动关闭。3000s
				showType: 'slide'  //show,fade,slide
			});
```
## obj
```
s PatDiagsStr = ##class(User.DHCPAPatMas).%OpenId(##class(User.PAAdm).%OpenId(Adm).PAADMPAPMIDR.%Id()).PAPMIChronic
```

## query && query execute

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