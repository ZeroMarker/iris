```js
function DIPClickHandler(){
	var EpisodeID = GlobalObj.EpisodeID;
	var jsonStr=tkMakeServerCall("web.DHCDocCommon","DIPCommon",EpisodeID);
	var json = JSON.parse(jsonStr);
	// 获取json节点
	var result = json.result;
	if (result == null) {
		$.messager.alert("DIP预分组失败",json.desc,"error");
		return false;
	}
	var dmaEntry = result.find(entry => entry.sys === "dma");
	var dmaSuccess = dmaEntry.success;
	var dmaResult = dmaEntry.result;
	if (dmaSuccess) {
		var url = dmaResult;
		var message = '<a href="' + url + '" target="_blank">链接</a>';
	    $.messager.alert("DIP预分组成功",message,"info");
	} else {
	    $.messager.alert("DIP预分组失败",dmaResult,"error");
	}	
}
```
