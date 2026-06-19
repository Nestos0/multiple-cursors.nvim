local M = {}

local key_maps = require("multiple-cursors.key_maps")
local common = require("multiple-cursors.common")
local extmarks = require("multiple-cursors.extmarks")
local virtual_cursors = require("multiple-cursors.virtual_cursors")

local normal_mode_motion = require("multiple-cursors.normal_mode.motion")
local normal_mode_backspace = require("multiple-cursors.normal_mode.backspace")
local normal_mode_delete_yank_put = require("multiple-cursors.normal_mode.delete_yank_put")
local normal_mode_edit = require("multiple-cursors.normal_mode.edit")
local normal_mode_mode_change = require("multiple-cursors.normal_mode.mode_change")

local insert_mode_motion = require("multiple-cursors.insert_mode.motion")
local insert_mode_character = require("multiple-cursors.insert_mode.character")
local insert_mode_nonprinting = require("multiple-cursors.insert_mode.nonprinting")
local insert_mode_special = require("multiple-cursors.insert_mode.special")
local insert_mode_completion = require("multiple-cursors.insert_mode.completion")
local insert_mode_escape = require("multiple-cursors.insert_mode.escape")

local visual_mode_modify_area = require("multiple-cursors.visual_mode.modify_area")
local visual_mode_delete_yank_change_put = require("multiple-cursors.visual_mode.delete_yank_change_put")
local visual_mode_edit = require("multiple-cursors.visual_mode.edit")
local visual_mode_escape = require("multiple-cursors.visual_mode.escape")

local paste = require("multiple-cursors.paste")
local search = require("multiple-cursors.search")

