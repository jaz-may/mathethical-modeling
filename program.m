%% 读取并保留原始中文列名
T1 = readtable('附件1.xlsx','FileType','spreadsheet','VariableNamingRule','preserve');
T2 = readtable('附件2.xlsx','FileType','spreadsheet','VariableNamingRule','preserve');

% 去掉列名首尾空格，避免"说明 "这类列名带空格
T1 = renamevars(T1, T1.Properties.VariableNames, strtrim(T1.Properties.VariableNames));
T2 = renamevars(T2, T2.Properties.VariableNames, strtrim(T2.Properties.VariableNames));

%（可选）检查一下当前列名
disp(T1.Properties.VariableNames), disp(T2.Properties.VariableNames)

%% 必要列名存在性检查（防止再次因列名不匹配报错）
need1 = ["地块名称","地块类型","地块面积/亩"];
need2 = ["种植地块","作物编号","作物名称","作物类型","种植面积/亩","种植季次"];
assert(all(ismember(need1, string(T1.Properties.VariableNames))), '附件1列名不完整或不匹配。');
assert(all(ismember(need2, string(T2.Properties.VariableNames))), '附件2列名不完整或不匹配。');

%% 统一地块名称为 cellstr，提取唯一地块
namesCol = string(T1.("地块名称"));
uniqueNames = unique(cellstr(namesCol), 'stable');

%% 生成 Land 结构体
Land = struct('ID',[],'Type',[],'Area',[],'IsGreenhouse',[],'IsSmart',[], ...
              'Crop2023',[],'CropID2023',[],'CropType2023',[], ...
              'Area2023',[],'Season2023',[]);

Land = repmat(Land, numel(uniqueNames), 1);

for i = 1:numel(uniqueNames)
    landName = uniqueNames{i};

    % —— 附件1：地块基本信息（如同名多行，取第一行；可按需合并面积）
    row1 = T1(strcmp(string(T1.("地块名称")), landName), :);
    Land(i).ID   = landName;
    Land(i).Type = string(row1.("地块类型")(1));
    Land(i).Area = row1.("地块面积/亩")(1);

    Land(i).IsGreenhouse = contains(Land(i).Type, "大棚");
    Land(i).IsSmart      = contains(Land(i).Type, "智慧");

    % —— 附件2：2023年该地块的全部种植记录
    rows2 = T2(strcmp(string(T2.("种植地块")), landName), :);

    Land(i).Crop2023      = string(rows2.("作物名称"));
    Land(i).CropID2023    = rows2.("作物编号");
    Land(i).CropType2023  = string(rows2.("作物类型"));
    Land(i).Area2023      = rows2.("种植面积/亩");
    Land(i).Season2023    = rows2.("种植季次");
end

%% 快速查看
% function data_set=search()
%     targetName=input('地块名称');
% 
% %targetName = 'B2';%string(input('地块名称:'));   % 目标地块名称（string 类型）
%     idx = strcmp({Land.ID}, targetName);  % 返回逻辑向量
%     info = Land(idx);    % 提取该地块的结构体
%     disp(info)           % 查看全部信息
% end

function data_set = search(Land, targetName)
    % 如果没有提供 targetName，则提示输入
    if nargin < 2
        targetName = input('地块名称: ', 's');  % 输入字符串
    end

    % 查找匹配地块
    idx = strcmp({Land.ID}, targetName);
    data_set = Land(idx);  % 返回匹配的结构体

    if isempty(data_set)
        fprintf('未找到地块 "%s"\n', targetName);
    else
        disp(data_set)      % 显示信息
    end
end
L=search(Land)