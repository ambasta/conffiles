local handler = require("lspconfig")
local utils = require("common.utils")
local capabilities = require("plugins.capabilities")
local lspconfig_util = require("lspconfig.util")
local yaml_companion = require('plugins.yaml-companion')

local servers = {
    "angularls",
    "clangd",
    "cmake",
    "eslint",
    "gopls",
    "java_language_server",
    -- "jdtls",
    "jsonls",
    "kotlin_language_server",
    "pyright",
    "rust_analyzer",
    "tsserver",
    "yamlls",
}

function GetFileMatchingPattern(search_dir, pattern)
        local files = vim.fn.glob(search_dir .. "/**/" .. pattern, false, true)

        if vim.tbl_isempty(files) then
                error("Searched files: " .. search_dir .. "/**/" .. pattern .. " : " .. vim.inspect(files))
                error("No files found matching pattern: " .. pattern)
        end

        return files[1]
end

for _, server in ipairs(servers) do
        local opts = {
                on_attach = utils.on_attach,
                capabilities = capabilities.capabilities,
                flags = {
                        debounce_text_changes = 150,
                },
                format = { timeout_ms = 5000 },
        }

        if server == "tsserver" then
                local default_opts = require("lspconfig.server_configurations.tsserver")
                opts.cmd = vim.list_extend({ "yarn" }, default_opts.default_config.cmd)
                opts.root_dir = lspconfig_util.root_pattern({ ".yarn", "node_modules" })
        elseif server == "clangd" then
                local default_opts = require("lspconfig.server_configurations.clangd")
                opts.cmd = { "clangd", "--enable-config" }
                opts.filetypes = vim.list_extend({ "cppm", "cxxm" }, default_opts.default_config.filetypes)
        elseif server == "eslint" then
                local default_opts = require("lspconfig.server_configurations.eslint")
                opts.cmd = vim.list_extend({ "yarn" }, default_opts.default_config.cmd)
                opts.root_dir = lspconfig_util.root_pattern({ ".yarn", "node_modules" })
                opts.settings = {
                        validate = "on",
                        packageManager = "yarn",
                        format = true,
                        quiet = false,
                }
        elseif server == "jsonls" then
                local default_opts = require("lspconfig.server_configurations.jsonls")
                opts.cmd = vim.list_extend({ "yarn" }, default_opts.default_config.cmd)
                opts.root_dir = lspconfig_util.root_pattern({ ".yarn", "node_modules" })
        elseif server == "angularls" then
                local default_opts = require("lspconfig.server_configurations.angularls")
                local cmd = { "yarn", "ngserver", "--stdio", "--tsProbeLocations", "./", "--ngProbeLocations", "./" }
                opts.cmd = cmd
                opts.root_dir = lspconfig_util.root_pattern("angular.json")
                opts.on_new_config = function(new_config, new_root_dir)
                        new_config.cmd = opts.cmd
                end
        elseif server == "pyright" then
    -- opts.cmd = { "pywrong", "--stdio" }
                opts.capabilities.textDocument = {
      publishDiagnostics = {
        tagSupport = {
          valueSet = { 2 }
        }
      },
                        completion = {
                                completionItem = {
                                        snippetSupport = true,
                                },
                        }
                }
                opts.on_attach = utils.on_attach
        elseif server == "jsonls" then
                opts.commands = {
                        Format = {
                                function()
                                        vim.lsp.buf.range_formatting({}, { 0, 0 }, { vim.fn.line("$"), 0 })
                                end,
                        },
                }
        elseif server == "rust_analyzer" then
                opts.settings = {
                        rust = {
                                unstable_features = true,
                                build_on_save = false,
                                all_features = true,
                        },
                }
  elseif server == "gopls" then
    opts.settings = {
      gopls = {
        analyses = {
          unusedparams = true,
        },
        staticcheck = true,
      }
    }
        elseif server == "java_language_server" then
                opts.cmd = { "/home/amitprakash/foss/java-language-server/dist/lang_server_linux.sh" }
                -- setup
  elseif server == "yamlls" then
    opts = yaml_companion.handler
        elseif server == "jdtls" then
                local root_dir = lspconfig_util.root_pattern({ ".git", "mvnw", "gradlew", "pom.xml" })
                local home = os.getenv("HOME")
                local workspace_dir = home .. "/.workspace/"
                -- local jdls = GetFileMatchingPattern(home .. "/.local/opt", "jdt-language-server-*.jar")
                -- local lombok = GetFileMatchingPattern(home  .. "/.local/opt", "lombok-*.jar");
                local equinox = GetFileMatchingPattern(home .. "/.local/opt", "org.eclipse.equinox.launcher_*.jar")
                local configdir = GetFileMatchingPattern(home .. "/.local/opt", "config_linux")

                opts.cmd = {
                        "java",
                        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
                        "-Dosgi.bundles.defaultStartLevel=4",
                        "-Declipse.product=org.eclipse.jdt.ls.core.product",
                        "-Dlog.protocol=true",
                        "-Dlog.level=ALL",
                        -- '-javaagent:'.. lombok,
                        "-Xms1g",
                        "-Xmx2G",
                        "-jar",
                        -- jdls,
                        equinox,
                        "-configuration",
                        configdir,
                        "--add-modules=ALL-SYSTEM",
                        "--add-opens",
                        "java.base/java.util=ALL-UNNAMED",
                        "--add-opens",
                        "java.base/java.lang=ALL-UNNAMED",
                        "-data",
                        workspace_dir,
                }
                opts.flags = {
                        allow_incremental_sync = true,
                }
                -- opts.capabilities.workspace.configuration = true
                opts.capabilities.textDocument = {
                        completion = {
                                completionItem = {
                                        snippetSupport = true,
                                },
                        },
                }
                opts.root_dir = root_dir
                opts.settings = {
                        java = {
                                autobuild = {
                                        enabled = true,
                                },
                                import = {
                                        generatesMetadataFilesAtProjectRoot = true,
                                },
                                format = {
                                        settings = {
                                                url = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
                                        },
                                },
                                sources = {
                                        organizeImports = {
                                                starThreshold = 9999,
                                                staticStarThreshold = 9999,
                                        },
                                },
                                codeGeneration = {
                                        toString = {
                                                template = "$(object.className}{${member.name()}=${member.value}, ${otherMembers}}",
                                        },
                                },
                                saveActions = {
                                        organizeImports = true,
                                },
                                trace = {
                                        server = "verbose",
                                },
                        },
                }
        elseif server == "kotlin_language_server" then
                local default_opts = require("lspconfig.server_configurations.kotlin_language_server")
                opts.root_dir = lspconfig_util.root_pattern({ "gradlew", "settings.gradle.kts" })
        end

        handler[server].setup(opts)
        vim.cmd([[ do User LspAttachBuffers ]])
end

local exports = {
        handler = handler,
}

return exports
