```objectscript
s BillFlag1=$P($G(^MRC("ID",+ICDRowid)),"^",13)
s BillFlag3=$P($G(^MRC("ID",+ICDRowid)),"^",15)
s DiagObj.DiagnosisClass=$SELECT((BillFlag1="Y")&&(BillFlag3="Y"):"证型",BillFlag3="Y":"中医",1:"西医")
```