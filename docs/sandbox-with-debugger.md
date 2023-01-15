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
  - { from: /go/src/github.com/mauriciopoppe/kubernetes-playground, to: ./ }
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

### Connecting to the process with nvim and nvim-dap

The setup requires this plugin:

- https://github.com/mfussenegger/nvim-dap

The setup for nvim-dap that I have is this one, it's a little bit different
to the one in https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#go-using-delve-directly
and adapted to connect to a remote process if request = "attach"

```lua
local dap = require "dap"
dap.adapters.go = function(callback, config)
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  local handle
  local pid_or_err
  local host = config.host or "127.0.0.1"
  local port = config.port or "38697"
  local addr = string.format("%s:%s", host, port)
  if config.request == "attach" and config.mode == "remote" then
    local msg = string.format("connecting to server at '%s'...", addr)
    print(msg)
  else
    local opts = {
      stdio = {nil, stdout, stderr},
      -- To enable debugging:
      -- - Uncomment the following line
      -- args = {"dap", "-l", addr, "--log", "debug", "--log-output", "dap", "--log-dest", "/tmp/dap.log"},
      -- - Check ~/.cache/nvim/dap.log (I saw set breakpoint errors here)
      args = {"dap", "-l", addr},
      detached = true
    }
    print(config)
    print(opts)

    handle, pid_or_err = vim.loop.spawn("dlv", opts, function(code)
      stdout:read_stop()
      stderr:read_stop()
      stdout:close()
      stderr:close()
      handle:close()
      if code ~= 0 then
        print("ERROR: dlv exited with code", code)
      end
    end)
    assert(handle, "Error running dlv: " .. tostring(pid_or_err))

    stdout:read_start(function(err, chunk)
      assert(not err, err)
      if chunk then
        vim.schedule(function()
          require("dap.repl").append(chunk)
        end)
      end
    end)
    stderr:read_start(function(err, chunk)
      assert(not err, err)
      if chunk then
        vim.schedule(function()
          require("dap.repl").append(chunk)
        end)
      end
    end)
  end

  -- Wait for delve to start
  vim.defer_fn(function()
    callback({ type = "server", host = host, port = port })
  end, 100)
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

Assuming that the `cmd/<demo>` application is running you can already connect
to it, first let's set some breakpoints, in Neovim go to the source code of the program
chosen and set as many breakpoints as wanted with:

```
:lua require("dap").toggle_breakpoint()<CR>
```

Next run the application with delve in attach mode (the configuration above),
it'll ask you which configuration to run:

```
:lua require("dap").continue()<CR>
```

If everything went right you should see an arrow on the left of the number
line showing that the application paused at that point.

![breakpoint](https://user-images.githubusercontent.com/1616682/206831029-ffb50475-331b-422d-9815-da33174332dd.png)

### Debugging with nvim-dap-ui

This step requires this plugin:

- https://github.com/rcarriga/nvim-dap-ui

Configure it as follows:

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

Continuing on the steps above and assuming that your application hit a breakpoint
you can simply open a floating element for the debugger with `<Leader>bp` or your
favorite mapping.

![debugging with float](https://user-images.githubusercontent.com/1616682/206831092-c514ff76-76ee-4b78-aa77-1863dc9a5b7f.png)

## Demos

- `cmd/hello-world-linux` - Accessing the API server from a pod.
- `cmd/hello-world-windows` - Works only in windows nodes, same as hello-world-linux but with a windows binary.
