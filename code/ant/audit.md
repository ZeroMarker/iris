```objectscript
/// 抗菌药审核后审核
/// w ##class(web.DHCDocMain).AfterInsertAnt("5639||90","668","19590")
/// w ##class(web.DHCDocMain).AfterInsertAnt("4083||250","674","19590")
ClassMethod AfterInsertAnt(OrdItem, App, User)
{
	;抗菌药审核
	;医嘱录入
	;	抗菌药申请ID
	;	医生职称判断
	;	医嘱状态修改
	;发送科室审核
	;	同科室主任 副主任
	;	科室审核
	;		获取审核列表
	;	修改状态
	;		审核
	;		取消审核
	s $zt = "AntErr"
	s ^test4ant = $lb(OrdItem, App, User)
	q:OrdItem="" ""
	if App="" {
		s Arcim = ..Comm("value","OEORD",2,+OrdItem,"I",$p(OrdItem,"||",2),1)
		s EpisodeID = ..Comm("value","OEORD",1,+OrdItem)
		s HospId = ##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
		s App = ..GetArcimApp(EpisodeID,User,HospId,Arcim)
		q:App=""
	}
	
	s Doc = $p($g(^OEORD(+OrdItem,"I",$p(OrdItem,"||",2),1)),"^",11)	;医生
	s Loc = $p($g(^OEORD(+OrdItem,"I",$p(OrdItem,"||",2),7)),"^",2)	;开单科室
	&sql(select CTPCP_CarPrvTp_DR into :type from SQLUser.CT_careprov where ctpcp_rowid = :Doc)
	q:$g(type)="" ""
	&sql(SELECT CTCPT_Desc, CTCPT_InternalType into :typeDesc,:InType FROM SQLUser.CT_CarPrvTp WHERE CTCPT_RowId = :type)
	q:$g(typeDesc)["主任医师" ""
	q:$g(InType)'="DOCTOR" ""
	s obj = ##class(User.OEOrdItem).%OpenId(OrdItem)
	q:obj="" ""
	// 未审核
	d obj.OEORIItemStatDRSetObjectId(10)
	ts
	s sc = obj.%Save()
	if $$$ISERR(sc) {
		tro
		q ""	
	}
	else {
		tc	
	}
	s arcim=$p(^DHCDAA("ANT",App),"^",2)
 	s admId=$p(^DHCDAA("ANT",App),"^",1)
 	s appDoc=$p(^DHCDAA("ANT",App),"^",9)
 	s admType=##class(DHCAnt.KSS.Common.Method).GetPAAdmType(admId)
 	s poisonId=##class(DHCAnt.KSS.Common.Method).GetKssPoisonId(arcim)
 	s HospId = ##class(DHCDoc.Common.Hospital).GetAdmHospitalId(admId)
 	s users = ##class(DHCAnt.KSS.Extend.MessageTip).GetLocAuthDoc(Loc,admType,poisonId,HospId)
 	s users = $p(users,"!",1)
 	//指定link形式，link属性为要开的链接及所需参数，此时不再需要linkParam属性
	s jsonObj=##class(BSP.SYS.COM.ProxyObject).%New()
	s jsonObj.link="dhcant.kss.business.loc.audit.hui.csp?AARowid="_App_"&Status=H"   //消息对应业务界面链接和参数
	s jsonObj.BizObjId=App_"-KS"  //;业务ID  用于消息后续处理、撤销等
	s otherInfoJson=jsonObj.%ToJSON()    //;转成Json字符串
	b ;;;send
	s status = "H"
	s process = "S"
	s msg = ..BuildMessage(1,App,status,process)
	s msgTipKssCode=##class(DHCAnt.Base.MainConfigExcute).GetOSValueByCode("MSGTIPKSSCODE")
	s ^AntLocAudit(App) = $lb(msg,
		msgTipKssCode,
		User,
		admId,
		"",
		users,
		otherInfoJson,
		Loc_"|Onlyflag",
		"",
		Loc
	)
	d ##class(websys.DHCMessageInterface).Send(msg,
		msgTipKssCode,
		User,
		admId,
		"",
		users,
		otherInfoJson,
		Loc_"|Onlyflag",
		"",
		Loc
	)
	if $g(^AntAuditLog(App)) = "" {
		s ^AntAuditLog(App) = $lb(OrdItem)
	}
	else {
		s len = $ll(^AntAuditLog(App))
		s $list(^AntAuditLog(App),len+1) = OrdItem	
	}
	q 0
AntErr
	s ^AntErr(OrdItem) = $ze
	s $zt=""
	q $ze
}

ClassMethod LocAudit(AppStr)
{
	; 修改医嘱状态
	q:AppStr="" ""
	s len = $l(AppStr,"^")
	s result = ""
	for i=1:1:len {
		s App = $p(AppStr,"^",i)
		s OrdItem = $p(^DHCDAA("ANT",+App,1),"^",6)
		s sc = ..LocAuditOne(App, OrdItem)
		if $g(^AntAuditLog(App)) '= "" {
			s len = $ll(^AntAuditLog(App))
			for i=1:1:len {
				s OrdItem = $lg(^AntAuditLog(App),i)
				s sc = ..LocAuditOne(App,OrdItem)
				s result = result_sc
			}
		}
		s result = result_sc
	}
	q +result
}

ClassMethod LocAuditOne(App, OrdItem)
{
	; 修改医嘱状态
	q:OrdItem="" ""
	s obj = ##class(User.OEOrdItem).%OpenId(OrdItem)
	q:obj="" ""
	
	// 核实
	s status = 1	
	
	d obj.OEORIItemStatDRSetObjectId(status)
	ts
	s sc = obj.%Save()
	if $$$ISERR(sc) {
		tro
		q 1	
	}
	else {
		tc
		;Exec
		s EpisodeId = $lg(^AntLocAudit(App),4)
		s msgTipKssCode=##class(DHCAnt.Base.MainConfigExcute).GetOSValueByCode("MSGTIPKSSCODE")
		s ObjectId = App_"-KS"
		
		s User = ""
		if $d(%session)  {
			s User = %session.Data("LOGON.USERID")	
		}
		s ^Ant4Exec(App) = $lb("", msgTipKssCode, EpisodeId, "", ObjectId, User)
		d ##class(websys.DHCMessageInterface).Exec("", msgTipKssCode, EpisodeId, "", ObjectId, User)
		
		s status = "A"
		s process = "B"
		;d ..AfterLocAudit(OrdItem, App, status, process)
		q 0
	}
}

/// w ##class(web.DHCDocMain).GetArcimApp(4171,19590,2,"47||1")
ClassMethod GetArcimApp(EpisodeID, UserID, HospID, Arcim)
{
	q:EpisodeID="" ""
	q:UserID="" ""
	q:HospID="" ""
	q:Arcim="" ""
	s App = ""
	s query = ##class(%ResultSet).%New()
	s query.ClassName="DHCAnt.KSS.MainInterface"
	s query.QueryName="QryAntApplyInfo"

	if query.QueryIsValid() {
	    s rc = query.Execute(EpisodeID,UserID,HospID)
	    while (query.Next()) {
	        s id = query.Data("ArcimId")
	        if id = Arcim {
	            s status = query.Data("AppStatus")
	            if status = "U" {
		        	s App = query.Data("id")    
		        }
	        }
	        s oeori = query.Data("cOeori")
	        if oeori '= "" {
		    	;s App = ""    
		    }
			q:App'=""
	    }
	}
	d query.%Close()
	q App
}

/// w ##class(web.DHCDocMain).GetArcimCat("15540||1")
ClassMethod GetArcimCat(Arcim)
{
	q:Arcim="" ""
	q ..Comm("value","ARCIM",10,+Arcim,1,1)
}

/// w ##class(web.DHCDocMain).CheckAdmTime(1,$zt(40000))
ClassMethod CheckAdmTime(EpisodeID, Time)
{
	q:EpisodeID="" ""
	q:Time="" ""
	s AdmTime=$p($g(^PAADM(EpisodeID)),"^",7)
	s TimeZ = $zth(Time)
	if AdmTime > TimeZ {
		q $zt(AdmTime) 	
	}
	q Time
}

ClassMethod IsConsultFinish(App, EpisodeID, UserID, HospID)
{
	q:App="" ""
	q:EpisodeID="" ""
	q:UserID="" ""
	s flag = 1
	s query = ##class(%ResultSet).%New()
	s query.ClassName="DHCAnt.KSS.MainInterface"
	s query.QueryName="QryAntApplyInfo"

	if query.QueryIsValid() {
	    s rc = query.Execute(EpisodeID,UserID,HospID)
	    while (query.Next()) {
			s id = query.Data("id")
			if id = App {
				;ConsultDoc1:%String,ConsultDT1
		        s ConsultDoc1 = query.Data("ConsultDoc1")
		        s ConsultDT1 = query.Data("ConsultDT1")
		        s ConsultDoc2 = query.Data("ConsultDoc2")
		        s ConsultDT2 = query.Data("ConsultDT2")
		        s ConsultDoc3 = query.Data("ConsultDoc3")
		        s ConsultDT3 = query.Data("ConsultDT3")
		        if (ConsultDoc1 '= "") && (ConsultDT1 ="") {
			    	s flag = 0
			    }
			    if (ConsultDoc2 '= "") && (ConsultDT2 ="") {
			    	s flag = 0
			    }
			    if (ConsultDoc3 '= "") && (ConsultDT3 ="") {
			    	s flag = 0
			    }
			    b ;;; flag	
			}
		    
	    }
	}
	d query.%Close()
	q flag
}

/// w ##class(web.DHCDocMain).diff($zdh("2024-07-18",3),$zth("17:00:00"))
ClassMethod diff(date, time)
{
	s diff = ((+$h - date) * 60 * 60 * 24) + ($p($h,",",2) - time)
	b ;;; diff
	if diff > (60 * 60 * 24) {
		q 0
	}
	else {
		q 1	
	}
}
```