local M = {}

function M.get_clone_informations()
  local repo_cache = require("reposcope.cache.repository_cache")
  local reposcope_config = require("reposcope.config")
  local repo = repo_cache.get_selected()

  if type(repo) ~= "table" then
    vim.notify("[reposcope] Select a repository before cloning", vim.log.levels.WARN)
    return nil
  end

  local name = repo.name
  local owner = type(repo.owner) == "table" and repo.owner.login or nil
  if type(name) ~= "string" or name == "" then
    vim.notify("[reposcope] Selected repository has no name", vim.log.levels.ERROR)
    return nil
  end

  local clone_type = reposcope_config.options.clone.type
  local url
  if clone_type == "gh" and type(owner) == "string" and owner ~= "" then
    url = owner .. "/" .. name
  elseif clone_type == "ssh" then
    url = repo.ssh_url or repo.clone_url or repo.html_url
  else
    url = repo.clone_url or repo.html_url or repo.ssh_url
  end

  if type(url) ~= "string" or url == "" then
    vim.notify("[reposcope] Selected repository has no clone URL", vim.log.levels.ERROR)
    return nil
  end

  return { name = name, url = url }
end

return M
