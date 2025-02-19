new Promise(function(resolve,rejected){
    DHCP_GetXMLConfig("DepositPrintEncrypt", PatInfoXMLPrint);
    DHC_PrintByLodop(getLodop(), TxtInfo, ListInfo, "", "");
    resolve();
}).then(function() {
    // 如果HospId为2，则设置一个延迟来执行第二次打印
    if (HospId == 2) {
    // 延迟一段时间（例如2000毫秒）后执行EmrCardPrint函数
    setTimeout(EmrCardPrint, 8000);
}
})

// 延迟一段时间（例如2000毫秒）后执行EmrCardPrint函数
setTimeout(() => billPrintTask(PrtId), 2000);