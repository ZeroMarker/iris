# iris



s:HospitalId="" HospitalId = $g(^ARCIM(+ArcimRowid,1,"HOSP",1))


/// @docs:	诊断插入五笔首拼别名, 重复跳过不插入
/// @debug:	d ##class(web.DHCDocMain).AddDiagAlias()
/// @table:
/// 		MRC_ICDDx
/// 		MRC_ICDAlias
ClassMethod AddDiagAlias()
{
	s id = 0
	for {
		s id = $o(^MRC("ID",id))
		q:id=""
		s name = $p(^MRC("ID",id),"^",2)
		s name = ##class(web.DHCINSUPort).GetCNCODE(name,6,"^")
		s new = ""
		for i=1:1:$l(name,"^") {
			s item = $p(name,"^",i)
			s item = $e(item,1,1)
			s new = new _ item	
		}
		s k = 0
		for {
			s k = $o(^MRC("ID",id,"ALIAS",k))
			q:k=""
			s alias = ^MRC("ID",id,"ALIAS",k)
			s:alias=new repeat = 1
		}
		continue:$g(repeat)=1
		s res = ##class(web.DHCBL.CT.MRCICDAlias).SaveAll("^"_new_"^"_id)
	}
}

/// @debug: d ##class(web.DHCDocMain).TestView()
ClassMethod TestView()
{
	&sql(
		CREATE view OrderView as (
		select
			OEORI_OEORD_ParRef -> oeord_adm_dr->paadm_papmi_dr->papmi_name as name,
			OEORI_OEORD_ParRef -> oeord_adm_dr->paadm_papmi_dr->papmi_no as regno,
			OEORI_OEORD_ParRef -> oeord_adm_dr->paadm_papmi_dr->papmi_id as idcard,
			OEORI_OEORD_ParRef -> oeord_adm_dr->paadm_papmi_dr as patid,
			OEORI_OEORD_ParRef -> oeord_adm_dr as admid,
			OEORI_ItmMast_DR -> Arcim_desc as drug, 
			OEORI_ItemStat_DR->ostat_desc as status, 
			OEORI_OEORD_ParRef||OEORI_Childsub As ord,
			* 
		from SQLUser.OE_OrdItem)
	)
	&sql(DECLARE mycursor CURSOR FOR
		select 医嘱 into :name from SQLUser.OrderViewCN where 登记号 = "0000003481" 
	)
	&sql(OPEN mycursor)
	
	for {
		&sql(FETCH mycursor)
    	QUIT:SQLCODE'=0
    	w name,!
	}
	&sql(CLOSE mycursor)
}

/**
	* @debug w ##class(web.DHCDocMain).CalBaseQty("11134||1","16","4","O")
	* @debug w ##class(web.DHCDocMain).CalBaseQty("11134||1","0.1","66","O")
	* @debug w ##class(web.DHCDocMain).CalBaseQty("1475||1","2","16","O")
*/
ClassMethod CalBaseQty(type, arcim, qty, uom, AdmType)
{
	s ^CalBaseQty(uom) = $lb(arcim, qty, uom, AdmType)
	q:arcim="" ""
	q:qty="" ""
	q:uom="" ""
	s res = ""
	if type="dose" {
		s doseqty = qty
		s drgform=$p($g(^ARCIM(+arcim,+$p(arcim,"||",2),1)),"^",12)
		s res = $$calcqty^DHCOEOrdItem(drgform,uom,doseqty,AdmType)
	}
	if type="pack" {
		s convFac=##class(appcom.OEDispensing).convFac(arcim,uom)
		s res=qty*convFac
	}
	q res
}

