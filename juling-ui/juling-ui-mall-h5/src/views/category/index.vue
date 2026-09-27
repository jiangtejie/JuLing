<script setup lang="ts">
  import { showToast } from 'vant';
  import { addCart } from '@/api/cart';
  import { getCategoryTree, getProductDetail, getProductPage } from '@/api/product';
  import type { Category, Product } from '@/types';
  import { useCartStore } from '@/stores/cart';
  import { useUserStore } from '@/stores/user';
  import { formatCount } from '@/utils/format';
  import { resolveImage } from '@/utils/image';

  defineOptions({ name: 'Category' });

  const router = useRouter();
  const cartStore = useCartStore();
  const userStore = useUserStore();

  /** 一级分类（带 children，见 api/product.ts 的 getCategoryTree） */
  const categories = ref<Category[]>([]);
  /** van-sidebar 的 v-model 是「索引」而非业务 id */
  const activeIndex = ref(0);
  /** 搜索关键词：提交后跳商品列表页展示结果 */
  const keyword = ref('');
  /** 正在快速加购的商品 id：既防重复点击，也用于按钮的 loading 态 */
  const addingId = ref<number>();

  const { list, loading, finished, error, refreshing, total, onLoad, onRefresh, search } =
    usePaging<Product, { categoryId?: number }>((params) => getProductPage(params), {
      immediate: false,
    });

  const activeCategory = computed(() => categories.value[activeIndex.value]);
  const activeName = computed(() => activeCategory.value?.name ?? '');
  /** 当前一级分类下的二级分类 */
  const subCategories = computed(() => activeCategory.value?.children ?? []);
  /** 有二级分类时，右侧按二级分组展示 */
  const grouped = computed(() => subCategories.value.length > 0);

  interface ProductGroup {
    id: number;
    name: string;
    items: Product[];
  }

  /**
   * 右侧商品按二级分类分组。
   *
   * 后端 `/product/spu/page?categoryId=<一级 id>` 会连同子分类的商品一起返回
   * （ProductSpuServiceImpl 里做了 categoryId + children 的展开），所以这里
   * 只按商品自身的 categoryId 归组即可，不必逐个二级分类发请求。
   */
  const groups = computed<ProductGroup[]>(() => {
    const root = activeCategory.value;
    if (!root) return [];
    const rows = list.value;

    // 没有二级分类：保持平铺，不再多一层分组标题
    if (!subCategories.value.length) {
      return rows.length ? [{ id: root.id, name: root.name, items: rows }] : [];
    }

    const sections: ProductGroup[] = [
      // 直接挂在一级分类上的商品
      { id: root.id, name: root.name, items: [] },
      ...subCategories.value.map((item) => ({ id: item.id, name: item.name, items: [] })),
    ];
    const byId = new Map(sections.map((section) => [section.id, section]));

    const rest: Product[] = [];
    rows.forEach((product) => {
      const section = product.categoryId === undefined ? undefined : byId.get(product.categoryId);
      if (section) section.items.push(product);
      else rest.push(product);
    });
    if (rest.length) sections.push({ id: -1, name: '其他', items: rest });

    return sections.filter((section) => section.items.length);
  });

  /** 订货单非空时才展示底部动作栏（同时决定内容区避让高度） */
  const hasCartItems = computed(() => cartStore.totalKinds > 0);

  async function init(): Promise<void> {
    try {
      categories.value = await getCategoryTree();
      const first = categories.value[0];
      if (first) await search({ categoryId: first.id });
    } catch (err) {
      // 错误提示由请求层统一处理，这里仅留痕，避免未捕获的 Promise rejection
      console.warn('[category] 初始化失败:', err);
    }
  }

  async function onSelect(index: number): Promise<void> {
    const category = categories.value[index];
    if (!category) return;
    await search({ categoryId: category.id });
  }

  /** 搜索商品：跳到商品列表页（该页自带搜索框，可继续改词） */
  function onSearch(): void {
    void router.push({
      path: '/product/list',
      query: keyword.value ? { keyword: keyword.value } : {},
    });
  }

  function toDetail(id: number): void {
    void router.push(`/product/${id}`);
  }

  /**
   * 快速加入订货单（卡片右下角按钮）。
   *
   * 列表接口不返回 SKU，所以单规格商品这里补一次详情请求取唯一 SKU：
   * 与详情页共用同一套 addItem + addCart 同步逻辑，保证购物车数据（价格/库存/规格文案）一致。
   * 多规格商品由模板分流到详情页选规格，缺货商品不可点。
   */
  async function onQuickAdd(product: Product): Promise<void> {
    if (addingId.value) return;
    addingId.value = product.id;
    try {
      const detail = await getProductDetail(product.id);
      const sku = detail.skus?.[0];
      if (!sku) {
        showToast('该商品暂无可订规格');
        return;
      }
      const quantity = sku.minOrderQuantity ?? 1;
      cartStore.addItem({ spuId: product.id, sku, quantity });
      if (userStore.isLogin) {
        void addCart({ skuId: sku.id, count: quantity }).catch((error) => {
          console.warn('[cart] 同步加入订货单失败:', error);
        });
      }
      showToast('已加入订货单');
    } catch (err) {
      // 错误提示由请求层统一处理，这里仅留痕，避免未捕获的 Promise rejection
      console.warn('[category] 加入订货单失败:', err);
    } finally {
      addingId.value = undefined;
    }
  }

  /** 动作栏：查看订货单明细 */
  function toCart(): void {
    void router.push('/cart');
  }

  /** 动作栏：去结算 */
  function toConfirm(): void {
    if (!cartStore.checkedItems.length) {
      showToast('请先勾选要下单的商品');
      return;
    }
    void router.push('/order/confirm');
  }

  onMounted(() => {
    void init();
  });
