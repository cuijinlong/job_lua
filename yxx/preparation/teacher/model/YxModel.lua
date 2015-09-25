--[[
@Author cuijinlong
@date 2015-5-22
--]]
local _YX = {};
--[[
	局部函数：教师列表
]]
function _YX:yxList(yx_name, person_id, person_identity, subject_id, is_root, scheme_id, structure_id, sort_type, sort_mode, cnode, page_size, page_number)
    local DbUtil = require "yxx.tool.DbUtil";
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local offset = page_size * page_number - page_size;
    local limit = page_size;
    local str_maxmatches = page_number * 100;
    --升序还是降序
    local asc_desc = "";
    if sort_mode == "1" then
        asc_desc = "asc";
    else
        asc_desc = "desc";
    end
    --排序
    local sort_filed = "";
    if sort_type == "1" then
        sort_filed = "sort=attr_" .. asc_desc .. ":update_ts;";
    end
    local query_condition = "";
    if yx_name ~= "" then
        query_condition = query_condition .. yx_name .. ";"; --关键字搜索
    end
    if person_id ~= "" then
        query_condition = query_condition .. "filter=create_person_id," .. person_id .. ";"; --预习创建人ID
    end
    if person_identity ~= "" then
        query_condition = query_condition .. "filter=create_identity_id," .. person_identity .. ";"; --预习创建人身份
    end
    if subject_id ~= "" then
        query_condition = query_condition .. "filter=subject_id," .. subject_id .. ";";
    end

    local structure_scheme = ""
    if is_root == "1" then
        if cnode == "1" then
            structure_scheme = "filter=scheme_id," .. scheme_id .. ";"
        else
            structure_scheme = "filter=structure_id," .. structure_id .. ";"
        end
    else
        if cnode == "0" then
            structure_scheme = "filter=structure_id," .. structure_id .. ";"
        else
            local cache = DbUtil:getRedis();
            local sid = cache:get("node_" .. structure_id)
            local sids = Split(sid, ",")
            for i = 1, #sids do
                structure_scheme = structure_scheme .. sids[i] .. ","
            end
            structure_scheme = "filter=structure_id," .. string.sub(structure_scheme, 0, #structure_scheme - 1) .. ";"
            cache:set_keepalive(0, v_pool_size)
        end
    end
    local db = MysqlUtil:getDb();
    local query_sql = "SELECT SQL_NO_CACHE id FROM t_yx_person_sphinxse where QUERY=\'" .. query_condition .. structure_scheme .. sort_filed .. "filter=is_delete,0;filter=class_id,0;filter=group_id,0;maxmatches=" .. str_maxmatches .. ";offset=" .. offset .. ";limit=" .. limit .. "\';SHOW ENGINE SPHINX  STATUS;";

    local rows = MysqlUtil:query(query_sql);
    local read_result = db:read_result();
    local _, s_str = string.find(read_result[1]["Status"], "found: ");
    local e_str = string.find(read_result[1]["Status"], ", time:");
    local total_row = string.sub(read_result[1]["Status"], s_str + 1, e_str - 1);
    local total_page = math.floor((total_row + page_size - 1) / page_size);
    local return_table = {};
    for i = 1, #rows do
        local yxtoperson_tab = SSDBUtil:multi_hget_hash("yxx_yxtoperson_" .. rows[i].id, "yx_id"); --rows[i].id：预习人员表的ID
        local yx_table = SSDBUtil:multi_hget_hash("yx_moudel_info_" .. yxtoperson_tab.yx_id, "yx_id", "yx_name", "create_time", "person_id", "identity_id", "scheme_id", "structure_id", "subject_id", "is_public", "class_ids", "group_ids");
        -- todo 预习提交情况 start
        local ssdb = SSDBUtil:getDb();
        db:query("SELECT SQL_NO_CACHE id FROM t_yx_person_sphinxse WHERE query=\'filter=yx_id," .. yxtoperson_tab.yx_id .. "\';SHOW ENGINE SPHINX  STATUS;");
        local count = db:read_result();
        local _, s_str = string.find(count[1]["Status"], "found: ");
        local e_str = string.find(count[1]["Status"], ", time:");
        local total = string.sub(count[1]["Status"], s_str + 1, e_str - 1);
        local submit_count = ssdb:hsize("yx_student_submit_" .. yxtoperson_tab.yx_id);
        if not submit_count or string.len(submit_count[1]) == 0 then
            yx_table.submit_info = ngx.encode_base64("0/" .. (tonumber(total) - 1));
        else
            yx_table.submit_info = ngx.encode_base64(submit_count[1] .. "/" .. (tonumber(total) - 1));
        end
        -- todo 预习提交情况 end
        table.insert(return_table, yx_table);
    end
    local result = {};
    result["success"] = "true";
    result["total_row"] = total_row;
    result["total_page"] = total_page;
    result["page_number"] = page_number
    result["page_size"] = page_size;
    result["list"] = return_table;
    SSDBUtil:keepAlive();
    MysqlUtil:close(db);
    return result;
end
--[[
	局部函数：组装预习的VO对象
]]
function _YX:getYxTableArrs(param_table)
    local yx_table = {};
    yx_table.yx_id = param_table.yx_id; --预习ID
    yx_table.yx_name = param_table.yx_name; --预习名称
    yx_table.create_time = ngx.localtime(); --创建时间
    yx_table.class_ids = param_table.class_ids; --预习对象(按班级留预习)
    yx_table.group_ids = param_table.group_ids; --预习对象(按组留预习)
    yx_table.person_id = tonumber(param_table.person_id); --创建人
    yx_table.identity_id = tonumber(param_table.identity_id); --创建人身份
    yx_table.scheme_id = tonumber(param_table.scheme_id); --教材版本ID
    yx_table.structure_id = tonumber(param_table.structure_id); --教材章节目录
    yx_table.subject_id = tonumber(param_table.subject_id); --学科ID
    yx_table.yx_conent = param_table.yx_conent; --预习说明
    yx_table.is_delete = 0; --是否删除 0：未删除 1:删除
    yx_table.is_public = tonumber(param_table.is_public); --是否发布 1：发布 0表示未发布
    return yx_table;
end

--[[
	局部函数：组装预习表的insert语句
]]
function _YX:getYxInsertSql(yx_table)
    local tableUtil = require "yxx.tool.TableUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local TS = require "resty.TS";
    local yxtoperson_id = SSDBUtil:incr("t_yx_yxtoperson_pk");
    SSDBUtil:multi_hset("yxx_yxtoperson_" .. yxtoperson_id, yx_table);
    local k_v_table = tableUtil:convert_sql(yx_table);
    local insert_sql = "START TRANSACTION;" ..
            "delete from t_cp_info where cp_type_id=2 and bus_id=" .. yx_table.yx_id .. ";" ..
            "delete from t_yx_info where yx_id=" .. yx_table.yx_id .. ";" ..
            "insert into t_yx_info(" .. k_v_table["k_str"] .. ") value(" .. k_v_table["v_str"] .. ");" ..
            "insert into t_yx_person(id,yx_id,person_id,identity_id,bureau_id,class_id,group_id,update_ts) value(" ..
            yxtoperson_id .. "," .. yx_table.yx_id .. ",0,0,0,0,0," .. TS.getTs() .. ");" ..
            "COMMIT;";
    SSDBUtil:keepAlive();
    return insert_sql;
end

--[[
	局部函数：获得预习详情，通过预习ID
	参数：预习ID
]]
function _YX:getYxDetail(yx_id)
    local cjson = require "cjson";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local CacheUtil = require "common.CacheUtil";
    local PersonInfoModel = require "base.person.model.PersonInfoModel";
    local cache = CacheUtil:getRedisConn();
    local ssdb_db = SSDBUtil:getDb()
    local yx_detail_encode = ssdb_db:hget("preparation_yx_info", yx_id);
    local yx_detail_table = {};
    if yx_detail_encode ~= "ok" and yx_detail_encode[1] and string.len(yx_detail_encode[1]) > 0 then
        yx_detail_table = cjson.decode(yx_detail_encode[1]);
        --通过人员ID和人员身份 获得用户名称
        yx_detail_table.person_name = PersonInfoModel:getPersonName(yx_detail_table.person_id, yx_detail_table.identity_id);
        if yx_detail_table then
            local train_list = yx_detail_table.train_list;
            for i = 1, #train_list do
                local material_list = train_list[i].material_list;
                for j = 1, #material_list do
                    local resource_id = material_list[j].resource_id; --资源ID 通常是IID
                    local resource_type = material_list[j].resource_type; --资源类型
                    if resource_type then
                        if tonumber(resource_type) == 1 or tonumber(resource_type) == 4 or tonumber(resource_type) == 5 then --资源/备课/自定义
                            local info_myinfo = material_list[j].info_myinfo; --info_myinfo  1:云资源   2：我的资源
                            local myjson = {};
                            if tonumber(info_myinfo) == 1 then
                                myjson = ssdb_db:hgetall("resource_" .. resource_id);
                            elseif tonumber(info_myinfo) == 2 then
                                myjson = ssdb_db:hgetall("myresource_" .. resource_id);
                            end
                            material_list[j].resource_info = {};
                            if myjson then
                                for z = 2, #myjson, 2 do
                                    material_list[j].resource_info[tostring(myjson[z - 1])] = myjson[z];
                                end
                            end
                        elseif tonumber(resource_type) == 2 then --微课
                            local wkds_value_null = cache:hmget("wkds_" .. resource_id, "wkds_id_int");
                            if wkds_value_null[1] ~= ngx.null then
                                material_list[j].resource_info = self:getWkdsInfo(resource_id);
                            end
                        elseif tonumber(resource_type) == 3 then --试卷
                            local paper_source = material_list[j].paper_source;
                            local info_myinfo = material_list[j].info_myinfo; --info_myinfo  1:云试卷   2：我的试卷
                            if paper_source and tonumber(paper_source) == 2 then -- 非格式化试卷
                                material_list[j].resource_info = self:getPaperInfo(resource_id, info_myinfo);
                            end
                        end
                    end
                end
            end
        end
    end
    CacheUtil:keepConnAlive(cache);
    SSDBUtil:keepAlive();
    return yx_detail_table;
end

--[[
	局部函数：获得iid获得微课的资源详情
	参数： resource_id：微课的id
]]
local function getWkdsInfo(self, resource_id)
    local cjson = require "cjson";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local CacheUtil = require "common.CacheUtil";
    local cache = CacheUtil:getRedisConn();
    local ssdb_db = SSDBUtil:getDb();
    local thumb_id = "";
    local wkds_value = cache:hmget("wkds_" .. resource_id, "wkds_id_int", "wkds_id_char", "scheme_id", "structure_id",
        "wkds_name", "study_instr", "teacher_name", "play_count", "score_average", "create_time",
        "download_count", "downloadable", "person_id", "table_pk", "group_id", "content_json",
        "teacher_name", "wk_type");
    --获得缩略图id
    local content_json = wkds_value[16];
    local content = ngx.decode_base64(content_json);
    local data = cjson.decode(content);
    if #data.sp_list ~= 0 then
        local resource_info_id = data.sp_list[1].id;
        if resource_info_id ~= ngx.null then
            local thumbid = ssdb_db:multi_hget("resource_" .. resource_info_id, "thumb_id");
            thumb_id = thumbid[2];
        end
    else
        thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C";
    end
    --获得微课位置
    local resource_info = {};
    resource_info.iid = resource_id;
    resource_info.wkds_id_int = wkds_value[1];
    resource_info.wkds_id_char = wkds_value[2];
    resource_info.obj_id_char = wkds_value[2];
    resource_info.scheme_id_int = wkds_value[3];
    resource_info.scheme_id = wkds_value[3];
    resource_info.structure_id = wkds_value[4];
    resource_info.wkds_name = wkds_value[5];
    resource_info.study_instr = wkds_value[6];
    resource_info.teacher_name = wkds_value[7];
    resource_info.play_count = wkds_value[8];
    resource_info.score_average = wkds_value[9];
    resource_info.create_time = wkds_value[10];
    resource_info.download_count = wkds_value[11];
    resource_info.thumb_id = thumb_id;
    resource_info.downloadable = wkds_value[12];
    resource_info.person_id = wkds_value[13];
    resource_info.table_pk = wkds_value[14];
    resource_info.group_id = wkds_value[15];
    resource_info.content_json = wkds_value[16];
    resource_info.person_name = wkds_value[17];
    resource_info.wk_type = wkds_value[18];
    CacheUtil:keepConnAlive(cache);
    return resource_info;
end

_YX.getWkdsInfo = getWkdsInfo;
--[[
	局部函数：获得iid获得试卷的详情
	参数： resource_id：试卷IID info_myinfo：1:云试卷  2:我的试卷
]]
local function getPaperInfo(self, resource_id, info_myinfo)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local CacheUtil = require "common.CacheUtil";
    local StringUtil = require "yxx.tool.StringUtil";
    local cache = CacheUtil:getRedisConn();
    local ssdb_db = SSDBUtil:getDb();
    local resource_info_id;
    local redis_info = {};
    if info_myinfo == 1 then
        redis_info = cache:hmget("paper_" .. resource_id, "paper_id_char", "paper_id_int", "paper_name", "paper_type", "resource_info_id");
    else
        redis_info = cache:hmget("mypaper_" .. resource_id, "paper_id_char", "paper_id_int", "paper_name", "paper_type", "resource_info_id");
    end
    local res_info = ssdb_db:multi_hget("resource_" .. redis_info[5], "resource_title", "resource_type_name", "resource_size", "create_time", "down_count", "file_id", "width", "height", "resource_format", "resource_page", "thumb_id", "preview_status", "for_urlencoder_url", "for_iso_url", "resource_size_int", "beike_type", "scheme_id_int", "resource_id_int", "person_id", "app_type_id", "resource_type", "person_name", "structure_id", "resource_id_char");
    local res_tab = {};
    res_tab.resource_title = res_info[2];
    res_tab.resource_type_name = res_info[4];
    res_tab.resource_size = res_info[6];
    res_tab.create_time = res_info[8];
    res_tab.down_count = res_info[10];
    res_tab.file_id = res_info[12];
    res_tab.width = res_info[14];
    res_tab.height = res_info[16];
    res_tab.resource_format = res_info[18];
    res_tab.resource_page = res_info[20];
    res_tab.thumb_id = res_info[22];
    res_tab.preview_status = res_info[24];
    res_tab.for_urlencoder_url = res_info[26];
    res_tab.for_iso_url = res_info[28];
    res_tab.resource_size_int = res_info[30];
    res_tab.beike_type = res_info[32];
    res_tab.url_code = StringUtil:urlEncode(res_info[2]);
    res_tab.resource_id_int = res_info[36];
    res_tab.person_id = res_info[38];
    res_tab.app_type_id = res_info[40];
    res_tab.resource_type = res_info[42];
    res_tab.person_name = res_info[44];
    res_tab.structure_id = res_info[46];
    res_tab.obj_id_char = res_info[48];
    res_tab.scheme_id = res_info[34];
    CacheUtil:keepConnAlive(cache);
    return res_tab;
end

_YX.getPaperInfo = getPaperInfo;

return _YX;