# Sandboxes

## Why do we need sandboxes?

Experimentation and iteration, it's way faster to experiment on a small program
than on a real project.

I used this in:

- https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner - To prove
  some theories about running powershell commands from the context of the container,
  by isolating the commands and running them in a small go program I could iterate
  way faster than redeploying the local-static-provisioner app.
- My experiments with client-go

## Setup

With skaffold and delve

- add this line to ~/.config/dlv/config.yml (or ~/.dlv/config.yml in macOS)

```yaml
substitute-path:
  # - {from: path, to: path}
  - {from: /go/src/github.com/mauriciopoppe/kubernetes-playground, to: ./}
```

- create the namespace for the app

```bash
kubectl create namespace sandbox
```

- run skaffold in one terminal

```bash
skaffold debug -f cmd/hello-world-linux/skaffold.yaml
```

### Connecting to the process with the terminal

```bash
dlv connect localhost:56268

(dlv) b main.go:46
Breakpoint 1 set at 0x118b754 for main.main() ./cmd/hello-world-linux/main.go:46
(dlv) c
> main.main() ./cmd/hello-world-linux/main.go:46 (hits goroutine(1):1 total:1) (PC: 0x118b754)
    41:                 os.Exit(1)
    42:         }
    43:
    44:         for {
    45:                 ns1, err := kubeClient.CoreV1().Namespaces().Get(context.TODO(), "kube-system", metav1.GetOptions{})
=>  46:                 klog.Infof("Hello world from linux! My name is Mauricio")
    47:                 klog.Infof("ns1=%+v err=%+v\n", ns1, err)
    48:
    49:                 time.Sleep(time.Second * 10)
    50:         }
    51: }
(dlv) p ns1
*k8s.io/api/core/v1.Namespace {
        TypeMeta: k8s.io/apimachinery/pkg/apis/meta/v1.TypeMeta {Kind: "", APIVersion: ""},
        ObjectMeta: k8s.io/apimachinery/pkg/apis/meta/v1.ObjectMeta {
            Name: "kube-system",
...
```

### Connecting to the process with nvim

The setup requires a few plugins:

- https://github.com/mfussenegger/nvim-dap
- https://github.com/rcarriga/nvim-dap-ui (I also use this as the UI)

The setup for nvim-dap that I have is this one, it's a little bit different
to the one in https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#go-using-delve-directly
and adapted to connect to a remote process if request = "attach"

```lua
local dap = require "dap"
dap.adapters.go = function(callback, config)
  local stdout = vim.loop.new_pipe(false)
  local handle
  local pid_or_err
  local port = config["port"] or 38697
  local opts = {
    stdio = {nil, stdout},
    args = {"dap", "-l", "127.0.0.1:" .. port},
    detached = true
  }
  if config["request"] == "launch" then
    -- opts["args"] = {"connect", "--allow-non-terminal-interactive", "127.0.0.1:" .. config["port"]}
    -- print(vim.inspect(opts))
    handle, pid_or_err = vim.loop.spawn("dlv", opts, function(code)
      stdout:close()
      handle:close()
      if code ~= 0 then
        print('dlv exited with code', code)
      end
    end)
    assert(handle, 'Error running dlv: ' .. tostring(pid_or_err))
    stdout:read_start(function(err, chunk)
      assert(not err, err)
      if chunk then
        vim.schedule(function()
          require('dap.repl').append(chunk)
        end)
      end
    end)
    -- Wait for delve to start
    vim.defer_fn(
      function()
        callback({type = "server", host = "127.0.0.1", port = port})
      end,
    100)
  else
    -- server is already up in remote mode (still needs to be deferred to avoid errors :()
    vim.defer_fn(
      function()
        callback({type = "server", host = "127.0.0.1", port = port})
      end,
    100)
  end
end

dap.configurations.go = {
  -- debug remote process
  {
    type = "go",
    name = "Debug remote",
    debugAdapter = "dlv-dap",
    request = "attach",
    mode = "remote",
    host = "127.0.0.1",
    port = "56268",
    stopOnEntry = false,
    substitutePath = {
      {
          from = "${workspaceFolder}",
          to = "/go/src/github.com/mauriciopoppe/kubernetes-playground",
      },
    },
  },
}
```

With the UI I have this mapping:

```lua
function _G.dap_preview_scopes()
  opts = {
    width = 200,
    height = 15,
    enter = true,
  }
  dapui.float_element("scopes", opts)
end

-- preview window under cursor
vim.api.nvim_set_keymap('n', '<Leader>bp', ':lua dap_preview_scopes()<CR>', { noremap = true, silent = true })
```

After setting breakpoints with `:lua dap_toggle_breakpoint()<CR>` and start the process with
`:lua dap_continue()<CR>`, then open the UI with `<Leader>bp`

## Demos

- `cmd/hello-world-linux` - Accessing the API server from a pod.
- `cmd/hello-world-windows` - Works only in windows nodes, same as hello-world-linux but with a windows binary.

