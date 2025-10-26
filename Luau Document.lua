--# การ Insert ค่าเข้าไปใน Table ใช้ Table seen เก็บค่าที่เจอแล้ว เพื่อป้องกันการซ้ำ และแสดงค่าทั้งหมดที่ไม่ซ้ำกัน
local entitiesName = {}
local seen = {}

for _, Entity in pairs(workspace.Debris.Monsters:GetChildren()) do
    local title = Entity:GetAttribute("Title")
    if title and not seen[title] then
        table.insert(entitiesName, title)
        seen[title] = true
    end
end

for i, v in pairs(entitiesName) do
    print(i, v)
end

table.sort(entitiesName) -- เรียงตามตัวอักษร

print(entitiesName)

for i, v in ipairs(entitiesName) do
    print(i, v)
end

--# การใช้ os.date() เพื่อดึงค่าของนาทีและปีปัจจุบัน
local m = tonumber(os.date("%M"))
local y = tonumber(os.date("%Y"))
local halfhour
if m == 18 then
    halfhour = 30 - m --# เซตค่า halfhour เป็น 30 ลบด้วยนาทีปัจจุบัน
    print(halfhour)
end
