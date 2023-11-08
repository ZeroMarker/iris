Class demo.Sex Extends (%Persistent, %Library.Populate)
{

Property Desc As %String;

Storage Default
{
<Data name="SexDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Desc</Value>
</Value>
</Data>
<DataLocation>^demo.SexD</DataLocation>
<DefaultData>SexDefaultData</DefaultData>
<IdLocation>^demo.SexD</IdLocation>
<IndexLocation>^demo.SexI</IndexLocation>
<StreamLocation>^demo.SexS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
