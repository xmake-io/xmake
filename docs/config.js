var langs = [
  {title: 'English', path: '/home'},
  {title: '中文', path: '/zh/'},
]

self.$config = {
    landing: true,
    repo: 'tboox/xmake',
    twitter: 'waruqi',
    url: 'http://xmake.io',
    'edit-link': 'https://github.com/tboox/xmake/blob/dev/docs',
    nav: {
    default: [
      {
        title: 'Home', path: '/home'
      },
      {
        title: 'Plugins', path: '/plugins'
      },
      {
        title: 'Manual', path: '/manual'
      },
      {
        title: 'Articles', path: 'http://www.tboox.org/category/#xmake'
      },
      {
        title: 'Feedback', path: 'https://github.com/tboox/xmake/issues'
      },
      {
        title: 'Community', path: 'http://www.tboox.org/forum'
      },
      {
        title: 'English', type: 'dropdown', items: langs, exact: true
      }
    ],
    'zh': [
      {
        title: '首页', path: '/zh/'
      },
      {
        title: '插件', path: '/zh/plugins'
      },
      {
        title: '手册', path: '/zh/manual'
      },
      {
        title: '文章', path: 'http://www.tboox.org/cn/category/#xmake'
      },
      {
        title: '反馈', path: 'https://github.com/tboox/xmake/issues'
      },
      {
        title: '社区', path: 'http://www.tboox.org/forum'
      },
      {
        title: '中文', type: 'dropdown', items: langs, exact: true
      }
    ]
  },
  plugins: [
    docsearch({
      apiKey: 'fbba61eefc60a833d8caf1fa72bd8ef8',
      indexName: 'xmake',
      tags: ['en', 'zh']
    })
  ]
}
