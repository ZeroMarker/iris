Class User.PatBioBankLog Extends (%Persistent, User.Abstract) [ SqlTableName = Pat_BioBankLog ]
{

// 关联患者

Property PatMasDR As User.PAPatMas [ SqlColumnNumber = 2, SqlFieldName = PatMas_DR ];

// 修改日期

Property ChangeDate As %Date [ SqlColumnNumber = 3, SqlFieldName = PAPMI_BioBankFlagDate ];

// 修改日期

Property ChangeTime As %Time [ SqlColumnNumber = 4, SqlFieldName = PAPMI_BioBankFlagTime ];

// 修改后的值

Property OldValue As %String(COLLATION = "Exact", DISPLAYLIST = ",Yes,No", MAXLEN = 3, TRUNCATE = 1, VALUELIST = ",Y,N") [ SqlColumnNumber = 5, SqlFieldName = PAPMI_BioBankFlagOld ];

// 修改前的值

Property NewValue As %String(COLLATION = "Exact", DISPLAYLIST = ",Yes,No", MAXLEN = 3, TRUNCATE = 1, VALUELIST = ",Y,N") [ SqlColumnNumber = 6, SqlFieldName = PAPMI_BioBankFlagNew ];

// 工号

Property UserId As User.SSUser [ SqlColumnNumber = 7, SqlFieldName = PAPMI_BioBankFlagUserId ];

// IP地址

Property IP As %String [ SqlColumnNumber = 8, SqlFieldName = PAPMI_BioBankFlagIP ];

// 患者索引

Index PatDR On PatMasDR;

Storage Default
{
<Data name="PatBioBankLogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>PatMasDR</Value>
</Value>
<Value name="3">
<Value>ChangeDate</Value>
</Value>
<Value name="4">
<Value>ChangeTime</Value>
</Value>
<Value name="5">
<Value>OldValue</Value>
</Value>
<Value name="6">
<Value>NewValue</Value>
</Value>
<Value name="7">
<Value>PatMasDR</Value>
</Value>
<Value name="8">
<Value>UserId</Value>
</Value>
<Value name="9">
<Value>IP</Value>
</Value>
</Data>
<DataLocation>^User.PatBioBankLogD</DataLocation>
<DefaultData>PatBioBankLogDefaultData</DefaultData>
<IdLocation>^User.PatBioBankLogD</IdLocation>
<IndexLocation>^User.PatBioBankLogI</IndexLocation>
<StreamLocation>^User.PatBioBankLogS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}
