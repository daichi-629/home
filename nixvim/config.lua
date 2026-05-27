local lang = {
  go = @LANG_GO_ENABLED@,
  node = @LANG_NODE_ENABLED@,
  python = @LANG_PYTHON_ENABLED@,
  rust = @LANG_RUST_ENABLED@,
  latex = @LANG_LATEX_ENABLED@,
  nix = @LANG_NIX_ENABLED@,
  ruby = @LANG_RUBY_ENABLED@,
  lean = @LANG_LEAN_ENABLED@,
}
local clipboard_provider = "@CLIPBOARD_PROVIDER@"
local python_dap_python = "@PYTHON_DAP_PYTHON@"

local function find_copilot_disable_marker(start_path)
  local path = start_path
  if not path or path == "" then
    path = vim.fn.getcwd()
  elseif vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 0 then
    path = vim.fs.dirname(path)
  end

  local markers = vim.fs.find(".nvim-disable-copilot", {
    upward = true,
    path = path,
    type = "file",
  })
  return markers[1]
end

if find_copilot_disable_marker(vim.fn.getcwd()) then
  vim.g.copilot_enabled = 0
  vim.g.copilot_filetypes = { ["*"] = false }
end

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile", "BufEnter" }, {
  pattern = "*",
  callback = function(args)
    local path = vim.api.nvim_buf_get_name(args.buf)
    if find_copilot_disable_marker(path) then
      vim.b[args.buf].copilot_enabled = false
    end
  end,
  desc = "Disable Copilot when .nvim-disable-copilot exists in the project",
})

vim.api.nvim_create_augroup("extra-whitespace", {})
vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter" }, {
  group = "extra-whitespace",
  pattern = { "*" },
  command = [[call matchadd('ExtraWhitespace', '[\u200B\u3000]')]],
})
vim.api.nvim_create_autocmd({ "ColorScheme" }, {
  group = "extra-whitespace",
  pattern = { "*" },
  command = [[highlight default ExtraWhitespace ctermbg=202 ctermfg=202 guibg=salmon]],
})

local autosave_group = vim.api.nvim_create_augroup("AutoSaveGroup", { clear = true })
vim.api.nvim_create_autocmd({ "CursorHold", "FocusLost", "BufLeave" }, {
  group = autosave_group,
  pattern = "*",
  callback = function()
    local file_exists = vim.fn.filereadable(vim.fn.expand("%")) == 1
    if vim.bo.modified and vim.bo.buftype == "" and vim.bo.modifiable and file_exists then
      vim.cmd("update")
    end
  end,
  desc = "変更があったバッファを自動的に保存する",
})

local autoread_group = vim.api.nvim_create_augroup("AutoReadGroup", { clear = true })
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = autoread_group,
  pattern = "*",
  callback = function()
    if vim.bo.buftype ~= "" then
      return
    end
    vim.cmd("checktime")
  end,
  desc = "外部で更新されたファイルを自動的に再読込する",
})

local function setup_wl_clipboard()
  if vim.fn.executable("wl-copy") == 1 and vim.fn.executable("wl-paste") == 1 then
    vim.g.clipboard = {
      name = "wl-clipboard",
      cache_enabled = 0,
      copy = { ["+"] = "wl-copy --type text", ["*"] = "wl-copy --type text" },
      paste = { ["+"] = "wl-paste --no-newline", ["*"] = "wl-paste --no-newline" },
    }
    return true
  end
  return false
end

local function setup_xclip_clipboard()
  if vim.fn.executable("xclip") == 1 then
    vim.g.clipboard = {
      name = "xclip",
      copy = { ["+"] = "xclip -selection clipboard", ["*"] = "xclip -selection primary" },
      paste = { ["+"] = "xclip -selection clipboard -o", ["*"] = "xclip -selection primary -o" },
    }
    return true
  end
  return false
end

if clipboard_provider == "wayland" then
  setup_wl_clipboard()
elseif clipboard_provider == "xclip" then
  setup_xclip_clipboard()
elseif clipboard_provider == "auto" then
  if vim.env.XDG_SESSION_TYPE == "wayland" or (not vim.env.XDG_SESSION_TYPE and vim.env.WAYLAND_DISPLAY) then
    setup_wl_clipboard()
  else
    setup_xclip_clipboard()
  end
end

