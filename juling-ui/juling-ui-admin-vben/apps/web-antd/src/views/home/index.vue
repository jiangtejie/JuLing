<script lang="ts" setup>
  import type { MenuRecordRaw } from '@vben/types';

  import { computed } from 'vue';

  import { Page } from '@vben/common-ui';
  import { IconifyIcon } from '@vben/icons';
  import { useAccessStore, useUserStore } from '@vben/stores';

  import { Avatar, Card, Col, Empty, Row, Tag } from 'ant-design-vue';

  import { useNow } from '@vueuse/core';

  defineOptions({ name: 'Home' });

  const userStore = useUserStore();
  const accessStore = useAccessStore();

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
</style>