local function_registry = {
  NormalMotionUp              = {fn = normal_mode_motion.k,                 mode = {"n", "x"}},
  NormalMotionDown            = {fn = normal_mode_motion.j,                 mode = {"n", "x"}},
  NormalMotionFirstNonBlankUp = {fn = normal_mode_motion.minus,            mode = {"n", "x"}},
  NormalMotionFirstNonBlankDn = {fn = normal_mode_motion.plus,             mode = {"n", "x"}},
  NormalMotionFirstNonBlankDl = {fn = normal_mode_motion.underscore,      mode = {"n", "x"}},
  NormalMotionLeft            = {fn = normal_mode_motion.h,                mode = {"n", "x"}},
  NormalBackspace             = {fn = normal_mode_backspace.bs,            mode = {"n", "x"}},
  NormalMotionRight           = {fn = normal_mode_motion.l,                mode = {"n", "x"}},
  NormalMotionLineStart       = {fn = normal_mode_motion.zero,             mode = {"n", "x"}},
  NormalMotionFirstChar       = {fn = normal_mode_motion.caret,            mode = {"n", "x"}},
  NormalMotionLineEnd         = {fn = normal_mode_motion.dollar,           mode = {"n", "x"}},
  NormalMotionColumn          = {fn = normal_mode_motion.bar,              mode = {"n", "x"}},
  NormalMotionFindFwd         = {fn = normal_mode_motion.f,                mode = {"n", "x"}},
  NormalMotionFindBwd         = {fn = normal_mode_motion.F,                mode = {"n", "x"}},
  NormalMotionTillFwd         = {fn = normal_mode_motion.t,                mode = {"n", "x"}},
  NormalMotionTillBwd         = {fn = normal_mode_motion.T,                mode = {"n", "x"}},
  NormalMotionWordNext        = {fn = normal_mode_motion.w,                mode = {"n", "x"}},
  NormalMotionWordNextBare    = {fn = normal_mode_motion.W,                mode = {"n", "x"}},
  NormalMotionWordEnd         = {fn = normal_mode_motion.e,                mode = {"n", "x"}},
  NormalMotionWordEndBare     = {fn = normal_mode_motion.E,                mode = {"n", "x"}},
  NormalMotionWordPrev        = {fn = normal_mode_motion.b,                mode = {"n", "x"}},
  NormalMotionWordPrevBare    = {fn = normal_mode_motion.B,                mode = {"n", "x"}},
  NormalMotionWordEndPrev     = {fn = normal_mode_motion.ge,               mode = {"n", "x"}},
  NormalMotionWordEndPrevBare = {fn = normal_mode_motion.gE,               mode = {"n", "x"}},
  NormalMotionPercent         = {fn = normal_mode_motion.percent,          mode = {"n", "x"}},

  NormalMotionTop             = {fn = normal_mode_motion.gg,               mode = "n"},
  NormalMotionBottom          = {fn = normal_mode_motion.G,                mode = "n"},
  NormalDeleteChar            = {fn = normal_mode_delete_yank_put.x,       mode = "n"},
  NormalDeleteCharBefore      = {fn = normal_mode_delete_yank_put.X,       mode = "n"},
  NormalDelete                = {fn = normal_mode_delete_yank_put.d,       mode = "n"},
  NormalDeleteLine            = {fn = normal_mode_delete_yank_put.dd,      mode = "n"},
  NormalDeleteToEOL           = {fn = normal_mode_delete_yank_put.D,       mode = "n"},
  NormalYank                  = {fn = normal_mode_delete_yank_put.y,       mode = "n"},
  NormalYankLine              = {fn = normal_mode_delete_yank_put.yy,      mode = "n"},
  NormalPutAfter              = {fn = normal_mode_delete_yank_put.p,       mode = "n"},
  NormalPutBefore             = {fn = normal_mode_delete_yank_put.P,       mode = "n"},
  NormalReplace               = {fn = normal_mode_edit.r,                  mode = "n"},
  NormalIndent                = {fn = normal_mode_edit.indent,             mode = "n"},
  NormalDeindent              = {fn = normal_mode_edit.deindent,           mode = "n"},
  NormalJoinLines             = {fn = normal_mode_edit.J,                  mode = "n"},
  NormalJoinLinesNoSpace      = {fn = normal_mode_edit.gJ,                mode = "n"},
  NormalLowercase             = {fn = normal_mode_edit.gu,                 mode = "n"},
  NormalUppercase             = {fn = normal_mode_edit.gU,                 mode = "n"},
  NormalSwapCase              = {fn = normal_mode_edit.g_tilde,            mode = "n"},
  NormalRepeat                = {fn = normal_mode_edit.dot,                mode = "n"},
  NormalInsertAfter           = {fn = normal_mode_mode_change.a,           mode = "n"},
  NormalInsertAfterEOL        = {fn = normal_mode_mode_change.A,           mode = "n"},
  NormalInsertBefore          = {fn = normal_mode_mode_change.i,           mode = "n"},
  NormalInsertBeforeFirst     = {fn = normal_mode_mode_change.I,           mode = "n"},
  NormalInsertBelow           = {fn = normal_mode_mode_change.o,           mode = "n"},
  NormalInsertAbove           = {fn = normal_mode_mode_change.O,           mode = "n"},
  NormalChange                = {fn = normal_mode_mode_change.c,           mode = "n"},
  NormalChangeLine            = {fn = normal_mode_mode_change.cc,          mode = "n"},
  NormalChangeToEOL           = {fn = normal_mode_mode_change.C,           mode = "n"},
  NormalSubstitute            = {fn = normal_mode_mode_change.s,           mode = "n"},
  NormalVisual                = {fn = normal_mode_mode_change.v,           mode = "n"},
  NormalUndo                  = {fn = function() M.normal_undo() end,      mode = "n"},
  NormalEscape                = {fn = function() M.normal_escape() end,    mode = "n"},

  VisualToggleObject          = {fn = visual_mode_modify_area.o,           mode = "x"},
  VisualToggleArea            = {fn = visual_mode_modify_area.a,           mode = "x"},
  VisualToggleInner           = {fn = visual_mode_modify_area.i,           mode = "x"},
  VisualDelete                = {fn = visual_mode_delete_yank_change_put.d, mode = "x"},
  VisualYank                  = {fn = visual_mode_delete_yank_change_put.y, mode = "x"},
  VisualChange                = {fn = visual_mode_delete_yank_change_put.c, mode = "x"},
  VisualPutAfter              = {fn = visual_mode_delete_yank_change_put.p, mode = "x"},
  VisualPutBefore             = {fn = visual_mode_delete_yank_change_put.P, mode = "x"},
  VisualIndent                = {fn = visual_mode_edit.indent,             mode = "x"},
  VisualDeindent              = {fn = visual_mode_edit.deindent,           mode = "x"},
  VisualJoinLines             = {fn = visual_mode_edit.J,                  mode = "x"},
  VisualJoinLinesNoSpace      = {fn = visual_mode_edit.gJ,                mode = "x"},
  VisualLowercase             = {fn = visual_mode_edit.u,                  mode = "x"},
  VisualUppercase             = {fn = visual_mode_edit.U,                  mode = "x"},
  VisualSwapCase              = {fn = visual_mode_edit.tilde,              mode = "x"},
  VisualLowercaseMove         = {fn = visual_mode_edit.gu,                 mode = "x"},
  VisualUppercaseMove         = {fn = visual_mode_edit.gU,                 mode = "x"},
  VisualSwapCaseMove          = {fn = visual_mode_edit.g_tilde,            mode = "x"},
  VisualEscape                = {fn = visual_mode_escape.escape,           mode = "x"},

  InsertCursorUp              = {fn = insert_mode_motion.up,               mode = "i"},
  InsertCursorDown            = {fn = insert_mode_motion.down,             mode = "i"},
  InsertCursorLeft            = {fn = insert_mode_motion.left,             mode = "i"},
  InsertCursorRight           = {fn = insert_mode_motion.right,            mode = "i"},
  InsertCursorHome            = {fn = insert_mode_motion.home,             mode = "i"},
  InsertCursorEnd             = {fn = insert_mode_motion.eol,              mode = "i"},
  InsertWordLeft              = {fn = insert_mode_motion.word_left,        mode = "i"},
  InsertWordRight             = {fn = insert_mode_motion.word_right,       mode = "i"},
  InsertBackspace             = {fn = insert_mode_nonprinting.bs,          mode = "i"},
  InsertDelete                = {fn = insert_mode_nonprinting.del,         mode = "i"},
  InsertNewline               = {fn = insert_mode_nonprinting.cr,          mode = "i"},
  InsertTab                   = {fn = insert_mode_nonprinting.tab,         mode = "i"},
  InsertDeleteWord            = {fn = insert_mode_special.c_w,             mode = "i"},
  InsertIndent                = {fn = insert_mode_special.c_t,             mode = "i"},
  InsertDeindent              = {fn = insert_mode_special.c_d,             mode = "i"},
  InsertEscape                = {fn = insert_mode_escape.escape,           mode = "i"},
}

