local addonName, addonTable = ...

local Coordinator = {}
Coordinator.__index = Coordinator

function addonTable.createRefreshCoordinator()
    return setmetatable({
        pending = false,
        reason = nil,
        deadline = 0,
        scheduleCount = 0,
        coalescedCount = 0,
        dispatchCount = 0,
    }, Coordinator)
end

function Coordinator:schedule(now, delay, reason)
    now = tonumber(now) or 0
    delay = math.max(0, tonumber(delay) or 0)
    reason = tostring(reason or "SCHEDULED")

    self.scheduleCount = self.scheduleCount + 1
    if not self.pending then
        self.pending = true
        self.reason = reason
    else
        self.coalescedCount = self.coalescedCount + 1
        if self.reason ~= reason then
            self.reason = "MULTIPLE_EVENTS"
        end
    end

    self.deadline = now + delay
    return self.reason, self.deadline
end

function Coordinator:isPending()
    return self.pending and true or false
end

function Coordinator:getReason()
    return self.pending and self.reason or nil
end

function Coordinator:getDeadline()
    return self.pending and self.deadline or 0
end

function Coordinator:deferUntil(deadline)
    if not self.pending then
        return false
    end

    deadline = tonumber(deadline) or 0
    if deadline > self.deadline then
        self.deadline = deadline
    end
    return true
end

function Coordinator:takeIfDue(now)
    if not self.pending then
        return nil
    end

    now = tonumber(now) or 0
    if now < self.deadline then
        return nil
    end

    local reason = self.reason or "SCHEDULED"
    self.pending = false
    self.reason = nil
    self.deadline = 0
    self.dispatchCount = self.dispatchCount + 1
    return reason
end

function Coordinator:cancel()
    local wasPending = self.pending
    self.pending = false
    self.reason = nil
    self.deadline = 0
    return wasPending
end

function Coordinator:getStats()
    return {
        pending = self.pending and true or false,
        reason = self.reason,
        deadline = self.deadline,
        scheduleCount = self.scheduleCount,
        coalescedCount = self.coalescedCount,
        dispatchCount = self.dispatchCount,
    }
end
