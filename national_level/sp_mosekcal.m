function [sp] = sp_mosekcal(A,b,c,n_Ebranch,time,num_stage,eq,ineq)
%% gurobi
%     % 变量的下界和上界
%     lb = [];  % 变量非负
%     ub = [];     % 没有上界
%     
%     model.obj = full(c);
%     model.A = sparse(A);
%     b(find(b==0))=0.00001;
%     model.rhs = b;
%     
%     model.sense = repmat('=', length(b), 1);  % 所有约束现在都是等式约束
%     
%     lb = zeros(length(c), 1);
%     model.lb = lb;  % 所有原变量和松弛变量非负
%     model.ub = inf(length(c), 1);      % 所有原变量和松弛变量没有上界
%     % 设置Gurobi参数
%     params.outputflag = 0;  % 显示求解过程
%     params.method = 1;  % 使用对偶单纯形算法
%     % 调用Gurobi求解器
%     result = gurobi(model, params);
%     basic_vars = find(result.vbasis == 0);  % Gurobi中0通常表示变量在基中
%     
%     % 构建基矩阵B和对应的b
%     sp.w = model.obj(basic_vars)'/model.A(:, basic_vars);
%     sp.B = model.A(:, basic_vars);
%     sp.num = 1;
%     sp.f = result.objval;
%     sp.x = result.x;
%     sp.xb = basic_vars;
%% mosek
    % 设置变量边界
    lb = zeros(length(c), 1);  % 变量非负
    ub = inf(length(c), 1);    % 没有上界
    
    % 构建Mosek模型
    prob.c = full(c);
    prob.a = sparse(A);
    b(find(b == 0)) = 0.00001;
    prob.buc = b;  % 上界约束
    prob.blc = b;  % 下界约束
    
    % 所有约束现在都是等式约束
    prob.blx = lb;  % 所有原变量和松弛变量非负
    prob.bux = ub;  % 所有原变量和松弛变量没有上界
    
    % 设置Mosek参数
    param = struct();
    param.MSK_IPAR_LOG = 0;  % 显示求解过程
    param.MSK_IPAR_OPTIMIZER = 'MSK_OPTIMIZER_DUAL_SIMPLEX';  % 使用对偶单纯形算法
    cmd='minimize echo(0)';
    % 调用Mosek求解器
    [~, res] = mosekopt(cmd, prob, param);

    % 获取基变量
    basic_vars = find(res.sol.bas.skx == 'B');
    
    % 构建基矩阵B和对应的b
    sp.w = prob.c(basic_vars)' / prob.a(:, basic_vars);
    sp.B = prob.a(:, basic_vars);
    sp.num = 1;
    sp.f = res.sol.bas.pobjval;
    sp.x = res.sol.bas.xx;
    sp.xb = basic_vars;
    %% cplex
    % 设置CPLEX模型
% cplex = Cplex();
% cplex.Model.sense = 'minimize';
% 
% % 设置目标函数向量
% cplex.Model.obj = full(c);
% 
% % 设置A矩阵和约束的右侧向量b
% % 假设b中的0值已替换为0.00001，如原代码所示
% cplex.Model.A = sparse(A);
% b(find(b == 0)) = 0.00001;
% cplex.Model.lhs = b;  % CPLEX允许直接设置等式约束的左边界
% cplex.Model.rhs = b;  % 和右边界相同，因为这里所有约束都是等式
% 
% % 变量的下界和上界
% cplex.Model.lb = zeros(length(c), 1);   % 所有原变量和松弛变量非负
% cplex.Model.ub = inf(length(c), 1);     % 所有原变量和松弛变量没有上界
% 
% % 设置CPLEX参数
% cplex.Param.simplex.display.Cur = 0;   % 不显示求解过程
% cplex.Param.lpmethod.Cur = 1;          % 使用原始单纯形算法
% cplex.Param.simplex.display.Cur = 0;   % 不显示求解过程
% cplex.Param.barrier.display.Cur = 0;   % 对于内点法，不显示输出
% cplex.Param.sifting.display.Cur = 0;   % 对于筛选单纯形法，不显示输出
% cplex.Param.conflict.display.Cur = 0;  % 冲突分析时不显示输出
% cplex.DisplayFunc = [];                % 禁用所有CPLEX进度信息输出
% % 解决优化问题
% cplex.solve();
% 
% % 获取基本变量信息
% basic_vars = find(cplex.Solution.basis.colstat == 1);  % CPLEX中1表示变量在基中
% 
% % 构建基矩阵B和对应的b
% sp.w = cplex.Model.obj(basic_vars)' / cplex.Model.A(:, basic_vars);
% sp.B = cplex.Model.A(:, basic_vars);
% sp.num = 1;
% sp.f = cplex.Solution.objval;
% sp.x = cplex.Solution.x;
% sp.xb = basic_vars;

end

