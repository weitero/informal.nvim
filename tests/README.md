# Tests

Run all tests:

```sh
make test
```

Direct runner (if you want to specify interpreter):

```sh
luajit tests/run.lua
```

The suite uses a mocked `vim` runtime, so it can run without launching Neovim.
