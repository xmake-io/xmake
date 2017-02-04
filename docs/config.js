var langs = [
  {title: 'English', path: '/home'},
  {title: '中文', path: '/zh/'},
]

self.$config = {
    landing: '/landing/_site/index.html',
    repo: 'tboox/xmake',
    twitter: 'waruqi',
    url: 'http://xmake.io',
    'edit-link': 'https://github.com/tboox/xmake/blob/master/docs',
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
        title: 'Blog', path: 'http://www.tboox.org'
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
        title: '博客', path: 'http://www.tboox.org/cn'
      },
      {
        title: '中文', type: 'dropdown', items: langs, exact: true
      }
    ]
  },
  plugins: [
    docsearch({
      apiKey: '',
      indexName: 'xmake',
      tags: ['english', 'zh']
    })
  ]
}
