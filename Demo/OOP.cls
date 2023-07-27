Class Demo.OOP
{
ClassMethod ObjectAddData(StCode As %String, StName As %String, StSexDR As %String, StDob As %String) As %String
{
    q:StCode="" "学号不能为空"
    q:StName="" "姓名不能为空"
    q:$Data(^DHCSTUDENTSFA("Code",StCode)) "学号已存在"
    if (StDob'="")
    {
        s StDob = ##class(websys.Conversions).DateHtmlToLogical(StDob)
    }
    s oref=##class(User.DHCStudentSFA).%New()
    if (oref)
    {
        s oref.StCode = StCode
        s oref.StName = StName
        d oref.StSexDRSetObjectId(StSexDR)  // 指向性字段，使用SetObjectId()
        s oref.StDob = StDob
        d oref.%Save()
        if ($$$ISOK(sc))    // (sc)=1
        {
            s StRowId = oref.%Id()
            s result = "新增成功"_StRowId
        }
        else
        {
            s result = "新增失败"_$system.OBJ.DisplayError(sc)
        }
    }
    d oref.%Close()
    q result
}    
}