
require "core/enum"

local state = enum{ "Clamped", "Unclamped"}

print(state["Clamped"])
print(state["Unclamped"])

local newEnum = enum{ "asdf", "qwer" }

print(newEnum["asdf"])
print(newEnum["qwer"])