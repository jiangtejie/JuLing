import type { FormValues } from '@vben/common-ui';
import type { VxeTableGridOptions } from '@vben/plugins/vxe-table';
import type { Recordable } from '@vben/types';

import type { ComponentPropsMap, ComponentType } from './component';

import { h, onActivated, onDeactivated } from 'vue';

import { IconifyIcon } from '@vben/icons';
import { $te } from '@vben/locales';
import {
  AsyncVxeColumn,
  AsyncVxeTable,
  createRequiredValidation,
  setupVbenVxeTable,
  useVbenVxeGrid as useGrid,
} from '@vben/plugins/vxe-table';
import {
  erpCountInputFormatter,
  erpNumberFormatter,
  fenToYuan,
  formatFileSize,
  formatPast2,
  isFunction,
  isString,
} from '@vben/utils';

import {
  Button,
  Image,
  ImagePreviewGroup,
  Popconfirm,
  Switch,
  Tag,
} from 'ant-design-vue';

import { DictTag } from '#/components/dict-tag';
import { $t } from '#/locales';

import { useVbenForm } from './form';

setupVbenVxeTable({
  configVxeTable: (vxeUI) => {
    vxeUI.setConfig({
      grid: {
        align: 'center',
        border: false,
        columnConfig: {
          resizable: true,
        },
        minHeight: 180,
        formConfig: {
          // 全局禁用vxe-table的表单配置，使用formOptions
          enabled: false,
        },
        toolbarConfig: {
          import: false, // 是否导入
          export: false, // 是否导出
          refresh: true, // 是否刷新
          print: false, // 是否打印
          zoom: true, // 是否缩放
          custom: true, // 是否自定义配置
        },
        customConfig: {
          mode: 'modal',
        },
        proxyConfig: {
          autoLoad: true,
          response: {
            result: 'list',
            total: 'total',
          },
          showActiveMsg: true,
          showResponseMsg: false,
        },
        pagerConfig: {
          enabled: true,
        },
        sortConfig: {
          multiple: true,
        },
        round: true,
        showOverflow: true,
        size: 'small',
      } as VxeTableGridOptions,
    });

    // 表格配置项可以用 cellRender: { name: 'CellImage' },
    vxeUI.renderer.add('CellImage', {
      renderTableDefault(renderOpts, params) {
        const { props } = renderOpts;
        const { column, row } = params;
        return h(Image, { src: row[column.field], ...props });
      },
    });

    vxeUI.renderer.add('CellImages', {
      renderTableDefault(_renderOpts, params) {
        const { column, row } = params;
        if (column && column.field && row[column.field]) {
          return h(ImagePreviewGroup, {}, () => {
            return row[column.field].map((item: any) =>
              h(Image, { src: item }),
            );
          });
        }
        return '';
      },
    });

    // 表格配置项可以用 cellRender: { name: 'CellLink' },
    vxeUI.renderer.add('CellLink', {
      renderTableDefault(renderOpts) {
        const { props } = renderOpts;
        return h(
          Button,
          { size: 'small', type: 'link' },
          { default: () => props?.text },
        );
      },
    });

    // 表格配置项可以用 cellRender: { name: 'CellTag' },
    vxeUI.renderer.add('CellTag', {
      renderTableDefault(renderOpts, params) {
        const { props } = renderOpts;
        const { column, row } = params;
        return h(Tag, { color: props?.color }, () => row[column.field]);
      },
    });

    vxeUI.renderer.add('CellTags', {
      renderTableDefault(renderOpts, params) {
        const { props } = renderOpts;
        const { column, row } = params;
        if (!row[column.field] || row[column.field].length === 0) {
          return '';
        }
        return h(
          'div',
          { class: 'flex items-center justify-center' },
          {
            default: () =>
              row[column.field].map((item: any) =>
                h(Tag, { color: props?.color }, { default: () => item }),
              ),
          },
        );
      },
    });

    // 表格配置项可以用 cellRender: { name: 'CellDict', props:{dictType: ''} },
    vxeUI.renderer.add('CellDict', {
      renderTableDefault(renderOpts, params) {
        const { props } = renderOpts;
        const { column, row } = params;
        if (!props) {
          return '';
        }
        // 使用 DictTag 组件替代原来的实现
        return h(DictTag, {
          type: props.type,
          value: row[column.field]?.toString(),
        });
      },
    });

    // 表格配置项可以用 cellRender: { name: 'CellSwitch', props: { beforeChange: () => {} } },
    // add by 亚特：from https://github.com/vbenjs/vue-vben-admin/blob/main/playground/src/adapter/vxe-table.ts#L97-L123
    vxeUI.renderer.add('CellSwitch', {
      renderTableDefault({ attrs, props }, { column, row }) {
        const loadingKey = `__loading_${column.field}`;
        const finallyProps = {
          checkedChildren: $t('common.enabled'),
          checkedValue: 1,
          unCheckedChildren: $t('common.disabled'),
          unCheckedValue: 0,
          ...props,
          checked: row[column.field],
          loading: row[loadingKey] ?? false,
          'onUpdate:checked': onChange,
        };

        async function onChange(newVal: any) {
          row[loadingKey] = true;
          try {
            const result = await attrs?.beforeChange?.(newVal, row);
            if (result !== false) {
              row[column.field] = newVal;
            }
          } finally {
            row[loadingKey] = false;
          }
        }

        return h(Switch, finallyProps);
      },
    });

    // 注册表格的操作按钮渲染器 cellRender: { name: 'CellOperation', options: ['edit', 'delete'] }
    // add by 亚特：from https://github.com/vbenjs/vue-vben-admin/blob/main/playground/src/adapter/vxe-table.ts#L125-L255
    vxeUI.renderer.add('CellOperation', {
      renderTableDefault({ attrs, options, props }, { column, row }) {
        const defaultProps = { size: 'small', type: 'link', ...props };
        let align: string;
        switch (column.align) {
          case 'center': {
            align = 'center';
            break;
          }
          case 'left': {
            align = 'start';
            break;
          }
          default: {
            align = 'end';
            break;
          }
        }
        const presets: Recordable<Recordable<any>> = {
          delete: {
            danger: true,
            text: $t('common.delete'),
          },
          edit: {
            text: $t('common.edit'),
          },
        };
        const operations: Array<Recordable<any>> = (
          options || ['edit', 'delete']
        )
          .map((opt) => {
            if (isString(opt)) {
              return presets[opt]
                ? { code: opt, ...presets[opt], ...defaultProps }
                : {
                    code: opt,
                    text: $te(`common.${opt}`) ? $t(`common.${opt}`) : opt,
                    ...defaultProps,
                  };
            } else {
              return { ...defaultProps, ...presets[opt.code], ...opt };
            }
          })
          .map((opt) => {
            const optBtn: Recordable<any> = {};
            Object.keys(opt).forEach((key) => {
              optBtn[key] = isFunction(opt[key]) ? opt[key](row) : opt[key];
            });
            return optBtn;
          })
          .filter((opt) => opt.show !== false);

        function renderBtn(opt: Recordable<any>, listen = true) {
          return h(
            Button,
            {
              ...props,
              ...opt,
              icon: undefined,
              onClick: listen
                ? () =>
                    attrs?.onClick?.({
                      code: opt.code,
                      row,
                    })
                : undefined,
            },
            {
              default: () => {
                const content = [];
                if (opt.icon) {
                  content.push(
                    h(IconifyIcon, { class: 'size-5', icon: opt.icon }),
                  );
                }
                content.push(opt.text);
                return content;
              },
            },
          );
        }

        function renderConfirm(opt: Recordable<any>) {
          return h(
            Popconfirm,
            {
              getPopupContainer(el) {
                return el.closest('tbody') || document.body;
              },
              placement: 'topLeft',
              title: $t('ui.actionTitle.delete', [attrs?.nameTitle || '']),
              ...props,
              ...opt,
              icon: undefined,
              onConfirm: () => {
                attrs?.onClick?.({
                  code: opt.code,
                  row,
                });
              },
            },
            {
              default: () => renderBtn({ ...opt }, false),
              description: () =>
                h(
                  'div',
                  { class: 'truncate' },
                  $t('ui.actionMessage.deleteConfirm', [
                    row[attrs?.nameField || 'name'],
                  ]),
                ),
            },
          );
        }

        const btns = operations.map((opt) =>
          opt.code === 'delete' ? renderConfirm(opt) : renderBtn(opt),
        );
        return h(
          'div',
          {
            class: 'flex table-operations',
            style: { justifyContent: align },
          },
          btns,
        );
      },
    });

    // 这里可以自行扩展 vxe-table 的全局配置，比如自定义格式化
    // vxeUI.formats.add

    vxeUI.formats.add('formatPast2', {
      tableCellFormatMethod({ cellValue }) {
        return formatPast2(cellValue);
      },
    });

    // add by 星语：数量格式化，保留 3 位
    vxeUI.formats.add('formatAmount3', {
      tableCellFormatMethod({ cellValue }) {
        return erpCountInputFormatter(cellValue);
      },
    });
    // add by 星语：数量格式化，保留 2 位
    vxeUI.formats.add('formatAmount2', {
      tableCellFormatMethod({ cellValue }, digits = 2) {
        return `${erpNumberFormatter(cellValue, digits)}`;
      },
    });

    vxeUI.formats.add('formatFenToYuanAmount', {
      tableCellFormatMethod({ cellValue }, digits = 2) {
        return `${erpNumberFormatter(fenToYuan(cellValue), digits)}`;
      },
    });

    // add by 星语：文件大小格式化
    vxeUI.formats.add('formatFileSize', {
      tableCellFormatMethod({ cellValue }, digits = 2) {
        return formatFileSize(cellValue, digits);
      },
    });
  },
  useVbenForm,
});

