var PageLogicObj = {
    m_FindPatListTabDataGrid: "",
    dw: $(window).width() - 400,
    dh: $(window).height() - 100,
    m_SessionStr: "^" + session['LOGON.USERID'] + "^" + session['LOGON.CTLOCID'] + "^" + session['LOGON.GROUPID'] + "^" + "^" + session['LOGON.SITECODE'] + "^",
    m_SelectCardTypeRowID: "",
    m_OverWriteFlag: "",
    m_CardCost: "",
    m_CCMRowID: "",
    m_SetFocusElement: "",
    m_CardNoLength: "",
    m_SetRCardFocusElement: "",
    m_SetCardRefFocusElement: "",
    m_SetCardReferFlag: "",
    m_CardINVPrtXMLName: "",
    m_PatPageXMLName: "",
    m_CardTypePrefixNo: "",
    m_UsePANoToCardNO: "",
    m_RegCardConfigXmlData: "",
    m_PAPMINOLength: 10,
    m_PatMasFlag: "",
    m_CardRefFlag: "",
    m_AccManagerFlag: "",
    m_CardSecrityNo: "",
    m_MedicalFlag: 0, //建病历标识
    m_CurSearchValue: "",
    m_tmformat: 'HMS',
    m_IDCredTypePlate: "01", //身份证代码字段
    m_CardValidateCode: "",
    m_CardVerify: "",
    m_ModifiedFlag: "",
    m_ReceiptsType: "",
    m_IsNotStructAddress: "",
    m_CredTypeDef: "",
    m_CredTypeID: "",
    m_TransferCardFlag: 0,
    //已婚
    m_MarriedIDStr: "22^23^24^25^26^27",
    //已婚最低年龄限制(女)
    m_MarriedLimitFemaleFAge: 18,
    //已婚最低年龄限制(男)
    m_MarriedLimitMaleAge: 18,
    m_PrtXMLName: "UDHCAccDeposit",
    JumpAry: ["CardNo", "Name", "Sex", "CredNo", "PatType", "TelHome"],
    m_CardRegMustFillInArr: [],
    m_CardRegJumpSeqArr: [],
    m_CTDTemporaryCardFlag: "",
    m_ShowWindowFlag: "",
    m_AllowNoCardNoFlag:""
}
if (websys_isIE == true) {
    var script = document.createElement('script');
    script.type = 'text/javaScript';
    script.src = '../scripts/dhcdoc/tools/bluebird.min.js'; // bluebird 文件地址
    document.getElementsByTagName('head')[0].appendChild(script);
}
$(function() {
    InitBtnBar();
    //初始化
    Init();
    //事件初始化
    InitEvent();
    //页面元素初始化
    //setTimeout(function (){
    //},50)
})
$(window).load(function() {
    if (ServerObj.CardRefgDOMCache == "") {
        SaveCahce();
    }
    setTimeout(function() {
        ExtendComboxEvent();
        LoadPatInfoByRegNo();
    })
    $("#ComputerIP").val(ClientIPAddress);
    $(window).resize(function() {
        $("#FindPatListTab").datagrid("getPanel").panel('resize', {
            width: $(window).width(),
            height: $(window).width() - 460
        });

    });
});

function Init() {
    PageLogicObj.m_FindPatListTabDataGrid = InitFindPatListTabDataGrid();
}
function InitBtnBar()
{
	$('#btnList').marybtnbar({
        btnCls:'big',
        MethodName:'GetCardRegBtnCfgData',
        onClick:function(jq,cfg){
	        ReadBtnClickHandler(cfg);
        },
        onLoadSuccess:function(data){
            PageHandle();
            //初始化读卡按钮的快捷键
			$(document).off('keydown.btnList').on('keydown.btnList',function(e){
		        if ((e.keyCode<37)||(e.keyCode>135)) return;
		        var keyName=e.key||window.event.code;
		        if (keyName=="") return;
		        if (keyName.indexOf('Digit')==0) keyName=keyName.split('Digit')[1];
		        if (keyName.indexOf('Key')==0) keyName=keyName.split('Key')[1];
		        keyName=keyName.toUpperCase();
		        if (e.shiftKey) keyName='Shift+'+keyName;
		        if (e.ctrlKey) keyName='Ctrl+'+keyName;
		        
		        $.each(data,function(i,obj){
			        if (keyName==obj.shortcut){
				        ReadBtnClickHandler(obj);
		            }
				})
	        });
        }
    });
}

function ReadBtnClickHandler(cfg) {
	var ReadList=$.cm({
        ClassName:"DHCDoc.Reg.RWCard",
        MethodName:"GetCardHardOutData",
        ReadBtnId:cfg.id,
        CardType:"",
        HospitalId:session["LOGON.HOSPID"]
    },false);
    if ((ReadList.HardList.length>0)||(ReadList.OutList.length>0)) {
        var rtn=CardCommon_ControlObj.ReadMagCard({
	        ReadBtnId:cfg.id,
	        CardTypeDR:PageLogicObj.m_SelectCardTypeRowID
        })
        var myary = rtn.split("^");
	    if (myary[0] == '0') {
	        $("#CardNo").val(myary[1]);
	        PageLogicObj.m_CardVerify = myary[2];
	        PageLogicObj.m_CardValidateCode = myary[2];
	        PageLogicObj.m_CardSecrityNo = myary[2];
	        GetValidatePatbyCard();
	    }
    }
}

function InitEvent() {
    $("#PAPMINo").blur(PAPMINoOnblur);
    $("#PAPMINo").keydown(PAPMINoOnKeyDown);
    $("#InMedicare").blur(InMedicareOnBlur);
    $("#Birth").keydown(BirthOnKeyDown);
    $("#BirthTime").blur(BirthTimeOnBlur);
    $("#Name").blur(SearchSamePatient);
    $("#TelHome").blur(TelHomeOnBlur); //SearchSamePatient
    $("#PatYBCode").blur(SearchSamePatient);
    $("#Age").keypress(AgeOnKeypress);
    $("#Age").blur(AgeOnBlur);
    $("#CredNo").change(CredNoOnChange);
    //$("#CredNo").keypress(CredNoOnKeyPress);
    $("#CredNo").blur(SearchSamePatient);
    $("#NewCard").click(NewCardclick);
    $("#BModifyInfo").click(BModifyInfoclick);
    //$("#PatPaySum").keypress(PatPaySumKeyPress);

    $("#BOtherCredType").click(OtherCredTypeInput);
    $("#BAddressInoCollaps").click(BAddressInoCollapsClick);
    $("#BPayInoCollaps").click(BPayInoCollapsClick);
    $("#BBaseInoCollaps").click(BBaseInoCollapsClick);
    $("#EmployeeNo").keydown(EmployeeNoOnKeyDown);
    $("#RealBtn").click(RealBtnClick);
    $("#SelecAll").click(SelecAllClick);
    $("#SelecOther").click(SelecOtherClick);
    $("#OtherName").click(OtherNameclick);
    document.onkeydown = Doc_OnKeyDown;
}

function PageHandle() {
    //卡类型
    LoadCardType();
    //证件类型、联系人证件类型
    //LoadCredType();
    LoadForeignCredType();
    //病人类型
    LoadPatType();
    //学历
    InitEDUCombo()
    //语言
    InitLanguageCombo()
    //结构化默认地址
    InitAddressDefCombo()
    //病人级别
    //LoadPoliticalLevel();
    //病人密级
    //LoadSecretLevel();
    //合同单位
    //LoadHCPDR();
    //民族
    LoadCTNation();
    //关系
    //LoadCTRelation();
    //职业
    //LoadVocation();
    //加载地址类型
    LoadAddrType()
    //性别
    LoadSex();
    //籍贯
    LoadCountry();
    //银行(需在LoadPayMode之前)
    LoadBank();
    //银行卡类型(需在LoadPayMode之前)
    LoadBankCardType();
    //设备类型
    LoadIEType();
    InitOtherCom();
    IntDoc();
    setTimeout(function() {
        //支付方式
        LoadPayMode();
        InitPatRegConfig();
        setTimeout(function() {
            for (var i = 0; i < PageLogicObj.m_CardRegMustFillInArr.length; i++) {
                var id = PageLogicObj.m_CardRegMustFillInArr[i]['id'];
                if (!id) continue;
                $("label[for=" + id + "]").addClass("clsRequired");
            }
        }, 50)
    }, 50);

    if (PageLogicObj.m_UsePANoToCardNO != "Y") {
        DisableBtn("NewCard", true);
    }
}

function InitOtherCom() {
    //婚姻
    LoadMarital();
    //病人级别
    LoadPoliticalLevel();
    //病人密级
    LoadSecretLevel();
    //合同单位
    LoadHCPDR();
    //关系
    LoadCTRelation();
    //职业
    LoadVocation();
}

function LoadCardType() {
    $("#CardTypeDefine").combobox({
        valueField: 'id',
        textField: 'text',
        editable: false,
        blurValidValue: true,
        data: JSON.parse(ServerObj.DefaultCardTypePara),
        onSelect: function(rec) {
            CardTypeKeydownHandler();
        }
    })
    CardTypeKeydownHandler();
}

function LoadCredType() {
    //var CredTypeData = JSON.parse(ServerObj.DefaultCredTypePara);
    //获取卡类型关联的证件类型
    var CredTypeData=$.cm({
        ClassName:"web.UDHCOPOtherLB",
        MethodName:"ReadCredTypeExp",
        JSFunName:"GetCredTypeToHUIJson",
        ListName:"",
        HospId:session["LOGON.HOSPID"], 
        CardTypeID:PageLogicObj.m_SelectCardTypeRowID
    },false);
	$("#CredType").combobox({
		valueField: 'id',
		textField: 'text',
		editable: false,
		blurValidValue: true,
		data: CredTypeData
	})
	for (var i = 0; i < CredTypeData.length; i++) {
		if (CredTypeData[i]['selected'] == true) {
			PageLogicObj.m_CredTypeDef = CredTypeData[i]['id'];
		}
		if (CredTypeData[i]['text'].indexOf("身份证") > -1) {
			PageLogicObj.m_CredTypeID = CredTypeData[i]['id'];
		}
	}
}
function LoadForeignCredType(){
	var CredTypeData = JSON.parse(ServerObj.DefaultCredTypePara);
    $("#ForeignCredType").combobox({
        valueField: 'id',
        textField: 'text',
        editable: false,
        blurValidValue: true,
        data: CredTypeData
    })
    for (var i = 0; i < CredTypeData.length; i++) {
        if (CredTypeData[i]['selected'] == true) {
            PageLogicObj.m_CredTypeDef = CredTypeData[i]['id'];
        }
        if (CredTypeData[i]['text'].indexOf($g("身份证")) > -1) {
            PageLogicObj.m_CredTypeID = CredTypeData[i]['id'];
        }
    }
}
function LoadPatType() {
    $("#PatType").combobox({
        width: 115,
        valueField: 'id',
        textField: 'text',
        //editable:false,
        blurValidValue: true,
        data: JSON.parse(ServerObj.DefaultPatTypePara),
        filter: function(q, row) {
            if (q == "") return true;
            if (row["text"].indexOf(q.toUpperCase()) >= 0) return true;
            var find = 0;
            if ((row["AliasStr"]) && (row["AliasStr"] != "")) {
                for (var i = 0; i < row["AliasStr"].split("^").length; i++) {
                    if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0) {
                        find = 1;
                        break;
                    }
                }
            }
            if (find == 1) return true;
            return false;
        },
        onSelect: function(rec) {
            PatTypeOnChange();
        }
    })
}

function LoadMarital() {
    $("#PAPERMarital").combobox({
        valueField: 'id',
        textField: 'text',
        editable: false,
        blurValidValue: true,
        data: JSON.parse(ServerObj.DefaultMaritalPara)
    })
}

function LoadPoliticalLevel() {
    $("#PoliticalLevel").combobox({
        valueField: 'id',
        textField: 'text',
        editable: true,
        blurValidValue: true,
        data: JSON.parse(ServerObj.DefaultPoliticalLevPara)
    })
}

function LoadSecretLevel() {
    $("#SecretLevel").combobox({
        valueField: 'id',
        textField: 'text',
        editable: true,
        blurValidValue: true,
        data: JSON.parse(ServerObj.DefaultSecretLevelPara)
    })
}

function LoadHCPDR() {
    $("#HCPDR").combobox({
        valueField: 'id',
        textField: 'text',
        editable: true,
        blurValidValue: true,
        data: JSON.parse(ServerObj.DefaultHCPDRPara)
    })
}

function LoadCTNation() {
	/*var json = JSON.parse(ServerObj.DefaultNationPara)
	json.forEach(item => {
    	item.id = item.id.length === 1 ? '0' + item.id : item.id;
	});*/
    var cbox = $HUI.combobox("#NationDescLookUpRowID", {
        width: 115,
        valueField: 'id',
        textField: 'text',
        editable: true,
        blurValidValue: true,
        data: JSON.parse(ServerObj.DefaultNationPara),
        filter: function(q, row) {
            if (q == "") return true;
            if (row["text"].indexOf(q.toUpperCase()) >= 0) return true;
            var find = 0;
            for (var i = 0; i < row["AliasStr"].split("^").length; i++) {
                if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0) {
                    find = 1;
                    break;
                }
            }
            if (find == 1) return true;
            return false;
        }
    });
}

function LoadCTRelation() {
    $("#CTRelationDR").combobox({
        valueField: 'id',
        textField: 'text',
        editable: true,
        blurValidValue: true,
        data: JSON.parse(ServerObj.DefaultRelationPara)
    });
}

function LoadVocation() {
    $("#Vocation").combobox({
        valueField: 'id',
        textField: 'text',
        editable: true,
        blurValidValue: true,
        data: JSON.parse(ServerObj.DefaultOccuptionPara),
        filter: function(q, row) {
            if (q == "") return true;
            if (row["text"].indexOf(q.toUpperCase()) >= 0) return true;
            var find = 0;
            for (var i = 0; i < row["AliasStr"].split("^").length; i++) {
                if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0) {
                    find = 1;
                    break;
                }
            }
            if (find == 1) return true;
            return false;
        }
    });
}

function LoadSex() {
    $HUI.combobox("#Sex", {
        width: 115,
        valueField: 'id',
        textField: 'text',
        blurValidValue: true,
        data: JSON.parse(ServerObj.DefaultSexPara),
        filter: function(q, row) {
            if (q == "") return true;
            var find = 0;
            if (row["text"].indexOf(q.toUpperCase()) >= 0) return true;
            for (var i = 0; i < row["AliasStr"].split("^").length; i++) {
                if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0) {
                    find = 1;
                    break;
                }
            }
            if (find == 1) return true;
            return false;
        },
        onSelect: function(rec) {
            SearchSamePatient();
        }
    })

}

function LoadCountry() {
    var cbox = $HUI.combobox("#CountryDescLookUpRowID,#CountryHome,#CountryBirth,#CountryHouse,#CountryForeign", {
        valueField: 'id',
        textField: 'text',
        editable: true,
        blurValidValue: false,
        //data: JSON.parse(ServerObj.DefaultCTCountryPara),
        filter: function(q, row) {
            if (q == "") return true;
            if (row["text"].indexOf(q.toUpperCase()) >= 0) return true;
            var find = 0;
            for (var i = 0; i < row["AliasStr"].split("^").length; i++) {
                if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0) {
                    find = 1;
                    break;
                }
            }
            if (find == 1) return true;
            return false;
        },
        onSelect: function(rec) {
            if (rec) {
                var id = rec.id //$(this).combobox("getValue");
                if ($(this).combobox("getValue") != id) id = ""
                var Item = $(this)[0].id;
                var tt = Item;
                CountrySelect(Item, id);
            }
        },
        onChange: function(newValue, oldValue) {
            if (newValue == "") {
                var item = $(this)[0].id;

                if (item == "CountryHome") {
                    var provinceId = "ProvinceHome";
                } else if (item == "CountryBirth") {
                    var provinceId = "ProvinceBirth";
                } else if (item == "CountryHouse") {
                    var provinceId = "ProvinceInfoLookUpRowID"; //省现住
                } else if (item == "CountryDescLookUpRowID") {
                    var provinceId = "ProvinceHouse"
                }
                $("#" + provinceId).combobox('select', '');
                (function(item) {
                    setTimeout(function() {
                        $("#" + item).combobox('setValue', "").combobox('setText', "");
                        $($("#" + item).combobox('panel')[0].childNodes).removeClass("combobox-item-selected")
                    })
                })(item)
            } else if ($(this)[0].id == "CountryDescLookUpRowID") {
                DefLanguage(newValue)
            }
        },
        onShowPanel: function() {
            var item = $(this)[0].id;
            LoadCountryData(item);
        }
    });
    $HUI.combobox($("#ProvinceHome,#CityHome,#ProvinceBirth,#CityBirth,#AreaBirth,#ProvinceInfoLookUpRowID,#CityDescLookUpRowID,#CityAreaLookUpRowID,#Cityhouse,#AreaHouse,#StreetBirth,#StreetNow,#StreetHouse,#AreaHome,#AreaForeign,#CityForeign"), { width: 110 });
    $HUI.combobox($("#ProvinceHouse"), {});
}

function LoadCountryData(id) {
    if (typeof id != "undefined") {
        var text = $("#" + id).combobox("getText");
        var data = $("#" + id).combobox("getData");
        $("#" + id).combobox("loadData", JSON.parse(ServerObj.DefaultCTCountryPara)).combobox("setText", text);
    }
}

function CountrySelect(id, value) {
    if (id == "CountryHome") {
        $("#CityHome,#AreaHome").combobox("loadData", []).combobox('setValue', "");
        //$("#CityHome").combobox('select',"");
    } else if (id == "CountryBirth") {
        $("#CityBirth,#AreaBirth").combobox("loadData", []).combobox('setValue', "");
    } else if (id == "CountryHouse") {
        $("#CityDescLookUpRowID,#CityAreaLookUpRowID").combobox("loadData", []).combobox('setValue', "");
    } else if (id == "CountryDescLookUpRowID") {
        $("#Cityhouse,#AreaHouse").combobox("loadData", []).combobox('setValue', "");
    } else if (id == "CountryForeign") {
        $("#CityForeign,#AreaForeign").combobox("loadData", []).combobox('setValue', "");
    }
    LoadProvince(id, value);

}

function LoadPayMode() {
    $("#PayMode").combobox({
        valueField: 'id',
        textField: 'text',
        editable: false,
        blurValidValue: true,
        data: JSON.parse(ServerObj.DefaultPaymodePara),
        onSelect: function(rec) {
            PayModeOnChange();
        },
        onLoadSuccess: function() {
            var Data = $(this).combobox("getData");
            if (Data.length > 0) {
                $(this).combobox("select", Data[0]["id"]);
                PayModeOnChange();
            }
        }
    });
}

function LoadBank() {
    $("#Bank").combobox({
        valueField: 'id',
        textField: 'text',
        editable: false,
        blurValidValue: true,
        data: JSON.parse(ServerObj.DefaultBankPara)
    });
}

function LoadBankCardType() {
    $("#BankCardType").combobox({
        valueField: 'id',
        textField: 'text',
        editable: false,
        blurValidValue: true,
        data: JSON.parse(ServerObj.DefaultBankCardTypePara)
    });
}

function LoadIEType() {
    $("#IEType").combobox({
        valueField: 'HGRowID',
        textField: 'HGDesc',
        editable: false,
        blurValidValue: true,
        data: JSON.parse(ServerObj.DefaultIETypePara),
        onLoadSuccess: function() {
            var Data = $(this).combobox("getData");
            if (Data.length > 0) {
                $(this).combobox("select", Data[0]["HGRowID"]);
            }
        }
    });
}

function LoadProvince(item, CountryId) {
    if (item == "CountryHome") {
        var provinceId = "ProvinceHome";
    } else if (item == "CountryBirth") {
        var provinceId = "ProvinceBirth";
    } else if (item == "CountryHouse") {
        var provinceId = "ProvinceInfoLookUpRowID"; //省现住
    } else if (item == "CountryDescLookUpRowID") {
        var provinceId = "ProvinceHouse"
    } else if (item == "CountryForeign") {
        var provinceId = "ProvinceForeign"
    } else {
        provinceId = item
    }
    if ((ServerObj.defaultCountryDr == CountryId) && (ServerObj.DefaultCTProvince != "")) {
        var Data = ServerObj.DefaultCTProvince
    } else {
        var Data = $.m({
            ClassName: "web.DHCBL.CTBASEIF.ICTCardRegLB",
            MethodName: "ReadBaseData",
            dataType: "text",
            TabName: "CTProvince",
            QueryInfo: CountryId + "^^^HUIJSON^" + provinceId
        }, false);
    }
    var cbox = $HUI.combobox("#" + provinceId, {
        valueField: 'id',
        textField: 'text',
        editable: true,
        blurValidValue: true,
        data: JSON.parse(Data),
        filter: function(q, row) {
            if (q == "") return true;
            if (row["text"].indexOf(q.toUpperCase()) >= 0) return true;
            var find = 0;
            for (var i = 0; i < row["AliasStr"].split("^").length; i++) {
                if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0) {
                    find = 1;
                    break;
                }
            }
            if (find == 1) return true;
            return false;
        },
        onSelect: function(rec) {
            if (rec) {
                //加载市信息
                var id = rec.id; //$(this).combobox("getValue");
                var item = $(this)[0].id;
                if (item == "ProvinceHome") {
                    $("#AreaHome").combobox("loadData", []);
                    $("#AreaHome").combobox('select', "");
                } else if (item == "ProvinceBirth") {
                    $("#AreaBirth").combobox("loadData", []);
                    $("#AreaBirth").combobox('select', "");

                } else if (item == "ProvinceInfoLookUpRowID") {
                    $("#CityAreaLookUpRowID").combobox("loadData", []);
                    $("#CityAreaLookUpRowID").combobox('select', "");

                } else if (item == "ProvinceHouse") { //国籍
                    $("#AreaHouse").combobox("loadData", []);
                    $("#AreaHouse").combobox('select', "");
                }
                LoadCity($(this)[0].id, id);
                var PostCodeId = GetPostCodeId(item)
                $("#" + PostCodeId).val("")
            }
        },
        onChange: function(newValue, oldValue) {
            if (newValue == "") {
                var item = $(this)[0].id;
                if (item == "ProvinceHome") {
                    var cityId = "CityHome";
                } else if (item == "ProvinceBirth") {
                    var cityId = "CityBirth";
                } else if (item == "ProvinceInfoLookUpRowID") {
                    var cityId = "CityDescLookUpRowID";
                } else if (item == "ProvinceHouse") { //国籍
                    var cityId = "Cityhouse"
                }
                $("#" + cityId).combobox('select', '');
            }
        }
    });
    var id = $("#" + provinceId).combobox("getValue");
    if (id != "") {
        LoadCity(provinceId, id);
    }
}

function LoadCity(item, ProvinceId) {
    if (item == "ProvinceHome") {
        var cityId = "CityHome";
    } else if (item == "ProvinceBirth") {
        var cityId = "CityBirth";
    } else if (item == "ProvinceInfoLookUpRowID") {
        var cityId = "CityDescLookUpRowID";
    } else if (item == "ProvinceHouse") { //国籍
        var cityId = "Cityhouse"
    } else if (item == "ProvinceForeign") {
        var cityId = "CityForeign";
    }
    var Data = $.m({
        ClassName: "web.DHCBL.CTBASEIF.ICTCardRegLB",
        MethodName: "ReadBaseData",
        dataType: "text",
        TabName: "CTCITY",
        QueryInfo: ProvinceId + "^^^HUIJSON"
    }, false);
    var cbox = $HUI.combobox("#" + cityId, {
        width: 110,
        valueField: 'id',
        textField: 'text',
        editable: true,
        blurValidValue: true,
        data: JSON.parse(Data),
        filter: function(q, row) {
            if (q == "") return true;
            if (row["text"].indexOf(q.toUpperCase()) >= 0) return true;
            var find = 0;
            for (var i = 0; i < row["AliasStr"].split("^").length; i++) {
                if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0) {
                    find = 1;
                    break;
                }
            }
            if (find == 1) return true;
            return false;
        },
        onSelect: function(rec) {
            if (rec != undefined) {
                //加载县信息
                var id = rec.id; //$(this).combobox("getValue");
                LoadArea($(this)[0].id, id);
                var PostCodeId = GetPostCodeId(item)
                $("#" + PostCodeId).val("")
            }
        },
        onChange: function(newValue, oldValue) {
            if (newValue == "") {
                var item = $(this)[0].id;
                if (item == "CityHome") {
                    var areaId = "AreaHome";
                } else if (item == "CityBirth") {
                    var areaId = "AreaBirth";
                } else if (item == "CityDescLookUpRowID") {
                    var areaId = "CityAreaLookUpRowID";
                } else if (item == "Cityhouse") {
                    var areaId = "AreaHouse"
                }
                if (areaId != "") {
                    $("#" + areaId).combobox('select', '');
                }
            }
        }
    });
    var id = $("#" + cityId).combobox("getValue");
    if (id != "") {
        LoadArea(cityId, id);
    }
}

function LoadArea(item, cityId) {
    if (item == "CityHome") {
        var areaId = "AreaHome";
    } else if (item == "CityBirth") {
        var areaId = "AreaBirth";
    } else if (item == "CityDescLookUpRowID") {
        var areaId = "CityAreaLookUpRowID";
    } else if (item == "Cityhouse") {
        var areaId = "AreaHouse";
    } else if (item == "CityForeign") {
     	var areaId = "AreaForeign";
    }
    var Data = $.m({
        ClassName: "web.DHCBL.CTBASEIF.ICTCardRegLB",
        MethodName: "ReadBaseData",
        dataType: "text",
        TabName: "CTCITYAREA",
        QueryInfo: cityId + "^^^HUIJSON"
    }, false);
    var cbox = $HUI.combobox("#" + areaId, {
        width: 110,
        valueField: 'id',
        textField: 'text',
        editable: true,
        blurValidValue: true,
        data: JSON.parse(Data),
        filter: function(q, row) {
            if (q == "") return true;
            if (row["text"].indexOf(q.toUpperCase()) >= 0) return true;
            var find = 0;
            for (var i = 0; i < row["AliasStr"].split("^").length; i++) {
                if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0) {
                    find = 1;
                    break;
                }
            }
            if (find == 1) return true;
            return false;
        },
        onSelect: function(row) {
            CityAreaSelectHandler(areaId)
            StreetSelectHandler(areaId)
        }
    });
}