local initialised = false
local autocmd_group_id = nil
local buf_enter_autocmd_id = nil

local pre_hook = nil
local post_hook = nil

local bufnr = nil

local remove_in_opposite_direction = nil
local direction = 0 -- 0: unknown, 1: down, 2: up

local default_key_maps = {
  {{"k", "<Up>"},              "NormalMotionUp"},
  {{"j", "<Down>"},            "NormalMotionDown"},
  {"-",                        "NormalMotionFirstNonBlankUp"},
  {{"+", "<CR>", "<Enter>"},   "NormalMotionFirstNonBlankDn"},
  {"_",                        "NormalMotionFirstNonBlankDl"},
  {{"h", "<Left>"},            "NormalMotionLeft"},
  {"<BS>",                     "NormalBackspace"},
  {{"l", "<Right>", "<Space>"},"NormalMotionRight"},
  {{"0", "<Home>"},            "NormalMotionLineStart"},
  {"^",                        "NormalMotionFirstChar"},
  {{"$", "<End>"},             "NormalMotionLineEnd"},
  {"|",                        "NormalMotionColumn"},
  {"f",                        "NormalMotionFindFwd"},
  {"F",                        "NormalMotionFindBwd"},
  {"t",                        "NormalMotionTillFwd"},
  {"T",                        "NormalMotionTillBwd"},
  {{"w", "<S-Right>", "<C-Right>"}, "NormalMotionWordNext"},
  {"W",                        "NormalMotionWordNextBare"},
  {"e",                        "NormalMotionWordEnd"},
  {"E",                        "NormalMotionWordEndBare"},
  {{"b", "<S-Left>", "<C-Left>"},   "NormalMotionWordPrev"},
  {"B",                        "NormalMotionWordPrevBare"},
  {"ge",                       "NormalMotionWordEndPrev"},
  {"gE",                       "NormalMotionWordEndPrevBare"},
  {"%",                        "NormalMotionPercent"},

  {"gg",                       "NormalMotionTop"},
  {"G",                        "NormalMotionBottom"},
  {{"x", "<Del>"},             "NormalDeleteChar"},
  {"X",                        "NormalDeleteCharBefore"},
  {"d",                        "NormalDelete"},
  {"dd",                       "NormalDeleteLine"},
  {"D",                        "NormalDeleteToEOL"},
  {"y",                        "NormalYank"},
  {"yy",                       "NormalYankLine"},
  {"p",                        "NormalPutAfter"},
  {"P",                        "NormalPutBefore"},
  {"r",                        "NormalReplace"},
  {">>",                       "NormalIndent"},
  {"<<",                       "NormalDeindent"},
  {"J",                        "NormalJoinLines"},
  {"gJ",                       "NormalJoinLinesNoSpace"},
  {"gu",                       "NormalLowercase"},
  {"gU",                       "NormalUppercase"},
  {"g~",                       "NormalSwapCase"},
  {".",                        "NormalRepeat"},
  {"a",                        "NormalInsertAfter"},
  {"A",                        "NormalInsertAfterEOL"},
  {{"i", "<Insert>"},          "NormalInsertBefore"},
  {"I",                        "NormalInsertBeforeFirst"},
  {"o",                        "NormalInsertBelow"},
  {"O",                        "NormalInsertAbove"},
  {"c",                        "NormalChange"},
  {"cc",                       "NormalChangeLine"},
  {"C",                        "NormalChangeToEOL"},
  {"s",                        "NormalSubstitute"},
  {"v",                        "NormalVisual"},
  {"u",                        "NormalUndo"},
  {"<Esc>",                    "NormalEscape"},

  {"o",                        "VisualToggleObject"},
  {"a",                        "VisualToggleArea"},
  {"i",                        "VisualToggleInner"},
  {{"d", "<Del>"},             "VisualDelete"},
  {"y",                        "VisualYank"},
  {"c",                        "VisualChange"},
  {"p",                        "VisualPutAfter"},
  {"P",                        "VisualPutBefore"},
  {">",                        "VisualIndent"},
  {"<",                        "VisualDeindent"},
  {"J",                        "VisualJoinLines"},
  {"gJ",                       "VisualJoinLinesNoSpace"},
  {"u",                        "VisualLowercase"},
  {"U",                        "VisualUppercase"},
  {"~",                        "VisualSwapCase"},
  {"gu",                       "VisualLowercaseMove"},
  {"gU",                       "VisualUppercaseMove"},
  {"g~",                       "VisualSwapCaseMove"},
  {{"<Esc>", "v"},             "VisualEscape"},

  {"<Up>",                     "InsertCursorUp"},
  {"<Down>",                   "InsertCursorDown"},
  {"<Left>",                   "InsertCursorLeft"},
  {"<Right>",                  "InsertCursorRight"},
  {"<Home>",                   "InsertCursorHome"},
  {"<End>",                    "InsertCursorEnd"},
  {"<C-Left>",                 "InsertWordLeft"},
  {"<C-Right>",                "InsertWordRight"},
  {{"<BS>", "<C-h>"},          "InsertBackspace"},
  {"<Del>",                    "InsertDelete"},
  {{"<CR>", "<Enter>"},        "InsertNewline"},
  {"<Tab>",                    "InsertTab"},
  {"<C-w>",                    "InsertDeleteWord"},
  {"<C-t>",                    "InsertIndent"},
  {"<C-d>",                    "InsertDeindent"},
  {"<Esc>",                    "InsertEscape"},
}

