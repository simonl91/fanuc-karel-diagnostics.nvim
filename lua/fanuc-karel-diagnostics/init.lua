local M = {}

local ns = vim.api.nvim_create_namespace("fanuc-karel-diagnostics")
local jobId = 0
local config = require("fanuc-karel-diagnostics.config")

function M.setup(opts)
	config.setup(opts)
end

function run_ktrans(karelfile, on_complete)
	-- Stop ongoing job
	local running = vim.fn.jobwait({ jobId }, 0)[1] == -1
	if running then
		local res = vim.fn.jobstop(jobId)
	end

	local cmd = { "ktrans", karelfile }
	cmd = vim.list_extend(cmd, config.options.ktrans_args or {}) -- extend table with args from config.options.ktrans_args

	jobId = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, d)
			on_complete(d)
		end,
	})
end

function parse_result(result)
	local diag = {}
	for i, v in ipairs(result) do
		local lineStr, _ = string.match(v, "^%s*(%d+).+$")
		if lineStr == nil then
			goto continue
		end -- not a match
		local line = tonumber(lineStr)
		local colStr = result[i + 1]
		local s, _ = string.find(colStr, "%^")
		local col = tonumber(s) - 6
		local msg = result[i + 2]
		table.insert(diag, {
			lnum = line - 1,
			col = col,
			message = msg,
			severtiy = vim.diagnostic.severity.E,
		})
		::continue::
	end
	return diag
end

-- Run ktrans on save
function Callback_fn()
	-- Get full path of the current file opened in the current buffer
	local bufname = vim.api.nvim_buf_get_name(0)

	-- Skip files that are includes, and not compilable by them selves
	-- .th.kl and .h.kl are only a convention, but they are used to indicate
	-- header files.
	if string.find(bufname, ".th.kl") then
		do
			return
		end
	end
	if string.find(bufname, ".h.kl") then
		do
			return
		end
	end

	run_ktrans(bufname, function(d)
		bufname = vim.fs.joinpath(vim.fn.getcwd(), vim.fs.basename(bufname))
		os.remove(string.gsub(bufname, ".kl", ".pc"))
		-- Parse output
		local diag = parse_result(d)
		-- report diagnostics
		vim.diagnostic.set(ns, 0, diag, { virtual_text = config.options.virtual_text })
	end)
end

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "*.kl",
	group = vim.api.nvim_create_augroup("FanucKarelDiagnostics", { clear = true }),
	callback = Callback_fn,
})

return M