function CardTypeKeydownHandler() {
    var myoptval = $("#CardTypeDefine").combobox("getValue");
    var myary = myoptval.split("^");
    var myCardTypeDR = myary[0];
    if (myCardTypeDR == "") {
        return;
    }
    PageLogicObj.m_SelectCardTypeRowID = myCardTypeDR;
    PageLogicObj.m_OverWriteFlag = myary[23];
    $("#CardFareCost,#ReceiptNO,#CardNo,#PatPaySum").val("");
    if (ServerObj.defCardDr == myCardTypeDR) {
        var m_RegCardConfigXmlData = $("#RegCardConfigXmlData").val()
    } else {
        var m_RegCardConfigXmlData = $.m({
            ClassName: "web.DHCBL.CARD.UCardPATRegConfig",
            MethodName: "ReadDefaultCardTypeConfigByDR",
            CardTypeDR: PageLogicObj.m_SelectCardTypeRowID,
            SessionStr: ""
        }, false);
    }
    PageLogicObj.m_RegCardConfigXmlData = m_RegCardConfigXmlData;
    PageLogicObj.m_CardCost = 0;
    if (myary[3] == "C") {
        $("#CardFareCost").val(myary[6]);
        $("#PatPaySum").val(myary[6]);
        PageLogicObj.m_CardCost = myary[6];
        GetReceiptNo();
    }
    if (myary[16] == "Handle") {
        $("#CardNo").attr("disabled", false);
        $("#CardNo").focus();
    } else {
        $("#CardNo").attr("disabled", true);
        $("#BReadCard").focus();
    }
    PageLogicObj.m_CCMRowID = myary[14];
    PageLogicObj.m_SetFocusElement = myary[13];
    if (PageLogicObj.m_SetFocusElement != "") {
        $("#" + PageLogicObj.m_SetFocusElement).focus();
    }
    PageLogicObj.m_CardNoLength = myary[17];
    PageLogicObj.m_SetRCardFocusElement = myary[20];
    PageLogicObj.m_SetCardRefFocusElement = myary[22];
    PageLogicObj.m_SetCardReferFlag = myary[21];
    var myobj = document.getElementById("PAPMINo");
    if (PageLogicObj.m_SetCardReferFlag == "Y") {
        //myobj.onkeydown = PAPMINoOnKeyDown;
        //myobj.readOnly=false;
        $('#PAPMINo').removeAttr("disabled");
    } else {
        myobj.onclick = function() { return false; }
            //myobj.readOnly=true;
        $('#PAPMINo').val('').attr("disabled", true);
    }
    PageLogicObj.m_CardINVPrtXMLName = myary[25];
    PageLogicObj.m_PatPageXMLName = myary[26];
    PageLogicObj.m_CardTypePrefixNo = myary[29];
    //设置使用登记号作为卡号
    if (myary.length >= 37) {
        PageLogicObj.m_UsePANoToCardNO = myary[36];
        PageLogicObj.m_AllowNoCardNoFlag=myary[42];
    }
    if (PageLogicObj.m_UsePANoToCardNO == "Y") {
        $('#btnList').marybtnbar('disable',['BReadCard','BReadInsuCard']);
        $("#CardNo").attr("disabled", true);
        DisableBtn("NewCard", false);
        PageLogicObj.m_CardNoLength = 0;
        $('#Name').focus();
    }
    else {
		DisableBtn("NewCard", true);
	}
    if (PageLogicObj.m_AllowNoCardNoFlag=="Y") {
		DisableBtn("NewCard",false);
	}
    PageLogicObj.m_CTDTemporaryCardFlag = myary[38];
    if ((myary[24] == "N") && (myary[3] == "NP")) {
        //不显示收费信息
        document.getElementById("PayInfo").style.display = "none";
        if (!AddressInfoIsExpand()) BAddressInoCollapsClick();
    } else {
        document.getElementById("PayInfo").style.display = "block";
        if (AddressInfoIsExpand()) BAddressInoCollapsClick();
    }
    //初始化临时卡相关
    InitTemporaryCard($("#CardNo").val());
    //修改卡类型时判断一下患者类型是否收取卡费用
    PatTypeOnChange()
    //加载卡类型关联的证件类型
    LoadCredType()
    //控制读卡按钮是否可用
    CardCommon_ControlObj.CommonFuncs.ControlReadBtnAble({
        id:"btnList",
        CardTypeDR:PageLogicObj.m_SelectCardTypeRowID
    })
}

function ReadCardClickHandle() {
    if ($("#BReadCard").hasClass('l-btn-disabled')) {
        return false;
    }
    var myVersion = ServerObj.ConfigVersion;
    if (myVersion == "12") {
        M1Card_InitPassWord();
    }
    var rtn = DHCACC_ReadMagCard(PageLogicObj.m_CCMRowID, "R", "23");
    var myary = rtn.split("^");
    if (myary[0] == '0') {
        $("#CardNo").val(myary[1]);
        PageLogicObj.m_CardVerify = myary[2];
        PageLogicObj.m_CardValidateCode = myary[2];
        PageLogicObj.m_CardSecrityNo = myary[2];
        GetValidatePatbyCard();
    }
}

function M1Card_InitPassWord() {
    try {
        var myobj = document.getElementById("ClsM1Card");
        if (myobj == null) return;
        var rtn = myobj.M1Card_Init();
    } catch (e) {}
}

function GetReceiptNo() {
    var myPINVFlag = "Y";
    var myExpStr = session['LOGON.USERID'] + "^" + myPINVFlag;
    if (cspRunServerMethod(ServerObj.GetreceipNO, 'SetReceipNO', session['LOGON.USERID'], PageLogicObj.m_SelectCardTypeRowID, myExpStr) != '0') {
        $.messager.alert("提示", t['InvalidReceiptNo']);
        return false;
    }
}

function SetReceipNO(value) {
    var myary = value.split("^");
    var ls_ReceipNo = myary[0];
    $('#ReceiptNO').val(ls_ReceipNo);
    //如果张数小于最小提示额change the Txt Color
    if (myary[1] != "0") {
        $("#ReceiptNO").addClass("newclsInvalid");
    }
}

function PAPMINoOnKeyDown(e) {
    var key = websys_getKey(e);
    if (key == 13) {
        $("#PAPMINo").unbind("blur");
        SetPAPMINoLenth();
        GetPatDetailByPAPMINo();
        setTimeout(function() {
            $("#PAPMINo").blur(PAPMINoOnblur);
        });
        return false;
    }
}

function PAPMINoOnblur() {
    SetPAPMINoLenth();
    GetPatDetailByPAPMINo();
}

function InMedicareOnBlur() {
    var myInMedicare = $("#InMedicare").val();
    if (myInMedicare.split('M').length > 1) {
        $("#InMedicare").val(myInMedicare.split('M')[0]);
    }
    SearchSamePatient();
}

function BirthOnBlur() {
    ///清屏的时候不在处理
    //var Obj=GetEventElementObj()
    //if (Obj.name=="Clear"){return websys_cancel();}
    var mybirth = $("#Birth").val();
    if ((mybirth != "") && ((mybirth.length != 8) && ((mybirth.length != 10)))) {
        $.messager.alert("提示", $g("请输入正确的出生日期!"), "info", function() {
            $("#Birth").addClass("newclsInvalid");
            $("#Birth").focus();
        });
        return false;
    }
    $("#Birth").removeClass("newclsInvalid");
    if ((mybirth.length == 8)) {
        if (ServerObj.dtformat == "YMD") {
            var mybirth = mybirth.substring(0, 4) + "-" + mybirth.substring(4, 6) + "-" + mybirth.substring(6, 8)
        }
        if (ServerObj.dtformat == "DMY") {
            var mybirth = mybirth.substring(6, 8) + "/" + mybirth.substring(4, 6) + "/" + mybirth.substring(0, 4)
        }
        $("#Birth").val(mybirth);
    }
    if (mybirth != "") {
        if (ServerObj.dtformat == "YMD") {
            var reg = /^(([0-9]{3}[1-9]|[0-9]{2}[1-9][0-9]{1}|[0-9]{1}[1-9][0-9]{2}|[1-9][0-9]{3})-(((0[13578]|1[02])-(0[1-9]|[12][0-9]|3[01]))|((0[469]|11)-(0[1-9]|[12][0-9]|30))|(02-(0[1-9]|[1][0-9]|2[0-8]))))|((([0-9]{2})(0[48]|[2468][048]|[13579][26])|((0[48]|[2468][048]|[3579][26])00))-02-29)$/;
        }
        if (ServerObj.dtformat == "DMY") {
            var reg = /^(((0[1-9]|[12][0-9]|3[01])\/((0[13578]|1[02]))|((0[1-9]|[12][0-9]|30)\/(0[469]|11))|(0[1-9]|[1][0-9]|2[0-8])\/(02))\/([0-9]{3}[1-9]|[0-9]{2}[1-9][0-9]{1}|[0-9]{1}[1-9][0-9]{2}|[1-9][0-9]{3}))|(29\/02\/(([0-9]{2})(0[48]|[2468][048]|[13579][26])|((0[48]|[2468][048]|[3579][26])00)))$/;
        }
        var ret = mybirth.match(reg);
        if (ret == null) {
            $.messager.alert("提示", $g("请输入正确的出生日期!"), "info", function() {
                $("#Birth").addClass("newclsInvalid");
                $("#Birth").focus();
            });
            return false;
        }
        if (ServerObj.dtformat == "YMD") {
            var myrtn = DHCWeb_IsDate(mybirth, "-")
        }
        if (ServerObj.dtformat == "DMY") {
            var myrtn = DHCWeb_IsDate(mybirth, "/")
        }
        if (!myrtn) {
            $.messager.alert("提示", $g("请输入正确的出生日期!"), "info", function() {
                $("#Birth").addClass("newclsInvalid");
                $("#Birth").focus();
            });
            return false;
        } else {
            var mybirth1 = $("#Birth").val();
            var Checkrtn = CheckBirth(mybirth1);
            if (Checkrtn == false) {
                $.messager.alert("提示", $g("出生日期不能大于今天或者小于、等于1840年!"), "info", function() {
                    $("#Birth").addClass("newclsInvalid");
                    $("#Birth").focus();
                });
                return false;
            }
            var myAge = DHCWeb_GetAgeFromBirthDay("Birth");
            $("#Age").val(myAge);
            if (!LimitBirthTime()) {
                $("label[for=BirthTime]").addClass("clsRequired");
            } else {
                $("label[for=BirthTime]").removeClass("clsRequired");
            }
            AdjustForeignPhone();
        }
    } else {
        $("#Birth").removeClass("newclsInvalid");
    }
    SearchSamePatient();
    return true;
}

function BirthTimeOnBlur() {
    var mybirthTime = $("#BirthTime").val();
    if (mybirthTime == "") return false;
    if (mybirthTime.length < 6) {
        var AddZeroNum = 6 - mybirthTime.length
        for (var i = 0; i < AddZeroNum; i++) {
            mybirthTime = mybirthTime + "0"
        }
        $("#BirthTime").val(mybirthTime);
    }
    var eSrc = document.getElementById('BirthTime')
    if (!IsValidTime(eSrc)) {
        $.messager.alert("提示", $g("请输入正确的出生时间!"), "info", function() {
            $("#BirthTime").addClass("newclsInvalid");
            $("#BirthTime").focus();
        });
        return false;
    }
    var mybirth = $("#Birth").val();
    if (mybirth == "") return false;
    var myage = $("#Age").val();
    var mybirthTime = $("#BirthTime").val();
    $.cm({
        ClassName: "web.UDHCJFCOMMON",
        MethodName: "DispPatAge",
        dataType: "text",
        birthDate: mybirth,
        admDate: "",
        birthTime: mybirthTime,
        admTime: "",
        controlFlag: "N",
        hospId: session['LOGON.HOSPID']
    }, function(ageStr) {
        var ageStr = ageStr.split("||")[0];
        if (parseInt(ageStr) < 0) {
            $.messager.alert("提示", $g("出生时间不能小于当前时间!"), "info", function() {
                $("#Age").val("");
                $("#BirthTime").addClass("newclsInvalid");
                $("#BirthTime").focus();
            });
        } else {
            $("#Age").val(ageStr);
        }
    });
    $("#BirthTime").removeClass("newclsInvalid");
}

function AgeOnKeypress() {
    try { keycode = websys_getKey(e); } catch (e) { keycode = websys_getKey(); }
    if (keycode == 45) { window.event.keyCode = 0; return websys_cancel(); }
    //过滤"." 年龄计算会错误
    if (keycode == 46) { window.event.keyCode = 0; return websys_cancel(); }
    if (((keycode > 47) && (keycode < 58)) || (keycode == 46)) {} else {
        window.event.keyCode = 0;
        return websys_cancel();
    }
}

function setBirthAndSex(mypId) {
    var myary = DHCWeb_GetInfoFromId(mypId);
    if (myary[0] == "1") {
        var myBirth = $("#Birth").val();
        $("#Birth").val(myary[2]);
        $("#Age").val(myary[4]);
        var mySexDR = "";
        switch ($g(myary[3])) {
            case $g("男"):
                mySexDR = "1";
                break;
            case $g("女"):
                mySexDR = "2";
                break;
            default:
                mySexDR = "4";
                break;
        }
        $("#Sex").combobox("select", mySexDR);
    } else {
        $("#CredNo").focus();
        return false;
    }
}

function AgeOnBlur() {
    var myrtn = IsCredTypeID();
    var mypId = $("#CredNo").val();
    if ((myrtn) && (mypId != "")) {
        var Birth = $("#Birth").val();
        if (Birth == "") {
            setBirthAndSex(mypId);
            AdjustForeignPhone();
        }
        return;
    };
    var myage = $("#Age").val();
    if (myage == "") return;
    if (((myage.indexOf("岁") != -1) || (!isNaN(myage))) && (myage != "")) {
        if (parseInt(myage) >= parseInt(ServerObj.LimitAge)) {
            $.messager.alert("提示", $g("年龄不能超过") + LimitAge + $g("岁"), "info", function() {
                $("#Birth").focus();
                $("#Birth").val("");
            });
            return false;
        }
    }
    //if ((myBirth == "") || (myBirth == undefined)) {
	    var rtn = tkMakeServerCall("web.DHCDocCommon","GetBirthDateByAge",myage,"");
	    if (rtn) {
		    $("#Birth").val(rtn);
		    AdjustForeignPhone();
		}
        /*$.cm({
            ClassName: "web.DHCDocCommon",
            MethodName: "GetBirthDateByAge",
            dataType: "text",
            Age: myage,
            Type: ""
        }, function(rtn) {
            $("#Birth").val(rtn);
            AdjustForeignPhone();
        });*/
    //}
    var mybirth = $("#Birth").val();
    var myage = $("#Age").val();
    var mybirthTime = $("#BirthTime").val();
    var ageStr = $.cm({
        ClassName: "web.UDHCJFCOMMON",
        MethodName: "DispPatAge",
        dataType: "text",
        birthDate: mybirth,
        admDate: "",
        birthTime: mybirthTime,
        admTime: "",
        controlFlag: "N",
        hospId: session['LOGON.HOSPID']
    }, false);
    var ageDesc = ageStr.split("||")[0];
	$("#Age").val(ageDesc);
}

function SetPAPMINoLenth() {
    var PAPMINo = $("#PAPMINo").val();
    if (PAPMINo != '') {
        if ((PAPMINo.length < PageLogicObj.m_PAPMINOLength) && (PageLogicObj.m_PAPMINOLength != 0)) {
            for (var i = (PageLogicObj.m_PAPMINOLength - PAPMINo.length - 1); i >= 0; i--) {
                PAPMINo = "0" + PAPMINo;
            }
        }
        $("#PAPMINo").val(PAPMINo);
    }
}

function GetPatDetailByPAPMINo() {
    $("#PAPMINo").removeClass("newclsInvalid");
    var myPAPMINo = $('#PAPMINo').val();
    if (myPAPMINo != "") {
        var myPatInfo = $.cm({
            ClassName: "web.DHCBL.CARD.UCardPaPatMasInfo",
            MethodName: "GetPatInfoByPANo",
            dataType: "text",
            PAPMINo: myPAPMINo,
            ExpStr: ""
        }, false);
        var myary = myPatInfo.split("^");
        if (myary[0] == "0") {
            //先清除页面信息,对应用于清除匹配的XML获取:##class(web.DHCBL.UDHCUIDefConfig).ReadCardPatUDIef
            InitPatRegConfig();
            var myXMLStr = myary[1];
            var PAPMIXMLStr = GetRegMedicalEPMI("", myPAPMINo);
            if (PAPMIXMLStr != "") myXMLStr = PAPMIXMLStr;
            SetPatInfoByXML(myXMLStr);
            if (PageLogicObj.m_SetCardRefFocusElement != "") {
                $("#" + PageLogicObj.m_SetCardRefFocusElement).focus();
            }
            //加入图片base64应用
            var PhotoInfo = $("#PhotoInfo").val();
            if (PhotoInfo != "") {
                var src = "data:image/png;base64," + PhotoInfo;
            } else {
                var src = "../images/uiimages/patdefault.png";
            }
            ShowPicBySrcNew(src, "imgPic");
            var PAPMIDR = $('#PAPMIRowID').val();
            return true;
        } else if (myary[0] == "2001") {
            $.messager.alert("提示", $g("无此登记号的患者!"));
        } else if (myary[0] == "-353") {
            $.messager.alert("提示", $g("此登记号不能重复建立账户!"));
        } else if (myary[0] == "2002") {
	        $.messager.confirm("提示", $g("该登记号已经被合并无法使用，保留的登记号为") + "<font color=red>" + myary[1]+ "</font>，" + $g("是否自动使用新登记号进行检索？"), function(r) {
                if (r) {
	                $("#PAPMINo").val(myary[1]);
                    GetPatDetailByPAPMINo();
                }
            });
        } else {
            $.messager.alert("提示", "Error Code: " + myary[0]);
        }
        $("#PAPMINo").addClass("newclsInvalid");
        return false;
    }
}

function InitPatRegConfig() {
    /*var myvalue=$.cm({
    	ClassName:"web.DHCBL.CARD.UCardPATRegConfig",
    	MethodName:"GetCardPatRegConfig",
    	dataType:"text",
    	SessionStr:""
    },false);*/
    var myvalue = ServerObj.DefaultCardPatRegConfigPara;
    if (myvalue == "") {
        return;
    }
    var myRtnAry = myvalue.split(String.fromCharCode(2))
    var myary = myRtnAry[0].split("^");
    var mySetFocusElement = myary[2];
    PageLogicObj.m_IsNotStructAddress = myary[17];
    if (PageLogicObj.m_IsNotStructAddress == "Y") {
        InitAddressCombo();
    }
    if (mySetFocusElement != "") {
        PageLogicObj.m_SetFocusElement = mySetFocusElement;
    }
    PageLogicObj.m_PatMasFlag = myary[3];
    PageLogicObj.m_CardRefFlag = myary[4];
    PageLogicObj.m_AccManagerFlag = myary[5];
    //SetPatInfoByXML(myRtnAry[1]);
    SetPatInfoByXML(ServerObj.CardPatUIDefStr);
    if (mySetFocusElement != "") {
        $("#" + mySetFocusElement).focus();
    }
    PageLogicObj.m_CardSecrityNo = "";
    PageLogicObj.m_CardRegMustFillInArr = JSON.parse(myary[19]);
    PageLogicObj.m_CardRegJumpSeqArr = JSON.parse(myary[20]);
}

function SetPatInfoByXML(XMLStr, CheckFlag, getMessageByIdCard) {
    XMLStr = "<?xml version='1.0' encoding='gb2312'?>" + XMLStr
    var AddressObj = {
        AdrDesc: {
            Country: '',
            Province: '',
            City: '',
            Area: '',
            Street: ''
        },
        AdrHouse: {
            Country: '',
            Province: '',
            City: '',
            Area: '',
            Street: ''
        },
        AdrBirth: {
            Country: '',
            Province: '',
            City: '',
            Area: '',
            Street: ''
        },
        AdrHome: {
            Country: '',
            Province: '',
            City: '',
            Area: '',
            Street: ''
        },
        AdrForeign: {
            Country: '',
            Province: '',
            City: '',
            Area: '',
            Street: ''
        }
    };
    oldPersonMessage = [];
    if (typeof getMessageByIdCard != "undefined") {
        oldPersonMessageFromIDCard = {};
    }
    var AddressBirth=""
    /*var xmlDoc = DHCDOM_CreateXMLDOM();
    xmlDoc.async = false;
    xmlDoc.loadXML(XMLStr);*/
    var xmlDoc = DHCDOM_CreateXMLDOMNew(XMLStr);
    if (!xmlDoc) return;
    var nodes = xmlDoc.documentElement.childNodes;
    if (nodes.length <= 0) { return; }
    var PostArr = []
    for (var i = 0; i < nodes.length; i++) {
        //var myItemName = nodes(i).nodeName;
        //var myItemValue = nodes(i).text;
        var myItemName = getNodeName(nodes, i);
        var myItemValue = getNodeValue(nodes, i);
        if (myItemName == 'NationDescLookUpRowID') {
	        if (myItemValue.startsWith('0')) {
	            myItemValue = myItemValue.replace('0','');
	    	}
	    }
        if ((myItemName == "OtherCardInfo") && (myItemValue != "")) {
            myItemValue = myItemValue.replace(/@/g, "^");
        }
        if ((myItemName == "OtherNameInfo") && (myItemValue != "")) {
            myItemValue = myItemValue.replace(/@/g, "^");
        }
        var _$id = $("#" + myItemName);
        if (_$id.length > 0) {
            //if (_$id.hasClass("hisui-combobox")){
            if (_$id.next().hasClass('combo')) {
                if (typeof getMessageByIdCard != "undefined") {
                    if (myItemName == "PatType") {
                        oldPersonMessageFromIDCard.PatType = myItemValue
                    }
                } else {
                    //地址信息有加载顺序问题,所以先记录,后处理
                    if (myItemName == "CountryHouse") { //国(现住)
                        AddressObj.AdrDesc.Country = myItemValue;
                    } else if (myItemName == "ProvinceInfoLookUpRowID") { //省(现住)
                        AddressObj.AdrDesc.Province = myItemValue;
                    } else if (myItemName == "CityDescLookUpRowID") { //市(现住)
                        AddressObj.AdrDesc.City = myItemValue;
                    } else if (myItemName == "CityAreaLookUpRowID") { //CTArea 县(现住)
                        AddressObj.AdrDesc.Area = myItemValue;
                    } else if (myItemName == "CountryDescLookUpRowID") { //国籍
                        AddressObj.AdrHouse.Country = myItemValue;
                    } else if (myItemName == "ProvinceHouse") { //省(户口)
                        AddressObj.AdrHouse.Province = myItemValue;
                    } else if (myItemName == "Cityhouse") { //市(户口)
                        AddressObj.AdrHouse.City = myItemValue;
                    } else if (myItemName == "AreaHouse") { //县(户口)
                        AddressObj.AdrHouse.Area = myItemValue;
                    } else if (myItemName == "CountryBirth") { //国(出生)
                        AddressObj.AdrBirth.Country = myItemValue;
                    } else if (myItemName == "ProvinceBirth") { //省(出生)
                        AddressObj.AdrBirth.Province = myItemValue;
                    } else if (myItemName == "CityBirth") { //市(出生)
                        AddressObj.AdrBirth.City = myItemValue;
                    } else if (myItemName == "AreaBirth") { //县(出生)
                        AddressObj.AdrBirth.Area = myItemValue;
                    } else if (myItemName == "CountryHome") {
                        AddressObj.AdrHome.Country = myItemValue;
                    } else if (myItemName == "ProvinceHome") {
                        AddressObj.AdrHome.Province = myItemValue;
                    } else if (myItemName == "CityHome") {
                        AddressObj.AdrHome.City = myItemValue;
                    } else if (myItemName == "AreaHome") {
                        AddressObj.AdrHome.Area = myItemValue;
                    } else if (myItemName == "StreetBirth") {
                        AddressObj.AdrBirth.Street = myItemValue;
                    } else if (myItemName == "StreetHouse") {
                        AddressObj.AdrHouse.Street = myItemValue;
                    } else if (myItemName == "StreetNow") {
                        AddressObj.AdrDesc.Street = myItemValue;
                    } else if (myItemName == "CountryForeign") {
                        AddressObj.AdrForeign.Country = myItemValue;
                    } else if (myItemName == "ProvinceForeign") {
                        AddressObj.AdrForeign.Province = myItemValue;
                    } else if (myItemName == "CityForeign") {
                        AddressObj.AdrForeign.City = myItemValue;
                    } else if (myItemName == "AreaForeign") {
                        AddressObj.AdrForeign.Area = myItemValue;
                    } else if (myItemName == "StreetForeign") {
                        AddressObj.AdrForeign.Street = myItemValue;
                    } else {
	                    if (myItemName == "AddressBirth"){
		                    AddressBirth=myItemValue
		                }
                        if ((myItemName == "CardTypeDefine") || (myItemName == "PayMode") || (myItemName == "CredType") || (myItemName == "ForeignCredType")) {
                            if (myItemName == "ForeignCredType") {}
                            var Data = _$id.combobox("getData");
                            for (var m = 0; m < Data.length; m++) {
                                var id = Data[m]["id"];
                                if (myItemValue == id.split("^")[0]) {
                                    _$id.combobox("select", id);
                                    break;
                                }
                            }
                        } else if (myItemName == "IEType") {
                            if (myItemValue != "") {
                                _$id.combobox("select", myItemValue);
                            }
                        } else if ((PageLogicObj.m_IsNotStructAddress == "Y") && ((myItemName == "Address") || (myItemName == "RegisterPlace"))) {
		                        _$id.combobox("setValue", myItemValue);
		                        _$id.combobox("setText", myItemValue);
		                 }else {
	       
                            //tanjishan 20200605防止无法触发onselect事件
                            if ((_$id.combo("getValues") == myItemValue) && (myItemValue != "")) {
                                _$id.combobox("setValues", "");
                            }
                            _$id.combobox("select", myItemValue);
							//一般id是不会和描述重复，如果重复combobox直接select空
							//如果有重复的可以修改此处
                            if (_$id.combobox("getText") == myItemValue){
	                            _$id.combobox("select", "");
	                        }
                        }
                    }
                }
            } else {
                if (typeof getMessageByIdCard != "undefined") {
                    if (myItemName == "InMedicare") {
                        oldPersonMessageFromIDCard.InMedicare = myItemValue
                    }
                    if (myItemName == "Name") {
                        oldPersonMessageFromIDCard.Name = myItemValue
                    }
                    if (myItemName == "CredNo") {
                        oldPersonMessageFromIDCard.CredNo = myItemValue
                    }
                } else {
                    if ((PageLogicObj.m_IsNotStructAddress == "Y") && ((myItemName == "Address") || (myItemName == "RegisterPlace"))) {
                        _$id.combobox("setText", myItemValue);
                    } else {
                        //把邮编号码存储到数据PostArr中 防止修改地址信息清空邮编
                        if (myItemName.indexOf("PostCode") != -1) {
                            var PostObj = {}
                            PostObj["ItemName"] = myItemName
                            PostObj["ItemValue"] = myItemValue
                            PostArr.unshift(PostObj)
                            if (myItemValue == "") {
                                _$id.val(myItemValue);
                            }
                        } else {
                            _$id.val(myItemValue);
                        }
                        //_$id.val(myItemValue);
                    }
                }
                if ((myItemName == "InMedicare") && (myItemValue != "")) {
                    $("#InMedicare").attr("disabled", true);
                } else if ((myItemName == "InMedicare") && (myItemValue == "") && (PageLogicObj.m_MedicalFlag == 1)) {
                    $("#InMedicare").attr("disabled", false);
                }
            }
        }
    }
    delete(xmlDoc);
    //地址字段联动(国家,省份,城市)
    for (var Item in AddressObj) {
        if (Item === "AdrDesc") {
            SetCountryComboxData("CountryHouse", AddressObj[Item].Country);
            CountrySelect("CountryHouse", AddressObj[Item].Country);
            //$("#CountryHouse").combobox("select",AddressObj[Item].Country);
            $("#ProvinceInfoLookUpRowID").combobox("select", AddressObj[Item].Province);
            $("#CityDescLookUpRowID").combobox("select", AddressObj[Item].City);
            $("#CityAreaLookUpRowID").combobox("select", AddressObj[Item].Area);
            $("#StreetNow").combobox("select", AddressObj[Item].Street);
        } else if (Item === "AdrHouse") {
            SetCountryComboxData("CountryDescLookUpRowID", AddressObj[Item].Country);
            CountrySelect("CountryDescLookUpRowID", AddressObj[Item].Country);
            //$("#CountryDescLookUpRowID").combobox("select",AddressObj[Item].Country);
            $("#ProvinceHouse").combobox("select", AddressObj[Item].Province);
            $("#Cityhouse").combobox("select", AddressObj[Item].City);
            $("#AreaHouse").combobox("select", AddressObj[Item].Area);
            $("#StreetHouse").combobox("select", AddressObj[Item].Street);
        } else if (Item === "AdrBirth") {
            SetCountryComboxData("CountryBirth", AddressObj[Item].Country);
            CountrySelect("CountryBirth", AddressObj[Item].Country);
            //$("#CountryBirth").combobox("select",AddressObj[Item].Country);
            $("#ProvinceBirth").combobox("select", AddressObj[Item].Province);
            $("#CityBirth").combobox("select", AddressObj[Item].City);
            $("#AreaBirth").combobox("select", AddressObj[Item].Area);
            $("#StreetBirth").combobox("select", AddressObj[Item].Street);
        } else if (Item === "AdrHome") {
            SetCountryComboxData("CountryHome", AddressObj[Item].Country);
            CountrySelect("CountryHome", AddressObj[Item].Country);
            //$("#CountryHome").combobox("select",AddressObj[Item].Country);
            $("#ProvinceHome").combobox("select", AddressObj[Item].Province);
            $("#CityHome").combobox("select", AddressObj[Item].City);
            $("#AreaHome").combobox("select", AddressObj[Item].Area);
		} else if (Item === "AdrForeign") {
            SetCountryComboxData("CountryForeign", AddressObj[Item].Country);
            CountrySelect("CountryForeign", AddressObj[Item].Country);
            $("#ProvinceForeign").combobox("select", AddressObj[Item].Province);
            $("#CityForeign").combobox("select", AddressObj[Item].City);
            $("#AreaForeign").combobox("select", AddressObj[Item].Area);
            //$("#StreetForeign").combobox("select", AddressObj[Item].Street);
        }
    }
    //给邮编号码赋值
    setTimeout(function() {
        for (var i = 0; i < PostArr.length; i++) {
            var PostObj = PostArr[i]
            if (PostObj["ItemValue"] == "") continue;
            $("#" + PostObj["ItemName"]).val(PostObj["ItemValue"]);
        }
        $("#AddressBirth").combobox("setText", AddressBirth)
    }, 300);
    if (typeof getMessageByIdCard != "undefined") {
        return;
    }
    oldPersonMessage.push($("#Name").val(), $("#CredNo").val(), $("#InMedicare").val(), $("#PatType").combobox("getText"));
    if (typeof CheckFlag != "undefined") {
        //读证件建卡时，姓名、出生日期、证件号、民族、性别信息不能修改，以读出信息为准。
        $("#Name,#Birth,#CredNo").attr("disabled", true);
        $('#NationDescLookUpRowID,#Sex').combobox('disable');
    } else {
        $("#Name,#Birth,#CredNo").attr("disabled", false);
        $('#NationDescLookUpRowID,#Sex').combobox('enable');
    }
}
///判断是否要使用APP患者录入的建大病历的暂存信息,如果使用则输出XML，调用SetPatInfoByXML方法完成页面赋值
///支持传入病人Rowid 或 病人登记号，传一个即可
function GetRegMedicalEPMI(PAPMIRowID, PAPMINo) {
    if ((PAPMIRowID == "") && (PAPMINo == "")) return "";
    var ret = $.m({
        ClassName: "web.DHCBL.CARD.UCardPaPatMasInfo",
        MethodName: "IsNeedRegMedicalEPMI",
        PAPMIRowID: PAPMIRowID,
        PAPMINo: PAPMINo
    }, false);
    if (ret.split('^')[0] == "1") {
        var PAPMINo = ret.split('^')[1];
        var conFlag = confirm("患者没有病案号且已经在手机APP上注册了大病历信息,是否载入？");
        if (conFlag) {
            var ExpStr = "^1"
            var PAPMIXMLStr = $.m({
                ClassName: "web.DHCBL.CARD.UCardPaPatMasInfo",
                MethodName: "GetPatInfoByPANo",
                PAPMINo: PAPMINo,
                ExpStr: "^1"
            }, false);
            if (PAPMIXMLStr.split('^')[0] == "0") return PAPMIXMLStr.split('^')[1];
        }
    }
    return "";
}

