local jdtls = require("jdtls.setup")
local handler = require("jdtls")

local root_dir = jdtls.find_root({".git", "mvnw", "gradlew", "pom.xml"})
local home = os.getenv('HOME')
local workspace_dir = home .. "/.workspace/" .. vim.fn.fnamemodify(root_dir, ":p:h:t")

local config = {
  cmd = {
    'java',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xms1g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',
    '-jar',
    '/home/amitprakash/.local/opt/org.eclipse/plugins/org.eclipse.equinox.launcher_1.6.400.v20210924-0641.jar',
    '-configuration',
    '/home/amitprakash/.local/opt/org.eclipse/config_linux',
    '-data',
    workspace_dir,
  },
  root_dir = root_dir,
  settings = {
    java = {}
  },
  init_options = {
    bundles = {}
  }
}

handler.start_or_attach(config)

local exports = {
	handler = handler,
}

return exports