local function buf_delete()
  M.deinit(true)
end

local function buf_leave()
  -- Deinitialise without clearing virtual cursors
  M.deinit(false)
end

local function buf_enter()
  -- Returning to buffer with multiple cursors
  if vim.fn.bufnr() == bufnr then
    M.init()
    virtual_cursors.update_extmarks()
  end
end

-- Create autocmds used by this plug-in
local function create_autocmds()

  -- Monitor cursor movement to check for virtual cursors colliding with the real cursor
    vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"},
      { group = autocmd_group_id, callback = virtual_cursors.cursor_moved }
    )

    -- Insert characters
    vim.api.nvim_create_autocmd({"InsertCharPre"},
      { group = autocmd_group_id, callback = insert_mode_character.insert_char_pre }
    )

    vim.api.nvim_create_autocmd({"TextChangedI"},
      { group = autocmd_group_id, callback = insert_mode_character.text_changed_i }
    )

    vim.api.nvim_create_autocmd({"CompleteDonePre"},
      { group = autocmd_group_id, callback = insert_mode_completion.complete_done_pre }
    )

    -- Mode changed from normal to insert or visual
    vim.api.nvim_create_autocmd({"ModeChanged"}, {
      group = autocmd_group_id,
      pattern = "n:{i,v}",
      callback = normal_mode_mode_change.mode_changed,
    })

    -- Mode changed from insert to normal
    vim.api.nvim_create_autocmd({"ModeChanged"}, {
      group = autocmd_group_id,
      pattern = "i:n",
      callback = insert_mode_escape.mode_changed,
    })

    -- If there are custom key maps, reset the custom key maps on the LazyLoad
    -- event (when a plugin has been loaded)
    -- This is to fix an issue with using a command from a plugin that was lazy
    -- loaded while multi-cursors is active
    if key_maps.has_custom_keys_maps() then
      vim.api.nvim_create_autocmd({"User"}, {
        group = autocmd_group_id,
        pattern = "LazyLoad",
        callback = key_maps.set_custom,
      })
    end

    vim.api.nvim_create_autocmd({"BufLeave"},
      { group = autocmd_group_id, callback = buf_leave }
    )

    vim.api.nvim_create_autocmd({"BufDelete"},
      { group = autocmd_group_id, callback = buf_delete }
    )

end