vim.keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
vim.keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })
vim.keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" })
vim.keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" })
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertical" })
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontal" })
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })
vim.keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
vim.keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
vim.keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
vim.keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
vim.keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" })

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*",
  callback = function(args)
    vim.keymap.set("t", "jk", "<C-\\><C-n>", { desc = "Exit Terminal mode", buffer = args.buf, noremap = true, silent = true })
  end,
})
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.cmd("startinsert")
  end,
})
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  callback = function()
    if vim.bo.buftype == "terminal" and vim.fn.mode() == "n" then
      vim.cmd("startinsert")
    end
  end,
})

require("tokyonight").setup({
  style = "night",
  on_colors = function(colors)
    colors.bg = "#011628"
    colors.bg_dark = "#011423"
  end,
  on_highlights = function(hl, colors)
    -- Python: self / cls を赤 + italic で目立たせる (tree-sitter & LSP semantic tokens)
    hl["@variable.builtin.python"] = { fg = colors.red, italic = true }
    hl["@lsp.type.selfParameter.python"] = { fg = colors.red, italic = true }
    hl["@lsp.type.clsParameter.python"] = { fg = colors.red, italic = true }
    -- Python: デコレータ
    hl["@lsp.type.decorator.python"] = { fg = colors.yellow }
    -- Python: ドキュメント文字列をコメント色 + italic に
    hl["@string.documentation.python"] = { fg = colors.comment, italic = true }
    -- Python: 組み込み関数 (print, len, range ...) を cyan に
    hl["@function.builtin.python"] = { fg = colors.cyan }
    hl["@lsp.typemod.function.defaultLibrary.python"] = { fg = colors.cyan }
    -- Python: 組み込み型 (int, str, list ...) を yellow に
    hl["@type.builtin.python"] = { fg = colors.yellow }
    hl["@lsp.typemod.class.defaultLibrary.python"] = { fg = colors.yellow, bold = true }
    -- Python: マジックメソッド (__init__ 等) を magenta に
    hl["@lsp.typemod.function.magic.python"] = { fg = colors.magenta }
    hl["@lsp.typemod.method.magic.python"] = { fg = colors.magenta }
  end,
})
vim.cmd("colorscheme tokyonight")

local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")
dashboard.section.header.val = {
  "                                                     ",
  "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
  "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
  "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
  "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
  "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
  "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
  "                                                     ",
}
dashboard.section.buttons.val = {
  dashboard.button("e", "  > New File", "<cmd>ene<CR>"),
  dashboard.button("SPC ee", "  > Toggle file explorer", "<cmd>NvimTreeToggle<CR>"),
  dashboard.button("SPC ff", "󰱼 > Find File", "<cmd>Telescope find_files<CR>"),
  dashboard.button("SPC fs", "  > Find Word", "<cmd>Telescope live_grep<CR>"),
  dashboard.button("SPC wr", "󰁯  > Restore Session For Current Directory", "<cmd>SessionRestore<CR>"),
  dashboard.button("q", " > Quit NVIM", "<cmd>qa<CR>"),
}
alpha.setup(dashboard.opts)
vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])

require("auto-session").setup({
  auto_restore_enabled = false,
  auto_session_suppress_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
})
vim.keymap.set("n", "<leader>wr", "<cmd>SessionRestore<CR>", { desc = "Restore session for cwd" })
vim.keymap.set("n", "<leader>ws", "<cmd>SessionSave<CR>", { desc = "Save session for auto session root dir" })

local luasnip = require("luasnip")
local vscode_snippet_loader = require("luasnip.loaders.from_vscode")
vscode_snippet_loader.lazy_load()
local loaded_project_snippet_roots = {}

local function load_project_snippets(bufnr)
  bufnr = bufnr or 0
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == "" then
    return
  end

  local root = vim.fs.root(filename, { ".git", "flake.nix", "package.json" }) or vim.fs.root(filename, { ".vscode" })
  if not root or loaded_project_snippet_roots[root] then
    return
  end

  local vscode_dir = root .. "/.vscode"
  if vim.fn.isdirectory(vscode_dir) == 0 then
    loaded_project_snippet_roots[root] = true
    return
  end

  local snippet_files = vim.fs.find(function(name)
    return name:match("%.code%-snippets$")
  end, {
    path = vscode_dir,
    type = "file",
    limit = math.huge,
  })

  for _, path in ipairs(snippet_files) do
    vscode_snippet_loader.load_standalone({
      path = path,
      lazy = true,
      override_priority = 2000,
    })
  end

  loaded_project_snippet_roots[root] = true
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  callback = function(args)
    load_project_snippets(args.buf)
  end,
})

