local M = {}
local va = vim.api
local vf = vim.fn

M.config = {
	separator = " || ",
}

function M.calculate_project_words()
	local filepath = vf.expand("%:p")
	if filepath == "" then
		return
	end
	local file_dir = vf.expand("%:p:h")

	-- 1. Grab Git Root Path
	local repo_root = string.gsub(
		vf.system("git -C " .. vf.shellescape(file_dir) .. " rev-parse --show-toplevel 2>/dev/null"),
		"\n",
		""
	)
	if vim.v.shell_error ~= 0 or repo_root == "" then
		print("GitWords: This directory is not tracked by Git.")
		return
	end

	-- 2. Determine Main Target Document
	local main_tex = repo_root .. "/main.tex"
	if vf.filereadable(main_tex) == 0 then
		main_tex = filepath
	end

	-- Explicitly calculate path relative to the repo root folder (not Neovim's cwd)
	local relative_main = string.sub(main_tex, string.len(repo_root) + 2)

	-- 3. CURRENT: Calculate true prose words across live workspace files
	local current_cmd = "texcount -1 -sum -merge " .. vf.shellescape(relative_main) .. " 2>/dev/null"
	local current_raw = vf.system("cd " .. vf.shellescape(repo_root) .. " && " .. current_cmd)
	local current_total = tonumber(string.match(current_raw or "0", "(%d+)")) or 0

	-- --- NEW: Log wordcount and timestamp to .cls file ---
	local log_file_path = repo_root .. "/wordcount.cls"
	local log_file = io.open(log_file_path, "a")
	if log_file then
		local timestamp = os.date("%Y-%m-%d %H:%M:%S")
		log_file:write(string.format("[%s] Total Word Count: %d\n", timestamp, current_total))
		log_file:close()
	else
		print("GitWords: Could not write to " .. log_file_path)
	end
	-- -----------------------------------------------------

	-- 4. PAST: Safely extract a pure commit copy to a temporary sandbox
	local tmp_dir = vf.trim(vf.system("mktemp -d 2>/dev/null"))
	if tmp_dir == "" or vim.v.shell_error ~= 0 then
		print("GitWords: Failed to build temporary workspace allocation.")
		return
	end

	-- Export the historical Git archive layout into our temporary directory
	vf.system("git -C " .. vf.shellescape(repo_root) .. " archive HEAD | tar -x -C " .. vf.shellescape(tmp_dir))

	-- Calculate historical words cleanly with absolute separation
	local past_raw = vf.system("cd " .. vf.shellescape(tmp_dir) .. " && " .. current_cmd)
	local past_total = tonumber(string.match(past_raw or "0", "(%d+)")) or 0

	-- Delete the temporary directory to clean up system assets
	vf.system("rm -rf " .. vf.shellescape(tmp_dir))

	-- 5. Calculate precise delta additions
	local added_words = current_total - past_total
	if added_words < 0 then
		added_words = 0
	end

	-- Print out exactly one row matching your target specification
	print("+ " .. added_words .. M.config.separator .. past_total .. " words")
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	va.nvim_create_user_command("LatexWordsSince", function()
		M.calculate_project_words()
	end, {})
end

return M