ClassMethod GetEqUom(arcim, EpisodeID)
{
	s DrgformRowid=##class(web.DHCDocOrderEntry).GetDrgForm(arcim)
	i DrgformRowid'="" {
		s PHCDRowid=$P(DrgformRowid,"||",1)
		s ChildSub=$P(DrgformRowid,"||",2)

		s HospitalID = ##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
		s PHUseEqQty=..%GetConfig("PHUseEqQty",HospitalID)
		;草药不取等效单位
		s defaultFindFlag=0,firstEqUomID=""

		s leq=0  f  s leq=$o(^PHCD(PHCDRowid,"DF",ChildSub,"EQ",leq)) q:leq=""  d
		.s eqrec=^PHCD(PHCDRowid,"DF",ChildSub,"EQ",leq)
		.s FormDoseUOMRowid=$p(eqrec,"^"),eqqty=$p(eqrec,"^",2),eqdefaultqty=$p(eqrec,"^",3),defaultFlag=$p(eqrec,"^",4)
		.;s FormDoseQty=eqdefaultqty
		.if eqdefaultqty'="" s FormDoseQty=eqdefaultqty
		.e  d
		..i PHUseEqQty=1 s FormDoseQty=eqqty
		..e  s FormDoseQty=""
		.s FormDoseUOMDesc=##class(web.DHCDocOrderCommon).GetUOMDesc(FormDoseUOMRowid)
		.i (FormDoseQty'="")&(FormDoseQty<1)&(FormDoseQty'=0) s FormDoseQty="0"_FormDoseQty
		.s formDoseQty(FormDoseUOMRowid)=FormDoseQty_$C(1)_FormDoseUOMDesc_$C(1)_FormDoseUOMRowid_$C(1)_defaultFlag_$C(1)_FormDoseQty
		.s:firstEqUomID="" firstEqUomID=FormDoseUOMRowid
		.s:defaultFlag="Y" defaultFindFlag=1
	}
	q $g(firstEqUomID)
}

/// @debug: w ##class(web.DHCDocMain).CheckPackBaseQty("312031","441||1","3","6")
ClassMethod CheckPackBaseQty(EpisodeID, Arcim, PackQty, PackUom)
{
	/*
	片剂、普通片、分散片、含片、薄膜衣片、咀嚼片、缓释片、控释片、肠溶片、糖衣片、胶囊剂、缓释胶囊剂、软胶囊剂、颗粒剂、散剂、干混悬剂、口服溶液
	*/
	s ^CheckPackBaseQty = $lb(EpisodeID, Arcim, PackQty, PackUom)
	q:EpisodeID="" ""
	q:Arcim="" ""
	q:PackQty="" ""
	q:PackUom="" ""
	s AdmType = $p(^PAADM(EpisodeID),"^",2)
	s HospID=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
	q:HospID'=2 ""
	q:AdmType="I" ""
	s list = $lb("片剂","普通片","分散片","含片","薄膜衣片","咀嚼片","缓释片","控释片","肠溶片","糖衣片","胶囊剂","缓释胶囊剂","软胶囊剂","颗粒剂","散剂","干混悬剂","口服溶液")
	s ItemCatDR=$p(^ARCIM(+Arcim,1,1),"^",10)
	s OrderType=$P(^ARC("IC",ItemCatDR),"^",7)
	q:OrderType'="R" ""
	s Phcdf=##class(web.DHCST.Common.DrugInfoCommon).GetPhcdfByArcim(Arcim)
	s drugform=$p(##class(web.DHCST.Common.DrugInfoCommon).GetFormByPhcdf(Phcdf),"^",2)
	if $lf(list, drugform) {
		s convFac=##class(appcom.OEDispensing).convFac(Arcim,PackUom)
		s res=PackQty*convFac
		;整包装单位
		/*
		s PackUOMRowid=$p($g(^ARCIM(+ArcimRowid,1,8)),"^",14)
		s convFac=##class(appcom.OEDispensing).convFac(Arcim,PackUOMRowid)
		if res < convFac {
				
		}
		*/
		s incId=$o(^INCI(0,"ARCIM_DR",+Arcim,0))
		s UOMFac=1
		i incId'="" d
		.//包装单位
		.s bUom=$p(^INCI(incId,1),"^",10)
		.//基本单位
		.s pUom=$p(^INCI(incId,3),"^",6)
		.//门诊发药单位
		.s outPhUomDr=$p(^INCI(incId,1),"^",12)
		.//入库单位（正包装的）
		.s UOMFac= ##class(PHA.FACE.OUT.Com).UOMFac(pUom,bUom) //整包装单位
		.//s UOMFac= ##class(PHA.FACE.OUT.Com).UOMFac(outPhUomDr,bUom) // 和发药单位匹配
		//取医嘱的销售单位  发药单位
		b ;;;;
		if res < $g(UOMFac) {
			q "Y"	
		}
		q ""
	}
	else {
		q ""	
	}
	;剂型
	;基本单位
	;整包装
}