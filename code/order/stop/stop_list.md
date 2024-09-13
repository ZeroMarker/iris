w $LISTTOSTRING(##class(DHCDoc.Interface.Inside.ServiceOrd).GetOrdFreqInfo("93||586"),"^")

d ##class(%ResultSet).RunQuery("web.DHCDocInPatPortalCommon","GetPHFreqInfoList","68666||245","2024-09-03")