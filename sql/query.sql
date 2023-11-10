-- @Block
SELECT description,*
From information_schema.columns
where table_name like "PA_adm";
-- 表字段

-- @Block
SELECT * FROM SQLUser.CT_Sex;
--性别

-- @Block
INSERT INTO SQLUser.Student 
VALUES ('1', '2023-01-01', '张', '1');

-- @Block
SELECT TARAC_TARTAC_DR->TARTAC_Desc,* 
FROM SQLUser.DHC_TarAcctCate;
-- 账单费用类别

-- @Block
SELECT * 
FROM SQLUser.PA_PatMas;
--病人信息

-- @Block
SELECT AA_Arcim_DR -> ARCIM_Desc AS apply_count, count(*) 
FROM SQLUser.DHC_Doc_AntibioticApply 
group by AA_Arcim_DR;
-- 特抗药申请

-- @Block
Select * 
FROM SQLUser.CT_Address;
--地址

-- @Block
SELECT * 
from SQLUser.CT_Hospital;
--医院

-- @Block
SELECT * 
FROM SQLUser.ARC_ItmMast 
-- 医嘱项明细

-- @Block
select * from SQLUser.DHC_CardRef;
-- 卡表

-- @Block
SELECT *
FROM SQLUser.OE_OrdItem;
--医嘱明细

-- @Block
SELECT  AA_OEORI_DR->OEORI_OEORD_ParRef->OEORD_Adm_DR->PAADM_PAPMI_DR->PAPMI_No 
        AS PA 
FROM SQLUser.DHC_Doc_AntibioticApply
WHERE AA_OEORI_DR like "%||%";
-- 特抗药申请

-- @Block
SELECT OEORI_RowId 
FROM SQLUser.OE_OrdItem 
WHERE OEORI_RowId like "266%";

-- @Block
SELECT OEORI_RowId 
FROM SQLUser.OE_OrdItem 
WHERE OEORI_RowId IN (
    SELECT  AA_OEORI_DR->OEORI_RowId 
    FROM SQLUser.DHC_Doc_AntibioticApply
);
-- 医嘱 特抗药

-- @Block
SELECT * 
FROM SQLUser.PA_Adm 
WHERE PAADM_ADMNo = "0000000001";
-- 就诊

-- @Block
SELECT  AA_OEORI_DR->OEORI_InsertDate 
        AS PA 
FROM SQLUser.DHC_Doc_AntibioticApply;
-- 特抗药

-- @Block
select * 
from SQLUser.ARC_BillGrp;
-- 医嘱账单组

-- @Block
select AA_Arcim_DR -> ARCIM_Desc 
        AS apply_count, count(*) 
FROM SQLUser.DHC_Doc_AntibioticApply 
group by AA_Arcim_DR;
-- 特抗药

-- @Block
select AA_Arcim_DR -> ARCIM_Desc,* 
FROM SQLUser.DHC_Doc_AntibioticApply 
group by AA_Arcim_DR
-- 特抗药

-- @Block
select PAPMI_ConcessionCardNo ,* 
from SQLUser.PA_PatMas;
-- 病人信息


-- @Block
SELECT OEORI_RowId 
FROM SQLUser.OE_OrdItem 
WHERE OEORI_RowId like "266%"
-- 医嘱明细

-- @Block
SELECT OEORI_RowId 
FROM SQLUser.OE_OrdItem 
WHERE OEORI_RowId IN (
    SELECT  AA_OEORI_DR->OEORI_RowId 
    FROM SQLUser.DHC_Doc_AntibioticApply
);
-- 医嘱明细 特抗药申请

-- @Block
SElECT * 
FROM SQLUser.CT_CareProv

-- @Block
SELECT * 
FROM SQLUser.CT_Loc
-- 科室

-- @Block
SELECT PAADM_PAPMI_DR -> PAPMI_Name,PAADM_AdmDocCodeDR->CTPCP_Desc,PAADM_DepCode_DR->CTLOC_Desc,* 
FROM SQLUser.PA_Adm 
WHERE PAADM_ADMNo = "0000000001";
-- 就诊

-- @Block
SELECT * 
FROM SQLUser.DHC_DocCureAppCureItem;
-- 治疗申请单中治疗项目

-- @Block
SELECT * 
FROM SQLUser.DHC_DocCureRecode;
-- Arrive_DR DCR_ChildSub
-- 治疗记录表(预约记录表子表)

-- @Block
SELECT * 
FROM SQLUser.DHC_DocCureApp;
-- DCA_RowId
-- 治疗记录申请表

-- @Block
SELECT DCA_Adm_DR->PAADM_PAPMI_DR->PAPMI_Name,* 
FROM SQLUser.DHC_DocCureApp;
-- 治疗记录申请表