export { createRequiredValidation };

export const [VxeTable, VxeColumn] = [AsyncVxeTable, AsyncVxeColumn];

export * from '#/components/table-action';
export const useVbenVxeGrid = <
  T extends Record<string, any>,
  TFormValues extends FormValues = FormValues,
  TSubmitValues extends FormValues = TFormValues,
>(
  ...rest: Parameters<
    typeof useGrid<
      T,
      ComponentType,
      ComponentPropsMap,
      TFormValues,
      TSubmitValues
    >
  >
) => {
  const result = useGrid<
    T,
    ComponentType,
    ComponentPropsMap,
    TFormValues,
    TSubmitValues
  >(...rest);

  /**
   * 页签缓存下的「回到列表自动刷新」。
   *
   * vben 的多页签会把已打开的页面 KeepAlive 缓存，列表页从详情页返回时不会重新 mount，
   * 于是在别的页面改过的数据（订单状态、收款状态、核验结果等）在列表里看不到旧值。
   * 这里统一在页面重新激活时刷新一次，避免每个列表页各写一遍。
   *
   * 注意：
   * 1. 只有配置了 proxyConfig.ajax.query 的表格（真正的远程列表）才刷新，
   *    详情页里用 setGridOptions 灌数据的静态表格不参与，避免无谓请求与报错；
   * 2. 为什么不用「首次 onActivated 直接跳过」的写法：布局的
   *    <KeepAlive :include="getCachedTabs"> 里，cachedTabs 由 tabbar store 在路由跳转之后
   *    异步写入，首次进入某路由时组件已挂载而 include 里还没有当前路由名，KeepAlive 不会给
   *    该实例打缓存标记，Vue 挂载时也就不会触发 onActivated（是否触发取决于写入与 vnode
   *    创建是否同帧，属竞态、因页面而异）。于是「首次 onActivated 跳过」会把这个竞态
   *    反过来用：首屏恰好触发过 activated 的页面（如 /bpm/manager/form）第一次切回能刷新，
   *    而首屏没触发的页面（如 /mall/trade/order）第一次切回会被当成首屏吞掉、第二次切回才
   *    刷新 —— 第一次切回的刷新是真的丢了。
   * 3. 统一改写为与 #/utils/usePageActivateLoad 一致的守卫：只有实例确实被 KeepAlive
   *    冻结过（onDeactivated 触发）再激活，才刷新一次。onDeactivated / onActivated 只在
   *    KeepAlive 缓存内触发，未缓存的普通页面（无 KeepAlive 包裹）两者都不触发，
   *    因此非缓存场景不会多出任何请求。
   */
  const hasProxyQuery = Boolean(
    (rest[0] as undefined | { gridOptions?: VxeTableGridOptions })?.gridOptions
      ?.proxyConfig?.ajax?.query,
  );
  if (hasProxyQuery) {
    /** 是否曾经被页签缓存「冻结」过，用于区分首次挂载（或未被缓存）与切回页签 */
    let deactivated = false;
    onDeactivated(() => {
      deactivated = true;
    });
    onActivated(() => {
      if (!deactivated) {
        return;
      }
      deactivated = false;
      try {
        void Promise.resolve(result[1].query()).catch(() => {
          // 刷新失败由表格自身的错误提示兜住，这里不再打扰用户
        });
      } catch {
        // query 不可用时忽略（例如页面已被销毁）
      }
    });
  }
  return result;
};

export type * from '@vben/plugins/vxe-table';
