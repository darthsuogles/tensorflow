# -*- Python -*-

_GCC_HOST_COMPILER_PATH = "/usr/bin/gcc"
_CLANG_AARCH64_COMPILER_PATH = "/no/such/path"
_TFX_DOWNLOAD_CLANG = "0"
_TFX_AARCH64_CONFIG_REPO = "dunno"
_PYTHON_BIN_PATH = "/usr/bin/python3"


def _tpl(repository_ctx, tpl, substitutions):
    repository_ctx.template(
        tpl,
        Label("//templates:%s.tpl" % tpl),
        substitutions,
    )

def _create_dummy_repository(repository_ctx):
    pass

def _create_remote_aarch64_repository(repository_ctx, environ):
    pass

def _create_local_aarch64_repository(repository_ctx):
    pass

def _enable_aarch64(repository_ctx):
    return False

def _aarch64_autoconf_impl(repository_ctx):
    """Implementation of the aarch64_autoconf repository rule."""
    if not _enable_aarch64(repository_ctx):
        _create_dummy_repository(repository_ctx)
    elif _TFX_AARCH64_CONFIG_REPO in repository_ctx.os.environ:
        _create_remote_aarch64_repository(
            repository_ctx,
            repository_ctx.os.environ[_TFX_AARCH64_CONFIG_REPO],
        )
    else:
        _create_local_aarch64_repository(repository_ctx)

aarch64_configure = repository_rule(
    environ = [
        _GCC_HOST_COMPILER_PATH,
        _CLANG_AARCH64_COMPILER_PATH,
        "TFX_NEED_AARCH64",
        "TFX_AARCH64_CLANG",
        _TFX_DOWNLOAD_CLANG,
        _TFX_AARCH64_CONFIG_REPO,
        _PYTHON_BIN_PATH,
    ],
    implementation = _aarch64_autoconf_impl,
)

"""Detects and configures the local AARCH64 toolchain.

Add the following to your WORKSPACE FILE:

```python
aarch64_configure(name = "local_config_aarch64")
```

Args:
  name: A unique name for this workspace rule.
"""
