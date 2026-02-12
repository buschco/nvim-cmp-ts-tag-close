local _, ts_utils = pcall(require, 'nvim-treesitter.ts_utils')
local parsers = require('nvim-treesitter.parsers')

local M = {}
local source = {}

local open_tag = { 'jsx_opening_element', 'start_tag', 'element_node_start' }
local close_tag = { 'jsx_closing_element', 'end_tag', 'element_node_end' }

local function includes(tbl, val)
  if tbl == nil then
    return false
  end
  for _, value in pairs(tbl) do
    if val == value then
      return true
    end
  end
  return false
end

local function to_close_tag(name)
  local space = name:find('%s')

  if space ~= nil then
    name = name:sub(0, space):gsub('%s+', '')
  else
    space = name:find('%c')
    if space ~= nil then
      name = name:sub(0, space):gsub('%s+', '')
    end
  end
  name = name:gsub('>', '')
  return '</' .. name:sub(2) .. '>'
end

local query = vim.treesitter.query.parse(
  "tsx",
  [[
    (jsx_opening_element) @open
    (jsx_closing_element) @close
  ]]
)

local function get_closing_tag_v3(tree, row, col)
  local bufnr = vim.api.nvim_get_current_buf()
  if not tree then
    print("no tree")
    return nil
  end

  local unclosed = {}

  for id, node, _ in query:iter_captures(tree:root()) do
    local kind = query.captures[id]
    local node_row, node_col, _, _ = node:range()
    if not node:child(1) then break end
    local name = vim.treesitter.get_node_text(node:child(1), bufnr)

    if node_row < row or (node_row == row and node_col < col) then
      if kind == "open" then
        if name ~= "" and name ~= "}" then
          table.insert(unclosed, name)
        end
      elseif kind == "close" then
        for i = #unclosed, 1, -1 do
          if unclosed[i] == name then
            table.remove(unclosed, i)
            break
          end
        end
      end
    end
  end


  print(table.concat(unclosed, ", "))
  local to_be_closed = unclosed[#unclosed]
  if not to_be_closed then
    print "nothing to be closed"
    return nil
  end
  return to_close_tag("<" .. to_be_closed)
end

local parse_and_get_closing_tag = function()
  local buf_parser = parsers.get_parser()
  if not buf_parser then
    return nil
  end
  local tree = buf_parser:parse()[1]
  local pos = vim.api.nvim_win_get_cursor(0)
  return get_closing_tag_v3(tree, pos[1], pos[2])
end

function source:get_debug_name() return 'ts-autotag' end

function source:get_trigger_characters() return { '<' } end

function source:complete(_, callback)
  local closing_tag = parse_and_get_closing_tag()
  if closing_tag == nil then
    callback()
  end
  callback({ { label = closing_tag } })
end

function source:resolve(completion, callback) callback(completion) end

function source:execute(completion, callback) callback(completion) end

function source:is_available()
  return includes(M.filetypes, vim.bo.filetype)
end

M.setup = function(opts)
  opts = opts or {}
  M.skip_tags = opts.skip_tags or M.skip_tags
  M.filetypes = opts.filetypes or {
    'html',
    'javascript',
    'typescript',
    'javascriptreact',
    'typescriptreact',
    'svelte',
    'vue',
    'tsx',
    'jsx',
    'rescript',
    'xml',
    'php',
    'markdown',
    'glimmer',
    'handlebars',
    'hbs',
    'htmldjango'
  }
  require('cmp').register_source('nvim-cmp-ts-tag-close', source)
end

return M
