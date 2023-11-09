Class demo.Person Extends (%Persistent, %Library.Populate)
{

/// Planet
Parameter PLANET = "Earth";

// name

Property Name As %String [ Required ];

// phone

Property Phone As %String;

// age

Property Age As %Integer;

// phone index

Index PhoneIdx On Phone As Exact;

ClassMethod GetSum() As %String
{
    s Id = 0
    for
    {
        s Id = $O(^demo.PersonI("PhoneIdx", Id))   // next element
        q:Id="" // if Id = "" quit return
        s Desc=$lg(^demo.PersonD(Id), 2)
        w Desc , ! // Line feed, Carriage return
        s a="a"
        s b="b"
        write ?10,a,?20,b   // 10th column, 20th column
    }
}

Query ByName(name As %String = "") As %SQLQuery(COMPILEMODE = "IMMEDIATE", CONTAINID = 1, ROWSPEC = "ID:%Integer,Name:%String,DOB:%Date,SSN:%String", SELECTMODE = "RUNTIME") [ SqlName = SP_Sample_By_Name, SqlProc ]
{
    SELECT ID, Name, Phone, Age FROM demo.Person
    WHERE (Name = :name)
    ORDER BY Name
}

ClassMethod DQuery()
{
    SET myquery = "SELECT top 40 * FROM demo.Person"
    SET tStatement = ##class(%SQL.Statement).%New()
    SET tStatus = tStatement.%Prepare(myquery)
    SET rset = tStatement.%Execute()
    DO rset.%Display()
    WRITE !,"End of data"
}

ClassMethod InQuery()
{
    &sql(SELECT COUNT(*) INTO :myvar FROM demo.Person)
    IF SQLCODE<0 {
        WRITE "SQLCODE error ",SQLCODE," ",%msg  
        QUIT
    }
    ELSEIF SQLCODE=100 {
        WRITE "Query returns no results"  
        QUIT
    }
    WRITE myvar
}

Method Print() As %Status
{
    write !, "This prerson is named ", ..Name, "."
    write !, ..Name, "'s phone number is ", ..Phone, "."
    write !, ..Name, "'s age is ", ..Age, "."
}

/// Others: d ##class(Demo.Person).GetPatientBirthday(3)
ClassMethod GetPatientBirthday(RowId As %String) As %String
{
    quit:RowId="" ""
    set PatientStr = $Get(^["USER"]demo.PersonD(RowId))  // 获取数据串
    set PaperDob = $Piece(PatientStr,"^",6)     // 截取所需字段
    s:PaperDob'="" PaperDob=$ZDATE(PaperDob, 3)
    quit "RowId为"_RowId_"的病人的生日:"_PaperDob
}

/// Table:Student
/// d ##class(demo.Person).InsertData(1,"name",1,"2023-01-01")
ClassMethod InsertData(StCode As %String, StName As %String, StSexDR As %String, StDob As %String) As %String
{
    if (StDob'="")
    {
        s StDob = $zdh(StDob,3)
    }
    &sql(
        INSERT INTO demo.Student
        Values (:StCode, :StName, :StSexDR, :StDob)
    )
    if (SQLCODE=0) {
        s result="新增成功"_%ROWID
    }
    else {
        s result="新增失败"_%msg
    }
    q result
}

Method GetName()
{
    q $this.Name
}

/// Function:无索引的数据遍历
/// CreateDate:2023-07-26
/// Table:Student
/// Input: rowid
/// Outpput:St_List
/// Others: d ##class(demo.Person).GetDataList(3)
ClassMethod GetDataList(StRowID As %String) As %String
{
    if ($Get(StRowID)'="") {
        if ($DATA(^["USER"]demo.StudentD(StRowID))=0) {
            q "该学生不存在"
        }
        else {
            s DataStr = $Get(^["USER"]demo.StudentD(StRowID))
            s StCode = $lg(DataStr,1)
            s StName = $lg(DataStr,2)
            s StSexDR = $lg(DataStr,3)
            s:StSexDR'="" StSexDRDesc = $LIST($Get(^["User"]demo.Sex(StSexDR)),2)
            s StDob = $lg(DataStr,4)
            s:StDob'="" StDob = $ZDATE(StDob, 3)
            w "学号"_StCode_",姓名"_StName_",性别"_StSexDRDesc_",生日"_StDob
        }
    }
    else {
        s StRowID = 0
        for {
            s StRowID = $O(^["USER"]demo.StudentD(StRowID))
            q:StRowID=""
            w StRowID ,!
            s DataStr = $Get(^["USER"]demo.StudentD(StRowID))
            s StCode = $lg(DataStr,1)
            s StName = $lg(DataStr,2)
            s StSexDR = $lg(DataStr,3)
            #; s StSexDRDesc = ""
            s:StSexDR'="" StSexDRDesc = $LIST($Get(^["User"]demo.Sex(StSexDR)),2)
            s StDob = $lg(DataStr,4)
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
    q:$Data(^["USER"]demo.StudentI("CodeIdx",StCode)) "学号已存在"
    if (StDob'="") {
        s StDob = $ZD(StDob)
    }
    s oref=##class(demo.Student).%New()
    if (oref) {
        s oref.StCode = StCode
        s oref.StName = StName
        d oref.StSexDRSetObjectId(StSexDR)  // 指向性字段，使用SetObjectId()
        s oref.StDob = StDob
        Tstart
        d oref.%Save()
        if ($$$ISOK(sc)) {
            Tcommit
            s StRowId = oref.%Id()
            s result = "新增成功"_StRowId
        }
        else {
            Trollback
            s result = "新增失败"_$system.OBJ.DisplayError(sc)
        }
    }
    ;d oref.%Close() 
    /*
    This method is deprecated because we now reference count objects automatically so there is no need to call this method. It is a no-op and just returns success %Status code.
    */
    q result
}

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
<DataLocation>^demo.PersonD</DataLocation>
<DefaultData>PersonDefaultData</DefaultData>
<IdLocation>^demo.PersonD</IdLocation>
<IndexLocation>^demo.PersonI</IndexLocation>
<StreamLocation>^demo.PersonS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
