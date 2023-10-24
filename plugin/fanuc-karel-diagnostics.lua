local ns = vim.api.nvim_create_namespace('fanuc-karel-diagnostics')

local function flatten(arr)
    local results = {}
    local function arrFlatten(arr)
        for _, v in ipairs(arr) do
            if type(v) == "table" then
                arrFlatten(v)
            else
                results[#results+1] = v
            end
        end
    end
    arrFlatten(arr)
    return results
end

function run_ktrans(karelfile)
    local message = {}
    local append_data = function(_, data)
        table.insert(message,data)
    end
    local job = vim.fn.jobstart(
        'ktrans ' .. karelfile,
        {
            on_stdout = append_data,
            on_stderr = append_data,
        }
    )
    vim.fn.jobwait({job})
    message = flatten(message)
    local removeEmpty = {}
    for _, v in ipairs(message) do
        if v == "" then
        else
            table.insert(removeEmpty, v)
        end
    end
    return removeEmpty
end

function parse_result(result)
    local diag = {}
    for i, v in ipairs(result) do
        local lineStr, _ = string.match(v,"^%s*(%d+).+$")
        if lineStr == nil then goto continue end -- not a match
        local line = tonumber(lineStr)
        local colStr = result[i+1]
        local s, _ = string.find(colStr, '%^')
        local col = tonumber(s)-6
        local msg = result[i+2]
        table.insert(diag, {
            lnum = line - 1,
            col =  col,
            message = msg,
            severtiy =  vim.diagnostic.severity.E,
        })
        ::continue::
    end
    return diag
end

function Callback_fn()
    -- Run ktrans
    local bufname = vim.api.nvim_buf_get_name(0)
    local result = run_ktrans(bufname)
    -- Parse output
    local diag = parse_result(result)
    -- report diagnostics
    vim.diagnostic.set(ns, 0, diag, nil)
end

vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.kl",
    group = vim.api.nvim_create_augroup("FanucKarelDiagnostics", {clear = true}),
    callback = Callback_fn,
})