-- Initialise
function M.init()
  if not initialised then

    if pre_hook then pre_hook() end

    key_maps.save_existing()
    key_maps.set()

    create_autocmds()

    paste.override_handler()

    -- Initialising in a new buffer
    if not bufnr or vim.fn.bufnr() ~= bufnr then
      extmarks.clear()
      virtual_cursors.clear()
      bufnr = vim.fn.bufnr()
      buf_enter_autocmd_id = vim.api.nvim_create_autocmd({"BufEnter"}, {callback=buf_enter})
    end

    initialised = true
  end
end

-- Merge all virtual cursor registers into the real cursor register
local function merge_registers()

  -- Get names of registers stored in virtual cursors
  local registers = virtual_cursors.get_registers()

  -- For each register
  for _, register in ipairs(registers) do
    -- Concatenate
    virtual_cursors.merge_register_info(register)
  end

end

-- Restore cursor to the position of the oldest virtual cursor
local function restore_cursor_position()

  local pos = virtual_cursors.get_exit_pos()

  if pos then
    vim.fn.cursor({pos[1], pos[2], 0, pos[3]})
  end

end

-- Deinitialise
function M.deinit(clear_virtual_cursors)
  if initialised then

    if clear_virtual_cursors then
      merge_registers()
      restore_cursor_position()
      virtual_cursors.clear()
      bufnr = nil
      direction = 0
      vim.api.nvim_del_autocmd(buf_enter_autocmd_id)
      buf_enter_autocmd_id = nil
    end

    extmarks.clear()

    key_maps.delete()
    key_maps.restore_existing()

    vim.api.nvim_clear_autocmds({group = autocmd_group_id}) -- Clear autocmds

    paste.revert_handler()

    if post_hook then post_hook() end

    initialised = false
  end
end

-- Normal mode undo will exit because cursor positions can't be restored
function M.normal_undo()
  M.deinit(true)
  common.feedkeys(nil, vim.v.count, "u", nil)
end

-- Escape key
function M.normal_escape()
  M.deinit(true)
  common.feedkeys(nil, 0, "<Esc>", nil)
end

-- Add a virtual cursor to the real cursor position, then move (normal mode)
local function add_virtual_cursor_and_move(count1, down)
  for i = 1, count1 do
    -- Get the real cursor position
    local pos = vim.fn.getcurpos()

    -- Add virtual cursor at the real cursor position
    virtual_cursors.add(pos[2], pos[3], pos[5], true)

    -- Move the real cursor
    if down then
      vim.cmd("normal! j")
    else
      vim.cmd("normal! k")
    end
  end
end

-- Add a virtual cursor to the real cursor position, then move (visual mode)
local function add_virtual_cursor_and_move_v(count1, down)
  for i = 1, count1 do
    -- Get the current visual area
    local v_lnum, v_col, lnum, col, curswant = common.get_visual_area()

    -- Add a virtual cursor with the visual area
    virtual_cursors.add_with_visual_area(lnum, col, curswant, v_lnum, v_col, true)

    -- Move the real cursor visual area
    if down then
      common.set_visual_area(v_lnum + 1, v_col, lnum + 1, col)
    else
      common.set_visual_area(v_lnum - 1, v_col, lnum - 1, col)
    end
  end
end

-- Add a virtual cursor to the real cursor position, then move (insert/replace
-- mode)
local function add_virtual_cursor_and_move_i(down)
  -- Get the real cursor position
  local pos = vim.fn.getcurpos()

  -- Add virtual cursor at the real cursor position
  virtual_cursors.add(pos[2], pos[3], pos[5], true)

  -- Move the real cursor
  if down then
    common.feedkeys(nil, 0, "<Down>", nil)
  else
    common.feedkeys(nil, 0, "<Up>", nil)
  end
end

-- Move the real cursor, then remove any virtual cursor on the same line
-- (normal mode)
local function move_and_remove_virtual_cursor(count1, down)
  for i = 1, count1 do
    if down then
      vim.cmd("normal! j")
    else
      vim.cmd("normal! k")
    end

    local lnum = vim.fn.line(".")
    virtual_cursors.remove_by_lnum(lnum)
  end
end

-- Move the real cursor, then remove any virtual cursor on the same line (visual
-- mode)
local function move_and_remove_virtual_cursor_v(count1, down)
  for i = 1, count1 do
    local v_lnum, v_col, lnum, col, curswant = common.get_visual_area()

    if down then
      v_lnum = v_lnum + 1
      lnum = lnum + 1
    else
      v_lnum = v_lnum - 1
      lnum = lnum - 1
    end

    common.set_visual_area(v_lnum, v_col, lnum, col)
    virtual_cursors.remove_by_lnum(v_lnum)
  end
end

