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