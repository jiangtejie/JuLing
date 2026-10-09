/*
 * @author 亚特
 * address https://github.com/igdianov/activiti-bpmn-moddle
 * */

import activitiExtension from './activitiExtension';

export default {
  __init__: ['ActivitiModdleExtension'],
  ActivitiModdleExtension: ['type', activitiExtension],
};
