/**
 * FAQ 常见问题数据
 */
export interface FaqItem {
  /** 问题标题 */
  title: string
  /** 问题答案 */
  content: string
}

export interface FaqCategory {
  /** 分类图标 */
  icon: string
  /** 分类标题 */
  title: string
  /** 问题列表 */
  childList: FaqItem[]
}

/** FAQ 数据列表 */
export const faqList: FaqCategory[] = [
  {
    icon: 'github-filled',
    title: '关于系统',
    childList: [
      {
        title: '本系统基于什么开发？',
        content: '本系统采用 MIT 开源协议，允许商业使用与二次开发。',
      },
      {
        title: '可以商用吗？',
        content: '可以，本系统采用 MIT 开源协议，允许商业使用。',
      },
      {
        title: '如何反馈问题？',
        content: '请联系系统管理员，或在内部工单系统中提交。',
      },
      {
        title: '如何获取使用文档？',
        content: '请向系统管理员索取内部使用手册。',
      },
    ],
  },
  {
    icon: 'exclamation-circle',
    title: '其他问题',
    childList: [
      {
        title: '如何退出登录？',
        content: '请点击 [我的] - [退出登录] 即可退出登录。',
      },
      {
        title: '如何修改用户头像？',
        content: '请点击 [我的] - [个人资料] - [选择头像] 即可更换用户头像。',
      },
      {
        title: '如何修改登录密码？',
        content: '请点击 [我的] - [账号安全] - [修改密码] 即可修改登录密码。',
      },
      {
        title: '如何切换用户？',
        content: '请先退出当前账号，然后使用其他账号重新登录即可。',
      },
    ],
  },
]
