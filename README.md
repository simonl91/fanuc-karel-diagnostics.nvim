# README
This extension provides [diagnostic information](#example) for Fanuc Karel language in neovim. \
On every save your .kl files are compiled with ktrans, compile errors are then sent to editor.


## Requirements
* Fanuc Roboguide must be installed

## Installation
* [Add ktrans to path](#add-to-path)

### Lazy package manager
```lua
{
  'simonl91/fanuc-karel-diagnostics.nvim',
  opts = {
    ktrans_args = {}  -- Optional: Additional arguments for ktrans ex: {'/config', 'robot1/robot.ini'}
    virtual_text = false, -- Optional: Disable virtual text (inlay errors)
  }
}
```


### Example
![Multi Diagnostics](./resources/diagnostic-related-info.png)
*The extension provides diagnostics when saving karel files* 


### Add to path

![Add To Path](./resources/add-to-path.png)
*Add to path step by step*