function SearchSamePatient() {
    setTimeout(function() {
        var name = "",
            sex = "",
            birth = "",
            CredNo = "";
        PatYBCode = "";
        var name = $('#Name').val();
        var sex = $("#Sex").combobox("getValue");
        var birth = $('#Birth').val();
        var CredNo = $("#CredNo").val();
        var myval = $("#CredType").combobox("getValue");
        var myary = myval.split("^");
        var CredTypeID = myary[0];
        if (CredNo == "") CredTypeID = "";
        var PatYBCode = $("#PatYBCode").val();
        var InMedicare = $("#InMedicare").val();
        var TelHome = $("#TelHome").val()
        if (name == "" && ((CredNo == "") && (PatYBCode == "") && (InMedicare == "") && (TelHome == ""))) return false;
        var Age = $("#Age").val();
        var PAPMINo = $("#PAPMINo").val()
        var ArgValue = name + "^" + birth + "^" + CredNo + "^" + sex + "^" + Age + "^" + PatYBCode + "^" + InMedicare + "^" + TelHome + "^" + CredTypeID;
        if (PageLogicObj.m_CurSearchValue == ArgValue) return false;
        PageLogicObj.m_CurSearchValue = ArgValue;
        name = DHCC_CharTransAsc(name);
        $.cm({
            ClassName: "web.DHCPATCardUnite",
            QueryName: "PatientCardQuery",
            Name: name,
            CredNo: CredNo,
            BirthDay: birth,
            Sex: sex,
            UserID: "",
            TPAGCNTX: "",
            PatYBCode: PatYBCode,
            Age: Age,
            InMedicare: InMedicare,
            CredTypeID: CredTypeID,
            TelHome: TelHome,
            PAPMINo: PAPMINo,
            Pagerows: $("#FindPatListTab").datagrid("options").pageSize,
            rows: 99999
        }, function(GridData) {
            PageLogicObj.m_FindPatListTabDataGrid.datagrid({ loadFilter: pagerFilter }).datagrid('loadData', GridData);
        });
    }, 500)
}

function InitFindPatListTabDataGrid() {
    var Columns = [
        [
            { field: 'TPatientID', hidden: true, title: '' },
            {
                field: 'Goto',
                title: '操作',
                width: 45,
                formatter: function(value, row, index) {
                    return '<a><img style="cursor:pointer;margin-left:10px" src="../scripts_lib/hisui-0.1.0/dist/css/icons/back.png" border="0" onmouseover="ShowGotoDetail(this)" onclick="BackRegWindow(\'' + row["TPatientID"] + '\',\'' +  row["RegNo"]  + '\')"></a>';
                }
            },
            { field: 'Name', title: '姓名', width: 100 },
            {
                field: 'CardNO',
                title: '卡号',
                width: 200,
                formatter: function(value, row, index) {
                    value = value.replace("\\u", " ")
                    return '<a class="" style="color:black"  id= "' + row["CardNO"] + '"onmouseover="ShowCardDescDetail(this)">' + value + '</a>';
                    //return value.replace("\\u"," ")
                }
            },
            { field: 'Sex', title: '性别', width: 50 },
            { field: 'Birthday', title: '出生日期', width: 140 },
            { field: 'CredTypeDesc', title: '证件类型', width: 100 },
            { field: 'CredNo', title: '证件号码', width: 150 },
            { field: 'RegNo', title: '登记号', width: 120 },
            { field: 'PatType', title: '患者类型', width: 90 },
            { field: 'Telphone', title: '电话', width: 100 },
            { field: 'NewInMedicare', title: '病历号', width: 90 },
            { field: 'Company', title: '单位', width: 150 },
            { field: 'Adress', title: '地址(现住)', width: 150 },
            { field: 'ContactPerson', title: '联系人', width: 90 },
            { field: 'PatYBCode', title: '医保卡号', width: 90 },
            { field: 'MobPhone', title: '手机', width: 100 },
            { field: 'myOtherStr', title: '', hidden: true },
            { field: 'EmployeeNo', title: '', hidden: true },
            { field: 'IDCardNo', title: '', hidden: true },
            { field: 'CardID', title: '', hidden: true },
            { field: 'TCreateDate', title: '', hidden: true },
            { field: 'TCreateUser', title: '', hidden: true },
            { field: 'OtherCardNo', title: '', hidden: true }
        ]
    ]

    var FindPatListTabDataGrid = $("#FindPatListTab").datagrid({
        fit: true,
        border: false,
        striped: true,
        singleSelect: true,
        fitColumns: false,
        autoRowHeight: false,
        rownumbers: true,
        pagination: true,
        rownumbers: true,
        pageSize: 20,
        pageList: [20, 100, 200],
        idField: 'CardID',
        //toolbar:toobar,
        columns: Columns,
        onDblClickRow: function(index, row) {
            CardSearchDBClickHander(row);
        },
        onBeforeLoad: function() {
            return false;
        }
    });
    FindPatListTabDataGrid.datagrid('loadData', { total: 0, rows: [] });
    return FindPatListTabDataGrid;
}

function pagerFilter(data) {
    if (typeof data.length == 'number' && typeof data.splice == 'function') { // is array
        data = {
            total: data.length,
            rows: data
        }
    }
    var dg = $(this);
    var opts = dg.datagrid('options');
    var pager = dg.datagrid('getPager');
    pager.pagination({
        showRefresh: false,
        onSelectPage: function(pageNum, pageSize) {
            opts.pageNumber = pageNum;
            opts.pageSize = pageSize;
            pager.pagination('refresh', {
                pageNumber: pageNum,
                pageSize: pageSize
            });
            dg.datagrid('loadData', data);
            dg.datagrid('scrollTo', 0); //滚动到指定的行        
        }
    });
    if (!data.originalRows) {
        data.originalRows = (data.rows);
    }
    if (opts.pageNumber == 0) { opts.pageNumber = 1 }
    if (opts.pagination) {
        var start = (opts.pageNumber - 1) * parseInt(opts.pageSize);
        if ((start + 1) > data.originalRows.length) {
            //取现有行数最近的整页起始值
            start = Math.floor((data.originalRows.length - 1) / opts.pageSize) * opts.pageSize;
            opts.pageNumber = (start / opts.pageSize) + 1;
        }
        var end = start + parseInt(opts.pageSize);
        data.rows = (data.originalRows.slice(start, end));
    }
    if (data.rows) {
        for (var i = 0; i < data.rows.length; i++) {
            var myOtherStr = data.rows[i].myOtherStr;
            data.rows[i].Sex = myOtherStr.split("^")[4];
            data.rows[i].Birthday = myOtherStr.split("^")[1];
            data.rows[i].RegNo = myOtherStr.split("^")[6];
            data.rows[i].PatType = myOtherStr.split("^")[5];
            data.rows[i].Telphone = myOtherStr.split("^")[0];
            data.rows[i].TPatType = myOtherStr.split("^")[5];
            data.rows[i].NewInMedicare = myOtherStr.split("^")[7];
            data.rows[i].Company = myOtherStr.split("^")[3];
            data.rows[i].Adress = myOtherStr.split("^")[2];
            data.rows[i].ContactPerson = myOtherStr.split("^")[13];
            data.rows[i].PatYBCode = myOtherStr.split("^")[16];
            data.rows[i].MobPhone = myOtherStr.split("^")[17];
        }
    }
    return data;
}

function CheckBirth(Birth) {
    var Year, Mon, Day, Str;
    if (ServerObj.dtformat == "YMD") {
        Str = Birth.split("-")
        Year = Str[0];
        Mon = Str[1];
        Day = Str[2];
    }
    if (ServerObj.dtformat == "DMY") {
        Str = Birth.split("/")
        Year = Str[2];
        Mon = Str[1];
        Day = Str[0];
    }

    var Today, ToYear, ToMon, ToDay;
    Today = new Date();
    ToYear = Today.getFullYear();
    ToMon = (Today.getMonth() + 1);
    ToDay = Today.getDate();
    if ((Year > ToYear) || (Year <= 1840)) {
        return false;
    } else if ((Year == ToYear) && (Mon > ToMon)) {
        return false;
    } else if ((Year == ToYear) && (Mon == ToMon) && (Day > ToDay)) {
        return false;
    } else {
        return true;
    }
}

function IsValidTime(fld) {
    var TIMER = 0;
    var tm = fld.value;
    var re = /^(\s)+/;
    tm = tm.replace(re, '');
    var re = /(\s)+$/;
    tm = tm.replace(re, '');
    var re = /(\s){2,}/g;
    tm = tm.replace(re, ' ');
    tm = tm.toUpperCase();
    var x = tm.indexOf(' AM');
    if (x == -1) x = tm.indexOf(' PM');
    if (x != -1) tm = tm.substring(0, x) + tm.substr(x + 1);
    if (tm == '') { fld.value = ''; return 1; }
    re = /[^0-9A-Za-z]/g;
    tm = tm.replace(re, ':');
    if (isNaN(tm.charAt(0))) return ConvNTime(fld);
    if ((tm.indexOf(':') == -1) && (tm.length > 2)) tm = ConvertNoDelimTime(tm);
    symIdx = tm.indexOf('PM');
    if (symIdx == -1) {
        symIdx = tm.indexOf('AM');
        if (symIdx != -1) {
            if (tm.slice(symIdx) != 'AM') return 0;
            else {
                tm = tm.slice(0, symIdx);
                TIMER = 1;
            }
        }
    } else {
        if (tm.slice(symIdx) != 'PM') return 0;
        else {
            tm = tm.slice(0, symIdx);
            TIMER = 2;
        }
    }
    if (tm == '') return 0;
    var tmArr = tm.split(':');
    var len = tmArr.length;
    if (len > 3) return 0;
    for (i = 0; i < len; i++) {
        if (tmArr[i] == '') return 0;
    }
    var hr = tmArr[0];
    var mn = tmArr[1];
    var sc = tmArr[2];
    if (len == 1) {
        mn = 0;
        sc = 0;
    } else if (len == 2) {
        if (mn.length != 2) return 0;
        sc = 0;
    } else if (len == 3) {
        if (mn.length != 2) return 0;
        if (sc.length != 2) return 0;
    }
    if ((hr > 12) && (TIMER == 1)) return 0;
    if ((hr == 12) && (TIMER == 1)) hr = 0;
    if (isNaN(hr) || isNaN(mn) || isNaN(sc)) return 0;
    hr = parseInt(hr, 10);
    mn = parseInt(mn, 10);
    sc = parseInt(sc, 10);
    if ((hr > 23) || (hr < 0) || (mn > 59) || (mn < 0) || (sc > 59) || (sc < 0)) return 0;
    if ((hr < 12) && (TIMER == 2)) hr += 12;
    fld.value = ReWriteTime(hr, mn, sc);
    websys_returnEvent();
    return 1;
}

function ConvertNoDelimTime(tm) {
    if (isNaN(tm)) return tm;
    var hr = tm.slice(0, 2);
    var mn = tm.slice(2, 4);
    var s = tm.slice(4);
    var tmconv = hr + ':' + mn + ':' + s;
    return tmconv
}

function ReWriteTime(h, m, s) {
    var newtime = '';
    if (h < 10) h = '0' + h;
    if (m < 10) m = '0' + m;
    if (s < 10) s = '0' + s;
    if (PageLogicObj.m_tmformat == 'HMS') { newtime = h + ':' + m + ':' + s; }
    if (PageLogicObj.m_tmformat == 'HM') { newtime = h + ':' + m; }
    return newtime;
}

function ConvNTime(fld) {
    var now = new Date();
    var tm = fld.value;
    var re = /(\s)+/g;
    tm = tm.replace(re, '');
    if (tm.charAt(0).toUpperCase() == 'N') {
        xmin = tm.slice(2);
        if (xmin == '') xmin = 0;
        if (isNaN(xmin)) return 0;
        xmin_ms = xmin * 60 * 1000;
        if (tm.charAt(1) == '+') now.setTime(now.getTime() + xmin_ms);
        else if (tm.charAt(1) == '-') now.setTime(now.getTime() - xmin_ms);
        else if (tm.length > 1) return 0;
        fld.value = ReWriteTime(now.getHours(), now.getMinutes(), now.getSeconds());
        websys_returnEvent();
        return 1;
    }
    return 0;
}

function PayModeOnChange() {
    var myoptval = $("#PayMode").combobox("getValue");
    var myary = myoptval.split("^");
    if (myary[2] == "Y") {
        SetPayInfoStatus(false);
    } else {
        SetPayInfoStatus(true);
    }
}

function SetPayInfoStatus(SFlag) {
    $("#ChequeDate").dateboxq('setValue', '');
    $("#PayCompany,#CardChequeNo,#PayAccNo").attr("disabled", SFlag).val(""); //#ChequeDate
    if (SFlag) {
        $('#Bank,#BankCardType').combobox('select', '').combobox('disable');
        //$("#ChequeDate").dateboxq('disable');
    } else {
        $('#Bank,#BankCardType').combobox('select', '').combobox('enable');
        //$("#ChequeDate").dateboxq('enable');
    }
    //Remark
}

function myformatter(date) {
    var y = date.getFullYear();
    var m = date.getMonth() + 1;
    var d = date.getDate();
    if (ServerObj.sysDateFormat == "3") return y + '-' + (m < 10 ? ('0' + m) : m) + '-' + (d < 10 ? ('0' + d) : d);
    else if (ServerObj.sysDateFormat == "4") return (d < 10 ? ('0' + d) : d) + "/" + (m < 10 ? ('0' + m) : m) + "/" + y
    else return y + '-' + (m < 10 ? ('0' + m) : m) + '-' + (d < 10 ? ('0' + d) : d);
}

function myparser(s) {
    if (!s) return new Date();
    if (ServerObj.sysDateFormat == "4") {
        var ss = s.split('/');
        var y = parseInt(ss[2], 10);
        var m = parseInt(ss[1], 10);
        var d = parseInt(ss[0], 10);
    } else {
        var ss = s.split('-');
        var y = parseInt(ss[0], 10);
        var m = parseInt(ss[1], 10);
        var d = parseInt(ss[2], 10);
    }
    if (!isNaN(y) && !isNaN(m) && !isNaN(d)) {
        return new Date(y, m - 1, d);
    } else {
        return new Date();
    }
}

function CredNoOnChange() {
    var myrtn = IsCredTypeID();
    var CredNo = $("#CredNo").val();
    if (myrtn) {
        $("#IDCardNo1").val(CredNo);
        //若是身份证则默认国(籍贯)
        if ($("#CountryHome").combobox('getData').length == 0) {
            LoadCountryData("CountryHome");
        }
        $("#CountryHome").combobox('select', 1)
    }
    if (!myrtn) {
        $("#IDCardNo1").val("");
    }
}

function IsCredTypeID() {
    var myval = $("#CredType").combobox("getValue");
    var myary = myval.split("^");
    if (myary[1] == PageLogicObj.m_IDCredTypePlate) {
        return true;
    } else {
        return false;
    }
}

function ForeignIDCardOnKeyPress() {
    var myval = $("#ForeignCredType").combobox("getValue");
    var myary = myval.split("^");
	var mypId = $("#ForeignIDCard").val();
	mypId = mypId.toUpperCase();
	var ret=CheckCredNoValid(mypId,myary[0])
	if (ret!=0){
		$.messager.alert("提示", $g("联系人")+ ret , "info", function() {
			//$("#CredNo").focus();
		});
		return false;
	}
    if (myary[1] == PageLogicObj.m_IDCredTypePlate) {
        
        $("#ForeignIDCard").val(mypId);
        if (mypId != "") {
            var myary = DHCWeb_GetInfoFromId(mypId);
            if (myary[0] == "1") {
                return true;
            } else {
                $("#ForeignIDCard").focus();
                return false;
            }
        }
    }
	
	
    return true
}

function CredNoOnKeyPress() {
    var winEvent = window.event;
    var mykey = winEvent.keyCode;
    if (mykey == 13) {
        //var myrtn=IsCredTypeID();
        //if (myrtn){
        var mypId = $("#CredNo").val();
        mypId = mypId.toUpperCase();
        var myval = $("#CredType").combobox("getValue");
        var myCredTypeDR = myval.split("^")[0];
        var RtnStr = $.cm({
            ClassName: "web.DHCRBAppointment",
            MethodName: "GetAppedCommomInfo",
            dataType: "text",
            CredNo: mypId,
            CredTypeDR: myCredTypeDR
        }, false);
        var FindAppFlag = RtnStr.split("^")[0];
        if (FindAppFlag == "1") {
            var LastAppedInfo = RtnStr.split("^")[1];
            var LastAppendName = LastAppedInfo.split("$")[0];
            var LastAppenTelH = LastAppedInfo.split("$")[1];
            var DifferenceAppInfo = RtnStr.split("^")[2];
            if (DifferenceAppInfo != "") {
                $.messager.confirm($g('确认对话框'), $g("此证件号存在以下有效的公共卡预约预留信息") + ":<br/>" + $g("姓名:") + LastAppendName + "  " + $g("电话:") + LastAppenTelH + "(" + $g("最后一次预留信息") + ")<br/>" + DifferenceAppInfo + "<br/>" + $g("是否取最后一次的预留信息?"), function(r) {
                    if (r) {
                        $("#Name").val(LastAppendName);
                        $("#TelHome").val(LastAppenTelH);
                    }
                });
            } else {
                $.messager.confirm($g('确认对话框'), $g("此证件号存在有效的公共卡预约预留信息") + ":<br/>" + $g("姓名:") + LastAppendName + "  " + $g("电话:") + LastAppenTelH + "<br/>" + $g("是否带入预约预留信息?"), function(r) {
                    if (r) {
                        $("#Name").val(LastAppendName);
                        $("#TelHome").val(LastAppenTelH);
                    }
                });
            }
        }
        if (IsCredTypeID()) {
            $("#CredNo").val(mypId);
            if (mypId != "") {
                setBirthAndSex(mypId);
            }
            //若是身份证则默认国(籍贯)
            if ($("#CountryHome").combobox('getData').length == 0) {
                LoadCountryData("CountryHome");
            }
            $("#CountryHome").combobox('select', 1);
        }
        //}
        CredNoOnChange();
        var myIDNo = $("#IDCardNo1").val();
        var myval = $("#CredType").combobox("getValue");
        var myCredTypeDR = myval.split("^")[0];
        var myCredNo = $("#CredNo").val();
        if (myval.split("^")[1] == PageLogicObj.m_IDCredTypePlate) {
            BuildAddressByIDCard(myCredNo);
        }
        var myval = $("#CardTypeDefine").combobox("getValue");
        var myCardTypeDR = myval.split("^")[0];
        var myValidateMode = myval.split("^")[30];
        if (myValidateMode == "IDU") {
            if ((myIDNo != "") || (myCredNo != "")) {
                var myInfo = $.cm({
                    ClassName: "web.DHCBL.CARD.UCardPATRegConfig",
                    MethodName: "ReadConfigByIDU",
                    dataType: "text",
                    IDNo: myIDNo,
                    CredTypeDR: myCredTypeDR,
                    CredNo: myCredNo,
                    CardTypeDR: myCardTypeDR
                }, false);
                var myary = myInfo.split(String.fromCharCode(1));
                switch (myary[0]) {
                    case "0":
                        break;
                    case "-368":
                        PageLogicObj.m_RegCardConfigXmlData = myary[1];
                        var myPatInfoXmlData = myary[2];
                        var myRepairFlag = myary[3];
                        // myRepairFlag 为卡类型配置的"数据类型转换验证",用于控制被赋值的元素是否可再编辑
                        if (myRepairFlag == "Y") {
                            SetPatInfoModeByXML(myPatInfoXmlData, false);
                        } else {
                            SetPatInfoModeByXML(myPatInfoXmlData, false);
                        }
                        GetPatDetailByPAPMINo();
                        SetPatRegCardDefaultConfigValue(myary[4]);
                        break;
                    case "-365":
                        $.messager.alert('提示', '此证件号码已经存在,请办理其他卡或办理补卡!');
                        SearchSamePatient();
                        break;
                    default:
                        $.messager.alert('提示', "" + " Err Code=" + myary[0]);
                        break;
                }

            }
        }
    }
}

