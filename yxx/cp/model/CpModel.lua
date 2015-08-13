--[[
@Author cuijinlong
@date 2015-7-11
--]]
local _Cp = {};

--[[
@Author cuijinlong
@date 2015-7-23
--]]
--[[
    获得测评主表的mysql插入脚本
    cp_id:测评ID
    cp_name:测评名称
    bus_id：业务ID（作业/预习/复习）
    parent_id：父亲ID 默认值-1
    paper_id：试卷ID
    person_id：人员ID
    identity_id：身份ID
    scheme_id：版本ID
    structure_id：目录结构ID
    subject_id：学科ID
    cp_type_id：测评类型（1：作业 2：测评）
--]]

function _Cp:CpMoudelInsertSql(cp_table)
    --第一步：组装测评主表的信息 start
    local questionModel = require "yxx.cp.question.model.QuestionModel";
    local cjson = require "cjson";
    --组装测评信息的信息 start
    local cp_insert_sql = self:getCpInsertSql(cp_table);
    --ngx.log(ngx.ERR,"########################"..cp_insert_sql);
    --组装测评信息的信息 end
    --第二步：组装试卷中试题的信息 start
    local cp_question_insert_sql_table = {}; --测评中的试题的insert语句数组
    local cp_question_table_arrs = {};--装着本次测评的所有试题信息
    --todo cp_question_table_arrs = 通过paper_id获得试卷中的所有试题信息
    local question_json = "ewogICAgInN1Y2Nlc3MiOiAidHJ1ZSIsCiAgICAicXVlc3Rpb25fbGlzdCI6IFsKICAgICAgICB7CiAgICAgICAgICAgICJxdWVzdGlvbl9pZCI6ICIxNTM0NTkiCiAgICAgICAgfSwKICAgICAgICB7CiAgICAgICAgICAgICJxdWVzdGlvbl9pZCI6ICIxNTM0MzYiCiAgICAgICAgfSwKICAgICAgICB7CiAgICAgICAgICAgICJxdWVzdGlvbl9pZCI6ICIxNTM0MjMiCiAgICAgICAgfSwKICAgICAgICB7CiAgICAgICAgICAgICJxdWVzdGlvbl9pZCI6ICIxNTM0MjEiCiAgICAgICAgfSwKICAgICAgICB7CiAgICAgICAgICAgICJxdWVzdGlvbl9pZCI6ICIxNTM0MTciCiAgICAgICAgfSwKICAgICAgICB7CiAgICAgICAgICAgICJxdWVzdGlvbl9pZCI6ICIxNTM0MDEiCiAgICAgICAgfSwKICAgICAgICB7CiAgICAgICAgICAgICJxdWVzdGlvbl9pZCI6ICIxNTMzODYiCiAgICAgICAgfSwKICAgICAgICB7CiAgICAgICAgICAgICJxdWVzdGlvbl9pZCI6ICIxNTMzNzYiCiAgICAgICAgfQogICAgXQp9";
    local cp_question_table = cjson.decode(ngx.decode_base64(question_json));--组装预习中测评的参与人的insert语句
    local question_list = cp_question_table.question_list;

    for i=1,#question_list do
        --组装试卷中试题的Vo数组 start
        local question_vo = questionModel:getQuestionVo(cp_table,question_list[i].question_id);
        table.insert(cp_question_table_arrs, question_vo);
        --组装试卷中试题的Vo数组 end
    end
    if #cp_question_table_arrs>0 then
        cp_question_insert_sql_table = questionModel:getQuestionInsertSqlTable(cp_question_table_arrs);
    end
    --组装试卷中试题的信息 end
    local cp_model_insert_sql_table = self:getCpAndQuestionSql(cp_insert_sql,cp_question_insert_sql_table);

    return  cp_model_insert_sql_table
end


--[[
	局部函数：组装测评模块测评主表的insert语句
]]
local function getCpInsertSql(self,cp_table)
    local tableUtil = require "yxx.tool.TableUtil";
    local k_v_table = tableUtil:convert_sql(cp_table);
    local insert_sql = "insert into t_cp_info("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..");"
    return insert_sql;
end
_Cp.getCpInsertSql = getCpInsertSql;

--[[
	局部函数：获得测评模块的insert语句（不发布发布）
]]
local function getCpAndQuestionSql(self,cp_insert_sql,cp_question_insert_sql_table)
    local cpSqlTable = {};
    cpSqlTable[1] = cp_insert_sql;
    if cp_question_insert_sql_table then
        for i=1,#cp_question_insert_sql_table do
            cpSqlTable[1+i] = cp_question_insert_sql_table[i];
        end
    end
    return cpSqlTable;
end
_Cp.getCpAndQuestionSql = getCpAndQuestionSql;

--[[
	局部函数：通过业务ID和业务类型获得测评ID
	bus_id：业务ID  作业：zy_id  预习:yx_id
	cp_type_id: 作业：1   预习：2
]]
function _Cp:getCpIdByBusIdAndCpTypeId(bus_id,cp_type_id)
    local sql = "select cp_id from t_cp_info where bus_id="..bus_id.." and cp_type_id="..cp_type_id;
    local DBUtil = require "common.DBUtil";
    local queryResult = DBUtil:querySingleSql(sql);
    if not queryResult then
        return {};
    end
    return queryResult;
end

return _Cp;