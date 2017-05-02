function formula=getFormulaFromInChI(InChI)
% extract formula from InChI
[token,rem] = strtok(InChI, '/');
formula=strtok(rem, '/');
%This could be a composite formula, so combine it.
tokens = strsplit(formula,'.');

%The protonation state can also modify the formula! To get it, we remove
%any reconstruction fields, as they do not influence it.
InChI = regexprep(InChI,'/r.*','');
p_layer = regexp(InChI,'/p(.*?)/|/p(.*?)$','tokens');

if ~isempty(p_layer)
    individualProtons = cellfun(@(x) {strsplit(x{1},';')},p_layer);
    addedProtons = cellfun(@(x) sum(cellfun(@(y) eval(y) , x)), individualProtons);
end


%Calc the coefs for all formulas
if (numel(tokens) > 1) || (~isempty(regexp(formula,'(^[0-9]+)'))) || (~isempty(p_layer))
    CoefLists = cellfun(@(x) calcFormula(x), tokens,'UniformOutput',0);
    if exist('addedProtons','var')
        CoefLists = [CoefLists;{{'H';addedProtons}}];
    end
    %and now, combine them.
    Elements = {};
    Coefficients = [];
    for i = 1:numel(CoefLists)
        currentForm = CoefLists{i};
        Elements = [Elements,setdiff(currentForm(1,:),Elements)];
        current_coefs = cell2mat(currentForm(2,:));
        [A,B] = ismember(Elements,currentForm(1,:));
        %Extend the coefficients if necessary 
        Coefficients(end+1:numel(Elements)) = 0;
        Coefficients(A) = Coefficients(A)+current_coefs;        
    end    
        
    Coefs = num2cell(Coefficients);
    Coefs(cellfun(@(x) x == 1, Coefs)) = {[]};
    Coefs = cellfun(@(x) num2str(x) , Coefs,'UniformOutput',0);
    formula = strjoin([Elements , {''}],Coefs);    
end

    
end


function [CoefList] = calcFormula(Formula)
multiplier = 1;
isReplicated = regexp(Formula,'(^[0-9]+)','tokens');
ElementTokens = regexp(Formula,'([A-Z][a-z]?)([0-9]*)','tokens');    
Elements = cellfun(@(x) x{1}, ElementTokens,'UniformOutput',0);
Coefs = cellfun(@(x) str2num(x{2}), ElementTokens,'UniformOutput',0);
Coefs(cellfun(@isempty, Coefs)) = {1};

if ~isempty(isReplicated)
    multiplier = str2num(isReplicated{1}{1});
    Coefs = cellfun(@(x) x*multiplier, Coefs,'UniformOutput',0);
end

CoefList = [Elements;Coefs];
end