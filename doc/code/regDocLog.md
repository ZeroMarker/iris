润乾报表
// d ##class(%ResultSet).RunQuery("web.DHCFHQ.DHCFRegTotal","GetLocReg","2022-09-10","2023-11-08","",2,"上午")
SELECT TR_RowId into TimeRange
FROM SQLUser.DHC_TimeRange
WHERE TR_Desc = :TimeRange
```objectscript
s TimeRangeDr = ""
&sql(
SELECT TR_RowId into :TimeRangeDr
FROM SQLUser.DHC_TimeRange
WHERE TR_ValidEndDate IS NULL
	AND TR_Desc = :TimeRange)
	
s Date=StartDate-1
f  s Date=$o(^PAADMi("PAADM_AdmDate",Date)) q:((Date>EndDate)!(Date=""))  d
.s AdmId=0
.f  s AdmId=$o(^PAADMi("PAADM_AdmDate",Date,AdmId)) q:AdmId=""  d
..s adm = " "_AdmId
..s regfee = $o(^User.DHCRegistrationFeeI("ADM",adm,""))
..s range =  $lg($g(^User.DHCRegistrationFeeD(regfee)),21)
..q:(range'=TimeRangeDr)&&(TimeRangeDr'="")
```
Adm -> regfee -> range