## 关联医嘱
```js
function CheckMasterOrdStyle()
{
    /*var allrowids = GetAllRowId();
    for (var i = 0; i < allrowids.length; i++) {
        var id1 = allrowids[i];
        var ItemRowid1 = GetCellData(id1, "OrderItemRowid");
        if (ItemRowid1 != "") { continue }
        var OrderSeqNo1 = GetCellData(id1, "id");
        var MasterSeqNo1 = GetCellData(id1, "OrderMasterSeqNo");
        if (MasterSeqNo1!="") continue;
        var isMasterOrdFlag=0;
        for (var j = 0; j < allrowids.length; j++) {
	        var id2 = allrowids[j];
	        var ItemRowid2 = GetCellData(id2, "OrderItemRowid");
	        if (ItemRowid2 != "") { continue }
	        var OrderSeqNo2 = GetCellData(id2, "id");
	        var MasterSeqNo2 = GetCellData(id2, "OrderMasterSeqNo");
	        if (MasterSeqNo2=="") continue;
	        if (OrderSeqNo1==MasterSeqNo2) isMasterOrdFlag=1;break;
	    }
	    if (isMasterOrdFlag==0){
			if ($("#"+ id1).find("td").hasClass("OrderMasterM")){
				$("#" + id1).find("td").removeClass("OrderMasterM");
			}
		}else{
			$("#" + id1).find("td").addClass("OrderMasterM");
		}
    }*/
    var allrowids = GetAllRowId();
    for (var i = 0; i < allrowids.length; i++) {
        var id1 = allrowids[i];
        var ItemRowid1 = GetCellData(id1, "OrderItemRowid");
        if (ItemRowid1 != "") continue;
        var MasterSeqNo1 = GetCellData(id1, "OrderMasterSeqNo");
        if (MasterSeqNo1!="") continue;
		var RowArry = GetSeqNolist(id1);
	    if (!RowArry.length){
			if ($("#"+ id1).find("td").hasClass("OrderMasterM")){
				$("#" + id1).find("td").removeClass("OrderMasterM");
			}
		}else{
			$("#" + id1).find("td").addClass("OrderMasterM");
		}
    }
}
```