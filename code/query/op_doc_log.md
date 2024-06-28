```objectscript
/// desc: 获取科室号别
/// input: LogLoc 科室
/// output: CTPCPDesc 科室号别 CTPCPRowId 科室号别ID
/// debug: d ##class(%ResultSet).RunQuery("web.DHCUserGroup","FindLogonLocCTPCPDesc","21")
Query FindLogonLocCTPCPDesc(LogLoc As %String, Desc As %String = "") As %SQLQuery(CONTAINID = 1, ROWSPEC = "CTPCPDesc:%String,CTPCPRowId:%String")
{
	SELECT DISTINCT MarkdMarkDr->CTPCP_Desc, MarkdMarkDr->CTPCP_RowId FROM DHCMarkDoc
	WHERE MarkdDocDr IN (
		SELECT SSUSR_CareProv_DR->CTPCP_RowId FROM SS_User 
		WHERE SSUSR_RowId IN (
			SELECT OTHLL_ParRef FROM SS_UserOtherLogonLoc WHERE OTHLL_CTLOC_DR=:LogLoc 
				and (OTHLL_StartDate is null or OTHLL_StartDate <= {fn CURDATE()})
				and (OTHLL_EndDate is null or OTHLL_EndDate >= {fn CURDATE()})
			union
			SELECT SSUSR_RowId FROM SS_User WHERE SSUSR_DefaultDept_DR=:LogLoc
		) AND SSUSR_CareProv_DR IS NOT null and :LogLoc  is not null
		and (
		((SSUSR_Name like '%'||:Desc||'%') or (:Desc is null) or (SSUSR_Initials =:Desc) or (SSUSR_Initials like '%'||:Desc||'%'))
		)
	)
}
```
