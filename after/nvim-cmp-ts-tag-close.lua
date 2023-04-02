local ok, cmp = pcall(require, "cmp")
if ok then
  cmp.register_source("nvim-cmp-ts-tag-close", require("nvim-cmp-ts-tag-close").new())
end