</script>

<template>
  <div class="app-page app-page--fixed">
    <AppNavBar title="商品分类" :left-arrow="false" />

    <!-- 搜索栏：由首页挪来（首页不再放搜索入口）。提交后跳到商品列表页展示结果 -->
    <van-search
      v-model="keyword"
      shape="round"
      show-action
      placeholder="搜索商品名称 / 编码"
      @search="onSearch"
    >
      <template #action>
        <div class="category__search-action" @click="onSearch">搜索</div>
      </template>
    </van-search>

    <div class="category">
      <!-- 左侧只放一级分类：二级分类在右侧分组呈现（后端分类是 parentId 表达的层级） -->
      <van-sidebar v-model="activeIndex" class="category__sidebar" @change="onSelect">
        <van-sidebar-item v-for="item in categories" :key="item.id" :title="item.name" />
      </van-sidebar>

      <!-- 右侧商品：内部滚动容器，下拉刷新需挂在容器内才生效 -->
      <div :class="['category__content', { 'category__content--with-bar': hasCartItems }]">
        <van-pull-refresh v-model="refreshing" @refresh="onRefresh">
          <div class="flex-between category__title">
            <span>{{ activeName }}</span>
            <span v-if="total" class="category__count">共 {{ total }} 件</span>
          </div>

          <van-list
            v-model:loading="loading"
            :finished="finished"
            :error="error"
            :loading-text="list.length ? '加载中...' : ''"
            finished-text="没有更多了"
            error-text="加载失败，点击重试"
            @load="onLoad"
          >
            <!-- 首屏骨架：列表为空且加载中时用骨架屏代替空白（切换分类同样适用） -->
            <ListSkeleton v-if="!list.length && loading && !refreshing" :rows="4" />

            <div v-for="group in groups" :key="group.id" class="category__group">
              <!-- 二级分类标题：吸顶在分类标题下方，滚动时知道当前在哪一组 -->
              <div v-if="grouped" class="category__group-title">{{ group.name }}</div>

              <div
                v-for="product in group.items"
                :key="product.id"
                class="category__item"
                @click="toDetail(product.id)"
              >
                <van-image
                  class="category__img"
                  :src="resolveImage(product.picUrl)"
                  fit="cover"
                  radius="8"
                  lazy-load
                />
                <div class="category__info">
                  <div class="text-ellipsis-2 category__name">{{ product.name }}</div>

                  <div class="category__meta">
                    <van-tag v-if="(product.stock ?? 0) > 0" plain type="primary">
                      库存 {{ product.stock }}
                    </van-tag>
                    <van-tag v-else plain type="danger">缺货</van-tag>
                    <span class="category__sales">
                      已订 {{ formatCount(product.salesCount ?? 0) }}
                    </span>
                  </div>

                  <div class="category__foot">
                    <PriceText :value="product.price" />
                    <span class="category__unit">/ {{ product.unit ?? '件' }}</span>

                    <!-- 快速加入订货单：单规格直接加、多规格去详情选规格、缺货不可点 -->
                    <button
                      v-if="(product.stock ?? 0) <= 0"
                      type="button"
                      class="category__add category__add--plane"
                      disabled
                      @click.stop
                    >
                      缺货
                    </button>
                    <button
                      v-else-if="product.specType"
                      type="button"
                      class="category__add category__add--plane"
                      @click.stop="toDetail(product.id)"
                    >
                      选规格
                    </button>
                    <button
                      v-else
                      type="button"
                      class="category__add"
                      :disabled="addingId === product.id"
                      @click.stop="onQuickAdd(product)"
                    >
                      <van-icon :name="addingId === product.id ? 'loading' : 'plus'" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </van-list>

          <!-- 空态：该分类下暂无商品（区别于「加载失败」，无需重试入口） -->
          <van-empty v-if="!loading && !list.length" image="search" description="该分类暂无商品" />
        </van-pull-refresh>
      </div>
    </div>

    <!--
      底部购物车动作栏：Vant ActionBar 官方结构（图标 + 合计 + 主按钮）。
      订货单为空时不渲染，避免遮挡内容（这也是原「悬浮购物车栏」的交互约定）。
    -->
    <van-action-bar v-if="hasCartItems" class="category__bar" :safe-area-inset-bottom="false">
      <van-action-bar-icon
        icon="cart-o"
        text="订货单"
        :badge="cartStore.totalQuantity"
        to="/cart"
      />
      <div class="category__bar-total" @click="toCart">
        <span class="category__bar-label">合计</span>
        <PriceText :value="cartStore.totalPrice" size="large" />
      </div>
      <van-action-bar-button
        class="category__bar-btn"
        type="danger"
        text="去结算"
        @click="toConfirm"
      />
    </van-action-bar>
  </div>
