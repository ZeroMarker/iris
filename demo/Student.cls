Class demo.Student Extends %Persistent [ SqlRowIdName = St_RowID, SqlTableName = Student ]
{

// 学号

Property StCode As %String [ SqlColumnNumber = 2, SqlFieldName = St_Code ];

// 姓名

Property StName As %String [ SqlColumnNumber = 3, SqlFieldName = St_Name ];

// 性别

Property StSexDR As %String [ SqlColumnNumber = 4, SqlFieldName = St_Sex_DR ];

// 生日

Property StDob As %Date [ SqlColumnNumber = 5, SqlFieldName = St_Dob ];

// 是否有效

Property StActive As %String(DISPLAYLIST = ",Yes,No", VALUELIST = ",Y,N");

// 学号索引

Index CodeIdx On StCode As Exact;

// 姓名索引

Index NameIdx On StName As Exact;

// 有效索引

Index StActiveIndex On StActive;

ClassMethod PrintHello()
{
    write "Hello",!
}

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