local default_sources = { "lsp", "path", "snippets", "buffer" }
local providers = {}

if lang.latex then
  table.insert(default_sources, "vimtex")
  providers.vimtex = {
    name = "vimtex",
    module = "blink.compat.source",
    score_offset = 100,
  }
end

require("blink.cmp").setup({
  keymap = {
    preset="enter",
    ["<Tab>"]={
      "select_next",
      "snippet_forward",
      "fallback",
    },
    ["<S-Tab>"]={
      "select_prev",
      "snippet_backward",
      "fallback"
    },
    ["<CR>"]={
      "accept",
      "fallback",
    },
  },
  snippets = {
    preset = "luasnip",
  },
  sources = {
    default = default_sources,
    providers = providers,
  },
  completion = {
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
    },
  },
  signature = {
    enabled = true,
  },
})

require("nvim-autopairs").setup({
  check_ts = true,
  ts_config = {
    lua = { "string" },
    javascript = { "template_string" },
    java = false,
  },
})

require("bufferline").setup({ options = { mode = "tabs", separator_style = "slant" } })
vim.keymap.set("i", "<C-L>", "<Plug>(copilot-accept-word)", { desc = "Copilot Accept Word" })
vim.keymap.set("i", "<C-J>", "<Plug>(copilot-next)", { desc = "Copilot Next Suggestion" })
vim.keymap.set("i", "<C-K>", "<Plug>(copilot-previous)", { desc = "Copilot Previous Suggestion" })

local dap = require("dap")
require("dapui").setup({ controls = { icons = { disconnect = "⏻" } } })
require("nvim-dap-virtual-text").setup()
vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected", { text = "󰉥", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapLogPoint", { text = "", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "", texthl = "", linehl = "", numhl = "" })
vim.keymap.set("n", "<leader>du", function() require("dapui").toggle() end, { desc = "Toggle DAP UI" })
vim.keymap.set("n", "<leader>db", function() require("dap").toggle_breakpoint() end, { desc = "Toggle Breakpoint" })
vim.keymap.set("n", "<leader>dc", function() require("dap").continue() end, { desc = "DAP Continue" })
if lang.python then
  require("dap-python").setup(python_dap_python)
  require("dap-python").test_runner = "pytest"
  vim.keymap.set("n", "<leader>dpt", function() require("dap-python").test_method() end, { desc = "Debug Python test" })
  vim.keymap.set("n", "<leader>dpc", function() require("dap-python").test_class() end, { desc = "Debug Python test class" })
  vim.keymap.set("v", "<leader>dps", function() require("dap-python").debug_selection() end, { desc = "Debug Python selection" })
end

require("diffview").setup({
  enhanced_diff_hl = true,
  use_icons = true,
  view = {
    default = { layout = "diff2_horizontal" },
    merge_tool = { layout = "diff4_mixed", disable_diagnostics = true },
  },
})
vim.keymap.set("n", "<leader>gv", "<cmd>DiffviewOpen<cr>", { desc = "Open diff view" })
vim.keymap.set("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "Open file history" })
vim.keymap.set("n", "<leader>gB", "<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<cr>", { desc = "Review branch changes" })

require("dressing").setup()
require("fusen").setup()
require("ibl").setup({ indent = { char = "┊" } })
require("markview").setup()
require("yanky").setup({
  ring = {
    history_length = 100,
    storage = "shada",
  },
})
require("nvim-surround").setup()

local formatters = {}
local formatters_by_ft = { lua = { "stylua" } }

if lang.go then
  formatters.golines = {
    command = "golines",
    args = { "--base-formatter=gofumpt" },
    stdin = true,
  }
  formatters_by_ft.go = { "goimports", "golines" }
end
if lang.node then
  vim.tbl_deep_extend("force", formatters_by_ft, {
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },
    svelte = { "prettier" },
    css = { "prettier" },
    html = { "prettier" },
    json = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    graphql = { "prettier" },
    liquid = { "prettier" },
  })
end
if lang.python then
  formatters_by_ft.python = { "ruff_organize_imports", "ruff_fix", "ruff_format" }
