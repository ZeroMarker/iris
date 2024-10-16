/// w ##class(web.DHCDocMain).OrderGraph(19396)
/// w ##class(web.DHCDocMain).GetOrderGraph()
ClassMethod GetOrderGraph()
{
	s Loc = 180
	s date = +$h-7
	&sql(DECLARE mycursor CURSOR FOR
		select OEORI_ItmMast_DR->ARCIM_Desc ,OEORI_OEORD_ParRef->OEORD_Adm_DR,
		OEORI_OEORD_ParRef->OEORD_Adm_DR->PAADM_PAPMI_DR->PAPMI_Name,
		OEORI_OEORD_ParRef->OEORD_Adm_DR->PAADM_PAPMI_DR->PAPMI_No,
		OEORI_RowId,OEORI_SttDat into :arcim, :adm, :name, :no, :rowid, :sttDate
		from SQLUser.oe_ordItem WHERE OE_OrdItem.OEORI_SttDat > :date
		and OEORI_OrdDept_DR=180
		and OEORI_ItemStat_DR <> 4
		order by OEORI_OEORD_ParRef
	)
	&sql(OPEN mycursor)
	
	s json = []
	for {
		&sql(FETCH mycursor)
    	QUIT:SQLCODE'=0
    	s stayFlag = ##class(web.DHCEMPatCheckLev).IsStaying(adm)
    	continue:stayFlag=0
    	s opOrderExecInfo=##class(web.DHCOPBillEmergTrans2IP).GetOrdExecStatus(rowid,"2")
    	continue:+opOrderExecInfo=1
   		continue:name["测试"
   		s VirtualtLongFlag=##class(web.DHCDocOrderVirtualLong).GetVirtualtLongFlag(rowid)
   		continue:VirtualtLongFlag="Y"
    	s item = {}
    	s item.arcim = arcim
    	s item.name = name
    	s item.no = no
    	s item.rowid = rowid
    	s item.adm = adm
    	s item.sttDate = $zd(sttDate,3)
    	d json.%Push(item)
	}
	&sql(CLOSE mycursor)
	s json = json.%ToJSON()
	q json
}