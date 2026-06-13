-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- ============================================================
-- DIFF MODE (used by `nvim -d`, lazygit external diff, git mergetool)
-- ============================================================
-- Strip LazyVim's default linematch:40 so our linematch:60 is the only one.
vim.opt.diffopt:remove("linematch:40")
vim.opt.diffopt:append("linematch:60")        -- align moved lines (was 40)
vim.opt.diffopt:append("algorithm:histogram") -- better than default myers for code
vim.opt.diffopt:append("iwhite")              -- ignore whitespace-only changes
vim.opt.diffopt:append("vertical")            -- always vertical splits in diff mode

-- Diff-mode keymaps reminder (already builtin):
--   ]c / [c       next/prev hunk
--   do / dp       diff obtain / diff put
--   :diffupdate   refresh
--   zo / zc       open/close folds
