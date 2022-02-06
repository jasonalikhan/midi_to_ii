-- midi_to_ii
--
-- convert incoming midi to i2c
-- 16 channels of monophonic note data
-- for use with torso t1 or any midi device


local curr_note = {n=16}
local curr_vel = {n=16}
local last_note = {n=16}
local last_vel = {n=16}

local note_str = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
local midi_in_device

function init()
  -- assign midi handler
  midi_in_device = midi.connect(1)
  midi_in_device.event = midi_data_handler

  for ch = 1, 16 do
    curr_note[ch] = -1
    curr_vel[ch] = -1
    last_note[ch] = -1
    last_vel[ch] = -1
  end
end


function midi_data_handler(data)
  local msg = midi.to_msg(data)
  local ch = msg.ch

  if msg.type == "note_on" then
    note_on(ch, msg.note, msg.vel)
  -- note off
  elseif msg.type == "note_off" then
    note_off(ch, msg.note)
  -- key pressure
  elseif msg.type == "key_pressure" then
  -- channel pressure
  elseif msg.type == "channel_pressure" then
  -- pitch bend
  elseif msg.type == "pitchbend" then
    local bend_st = (util.round(msg.val / 2)) / 8192 * 2 -1 -- Convert to -1 to 1
  -- CC
  elseif msg.type == "cc" then
    -- mod wheel
    if msg.cc == 1 then
    end
  end
end

function key(n, z)

  redraw()
end

function note_on(ch, note, vel)
  -- send ii commands in triplets: note, vel, trig
  local offset = (ch-1)*3 + 1

  -- store the note data for screen drawing
  curr_note[ch] = note
  curr_vel[ch] = vel

  crow.ii.er301.cv(offset,note / 12)
  crow.ii.er301.cv(offset+1, vel/127 * 10.0)
  crow.ii.er301.tr(offset+2,1)
  redraw()
end

function note_off(ch, note)
  last_note[ch] = curr_note[ch]
  last_vel[ch] = curr_vel[ch]
  curr_note[ch] = -1
  curr_vel[ch] = -1

  crow.ii.er301.tr((ch-1)*3 + 3,0)
  redraw()
end

function redraw()
  local ch

  screen.clear()
  screen.level(15)

  for ch = 1, 16 do
    if ch < 9 then
      x = 1
      y = ch*8
    else
      x = 64
      y = (ch-8)*8
    end

    if curr_note[ch] >= 0 then
      screen.level(15)
      screen.move(x, y)
      screen.text(note_str[math.fmod(curr_note[ch], 12)+1]..math.floor(curr_note[ch]/12))
      screen.move(x+20, y)
      screen.text(curr_vel[ch])
    else
      screen.level(1)
      if last_note[ch] >= 0 then
        screen.move(x, y)
        screen.text(note_str[math.fmod(last_note[ch], 12)+1]..math.floor(last_note[ch]/12))
        screen.move(x+20, y)
        screen.text(last_vel[ch])
      else
        screen.move(x, y)
        screen.text(".")
        screen.move(x+20, y)
        screen.text(".")
      end
    end
  end

  screen.update()
end