</template>

<style scoped lang="scss">
  .category {
    display: flex;
    flex: 1;
    min-height: 0;
    overflow: hidden;

    /* 侧边导航：保留 Vant 官方观感（浅灰导轨 + 选中项白底 + 主题色指示条），
       只把宽度与字号调大，避免中文分类名折行 */
    &__sidebar {
      flex: none;
      width: var(--van-sidebar-width);
      height: 100%;
      /* Vant 的 .van-sidebar 本身没有背景（灰底来自每个 item），补一层整列灰底，
         选中项的白底才能与右侧白色内容区连成一体（美团外卖的分类页观感） */
      background: var(--van-sidebar-background);
      --van-sidebar-width: 92px;
      --van-sidebar-font-size: 13px;
      --van-sidebar-padding: 16px 10px;
      --van-sidebar-line-height: 20px;
    }

    &__content {
      flex: 1;
      height: 100%;
      overflow-y: auto;
      /* 底部预留固定 tabbar 的高度，否则滚到底时最后一项（如「没有更多了」）会被 tabbar 遮挡 */
      padding: 0 12px calc(12px + var(--app-tabbar-height) + env(safe-area-inset-bottom));
      /* 白底：左侧选中项也是白底，两者连成一体（美团外卖式）——这条视觉关系别改；
         商品卡片改由「描边 + 淡阴影」在白底上立起来，不靠背景色差 */
      background: var(--app-white);
    }

    /* 有底部动作栏时，内容区再多留出动作栏高度（50 + 8 间距） */
    &__content--with-bar {
      padding-bottom: calc(
        12px + var(--app-tabbar-height) + env(safe-area-inset-bottom) + 58px
      );
    }

    /* 一级分类标题吸顶：高度固定为 40px，二级分组标题据此下移 */
    &__title {
      position: sticky;
      top: 0;
      z-index: 2;
      padding: 10px 0;
      font-size: 14px;
      font-weight: 600;
      line-height: 20px;
      background: var(--app-white);
    }

    &__count {
      font-size: 12px;
      font-weight: 400;
      color: var(--app-text-color-secondary);
    }

    /* 二级分类标题：吸顶在一级标题下方 */
    &__group-title {
      position: sticky;
      top: 40px;
      z-index: 1;
      padding: 8px 0 6px;
      font-size: 13px;
      font-weight: 600;
      line-height: 18px;
      color: var(--app-text-color);
      background: var(--app-white);
    }

    /* ===== 商品卡片 =====
       内容区是白底（要与左侧选中项连成一体），所以卡片靠「描边 + 淡阴影」区分，
       而不是靠背景色差：描边给出清晰边界，阴影补一点层次 */
    &__item {
      display: flex;
      gap: 10px;
      padding: 10px;
      margin-bottom: 8px;
      background: var(--app-white);
      border: 1px solid var(--app-border-color);
      border-radius: var(--app-radius-md);
      box-shadow: 0 1px 2px rgb(0 0 0 / 4%);
    }

    &__item:active {
      background: #fafafa;
    }

    &__img {
      flex: none;
      width: 84px;
      height: 84px;
      overflow: hidden;
      background: var(--app-bg-color);
      border-radius: var(--app-radius-md);
    }

    &__info {
      display: flex;
      flex: 1;
      flex-direction: column;
      min-width: 0;
    }

    &__name {
      font-size: 14px;
      font-weight: 500;
      line-height: 1.4;
      color: var(--app-text-color);
    }

    &__meta {
      display: flex;
      align-items: center;
      gap: 6px;
      margin-top: 6px;
    }

    &__sales {
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    &__foot {
      display: flex;
      align-items: center;
      gap: 2px;
      margin-top: auto;
      padding-top: 6px;
    }

    &__unit {
      font-size: 12px;
      color: var(--app-text-color-secondary);
      /* 卡片信息列窄，价格行整体不换行 */
      white-space: nowrap;
    }

    /* 快速加购按钮：单规格是圆形「＋」，多规格/缺货是胶囊文字（美团式） */
    &__add {
      display: flex;
      align-items: center;
      justify-content: center;
      flex: none;
      width: 26px;
      height: 26px;
      /* 推到卡片右下角；不允许被固定价格挤压（否则「选规格」会折成两行） */
      margin-left: auto;
      padding: 0;
      font-size: 17px;
      line-height: 1;
      white-space: nowrap;
      color: var(--app-white);
      background: var(--app-primary-color);
      border: 0;
      border-radius: 50%;
    }

    &__add:disabled {
      opacity: 0.6;
    }

    &__add--plane {
      width: auto;
      height: 22px;
      padding: 0 10px;
      font-size: 12px;
      border-radius: 11px;
    }

    &__add--plane:disabled {
      color: var(--app-text-color-secondary);
      background: #f2f3f5;
      opacity: 1;
    }

    /* 搜索行右侧的「搜索」按钮（与商品列表页保持一致） */
    &__search-action {
      padding-left: 12px;
      font-size: 14px;
      color: var(--app-primary-color);
    }

    /* ===== 底部动作栏 ===== */
    &__bar {
      /* 叠在 tabbar 之上：tabbar 已经处理了底部安全区，动作栏不再重复避让 */
      bottom: calc(var(--app-tabbar-height) + env(safe-area-inset-bottom));
      border-top: 1px solid var(--app-border-color);
      /* 主题色：主按钮用品牌渐变，替换 Vant 默认的红色渐变 */
      --van-action-bar-button-danger-color: var(--app-primary-gradient);
    }

    &__bar-total {
      display: flex;
      flex: 1;
      align-items: baseline;
      justify-content: flex-end;
      gap: 4px;
      min-width: 0;
      padding-right: 10px;
    }

    &__bar-label {
      font-size: 12px;
      color: var(--app-text-color-secondary);
    }

    /* 单个主按钮不必占满剩余空间，固定宽度更接近商城观感 */
    &__bar-btn {
      flex: none;
      width: 116px;
    }
  }
</style>
