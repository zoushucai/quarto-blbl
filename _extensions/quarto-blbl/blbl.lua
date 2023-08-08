---- --- 方法 2 -- 定义有序 table
-- 1.定义一个有序的 table，用于存储参数, 格式如下
-- local optionalParams1 = {
--   {name = "aid", value = "aid1"},
--   {name = "cid", value = "cid1"}
-- }
-- 2.合并多个 table，保留原来的顺序
local function mergeOrderedTables(...)
  local mergedTable = {}
  local orderedKeys = {}

  for _, tableToMerge in ipairs({...}) do
      for _, entry in ipairs(tableToMerge) do
          if mergedTable[entry.name] == nil then
              table.insert(orderedKeys, entry.name)
          end
          mergedTable[entry.name] = entry.value
      end
  end

  local orderedMergedTable = {}
  for _, key in ipairs(orderedKeys) do
      table.insert(orderedMergedTable, {
          name = key,
          value = mergedTable[key]
      })
  end

  return orderedMergedTable
end

-- 3.连接 table 中的所有值
local function concatenateParams(params, sep, collapse)
  sep = sep or "="
  collapse = collapse or "&"
  -- 以上两个参数都是可选的，如果不传入，就使用默认值

  local concatenatedString = ""
  for _, entry in ipairs(params) do
      concatenatedString = concatenatedString .. entry.name .. sep .. entry.value .. collapse
  end
  -- Remove the trailing "&" if needed
  if #concatenatedString > 0 then
      concatenatedString = string.sub(concatenatedString, 1, #concatenatedString - 1)
  end
  return concatenatedString
end

-- 4. 把字符串转换为 table
local function parseUrlParams(url)
  local params = {}
  local queryString = url:match("%?(.*)")

  if queryString then
      for key, value in queryString:gmatch("([^=&]+)=([^&]*)") do
          table.insert(params, {
              name = key,
              value = value
          })
      end
  end

  return params
end

-- 5. 判断字符串是否为空
local function is_Empty(s)
  return s == nil or s == ''
end

----6. 对定义的 table 进行增删改查
-- 增加一对键值对
local function addKeyValueToObject(obj, name, value)
  table.insert(obj, {
      name = name,
      value = value
  })
end

-- 删除指定名称的键值对
local function removeKeyValueFromObject(obj, name)
  for i, entry in ipairs(obj) do
      if entry.name == name then
          table.remove(obj, i)
          break
      end
  end
end

-- 修改指定名称的键值对的值
local function updateKeyValueInObject(obj, name, newValue)
  for _, entry in ipairs(obj) do
      if entry.name == name then
          entry.value = newValue
          break
      end
  end
end

-- 根据名称查找键值对的值
local function findValueInObject(obj, name)
  for _, entry in ipairs(obj) do
      if entry.name == name then
          return entry.value
      end
  end
  return nil
end

-- 打印所有键值对
local function printKeyValuePairs(obj)
  for _, entry in ipairs(obj) do
      print(entry.name, entry.value)
  end
end

local function convertPercentageToNumber(percentage)
  local numericValue = tonumber(percentage)
  if numericValue then
    return numericValue
  elseif percentage:match("(%d+)%%$") then
    return tonumber(percentage:match("(%d+)")) / 100
  else
    return nil
  end
end

------------------------------ 下面的实现具体的功能 ------------------------------

local function generateEmbedCode(url, width, align)
  local aspectRatio = convertPercentageToNumber(width) * 9/16;
  local aspectRatioPercentage = string.format("%.2f%%", aspectRatio * 100)
  
  local alignmentStyles = {
    center = "margin: 0 auto;",
    left = "margin-right: auto;",
    right = "margin-left: auto;"
  }
  local alignmentStyle = alignmentStyles[align] or alignmentStyles["left"]
  
  return string.format([[
    <div style="position: relative; width: %s; height: 0; padding-bottom: %s; %s">
      <iframe style="position: absolute; width: 100%%; height: 100%%; left: 0; top: 0;" src="%s" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true"></iframe>
    </div>
   ]], width, aspectRatioPercentage, alignmentStyle, url)
end









-- 保证字符串以百分比符号结尾
local function ensurePercentage(value, defaultValue)
  if is_Empty(value) then
      return defaultValue or "100%"
  end
  local numericValue = tonumber(value)
  if numericValue and numericValue >= 0 and numericValue <= 100 then
      return string.format("%.2f%%", numericValue)
  end
  return value
end

return {
  ["blbl"] = function(args, kwargs)
      -- quarto.log.output(args)
      -- quarto.log.output(kwargs)
      local url = pandoc.utils.stringify(args[1])
      -- print(url)
      local urlParams = parseUrlParams(url)
      local aid = findValueInObject(urlParams, 'aid')
      local cid = findValueInObject(urlParams, 'cid')
      -- print(aid, cid)

      local width = pandoc.utils.stringify(kwargs["width"])
      local height = pandoc.utils.stringify(kwargs["height"])
      local align = pandoc.utils.stringify(kwargs["align"])
      -- print("sss", width)
      if not url then
        return pandoc.Null()
      end

      if not (aid and cid) then
          return pandoc.Null()
      end

      -- {name = "bvid", value = bvid},
      local optionalParams = {
          {name = "aid", value = aid},
          {name = "cid", value = cid},
          {name = "page", value = '1'},
          {name = 'as_wide', value = '1'},
          {name = 'high_quality', value = '1'},
          {name = 'danmaku', value = '0'}, -- 0 开启弹幕
          {name = 'autoplay', value = 'false'}
      }

      local newQuery = mergeOrderedTables(urlParams, optionalParams)
      local concatenatedString = concatenateParams(newQuery)

      url = url:gsub('%?.*', '') -- 移除原有的参数
      url = url .. '?' .. concatenatedString -- 重新构建 URL
      -- print(url)

      height = ensurePercentage(height, "100%")
      width = ensurePercentage(width, "100%")
      
      align = align or "left"
      embed_code = generateEmbedCode(url, width, align)
      --- print(embed_code)

      return pandoc.RawBlock("html", embed_code)
  end
}
