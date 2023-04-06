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
  return '</'..name:sub(2)..'>'
end



local function get_closing_tag()
  local target = ts_utils.get_node_at_cursor()

  if target == nil then
    return nil
  end

  local depth = 0
  local unopened = 0

  local current_node = nil

  if target:type() == 'fragment' then
    target =  target:child()
    current_node = target:child(target:child_count()-1)
  elseif target:child_count() < 2 then
    current_node = target:prev_sibling()
  else
    current_node = target:child(target:child_count()-1)
  end

  local function traverse_tree() 
    while current_node ~= nil and depth < 20 do

      depth = depth + 1
      local node_type = current_node:type()

      if node_type == 'ERROR' and current_node:child_count() > 0 then
        local entry = current_node
        current_node = current_node:child(current_node:child_count()-1)
        local result_in_error_node = traverse_tree()

        if result_in_error_node ~= nil then
          return result_in_error_node
        end
        current_node = entry
      end

      if node_type == nil then
        return nil
      end

      if includes(open_tag, node_type) then
        if unopened == 0 then
          local name = ts_utils.get_node_text(current_node)[1]

          name = to_close_tag(name)

          if M.skip_tags ~= nil and includes(M.skip_tags, name:sub(3, -2)) then
            return nil
          end

          if name == "" then
            return "</>"
          end

          return name
        else
          unopened = unopened - 1 
        end
      end

      if includes(close_tag, node_type) then
        unopened = unopened + 1
      end

      current_node = current_node:prev_sibling()
    end
    return nil
  end

  return traverse_tree()
end


local parse_and_get_closing_tag = function()
  local buf_parser = parsers.get_parser()
  if not buf_parser then
    return nil
  end
  buf_parser:parse()
  return get_closing_tag()
end

function source:get_debug_name() return 'ts-autotag' end
function source:get_trigger_characters() return { '<' } end

function source:complete(_, callback)
  local closing_tag = parse_and_get_closing_tag()
  if closing_tag == nil then
    callback()
  end
  callback({{label = closing_tag}})
end
function source:resolve(completion, callback) callback(completion) end
function source:execute(completion, callback) callback(completion) end

function source:is_available()
  return includes(M.filetypes, vim.bo.filetype)
end

M.setup = function(opts)
    opts = opts or {}
    M.skip_tags = opts.skip_tags or M.skip_tags 
    M.filetypes = opts.filetypes or { 'html', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'svelte', 'vue', 'tsx', 'jsx', 'rescript', 'xml', 'php', 'markdown', 'glimmer', 'handlebars', 'hbs', 'htmldjango' }
    require('cmp').register_source('nvim-cmp-ts-tag-close', source)
end

return M
