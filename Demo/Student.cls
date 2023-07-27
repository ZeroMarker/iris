/// 功能：创建学生表
/// 创建日期：2023-07-25
/// 创建人：chenhongliang
/// 字段：St_Rowid, St_Code, St_Name, St_Sex_DR(CT_Sex), St_Dob
Class Demo.Student Extends %Persistent [ SqlRowIdName = St_RowID, SqlTableName = DHC_StudentUNI ]
{

// 学号

Property StCode As %String [ SqlColumnNumber = 2, SqlFieldName = St_Code ];

// 姓名

Property StName As %String [ SqlColumnNumber = 3, SqlFieldName = St_Name ];

// 性别

Property StSexDR As User.CTSex [ SqlColumnNumber = 4, SqlFieldName = St_Sex_DR ];

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

/// ^User.DHCStudentUNID
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
<DataLocation>^Demo.StudentD</DataLocation>
<DefaultData>StudentDefaultData</DefaultData>
<Description>
<![CDATA[^User.DHCStudentUNID]]></Description>
<IdLocation>^Demo.StudentD</IdLocation>
<IndexLocation>^Demo.StudentI</IndexLocation>
<StreamLocation>^Demo.StudentS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

Property StActive As %String(DISPLAYLIST = ",Yes,No", VALUELIST = ",Y,N");

Index StActiveIndex On StActive;

}