function SetPatInfoModeByXML(XMLStr, Mode) {
    XMLStr = "<?xml version='1.0' encoding='gb2312'?>" + XMLStr
        /*var xmlDoc=DHCDOM_CreateXMLDOM();
        xmlDoc.async = false;
        xmlDoc.loadXML(XMLStr);
        if(xmlDoc.parseError.errorCode != 0) { 
        	alert(xmlDoc.parseError.reason); 
        	return; 
        }
        */
    var xmlDoc = DHCDOM_CreateXMLDOMNew(XMLStr);
    
    if (!xmlDoc) return;
    var nodes = xmlDoc.documentElement.childNodes;
    if (nodes.length <= 0) { return; }
    for (var i = 0; i < nodes.length; i++) {
        //var myItemName=nodes(i).nodeName;
        //var myItemValue= nodes(i).text;
        var myItemName = getNodeName(nodes, i);
        var myItemValue = getNodeValue(nodes, i);
        if ((myItemName == "OtherCardInfo") && (myItemValue != "")) {
            myItemValue = myItemValue.replace(/@/g, "^");
        }
        if ((myItemName == "OtherNameInfo") && (myItemValue != "")) {
            myItemValue = myItemValue.replace(/@/g, "^");
            alert(myItemValue)
        }
        var _$id = $("#" + myItemName);
        if (_$id.length > 0) {
            //if (_$id.hasClass("hisui-combobox")){
            if (_$id.next().hasClass('combo')) {
                if (Mode) {
                    $('#NationDescLookUpRowID').combobox('disable');
                } else {
                    $('#NationDescLookUpRowID').combobox('enable');
                }
                _$id.combobox("select", myItemValue);
            } else {
                _$id.attr("disabled", Mode);
                _$id.val(myItemValue);
            }
        }
    }
    delete(xmlDoc);
    //关联建卡使用登记号作为卡号，验证卡号的有效性
    CheckForUsePANoToCardNO("New");
}
//验证使用登记号作有没有为卡号时候登记号作为卡号有没有被使用
function CheckForUsePANoToCardNO(Type) {
    var PAPMINO = $("#PAPMINo").val();
    if (PageLogicObj.m_UsePANoToCardNO == "Y") {
        if (PAPMINO != "") {
            //$("#CardNo").val(PAPMINO);
            var myPAPMIStr = $.cm({
                ClassName: "web.DHCBL.CARD.UCardRefInfo",
                MethodName: "GetPAPMIInfoByCardNo",
                dataType: "text",
                CardNo: PAPMINO,
                CardType: PageLogicObj.m_SelectCardTypeRowID
            }, false);
            if (myPAPMIStr != "") {
                if (Type == "New") {
                    $.messager.alert('提示', "该登记号已经作为卡号存在,不能再次使用建卡!", "info", function() {
                        $("#CardNo").val("");
                    });
                }
                DisableBtn("NewCard", true);
            } else {
                DisableBtn("NewCard", false);
            }
        } else {
            DisableBtn("NewCard", false);
        }

    }
}

function SetPatRegCardDefaultConfigValue(Value) {
    var myary = Value.split("^");
    PageLogicObj.m_PatMasFlag = myary[1];
    PageLogicObj.m_CardRefFlag = myary[2];
    PageLogicObj.m_AccManagerFlag = myary[3];
    PageLogicObj.m_SetCardReferFlag = myary[4];
}

function Clearclick() {
    SetUIDefaultValue();
    $(".newclsInvalid").removeClass("newclsInvalid");
    $("#PatYBCode,#ChequeDate,#PatPaySum,#OtherCardInfo,#OtherNameInfo").val("");
    $("#PAPERMarital,#Bank,#BankCardType,#PAPMILangPrimDR,#PAPMILangSecondDR,#Education,#AddressDef").combobox('select', '');
    if (PageLogicObj.m_UsePANoToCardNO != "Y") {
        DisableBtn("NewCard", true);
    }
    PageLogicObj.m_CurSearchValue = "";
    $("#CredType,#ForeignCredType").combobox('select', PageLogicObj.m_CredTypeDef);
    if (PageLogicObj.m_IsNotStructAddress == "Y") {
        $("#Address").combobox('setText', "");
    } else {
        $("#Address").val("");
    }
    //重新加载地址类型
    LoadAddrType()
    DefLanguage("")
    setTimeout(function() {
        PageLogicObj.m_FindPatListTabDataGrid.datagrid('loadData', { total: 0, rows: [] });
    }, 500);
    PageLogicObj.m_FindPatListTabDataGrid.datagrid('clearChecked')
}

function SetUIDefaultValue() {
    InitPatRegConfig();
    $("#OpMedicare,#InMedicare").attr("disabled", true);
    IDReadControlDisable(false);
    CardTypeKeydownHandler();
    var src = "../images/uiimages/patdefault.png";
    ShowPicBySrcNew(src, "imgPic");
}

function IDReadControlDisable(bFlag) {
    $("#CredNo,#Name,#Birth,#Age").attr("disabled", bFlag);
    if (bFlag) {
        $('#Sex,#NationDescLookUpRowID').combobox('disable');
    } else {
        $('#Sex,#NationDescLookUpRowID').combobox('enable');
    }
    //地址 有结构化地址 todo
    //var myobj=document.getElementById("Address");
}

function GetValidatePatbyCard() {
    var myCardNo = $("#CardNo").val();
    if (myCardNo == "") {
        $.messager.alert('提示', "卡号不能为空!");
        return false;
    }
    var rtn = $.m({
        ClassName: "web.DHCBL.CARDIF.ICardRefInfo",
        MethodName: "ReadPatValidateInfoByCardNo",
        CardNO: myCardNo,
        SecurityNo: PageLogicObj.m_CardVerify,
        CardTypeDR: PageLogicObj.m_SelectCardTypeRowID,
        ExpStr: ""
    }, false);
    var myary = rtn.split("^");
    if (rtn == "") return;
    ///gyt 要加电子健康卡获取信息
	if ((PageLogicObj.m_SelectCardTypeRowID==31)&&(myary[0]=='0')){  
		var rtn=$.m({
			ClassName:"DHCDoc.Interface.Outside.TZWYHealthCard.Methods",
			MethodName:"GetHealthCardInfoByCardNo",
			CardNo:myCardNo,
		},false);
		var myary=rtn.split("^");
	}
	
    if (myary[0] == '0') {
        //InitPatRegConfig();
        $("#CardNo").val(myCardNo);
        var myXMLStr = myary[1];
        SetPatInfoByXML(myXMLStr);
        DisableBtn("NewCard", false);
        if (PageLogicObj.m_SetRCardFocusElement != "") {
            $("#" + PageLogicObj.m_SetRCardFocusElement).focus();
        }
    } else {
        switch (myary[0]) {
            case "-341": //已经建卡
                //经过讨论如果已经建卡的不带出已有信息
                var CardNo = $("#CardNo").val();
                var myPAPMIStr = $.m({
                    ClassName: "web.DHCBL.CARD.UCardRefInfo",
                    MethodName: "GetPAPMIInfoByCardNo",
                    CardNo: myCardNo,
                    CardType: PageLogicObj.m_SelectCardTypeRowID
                }, false);
                if (myPAPMIStr==""){
					if (PageLogicObj.m_MedicalFlag == 1) {
					    var flag = ValidateRegInfoByCQU(myary[2]);
					    if (flag) {
					        DisableBtn("NewCard", false);
					        return true;
					    }
					}
	                return ;
                }
                var CheckMsg=$.messager.confirm('提示', '此卡号已经存在,不能发卡,是否带入患者信息?', function(r) {
	                if (r){
		                if (myPAPMIStr != "") {
		                    $("#PAPMINo").val(myPAPMIStr.split("^")[1]);
		                    $("#PAPMIRowID").val(myPAPMIStr.split("^")[0]);
		                    var IsTemporaryCard = InitTemporaryCard(CardNo);
		                    if (IsTemporaryCard == "Y") {
		                        $.messager.alert('提示', "此卡为临时卡!");
		                        GetPatDetailByPAPMINo();
		                        SearchSamePatient();
		                        return;
		                    } else {
		                        $("#CardNo").val("");
		                        GetPatDetailByPAPMINo();
		                        SearchSamePatient();
		                    }
		                }
		                //CardTypeKeydownHandler();
		                if (PageLogicObj.m_MedicalFlag == 1) {
		                    var flag = ValidateRegInfoByCQU(myary[2]);
		                    if (flag) {
		                        DisableBtn("NewCard", false);
		                        return true;
		                    }
		                }
	                }
                }).children("div.messager-button");
                setTimeout(function() {
                    CheckMsg.children("a:eq(0)").focus()
                })
                break;
            case "-340":
                $.messager.alert('提示', "此卡没有对应的病人信息!");
                break;
            case "-350":
                $.messager.alert('提示', "此卡已经使用,不能重复发卡!");
                break;
            case "-351":
                var CancelInfo = $.cm({
                    ClassName: "web.UDHCAccManageCLS7",
                    MethodName: "GetCancenlInfo",
                    dataType: "text",
                    cardno: myCardNo,
                    CardTypeDR: PageLogicObj.m_SelectCardTypeRowID
                }, false);
                $.messager.alert('提示', "此卡已经被挂失,不能使用,挂失人:" + CancelInfo.split("^")[0] + ",挂失原因:" + CancelInfo.split("^")[1]);
                break;
            case "-352":
                $.messager.alert('提示', "此卡已经被作废,不能使用!");
                break;
            case "-356":
                $.messager.alert('提示', "发卡时,配置要求新增卡记录,但是此卡数据被预先生成错误!");
                break;
            case "-357":
                $.messager.alert('提示', "发卡时,配置要求更新卡记录,但是此卡数据没有预先生成!");
                break;
            case "-358":
                $.messager.alert('提示', "发卡时,此卡已经有对应的登记号了,不能再新增!");
                break;
            default:
                $.messager.alert('提示', "Error Code:" + myary[0]);
                break;
        }
        DisableBtn("NewCard", true);
    }
}

function DisableBtn(id, disabled) {
    if (disabled) {
        $HUI.linkbutton("#" + id).disable();
    } else {
        $HUI.linkbutton("#" + id).enable();
    }
}

function ReadRegInfoOnClick() {
    var myHCTypeDR = $("#IEType").combobox("getValue");
    //var myInfo = DHCWCOM_PersonInfoRead(myHCTypeDR);
    var myInfo = CardCommon_ControlObj.ReadPersonInfo({HCTypeDR:myHCTypeDR});
    var myary = myInfo.split("^");
    if (myary[0] == "0") {
        /* SetPatInfoByXML(myary[1]);
        var CredNo = $("#CredNo").val();
        $("#IDCardNo1").val(CredNo);
        //SetIDCredType();
        IDReadControlDisable(true);
        if ($("#CountryHome").combobox('getData').length == 0) {
            LoadCountryData("CountryHome");
        }
        $("#CountryHome").combobox('select', 1)
        BirthOnBlur();
        var myval = $("#CredType").combobox("getValue");
        var myCredTypeDR = myval.split("^")[0];
        if (myval.split("^")[1] == PageLogicObj.m_IDCredTypePlate) {
            BuildAddressByIDCard(CredNo);
        } */
        SetPatInfo(myary[1]);
        IDReadControlDisable(true);
        //如果读取信息时直接默认卡号,此处需要增加校验
        CheckRegCardNo(myary[1]);
    }
    //使用读取得照片数据文件
    var PhotoInfo = $("#PhotoInfo").val();
    if (PhotoInfo != "") {
        var src = "data:image/png;base64," + PhotoInfo;
    } else {
        var src = 'c://' + $("#CredNo").val() + ".bmp"
            //此处的src需要看具体项目生成的路径
        var PhotoInfo = "";
        var myrtn = ImageToBase64.ImgToBase64(src);
        if (typeof myrtn == 'object') { PhotoInfo = myrtn.rtn; }
        $("#PhotoInfo").val(PhotoInfo);
        src = "data:image/bmp;base64," + PhotoInfo;
    }
    ShowPicBySrcNew(src, "imgPic");
}
function SetPatInfo(PatInfoXML) {
    SetPatInfoByXML(PatInfoXML);
    var CredNo = $("#CredNo").val();
    $("#IDCardNo1").val(CredNo);
    //SetIDCredType();
    if ($("#CountryHome").combobox('getData').length == 0) {
        LoadCountryData("CountryHome");
    }
    $("#CountryHome").combobox('select', 1)
    BirthOnBlur();
    var myval = $("#CredType").combobox("getValue");
    var myCredTypeDR = myval.split("^")[0];
    if (myval.split("^")[1] == PageLogicObj.m_IDCredTypePlate) {
        BuildAddressByIDCard(CredNo);
    }
}
function NewCardclick() {
    if ($("#NewCard").hasClass('l-btn-disabled')) {
        return false;
    }
    SaveDataToServer();
    return;
}

function BModifyInfoclick() {
    var PAPMIRowID = $("#PAPMIRowID").val();
    if (PAPMIRowID == "") {
        $.messager.alert("提示", "请先选择病人记录,再更新!");
        return false;
    }
    PageLogicObj.m_MedicalFlag = 1;
    PageLogicObj.m_ModifiedFlag = 1;
    //患者证件类型为身份证时，验证身份证号是否已经存在患者信息，如果存在则不能更新
    var myExpstr = "";
    var myIDrtn = IsCredTypeID();
    if (myIDrtn) {
        var CredNo = $("#CredNo").val();
        if (CredNo != "") {
            myExpstr = CredNo;
        }
    }
    var myPAPMINo = $('#PAPMINo').val();
    if (myExpstr != "") {
        var myPatInfo = $.cm({
            ClassName: "web.DHCBL.CARD.UCardPaPatMasInfo",
            MethodName: "GetPatInfoByPANo",
            dataType: "text",
            PAPMINo: "",
            ExpStr: myExpstr
        }, false);
        var myary = myPatInfo.split("^");
        if (myary[0] == "0") {
            var myXMLStr = myary[1];
            var PAPMIRowID = $("#PAPMIRowID").val();
            var PatientID = myXMLStr.split("<PAPMIRowID>")[1].split("</PAPMIRowID>")[0];
            if ((PatientID != "") && (PatientID != PAPMIRowID)) {
                $.messager.alert("提示", "此身份证已经被使用!", "info", function() {
                    $("#CredNo").focus();
                })
                return false;
            }
        }
    }
    SaveDataToServer();
    PageLogicObj.m_MedicalFlag = 0;
    PageLogicObj.m_ModifiedFlag = 0;
}

function checkPatYBCode() {
    var PatYBCode = $('#PatYBCode').val();
    var myPatType = $("#PatType").combobox("getValue");
    myPatType = CheckComboxSelData("PatType", myPatType);
    if ((myPatType == "") || (myPatType == undefined)) {
        $.messager.alert("提示", "请选择病人类型！", "info", function() {
            $('#PatType').next('span').find('input').focus();
        });
        return false;
    }
    var PatypeDrArray = myPatType.split("^");
    var PatypeDr = PatypeDrArray[0];
    var rtn = $.cm({
        ClassName: "web.DHCBL.CARD.UCardRefInfo",
        MethodName: "GetInsurFlag",
        dataType: "text",
        PatypeDr: PatypeDr
    }, false);
    if ((rtn == 0) && (PatYBCode != "")) {
        $.messager.alert("提示", "非医保病人,医保卡号不可填!", "info", function() {
            $("#PatYBCode").focus();
        })
        return false;
    }
    /*if ((rtn != 0) && (PatYBCode == "")) {
        $.messager.alert("提示", "医保病人,请填写正确的医保卡号", "info", function() {
            $("#PatYBCode").focus();
        })
        return false;
    }*/
    return true;
}

function SaveDataToServer() {
    //根据配置来验证 界面数据是否完整 ,这个需要单独来写
    //配置需要传递到 Cache端的数据串
    //调用Cache函数
    //分别调用打印程序
    //1.如果卡需要收费, 是否打印发票,或者打印小条(热敏条)
    //2.如果有预交金是否需要打印小条;
    //3.根据卡类型是否打印条形码
    if (!CheckData()) {
        return false;
    }
    DisableBtn("NewCard", true);
    ///配置需要传递到 Cache端的数据串
    var myPatInfo = GetPatMasInfo();
    var myCardInfo = GetCardRefInfo();
    var myCardInvInfo = GetCardINVInfo();
    var myAccInfo = GetAccManagerInfo();
    var myAccDepInfo = GetPreDepositeInfo();
    var mySecrityNo = "";
    //如果是修改病人基本信息不再设置写卡。
    if ((PageLogicObj.m_MedicalFlag != "1") && (PageLogicObj.m_UsePANoToCardNO != "Y")) {
        if (PageLogicObj.m_CardRefFlag == "Y") {
            if (PageLogicObj.m_OverWriteFlag == "Y") {
                ///设置写卡
                var myrtn = WrtCard();
                var myary = myrtn.split("^");
                if (myary[0] != "0") {
                    DisableBtn("NewCard", false);
                    return false;
                }
                var mySecrityNo = myary[1];
            } else {
                var mySecrityNo = PageLogicObj.m_CardSecrityNo;
            }
        }
    }
    var Password = "000000";
    if (PageLogicObj.m_AccManagerFlag == "Y") {
        var myDefaultPWDFlag = $("#SetDefaultPassword").checkbox('getValue');
        //标版目前没有校验账户密码的功能，此处暂时屏蔽，后续有业务需求的话再统一改造
        /*if (myDefaultPWDFlag) {
            var ren = DHCACC_GetValidatePWD(Password);
            var myary = ren.split("^");
            if (myary[0] == '0') {
                Password = myary[1];
            } else {
                $.messager.alert("提示", "设置密码失败!");
                DisableBtn("NewCard", false);
                return false;
            }
        } else {
            var ren = DHCACC_SetAccPWD();
            var myary = ren.split("^");
            if (myary[0] == '0') {
                Password = myary[1];
            } else {
                $.messager.alert("提示", "设置密码失败!");
                DisableBtn("NewCard", false);
                return false;
            }
        }*/
    }
    //因为使用promise，故全局变量在此先记录
    var DataObj = {};
    DataObj.m_ModifiedFlag = PageLogicObj.m_ModifiedFlag;
    DataObj.m_MedicalFlag = PageLogicObj.m_MedicalFlag;
    DataObj.m_TransferCardFlag = PageLogicObj.m_TransferCardFlag;

    new Promise(function(resolve, rejected) {
        var CardNo = $("#CardNo").val();
        var PayModeStr = $("#PayMode").combobox("getValue");
        if (PayModeStr == "") {
            $.messager.alert("提示", "请选择支付方式!", "info", function() {
                $('#PayMode').next('span').find('input').focus();
            });
            return false;
        }
        var PayModeId = PayModeStr.split("^")[0];
		var PatPaySum=$("#PatPaySum").val();
		var PatPaySum=parseFloat(PatPaySum)             //转化正数字类型
		if ((PatPaySum>0)&&(PatPaySum!="")&&(DataObj.m_MedicalFlag!="1")){
            //第三方交易接口部署
			RegPayObj.RegPay(PatPaySum,"",PayModeId,"","","","","","","","CARD",resolve)
        } else {
            resolve(true);
        }
    }).then(function(rtnPay) {
		if (!rtnPay) {
			DisableBtn("NewCard",false);
			return false;
		}
		var ETPRowID=""
		if (typeof RegPayObj.PayRtnJsonObj.ETPRowID!="undefined"){
			ETPRowID=RegPayObj.PayRtnJsonObj.ETPRowID;
		}
        return new Promise(function(resolve, rejected) {
            var myConfigInfo = PageLogicObj.m_RegCardConfigXmlData;
            var mySpecInfo = mySecrityNo;
            mySpecInfo += "^" + Password;
            var myExpStr = DataObj.m_MedicalFlag + "^" + PageLogicObj.m_UsePANoToCardNO + "^" + session['LOGON.HOSPID'] + "^" + DataObj.m_TransferCardFlag;
            myExpStr = myExpStr + "^" + "";
			myExpStr=myExpStr+"^"+ETPRowID;
            var rtn = $.cm({
                ClassName: "web.DHCBL.CARDIF.ICardRefInfo",
                MethodName: "SavePCAInfoToServer",
                dataType: "text",
                ConfigInfo: myConfigInfo,
                PaPatInfo: myPatInfo,
                CardInfo: myCardInfo,
                AccInfo: myAccInfo,
                DepositInfo: myAccDepInfo,
                CardINVInfo: myCardInvInfo,
                SepcialInfo: mySpecInfo,
                ExpStr: myExpStr
            }, false);
            var myary = rtn.split(String.fromCharCode(1));
            if (myary[0] == '0') {
                //第三方交易接口信息关联 现在后台关联如果未关联成功核实一下ETPRowID是否传入
                //RegPayObj.Relation(myary[1], "CARD");
                //对外接口调用(电子发票)
				if (typeof Common_ControlObj == "object") {
					var argObj={
						CardINVRowId:myary[1],
                        AccPreRowId:myary[2],
                        PatientID:myary[4],
                        CardRefRowId:myary[5],
					}
					Common_ControlObj.AfterUpdate("Interface",argObj);
				}
                //更新照片
                var PhotoInfo = $("#PhotoInfo").val();
                if (PhotoInfo != "") {
                    $.cm({
                        ClassName: "web.DHCBL.CARD.UCardPaPatMasInfo",
                        MethodName: "SavePhoto",
                        dataType: "text",
                        RegNo: PageLogicObj.m_MedicalFlag == 1 ? myary[3].split("^")[0] : myary[6],
                        PhotoInfo: PhotoInfo
                    }, false);
                }
                ////根据配置设置打印
                ////发卡时收费票据打印的RowID
                if (myary[1] != "") {
                    var myCardCost = $("#CardFareCost").val();
                    var myCardCost = parseFloat(myCardCost) //转化正数字类型
                    if ((myCardCost > 0) && (myCardCost != "")) {
                        PatRegPatInfoPrint(myary[1], PageLogicObj.m_CardINVPrtXMLName, "ReadCardINVEncrypt");
                    }
                }
                ////预交金RowID
                var myAmtValue = $("#amt").val();
                if ((myAmtValue > 0) && (myary[2] != "")) {
                    //Add Version Contral
                    var myVersion = ServerObj.ConfigVersion;
                    switch (myVersion) {
                        case "1":
                            var mystr = rtn + "^";
                            Print_Click(mystr);
                            break;
                        default:
                            PatRegPatInfoPrint(myary[2], PageLogicObj.m_PrtXMLName, "ReadAccDPEncrypt");
                    }
                }
                ////打印条形码等
                if (myary[3] != "") {}
                ///打印首页
                if (myary[4] != "") {
                    PatRegPatInfoPrint(myary[4], PageLogicObj.m_PatPageXMLName, "ReadFirstPageEncrypt");
                }
                if (DataObj.m_ModifiedFlag == 1) {
                    $.messager.alert("提示", "信息修改成功!");
                    PageLogicObj.m_CurSearchValue = "";
                    SearchSamePatient();
                    //调用回调函数
                    resolve();
                    //return;
                } else if (DataObj.m_MedicalFlag == 1) {
                    $.messager.alert("提示", "建病历成功!");
                    //调用回调函数
                    resolve();
                    //return;
                } else {
                    $.messager.alert("提示", "建卡成功!", "info", function() {
                        //使用后台返回的卡号和登记号处理界面值，如果是登记号作为卡号的打印登记号
                        var CardNo = $("#CardNo").val();
                        if (CardNo == "") {
                            $("#CardNo").val(myary[7]);
                        }
                        var PAPMINo = $("#PAPMINo").val();
                        if (PAPMINo == "") {
                            $("#PAPMINo").val(myary[6]);
                        }
                        if (PageLogicObj.m_UsePANoToCardNO == "Y") {
                            PatInfoPrint("PAPMINo");
                        }
						var argObj = { CardTypeDR: PageLogicObj.m_SelectCardTypeRowID, CardNo: myary[7], PatientID: myary[4] };
                        CardCommon_ControlObj.PrintCardInfo(argObj);
			
                        if ((window.parent) && (window.parent.SetPassCardNo)) {
                            if (PageLogicObj.m_UsePANoToCardNO == "Y") {
                                window.parent.SetPassCardNo(myary[6]);
                            } else {
                                window.parent.SetPassCardNo(CardNo);
                            }
                            window.parent.destroyDialog("CardReg");
                            //调用回调函数
                            resolve();
                            //return;
                        }
                        Clearclick();
                        DisableBtn("NewCard", false);
                    });
                    //调用回调函数
                    resolve(true);
                }
            } else {
                //lxz 第三方支付交易接口退回
                RegPayObj.ErrCard();
                var errmsg = GetErrMsg(myary[0]);
				//单次充值上限判断由于返回-1通过返回的描述提示
                if ((typeof myary[2]!="undefined")&&(myary[2]!="")&&(errmsg == "")) {
	            	errmsg=myary[2];    
	            }
                if (errmsg == "") errmsg = "Error Code: " + myary[0] + "  保存数据失败!";
                $.messager.alert("提示", errmsg);
                DisableBtn("NewCard", false);
                return false
            }
        })
    })
}

function CardNokeydown(e) {
    var key = websys_getKey(e);
    if (key == 13) {        
        var argObj = { CardTypeDR: PageLogicObj.m_SelectCardTypeRowID, CardNo: $("#CardNo").val() };
        var myInfo = CardCommon_ControlObj.ReadPersonInfo(argObj);
        if (myInfo.split("^")[0] == "0") {
            SetPatInfo(myInfo.split("^")[1]);
        }
        var CardNo =  $("#CardNo").val();
        if (PageLogicObj.m_SelectCardTypeRowID == '31') {
	    	 CardNo = CardNo.split(':')[0];
	    	 $("#CardNo").val(CardNo);
	    }
        if (!SetCardNOLength()) return false;
    }
}

function PatPaySumKeyPress(e) {
    var key = event.keyCode;
    if (key == 13) {
        var PatPaySum = $("#PatPaySum").val();
        var CardFareCost = $("#CardFareCost").val()
        $("#amt").val(DHCCalCom(PatPaySum, CardFareCost, "-"));
        var myChange = $("#amt");
        if ((isNaN(myChange)) || (myChange == "")) {
            myChange = 0;
        }
        myChange = parseFloat(myChange);
        if (myChange < 0) {
            $.messager.alert("提示", "输入费用金额错误!", "info", function() {
                $("#PatPaySum").focus();
            })
        }
    }
}