end
if lang.ruby then
  formatters_by_ft.eruby = { "htmlbeautifier" }
end
if lang.latex then
  formatters.latexindent = { command = "latexindent", args = { "-m" }, stdin = true }
  formatters_by_ft.tex = { "latexindent" }
end
if lang.nix then
  formatters_by_ft.nix = { "nixfmt" }
end
if lang.rust then
  formatters_by_ft.rust = { "rustfmt" }
end

require("conform").setup({
  formatters = formatters,
  formatters_by_ft = formatters_by_ft,
  format_on_save = { lsp_format = "fallback", timeout_ms = 10000 },
  default_format_opts = { lsp_format = "fallback" },
})
vim.keymap.set({ "n", "v" }, "<leader>mp", function()
  require("conform").format({ lsp_format = "fallback", timeout_ms = 10000 })
end, { desc = "Format file or range (in visual mode)" })

require("gitsigns").setup({
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end
    map("n", "]h", gs.next_hunk, "Next Hunk")
    map("n", "[h", gs.prev_hunk, "Prev Hunk")
    map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
    map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
    map("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage hunk")
    map("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset hunk")
    map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
    map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
    map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
    map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
    map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
    map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle line blame")
    map("n", "<leader>hd", gs.diffthis, "Diff this")
    map("n", "<leader>hD", function() gs.diffthis("~") end, "Diff this ~")
    map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Gitsigns select hunk")
  end,
})

local lint = require("lint")
lint.linters_by_ft = {}
if lang.node then
  lint.linters_by_ft.javascript = { "eslint_d" }
  lint.linters_by_ft.typescript = { "eslint_d" }
  lint.linters_by_ft.javascriptreact = { "eslint_d" }
  lint.linters_by_ft.typescriptreact = { "eslint_d" }
  lint.linters_by_ft.svelte = { "eslint_d" }
end
local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
  group = lint_augroup,
  callback = function()
    lint.try_lint()
  end,
})
vim.keymap.set("n", "<leader>l", function() lint.try_lint() end, { desc = "Trigger linting for current file" })

require("lualine").setup({
  sections = {
    lualine_c = { { "filename", path = 1 } },
    lualine_x = {
      {
        function() return require("dap").status() end,
        icon = { "", color = { fg = "#afdf00" } },
        cond = function()
          if not package.loaded.dap then return false end
          return require("dap").session() ~= nil
        end,
      },
    },
  },
  options = { disable_filetype = { winbar = { "dap-repl" } } },
})

require("nvim-tree").setup({
  view = { width = 35, relativenumber = true },
  renderer = {
    indent_markers = { enable = true },
    icons = { glyphs = { folder = { arrow_closed = "", arrow_open = "" } } },
  },
  actions = { open_file = { window_picker = { enable = false } } },
  git = { ignore = false },
  filters = { custom = { "^\\.git$", "node_modules", "^\\.cache$" } },
})
vim.keymap.set("n", "<leader>ee", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explore" })
vim.keymap.set("n", "<leader>ef", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Toggle file explore on current file" })
vim.keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse file explore" })
vim.keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explore" })

local substitute = require("substitute")
substitute.setup()
vim.keymap.set("n", "s", substitute.operator, { desc = "Substitute with motion" })
vim.keymap.set("n", "ss", substitute.line, { desc = "Substitute line" })
vim.keymap.set("n", "S", substitute.eol, { desc = "Substitute to end of line" })
vim.keymap.set("x", "s", substitute.visual, { desc = "Substitute in visual mode" })

local telescope = require("telescope")
local actions = require("telescope.actions")
telescope.setup({
  defaults = {
    path_display = { "smart" },
    mappings = { i = {
      ["<C-k>"] = actions.move_selection_previous,
      ["<C-j>"] = actions.move_selection_next,
      ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
    } },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  },
})
telescope.load_extension("fzf")
telescope.load_extension("yank_history")
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
vim.keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
vim.keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
vim.keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })
vim.keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
vim.keymap.set("n", "<leader>fy", "<cmd>Telescope yank_history<cr>", { desc = "Fuzzy find yank history" })
vim.keymap.set("n", "<leader>fm", ":Telescope fusen marks<CR>", { desc = "Find fusen marks" })