-- @Block
SELECT PAPMI_No, PAPMI_Name, PAPMI_DOB, PAPMI_Sex_DR->CTSEX_Desc, PAPMI_DVAnumber 
FROM PA_PatMas 
WHERE PAPMI_Name LIKE "陈洪亮%";
-- 病人信息

-- @Block
SELECT * 
FROM PA_Adm
WHERE PAADM_PAPMI_DR = 676;
-- 就诊

-- @Block
SELECT * 
FROM OE_Order
WHERE OEORD_Adm_DR = 1774;
-- 就诊 医嘱

-- @Block
SELECT TOP 40 * 
FROM OE_OrdItem
WHERE OEORI_OEORD_ParRef = 1636;
-- 医嘱明细

-- @Block
SELECT TOP 20 * 
FROM DHC_InvPrt
WHERE PRT_Acount = 1243.29;
-- 发票

-- @Block
SELECT * 
FROM OE_OrdItem
WHERE OEORI_OEORD_ParRef IN
(
	SELECT OEORD_RowId1 FROM OE_Order
	WHERE OEORD_Adm_DR IN
	(
		SELECT PAADM_RowID FROM PA_Adm
		WHERE PAADM_PAPMI_DR = 676
	)
);
--  就诊 医嘱 医嘱明细

-- @Block
SELECT TOP 20 * 
FROM DHC_InvPrt
WHERE PRT_inv = "0001000202";
-- 发票打印

-- @Block
SELECT * 
FROM dhc_patbilldetails
WHERE PBD_PBO_ParRef IN
(
	SELECT PBO_RowId 
	FROM dhc_patbillorder
	WHERE PBO_PB_ParRef IN
	(
		SELECT PB_Rowid 
		FROM dhc_patientbill
		WHERE PB_Adm_DR IN
		(
			SELECT PAADM_Rowid 
			FROM PA_adm
			WHERE PAADM_PAPMI_DR = 846 & PAADM_Type = "I"
		)
	)
);
-- 就诊 账单 账单医嘱 账单明细

-- @Block
SELECT TOP 20 * 
FROM PHC_DrgMast
WHERE PHCD_Code = 4567897654;
-- 药品

-- @Block
SELECT TOP 20 * 
FROM ARC_ItmMast
WHERE ARCIM_Code = 4567897654;
-- 医嘱项

-- @Block
SELECT TOP 20 * 
FROM INC_Itm 
WHERE INCI_Code = 4567897654;
-- Inventory
-- 库存项

-- @Block
SELECT TOP 20 * 
FROM DHC_InIsTrf 
WHERE INIT_No = "TRXYK1282023090802";
-- 库存转移申请单

-- @Block
SELECT TOP 20 * 
FROM DHC_InIsTrfItm
WHERE INITI_INIT_ParRef = 146;
-- 库存转移申请单

-- @Block
SELECT TOP 200 * 
FROM DHC_INTRANS
WHERE INTR_INCI_DR IN
(
	SELECT INCI_RowId FROM INC_Itm 
	WHERE INCI_Code = 4567897654
);
-- 转移记录

-- @Block
select Regfeetemp1
from SQLUser.DHCRegistrationFee
where RegfeeAdmDr in (
	select PAADM_RowID
	from SQLUser.PA_Adm
	where PAADM_PAPMI_DR = 46
) 
	and RegfeeDepDr = RegfeeDepDr
	and RegfeeDate + 3 >= RegfeeDate   
	and RegfeeArcPrice > 0;
-- 挂号 发票 价格

-- @Block
select RegfeeTimeRangeDr
from SQLUser.DHCRegistrationFee
where RegfeeAdmDr = AdmId;
-- 挂号 时段

-- @Block
SELECT TR_RowId
FROM DHC_TimeRange
WHERE TR_ValidEndDate IS NULL
	AND TR_Desc = Desc;
-- 时段

-- @Block
SELECT OEORI_LabEpisodeNo,* 
FROM OE_OrdItem
WHERE OEORI_OEORD_ParRef IN
(
	SELECT OEORD_RowId1 
	FROM OE_Order
	WHERE OEORD_Adm_DR IN
	(
		SELECT PAADM_RowID 
		FROM PA_Adm
		WHERE PAADM_PAPMI_DR = 46
	)
);
-- 就诊 医嘱 检验

-- @Block
SELECT AS_TimeRange_DR ,* 
FROM DHC_RBApptSchedule;
-- 排班 时段

-- @Block
SELECT * 
FROM SqlUser.OEC_Priority;
-- 医嘱类型 自备药长期

-- @Block
select PAADM_DepCode_DR -> ctloc_desc ,count(*) As 总数
From PA_Adm
group by PAADM_DepCode_DR;
select * FROM Ct_loc;
-- 患者 科室 统计
