local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq;f.reset()
local real=os.date
for _,hostDst in ipairs({false,true}) do
 os.date=function(format,epoch)local p=real(format,epoch);if format=='*t' and type(p)=='table' then p.isdst=hostDst end;return p end
 local summer=s:ParseEasternDateTime('2026-10-15','12:00 PM')
 local winter=s:ParseEasternDateTime('2026-01-15','12:00 PM')
 for _,zone in ipairs({{'ET','EDT','EST'},{'CT','CDT','CST'},{'MT','MDT','MST'},{'PT','PDT','PST'}}) do
  eq(s:scm_canonicalize_timezone_token(zone[1],summer),zone[2],'source timezone follows its calendar rather than client DST')
  eq(s:scm_canonicalize_timezone_token(zone[1],winter),zone[3])
 end
end
os.date=real
print('literal timezone-family previews are independent of client DST')
