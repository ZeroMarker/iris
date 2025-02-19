```js
///山一大二附院对调配费用加收的特殊规则
/*
var UpNums=OrderItemObj.length
if (UpNums>15){
	var CNMedAddARCIMRowId="15963||1"
	//var CNMedAddQty=(Math.ceil(UpNums/5))-3   ///向上取整
	var CNMedAddQty=(Math.floor(UpNums/5))-3   ///向下取整
	if (CNMedAddQty>0){
		var OrderItem=CNMedAddARCIMRowId+"^"+CNMedAddQty + "^" + "" + "^" + ""+"^"+""+"^^^^^^^^^CMPTAOF"+"^"+OrderSerialNum+"^"+CalPrescNo+"^"+CalPrescSeqNo;;
			OrderItemStr=OrderItemStr+String.fromCharCode(1)+OrderItem;
	}
	}
*/
```