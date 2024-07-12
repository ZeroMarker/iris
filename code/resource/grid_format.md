```js
rowStyler: function(index,row){
			var set = PageLogicObj.set;
			set.add(row.LocDesc+row.ResDesc);
			index = set.size;
			var HospId = ServerObj.HospId;
			console.log(HospId);
			if (HospId != 2) {
				return ;	
			}
	        if (index % 2 == 0) {
	            return 'background-color:#90EE90;'; //'<div style="background-color:#90EE90;">' + value + '</div>';
	        }
	    },
```