-- Move the real cursor, then remove any virtual cursor on the same line
-- (insert/replace mode)
local function move_and_remove_virtual_cursor_i(down)

  local lnum = vim.fn.line(".")

  if down then
    lnum = lnum + 1
    if lnum > vim.fn.line("$") then
      -- Past end of buffer
      return
    end
  else
    lnum = lnum - 1
    if lnum < 1 then
      -- Before start of buffer
      return
    end
  end

  virtual_cursors.remove_by_lnum(lnum)

  -- Move the real cursor (this will be occur later in the event loop)
  if down then
    common.feedkeys(nil, 0, "<Down>", nil)
  else
    common.feedkeys(nil, 0, "<Up>", nil)
  end

end

-- Add a virtual cursor at the real cursor position, then move the real cursor
-- up
-- If remove_in_opposite_direction is true and cursors have previously been
-- added in the downward direction, move up and remove any virtual cursor on the
-- same line
function M.add_cursor_up()

  -- If a cursor has already been added in the opposite direction
  if remove_in_opposite_direction and direction == 1 then

    -- Move up and remove any virtual cursor on the same line
    if common.is_mode("n") then -- Normal mode
      move_and_remove_virtual_cursor(vim.v.count1, false)
    elseif common.is_mode("v") then -- Visual mode
      move_and_remove_virtual_cursor_v(vim.v.count1, false)
    else -- Insert/replace mode
      move_and_remove_virtual_cursor_i(false)
    end

    -- Deinitialise if there are no more cursors
    if virtual_cursors.get_num_virtual_cursors() == 0 then
      M.deinit(true)
    end
  else
    -- Set direction to up
    if remove_in_opposite_direction and direction == 0 then
      direction = 2
    end

    -- Initialise if this is the first cursor
    M.init()

    -- Add a cursor and move up
    if common.is_mode("n") then -- Normal mode
      add_virtual_cursor_and_move(vim.v.count1, false)
    elseif common.is_mode("v") then -- Visual mode
      add_virtual_cursor_and_move_v(vim.v.count1, false)
    else -- Insert or replace mode
      add_virtual_cursor_and_move_i(false)
    end

  end

end

-- Add a virtual cursor at the real cursor position, then move the real cursor
-- down
-- If remove_in_opposite_direction is true and cursors have previously been
-- added in the upward direction, move down and remove any virtual cursor on the
-- same line
function M.add_cursor_down()

  -- If a cursor has already been added in the opposite direction
  if remove_in_opposite_direction and direction == 2 then

    -- Move up and remove any virtual cursor on the same line
    if common.is_mode("n") then -- Normal mode
      move_and_remove_virtual_cursor(vim.v.count1, true)
    elseif common.is_mode("v") then -- Visual mode
      move_and_remove_virtual_cursor_v(vim.v.count1, true)
    else -- Insert/replace mode
      move_and_remove_virtual_cursor_i(true)
    end

    -- Deinitialise if there are no more cursors
    if virtual_cursors.get_num_virtual_cursors() == 0 then
      M.deinit(true)
    end
  else
    -- Set direction to down
    if remove_in_opposite_direction and direction == 0 then
      direction = 1
    end

    -- Initialise if this is the first cursor
    M.init()

    -- Add a cursor and move down
    if common.is_mode("n") then -- Normal mode
      add_virtual_cursor_and_move(vim.v.count1, true)
    elseif common.is_mode("v") then -- Visual mode
      add_virtual_cursor_and_move_v(vim.v.count1, true)
    else -- Insert or replace mode
      add_virtual_cursor_and_move_i(true)
    end

  end

end

-- Add or delete a virtual cursor at the mouse position
function M.mouse_add_delete_cursor()
  M.init() -- Initialise if this is the first cursor

  local mouse_pos = vim.fn.getmousepos()

  -- Add a virtual cursor to the mouse click position, or delete an existing one
  virtual_cursors.add_or_delete(mouse_pos.line, mouse_pos.column)

  if virtual_cursors.get_num_virtual_cursors() == 0 then
    M.deinit(true) -- Deinitialise if there are no more cursors
  end
end

local function get_visual_area_text()

  local lnum1, col1, lnum2, col2 = common.get_normalised_visual_area()

  if lnum1 ~= lnum2 then
    vim.print("Search pattern must be a single line")
    return nil
  end

  local line = vim.fn.getline(lnum1)
  return line:sub(col1, col2)

end

-- Get a search pattern
-- Returns cword in normal mode and the visual area text in visual mode
local function get_search_pattern()

  local pattern = nil

  if common.is_mode("v") then
    pattern = get_visual_area_text()
  else -- Normal mode
    -- Get word under cursor
    pattern = vim.fn.expand("<cword>")
    -- Match whole word
    pattern = "\\<" .. vim.pesc(pattern) .. "\\>"
  end

  if pattern == "" then
    return nil
  else
    return pattern
  end