function DHCCalCom(value1, value2, caloption) {
    var mynum1 = parseFloat(value1);
    if (isNaN(mynum1)) { var mynum1 = 0; }
    var mynum2 = parseFloat(value2);
    if (isNaN(mynum2)) { mynum2 = 0; }
    switch (caloption) {
        case "-":
            var myres = mynum1 - mynum2;
            break;
        case "+":
            var myres = mynum1 + mynum2;
            break;
        case "*":
            var myres = mynum1 * mynum2;
            break;
        case "%":
            var myres = mynum2 / mynum1;
            break;
        default:
            var myres = mynum1 * mynum2;
            break;
    }
    myres = parseFloat(myres) + 0.0000001;
    myres = myres.toFixed(2); //.toString();
    return myres.toFixed(2);
}

function TransferCardClick(e) {
    if ($("#TransferCard").hasClass('l-btn-disabled')) {
        return false;
    }
    var CardNo = $("#CardNo").val();
    if (CardNo == "") {
        $.messager.alert("提示", "卡号不能为空。转正式卡前，请双击临时卡记录带出临时卡号!", "info", function() {
            $("#CardNo").focus();
        });
        return false;
    }
    var myval = $("#CardTypeDefine").combobox('getValue');
    var myCardTypeDR = myval.split("^")[0];
    var myCardType = myval.split("^")[2];
    var TemporaryCardFlag = $.m({
        ClassName: "web.DHCBL.CARD.UCardRefInfo",
        MethodName: "GetTemporaryCardFlag",
        CardTypeId: myCardTypeDR
    }, false)
    if (TemporaryCardFlag != "Y") {
        $.messager.alert("提示", myCardType + " 无临时卡权限!");
        return false;
    }
    PageLogicObj.m_MedicalFlag = 1;
    PageLogicObj.m_ModifiedFlag = 1;
    PageLogicObj.m_TransferCardFlag = 1;
    $("#TemporaryCard").switchbox("setValue", false);
    setTimeout(function() {
        SaveDataToServer();
        PageLogicObj.m_MedicalFlag = 0;
        PageLogicObj.m_ModifiedFlag = 0;
        PageLogicObj.m_TransferCardFlag = 0;
    });
}

function InitTemporaryCard(CardNo) {
    if (!CardNo) CardNo = "";
    if (CardNo != "") {
        var myval = $("#CardTypeDefine").combobox('getValue');
        var myCardTypeDR = myval.split("^")[0];
        var Data = $.m({
            ClassName: "web.DHCBL.CARD.UCardRefInfo",
            MethodName: "GetTemporaryCardFlag",
            CardTypeId: myCardTypeDR,
            CardNo: CardNo
        }, false)
    } else {
        var Data = PageLogicObj.m_CTDTemporaryCardFlag;
    }
    if (Data == "Y") {
        $("#TemporaryCard").switchbox('setActive', true)
        var Val = CardNo ? true : false
        $("#TemporaryCard").switchbox('setValue', Val)
        DisableBtn("TransferCard", false);
    } else {
        $("#TemporaryCard").switchbox('setActive', false)
        $("#TemporaryCard").switchbox('setValue', false)
        DisableBtn("TransferCard", true);
    }
    return Data
}

function IntDoc() {
    var myary = ServerObj.DefaultAccPara.split("^");
    if (isNaN(myary[0])) {
        var myVal = 0;
    } else {
        var myVal = parseInt(myary[0]);
    }
    if (myVal == 1) myVal = true;
    else myVal = false;
    $("#SetDefaultPassword").checkbox('setValue', myVal);
    if (myVal) {
        $("#SetDefaultPassword").checkbox('disable')
    } else {
        $("#SetDefaultPassword").checkbox('enable')
    }
    if (isNaN(myary[14])) {
        var myVal = 0;
    } else {
        var myVal = parseInt(myary[14]);
    }
    $("#DepPrice").val(myVal);
    GetCurrentRecNo();
    var src = "../images/uiimages/patdefault.png";
    ShowPicBySrcNew(src, "imgPic");
}

function GetCurrentRecNo() {
    /*$.m({
    	ClassName:"web.UDHCAccAddDeposit",
    	MethodName:"GetCurrentRecNo",
    	userid:session['LOGON.USERID'],
    	type:"D"
    },function(ren){
    	var myary=ren.split("^");
    	if (myary.length>5) PageLogicObj.m_ReceiptsType=myary[5];
    	if (myary[0]=='0'){
    		$("#ReceiptsNo").val(myary[3]);
    	}
    });*/
    var myary = ServerObj.DefaultCurrentRecNoPara.split("^");
    if (myary.length > 5) PageLogicObj.m_ReceiptsType = myary[5];
    if (myary[0] == '0') {
        $("#ReceiptsNo").val(myary[3]);
    }
}

function prtClick() {
    if ($("#PAPMINo").val() == "") {
        $.messager.alert("提示", "病人ID不能为空!");
        return false;
    }
    //PatInfoPrint("PAPMINo");
    var argObj = { CardTypeDR: PageLogicObj.m_SelectCardTypeRowID, CardNo: $("#CardNo").val(), PatientID: $("#PAPMIRowID").val() };
    var rtn = CardCommon_ControlObj.PrintCardInfo(argObj);
    if (rtn.split("^")[0]!="0") {
        PatInfoPrint("PAPMINo");
    }
}

function PatInfoPrint(ElementName) {
    var PatInfoXMLPrint = "PatInfoPrint";
    var Char_2 = "\2";
    var InMedicare = $("#InMedicare").val();
    var Name = $("#Name").val();
    var RegNo = $("#" + ElementName).val();
    //如果登记号存在去后台取患者姓名
    if (RegNo != "") {
        var PatStr = $.cm({
            ClassName: "web.DHCDocOrderEntry",
            MethodName: "GetPatientByNo",
            dataType: "text",
            PapmiNo: RegNo
        }, false)
        if (PatStr != "") { Name = PatStr.split("^")[2] }
    }
    var TxtInfo = "TPatName" + Char_2 + "姓  名:" + "^Name" + Char_2 + Name + "^TRegNo" + Char_2 + "病人ID:" + "^RegNo" + Char_2 + RegNo + "^RegNoTM" + Char_2 + "*" + RegNo + "*"
    if (InMedicare != "") TxtInfo = TxtInfo + "^TMedicareNo" + Char_2 + "病案号:" + "^MedicareNo" + Char_2 + InMedicare;
    var ListInfo = "";
    DHCP_GetXMLConfig("DepositPrintEncrypt", PatInfoXMLPrint);
    //var myobj = document.getElementById("ClsBillPrint");
    //DHCP_PrintFun(myobj, TxtInfo, ListInfo);
    DHC_PrintByLodop(getLodop(), TxtInfo, ListInfo, "", "");
}

function CardSearchCallBack(cardno, Regno, patientid) {
    $("#PAPMINo").val(Regno);
    ValidateRegInfoByCQU(patientid);
}

function ValidateRegInfoByCQU(PAPMIDR) {
    var myval = $("#CardTypeDefine").combobox('getValue');
    var myCardTypeDR = myval.split("^")[0];
    var myValidateMode = myval.split("^")[30];
    if (myValidateMode == "CQU") {
        var myInfo = $.cm({
            ClassName: "web.DHCBL.CARD.UCardPATRegConfig",
            MethodName: "ReadConfigByCQU",
            dataType: "text",
            PAPMIDR: PAPMIDR,
            CardTypeDR: myCardTypeDR,
            SessionStr: ""
        }, false)
        var myary = myInfo.split(String.fromCharCode(1));
        switch (myary[0]) {
            case "0":
                break;
            case "-368":
                PageLogicObj.m_RegCardConfigXmlData = myary[1];
                var myPatInfoXmlData = myary[2];
                var myRepairFlag = myary[3];
                SetPatInfoByXML(myPatInfoXmlData);
                GetPatDetailByPAPMINo();
                SetPatRegCardDefaultConfigValue(myary[4]);
                break;
            case "-365":
                $.messager.alert("提示", "此证件号码已经存在,请办理其他卡或办理补卡!");
                SearchSamePatient();
                break;
            default:
                $.messager.alert("提示", "" + " Err Code=" + myary[0]);
                break;
        }
    } else {
        GetPatDetailByPAPMINo();
    }
}

function CardSearchClick() {
    var src = "reg.cardsearchquery.hui.csp";
    src=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(src):src;
    var $code = "<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='" + src + "'></iframe>";
    createModalDialog("FindPatReg", "卡查询", 1260, PageLogicObj.dh, "icon-w-find", "", $code, "");
}

function OtherCredTypeInput() {
    var src = "doc.othercredtype.hui.csp?OtherCardInfo=" + $("#OtherCardInfo").val();;
    src=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(src):src;
    var $code = "<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='" + src + "'></iframe>";
    createModalDialog("OtherCredTypeManager", "其他证件管理", "500", "390", "icon-w-list", "", $code, "");
}

function CardUniteClick() {
    var src = "reg.dhcpatcardunite.hui.csp"; //websys.default.csp?WEBSYS.TCOMPONENT=DHCPATCardUnite
    src=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(src):src;
    var $code = "<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='" + src + "'></iframe>";
    createModalDialog("Find", "患者信息合并", PageLogicObj.dw + 150, PageLogicObj.dh + 80, "icon-w-edit", "", $code, "");
}

function CardTypeSave(newData) {
    $("#OtherCardInfo").val(newData);
}

function PatTypeOnChange() {
    if (!$("#PatType").next().hasClass('combo')) return false
    var PatType = $("#PatType").combobox("getValue");
    var CardTypeDefine = $("#CardTypeDefine").combobox("getValue");
    var NotCardFeePatType = CardTypeDefine.split("^")[39]
    if (NotCardFeePatType == "") {
        $("#CardFareCost").val(PageLogicObj.m_CardCost);
        $("#PatPaySum").val(PageLogicObj.m_CardCost);
        return false
    }
    var NotCardFeePatTypeStr = "," + NotCardFeePatType + ","
    var PatTypeStr = "," + PatType + ","
    if (NotCardFeePatTypeStr.indexOf(PatTypeStr) > -1) {
        $("#CardFareCost").val("0");
        $("#PatPaySum").val("0");
        $("#amt").val("");
    } else {
        $("#CardFareCost").val(PageLogicObj.m_CardCost);
        $("#PatPaySum").val(PageLogicObj.m_CardCost);
        $("#amt").val("");
    }
}

function Doc_OnKeyDown(e) {
    if (window.event) {
        var keyCode = window.event.keyCode;
        var type = window.event.type;
        var SrcObj = window.event.srcElement;
    } else {
        var keyCode = e.which;
        var type = e.type;
        var SrcObj = e.target;
    }
    if (keyCode == 13) {
        var dis = $("#EditWindow").parent().css('display');
        if ((dis != 'none') && (PageLogicObj.m_ShowWindowFlag == "Y")) {
            RealBtnClick();
        }
        if (dis != 'none') {
            PageLogicObj.m_ShowWindowFlag = "Y";
        }
        if ((SrcObj.tagName == "A") || (SrcObj.tagName == "INPUT")) {
            if ($(".window-mask").is(":visible")) {
                $(".messager-button a").click();
                return false;
            }
            var myComName = SrcObj.id;
            if (myComName == "CardNo") {
                CardNokeydown(e);
            }
            /*else if(myComName=="PAPMINo"){
            				PAPMINoOnKeyDown(e);
            			}*/
            if (myComName == "ForeignIDCard") {
                ForeignIDCardOnKeyPress(e);
            } else if (myComName == "CredNo") {
                CredNoOnKeyPress(e);
            } else if (myComName == "PatPaySum") {
                PatPaySumKeyPress(e);
            }
            return DOMFocusJump(myComName);
        }
        return true;
    }
    if (((event.altKey) && ((event.keyCode == 67) || (event.keyCode == 99)))) {
        NewCardclick();
    }
}

function InitAddressCombo() {

    var cbox = $HUI.combobox("#Address,#RegisterPlace,#AddressBirth", {
        valueField: 'provid',
        textField: 'provdesc',
        editable: true,
        selectOnNavigation: false,
        mode: "remote",
        delay: "500",
        url: $URL + "?ClassName=web.DHCBL.CTBASEIF.ICTCardRegLB&QueryName=admaddressNewlookup&rows=999999",
        onBeforeLoad: function(param) {
            var desc = "";
            if (param['q']) {
                desc = param['q'];
            }
            param = $.extend(param, { desc: desc });
        },
        loadFilter: function(data) {
            return data['rows'];
        },
        onSelect: function(record) {
            if (typeof record == "undefined") { return }
            var AdddressIDStr = ""
            var AdddressIDStr = record.AddressIDStr; //sbq导致读不出病人信息
            if (AdddressIDStr == "") {
                return true;
            }
            var AdddressIDArr = AdddressIDStr.split("^");
            var CountryDR = AdddressIDArr[0];
            var ProvinceDR = AdddressIDArr[1];
            var CityDR = AdddressIDArr[2];
            var CityAreaDR = AdddressIDArr[3];
            var CommunityDR = AdddressIDArr[4];
            var StreetDR = AdddressIDArr[5];
            if (this.id == "Address") {
                SetCountryComboxData("CountryHouse", CountryDR);
                CountrySelect("CountryHouse", CountryDR);
                $("#ProvinceInfoLookUpRowID").combobox("select", ProvinceDR);
                $("#CityDescLookUpRowID").combobox("select", CityDR);
                $("#CityAreaLookUpRowID").combobox("select", CityAreaDR);
                $("#StreetNow").combobox("select", StreetDR);
            } else if (this.id == "RegisterPlace") {
                SetCountryComboxData("CountryDescLookUpRowID", CountryDR);
                CountrySelect("CountryDescLookUpRowID", CountryDR);
                $("#ProvinceHouse").combobox("select", ProvinceDR);
                $("#Cityhouse").combobox("select", CityDR);
                $("#AreaHouse").combobox("select", CityAreaDR);
                $("#StreetHouse").combobox("select", StreetDR);

            } else if (this.id == "AddressDef") {
                var winEvent = window.event;
                var mykey = winEvent.keyCode;
                if (mykey == 13) {
                    PageLogicObj.m_ShowWindowFlag = ""
                }
                OpenWin(AdddressIDStr)
            } else if (this.id == "AddressBirth") {
                $("#ProvinceBirth").combobox("select", ProvinceDR);
                $("#CityBirth").combobox("select", CityDR);
                $("#AreaBirth").combobox("select", CityAreaDR);
                $("#StreetBirth").combobox("select", StreetDR);

            }
            return true;
        }
    });
    //$("#Address").combobox("resize","625");
}

function BAddressInoCollapsClick() {
    if ($(".addressinfo").css("display") == "none") {
        $(".addressinfo-div").removeClass("addressinfo-collapse").addClass("addressinfo-expand");
        $(".addressinfo").show();
        $("#BAddressInoCollaps .l-btn-text")[0].innerText = $g("隐藏全部");
        if (PageLogicObj.m_IsNotStructAddress == "Y") {
            $("#Address").combobox("resize", 547);
            $("#RegisterPlace").combobox("resize", 110);
        }
    } else {
        $(".addressinfo-div").removeClass("addressinfo-expand").addClass("addressinfo-collapse");
        $(".addressinfo").hide();
        $("#BAddressInoCollaps .l-btn-text")[0].innerText = $g("展开全部");
    }
}

function BPayInoCollapsClick() {
    if ($(".payinfo").css("display") == "none") {
        $(".payinfo-div").removeClass("payinfo-collapse").addClass("payinfo-expand");
        $(".payinfo").show();
        $("#BPayInoCollaps .l-btn-text")[0].innerText = $g("隐藏全部");
    } else {
        $(".payinfo-div").removeClass("payinfo-expand").addClass("payinfo-collapse");
        $(".payinfo").hide();
        $("#BPayInoCollaps .l-btn-text")[0].innerText = $g("展开全部");
    }
}

function BBaseInoCollapsClick() {
    if ($(".baseinfo").css("display") == "none") {
        $(".baseinfo-div").removeClass("baseinfo-collapse").addClass("baseinfo-expand");
        $(".baseinfo").show();
        $("#BBaseInoCollaps .l-btn-text")[0].innerText = $g("隐藏全部");
    } else {
        $(".baseinfo-div").removeClass("baseinfo-expand").addClass("baseinfo-collapse");
        $(".baseinfo").hide();
        $("#BBaseInoCollaps .l-btn-text")[0].innerText = $g("展开全部");
    }
}

