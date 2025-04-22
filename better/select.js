const $input = $(`input[name='hemo'][value="${hemo}"]`);
$input.prop('checked', true);
$input.siblings('label').first().addClass('checked'); // 只选中第一个同级 label

$input.prop('checked', true);
$input.next('label').addClass('checked'); // 直接选择 input 后的第一个 label

$input.prop('checked', true);
$input.prev('label').addClass('checked'); // 选择 input 前的第一个 label