end

-- Get the normalise visual area if in visual mode
-- returns is_v, lnum1, col1, lnum2, col2
local function maybe_get_normalised_visual_area()

  if not common.is_mode("v") then
    return false
  end

  local lnum1, col1, lnum2, col2 = common.get_normalised_visual_area()

  return true, lnum1, col1, lnum2, col2

end

-- Add cursors by searching for the word under the cursor or visual area
local function _add_cursors_to_matches(use_prev_visual_area)

  -- Get the visual area if in visual mode
  local is_v, lnum1, col1, lnum2, col2 = maybe_get_normalised_visual_area()

  -- Get the search pattern: either the cursor under the word in normal mode or the visual area in
  -- visual mode
  local pattern = get_search_pattern()

  if pattern == nil then
    return
  end

  -- Find matches (without the one for the cursor) and move the cursor to its match
  local matches = search.get_matches_and_move_cursor(pattern, match_visible_only, use_prev_visual_area)

  if matches == nil then
    return
  end

  -- Initialise if not already initialised
  M.init()

  -- Create a virtual cursor at every match
  for _, match in ipairs(matches) do
    local match_lnum1 = match[1]
    local match_col1 = match[2]

    -- If normal mode
    if not is_v then
      virtual_cursors.add(match_lnum1, match_col1, match_col1, false)

    else  -- Visual mode
      local match_col2 = match_col1 + string.len(pattern) - 1
      virtual_cursors.add_with_visual_area(match_lnum1, match_col2, match_col2, match_lnum1, match_col1, false)

    end
  end

  vim.print(#matches .. " cursors added")

  -- Restore visual area
  if is_v then
    common.set_visual_area(lnum1, col1, lnum2, col2)
  end

end

-- Add cursors to each match of cword or visual area
function M.add_cursors_to_matches() _add_cursors_to_matches(false) end

-- Add cursors to each match of cword or visual area, but only within the previous visual area
function M.add_cursors_to_matches_v() _add_cursors_to_matches(true) end

-- Add cursors to the visual area
function M.add_cursors_to_visual_area()

  local lnum1, _, lnum2, col, _ = common.get_visual_area()

  -- In visual line mode add cursors to the start of each line
  if common.is_mode("V") then
    col = 1
  end

  -- Exit visual mode
  common.feedkeys(nil, 0, "<Esc>", nil)

  -- Don't add cursors if the area is on a single line
  if lnum1 == lnum2 then
    return
  end

  -- Initialise if not already
  M.init()

  -- Direction
  local step = 1
  if lnum1 < lnum2 then
    -- Downwards
    if remove_in_opposite_direction and direction == 0 then
      direction = 1
    end
  else
    -- Upwards
    step  = -1
    if remove_in_opposite_direction and direction == 0 then
      direction = 2
    end
  end

  -- End before the line with the real cursor
  local end_lnum = lnum1 < lnum2 and lnum2 - 1 or lnum2 + 1

  -- Add virtual cursors
  for lnum = lnum1, end_lnum, step do
    virtual_cursors.add(lnum, col, -1, true)
  end

  -- Move the real cursor
  vim.fn.cursor({lnum, col, 0, -1})

end

-- Add a virtual cursor to the start of the word under the cursor (or visual area), then move the
-- cursor to to the next match
local function add_cursor_and_jump_to_match(backward)

  -- Get the visual area if in visual mode
  local is_v, lnum1, col1, lnum2, col2 = maybe_get_normalised_visual_area()

  -- Get the search pattern
  local pattern = get_search_pattern()

  -- Get a match without moving the cursor if there are already virtual cursors
  local match = search.get_next_match(pattern, backward, not initialised)

  if match == nil then
    return
  end

  -- Initialise if not already initialised
  M.init()

  local match_lnum1 = match[1]
  local match_col1 = match[2]

  -- Normal mode
  if not is_v then
    -- Add virtual cursor to cursor position
    local pos = vim.fn.getcurpos()
    virtual_cursors.add(pos[2], pos[3], pos[5], true)

    -- Move cursor to match
    vim.fn.cursor({match_lnum1, match_col1, 0, match_col1})

    -- Remove any existing virtual cursor
    virtual_cursors.remove_by_pos(match_lnum1, match_col1)

  else  -- Visual mode
    -- Add virtual cursor to cursor position
    virtual_cursors.add_with_visual_area(lnum2, col2, col2, lnum1, col1, true)

    -- Move cursor to match
    local match_col2 = match_col1 + string.len(pattern) - 1
    common.set_visual_area(match_lnum1, match_col1, match_lnum1, match_col2)

    virtual_cursors.remove_by_visual_area(match_lnum1, match_col1, match_lnum1, match_col2)

  end

end

function M.add_cursor_and_jump_to_next_match()
  add_cursor_and_jump_to_match(false)
end

function M.add_cursor_and_jump_to_previous_match()
  add_cursor_and_jump_to_match(true)
end

-- Move the cursor to the next match of the word under the cursor (or saved visual area, if any)
local function jump_to_match(backward)

  -- Get the search pattern
  local pattern = get_search_pattern()

  -- Get a match without moving the cursor
  local match = search.get_next_match(pattern, backward, false)

  if match == nil then
    return
  end

  local match_lnum1 = match[1]
  local match_col1 = match[2]

  if not common.is_mode("v") then
    -- Move cursor to match
    vim.fn.cursor({match_lnum1, match_col1, 0, match_col1})

    -- Remove any existing virtual cursor
    virtual_cursors.remove_by_pos(match_lnum1, match_col1)
  else
    -- Move visual area to match
    local match_col2 = match_col1 + string.len(pattern) - 1
    common.set_visual_area(match_lnum1, match_col1, match_lnum1, match_col2)

    -- Remove any existing virtual cursor
    virtual_cursors.remove_by_visual_area(match_lnum1, match_col1, match_lnum1, match_col2)
  end

end

function M.jump_to_next_match()
  jump_to_match(false)
end

function M.jump_to_previous_match()
  jump_to_match(true)
end

-- Add a new cursor at given position
function M.add_cursor(lnum, col, curswant)

  -- Initialise if this is the first cursor
  M.init()

  -- Add a virtual cursor
  virtual_cursors.add(lnum, col, curswant, false)

end

-- Insert spaces before each cursor to align them all to the rightmost cursor
function M.align()

  -- This function should only be used when there are multiple cursors
  if not initialised then
    return
  end

  -- Find the column of the rightmost cursor
  local col = vim.fn.col(".")

  virtual_cursors.visit_all(function(vc)
    col = vim.fn.max({col, vc.col})
  end)

  -- For each virtual cursor, insert spaces to move the cursor to col
  virtual_cursors.edit_with_cursor(function(vc)
    local num = col - vc.col
    for i = 1, num do
      vim.api.nvim_put({" "}, "c", false, true)
    end
  end)

  -- Insert spaces for the real cursor
  local num = col - vim.fn.col(".")
  for i = 1, num do
    vim.api.nvim_put({" "}, "c", false, true)
  end

end

-- Toggle locking the virtual cursors if initialised
function M.lock()
  if initialised then
    virtual_cursors.toggle_lock()
  end
end

function M.setup(opts)

  -- Options
  opts = opts or {}

  local custom_key_maps = opts.custom_key_maps or {}

  remove_in_opposite_direction = opts.remove_in_opposite_direction or true

  local enable_split_paste = opts.enable_split_paste or true

  match_visible_only = opts.match_visible_only or true

  pre_hook = opts.pre_hook or nil
  post_hook = opts.post_hook or nil

  -- Set up extmarks
  extmarks.setup()

  -- Set up key maps
  key_maps.setup(default_key_maps, custom_key_maps, function_registry)

  -- Set up paste
  paste.setup(enable_split_paste)

  -- Autocmds
  autocmd_group_id = vim.api.nvim_create_augroup("MultipleCursors", {})

  vim.api.nvim_create_user_command("MultipleCursorsAddDown", M.add_cursor_down, {})
  vim.api.nvim_create_user_command("MultipleCursorsAddUp", M.add_cursor_up, {})

  vim.api.nvim_create_user_command("MultipleCursorsMouseAddDelete", M.mouse_add_delete_cursor, {})

  vim.api.nvim_create_user_command("MultipleCursorsAddMatches", M.add_cursors_to_matches, {})
  vim.api.nvim_create_user_command("MultipleCursorsAddMatchesV", M.add_cursors_to_matches_v, {})
  vim.api.nvim_create_user_command("MultipleCursorsAddVisualArea", M.add_cursors_to_visual_area, {})

  vim.api.nvim_create_user_command("MultipleCursorsAddJumpNextMatch", M.add_cursor_and_jump_to_next_match, {})
  vim.api.nvim_create_user_command("MultipleCursorsAddJumpPrevMatch", M.add_cursor_and_jump_to_previous_match, {})
  vim.api.nvim_create_user_command("MultipleCursorsJumpNextMatch", M.jump_to_next_match, {})
  vim.api.nvim_create_user_command("MultipleCursorsJumpPrevMatch", M.jump_to_previous_match, {})

  vim.api.nvim_create_user_command("MultipleCursorsLock", M.lock, {})
end

return M
