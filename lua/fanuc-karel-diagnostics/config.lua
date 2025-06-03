local M = {}

local defaults = {
	ktrans_cwd = nil,
	ktrans_args = {},
}

M.options = nil

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", {}, defaults, opts or {})
end

M.setup()

return M
