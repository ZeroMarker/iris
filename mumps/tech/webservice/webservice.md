## WSDL
```objectscript
Class Soap Extend %SOAP
{
Method GetName() As %String [WebMethod]
{
    // write something
}
}
```


s obj=##class(Soap).%New()
obj.GetName()
