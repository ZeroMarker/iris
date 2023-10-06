-- @Block
SELECT * FROM SQLUser.CT_Sex 

-- @Block
SELECT * FROM SQLUser.DHC_StudentSFC

-- @Block
INSERT INTO SQLUser.DHC_StudentSFC VALUES ('1', '2023-01-01', '张', '1')

-- @Block
SELECT TARAC_TARTAC_DR -> TARTAC_Desc, * FROM SQLUser.DHC_TarAcctCate

-- @Block
SELECT * FROM SQLUser.PA_PatMas

-- @Block
SELECT AA_Arcim_DR -> ARCIM_Desc AS apply_count, count(*) 
FROM SQLUser.DHC_Doc_AntibioticApply 
group by AA_Arcim_DR

SELECT * FROM SQLUser.CT_Sex 

Select * from SQLUser.DHC_Student_SFA 

SELECT TARAC_TARTAC_DR->TARTAC_Desc,* FROM SQLUser.DHC_TarAcctCate 

Select * FROM SQLUser.CT_Address 

SELECT * FROM SQLUser.DHC_Student_SFA
insert INTO SQLUser.DHC_Student_SFA values ('2', '陈',  '1', '2023-02-02')

select * from SQLUser.PA_PatMas 

select * from SQLUser.DHC_PA_PatMas

SELECT * from SQLUser.CT_Hospital

select * from SQLUser.ARC_BillGrp 

SELECT * FROM SQLUser.ARC_ItmMast 
SELECT * FROM ARC_ItmMast

select AA_Arcim_DR -> ARCIM_Desc AS apply_count, count(*) FROM SQLUser.DHC_Doc_AntibioticApply group by AA_Arcim_DR

select AA_Arcim_DR -> ARCIM_Desc,* FROM SQLUser.DHC_Doc_AntibioticApply group by AA_Arcim_DR

select * from SQLUser.DHC_CardRef 

SELECT *
FROM SQLUser.OE_OrdItem
WHERE 
select PAPMI_ConcessionCardNo ,* from SQLUser.PA_PatMas 
SELECT  AA_OEORI_DR->OEORI_InsertDate
FROM SQLUser.DHC_Doc_AntibioticApply 
SELECT*
SELECT  AA_OEORI_DR-->OEORI_OEORD_ParRef->OEORD_Adm_DR->PAADM_PAPMI_DR->PAPMI_No AS PA 
FROM SQLUser.DHC_Doc_AntibioticApply
WHERE AA_OEORI_DR like "%||%"

SELECT OEORI_RowId FROM SQLUser.OE_OrdItem 
WHERE OEORI_RowId like "266%"

SELECT OEORI_RowId FROM SQLUser.OE_OrdItem 
WHERE OEORI_RowId IN (SELECT  AA_OEORI_DR->OEORI_RowId 
FROM SQLUser.DHC_Doc_AntibioticApply)
SELECT * FROM SQLUser.OE_Order

SELECT * FROM SQLUser.PA_Adm 
WHERE PAADM_ADMNo = "0000000001"

SELECT  AA_OEORI_DR->OEORI_InsertDate AS PA 
FROM SQLUser.DHC_Doc_AntibioticApply 