function CheckData() {
    //患者住院期间控制只允许在住院登记界面修改患者基本信息
    var rtn = CheckInHos();
    if (!rtn) { return false; }
    var IsTemporaryCard = $("#TemporaryCard").switchbox("getValue")
    var myrtn = true;
    if (IsTemporaryCard) {
        var myCardNo = $("#CardNo").val();
        if (PageLogicObj.m_UsePANoToCardNO != "Y") {
            if (myCardNo == "") {
                $.messager.alert("提示", "请输入临时卡卡号!", "info", function() { $("#CardNo").focus(); });
                return false;
            } else {
                if ((PageLogicObj.m_CardNoLength != 0) && (myCardNo.length != PageLogicObj.m_CardNoLength)) {
                    $.messager.alert("提示", "卡号长度应该为" + PageLogicObj.m_CardNoLength + "位，请核实！", "info", function() {
                        $("#CardNo").focus();
                    });
                    return false;
                }
            }
        }
        var myName = $("#Name").val();
        if (myName == "") {
            $.messager.alert("提示", "请输入患者姓名!", "info", function() { $("#Name").focus(); });
            return false;
        }
        var mySex = $("#Sex").combobox("getValue");
        if ((mySex == "") || (mySex == undefined)) {
            $.messager.alert("提示", "请选择性别!", "info", function() {
                $('#Sex').next('span').find('input').focus();
            });
            return false;
        }
        var myPatType = $("#PatType").combobox("getValue");
        myPatType = CheckComboxSelData("PatType", myPatType);
        if ((myPatType == "") || (myPatType == undefined)) {
            $.messager.alert("提示", "请选择患者类型", "info", function() {
                $('#PatType').next('span').find('input').focus();
            });
            return false;
        }
        var PAPMIRowID = $("#PAPMIRowID").val();
        if ((PAPMIRowID == "") && (!ChkCardCost())) return false;
        return true; //临时卡只需要验证姓名、性别、卡费用
    }
    if (PageLogicObj.m_PatMasFlag == "Y") {
        var IsNullInfo = "",
            FocusName = "";
        //必填项目验证
        var myrtn = true;
        for (var i = 0; i < PageLogicObj.m_CardRegMustFillInArr.length; i++) {
            var id = PageLogicObj.m_CardRegMustFillInArr[i]['id'];
            if (id == "CredNo") continue;
            if (id == "TelHome") {
	            var myval = $("#CredType").combobox("getValue");
	            if (myval == "33^09") continue;
	        };
            var text = PageLogicObj.m_CardRegMustFillInArr[i]['text'];
            var val = getValue(id);
            if (val == "") {
                text = $g(text)
                if (IsNullInfo == "") IsNullInfo = text, FocusName = id;
                else IsNullInfo = IsNullInfo + " , " + text;

            }
        }
        if (IsNullInfo != "") {
            $.messager.alert("提示", $g("请输入") + "<font color=red>" + IsNullInfo + "</font> !", "info", function() {
                setFocus(FocusName)
            });
            return false;
        }
    }
    var myExpstr = "";
    //患者证件类型为身份证时，验证身份证号是否已经存在患者信息，如果存在则更新患者信息
    var myIDrtn = IsCredTypeID();
    if (myIDrtn) {
        var CredNo = $("#CredNo").val();
        if (CredNo != "") {
            myExpstr = CredNo;
        }
		if ((CredNo.substr(0,6)=="810000")||((CredNo.substr(0,6)=="820000"))||((CredNo.substr(0,6)=="830000"))){
    		$.messager.alert("提示", CredNo+"<font color=red>" + "为港澳台通行证号码" + "</font> !", "info", function() {
          		setFocus("CredNo")
       		});
        	return false;
    	}
    }
    var myPAPMINo = $('#PAPMINo').val();
    if ((myPAPMINo != "") || (myExpstr != "")) {
        var myPatInfo = $.cm({
            ClassName: "web.DHCBL.CARD.UCardPaPatMasInfo",
            MethodName: "GetPatInfoByPANo",
            dataType: "text",
            PAPMINo: myPAPMINo,
            ExpStr: myExpstr
        }, false);
        var myary = myPatInfo.split("^");
        if (myary[0] == "2001") {
            $.messager.alert("提示", "无此登记号的患者,不能建卡!", "info", function() {
                $("#PAPMINo").focus();
            });
            return false;
        } else if (myary[0] == "0") {
            var myXMLStr = myary[1];
            var PatientID = myXMLStr.split("<PAPMIRowID>")[1].split("</PAPMIRowID>")[0];
            if (PatientID != "") {
                $("#PAPMIRowID").val(PatientID);
            } else {
                $("#PAPMIRowID").val("");
            }
        }
    }
    var PAPMIRowID = $("#PAPMIRowID").val();
    //验证患者信息(姓名、性别、出生日期、联系电话)是否存在一致的患者
    if (!PatInfoUnique()) {
        return false;
    }
    var InsuNo = $('#PatYBCode').val();
    //医保手册号
    if ((InsuNo != "") && (InsuNo != "99999999999S")) {
        var Rtn = $.cm({
            ClassName: "web.DHCBL.Patient.DHCPatient",
            MethodName: "PatUniInfoQuery",
            dataType: "text",
            PatientDr: PAPMIRowID,
            Type: "InsuNo",
            NoStr: InsuNo
        }, false);
        if (Rtn > 0) {
            $.messager.alert("提示", InsuNo + "医保号已被使用!", "info", function() {
                $("#PatYBCode").focus();
            });
            return false
        }
    }
    var OpMedicareObj = document.getElementById('OpMedicare');
    if (PageLogicObj.m_PatMasFlag == "Y") {
        var myBirthTime = $("#BirthTime").val();
        if (myBirthTime != "") {
            var regTime = /^([0-2][0-9]):([0-5][0-9]):([0-5][0-9])$/;
            if (!regTime.test(myBirthTime)) {
                $.messager.alert("提示", "请输入正确的出生时间!", "info", function() {
                    $("#BirthTime").focus();
                });
                return false;
            }
        }
        /*var IsNullInfo="",FocusIndex=""
        var myTelHome=$("#TelHome").val();
        if (myTelHome=="")
        {
        	IsNullInfo="联系电话"
        	FocusIndex="TelHome"
        	//$.messager.alert("提示","请输入联系电话!","info",function(){
        	//	$("#TelHome").focus();
        	//});
        	//return false;
        }
        var myMobPhone=$("#MobPhone").val();
        if (myMobPhone!=""){
        	if(myMobPhone.length!="11"){
        		$.messager.alert("提示","手机号码长度错误,应为【11】位,请核实!","info",function(){
        			$("#MobPhone").focus();
        		});
        	    return false;
        	}
        }
        var myName=$("#Name").val();
        if (myName==""){
        	if (IsNullInfo=="")	{
        		IsNullInfo="患者姓名"
        		FocusIndex="Name"
        	}
        	else IsNullInfo=IsNullInfo+"、患者姓名"
        	//$.messager.alert("提示","请输入患者姓名!","info",function(){
        	//	$("#Name").focus();
        	//});
        	//return false;
        }
        var mySex=$("#Sex").combobox("getValue");
        if ((mySex=="")||(mySex==undefined)){
        	if (IsNullInfo=="")	{
        		IsNullInfo="性别"
        		FocusIndex="Sex"
        	}
        	else IsNullInfo=IsNullInfo+"、性别"
        	//$.messager.alert("提示","请选择性别!","info",function(){
        	//	$("#Sex").focus();
        	//});
        	//return false;
        }
        var myPatType= $("#PatType").combobox("getValue");
        myPatType=CheckComboxSelData("PatType",myPatType);
        if ((myPatType=="")||(myPatType==undefined)){
        	if (IsNullInfo=="")	{
        		IsNullInfo="患者类型"
        		FocusIndex="PatType"
        	}
        	else IsNullInfo=IsNullInfo+"、患者类型"
        	//$.messager.alert("提示","请选择患者类型!","info",function(){
        	//	$("#PatType").focus();
        	//});
        	//return false;
        }
        var myBirth=$("#Birth").val();
        if (myBirth==""){
        	if (IsNullInfo=="")	{
        		IsNullInfo="出生日期"
        		FocusIndex="Birth"
        	}
        	else IsNullInfo=IsNullInfo+"、出生日期"
        	//$.messager.alert("提示","请输入出生日期!","info",function(){
        	//	$("#Birth").focus();
        	//});
        	//return false;
        }
        if (IsNullInfo!=""){
        	$.messager.alert("提示",IsNullInfo+"不能为空!","info",function(){
        		$("#"+FocusIndex).focus();
        	});
        	return false;
        }*/
        //非医保类型不能填写医保号
        if (!checkPatYBCode()) return false;
        if (!BirthCheck()) return false;
        if (!ForeignIDCardOnKeyPress()) return false;
        var myTelHome = $("#TelHome").val();
        if (myTelHome != "") {
            if (!CheckTelOrMobile(myTelHome, "TelHome", "联系电话")) return false;
        }
        var myMobPhone = $("#MobPhone").val();
        if (myMobPhone != "") {
            if (!CheckTelOrMobile(myMobPhone, "MobPhone", "手机")) return false;
        }
        var myTelOffice = $("#TelOffice").val();
        if (myTelOffice != "") {
            if (!CheckTelOrMobile(myTelOffice, "TelOffice", "办公电话")) return false;
        }
        var myBirth = $("#Birth").val();
        if (myBirth != "") {
            if (ServerObj.dtformat == "YMD") {
                var reg = /^(([0-9]{3}[1-9]|[0-9]{2}[1-9][0-9]{1}|[0-9]{1}[1-9][0-9]{2}|[1-9][0-9]{3})-(((0[13578]|1[02])-(0[1-9]|[12][0-9]|3[01]))|((0[469]|11)-(0[1-9]|[12][0-9]|30))|(02-(0[1-9]|[1][0-9]|2[0-8]))))|((([0-9]{2})(0[48]|[2468][048]|[13579][26])|((0[48]|[2468][048]|[3579][26])00))-02-29)$/;
            }
            if (ServerObj.dtformat == "DMY") {
                var reg = /^(((0[1-9]|[12][0-9]|3[01])\/((0[13578]|1[02]))|((0[1-9]|[12][0-9]|30)\/(0[469]|11))|(0[1-9]|[1][0-9]|2[0-8])\/(02))\/([0-9]{3}[1-9]|[0-9]{2}[1-9][0-9]{1}|[0-9]{1}[1-9][0-9]{2}|[1-9][0-9]{3}))|(29\/02\/(([0-9]{2})(0[48]|[2468][048]|[13579][26])|((0[48]|[2468][048]|[3579][26])00)))$/;
            }
            var ret = myBirth.match(reg);
            if (ret == null) {
                $.messager.alert("提示", "请输入正确的出生日期!", "info", function() {
                    $("#Birth").focus();
                });
                return false;
            }
            if (ServerObj.dtformat == "YMD") {
                var myrtn = DHCWeb_IsDate(myBirth, "-")
            }
            if (ServerObj.dtformat == "DMY") {
                var myrtn = DHCWeb_IsDate(myBirth, "/")
            }
            if (!myrtn) {
                $.messager.alert("提示", "请输入正确的出生日期!", "info", function() {
                    $("#Birth").focus();
                });
                return false;
            } else {
                var mybirth1 = $("#Birth").val();
                var Checkrtn = CheckBirth(mybirth1);
                if (Checkrtn == false) {
                    $.messager.alert("提示", "出生日期不能大于今天或者小于、等于1840年!", "info", function() {
                        $("#Birth").focus();
                    });
                    return false;
                }
            }
            var mybirth = $("#Birth").val();
            var myage = $("#Age").val();
            var mybirthTime = $("#BirthTime").val();
            var ageStr = $.cm({
                ClassName: "web.UDHCJFCOMMON",
                MethodName: "DispPatAge",
                dataType: "text",
                birthDate: mybirth,
                admDate: "",
                birthTime: mybirthTime,
                admTime: "",
                controlFlag: "N",
                hospId: session['LOGON.HOSPID']
            }, false);
            if ((ageStr.split("||")[1] != myage) && (ageStr.split("||")[0] != myage)) {
                if (ageStr.split("||")[1] != 0) {
                    $.messager.alert("提示", "出生日期不能与年纪不相等!实际年龄" + ageStr.split("||")[1], "info", function() {
                        $("#Birth").focus();
                    });
                    return false;
                } else {
                    $.messager.alert("提示", "出生日期不能与年纪不相等!实际年龄" + ageStr.split("||")[0], "info", function() {
                        $("#Birth").focus();
                    });
                    return false;
                }

            }
            if (!LimitBirthTime() && mybirthTime == "") {
                $("label[for=BirthTime]").addClass("clsRequired");
                $.messager.alert("提示", $g("年龄小于") + ServerObj.LimitBirthTimeByAge + $g("天需填写出生时间"), "info", function() {
                    $("#BirthTime").focus();
                });
                return false;
            } else {
                $("label[for=BirthTime]").removeClass("clsRequired");
            }
        }
        //仅建病历下列提示信息为必填
        if ((PageLogicObj.m_MedicalFlag == 1) && (PageLogicObj.m_ModifiedFlag == 0)) {
            if (PageLogicObj.m_IsNotStructAddress == "Y") {
                var myAddress = $("#Address").combobox("getText");
                if (myAddress == "") {
                    $.messager.alert("提示", "没有地址,请填写地址!", "info", function() {
                        $('#Address').next('span').find('input').focus();
                    });
                    return false;
                }
            } else {
                var myAddress = $("#Address").val();
                if (myAddress == "") {
                    $.messager.alert("提示", "没有地址,请填写地址!", "info", function() {
                        $("#Address").focus();
                    });
                    return false;
                }
            }
            var myCountryDesc = $("#CountryDescLookUpRowID").combobox('getValue');
            myCountryDesc = CheckComboxSelData("CountryDescLookUpRowID", myCountryDesc);
            if (myCountryDesc == "") {
                $.messager.alert("提示", "请选择国籍!", "info", function() {
                    $('#CountryDescLookUpRowID').next('span').find('input').focus();
                });
                return false;
            }
            var myPAPERMarital = $("#PAPERMarital").combobox('getValue');
            if (myPAPERMarital == "") {
                $.messager.alert("提示", "请选择婚姻状态!", "info", function() {
                    $('#PAPERMarital').next('span').find('input').focus();
                });
                return false;
            }
            var myProvinceBirth = $("#ProvinceBirth").combobox('getValue');
            myProvinceBirth = CheckComboxSelData("ProvinceBirth", myProvinceBirth);
            if (myProvinceBirth == "") {
                if (!AddressInfoIsExpand()) BAddressInoCollapsClick();
                $.messager.alert("提示", "请选择省(出生)!", "info", function() {
                    $('#ProvinceBirth').next('span').find('input').focus();
                });
                return false;
            }
            var myNationDesc = $("#NationDescLookUpRowID").combobox('getValue');
            myNationDesc = CheckComboxSelData("NationDescLookUpRowID", myNationDesc);
            if (myNationDesc == "") {
                $.messager.alert("提示", "请选择民族!", "info", function() {
                    $('#NationDescLookUpRowID').next('span').find('input').focus();
                });
                return false;
            }
            var myCityBirth = $("#CityBirth").combobox('getValue');
            myCityBirth = CheckComboxSelData("CityBirth", myCityBirth);
            if (myCityBirth == "") {
                if (!AddressInfoIsExpand()) BAddressInoCollapsClick();
                $.messager.alert("提示", "请选择市(出生)!", "info", function() {
                    $('#CityBirth').next('span').find('input').focus();
                });
                return false;
            }
            var myAreaBirth = $("#AreaBirth").combobox('getValue');
            myAreaBirth = CheckComboxSelData("AreaBirth", myAreaBirth);
            if (myAreaBirth == "") {
                if (!AddressInfoIsExpand()) BAddressInoCollapsClick();
                $.messager.alert("提示", "请选择县(出生)!", "info", function() {
                    $('#AreaBirth').next('span').find('input').focus();
                });
                return false;
            }
            var myProvinceInfo = $("#ProvinceInfoLookUpRowID").combobox('getValue');
            myProvinceInfo = CheckComboxSelData("ProvinceInfoLookUpRowID", myProvinceInfo);
            if (myProvinceInfo == "") {
                if (!AddressInfoIsExpand()) BAddressInoCollapsClick();
                $.messager.alert("提示", "请选择省(现住)!", "info", function() {
                    $('#AreaBirth').next('span').find('input').focus();
                });
                return false;
            }
            var myCityDesc = $("#CityDescLookUpRowID").combobox('getValue');
            myCityDesc = CheckComboxSelData("CityDescLookUpRowID", myCityDesc);
            if (myCityDesc == "") {
                if (!AddressInfoIsExpand()) BAddressInoCollapsClick();
                $.messager.alert("提示", "请选择市(现住)!", "info", function() {
                    $('#CityDescLookUpRowID').next('span').find('input').focus();
                });
                return false;
            }
            var myCTArea = $("#CityAreaLookUpRowID").combobox('getValue');
            myCTArea = CheckComboxSelData("CityAreaLookUpRowID", myCTArea);
            if (myCTArea == "") {
                if (!AddressInfoIsExpand()) BAddressInoCollapsClick();
                $.messager.alert("提示", "请选择县(现住)!", "info", function() {
                    $('#CityAreaLookUpRowID').next('span').find('input').focus();
                });
                return false;
            }
            var myCompany = $("#EmployeeCompanyLookUpRowID").val();
            if (myCompany == "") {
                if (!AddressInfoIsExpand()) BAddressInoCollapsClick();
                $.messager.alert("提示", "请输入工作单位!", "info", function() {
                    $('#EmployeeCompanyLookUpRowID').focus();
                });
                return false;
            }
            var myProvinceHouse = $("#ProvinceHouse").combobox('getValue');
            myProvinceHouse = CheckComboxSelData("ProvinceHouse", myProvinceHouse);
            if (myProvinceHouse == "") {
                if (!AddressInfoIsExpand()) BAddressInoCollapsClick();
                $.messager.alert("提示", "请选择省(户口)!", "info", function() {
                    $('#CityAreaLookUpRowID').next('span').find('input').focus();
                });
                return false;
            }
            var myCityhouse = $("#Cityhouse").combobox('getValue');
            myCityhouse = CheckComboxSelData("Cityhouse", myCityhouse);
            if (myCityhouse == "") {
                if (!AddressInfoIsExpand()) BAddressInoCollapsClick();
                $.messager.alert("提示", "请选择市(户口)!", "info", function() {
                    $('#CityAreaLookUpRowID').next('span').find('input').focus();
                });
                return false;
            }
            var myAreaHouse = $("#AreaHouse").combobox('getValue');
            myAreaHouse = CheckComboxSelData("AreaHouse", myAreaHouse);
            if (myAreaHouse == "") {
                if (!AddressInfoIsExpand()) BAddressInoCollapsClick();
                $.messager.alert("提示", "请选择县(户口)!", "info", function() {
                    $('#AreaHouse').next('span').find('input').focus();
                });
                return false;
            }
            if (PageLogicObj.m_IsNotStructAddress == "Y") {
                var myAddress = $("#RegisterPlace").combobox("getText");
                if (myAddress == "") {
                    if (!AddressInfoIsExpand()) BAddressInoCollapsClick();
                    $.messager.alert("提示", "请填写地址(户口)!", "info", function() {
                        $('#RegisterPlace').next('span').find('input').focus();
                    });
                    return false;
                }
            } else {
                var myAddress = $("#RegisterPlace").val();
                if (myAddress == "") {
                    if (!AddressInfoIsExpand()) BAddressInoCollapsClick();
                    $.messager.alert("提示", "请填写地址(户口)!", "info", function() {
                        $("#RegisterPlace").focus();
                    });
                    return false;
                }
            }
            var myCTRelationDR = $("#CTRelationDR").combobox("getText");
            myCTRelationDR = CheckComboxSelData("CTRelationDR", myCTRelationDR);
            if (myCTRelationDR == "") {
                if (!BaseInfoIsExpand()) BBaseInoCollapsClick();
                $.messager.alert("提示", "请选择关系!", "info", function() {
                    $("#CTRelationDR").focus();
                });
                return false;
            }
            var myForeignPhone = $("#ForeignPhone").val();
            if (myForeignPhone == "") {
                if (!BaseInfoIsExpand()) BBaseInoCollapsClick();
                $.messager.alert("提示", "请输入联系人电话!", "info", function() {
                    $("#ForeignPhone").focus();
                });
                return false;
            } else {
                if (!CheckTelOrMobile(myForeignPhone, "ForeignPhone", "联系人电话")) return false;
            }
        }
    }
    //var OpMedicareObj = document.getElementById('OpMedicare');
    var CredNo = $("#CredNo").val();
    if (PageLogicObj.m_PatMasFlag == "Y") {
        var myForeignName = $("#ForeignName").val();
        if (myForeignName == "") {
            /*if(PageLogicObj.m_MedicalFlag==1){
			    if (!BaseInfoIsExpand()) BBaseInoCollapsClick();
				$.messager.alert("提示","请输入联系人!","info",function(){
					$("#ForeignName").focus();
				});
				return false;
			}*/
        }
        /*var myTelHome = $("#TelHome").val();
        if (myTelHome == "") {
        	$.messager.alert("提示","请输入联系电话!","info",function(){
        		$("#TelHome").focus();
        	});
        	return false;
        }else{
        	if (!CheckTelOrMobile(myTelHome,"TelHome","")) return false;
        }
        var myBirth = $("#Birth").val();
        if (myBirth == "") {
        	$.messager.alert("提示","请输入出生日期!","info",function(){
        		$("#Birth").focus();
        	});
        	return false;
        }*/
        if (CheckBirthAndBirthTime()) {
            $.messager.alert("提示", "出生日期是当天的,出生时间不能大于当前时间,请核实!", "info", function() {
                $("#BirthTime").focus();
            });
            return false;
        }
        /*var mySex = $("#Sex").combobox("getValue");
        if (mySex == "") {
        	$.messager.alert("提示","请选择性别!","info",function(){
        		$('#Sex').next('span').find('input').focus();
        	});
        	return false;
        }*/
        var Age = AgeForYear(myBirth)
        if (Age < ServerObj.ForeignInfoByAge) {
            var ForeignName = $("#ForeignName").val();
            var ForeignPhone = $("#ForeignPhone").val();
            var ForeignIDCard = $("#ForeignIDCard").val();
            if (ForeignName == "") {
                if (!BaseInfoIsExpand()) BBaseInoCollapsClick();
                $.messager.alert("提示", $g("年龄小于") + ServerObj.ForeignInfoByAge + $g("岁") + "," + $g("联系人不能为空!"), "info", function() {
                    $("#ForeignName").focus();
                });
                return false;
            }
            if (ForeignPhone == "") {
                if (!BaseInfoIsExpand()) BBaseInoCollapsClick();
                $.messager.alert("提示", $g("年龄小于") + ServerObj.ForeignInfoByAge + $g("岁") + "," + $g("联系人电话不能为空!"), "info", function() {
                    $("#ForeignPhone").focus();
                });
                return false;
            }
            if (ForeignPhone != "") {
                if (!BaseInfoIsExpand()) BBaseInoCollapsClick();
                if (!CheckTelOrMobile(ForeignPhone, "ForeignPhone", "联系人电话")) return false;
            }
            if (ForeignIDCard == "") {
                if (!BaseInfoIsExpand()) BBaseInoCollapsClick();
                $.messager.alert("提示", $g("年龄小于") + ServerObj.ForeignInfoByAge + $g("岁") + "," + $g("联系人证件信息不能为空"), "info", function() {
                    $("#ForeignIDCard").focus();
                });
                return false;
            }
        } else {
            var myForeignPhone = $("#ForeignPhone").val();
            if (myForeignPhone != "") {
                if (!CheckTelOrMobile(myForeignPhone, "ForeignPhone", "联系人电话")) return false;
            }
        }
        /*婚姻状态控制 start*/
        var mySex = $("#Sex").combobox('getText');
        var mySexID = $("#Sex").combobox('getValue');
        var SexData = $("#Sex").combobox('getData');
        var SexDesc=mySex; //默认取界面上的性别描述
        var SexDesc="";
        SexData.forEach(object =>{
            if(object.id === mySexID){
                if (object.code ==1){
                    SexDesc=$g("男");
                }else{
                    SexDesc=$g("女");
                }
            }
        });
        var myPAPERMarital = $("#PAPERMarital").combobox('getValue');
        var AgeToMaritalFlag = 0
        if (SexDesc == $g("女")) {
            if ((Age < PageLogicObj.m_MarriedLimitFemaleFAge) && (("^" + PageLogicObj.m_MarriedIDStr + "^").indexOf("^" + myPAPERMarital + "^") != -1)) {
                AgeToMaritalFlag = 1;
            }
        } else if (SexDesc == $g("男")) {
            if ((Age < PageLogicObj.m_MarriedLimitMaleAge) && (("^" + PageLogicObj.m_MarriedIDStr + "^").indexOf("^" + myPAPERMarital + "^") != -1)) {
                AgeToMaritalFlag = 1;
            }
        }
        if (AgeToMaritalFlag == 1) {
		   dhcsys_alert($g("该患者未到法定年龄!"));
           //$.messager.alert("提示", "该患者未到法定年龄!", "info");
        }
        /*婚姻状态控制 end*/
        /*var myPatType = $("#PatType").combobox("getValue");
        myPatType=CheckComboxSelData("PatType",myPatType);
        if ((myPatType == "")||(myPatType==undefined)) {
        	$.messager.alert("提示","请选择患者类型","info",function(){
        		$('#PatType').next('span').find('input').focus();
        	});
        	return false;
        }*/
        //对于病人类型为职工的对工号的判断
        var myPatType = $("#PatType").combobox("getText");
        if (myPatType.indexOf('本院') >= 0) {
            var EmployeeNo = $("#EmployeeNo").val();
            if (EmployeeNo == "") {
                $.messager.alert("提示", "本院职工,请填写职工工号!", "info", function() {
                    $("#EmployeeNo").focus();
                });
                return false;
            }
            var curPAPMIRowID = $.cm({
                ClassName: "web.DHCBL.CARDIF.ICardPaPatMasInfo",
                MethodName: "GetPAPMIRowIDByEmployeeNo",
                dataType: "text",
                EmployeeNo: EmployeeNo
            }, false);
            var name = curPAPMIRowID.split("^")[1];
            var UserName = curPAPMIRowID.split("^")[2];
            curPAPMIRowID = curPAPMIRowID.split("^")[0];
            if (curPAPMIRowID == "0") {
                $.messager.alert("提示", "工号不正确,请核实工号!", "info", function() {
                    $("#EmployeeNo").focus();
                });
                return false;
            }
            var PAPMIRowID = $("#PAPMIRowID").val();
            if ((PAPMIRowID != curPAPMIRowID) && (curPAPMIRowID != "")) {
                $.messager.alert("提示", $g("此工号已经被") + "'" + name + "'" + $g("所用,请核实工号!"), "info", function() {
                    $("#EmployeeNo").focus();
                });
                return false;
            }
            var Name = $("#Name").val();
            if (UserName != Name) {
                $.messager.alert("提示", $g("此工号对应姓名为") + "'" + UserName + "'" + $g("和所录入姓名不一致!"), "info", function() {
                    $("#Name").focus();
                });
                return false;
            }
        } else {
            var EmployeeNo = $("#EmployeeNo").val();
            if (EmployeeNo != "") {
                $.messager.alert("提示", "非本院职工工号不可填写!", "info", function() {
                    $("#EmployeeNo").focus();
                });
                return false;
            }
        }
        var myIDNo = $("#CredNo").val();
        if (myIDNo != "") {
            var myval = $("#CredType").combobox("getValue");
            if (myval == "") {
                $.messager.alert("提示", "证件号码不为空时,证件类型不能为空!");
                return false;
            }
            var myIDrtn = IsCredTypeID();
            if (myIDrtn) {
                var myIsID = DHCWeb_IsIdCardNo(myIDNo);
                if (!myIsID) {
                    $("#CredNo").focus();
                    return false;
                }
                var IDNoInfoStr = DHCWeb_GetInfoFromId(myIDNo)
                var IDBirthday = IDNoInfoStr[2]
                if (myBirth != IDBirthday) {
                    $.messager.alert("提示", "出生日期与身份证信息不符!", "info", function() {
                        $("#Birth").focus();
                    });
                    return false;
                }
                var IDSex = $g(IDNoInfoStr[3])
                if (SexDesc != IDSex) {
                    $.messager.alert("提示", $g("身份证号:") + myIDNo + $g("对应的性别是") + "【" + IDSex + "】," + $g("请选择正确的性别!"), "info", function() {
                        $('#Sex').next('span').find('input').focus();
                    });
                    return false;
                }
            } else {
                var myval = $("#CredType").combobox("getValue");
                var myCredTypeDR = myval.split("^")[0];
                var PAPMIRowID = $("#PAPMIRowID").val();
                var mySameFind = $.cm({
                    ClassName: "web.DHCBL.CARD.UCardPaPatMasInfo",
                    MethodName: "CheckCredNoIDU",
                    PatientID: PAPMIRowID,
                    CredNo: myIDNo,
                    CredTypeDR: myCredTypeDR,
                    dataType: "text"
                }, false);
                if (mySameFind == "1") {
                    $.messager.alert("提示", myIDNo + " 此证件号码已经被使用!", "info", function() {
                        $("#CredNo").focus();
                    })
                    return false;
                }
                //如果证件类型不是身份证,清空IDCardNo1值，防止IDCardNo1更新到papmi_id
                $("#IDCardNo1").val("");
            }
            var OtherCardInfo = $("#OtherCardInfo").val();
            if (OtherCardInfo != "") {
                var CredNo = $("#CredNo").val();
                var myval = $("#CredType").combobox("getValue");
                var myCredTypeDR = myval.split("^")[0];
                for (var i = 0; i < OtherCardInfo.split("!").length; i++) {
                    var oneCredTypeId = OtherCardInfo.split("!")[i].split("^")[0];
                    var oneCredNo = OtherCardInfo.split("!")[i].split("^")[1];
                    if (oneCredTypeId != myCredTypeDR) {
                        var ret=CheckCredNoValid(oneCredNo,oneCredTypeId)
                        if (ret!=0){
                            $.messager.alert("提示",  ret , "info", function() {
                                //$("#CredNo").focus();
                            });
                            return false;
                        }
                        continue;
                    }
                    var oneCredNo = OtherCardInfo.split("!")[i].split("^")[1];
                    if ((oneCredNo != CredNo) && (oneCredNo != "")) {
                        $.messager.alert("提示", $g("证件号码:") + " " + CredNo + " " + $g("和其他证件里面相同证件类型维护的号码:") + " " + oneCredNo + " " + $g("不一致!请核实!"), "info", function() {
                            $("#CredNo").focus();
                        });
                        return false;
                    }
                }
            }
        } else {
            var myval = $("#CredType").combobox("getValue");
            var myCredTypeDR = myval.split("^")[0];
            var CredNoRequired = $.cm({
                ClassName: "web.DHCBL.CARD.UCardRefInfo",
                MethodName: "CheckCardNoRequired",
                dataType: "text",
                CredTypeDr: myCredTypeDR
            }, false)
            var AgeAllow = $.cm({
                ClassName: "web.DHCDocConfig",
                MethodName: "GetDHCDocCardConfig",
                dataType: "text",
                Node: "AllowAgeNoCreadCard"
            }, false);
            var FlagNoCread = $.cm({
                ClassName: "web.DHCDocConfig",
                MethodName: "GetDHCDocCardConfig",
                dataType: "text",
                Node: "NOCREAD"
            }, false);
            if (CredNoRequired == "Y") {
                if ((AgeAllow != "") & (parseFloat(Age) <= parseFloat(AgeAllow))) {} else {
                    $.messager.alert("提示", "请填写证件号码!", "info", function() {
                        $('#CredNo').focus();
                    });
                    return false;
                }
            }
        }
        var myval = $("#CardTypeDefine").combobox("getValue");
        var myary = myval.split("^");
        if (myary[3] == "C") {
            var mypmval = $("#PayMode").combobox("getValue");
            if (mypmval == "") {
                $.messager.alert("提示", "请选择支付方式!", "info", function() {
                    $('#PayMode').next('span').find('input').focus();
                });
                return false;
            }
            var mytmpary = mypmval.split("^");
            if (mytmpary[2] == "Y") {
                ///Require Pay Info
                var myCheckNO = $("#CardChequeNo").val();
                if (myCheckNO == "") {
                    if (!PayInfoIsExpand()) BPayInoCollapsClick();
                    $.messager.alert("提示", "请输入支票/信用卡号!", "info", function() {
                        $('#CardChequeNo').focus();
                    });
                    return false;
                }
            }
        }
        var myOtheRtn = OtherSpecialCheckData();
        if (!myOtheRtn) {
            return myOtheRtn;
        }
        if (PageLogicObj.m_ModifiedFlag == 1) return true;
    }
    //如果是用登记号号作为卡号则不取校验界面卡号
    // if ((PageLogicObj.m_CardRefFlag == "Y") && (PageLogicObj.m_UsePANoToCardNO != "Y")) {
    if ((PageLogicObj.m_CardRefFlag == "Y") && (PageLogicObj.m_UsePANoToCardNO != "Y")&&(PageLogicObj.m_AllowNoCardNoFlag!="Y")) {
        var myCardNo = $("#CardNo").val();
        if (myCardNo == "") {
            $.messager.alert("提示", "卡号不能为空,请读卡!", "info", function() {
                if (PageLogicObj.m_SetFocusElement != "") {
                    $("#" + PageLogicObj.m_SetFocusElement).focus();
                } else {
                    $("#CardNo").focus();
                }
            });
            return false;
        }
        ////Card NO Length ?= Card Type Define Length
        var myCTDefLength = 0;
        if (isNaN(PageLogicObj.m_CardNoLength)) {
            myCTDefLength = 0;
        } else {
            myCTDefLength = PageLogicObj.m_CardNoLength;
        }
        if ((myCTDefLength != 0) && (myCardNo.length != myCTDefLength)) {
            $.messager.alert("提示", "卡号长度应该为" + PageLogicObj.m_CardNoLength + "位，请核实！", "info", function() {
                if (PageLogicObj.m_SetFocusElement != "") {
                    $("#" + PageLogicObj.m_SetFocusElement).focus();
                } else {
                    $("#CardNo").focus();
                }
            });
            return false;
        }
        ////Card No Pre ?= Card Type Define Pre
        if (PageLogicObj.m_CardTypePrefixNo != "") {
            var myPreNoLength = PageLogicObj.m_CardTypePrefixNo.length;
            var myCardNo = $("#CardNo").val();
            var myPreNo = myCardNo.substring(0, myPreNoLength);
            if (myPreNo != PageLogicObj.m_CardTypePrefixNo) {
                $.messager.alert("提示", "卡号码前缀错误!", "info", function() {
                    $("#CardNo").focus();
                });
                return false;
            }
        }
    }
    if (!ChkCardCost()) return false;

    return myrtn;
}

function ChkCardCost() {
    var myPatPaySum = $("#PatPaySum").val();
    if ((myPatPaySum == "") && (+PageLogicObj.m_CardCost > 0)) {
        $.messager.alert("提示", "请输入收款金额!", "info", function() {
            $("#PatPaySum").focus();
        });
        return false;
    } else {
        var PatPaySum = $("#PatPaySum").val();
        var CardFareCost = $("#CardFareCost").val()
        $("#amt").val(DHCCalCom(PatPaySum, CardFareCost, "-"));
        var myChange = $("#amt").val();
        if ((isNaN(myChange)) || (myChange == "")) {
            myChange = 0;
        }
        myChange = parseFloat(myChange);
        if (myChange < 0) {
            $.messager.alert("提示", "输入费用金额错误!", "info", function() {
                $("#PatPaySum").focus();
            });
            return false;
        }
        var ReceiptsNo = $("#ReceiptsNo").val();
        var myChange = $("#amt").val();
        if ((myChange != "") && (myChange != "0") && (ReceiptsNo == "") && (PageLogicObj.m_ReceiptsType != "")) {
            $.messager.alert("提示", "您已经没有可用收据,请先领取收据!");
            return false;
        }
    }
    if (PageLogicObj.m_AccManagerFlag == "Y") {
        var amt = $("#amt").val();
        if ((!IsNumber(amt)) || (amt < 0)) {
            $.messager.alert("提示", "金额输入有误,请重新输入!", "info", function() {
                $("#PatPaySum").focus();
            });
            return false;
        }
    }
    return true;
}

