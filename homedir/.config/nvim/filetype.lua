vim.filetype.add({
  extension = {
    ixx = "cpp",
    -- Neovim maps these to "bash" by default, which attaches bashls and
    -- yields bogus shellcheck diagnostics (SC2034 for EAPI etc.). A dedicated
    -- filetype keeps bashls and shfmt off; bash treesitter is registered below.
    ebuild = "ebuild",
    eclass = "ebuild",
  },
})

vim.treesitter.language.register("bash", "ebuild")