local todo_comments = require("todo-comments")
vim.keymap.set("n", "]t", function() todo_comments.jump_next() end, { desc = "Next todo comment" })
vim.keymap.set("n", "[t", function() todo_comments.jump_prev() end, { desc = "Previous todo comment" })
todo_comments.setup()

require("toggleterm").setup({
  size = 20,
  open_mapping = [[<c-t>]],
  shade_filetypes = {},
  shade_terminals = true,
  shading_factor = 2,
  start_in_insert = true,
  insert_mappings = true,
  persist_size = true,
  direction = "horizontal",
  close_on_exit = true,
  shell = vim.o.shell,
  float_opts = { border = "curved", winblend = 0, highlights = { border = "Normal", background = "Normal" } },
  on_open = function(term)
    vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<ESC>", "<C-\\><C-n>", { desc = "Exit Terminal mode", noremap = true, silent = true })
    pcall(vim.keymap.del, "t", "jk", { buffer = term.bufnr })
  end,
})
local Terminal = require("toggleterm.terminal").Terminal
local lazygit = Terminal:new({
  cmd = "lazygit",
  direction = "float",
  hidden = true,
  on_open = function(term)
    vim.cmd("startinsert!")
    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
    pcall(vim.keymap.del, "t", "jk", { buffer = term.bufnr })
    pcall(vim.keymap.del, "t", "<Esc>", { buffer = term.bufnr })
  end,
  on_close = function() vim.cmd("startinsert!") end,
})
function _lazygit_toggle()
  lazygit:toggle()
end
vim.api.nvim_set_keymap("n", "<leader>gg", "<cmd>lua _lazygit_toggle()<CR>", { noremap = true, silent = true })
local gh_dash = Terminal:new({
  cmd = "gh dash",
  direction = "float",
  hidden = true,
  on_open = function(term)
    vim.cmd("startinsert!")
    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
    pcall(vim.keymap.del, "t", "jk", { buffer = term.bufnr })
    pcall(vim.keymap.del, "t", "<Esc>", { buffer = term.bufnr })
  end,
  on_close = function() vim.cmd("startinsert!") end,
})
function _gh_dash_toggle()
  gh_dash:toggle()
end
vim.api.nvim_set_keymap("n", "<leader>gd", "<cmd>lua _gh_dash_toggle()<CR>", { noremap = true, silent = true })

require("nvim-treesitter.configs").setup({
  highlight = {
    enable = true,
    disable = { "latex", "tex" },
  },
  indent = {
    enable = true,
    disable = { "latex", "tex" },
  },
  autotag = { enable = true },
  ensure_installed = {},
})

require("trouble").setup({ focus = true })
vim.keymap.set("n", "<leader>xw", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Open trouble workspace diagnostics" })
vim.keymap.set("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Open trouble document diagnostics" })
vim.keymap.set("n", "<leader>xq", "<cmd>Trouble quickfix toggle<CR>", { desc = "Open trouble quickfix list" })
vim.keymap.set("n", "<leader>xl", "<cmd>Trouble loclist toggle<CR>", { desc = "Open trouble location list" })
vim.keymap.set("n", "<leader>xt", "<cmd>Trouble todo toggle<CR>", { desc = "Open todos in trouble" })

vim.keymap.set("n", "<leader>sm", "<cmd>MaximizerToggle<CR>", { desc = "Maximize/minimize a split" })
vim.keymap.set("n", "<leader>trw", "<Plug>TranslateW", { noremap = false, silent = true })
vim.keymap.set("v", "<leader>trw", "<Plug>TranslateWV", { noremap = false, silent = true })

local wk = require("which-key")
wk.add({
  { "<leader>e", group = "Explolar" },
  { "<leader>s", group = "Split window" },
  { "<leader>f", group = "Finder" },
  { "<leader>t", group = "Tabs" },
  { "<leader>x", group = "Trouble" },
  { "<leader>w", group = "Session" },
  { "<leader>h", group = "Git" },
})
vim.keymap.set("n", "<leader>?", function() require("which-key").show({ global = true }) end, { desc = "Buffer Local Keymaps (which-key)" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local opts = { buffer = ev.buf, silent = true }
    opts.desc = "Show LSP references"
    vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)
    opts.desc = "Go to declaration"
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    opts.desc = "Show LSP definitions"
    vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
    opts.desc = "Show LSP implementations"
    vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
    opts.desc = "Show LSP type definitions"
    vim.keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)
    opts.desc = "See available code actions"
    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
    opts.desc = "Smart rename"
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    opts.desc = "Show buffer diagnostics"
    vim.keymap.set("n", "<leader>gdD", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)
    opts.desc = "Show line diagnostics"
    vim.keymap.set("n", "<leader>gdd", vim.diagnostic.open_float, opts)
    opts.desc = "Go to previous diagnostic"
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
    opts.desc = "Go to next diagnostic"
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
    opts.desc = "Show documentation for what is under cursor"
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    opts.desc = "Restart LSP"
    vim.keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
    opts.desc = "Toggle LSP inlay hints"
    vim.keymap.set("n", "<leader>li", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end, opts)
  end,
})