function CheckTelOrMobile(telephone, Name, Type) {
    if (telephone.length == 8) return true;
    if (DHCC_IsTelOrMobile(telephone)) return true;
    if (telephone.substring(0, 1) == 0) {
        if (telephone.indexOf('-') >= 0) {
            $.messager.alert("提示", Type + "固定电话长度错误,固定电话区号长度为【3】或【4】位,固定电话号码长度为【7】或【8】位,并以连接符【-】连接,请核实!", "info", function() {
                $("#" + Name).focus();
            })
            return false;
        } else {
            $.messager.alert("提示", Type + "固定电话长度错误,固定电话区号长度为【3】或【4】位,固定电话号码长度为【7】或【8】位,请核实!", "info", function() {
                $("#" + Name).focus();
            })
            return false;
        }
    } else {
        if (telephone.length != 11) {
            $.messager.alert("提示", Type + "电话长度应为【11】位,请核实!", "info", function() {
                $("#" + Name).focus();
            })
            return false;
        } else {
            $.messager.alert("提示", Type + "不存在该号段的手机号,请核实!", "info", function() {
                $("#" + Name).focus();
            })
            return false;
        }
    }
    return true;
}

function CheckBirthAndBirthTime() {
    var Today = new Date();
    var mytime = Today.getHours();
    var CurMinutes = Today.getMinutes();
    if (CurMinutes <= 9) {
        CurMinutes = "0" + CurMinutes;
    }
    mytime = mytime + ":" + CurMinutes;
    var CurSeconds = Today.getSeconds();
    if (CurSeconds <= 9) {
        CurSeconds = "0" + CurSeconds;
    }
    mytime = mytime + ":" + CurSeconds;
    var Today = getNowFormatDate();
    var myBirth = $("#Birth").val();
    if (myBirth == Today) {
        var BirthTime = $("#BirthTime").val();
        if (BirthTime != "") {
            if (BirthTime.split(":").length == 2) {
                BirthTime = BirthTime + ":00"
            }
        }
        BirthTime = BirthTime.replace(/:/g, "")
        mytime = mytime.replace(/:/g, "")
        if (parseInt(BirthTime) > parseInt(mytime)) {
            return true
        } else {
            return false
        }
    }
    return false;
}

function getNowFormatDate() {
    var date = new Date();
    var seperator1 = "-";
    var month = date.getMonth() + 1;
    var strDate = date.getDate();
    if (month >= 1 && month <= 9) {
        month = "0" + month;
    }
    if (strDate >= 0 && strDate <= 9) {
        strDate = "0" + strDate;
    }
    if (ServerObj.dtformat == "YMD") {
        var currentdate = date.getFullYear() + seperator1 + month + seperator1 + strDate
    }
    if (ServerObj.dtformat == "DMY") {
        var seperator1 = "/";
        var currentdate = strDate + seperator1 + month + seperator1 + date.getFullYear()
    }
    return currentdate;
}
//获取年龄--年用来比较
function AgeForYear(strBirthday) {
    if (ServerObj.dtformat == "YMD") {
        var strBirthdayArr = strBirthday.split("-");
        var birthYear = strBirthdayArr[0];
        var birthMonth = strBirthdayArr[1];
        var birthDay = strBirthdayArr[2];
    }
    if (ServerObj.dtformat == "DMY") {
        var strBirthdayArr = strBirthday.split("/");
        var birthYear = strBirthdayArr[2];
        var birthMonth = strBirthdayArr[1];
        var birthDay = strBirthdayArr[0];
    }
    var d = new Date();
    var nowYear = d.getFullYear();
    var nowMonth = d.getMonth() + 1;
    var nowDay = d.getDate();
    var ageDiff = nowYear - birthYear; //年之差
    if (birthMonth > nowMonth) {
        ageDiff = ageDiff - 1
    } else if (birthMonth == nowMonth) {
        if (birthDay > nowDay) {
            ageDiff = ageDiff - 1
        }
    }
    return ageDiff
}

function OtherSpecialCheckData() {
    var myVer = ServerObj.ConfigVersion;
    switch (myVer) {
        case "7":
            var myAge = $("#Age").val();
            if (isNaN(myAge)) { myAge = 0 };
            if (myAge < 14) {
                var myForeignName = $("#ForeignName").val();
                if (myForeignName == "") {
                    if (!BaseInfoIsExpand()) BBaseInoCollapsClick();
                    $.messager.alert("提示", "14岁以下,联系人是必填项目!", "info", function() {
                        $("#ForeignName").focus();
                    });
                    return false;
                }
                if (PageLogicObj.m_IsNotStructAddress == "Y") {
                    var myAddress = $("#Address").combobox("getText");
                    if (myAddress == "") {
                        if (!BaseInfoIsExpand()) BBaseInoCollapsClick();
                        $.messager.alert("提示", "14岁以下, 地址是必填项目!", "info", function() {
                            $('#Address').next('span').find('input').focus();
                        });
                        return false;
                    }
                } else {
                    var myAddress = $("#Address").val();
                    if (myAddress == "") {
                        if (!BaseInfoIsExpand()) BBaseInoCollapsClick();
                        $.messager.alert("提示", "14岁以下, 地址是必填项目!", "info", function() {
                            $("#Address").focus();
                        });
                        return false;
                    }
                }
                var myTelHome = $("#TelHome").val();
                if (myTelHome == "") {
                    if (!BaseInfoIsExpand()) BBaseInoCollapsClick();
                    $.messager.alert("提示", "14岁以下, 联系电话是必填项目!", "info", function() {
                        $("#TelHome").focus();
                    });
                    return false;
                }
            }
            break;
        default:
            break;
    }
    return true;
}

function IsNumber(string, sign) {
    var number;
    if (string == null) return false;
    if ((sign != null) && (sign != '-') && (sign != '+')) {
        return false;
    }
    number = new Number(string);
    if (isNaN(number)) {
        return false;
    } else if ((sign == null) || (sign == '-' && number < 0) || (sign == '+' && number > 0)) {
        return true;
    } else
        return false;
}

function PatInfoUnique() {
    var myoptval = $("#CardTypeDefine").combobox("getValue");
    var myary = myoptval.split("^");
    var myCardTypeDR = myary[0];
    var Name = $("#Name").val();
    var Sex = $("#Sex").combobox("getValue");
    var Birth = $('#Birth').val();
    var Tel = $("#TelHome").val();
    var PAPMIRowID = $("#PAPMIRowID").val()
    var rtn = $.cm({
        ClassName: "web.DHCPATCardUnite",
        MethodName: "GetPatByInfo",
        CardType: myCardTypeDR,
        Name: Name,
        Sex: Sex,
        Birth: Birth,
        Tel: Tel,
        PAPMIRowID: PAPMIRowID,
        dataType: "text"
    }, false)
    var RtnArr = rtn.split("^")
    if (RtnArr[0] == "0") {
        return true;
    } else if (RtnArr[0] == "S") {
        $.messager.alert('提示', '此卡类型、姓名、性别、出生日期、联系电话信息绑定已挂失卡' + RtnArr[1] + ',请作废此卡后重新建卡');
        return false;
    } else if (RtnArr[0] == "N") {
        $.messager.alert('提示', '此卡类型、姓名、性别、出生日期、联系电话信息绑定卡' + RtnArr[1] + ',请办理其他卡或者补卡');
        return false;
    }
    return true;
}

function BirthCheck() {
    var mybirth = $("#Birth").val();
    if ((mybirth == "") || ((mybirth.length != 8) && ((mybirth.length != 10)))) {
        $.messager.alert("提示", "请输入正确的出生日期!", "info", function() {
            $("#Birth").focus();
        });
        return false;
    } else {
        $("#Birth").removeClass("newclsInvalid");
    }
    if ((mybirth.length == 8)) {
        if (ServerObj.dtformat == "YMD") {
            var mybirth = mybirth.substring(0, 4) + "-" + mybirth.substring(4, 6) + "-" + mybirth.substring(6, 8)
        }
        if (ServerObj.dtformat == "DMY") {
            var mybirth = mybirth.substring(6, 8) + "/" + mybirth.substring(4, 6) + "/" + mybirth.substring(0, 4)
        }
        $("#Birth").val(mybirth);
    }
    if (ServerObj.dtformat == "YMD") {
        var myrtn = DHCWeb_IsDate(mybirth, "-")
    }
    if (ServerObj.dtformat == "DMY") {
        var myrtn = DHCWeb_IsDate(mybirth, "/")
    }
    if (!myrtn) {
        $.messager.alert("提示", "请输入正确的出生日期!", "info", function() {
            $("#Birth").focus();
        });
        return false;
    } else {
        $("#Birth").removeClass("newclsInvalid");
    }
    return true;
}

function GetPatMasInfo() {
    var myxml = "";
    if (PageLogicObj.m_PatMasFlag == "Y") {
        var myparseinfo = $("#InitPatMasEntity").val();
        var myxml = GetEntityClassInfoToXML(myparseinfo)
    }
    return myxml;
}

function GetCardRefInfo() {
    var myxml = "";
    if (PageLogicObj.m_CardRefFlag == "Y") {
        var myparseinfo = $("#InitCardRefEntity").val();
        var myxml = GetEntityClassInfoToXML(myparseinfo)
    }
    return myxml;
}

function GetCardINVInfo() {
    var myxml = "";
    if (PageLogicObj.m_CardRefFlag == "Y") {
        var myparseinfo = $("#InitCardINVPRTEntity").val();
        var myxml = GetEntityClassInfoToXML(myparseinfo)
    }
    return myxml;
}

function GetAccManagerInfo() {
    var myxml = "";
    if (PageLogicObj.m_AccManagerFlag == "Y") {
        var myparseinfo = $("#InitAccManagerEntity").val();
        var myxml = GetEntityClassInfoToXML(myparseinfo)
    }
    return myxml;
}

function GetPreDepositeInfo() {
    var myxml = "";
    if (PageLogicObj.m_AccManagerFlag == "Y") {
        var myparseinfo = $("#InitAccPreDepositEncrypt").val();
        var myxml = GetEntityClassInfoToXML(myparseinfo)
    }
    return myxml;
}

function GetEntityClassInfoToXML(ParseInfo) {
    var myxmlstr = "";
    try {
        var myary = ParseInfo.split("^");
        var xmlobj = new XMLWriter();
        xmlobj.BeginNode(myary[0]);
        for (var myIdx = 1; myIdx < myary.length; myIdx++) {
            xmlobj.BeginNode(myary[myIdx]);
            var _$id = $("#" + myary[myIdx]);
            if (_$id.length == 0) {
                var myval = "";
            } else {
                //if (_$id.hasClass("hisui-combobox")){
                if (_$id.next().hasClass('combo')) {
                    if ((myary[myIdx] == "RegisterPlace") || (myary[myIdx] == "Address") || (myary[myIdx] == "AddressBirth")) {
                        var myval = _$id.combobox("getText");
                    } else {
                        var myval = _$id.combobox("getValue");
                        if (myval == undefined) myval = "";
                        //防止类型卡类型、支付方式id是已串的形式存在
                        if (myval != "") {
                            myval = myval.split("^")[0];
                        }
                    }
                } else if (_$id.hasClass("hisui-switchbox")) {
                    var Val = _$id.switchbox("getValue");
                    var myval = Val ? "Y" : "N"
                } else {
                    if (PageLogicObj.m_IsNotStructAddress == "Y") {
                        if ((myary[myIdx] == "RegisterPlace") || (myary[myIdx] == "Address")) {
                            var myval = _$id.combobox("getText");
                        } else {
                            var myval = _$id.val();
                        }
                    } else {
                        var myval = _$id.val();
                    }
                    if (myary[myIdx] == "PhotoInfo") {
                        myval = "";
                    }
                    if (myary[myIdx] == "Name") {
                        myval = escape(myval) + "!!Unicode";
                    }
                }
            }
            xmlobj.WriteString(myval);
            xmlobj.EndNode();
        }
        xmlobj.Close();
        myxmlstr = xmlobj.ToString();
    } catch (Err) {
        $.messager.alert("提示", "Error: " + Err.description);
    }
    return myxmlstr;
}

function WrtCard() {
    var myPAPMINo = $("#PAPMINo").val();
    var mySecrityNo = $.cm({
        ClassName: "web.UDHCAccCardManage",
        MethodName: "GetCardCheckNo",
        dataType: "text",
        PAPMINo: myPAPMINo
    }, false);
    if (mySecrityNo != "") {
        //var rtn = DHCACC_WrtMagCard("3", "", mySecrityNo, PageLogicObj.m_CCMRowID);
        var rtn = CardCommon_ControlObj.WrtMagCard({
	        CardTypeDR:PageLogicObj.m_SelectCardTypeRowID,
	        SecurityNo:mySecrityNo,
	        WType:"3"  
        });
        if (rtn != "0") {
            return "-1^"
        }
    } else {
        return "-1^";
    }
    return "0^" + mySecrityNo
}

function PatRegPatInfoPrint(RowIDStr, CurXMLName, EncryptItemName) {
    if (CurXMLName == "") {
        return;
    }
    var INVtmp = RowIDStr.split("^");
    if (INVtmp.length > 0) {
        DHCP_GetXMLConfig("DepositPrintEncrypt", CurXMLName);
    }
    for (var invi = 0; invi < INVtmp.length; invi++) {
        if (INVtmp[invi] != "") {
            var encmeth = $("#" + EncryptItemName).val();
            var Guser = session['LOGON.USERID'];
            var sUserCode = session['LOGON.USERCODE'];
            var myExpStr = "";
            var Printinfo = cspRunServerMethod(encmeth, "InvPrintNew", CurXMLName, INVtmp[invi], Guser, myExpStr);
        }
    }
}

function InvPrintNew(TxtInfo, ListInfo) {
    var HospName = $("#HospName").val();
    var PDlime = String.fromCharCode(2);
    var TxtInfo = TxtInfo + "^" + "HospName3" + PDlime + HospName;
    var TxtInfo = TxtInfo + "^" + "hospitalDesc" + PDlime + HospName;
    //var myPAName=$("#Name").val();
    //TxtInfo=TxtInfo+"^"+"PatName"+PDlime+myPAName;
    //var myobj=document.getElementById("ClsBillPrint");
    //DHCP_PrintFun(myobj,TxtInfo,ListInfo);
    DHC_PrintByLodop(getLodop(), TxtInfo, ListInfo, "", "");
}

function CheckComboxSelData(id, selId) {
    var Find = 0;
    var Data = $("#" + id).combobox('getData');
    for (var i = 0; i < Data.length; i++) {
        var CombValue = Data[i].id;
        var CombDesc = Data[i].text;
        if (selId == CombValue) {
            selId = CombValue;
            Find = 1;
            break;
        }
    }
    if (Find == "1") return selId
    return "";
}

function SetCardNOLength() {
    var CardNo = $("#CardNo").val();
    if ((PageLogicObj.m_CardNoLength != 0) && (CardNo.length > PageLogicObj.m_CardNoLength)) {
        $.messager.confirm('提示', '卡号位数大于卡类型配置位数,是否截取?', function(r) {
            if (r) {
                GetPatByCardNo();
            } else {
                return false;
            }
        });
    } else {
        GetPatByCardNo();
    }

    function GetPatByCardNo() {
        if ((CardNo.length < PageLogicObj.m_CardNoLength) && (PageLogicObj.m_CardNoLength != 0)) {
            for (var i = (PageLogicObj.m_CardNoLength - CardNo.length - 1); i >= 0; i--) {
                CardNo = "0" + CardNo;
            }
        }
        if ((CardNo.length > PageLogicObj.m_CardNoLength) && (PageLogicObj.m_CardNoLength != 0)) {
            PageLogicObj.m_CardSecrityNo = CardNo.substring(PageLogicObj.m_CardNoLength, CardNo.length);
            CardNo = CardNo.substring(0, PageLogicObj.m_CardNoLength);
        }
        $("#CardNo").val(CardNo);
        PageLogicObj.m_CardVerify = "";
        GetValidatePatbyCard();
    }
    return true;
}

function createModalDialog(id, _title, _width, _height, _icon, _btntext, _content, _event) {
    $("body").append("<div id='" + id + "' class='hisui-dialog'></div>");
    if (_width == null)
        _width = 800;
    if (_height == null)
        _height = 500;
    $("#" + id).dialog({
        title: _title,
        width: _width,
        height: _height,
        cache: false,
        iconCls: _icon,
        //href: _url,
        collapsible: false,
        minimizable: false,
        maximizable: false,
        resizable: false,
        modal: true,
        closed: false,
        closable: true,
        content: _content,
        onClose: function() {
            destroyDialog(id);
        }
    });
}

function destroyDialog(id) {
    //移除存在的Dialog
    $("body").remove("#" + id);
    $("#" + id).dialog('destroy');
}
//判断基本信息是否全部展开
function BaseInfoIsExpand() {
    if ($(".baseinfo").css("display") == "none") {
        return false;
    }
    return true;
}
//判断地址信息是否全部展开
function AddressInfoIsExpand() {
    if ($(".addressinfo").css("display") == "none") {
        return false;
    }
    return true;
}
//判断缴费信息是否全部展开
function PayInfoIsExpand() {
    if ($(".payinfo").css("display") == "none") {
        return false;
    }
    return true;
}

function CardSearchDBClickHander(row) {
    var myPatientID = row['TPatientID'];
    var Regno = row['RegNo'];
    var OtherCardNo = row['OtherCardNo'];
    $("#PAPMINo").val(row['RegNo']);
    var myCardNo = $("#CardNo").val();
    GetPatDetailByPAPMINo();
    //双击患者信息行绑定，不清楚卡号框
    $("#CardNo").val(myCardNo);

    var CardNO = row['CardNO'];
    if (CardNO.indexOf(",") < 0) {
        var CardType = $.cm({
            ClassName: "web.DHCPATCardUnite",
            MethodName: "ReadCardTypeByDesc",
            Desc: CardNO,
            dataType: "text"
        }, false)
        $("#CardTypeDefine").combobox('select', CardType);
        var CardNo = CardNO.split(" ")[1];
        var IsTemporaryCard = InitTemporaryCard(CardNo);
        if (IsTemporaryCard == "Y") {
            $("#CardNo").val(CardNo);
        }
    }
    //设置其他证件信息
    CardTypeSave(OtherCardNo);
    //关联建卡使用登记号作为卡号，验证卡号的有效性
    CheckForUsePANoToCardNO("Modify");
}

//cache对象中以键值对的形式存储我们的缓存数据
var cache = {};
//index数组中该存储键，这个键是有顺序，可以方便我们做超出容量的处理
var index = [];

function createCache() {
    return function(key, value) {
        //如果传了值，就说名是设置值
        if (value !== undefined) {
            //将数据存入cache对象，做缓存
            cache[key] = value;
            //将键存入index数组中，以和cache中的数据进行对应
            index.push(key);

            //判断缓存中的数据数量是不是超出了限制
            if (index.length >= 150) {
                //如果超出了限制
                //删除掉最早存储缓存的数据
                //最早存入缓存的数据的键是在index数组的第一位
                //使用数组的shift方法可以获取并删除掉数组的第一个元素
                var tempKey = index.shift();
                //获取到最早加入缓存的这个数据的键，可以使用它将数据从缓存各种删除
                delete cache[tempKey];
            }
        }
        return cache[key];
    }
}

function SaveCahce() {
    var typeCache = createCache();
    var $txt = $(".textbox");
    for (var i = 0; i < $txt.length; i++) {
        var id = $txt[i]['id'];
        var _$label = $("label[for=" + id + "]");
        if (_$label.length == 1) {
            var text = _$label[0].innerHTML;
            typeCache(id, text);
        }
    }
    $.cm({
        ClassName: "web.DHCBL.CARD.UCardPATRegConfig",
        MethodName: "SaveCardRegDOMCache",
        dataType: "text",
        obj: JSON.stringify(cache)
    }, function(rtn) {});
}
///根据元素的classname获取元素值
function getValue(id) {
    var className = $("#" + id).attr("class")
    if (typeof className == "undefined") {
        return $("#" + id).val()
    }
    if (className.indexOf("hisui-lookup") >= 0) {
        var txt = $("#" + id).lookup("getText")
            //如果放大镜文本框的值为空,则返回空值
        if (txt != "") {
            var val = $("#" + id).val()
        } else {
            var val = ""
            $("#" + id + "Id").val("")
        }
        return val
    } else if (className.indexOf("combobox-f") >= 0) { //hisui-combobox
        var val = $("#" + id).combobox("getValue")
        if (typeof val == "undefined") val = ""
        return val
    } else if (className.indexOf("hisui-datebox") >= 0) {
        return $("#" + id).dateboxq("getValue")
    } else {
        return $("#" + id).val()
    }
    return ""
}

function setFocus(id) {
    var className = $("#" + id).attr("class")
    if (typeof className == "undefined") {
        $("#" + id).focus();
    }
    if (("^hisui-lookup^hisui-combobox^hisui-datebox^combobox-f").indexOf(("^" + className + "^")) >= 0) {
        $("#" + id).next('span').find('input').focus();
    } else {
        $("#" + id).focus();
    }
}

function DOMFocusJump(myComName) {
    var myComIdx = find(PageLogicObj.m_CardRegJumpSeqArr, myComName)
    if (myComIdx >= 0) {
        if (myComIdx == (PageLogicObj.m_CardRegJumpSeqArr.length - 1)) {} else {
            var id = PageLogicObj.m_CardRegJumpSeqArr[myComIdx + 1]['id'];
            if (id == "PAPMINo") {
                if ($("#PAPMINo").val() != "") {
                    DOMFocusJump("PAPMINo");
                    return;
                } else {
                    var id = PageLogicObj.m_CardRegJumpSeqArr[myComIdx + 2]['id'];

                }
            }
            if (id != "undefined") {
                var _$id = $("#" + id);
                //if (_$id.hasClass("hisui-combobox")){
                if (_$id.next().hasClass('combo')) {
                    _$id.next('span').find('input').focus();
                } else {
                    _$id.focus();
                }

            }
        }
        return false;
    } else {
        return true;
    }

    function find(list, elem) {
        var index = -1;
        for (var i = 0; i < list.length; i++) {
            var current = list[i];
            if (elem == current['id']) {
                index = i;
                break;
            }
        }
        return index;
    }
}
///根据身份证号赋值结构化地址信息
function BuildAddressByIDCard(IDCard) {
    $.cm({
        ClassName: "web.DHCDocCommon",
        MethodName: "GetAddrInfoByCredNo",
        CredNo: IDCard,
        dataType: "text"
    }, function(Data) {
        if (Data == "") return;
        var DataArr = Data.split("!")
        var ProvInfo = DataArr[0]
        var CityInfo = DataArr[1]
        var AreaInfo = DataArr[2]
        if (ServerObj.BuildAddrHomeByIDCard == "Y") {
            if ($("#CountryHome").combobox('getData').length == 0) {
                LoadCountryData("CountryHome");
            }
            $("#CountryHome").combobox('select', 1)
            $("#ProvinceHome").combobox('select', ProvInfo.split("^")[0])
            $("#CityHome").combobox('select', CityInfo.split("^")[0])
        }
        if (ServerObj.BuildAddrBirthByIDCard == "Y") {
            if ($("#CountryBirth").combobox('getData').length == 0) {
                LoadCountryData("CountryBirth");
            }
            $("#CountryBirth").combobox('select', 1)
            $("#ProvinceBirth").combobox('select', ProvInfo.split("^")[0])
            $("#CityBirth").combobox('select', CityInfo.split("^")[0])
            $("#AreaBirth").combobox('select', AreaInfo.split("^")[0])
        }
        if (ServerObj.BuildAddrLookUpByIDCard == "Y") {
            if ($("#CountryHouse").combobox('getData').length == 0) {
                LoadCountryData("CountryHouse");
            }
            $("#CountryHouse").combobox('select', 1)
            $("#ProvinceInfoLookUpRowID").combobox('select', ProvInfo.split("^")[0])
            $("#CityDescLookUpRowID").combobox('select', CityInfo.split("^")[0])
            $("#CityAreaLookUpRowID").combobox('select', AreaInfo.split("^")[0])
        }
        if (ServerObj.BuildAddrHouseByIDCard == "Y") {
            if ($("#CountryDescLookUpRowID").combobox('getData').length == 0) {
                LoadCountryData("CountryDescLookUpRowID");
            }
            $("#CountryDescLookUpRowID").combobox('select', 1)
            $("#ProvinceHouse").combobox('select', ProvInfo.split("^")[0])
            $("#Cityhouse").combobox('select', CityInfo.split("^")[0])
            $("#AreaHouse").combobox('select', AreaInfo.split("^")[0])
        }
    })
}

function ExtendComboxEvent() {
    $.extend(true, $.fn.combobox.defaults, {
        keyHandler: {
            left: function(e) {
                return false;
            },
            right: function(e) {
                return false;
            },
            up: function(e) {
                nav(this, 'prev');
                e.preventDefault();
            },
            down: function(e) {
                var Data = $(this).combobox("getData");
                var CurValue = $(this).combobox("getValue");
                if ($(this).combobox('panel').is(":hidden")) {
                    $(this).combobox('showPanel');
                    return false;
                }
                nav(this, 'next');
                e.preventDefault();
            },
            query: function(q, e) {
                _8c0(this, q);
            },
            enter: function(e) {
                _8c5(this);
                var id = $(this)[0].id;
                return DOMFocusJump(id);
            }
        }
    });
    /*$HUI.combobox(".combobox-f", { //.hisui-combobox
		keyHandler:{
			left: function (e) {
				return false;
            },
			right: function (e) {
				return false;
            },
            up: function (e) {
	            nav(this,'prev');
	            e.preventDefault();
             },
             down: function (e) {
              	var Data=$(this).combobox("getData");
				var CurValue=$(this).combobox("getValue");
				if ($(this).combobox('panel').is(":hidden")){
					$(this).combobox('showPanel');
					return false;
				}
				nav(this,'next');
				e.preventDefault();
            },
            query: function (q, e) {
                _8c0(this, q);
            },
            enter: function (e) { 
            	_8c5(this);
            	var id=$(this)[0].id;
            	return DOMFocusJump(id);
            }
		}
	})*/
}

function SetCountryComboxData(comboId, CountryId) {
    if (comboId == "") return;
    if (CountryId == "") {
        $("#" + comboId).combobox('setValue', "").combobox('setText', text);
        return;
    }
    var CountryDataJson = JSON.parse(ServerObj.DefaultCTCountryPara);
    for (var k = 0; k < CountryDataJson.length; k++) {
        if (CountryDataJson[k]['id'] == CountryId) {
            var text = CountryDataJson[k]['text'];
            var AliasStr = CountryDataJson[k]['AliasStr'];
            break;
        }
    }
    $("#" + comboId).combobox('setValue', CountryId).combobox('setText', text);
}

