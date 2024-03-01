Class doc.code.biobank.biobank Extends %RegisteredObject
{
/// w ##class(web.DHCExamPatList).SaveBioBank(5997929,"Y","N")
ClassMethod SaveBioBank(PatientID, NewValue, OldValue)
{
    s biobanklog = ##class(User.PatBioBankLog).%New()
    s UserId = %session.Data("LOGON.USERID")
    s UserId = $p($g(^SSU("SSUSR",UserId)), "^", 1)
    s IP = ##class(%SYSTEM.Process).ClientIPAddress()
    if (OldValue'=NewValue) {
    	d biobanklog.PatMasDRSetObjectId(PatientID)
        s biobanklog.ChangeDate = $p($h,",",1)
        s biobanklog.ChangeTime = $p($h,",",2)
        s biobanklog.OldValue = OldValue
        s biobanklog.NewValue = NewValue
        s biobanklog.IP = IP
        d biobanklog.UserIdSetObjectId(UserId)
        TSTART
        s rtn = biobanklog.%Save()
        if ($System.Status.IsOK(rtn)) {
        	TCOMMIT
           	s result = "生物标本库修改日志保存成功"
        }
        else {
	        TROLLBACK
	        do $System.Status.DisplayError(rtn)
            set myrtn = "-100"
            q myrtn_"^"
	    }
    }
   	else {
	    s result = result_"两次修改相同"	
	}
    d biobanklog.%Close()
    q result
}

Query GetBioBankFlagLog(PatNo As %String) As %Query(ROWSPEC = "PatNo:%String:登记号,PatName:%String:姓名,ChangeDate:%String:修改日期,ChangeTime:%String:修改时间,OldValue:%String:旧值,NewValue:%String:新值,UserId:%String:工号,IP:%String:IP地址,PAPMIRowId:%String")
{
}

/// d ##class(%ResultSet).RunQuery("web.DHCExamPatList","GetBioBankFlagLog","07668157")
ClassMethod GetBioBankFlagLogExecute(ByRef qHandle As %Binary, PatNo As %String) As %Status
{
	q:PatNo=""
	set repid = $i(^CacheTemp)
    set ind = 1
	s id = 0
	s PAPMIRowId = $o(^PAPERi("PAPMI_PatNo", $zcvt(PatNo, "U"), ""))
    for {	    
        s id=$o(^User.PatBioBankLogI("PatDR", PAPMIRowId, id))
        q:id=""
        s PatientNo = PatNo
        s PatName = $p(^PAPER(PAPMIRowId,"ALL"), "^", 1)
        s ChangeDate = $zd($lg(^User.PatBioBankLogD(id), 3), 3)
        s ChangeTime = $zt($lg(^User.PatBioBankLogD(id), 4), 1)
        s OldValue = $lg(^User.PatBioBankLogD(id), 5)
        s NewValue = $lg(^User.PatBioBankLogD(id), 6)
        s UserId = $lg(^User.PatBioBankLogD(id), 8)
        s IP = $lg(^User.PatBioBankLogD(id), 9)
        //生物标本库
		set TBioBankFlag = $p($g(^PAPER(PAPMIRowId,"PAT",1)),"^",25)
        d OutputRow
    }
    s qHandle=$lb(0, repid, 0)
    quit $$$OK
OutputRow
    s ^CacheTemp(repid, ind)=$lb(PatientNo, PatName, ChangeDate, ChangeTime,OldValue, NewValue, UserId, IP, id)
    s ind = ind + 1
    quit
}

ClassMethod GetBioBankFlagLogClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GetBioBankFlagLogExecute ]
{
	Set repid = $LIST(qHandle,2)
	Kill ^CacheTemp(repid)
	Quit $$$OK
}

ClassMethod GetBioBankFlagLogFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetBioBankFlagLogExecute ]
{
	Set AtEnd=$LIST(qHandle,1)
	Set repid=$LIST(qHandle,2)
	Set ind=$LIST(qHandle,3)
	Set ind=$o(^CacheTemp(repid,ind))
	If ind="" {				// if there are no more rows, finish fetching
		Set AtEnd=1
		Set Row=""
	}
	Else      {				// fetch row
		Set Row=^CacheTemp(repid,ind)
	}
	// Save QHandle
	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}
}