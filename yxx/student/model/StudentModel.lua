--[[
@Author cuijinlong
@date 2015-5-22
--]]
local _Group = {};
--[[
	局部函数：通过班级和组获得学生
	class_ids：123,433,545
	group_ids:3254_775,3233_775
]]
function _Group:getPersonTableArrs(class_ids,group_ids)
    local person_table_arrs = {};
    local studentModel = require "base.student.model.Student";
    --todo 按班级留预习 start
    if class_ids and string.len(class_ids)>0 then
        --todo 通过班级ID查询学生 end
        person_table_arrs = studentModel:getStudentByClassIds(class_ids);
    end
    --todo 按组留预习 start
    if group_ids and string.len(group_ids)>0 then

    end
    --todo 组留预习 end
    return person_table_arrs;
end
-- 返回_Game对象
return _Group;
