SmartChatMsg = SmartChatMsg or {}

local function leap(year) return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0) end
local function monthDays(year, month)
    local lengths = {31,28,31,30,31,30,31,31,30,31,30,31}
    return month == 2 and leap(year) and 29 or lengths[month]
end
local function civilSeconds(year, month, day, hour, minute)
    local days = 0
    for y = 1970, year - 1 do days = days + (leap(y) and 366 or 365) end
    for m = 1, month - 1 do days = days + monthDays(year, m) end
    return (days + day - 1) * 86400 + hour * 3600 + minute * 60
end
local function firstSunday(year, month)
    local weekday = (math.floor(civilSeconds(year, month, 1, 0, 0) / 86400) + 4) % 7
    return 1 + ((7 - weekday) % 7)
end

-- Modern US Eastern rules (2007 onward). All arithmetic and os.date calls
-- use UTC; the user's operating-system timezone and DST flag are irrelevant.
function SmartChatMsg:GetEasternUtcOffset(utc)
    local year = os.date("!*t", utc).year
    local starts = civilSeconds(year, 3, firstSunday(year, 3) + 7, 7, 0)
    local ends = civilSeconds(year, 11, firstSunday(year, 11), 6, 0)
    return utc >= starts and utc < ends and -4 or -5
end

function SmartChatMsg:GetEasternParts(utc)
    local offset = self:GetEasternUtcOffset(utc)
    local parts = os.date("!*t", utc + offset * 3600)
    parts.timezone = offset == -4 and "EDT" or "EST"
    return parts
end

function SmartChatMsg:ParseEasternDateTime(date, time, fold)
    local year, month, day = tostring(date or ""):match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    year, month, day = tonumber(year), tonumber(month), tonumber(day)
    if not year or year < 2007 or year > 2099 or month < 1 or month > 12
        or day < 1 or day > monthDays(year, month) then
        return nil, "Use a valid YYYY-MM-DD date between 2007 and 2099."
    end
    local hour, minute, meridiem = tostring(time or ""):upper():match("^(%d%d?):(%d%d)%s+([AP]M)$")
    hour, minute = tonumber(hour), tonumber(minute)
    if not hour or hour < 1 or hour > 12 or minute > 59 then
        return nil, "Use a time such as 08:00 PM, with AM or PM."
    end
    hour = hour % 12 + (meridiem == "PM" and 12 or 0)
    local wall = civilSeconds(year, month, day, hour, minute)
    local candidates = {}
    for _, offset in ipairs({-4, -5}) do
        local utc = wall - offset * 3600
        if self:GetEasternUtcOffset(utc) == offset then candidates[#candidates + 1] = utc end
    end
    if #candidates == 0 then return nil, "That Eastern time does not exist during the spring DST change."
    elseif #candidates == 1 then return candidates[1]
    elseif fold == "EDT" then return candidates[1]
    elseif fold == "EST" then return candidates[2] end
    return nil, "That Eastern time occurs twice. Choose the first (EDT) or second (EST) occurrence."
end

function SmartChatMsg:FormatEasternDateTime(utc)
    local p = self:GetEasternParts(utc)
    return string.format("%04d-%02d-%02d %02d:%02d %s %s", p.year, p.month, p.day,
        p.hour % 12 == 0 and 12 or p.hour % 12, p.min, p.hour >= 12 and "PM" or "AM", p.timezone)
end

function SmartChatMsg:GetSchedulePhase(schedule, utc)
    if schedule.mode=="WINDOW" or schedule.mode=="REMINDER" then return "ANY" end
    local occurrence=self.GetScheduleOccurrence and self:GetScheduleOccurrence(schedule,utc)
    schedule=occurrence or schedule
    if utc >= schedule.eventAtUtc then return "LIVE" end
    local event = self:GetEasternParts(schedule.eventAtUtc)
    local midnight = self:ParseEasternDateTime(string.format("%04d-%02d-%02d", event.year, event.month, event.day), "12:00 AM")
    return utc < midnight and "BEFORE" or "DAY"
end
