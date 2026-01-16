module.exports = {
  title: 'Kubernetes Playground',
  description: 'Notes and experiments with Kubernetes',
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'GitHub', link: 'https://github.com/mauriciopoppe/kubernetes-playground' }
    ],
    sidebar: [
      {
        text: 'Experiments',
        items: [
          { text: 'Sandboxes with Debugger', link: '/sandbox-with-debugger' },
          { text: 'Controller Runtime', link: '/controller-runtime' },
        ]
      },
      {
        text: 'Kubernetes Controllers',
        items: [
          { text: 'Kube Controller Manager', link: '/kube-controller-manager' },
          { text: 'Attach/Detach Controller', link: '/attach-detach-controller' },
          { text: 'PV Controller', link: '/pv-controller' },
          { text: 'Admission Controller', link: '/admission-controller-default-storage-class' },
        ]
      },
      {
        text: 'Kubernetes Development',
        items: [
          { text: 'General Development', link: '/kubernetes-development' },
          { text: 'Kubelet', link: '/kubelet' },
          { text: 'Containerd', link: '/containerd' },
          { text: 'E2E Tests', link: '/kubernetes-e2e-tests' },
          { text: 'Unit Tests', link: '/kubernetes-unit-tests' },
        ]
      },
      {
        text: 'Utils',
        items: [
          { text: 'Kubernetes Utils', link: '/kubernetes-utils' },
        ]
      }
    ]
  }
}