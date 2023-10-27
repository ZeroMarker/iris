/// 功能：创建学生表
/// 创建日期：2023-07-25
/// 创建人：chenhongliang
/// 字段：St_Rowid, St_Code, St_Name, St_Sex_DR(CT_Sex), St_Dob
Class demo.Student Extends %Persistent [ SqlRowIdName = St_RowID, SqlTableName = DHC_StudentUNI ]
{

// 学号

Property StCode As %String [ SqlColumnNumber = 2, SqlFieldName = St_Code ];

// 姓名

Property StName As %String [ SqlColumnNumber = 3, SqlFieldName = St_Name ];

// 性别

Property StSexDR As %String [ SqlColumnNumber = 4, SqlFieldName = St_Sex_DR ];

// 生日

Property StDob As %Date [ SqlColumnNumber = 5, SqlFieldName = St_Dob ];

// 建立学号索引

Index CodeIdx On StCode [ Unique ];

// 建立姓名索引

Index NameIdx On StName As Exact;

ClassMethod PrintHello()
{
    write "Hello",!
}

ClassMethod GetSexDescByAdmRowId(RowId As %String) As %String
{
    q:RowId="" "RowId不能为空"
    s AdmStr = $g(^PAADM(RowId))
    s PatMasDR = $p(AdmStr,"^",1)
    s PatMasStr = $g(^PAPER(PatMasDR,"ALL"))
    s SexDR = $p(PatMasStr,"^",7)
    s SexStr = $g(^CT("SEX",SexDR))
    s SexDesc = $p(SexStr,"^",2)
    q "就诊RowId为"_RowId_"的病人性别为："_SexDesc
}

Property StActive As %String(DISPLAYLIST = ",Yes,No", VALUELIST = ",Y,N");

Index StActiveIndex On StActive;

Storage Default
{
<Data name="StudentDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>StCode</Value>
</Value>
<Value name="3">
<Value>StName</Value>
</Value>
<Value name="4">
<Value>StSexDR</Value>
</Value>
<Value name="5">
<Value>StDob</Value>
</Value>
<Value name="6">
<Value>StActive</Value>
</Value>
</Data>
<DataLocation>^demo.StudentD</DataLocation>
<DefaultData>StudentDefaultData</DefaultData>
<IdLocation>^demo.StudentD</IdLocation>
<IndexLocation>^demo.StudentI</IndexLocation>
<StreamLocation>^demo.StudentS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
