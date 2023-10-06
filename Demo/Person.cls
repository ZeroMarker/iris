Class Demo.Person Extends (%Persistent, %Library.Populate)
{

// a person's name

Property Name As %String [ Required ];

// phone number

Property Phone As %String;

// age

Property Age As %Integer;

ClassMethod GetSum() As %String
{
    s Id = 0
    for
    {
        s Id = $O(^CT("TTL", Id))   // next element
        q:Id="" // if Id = "" quit return
        s Desc=$p($g(^CT("TTL", Id)), "^", 2)
        w Desc , ! // Line feed, Carriage return
        s a="a"
        s b="b"
        write ?10,a,?20,b   // 10th column, 20th column
    }
}

// Query ByName(name As %String = "") As %SQLQuery(COMPILEMODE = "IMMEDIATE", CONTAINID = 1, ROWSPEC = "ID:%Integer,Name:%String,DOB:%Date,SSN:%String", SELECTMODE = "RUNTIME") [ SqlName = SP_Sample_By_Name, SqlProc ]

// {

//     SELECT ID, Name, DOB, SSN

//     FROM Demo.Person

//     WHERE (Name %STARTSWITH :name)

//     ORDER BY Name

// }

ClassMethod DQuery()
{
    SET myquery = "SELECT top 40 * FROM SQLUser.PA_PatMas"
    SET tStatement = ##class(%SQL.Statement).%New()
    SET tStatus = tStatement.%Prepare(myquery)
    SET rset = tStatement.%Execute()
    DO rset.%Display()
    WRITE !,"End of data"
}

ClassMethod InQuery()
{
    &sql(SELECT COUNT(*) INTO :myvar FROM SQLUser.PA_PatMas)
    IF SQLCODE<0 {WRITE "SQLCODE error ",SQLCODE," ",%msg  QUIT}
    ELSEIF SQLCODE=100 {WRITE "Query returns no results"  QUIT}
    WRITE myvar
}

/// SQLQuery
/// Query
/// Others:d ##class(%ResultSet).RunQuery("Demo.Person","GetList")
/// Query GetList() As %Query(ROWSPEC = "StRowId:%String,StCode,%String,StName:%String,StSexDR,%String,StDob:%String")
Query GetList() As websys.Query(ROWSPEC = "StRowID:%String,StCode,%String,StName:%String,StSexDR,%String,StDob:%String")
{
}

ClassMethod GetListExecute(ByRef qHandle As %Binary) As %Status
{
    s repid = $i(^CacheTemp)
    s ind = 1

    s StRowID = 0
    for
    {
        s StRowID = $O(^DHCSTUDENTSFA(StRowID))
        q:StRowID'=""
        s StCode = $p($g(^DHCSTUDENTSFA,StRowID),"^",1)
        s StName = $p($g(^DHCSTUDENTSFA,StRowID),"^",2)
        s StSexDR = $p($g(^DHCSTUDENTSFA,StRowID),"^",3)
        s:StSexDR'="" StSexDR = $p($g(^CT("SEX",StSexDR)),"^",2)
        s StDob = $p($g(^DHCSTUDENTSFA,StRowID),"^",4)
        s:StDob'="" StDob = $zd(StDob, 3)
        s Data = $lb(StRowID,StCode,StName,StSexDR,StDob)
        s ^CacheTemp(repid,ind)=Data
        s ind = ind + 1        
    }
    s qHandle = $lb(0,repid,0)
    q $$$OK
}

// instance method, print

Method Print() As %Status
{
    write !, "This prerson is named ", ..Name, "."
    write !, ..Name, "'s phone number is ", ..Phone, "."
    write !, ..Name, "'s age is ", ..Age, "."
}

/// Function:获取rowId为3的病人（PA_Person）的生日（PAPER_Dob） (YYYY-MM-DD)
/// CreateDate:2023-07-24
/// Creator:chenhongliang
/// Table:PA_Person
/// Input:rowId
/// Output:PAPER_Dob (YYYY-MM-DD)
/// Others: d ##class(Demo.Person).GetPatientBirthday(3)
ClassMethod GetPatientBirthday(RowId As %String) As %String
{
    quit:RowId="" ""
    // ^PAPER(2,"ALL")="zfmcs0707^ZFMCS0707^^^^53879^2^^^^^^^^^^^^^^^^^^20"
    set PatientStr = $Get(^["DHC-APP"]PAPER(RowId,"ALL"))  // 获取数据串
    set PaperDob = $Piece(PatientStr,"^",6)     // 截取所需字段
    s:PaperDob'="" PaperDob=$ZDATE(PaperDob, 3)
    quit "RowId为"_RowId_"的病人（PA_Person）的生日"_PaperDob
}

/// Table:DHC_Student_SFA
/// Others:##class(Demo.Person).InsertData(1,"name",1,"2023-01-01")
ClassMethod InsertData(StCode As %String, StName As %String, StSexDR As %String, StDob As %String) As %String
{
    if (StDob'="")
    {
        s StDob = $zdh(StDob,3)
    }
    &SQL(
        INSERT INTO SQLUser.DHC_Student_SFA
        Values (:StCode, :StName, :StSexDR, :StDob)
    )
    if (SQLCODE=0)
    {
        s result="新增成功"_%ROWID
    }
    else
    {
        s result="新增失败"_%msg
    }
    q result
}

ClassMethod AddMRCICDByPLIST()
{

    K PLIST
    s PLIST(1)="name"
    &SQL(
        INSERT INTO SQLUser.DHC_Student_SFA
        Values :PLIST()
    )
}

Method GetName()
{
    q $this.Name
}

/// Function:无索引的数据遍历
/// CreateDate:2023-07-26
/// Creator:chenhongliang
/// Table:DHC_StudentSFA
/// Input: rowid
/// Outpput:St_List
/// Others
ClassMethod GetDataList(StRowID As %String) As %String
{
    if ($Get(StRowID)'="")
        {if ($DATA(^["DHC-APP"]DHCSTUDENTSFA(StRowID))=0)
        {
            w "该学生不存在"
        }
        else
        {
            s DataStr = $Get(^["DHC-APP"]DHCSTUDENTSFA(StRowID))
            s StCode = $Piece(DataStr,"^",1)
            s StName = $Piece(DataStr,"^",2)
            s StSexDR = $Piece(DataStr,"^",3)
            #; s StSexDRDesc = ""
            s:StSexDR'="" StSexDRDesc = $Piece($Get(^["DHC-APP"]CT("SEX",StSexDR)),"^",2)
            s StDob = $Piece(DataStr,"^",4)
            s:StDob'="" StDob = $ZDATE(StDob, 3)
            w "学号"_StCode_",姓名"_StName_",性别"_StSexDRDesc_",生日"_StDob
        }
    }
    else
    {
        s StRowID = 0
        for
        {
            s StRowID = $O(^["DHC-APP"]DHCSTUDENTSFA(StRowID))
            q:StRowID=""
            w StRowID ,!
            s DataStr = $Get(^["DHC-APP"]DHCSTUDENTSFA(StRowID))
            s StCode = $Piece(DataStr,"^",1)
            s StName = $Piece(DataStr,"^",2)
            s StSexDR = $Piece(DataStr,"^",3)
            #; s StSexDRDesc = ""
            s:StSexDR'="" StSexDRDesc = $Piece($Get(^["DHC-APP"]CT("SEX",StSexDR)),"^",2)
            s StDob = $Piece(DataStr,"^",4)
            s:StDob'="" StDob = $ZDATE(StDob, 3)
            w "学号"_StCode_",姓名"_StName_",性别"_StSexDRDesc_",生日"_StDob
            w !
        }
    }
}

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
        Tstart
        d oref.%Save()
        if ($$$ISOK(sc))    // (sc)=1
        {
            Tcommit
            s StRowId = oref.%Id()
            s result = "新增成功"_StRowId
        }
        else
        {
            Trollback
            s result = "新增失败"_$system.OBJ.DisplayError(sc)
        }
    }
    d oref.%Close()
    q result
}

ClassMethod GetAddressByCode(Code As %String) As %String
{
    /*
    s count = 0
    s CTADDRowID = 0
    for
    {
        s CTADDRowID = $Order(^CT("ADD",CTADDRowID))
        q:CTADDRowID=""
        s CTADDCode = $Piece($Get(^CT("ADD",CTADDRowID)),"^",1)
        s count=count+1
        if (CTADDCode=Code)
        {
            s CTADDDesc = $Piece($Get(^CT("ADD",CTADDRowID)),"^",2)
            w "代码"_Code_"对应的地址为"_CTADDDesc
            w !
        }
    }
    */
    s CTADDRowID = $Order(^CT("ADD",0,"Code",Code,0))
    if (CTADDRowID'="")
    {
        s CTADDDesc = $Piece($Get(^CT("ADD",CTADDRowID)),"^",2)
        w "代码"_Code_"对应的地址为"_CTADDDesc
        w !
    }
}

/// Planet
Parameter PLANET = "Earth";

Storage Default
{
<Data name="PersonDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Phone</Value>
</Value>
<Value name="4">
<Value>Age</Value>
</Value>
</Data>
<DataLocation>^Demo.PersonD</DataLocation>
<DefaultData>PersonDefaultData</DefaultData>
<IdLocation>^Demo.PersonD</IdLocation>
<IndexLocation>^Demo.PersonI</IndexLocation>
<StreamLocation>^Demo.PersonS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}
