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

	-- extend table with args from config.options
	cmd = vim.list_extend(cmd, config.options.ktrans_args or {})

	print("Running command: " .. table.concat(cmd, " "))
	jobId = vim.fn.jobstart(cmd, {
		cwd = config.options.ktrans_cwd,
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, d)
			on_complete(d)
		end,
		on_stderr = function(_, d)
			-- Print stderr output to the command line
			print_lines(d)
		end,
	})
end

function print_lines(data)
	for _, line in ipairs(data) do
		if line and line ~= "" then
			print(line)
		end
	end
end

function parse_result(result)
	-- print lua table
	print_lines(result)
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
	-- Get full path of the current file
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
		-- Check if config cwd is nil
		if config.options.ktrans_cwd ~= nil then
			bufname = vim.fs.joinpath(config.options.ktrans_cwd, vim.fs.basename(bufname))
		end
		print("Removing: " .. bufname)

		local success = os.remove(string.gsub(bufname, ".kl", ".pc"))
		print("Removed: " .. tostring(success))
		-- Parse output
		local diag = parse_result(d)
		-- report diagnostics
		vim.diagnostic.set(ns, 0, diag, nil)
	end)
end

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "*.kl",
	group = vim.api.nvim_create_augroup("FanucKarelDiagnostics", { clear = true }),
	callback = Callback_fn,
})

return M
