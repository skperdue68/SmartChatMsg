SmartChatMsg = {}
local file = io.open("SCM_Calendar.lua")
if file then file:close(); dofile("SCM_Calendar.lua") end
local scm = SmartChatMsg
local cases = {
    {"2026-01-16", "08:00 PM", nil, 1768611600},
    {"2026-10-16", "08:00 PM", nil, 1792195200},
    {"2026-03-08", "02:30 AM", nil, nil},
    {"2026-11-01", "01:30 AM", nil, nil},
    {"2026-11-01", "01:30 AM", "EDT", 1793511000},
    {"2026-11-01", "01:30 AM", "EST", 1793514600},
    {"2026-02-29", "08:00 PM", nil, nil},
    {"2028-02-29", "12:00 AM", nil, 1835413200},
    {"2026-10-16", "08:00", nil, nil},
    {"2026-10-16", "13:00 PM", nil, nil},
}
local failures = 0
for _, case in ipairs(cases) do
    local ok, why = pcall(function()
        assert(type(scm.ParseEasternDateTime) == "function", "Eastern conversion is missing")
        local value, reason = scm:ParseEasternDateTime(case[1], case[2], case[3])
        assert(value == case[4], case[1] .. " " .. case[2] .. ": expected " .. tostring(case[4]) .. ", got " .. tostring(value))
        if not value then assert(type(reason) == "string" and reason ~= "") end
    end)
    if ok then print("PASS Eastern " .. case[1] .. " " .. case[2] .. " " .. tostring(case[3])) else failures = failures + 1; print("FAIL " .. tostring(why)) end
end
assert(failures == 0, tostring(failures) .. " Eastern calendar failures")
local event = {eventAtUtc = 1792195200}
assert(scm:GetSchedulePhase(event, 1792123199) == "BEFORE")
assert(scm:GetSchedulePhase(event, 1792123200) == "DAY")
assert(scm:GetSchedulePhase(event, 1792195200) == "LIVE")
assert(scm:FormatEasternDateTime(1792195200) == "2026-10-16 08:00 PM EDT")
print("PASS Eastern midnight, event boundary, and display")
local originalDate,originalTime=os.date,os.time
os.date=function(format,utc) assert(format:sub(1,1)=="!","calendar consulted client local time"); return originalDate(format,utc) end
os.time=function() error("calendar consulted client local civil time") end
assert(scm:ParseEasternDateTime("2026-11-01","01:30 AM","EST")==1793514600)
assert(scm:GetSchedulePhase(event,1792123200)=="DAY")
assert(scm:FormatEasternDateTime(1768611600)=="2026-01-16 08:00 PM EST")
os.date,os.time=originalDate,originalTime
print("PASS calendar uses UTC independently of client local date/time APIs")