function LoadPatInfoByRegNo() {
    if (ServerObj.PatientNoReg != "") {
        $("#PAPMINo").val(ServerObj.PatientNoReg);
        PAPMINoOnblur();
        ServerObj.PatientNoReg = "";
        if (typeof(history.pushState) === 'function') {
            //防止右键刷新后医嘱重复复制
            var Url = window.location.href;
            var NewUrl = rewriteUrl(Url, { PatientNoReg: "" });
            history.pushState("", "", NewUrl);
        }
    }
}

/// desc:	获取邮编Id
function GetPostCodeId(item) {
    var postCodeId = "",
        areaId = ""
    if (item == "CountryHome") {
        var areaId = "";
    } else if (item == "CountryBirth") {
        var areaId = "AreaBirth";
    } else if (item == "CountryDescLookUpRowID") {
        var areaId = "CityAreaLookUpRowID";
    } else if (item == "CountryHouse") {
        var areaId = "AreaHouse"
    }
    if (item == "ProvinceHome") {
        var areaId = "";
    } else if (item == "ProvinceBirth") {
        var areaId = "AreaBirth";
    } else if (item == "ProvinceInfoLookUpRowID") {
        var areaId = "CityAreaLookUpRowID";
    } else if (item == "ProvinceHouse") {
        var areaId = "AreaHouse"
    }

    if (areaId == "CityAreaLookUpRowID") {
        postCodeId = "PostCode";
    } else if (areaId == "AreaHouse") {
        postCodeId = "PostCodeHouse";
    }
    return postCodeId;
}

function CityAreaSelectHandler(AreaType) {
    var ProviceId = "",
        CityId = "",
        AreaId = "",
        PostCodeId = ""

    if (AreaType == "CityAreaLookUpRowID") {
        ProviceId = $("#ProvinceInfoLookUpRowID").combobox("getValue");
        CityId = $("#CityDescLookUpRowID").combobox("getValue");
        AreaId = $("#CityAreaLookUpRowID").combobox("getValue");
        PostCodeId = "PostCode";
    } else if (AreaType == "AreaHouse") {
        ProviceId = $("#ProvinceHouse").combobox("getValue");
        CityId = $("#Cityhouse").combobox("getValue");
        AreaId = $("#AreaHouse").combobox("getValue");
        PostCodeId = "PostCodeHouse";
    } else if (AreaType == "AreaHome") {
        ProviceId = $("#ProvinceHome").combobox("getValue");
        CityId = $("#CityHome").combobox("getValue");
        AreaId = $("#AreaHome").combobox("getValue");
        PostCodeId = "HomePostCode";
    }
    if (ProviceId != "" && CityId != "" && AreaId != "" && PostCodeId != "") {
        $.cm({
            ClassName: "web.DHCBL.CTBASEIF.ICTCardRegLB",
            MethodName: "GetPostCodeByPCA",
            Prov: ProviceId,
            City: CityId,
            CityArea: AreaId,
            dataType: "text"
        }, function(PostCode) {
            $("#" + PostCodeId).val(PostCode)
        })
    }
}

function StreetSelectHandler(AreaID) {
    var StreetId = ""
    if (AreaID == "AreaHouse") {
        var StreetId = "StreetHouse";
    } else if (AreaID == "AreaBirth") {
        var StreetId = "StreetBirth";
    } else if (AreaID == "CityAreaLookUpRowID") {
        var StreetId = "StreetNow";
    }

    var AreaValue = $("#" + AreaID).combobox("getValue")
    if (StreetId != "") {
        var Data = $.m({
            ClassName: "web.DHCBL.CTBASEIF.ICTCardRegLB",
            MethodName: "ReadBaseData",
            dataType: "text",
            TabName: "CTLocalityType",
            QueryInfo: AreaValue + "^^^HUIJSON"
        }, false);
        var cbox = $HUI.combobox("#" + StreetId, {
            width: 110,
            valueField: 'id',
            textField: 'text',
            editable: true,
            blurValidValue: true,
            data: JSON.parse(Data),
            filter: function(q, row) {
                if (q == "") return true;
                if (row["text"].indexOf(q.toUpperCase()) >= 0) return true;
                var find = 0;
                for (var i = 0; i < row["AliasStr"].split("^").length; i++) {
                    if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0) {
                        find = 1;
                        break;
                    }
                }
                if (find == 1) return true;
                return false;
            },
            onSelect: function(rec) {
                if (rec != undefined) {

                }
            },
            onChange: function(newValue, oldValue) {


            }
        });
    }
}

function LimitBirthTime() {
    var LimitFlag = true
    var Birth = $("#Birth").val();
    var DaysBetween = $.cm({
        ClassName: "web.DHCDocCommon",
        MethodName: "GetDaysBetween",
        FromDate: Birth,
        dataType: "text"
    }, false);
    if (DaysBetween != "") {
        if (parseInt(DaysBetween) <= parseInt(ServerObj.LimitBirthTimeByAge)) {
            LimitFlag = false
        }
    }
    return LimitFlag

}

function TelHomeOnBlur() {
    AdjustForeignPhone();
    SearchSamePatient();
}

/// 当联系人信息必填时，将联系电话同步到联系人电话中
/// 注册配置->全局配置->联系人信息必填(年龄) 
function AdjustForeignPhone() {
    var Birth = $("#Birth").val();
    if (Birth != "") {
        var Age = AgeForYear(Birth);
        if (Age < ServerObj.ForeignInfoByAge) {
            var TelHome = $("#TelHome").val();
            $("#ForeignPhone").val(TelHome);
        } else {
            $("#ForeignPhone").val("");
        }
    } else {
        $("#ForeignPhone").val("");
    }
}


function EmployeeNoOnKeyDown(e) {
    var key = websys_getKey(e);
    if (key == 13) {
        var myPatType = $("#PatType").combobox("getText");
        if (myPatType.indexOf('本院') >= 0) {
            var EmployeeNo = $("#EmployeeNo").val();
            if (EmployeeNo == "") {
                $.messager.alert("提示", "本院职工,请填写职工工号!", "info", function() {
                    $("#EmployeeNo").focus();
                });
                return false;
            }
            var curPAPMIRowID = $.cm({
                ClassName: "web.DHCBL.CARDIF.ICardPaPatMasInfo",
                MethodName: "GetPAPMIRowIDByEmployeeNo",
                dataType: "text",
                EmployeeNo: EmployeeNo
            }, false);
            var name = curPAPMIRowID.split("^")[1];
            var UserName = curPAPMIRowID.split("^")[2];
            curPAPMIRowID = curPAPMIRowID.split("^")[0];
            if (curPAPMIRowID == "0") {
                $.messager.alert("提示", "工号不正确,请核实工号!", "info", function() {
                    $("#EmployeeNo").focus();
                });
                return false;
            }
            var PAPMIRowID = $("#PAPMIRowID").val();
            if ((PAPMIRowID != curPAPMIRowID) && (curPAPMIRowID != "")) {
                $.messager.alert("提示", $g("此工号已经被") + "'" + name + "'" + $g("所用,请核实工号!"), "info", function() {
                    $("#EmployeeNo").focus();
                });
                return false;
            }
            $.messager.confirm("提示", "是否加载员工基本信息到当前界面?", function(r) {
                if (r) {
                    SetUserInfoByEmployeeNo();
                }
            });
        } else {
            var EmployeeNo = $("#EmployeeNo").val();
            if (EmployeeNo != "") {
                $.messager.alert("提示", "非本院职工工号不可填写!", "info", function() {
                    $("#EmployeeNo").focus();
                });
            }
        }
        return false;
    }
}

function SetUserInfoByEmployeeNo() {
    var EmployeeNo = $("#EmployeeNo").val();
    $.cm({
        ClassName: "web.DHCBL.CARDIF.ICardPaPatMasInfo",
        MethodName: "GetUserInfoByEmployeeNo",
        EmployeeNo: EmployeeNo,
        dataType: "text"
    }, function(UserInfo) {
        if (UserInfo != "") {
            var InfoArr = UserInfo.split("^")
            var UserName = InfoArr[0];
            var SexStr = InfoArr[1];
            var PatDob = InfoArr[2];
            var CredNo = InfoArr[3];
            var NationStr = InfoArr[4];
            var MaritalStr = InfoArr[5];
            var Address = InfoArr[6];
            var TelH = InfoArr[7];
            var CountryStr = InfoArr[8];
            var Img = InfoArr[9];

            $("#Name").val(UserName);
            $("#Birth").val(PatDob);
            if (PatDob) BirthOnBlur();
            $("#CredType").combobox('select', PageLogicObj.m_CredTypeDef);
            $("#CredNo").val(CredNo);
            $("#TelHome").val(TelH);
            if (PageLogicObj.m_IsNotStructAddress == "Y") {
                $("#Address").combobox('setText', Address);
            } else {
                $("#Address").val(Address);
            }
            if (SexStr != "") {
                var SexId = SexStr.split(String.fromCharCode(1))[0];
                var Sex = SexStr.split(String.fromCharCode(1))[1];
                $("#Sex").combobox("setValue", SexId);
            }
            if (NationStr != "") {
                var NationId = NationStr.split(String.fromCharCode(1))[0];
                var Nation = NationStr.split(String.fromCharCode(1))[1];
                $("#NationDescLookUpRowID").combobox("setValue", NationId);
            }
            if (MaritalStr != "") {
                var MaritalId = MaritalStr.split(String.fromCharCode(1))[0];
                var Marital = MaritalStr.split(String.fromCharCode(1))[1];
                $("#PAPERMarital").combobox("setValue", MaritalId);
            }
            if (CountryStr != "") {
                var CountryId = CountryStr.split(String.fromCharCode(1))[0];
                var Country = CountryStr.split(String.fromCharCode(1))[1];
                $("#CountryDescLookUpRowID").combobox("setValue", CountryId);
                $("#CountryHome").combobox("setValue", CountryId);
                $("#CountryBirth").combobox("setValue", CountryId);
                $("#CountryHouse").combobox("setValue", CountryId);
                $("#CountryDescLookUpRowID").combobox("setText", Country);
                $("#CountryHome").combobox("setText", Country);
                $("#CountryBirth").combobox("setText", Country);
                $("#CountryHouse").combobox("setText", Country);
                //CountrySelect("CountryDescLookUpRowID",Country);
                //CountrySelect("CountryHome",Country);
                //CountrySelect("CountryBirth",Country);
                CountrySelect("CountryHouse",Country);
            }
            if (Img != "") {
                ShowPicBySrcNew(Img, "imgPic");
                var PhotoBase64 = Img.split(";base64,")[1];
                $("#PhotoInfo").val(PhotoBase64);
            } else {
                ShowPicBySrcNew("", "imgPic");
                $("#PhotoInfo").val("");
            }
            $("#CardNo").focus();
        } else {
            $.messager.alert("提示", "员工基本信息加载失败！")
        }
    })
}

function GetErrMsg(ErrCode) {
    var errmsg = "";
    if (ErrCode == "-302") errmsg = "此病人已经有正常的卡了,不能发卡!";
    if (ErrCode == "-303") errmsg = "卡号不能为空,请读卡!";
    if (ErrCode == "-304") errmsg = "此卡号已经存在,不能发卡!";
    if (ErrCode == "-364") errmsg = "已经存在此卡类型下的有效卡,不允许再发!";
    if (ErrCode == "-365") errmsg = "此证件号码已经存在,请办理其他卡或办理补卡!";
    if (ErrCode == "-366") errmsg = "请选择卡类型!";
    if (ErrCode == "-367") errmsg = "证件号码不能为空!";
    if (ErrCode == "-369") errmsg = "办理卡绑定时,获取患者信息错误!";
    if (ErrCode == "-341") errmsg = "此卡已经建卡,不能重复发卡!";
    if (ErrCode == "-371") errmsg = "卡号码前缀错误,不能发卡!";
    if (ErrCode == "-3411") errmsg = "转正式卡失败,未找到对应的卡记录,请核实卡号和卡类型!";
    if (ErrCode == "-34101") errmsg = "此卡已经建卡，如需继续建卡请再次点击发卡!";
	if (ErrCode == "-10001") errmsg = "获取当前用户发票信息失败，需核实卡类型发票类型是否维护正确、是否开启需要发票!";
    return errmsg;
}

function LoadAddrType() {
    $.cm({
        ClassName: "web.DHCBL.CARD.CardTypeDef",
        MethodName: "GetAddrDefTypeJson",
        HospId: session['LOGON.HOSPID'],
        dataType: "text"
    }, function(ret) {
        var cbox = $HUI.combobox("#AddressType", {
            multiple: true,
            valueField: 'id',
            textField: 'text',
            blurValidValue: true,
            data: JSON.parse(ret),
        })
    })
}

function SetAddressByAddrType(AdddressIDStr) {
    if (AdddressIDStr == "") return false
    var AdddressIDArr = AdddressIDStr.split("^");
    var CountryDR = AdddressIDArr[0];
    var ProvinceDR = AdddressIDArr[1];
    var CityDR = AdddressIDArr[2];
    var CityAreaDR = AdddressIDArr[3];
    var CommunityDR = AdddressIDArr[4];
    var StreetDR = AdddressIDArr[5];
    var AddrDefType = $("#AddressType").combobox("getValues")
    var AddressDef = $("#AddressDef").combobox('getText');
    var CheckFlag = ""
    if ($("#BirthAddrbox").checkbox('getValue')) {
        var CountryBirth = $("#CountryBirth").combobox("getValue")
        if (CountryBirth == "") {
            SetCountryComboxData("CountryBirth", CountryDR);
            CountrySelect("CountryBirth", CountryDR);
        }
        if (!AddressInfoIsExpand()) BAddressInoCollapsClick();
        $("#ProvinceBirth").combobox("select", ProvinceDR);
        $("#CityBirth").combobox("select", CityDR);
        $("#AreaBirth").combobox("select", CityAreaDR);
        $("#StreetBirth").combobox("select", StreetDR)
        CheckFlag = "Y"
    }
    if ($("#HomeAddrbox").checkbox('getValue')) { //case "现住":
        if (!AddressInfoIsExpand()) BAddressInoCollapsClick();
        var CountryHouse = $("#CountryHouse").combobox("getValue")
        if (CountryHouse == "") {
            SetCountryComboxData("CountryHouse", CountryDR);
            CountrySelect("CountryHouse", CountryDR);
        }
        $("#ProvinceInfoLookUpRowID").combobox("select", ProvinceDR);
        $("#CityDescLookUpRowID").combobox("select", CityDR);
        $("#CityAreaLookUpRowID").combobox("select", CityAreaDR);
        $("#StreetNow").combobox("select", StreetDR)
        CheckFlag = "Y"
    }
    if ($("#HKAddrbox").checkbox('getValue')) { //case "户口":
        if (!AddressInfoIsExpand()) BAddressInoCollapsClick();
        LoadProvince("ProvinceHouse", CountryDR);
        $("#ProvinceHouse").combobox("select", ProvinceDR);
        $("#Cityhouse").combobox("select", CityDR);
        $("#AreaHouse").combobox("select", CityAreaDR);
        $("#StreetHouse").combobox("select", StreetDR)
        CheckFlag = "Y"
    }
    return true;
}

function OpenWin(AdddressIDStr) {
    $('#EditWindow').window({
        title: $g("地址填充"),
        zIndex: 9999,
        iconCls: 'icon-w-edit',
        inline: false,
        minimizable: false,
        maximizable: false,
        collapsible: false,
        closable: true
    });
    $("#Str").val(AdddressIDStr);
    SetWincheckbox()
}
function UncheckAllClick() {
    $("#BirthAddrbox").checkbox('uncheck');
    $("#HomeAddrbox").checkbox('uncheck');
    $("#HKAddrbox").checkbox('uncheck');
}
function SetWincheckbox() {
	UncheckAllClick()
    var AddrDefType = $("#AddressType").combobox("getValues")

    if (AddrDefType.indexOf('出生') >= 0) {
        $("#BirthAddrbox").checkbox('check');

    }
    if (AddrDefType.indexOf('现住') >= 0) { //case "现住":
        $("#HomeAddrbox").checkbox('check');
    }
    if (AddrDefType.indexOf('户口') >= 0) { //case "户口":
        $("#HKAddrbox").checkbox('check');
    }
}
//
function SelecAllClick() {
    $("#BirthAddrbox").checkbox('check');
    $("#HomeAddrbox").checkbox('check');
    $("#HKAddrbox").checkbox('check');
}

function SelecOtherClick() {
    if ($("#BirthAddrbox").checkbox('getValue')) {
        $("#BirthAddrbox").checkbox('uncheck');
    } else {
        $("#BirthAddrbox").checkbox('check');
    }
    if ($("#HomeAddrbox").checkbox('getValue')) {
        $("#HomeAddrbox").checkbox('uncheck');
    } else {
        $("#HomeAddrbox").checkbox('check');
    }
    if ($("#HKAddrbox").checkbox('getValue')) {
        $("#HKAddrbox").checkbox('uncheck');
    } else {
        $("#HKAddrbox").checkbox('check');
    }
    return;
}

function RealBtnClick() {
    var AdddressIDStr = $("#Str").val()
    var rtn = SetAddressByAddrType(AdddressIDStr)
    if (rtn) $('#EditWindow').window('close');
}

function ShowCardDescDetail(that) {
    var content = that.id;
    MaxHeight = 'auto', placement = "bottom";
    $(that).webuiPopover({
        title: '',
        content: content,
        trigger: 'hover',
        placement: placement,
        style: 'inverse',
        height: MaxHeight

    });
    $(that).webuiPopover('show');
}

function ShowGotoDetail(that) {
    var content = $g("跳转到挂号")
    if ((window.parent) && (window.parent.ServerObj.ParaRegType == "APP")) {
        content =  $g("跳转到预约")
    }
    $(that).webuiPopover({
        title: '',
        content: content,
        trigger: 'hover',
        placement: "top",
        //style:'inverse',
        height: 'auto'

    });
    $(that).webuiPopover('show');
}

function BackRegWindow(PatientID,RegNo) {
    if (typeof window.parent.SetPassCardNo == 'function') {
        window.parent.$("#PatientNo").val(RegNo)
        window.parent.CheckPatientNo()
        window.parent.destroyDialog("CardReg");
    } else {
		var mwin = ("undefined"!=typeof window.websys_getMenuWin_origin)?websys_getMenuWin_origin():websys_getMenuWin(); /*在弹出式界面也强制找到头菜单*/
        if (mwin){
	        var frm = mwin.document.forms['fEPRMENU'];
	        if (frm) {
	            frm.PatientID.value = PatientID;
	        }
        }
        window.opener.clickHeaderMenu({ code: "opadm_reg_hui_reg" });
        window.close()
    }
}

function InitEDUCombo() {
    $.m({
        ClassName: "web.DHCBL.CTBASEIF.ICTCardRegLB",
        MethodName: "GetEDUJsonInfo",
    }, function(Data) {
        var cbox = $HUI.combobox("#Education", {
            valueField: 'id',
            textField: 'text',
            //editable:false,
            data: JSON.parse(Data)
        });
    });
}

function InitLanguageCombo() {
    $.m({
        ClassName: "web.DHCBL.CTBASEIF.ICTCardRegLB",
        MethodName: "GetLANJsonInfo",
    }, function(Data) {
        var cbox = $HUI.combobox("#PAPMILangPrimDR,#PAPMILangSecondDR", {
            valueField: 'id',
            textField: 'text',
            //editable:false,
            width: 115,
            data: JSON.parse(Data)
        });
    });
}

function InitAddressDefCombo() {
    var cbox = $HUI.combobox("#AddressDef", {
        valueField: 'provid',
        textField: 'provdesc',
        editable: true,
        selectOnNavigation: false,
        mode: "remote",
        delay: "500",
        url: $URL + "?ClassName=web.DHCBL.CTBASEIF.ICTCardRegLB&QueryName=admaddressNewlookup&rows=999999",
        onBeforeLoad: function(param) {
            var desc = "";
            if (param['q']) {
                desc = param['q'];
            }
            param = $.extend(param, { desc: desc });
        },
        loadFilter: function(data) {
            return data['rows'];
        },
        onSelect: function(record) {
            if (typeof record == "undefined") { return }
            var AdddressIDStr = ""
            var AdddressIDStr = record.AddressIDStr; //sbq导致读不出病人信息
            if (AdddressIDStr == "") {
                return true;
            }
            var AdddressIDArr = AdddressIDStr.split("^");
            var CountryDR = AdddressIDArr[0];
            var ProvinceDR = AdddressIDArr[1];
            var CityDR = AdddressIDArr[2];
            var CityAreaDR = AdddressIDArr[3];
            var CommunityDR = AdddressIDArr[4];
            if (this.id == "AddressDef") {
                var winEvent = window.event;
                var mykey = winEvent.keyCode;
                if (mykey == 13) {
                    PageLogicObj.m_ShowWindowFlag = ""
                }
                OpenWin(AdddressIDStr)
            }
            return true;
        }
    });
    //$("#Address").combobox("resize","625");
}

function CheckInHos() {
    var PAPMIRowID = $("#PAPMIRowID").val();
    var InHosFlag = $.cm({
        ClassName: "web.DHCDocOrderCommon",
        MethodName: "CheckPatInIPAdmission",
        PatientID: PAPMIRowID,
        HospID: session['LOGON.HOSPID'],
        dataType: "text"
    }, false);
    if (InHosFlag == 1) {
        $.messager.alert('提示', '患者住院期间请到住院登记界面修改患者信息!', "info");
        return false;
    }
    return true;
}
///如果国籍中维护了默认语言可以讲语言默认到母语1上
function DefLanguage(CountryID) {
    if (CountryID == "") {
        var CountryID = $("#CountryDescLookUpRowID").combobox('getValue');
        if (CountryID == "") return;
    }
    $.m({
        ClassName: "web.DHCBL.CTBASEIF.ICTCardRegLB",
        MethodName: "GetDefLanByCountry",
        CountryID: CountryID
    }, function(Data) {
        $("#PAPMILangPrimDR").combobox('select', Data);
    });
    return true;
}

function ReadLinkRegInfoOnClick() {
    var myHCTypeDR = $("#IEType").combobox("getValue");
    var myInfo = DHCWCOM_PersonInfoRead(myHCTypeDR);
    var myary = myInfo.split("^");
    if (myary[0] == "0") {
        var XMLStr = "<?xml version='1.0' encoding='gb2312'?>" + myary[1];
        var xmlDoc = DHCDOM_CreateXMLDOMNew(XMLStr);
        if (!xmlDoc) return;
        var nodes = xmlDoc.documentElement.childNodes;
        if (nodes.length <= 0) { return; }
        var CredTypeID = "";
        for (var i = 0; i < nodes.length; i++) {
            var myItemName = getNodeName(nodes, i);
            var myItemValue = getNodeValue(nodes, i);
            if (myItemName == "Name") $("#ForeignName").val(myItemValue);
            if (myItemName == "Address") $("#ForeignAddress").val(myItemValue);
            if (myItemName == "CredNo") $("#ForeignIDCard").val(myItemValue);
            if (myItemName == "CredType") CredTypeID = myItemValue;
        }
        SelectCredType("ForeignCredType", CredTypeID, PageLogicObj.m_CredTypeID);
        if ($(".baseinfo").css("display") == "none") {
            $(".baseinfo-div").removeClass("baseinfo-collapse").addClass("baseinfo-expand");
            $(".baseinfo").show();
            $("#BBaseInoCollaps .l-btn-text")[0].innerText = "隐藏全部";
        }
        $("#ForeignPhone").focus()
    }
}

function SelectCredType(ElementID, CredTypeID, DefaultID) {
    var _id = $("#" + ElementID);
    if (_id.length < 1) return;
    if (CredTypeID != "") {
        var Data = _id.combobox("getData");
        for (var m = 0; m < Data.length; m++) {
            var id = Data[m]["id"];
            var text = Data[m]["text"];
            if (CredTypeID == id.split("^")[0]) {
                _id.combobox("select", id);
                break;
            }
        }
    } else {
        _id.combobox("select", DefaultID);
    }
    return true;
}

function ShowOtherNamePopover(that) {
    var content = $g("多类型姓名管理")
    
    $(that).webuiPopover({
        title: '',
        content: content,
        trigger: 'hover',
        //style:'inverse',
        height: 'auto'

    });
    $(that).webuiPopover('show');
}

function OtherNameclick(that) {
	var src = "doc.othernametype.hui.csp?OtherNameInfo=" + $("#OtherNameInfo").val();;
    src=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(src):src;
    var $code = "<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='" + src + "'></iframe>";
    createModalDialog("OtherNameInfoManager", $g("多类型姓名管理"), "500", "290", "icon-w-list", "", $code, "");
}

function NameTypeSave(newData) {
    $("#OtherNameInfo").val(newData);
}
function ChangeCardClick() {
	var row=PageLogicObj.m_FindPatListTabDataGrid.datagrid('getSelected');
	var RegNo=""
	if (row) RegNo=row["RegNo"];
	var src = "reg.cardmanagement.hui.csp?RegNo=" + RegNo;
    src=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(src):src;
    var $code = "<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='" + src + "'></iframe>";
    createModalDialog("cardmanagement",$g("卡操作"), 1360  , PageLogicObj.dh, "icon-edit", "", $code, "");
}
function BirthOnKeyDown(e){
	var key = websys_getKey(e);
    if (key == 13) {
	    return BirthOnBlur()
	}
}

function CheckRegCardNo(PatInfoXML) {
    var XMLStr = "<?xml version='1.0' encoding='gb2312'?>" + PatInfoXML;
    var xmlDoc = DHCDOM_CreateXMLDOMNew(XMLStr);
    if (xmlDoc) {
        var nodes = xmlDoc.documentElement.childNodes;
        if (nodes.length > 0) {
            for (var i = 0; i < nodes.length; i++) {
                var myItemName = getNodeName(nodes, i);
                var myItemValue = getNodeValue(nodes, i);
                if ((myItemName == "CardTypeDesc") && (myItemValue != "")) {
                    var CardType = $.cm({
                        ClassName: "web.DHCPATCardUnite",
                        MethodName: "ReadCardTypeByDesc",
                        Desc: myItemValue,
                        dataType: "text"
                    }, false)
                    $("#CardTypeDefine").combobox('select', CardType);
                }
                if ((myItemName == "CardNo") && (myItemValue != "")) {
                    //确保默认完卡类型后才调用
                    var myCardNo=myItemValue;
                    setTimeout(function() {
                        $("#CardNo").val(myCardNo);
                        GetValidatePatbyCard();
                    })
                }
            }
        }
    }
}
