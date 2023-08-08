local function is_Empty(s)
  return s == nil or s == ''
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


local function generateEmbedCode2(url, width, height)
  -- 将百分比字符串转换为数字
  local parsedWidth = convertPercentageToNumber(width) or 1
  local parsedHeight = convertPercentageToNumber(height) or 1

  local defaultWidth = 800
  local defaultHeight = 600
  local minWidth = 300  -- 设置最小宽度
  local minHeight = 225 -- 设置最小高度

  local calculatedWidth = defaultWidth * parsedWidth
  local calculatedHeight = defaultHeight * parsedHeight

  local style = [[
    <style>
      .resizable-iframe {
        position: relative;
        width: ]] .. defaultWidth .. [[px;
        height: ]] .. defaultHeight .. [[px;
        resize: both;
        overflow: hidden;
        min-width: ]] .. minWidth .. [[px;  /* 设置最小宽度 */
        min-height: ]] .. minHeight .. [[px;  /* 设置最小高度 */
      }
      .resizable-iframe iframe {
        width: 100%%;
        height: 100%%;
        border: none;
      }
    </style>
  ]]

  local script = [[
    <script>
      function resizeIframe(iframe) {
        var bodyRect = document.body.getBoundingClientRect();
        var newWidth = (bodyRect.width - 16);  // 考虑滚动条宽度
        var newHeight = newWidth * 0.75;  // 保持 4:3 的宽高比

        iframe.style.width = newWidth + 'px';
        iframe.style.height = newHeight + 'px';

        // 调整页面的 body 大小以匹配 iframe 大小
        document.body.style.width = newWidth + 'px';
        document.body.style.height = newHeight + 'px';
      }
      window.addEventListener('resize', function() {
        var iframes = document.querySelectorAll('.resizable-iframe iframe');
        for (var i = 0; i < iframes.length; i++) {
          resizeIframe(iframes[i]);
        }
      });
      // 初始调整 iframe 大小
      var iframes = document.querySelectorAll('.resizable-iframe iframe');
      for (var i = 0; i < iframes.length; i++) {
        resizeIframe(iframes[i]);
      }
    </script>
  ]]


  return string.format([[
    %s
    %s
    <div class="resizable-iframe">
      <iframe src="%s" width="%d" height="%d" style="border: 1px solid #e4e4e4;border-radius: 4px;" frameborder="0" allowfullscreen="true"></iframe>
    </div>
   ]], style, script, url, calculatedWidth, calculatedHeight)
end

-- 原始的ggb
-- local function generateEmbedCode4(url)
--  return string.format([[
--    <iframe src="%s" width="800" height="600" allowfullscreen style="border: 1px solid #e4e4e4;border-radius: 4px;" frameborder="0"></iframe>
--   ]],url)
--end


local function generateEmbedCode(url, width, align)
  local aspectRatio = convertPercentageToNumber(width) * 3/4;
  local aspectRatioPercentage = string.format("%.2f%%", aspectRatio * 100)
  
  local alignmentStyles = {
    center = "margin: 0 auto;",
    left = "margin-right: auto;",
    right = "margin-left: auto;"
  }
  local alignmentStyle = alignmentStyles[align] or alignmentStyles["left"]
  
  return string.format([[
    <div style="position: relative; width: %s; height: 0; padding-bottom: %s; %s">
      <iframe style="position: absolute; width: 100%%; height: 100%%; left: 0; top: 0; border: 1px solid #e4e4e4;border-radius: 4px;" src="%s" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true"></iframe>
    </div>
   ]], width, aspectRatioPercentage, alignmentStyle, url)
end


return {
  ["ggb"] = function(args, kwargs)
    -- quarto.log.output(args)
    local url = pandoc.utils.stringify(args[1])
    
    local width = pandoc.utils.stringify(kwargs["width"])
    -- local height = pandoc.utils.stringify(kwargs["height"]) 
    local align = pandoc.utils.stringify(kwargs["align"])
    if not url then
      return pandoc.Null()
    end

    -- height = ensurePercentage(height, "100%")
    width = ensurePercentage(width, "100%")
    align = align or "left"
    embed_code = generateEmbedCode(url, width, align)
    print(embed_code)

    return pandoc.RawBlock("html", embed_code)
  end
}
