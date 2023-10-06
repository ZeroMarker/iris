sql storage

Global

DataMaster

index
(0,"Code",{CrsCode},{CrsRowId})

$i(^Course(0))
Crs_RowId

d ##(User.Course).%BuildIndices()

s id=0
for {
    s id=$o(^User.CourseD(id))
    s CrsCode=$lg($(^User.CourseD(id)), 4)
    q:id=""
    // generate single index
    s ^User.CourseI("Code",CrsCode,id)=""
}

index sort
(0,"score",40,1)
(0,"score",60,4)
(0,"score",90,2)

s scoreId=0
for {
    s scoreId=$o(^TMP(0,"score",score))
}