require("lsp-file-operations").setup()
require("neodev").setup()
vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end
vim.lsp.config("lua_ls", {
  settings = { Lua = { diagnostics = { globals = { "vim" } }, completion = { callSnippet = "Replace" } } },
})
if lang.node then
  vim.lsp.config("ts_ls", {
    init_options = {
      preferences = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
        importModuleSpecifierPreference = "non-relative",
      },
    },
  })
end
if lang.nix then
  vim.lsp.config("nil_ls", { formatting = { command = { "nixfmt" } } })
end
if lang.latex then
  vim.lsp.config("texlab", {
    root_markers = { ".texlabroot", "texlabroot", ".latexmkrc", "latexmkrc", "Tectonic.toml", ".git" },
    settings = {
      texlab = {
        build = {
          executable = "latexmk",
          args = {
            "-pdf",
            "-interaction=nonstopmode",
            "-synctex=1",
            "%f",
          },
          onSave = false,
          useFileList = true,
        },
        chktex = {
          onOpenAndSave = false,
          onEdit = false,
        },
        diagnosticsDelay = 300,
      },
    },
  })

  vim.g.vimtex_compiler_method = "latexmk"
  vim.g.vimtex_compiler_latexmk = {
    continuous = 0,
    options = {
      "-pdf",
      "-verbose",
      "-file-line-error",
      "-synctex=1",
      "-interaction=nonstopmode",
    },
  }
  vim.g.vimtex_quickfix_mode = 2
  vim.g.vimtex_quickfix_open_on_warning = 0
  vim.g.vimtex_quickfix_autojump = 0
  vim.g.vimtex_syntax_conceal_disable = 0
  vim.opt.conceallevel = 2
  vim.opt.concealcursor = "nc"

  -- VimTeX conceal の切り替え
  vim.keymap.set("n", "<localleader>lz", function()
    vim.wo.conceallevel = vim.wo.conceallevel == 0 and 2 or 0
    vim.wo.concealcursor = "nc"
  end, { desc = "Toggle VimTeX conceal" })

  -- nabla.nvim の数式プレビュー切り替え
  vim.keymap.set("n", "<localleader>ln", function()
    require("nabla").toggle_virt({ autogen = true, silent = true })
  end, { desc = "Toggle Nabla math preview" })
end
if lang.go then
  vim.lsp.config("gopls", {
    root_markers = { "go.work", "go.mod", ".git" },
    settings = {
      gopls = {
        completeUnimported = true,
        gofumpt = true,
        staticcheck = true,
        usePlaceholders = true,
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
      },
    },
  })
end
if lang.python then
  vim.lsp.config("basedpyright", {
    settings = {
      basedpyright = {
        analysis = {
          autoImportCompletions = true,
          autoSearchPaths = true,
          diagnosticMode = "workspace",
          inlayHints = {
            callArgumentNames = true,
            functionReturnTypes = true,
            genericTypes = true,
            variableTypes = true,
          },
          typeCheckingMode = "standard",
          useLibraryCodeForTypes = true,
        },
      },
      python = {
        analysis = {
          autoImportCompletions = true,
          autoSearchPaths = true,
          diagnosticMode = "workspace",
          typeCheckingMode = "standard",
          useLibraryCodeForTypes = true,
        },
      },
    },
  })
  vim.lsp.config("ruff", {
    init_options = {
      settings = {
        organizeImports = true,
      },
    },
    on_attach = function(client)
      client.server_capabilities.hoverProvider = false
    end,
  })
