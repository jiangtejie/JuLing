<script lang="ts" setup>
  import type { MenuRecordRaw } from '@vben/types';

  import type { BpmTaskApi } from '#/api/bpm/task';

  import { computed, onMounted, ref } from 'vue';

  import { useAccess } from '@vben/access';
  import { Page } from '@vben/common-ui';
  import { IconifyIcon } from '@vben/icons';
  import { useAccessStore, useUserStore } from '@vben/stores';

  import { useNow } from '@vueuse/core';
  import {
    Avatar,
    Button,
    Card,
    Col,
    Empty,
    Row,
    Spin,
    Tag,
  } from 'ant-design-vue';

  import { getTaskTodoPage } from '#/api/bpm/task';
  import { router } from '#/router';

  defineOptions({ name: 'Home' });

  const userStore = useUserStore();
  const accessStore = useAccessStore();
  const { hasAccessByCodes } = useAccess();

  /** 本页路径（快捷入口里排除自己） */
  const HOME_PATH = '/home';

  /** 实时时钟（每秒刷新） */
  const now = useNow({ interval: 1000 });

  const user = computed(() => userStore.userInfo ?? ({} as any));
  const displayName = computed(
    () => user.value.nickname || user.value.username || '朋友',
  );

  /** 按时间问候 */
  const greeting = computed(() => {
    const hour = now.value.getHours();
    if (hour < 6) return '夜深了';
    if (hour < 9) return '早上好';
    if (hour < 12) return '上午好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  });

  const WEEKDAYS = ['日', '一', '二', '三', '四', '五', '六'];
  const pad = (value: number) => String(value).padStart(2, '0');

  const dateText = computed(() => {
    const d = now.value;
    return `${d.getFullYear()} 年 ${d.getMonth() + 1} 月 ${d.getDate()} 日 星期${WEEKDAYS[d.getDay()]}`;
  });
  const timeText = computed(
    () => `${pad(now.value.getHours())}:${pad(now.value.getMinutes())}:${pad(now.value.getSeconds())}`,
  );

  /**
   * 快捷入口：取当前账号菜单里的叶子页面（即真正能打开的页面），最多 8 个。
   * 只展示有权限的菜单，避免点了跳 403；菜单来自后端，人人不同。
   */
  const shortcuts = computed(() => {
    const result: { icon?: string; name: string; path: string }[] = [];
    const walk = (items: MenuRecordRaw[]) => {
      for (const item of items ?? []) {
        if (result.length >= 8) return;
        const children = item.children ?? [];
        if (children.length > 0) {
          walk(children);
        } else if (item.path && item.path !== HOME_PATH) {
          // 排除欢迎页自身，快捷入口只放「要去做事」的页面
          result.push({
            icon: item.icon,
            name: item.name,
            path: item.path,
          });
        }
      }
    };
    walk(accessStore.accessMenus as MenuRecordRaw[]);
    return result;
  });

  /**
   * 角色：接口只给角色编码。
   * - `common`（普通角色）是所有账号都有的兜底角色，展示时过滤掉，避免噪音；
   * - `super_admin` 给个中文名；其余业务角色没有稳定中文名（角色是后台自建的），直接显示编码。
   */
  const ROLE_LABELS: Record<string, string> = { super_admin: '超级管理员' };
  const roles = computed(() =>
    (userStore.userRoles ?? [])
      .filter((role) => role !== 'common')
      .map((role) => ({ code: role, label: ROLE_LABELS[role] ?? role })),
  );

  /** 使用提示（与具体模块无关，人人适用） */
  const tips = [
    '顶部搜索框（Ctrl + K）可以按菜单名快速跳转任意功能页。',
    '菜单按角色分配：看不到某个功能，说明当前账号没有对应权限，可联系管理员在「系统管理 → 角色」中勾选。',
    '商城订单收到客户转账凭证后，需要在「商城系统 → 订单列表」核验收款，订单才会进入发货流程。',
    '遇到「系统异常」时记下操作时间，管理员可据此定位后端日志。',
  ];

  /**
   * 我的审批待办：只查当前登录人自己的待办任务，作为快捷入口用。
   * - 没有 bpm:task:query 权限的账号整张卡片不渲染，避免点进去 403；
   * - 进入首页只加载一次，其余靠卡片右上角的刷新按钮，不做轮询。
   */
  const TODO_PAGE_SIZE = 5;
  const TODO_PATH = '/bpm/task/todo';

  const canQueryTodo = computed(() => hasAccessByCodes(['bpm:task:query']));
  const todoList = ref<BpmTaskApi.Task[]>([]);
  const todoTotal = ref(0);
  const todoLoading = ref(false);
  const todoFailed = ref(false);

  /** 发起时间：后端给的是时间戳，这里只到分钟，卡片位置窄 */
  const formatDateTime = (value?: null | number | string) => {
    if (!value) return '-';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '-';
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
  };

  async function loadTodos() {
    if (!canQueryTodo.value || todoLoading.value) return;
    todoLoading.value = true;
    todoFailed.value = false;
    try {
      const data = await getTaskTodoPage({
        pageNo: 1,
        pageSize: TODO_PAGE_SIZE,
      });
      todoList.value = data?.list ?? [];
      todoTotal.value = data?.total ?? todoList.value.length;
    } catch {
      // 待办只是首页的一块小入口，失败不影响其它区块，卡片内给一句提示即可
      todoList.value = [];
      todoTotal.value = 0;
      todoFailed.value = true;
    } finally {
      todoLoading.value = false;
    }
  }

  /** 办理任务：与「待办任务」页面保持同一套跳转方式 */
  function openTodo(task: BpmTaskApi.Task) {
    if (!task.processInstance?.id) return;
    router.push({
      name: 'BpmProcessInstanceDetail',
      query: {
        id: task.processInstance.id,
        taskId: task.id,
      },
    });
  }

  onMounted(() => {
    loadTodos();
  });
</script>

<template>
  <Page auto-content-height>
    <div class="home">
      <!-- 欢迎横幅 -->
      <div class="home__banner">
        <Avatar :size="64" :src="user.avatar">
          {{ displayName.slice(0, 1) }}
        </Avatar>
        <div class="home__banner-text">
          <div class="home__title">
            {{ greeting }}，{{ displayName }}！欢迎使用亚特管理系统
          </div>
          <div class="home__subtitle">
            今天是 {{ dateText }} · 当前时间 {{ timeText }}
          </div>
          <div class="home__subtitle">
            左侧菜单是你当前账号可用的功能（按角色分配），下面的快捷入口按使用习惯挑选。
          </div>
        </div>
      </div>

      <Row :gutter="16">
        <Col :lg="16" :xs="24">
          <Card :bordered="false" size="small" title="快捷入口">
            <Empty v-if="shortcuts.length === 0" description="当前账号还没有可用菜单" />
            <div v-else class="home__grid">
              <RouterLink
                v-for="item in shortcuts"
                :key="item.path"
                :to="item.path"
                class="home__shortcut"
              >
                <IconifyIcon
                  :icon="item.icon || 'lucide:layout-grid'"
                  class="home__shortcut-icon"
                />
                <span class="home__shortcut-name">{{ item.name }}</span>
              </RouterLink>
            </div>
          </Card>
        </Col>

        <Col :lg="8" :xs="24">
          <Card :bordered="false" size="small" title="我的账号">
            <div class="home__account">
              <span class="home__label">昵称</span>
              <span>{{ user.nickname || '-' }}</span>
            </div>
            <div class="home__account">
              <span class="home__label">账号</span>
              <span>{{ user.username || '-' }}</span>
            </div>
            <div class="home__account">
              <span class="home__label">角色</span>
              <span>
                <template v-if="roles.length > 0">
                  <Tag v-for="role in roles" :key="role.code" color="blue">
                    {{ role.label }}
                  </Tag>
                </template>
                <template v-else>-</template>
              </span>
            </div>
          </Card>

          <Card
            :bordered="false"
            class="home__tips-card"
            size="small"
            title="使用提示"
          >
            <ul class="home__tips">
              <li v-for="tip in tips" :key="tip">{{ tip }}</li>
            </ul>
          </Card>

          <!-- 我的审批待办：只查当前登录人自己的待办，作为快捷入口 -->
          <Card
            v-if="canQueryTodo"
            :bordered="false"
            class="home__todo-card"
            size="small"
          >
            <template #title>
              <span class="home__todo-title">我的审批待办</span>
              <span v-if="!todoFailed" class="home__todo-count">
                {{ todoTotal }}
              </span>
            </template>
            <template #extra>
              <Button
                :loading="todoLoading"
                size="small"
                type="link"
                @click="loadTodos"
              >
                刷新
              </Button>
            </template>

            <div v-if="todoFailed" class="home__todo-hint">
              待办加载失败，可点右上角「刷新」重试。
            </div>
            <div v-else-if="todoLoading && todoList.length === 0" class="home__todo-loading">
              <Spin size="small" />
            </div>
            <!-- 深色主题下 antd 的空状态插图是近黑色，这里只用文字，保持卡片干净 -->
            <Empty
              v-else-if="todoList.length === 0"
              :image="false"
              description="暂无待办"
            />
            <ul v-else class="home__todo-list">
              <li v-for="task in todoList" :key="task.id">
                <button
                  class="home__todo-item"
                  type="button"
                  @click="openTodo(task)"
                >
                  <span class="home__todo-item-head">
                    <span class="home__todo-item-name">{{ task.name }}</span>
                    <span class="home__todo-item-time">
                      {{ formatDateTime(task.processInstance?.createTime) }}
                    </span>
                  </span>
                  <span class="home__todo-item-meta">
                    {{ task.processInstance?.name || '未命名流程' }} ·
                    {{ task.processInstance?.startUser?.nickname || '未知发起人' }}
                  </span>
                </button>
              </li>
            </ul>

            <div class="home__todo-more">
              <RouterLink :to="TODO_PATH">查看全部</RouterLink>
            </div>
          </Card>
        </Col>
      </Row>
    </div>
  </Page>
</template>

<style scoped lang="scss">
  .home {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .home__banner {
    display: flex;
    gap: 20px;
    align-items: center;
    padding: 24px;
    color: #fff;
    background: linear-gradient(135deg, hsl(var(--primary)) 0%, hsl(var(--primary) / 70%) 100%);
    border-radius: 8px;

    /* 头像在深色底上更清楚 */
    :deep(.ant-avatar) {
      color: hsl(var(--primary));
      background-color: #fff;
    }
  }

  .home__banner-text {
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .home__title {
    font-size: 20px;
    font-weight: 600;
    line-height: 1.4;
  }

  .home__subtitle {
    font-size: 13px;
    opacity: 0.85;
  }

  .home__grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
    gap: 12px;
  }

  .home__shortcut {
    display: flex;
    gap: 8px;
    align-items: center;
    padding: 12px 14px;
    color: hsl(var(--foreground));
    background-color: hsl(var(--accent));
    border-radius: 6px;
    transition:
      color 0.2s,
      background-color 0.2s,
      transform 0.2s;

    &:hover {
      color: hsl(var(--primary));
      background-color: hsl(var(--primary) / 12%);
      transform: translateY(-1px);
    }
  }

  .home__shortcut-icon {
    flex: none;
    font-size: 18px;
  }

  .home__shortcut-name {
    overflow: hidden;
    font-size: 13px;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .home__account {
    display: flex;
    gap: 8px;
    align-items: center;
    padding: 6px 0;
    font-size: 13px;
  }

  .home__label {
    flex: none;
    width: 40px;
    color: hsl(var(--muted-foreground));
  }

  .home__tips-card {
    margin-top: 16px;
  }

  .home__tips {
    padding-left: 18px;
    margin: 0;
    font-size: 13px;
    line-height: 1.9;
    color: hsl(var(--muted-foreground));
    list-style: disc;
  }

  .home__todo-card {
    margin-top: 16px;
  }

  .home__todo-count {
    display: inline-block;
    min-width: 20px;
    margin-left: 8px;
    font-size: 12px;
    font-weight: 500;
    line-height: 18px;
    color: hsl(var(--primary));
    text-align: center;
    background-color: hsl(var(--primary) / 12%);
    border-radius: 9px;
  }

  .home__todo-list {
    padding: 0;
    margin: 0;
    list-style: none;

    li + li {
      margin-top: 2px;
    }
  }

  .home__todo-item {
    display: flex;
    flex-direction: column;
    gap: 4px;
    width: 100%;
    padding: 8px 10px;
    font-size: 13px;
    color: hsl(var(--foreground));
    text-align: left;
    cursor: pointer;
    background-color: transparent;
    border: 0;
    border-radius: 6px;
    transition: background-color 0.2s;
  }

  .home__todo-item:hover {
    background-color: hsl(var(--primary) / 12%);
  }

  .home__todo-item-head {
    display: flex;
    gap: 8px;
    align-items: baseline;
    justify-content: space-between;
  }

  .home__todo-item-name {
    overflow: hidden;
    font-weight: 500;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .home__todo-item-time {
    flex: none;
    font-size: 12px;
    color: hsl(var(--muted-foreground));
  }

  .home__todo-item-meta {
    overflow: hidden;
    font-size: 12px;
    color: hsl(var(--muted-foreground));
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .home__todo-more {
    padding-top: 8px;
    margin-top: 8px;
    font-size: 13px;
    text-align: center;
    border-top: 1px solid hsl(var(--border) / 60%);
  }

  .home__todo-hint,
  .home__todo-loading {
    padding: 12px 0;
    font-size: 13px;
    color: hsl(var(--muted-foreground));
    text-align: center;
  }

  .home__todo-card :deep(.ant-empty) {
    margin: 0;
    font-size: 13px;
  }
</style>
