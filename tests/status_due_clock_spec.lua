local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset()
eq(s:FormatStatusDuration(105*3600+20*60+32),'4d 09:20:32')
eq(s:FormatStatusDuration(25*3600+2),'1d 01:00:02')
local original=os.date
os.date=function(pattern,time) if pattern=='%I:%M:%S %p' then eq(time,now+9014);return '03:38:14 PM' end;return original(pattern,time) end
local row={isActive=true,lastSentText='Never',nextSendText='2:30:14',nextSendAt=now+9014}
eq(s:GetRepeatCardTimingText(row),'Last Sent: Never | Next Send: 2:30:14 at 03:38:14 PM')
row.isActive=false;eq(s:GetRepeatCardTimingText(row),'Last Sent: Never')
os.date=original
assert(s:GetStatusPanelRepeatCardHeight()<164,'remove reserved blank space')
print('status duration days, local due clock and compact card verified')