end
if lang.ruby then
  vim.lsp.config("ruby_lsp", {
    filetypes = { "ruby" },
    cmd = { "ruby-lsp" },
    root_markers = { "gemfile", ".git" },
    init_options = { formatter = "standard", linters = { "standard" } },
  })
  vim.lsp.config("solargraph", {
    filetypes = { "ruby" },
    cmd = { "solargraph", "stdio" },
    root_markers = { "gemfile", ".git" },
    init_options = { formatting = true },
  })
end
vim.lsp.config("typos_lsp", {
  cmd = { "typos-lsp" },
  init_options = { config = "@TYPOS_CONFIG@" },
})
vim.lsp.config("harper_ls", {
  cmd = { "harper-ls", "--stdio" },
  filetypes = { "gitcommit", "latex", "markdown", "norg", "org", "plaintex", "rst", "tex", "text", "typst" },
  settings = {
    ["harper-ls"] = {
      diagnosticSeverity = "warning",
      linters = {
        SpellCheck = true,
      },
    },
  },
})
local lsp_servers = { "lua_ls", "harper_ls", "typos_lsp" }
if lang.node then
  vim.list_extend(lsp_servers, { "ts_ls", "html", "cssls", "tailwindcss", "graphql", "emmet_ls", "prismals" })
end
if lang.go then
  table.insert(lsp_servers, "gopls")
end
if lang.python then
  vim.list_extend(lsp_servers, { "basedpyright", "ruff" })
end
if lang.ruby then
  table.insert(lsp_servers, "solargraph")
end
if lang.nix then
  table.insert(lsp_servers, "nil_ls")
end
if lang.latex then
  table.insert(lsp_servers, "texlab")
end
for _, server in ipairs(lsp_servers) do
  pcall(vim.lsp.enable, server)
end

if lang.rust then
  vim.g.rustaceanvim = {
    server = {
      default_settings = {
        ["rust-analyzer"] = {
          cargo = { autoreload = true, allTargets = true, allFeatures = true, buildScripts = { enable = true } },
          procMacro = { enable = true },
          files = { watcher = "client" },
          -- checkOnSave = { command = "clippy", extraArgs = { "--all", "--", "-W", "clippy::all" } },
          diagnostics = { disabled = { "E0308", "E0605" } },
          inlayHints = {
            closureCaptureHints = { enable = true },
            closureReturnTypeHints = { enable = "always" },
            expressionAdjustmentHints = { enable = "always" },
            lifetimeElisionHints = { enable = "skip_trivial" },
            rangeExclusiveHints = { enable = true },
            reborrowHints = { enable = "always" },
          },
        },
      },
    },
  }
  require("rustowl").setup({
    auto_enable = true,
    highlight_style = "underline",
    client = {
      on_attach = function(_, buffer)
        vim.keymap.set("n", "<leader>o", function() require("rustowl").toggle(buffer) end, { buffer = buffer, desc = "Toggle RustOwl" })
      end,
    },
  })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "rust",
    callback = function(args)
      local function run_rust_with_args()
        local input = vim.fn.input("cargo run args: ")
        local cmd = { "runnables" }
        for _, arg in ipairs(vim.split(input, "%s+", { trimempty = true })) do
          table.insert(cmd, arg)
        end
        vim.cmd.RustLsp(cmd)
      end
      vim.keymap.set("n", "K", function() vim.cmd.RustLsp({ "hover", "actions" }) end, { silent = true, buffer = args.buf })
      vim.keymap.set("n", "<leader>rr", run_rust_with_args, { silent = true, buffer = args.buf, desc = "Run Rust project with args" })
      vim.keymap.set("n", "<leader>rd", function() vim.cmd.RustLsp("debuggables") end, { silent = true, buffer = args.buf, desc = "Debug Rust project" })
      vim.keymap.set("n", "<leader>rt", function() vim.cmd.RustLsp("testables") end, { silent = true, buffer = args.buf, desc = "Run Rust tests" })
    end,
  })
end

if lang.lean then
  vim.lsp.config("leanls", {
    on_attach = function()
      vim.keymap.localleader = "  "
      vim.keymap.set("n", "<leader><leader>i", "<cmd>LeanInfoviewToggle<CR>", { desc = "Toggle lean infoview", noremap = true })
    end,
  })
  require("lean").setup()
  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = true,
    virtual_text = { spacing = 4 },
    update_in_insert = true,
  })
end
