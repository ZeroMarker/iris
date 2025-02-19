Class better.string Extends %RegisteredObject
{
ClassMethod StringOut() 
{
    s list = $lb(
        1, 2, 43, 4
    )
    s list = $lts(list, "^")
    q list

    s list = $lfs("2,3,3",",")
}
ClassMethod List()
{
    for i=1:1:5 {
        s $list(list,i) = i
    }
    q list

    s $list(list, $ll($g(list))+1) = it
}
}